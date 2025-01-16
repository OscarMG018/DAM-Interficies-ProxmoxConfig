import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/FileData.dart';
import '../utils/SSHUtils.dart';
import '../widgets/FileDisplay.dart';
import '../widgets/ListWithTitle.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    _loadFiles();
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
    List<String> actions = [];
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
    }
  }

  void _handleRename(FileData file) {
    String newName = file.name;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rename'),
          content: TextField(
            controller: TextEditingController(text: newName),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'New name',
            ),
            onChanged: (value) {
              newName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                print(newName);
                if (newName == file.name) {
                  Navigator.pop(context);
                  return;
                }
                SSHUtils.renameFile(oldName: file.name, newName: newName);
                _loadFiles();
                Navigator.pop(context);
              },
              child: const Text('Rename'),
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
    // TODO: Load more info about the file
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListWithTitle(
                    title: 'Files',
                    items: files.map((file) => FileDisplay(
                      fileName: file.name,
                      assetImagePath: file.getImagePath(),
                      actions: const ['Rename', 'Delete','Info', 'Download'],
                      onActionSelected: (action) => _handleFileAction(action, file),
                      onDoubleClick: () => _handleFileDoubleClick(file),
                    )).toList(),
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _back();
                  },
                  child: const Text('Back'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _uploadFile();
                  },
                  child: const Text('Upload'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _loadFiles();
                  },
                  child: const Text('Refresh'),
                ),
                Row(children: [
                  Checkbox(
                    value: showHidden,
                    onChanged: _showHiddenFiles,
                  ),
                  const Text('Show Hidden Files'),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}