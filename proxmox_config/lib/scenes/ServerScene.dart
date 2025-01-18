import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/FileData.dart';
import '../utils/SSHUtils.dart';
import '../widgets/FileDisplay.dart';
import '../widgets/ListWithTitle.dart';
import '../widgets/FileInfo.dart';
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
    } else if (action == 'Extract') {
      _handleExtract(file);
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
    //show a dialog with the info: name, folder/extension, size, last modified, owner, permissions
    showDialog(
      context: context,
      builder: (context) => FileInfo(file: file),
    );
  }

  void _handleExtract(FileData file) {
    SSHUtils.extractFile(name: file.name);
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
                    items: _getFiles(),
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
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      sorting = _FileSorting.values[(sorting.index + 1) % _FileSorting.values.length];
                    });
                  },
                  child: Text('Sort by ${sorting.name}'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _showRedirectionDialog();
                  },
                  child: Text('Show Port Redirection'),
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