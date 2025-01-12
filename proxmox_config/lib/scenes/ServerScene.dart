import 'package:ssh2/ssh2.dart';
import 'package:flutter/material.dart';
import '../models/FileData.dart';
import '../utils/SSHUtils.dart';
import '../widgets/FileDisplay.dart';
import '../widgets/ListWithTitle.dart';

class ServerScene extends StatefulWidget {
  final SSHClient client;

  const ServerScene({
    Key? key,
    required this.client,
  }) : super(key: key);
  
  @override
  _ServerSceneState createState() => _ServerSceneState();
}

class _ServerSceneState extends State<ServerScene> {
  List<FileData> files = [];
  String currentPath = '/home';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => isLoading = true);
    try {
      final loadedFiles = await SSHUtils.getDirectoryContents(
        client: widget.client,
        path: currentPath,
      );
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
                  title: 'Files in $currentPath',
                  items: files.map((file) => FileDisplay(
                    fileName: file.name,
                    assetImagePath: file.getImagePath(),
                    actions: ['Rename', 'Delete',],
                    onActionSelected: (action) => _handleFileAction(action, file),
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