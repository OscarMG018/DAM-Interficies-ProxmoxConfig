import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:proxmox_config/widgets/CustomButton.dart';
import 'package:proxmox_config/widgets/CustomCheckboxWithText.dart';
import 'package:proxmox_config/widgets/LabeledTextField.dart';
import '../models/FileData.dart';
import '../utils/SSHUtils.dart';
import '../widgets/FileDisplay.dart';
import '../widgets/ListWithTitle.dart';
import '../widgets/FileInfo.dart';
import '../widgets/ServerStatus.dart';
import '../models/ServerData.dart';
import '../widgets/PortRedirectionDialog.dart';
import 'package:provider/provider.dart';
import '../providers/FileProvider.dart';
import '../providers/ServerProvider.dart';

class ServerScene extends StatefulWidget {

  const ServerScene({
    Key? key,
  }) : super(key: key);
  
  @override
  _ServerSceneState createState() => _ServerSceneState();
}

class _ServerSceneState extends State<ServerScene> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FileProvider>().loadFiles();
      context.read<ServerProvider>().loadServer();
    });
  }

  List<String> getFileActions(FileData file) {
    if (file.isFolder) {
      return const ['Rename', 'Delete','Info', 'Download'];
    } else if (file.extension == 'zip' || file.extension == 'rar') {
      return const ['Rename', 'Delete','Info', 'Download', 'Extract'];
    } else {
      return const ['Rename', 'Delete','Info', 'Download'];
    }
  }

  void _handleFileAction(String action, FileData file) {
    print('Action: $action on file: ${file.name}');
    if (action == 'Rename') {
      _handleRename(file);
    } else if (action == 'Delete') {
      SSHUtils.deleteFile(name: file.name);
      context.read<FileProvider>().loadFiles();
    } else if (action == 'Info') {
      _handleInfo(file);
    } else if (action == 'Download') {
      _handleDownload(file);
    } else if (action == 'Extract') {
      _handleExtract(file);
    }
  }

  void _handleDelete(FileData file) {
    if (file.isFolder) {
      SSHUtils.deleteFolder(name: file.name);
    } else {
      SSHUtils.deleteFile(name: file.name);
    }
  }

  void _handleRename(FileData file) {
    TextEditingController controller = TextEditingController(text: file.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: LabeledTextField(
          label: "New name",
          controller: controller,
        ),
        actions: [
          CustomButton(
            onPressed: () {
              Navigator.pop(context);
            },
            text: 'Cancel',
            color: Colors.blue,
          ),
          CustomButton(
            onPressed: () {
              print(controller.text);
              if (controller.text == file.name) {
                Navigator.pop(context);
                return;
              }
              SSHUtils.renameFile(oldName: file.name, newName: controller.text);
              context.read<FileProvider>().loadFiles();
              Navigator.pop(context);
            },
            text: 'Rename',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  void _handleDownload(FileData file) async {
    String? result = await FilePicker.platform.saveFile(fileName: file.name);
    if (result != null) {
      SSHUtils.downloadFile(name: file.name, destination: result);
      _showSnackBar(message: 'File downloaded succesfully: ${file.name} to $result',duration:10);
    }
  }

  void _handleInfo(FileData file) {
    //show a dialog with the info: name, folder/extension, size, last modified, owner, permissions
    showDialog(
      context: context,
      builder: (context) => FileInfo(file: file),
    );
  }

  void _handleExtract(FileData file) async {
    String result = await SSHUtils.extractFile(name: file.name);
    _showSnackBar(message: result);
    context.read<FileProvider>().loadFiles();
  }

  void _handleFileDoubleClick(file) {
    print('Double click on file: ${file.name}');
    if (file.isFolder) {
      SSHUtils.changeDirectory(path: '${file.name}');
      context.read<FileProvider>().loadFiles();
    }
  }

  void _back() {
    SSHUtils.changeDirectory(path: '..');
    context.read<FileProvider>().loadFiles();
  }

  void _showSnackBar({
    required String message,
    SnackBarAction? action,
    int duration = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        duration: Duration(seconds: duration),
      ),
    );
  }

  void _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(dialogTitle: 'Select a file');
    if (result != null) {
      String uploadResult = await SSHUtils.uploadFile(name: result.files.first.name, sourcePath: result.files.first.path!);
      _showSnackBar(message: uploadResult);
      context.read<FileProvider>().loadFiles();
    }
  }

  void _showHiddenFiles(value) {
    context.read<FileProvider>().toggleShowHidden();
  }

  void _showRedirectionDialog() {
    showDialog(
      context: context,
      builder: (context) => const PortRedirectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Expanded(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Consumer<ServerProvider>(
                builder: (context, serverProvider, child) {
                  final server = serverProvider.server;
                  if (server == null) return const SizedBox.shrink();
                  
                  return Column(
                    children: [
                      ServerStatus(
                        isRunning: server.isRunning,
                        serverType: server.type,
                        onStart: _startServer,
                        onStop: _stopServer,
                        onRestart: _restartServer
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
              Expanded(
                child: Consumer2<FileProvider, ServerProvider>(
                  builder: (context, fileProvider, serverProvider, child) {
                    if (fileProvider.isLoading || serverProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    return ListWithTitle(
                      title: 'Files',
                      items: _getFiles(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Consumer<FileProvider>(
                  builder: (context, fileProvider, child) {
                    return Row(
                      children: [
                        CustomButton(
                          onPressed: _disconnect,
                          text: 'Disconnect',
                          color: Colors.red,
                        ),
                        const SizedBox(width: 32),
                        CustomButton(
                          onPressed: _back,
                          text: 'Back',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 16),
                        CustomButton(
                          onPressed: _uploadFile,
                          text: 'Upload',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 16),
                        CustomButton(
                          onPressed: () {
                            context.read<FileProvider>().cycleSorting();
                          },
                          text: 'Sort by ${fileProvider.sorting.name}',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 16),
                        CustomButton(
                          onPressed: () {
                            _showRedirectionDialog();
                          },
                          text: 'Show Port Redirection',
                          color: Colors.blue,
                          width: 200,
                        ),
                        const SizedBox(width: 16),
                        CustomCheckboxWithText(
                          isChecked: fileProvider.showHidden,
                          text: 'Show Hidden Files',
                          onChanged: _showHiddenFiles,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FileDisplay> _getFiles() {
    return context.read<FileProvider>().files.map((file) {
      if (file.isFolder) {
        return FileDisplay(
          fileName: file.name,
          assetImagePath: file.getImagePath(),
          actions: const ['Rename', 'Delete', 'Info', 'Download'],
          onActionSelected: (action) => _handleFileAction(action, file),
          onDoubleClick: () => _handleFileDoubleClick(file),
        );
      } else if (file.extension == 'zip') {
        return FileDisplay(
          fileName: file.name,
          assetImagePath: file.getImagePath(),
          actions: const ['Rename', 'Delete', 'Info', 'Download', 'Extract'],
          onActionSelected: (action) => _handleFileAction(action, file),
          onDoubleClick: () => _handleFileDoubleClick(file),
        );
      } else {
        return FileDisplay(
          fileName: file.name,
          assetImagePath: file.getImagePath(),
          actions: const ['Rename', 'Delete', 'Info', 'Download'],
          onActionSelected: (action) => _handleFileAction(action, file),
          onDoubleClick: () => _handleFileDoubleClick(file),
        );
      }
    }).toList();
  }

  void _startServer() async {
    await context.read<ServerProvider>().startServer();
  }

  void _stopServer() async {
    await context.read<ServerProvider>().stopServer();
  }

  void _restartServer() async {
    await context.read<ServerProvider>().restartServer();
  }

  void _disconnect() async {
    SSHUtils.disconnect();
    // Go back to ConfigScene
    Navigator.pop(context);
  }
}