import 'package:flutter/material.dart';
import '../models/FileData.dart';
import '../utils/SSHUtils.dart';
import '../widgets/FileDisplay.dart';
import '../widgets/ListWithTitle.dart';

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

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => isLoading = true);
    try {
      final loadedFiles = await SSHUtils.getDirectoryContents();
      setState(() {
        files = loadedFiles;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading files: $e');
      setState(() => isLoading = false);
    }
  }

  void _handleFileAction(String action, FileData file) {
    // TODO: Implement file actions
    print('Action: $action on file: ${file.name}');
  }

  void _handleFileDoubleClick(file) {
    print('Double click on file: ${file.name}');
    if (file.isFolder) {
      SSHUtils.changeDirectory(path: '${file.name}');
      _loadFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: isLoading
              ? Center(child: CircularProgressIndicator())
              : ListWithTitle(
                  title: 'Files',
                  items: files.map((file) => FileDisplay(
                    fileName: file.name,
                    assetImagePath: file.getImagePath(),
                    actions: ['Rename', 'Delete',],
                    onActionSelected: (action) => _handleFileAction(action, file),
                    onDoubleClick: () => _handleFileDoubleClick(file),
                  )).toList(),
                ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement back navigation
                },
                child: Text('Back'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement upload
                },
                child: Text('Upload'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement refresh
                  _loadFiles();
                },
                child: Text('Refresh'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}