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

enum _FileSorting { name, size, lastModified }

class ServerScene extends StatefulWidget {

  const ServerScene({
    Key? key,
  }) : super(key: key);
  
  @override
  _ServerSceneState createState() => _ServerSceneState();
}

class _ServerSceneState extends State<ServerScene> {
  List<FileData> files = [];
  bool isLoading = true;
  bool showHidden = false;
  _FileSorting sorting = _FileSorting.name;
  ServerData? server;

  @override
  void initState() {
    super.initState();
    _loadFiles();
    _loadServer();
  }

  Future<void> _loadServer() async {
    setState(() => isLoading = true);
    try {
      server = await SSHUtils.DetectServers();
      print("Server detected: ${server?.type}");
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading server: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadFiles() async {
    setState(() => isLoading = true);
    try {
      final loadedFiles = await SSHUtils.getDirectoryContents(showHidden: showHidden);
      setState(() {
        files = loadedFiles;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading files: $e');
      setState(() => isLoading = false);
    }
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
      _loadFiles();
    } else if (action == 'Info') {
      _handleInfo(file);
    } else if (action == 'Download') {
      _handleDownload(file);
    } else if (action == 'Extract') {
      _handleExtract(file);
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
              _loadFiles();
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
    _loadFiles();
  }

  void _handleFileDoubleClick(file) {
    print('Double click on file: ${file.name}');
    if (file.isFolder) {
      SSHUtils.changeDirectory(path: '${file.name}');
      _loadFiles();
    }
  }

  void _back() {
    SSHUtils.changeDirectory(path: '..');
    _loadFiles();
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
      _loadFiles();
    }
  }

  void _showHiddenFiles(value) {
    showHidden = value;
    _loadFiles();
  }

  void _showRedirectionDialog() {
    showDialog(
      context: context,
      builder: (context) => const PortRedirectionDialog(),
    );
  }

  List<FileDisplay> _getFiles() {
    //Sort files firts
    if (sorting == _FileSorting.name) {
      files.sort((a, b) => a.name.compareTo(b.name));
    } else if (sorting == _FileSorting.size) {
      files.sort((a, b) => a.size.compareTo(b.size));
    } else if (sorting == _FileSorting.lastModified) {
      files.sort((a, b) => a.lastModified.compareTo(b.lastModified));
    }
    List<FileDisplay> fileList = [];
    for (FileData file in files) {
      if (file.isFolder) {
        fileList.add(FileDisplay(
          fileName: file.name,
          assetImagePath: file.getImagePath(),
          actions: const ['Rename', 'Delete','Info', 'Download'],
          onActionSelected: (action) => _handleFileAction(action, file),
          onDoubleClick: () => _handleFileDoubleClick(file),
        ));
      }
      else if (file.extension == 'zip') {
        fileList.add(FileDisplay(
          fileName: file.name,
          assetImagePath: file.getImagePath(),
          actions: const ['Rename', 'Delete','Info', 'Download', 'Extract'],
          onActionSelected: (action) => _handleFileAction(action, file),
          onDoubleClick: () => _handleFileDoubleClick(file),
        ));
      }
      else {
        fileList.add(FileDisplay(
          fileName: file.name,
          assetImagePath: file.getImagePath(),
          actions: const ['Rename', 'Delete','Info', 'Download'],
          onActionSelected: (action) => _handleFileAction(action, file),
          onDoubleClick: () => _handleFileDoubleClick(file),
        ));
      }
    }
    return fileList;
  }

  void _startServer() async {
    setState(() => isLoading = true);
    try {
      await SSHUtils.startServer(server!);
      setState(() => isLoading = false);
    } catch (e) {
      print('Error starting server: $e');
      setState(() => isLoading = false);
    }
  }

  void _stopServer() async {
    setState(() => isLoading = true);
    try {
      await SSHUtils.stopServer(server!);
      setState(() => isLoading = false);
    } catch (e) {
      print('Error stopping server: $e');
      setState(() => isLoading = false);
    }
  }

  void _restartServer() async {
    setState(() => isLoading = true);
    try {
      await SSHUtils.restartServer(server!);
      setState(() => isLoading = false);
    } catch (e) {
      print('Error restarting server: $e');
      setState(() => isLoading = false);
    }
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
              if (server != null)
                ServerStatus(isRunning: server!.isRunning, serverType: server!.type,
                  onStart: () => _startServer(),
                  onStop: () => _stopServer(),
                  onRestart: () => _restartServer()
                ),
                const SizedBox(height: 16),
              Expanded(
                child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListWithTitle(
                      title: 'Files',
                      items: _getFiles(),
                    ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CustomButton(
                      onPressed: _back,
                      text: 'Back',
                      color: Colors.blue,
                    ),
                    CustomButton(
                      onPressed: _uploadFile,
                      text: 'Upload',
                      color: Colors.blue,
                    ),
                    CustomButton(
                      onPressed: _loadFiles,
                      text: 'Refresh',
                      color: Colors.blue,
                    ),
                    CustomButton(
                      onPressed: () {
                        setState(() {
                          sorting = _FileSorting.values[(sorting.index + 1) % _FileSorting.values.length];
                        });
                      },
                      text: 'Sort by ${sorting.name}',
                      color: Colors.blue,
                    ),
                    CustomButton(
                      onPressed: () {
                        _showRedirectionDialog();
                      },
                      text: 'Show Port Redirection',
                      color: Colors.blue,
                    ),
                    CustomCheckboxWithText(
                      isChecked: showHidden,
                      text: 'Show Hidden Files',
                      onChanged: _showHiddenFiles,
                    ),
                  ],
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}