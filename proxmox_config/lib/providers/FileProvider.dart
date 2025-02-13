import 'package:flutter/material.dart';
import '../models/FileData.dart';
import '../utils/SSHUtils.dart';

enum FileSorting { name, size, lastModified }

class FileProvider extends ChangeNotifier {
  List<FileData> _files = [];
  bool _isLoading = false;
  bool _showHidden = false;
  FileSorting _sorting = FileSorting.name;

  List<FileData> get files => _getSortedFiles();
  bool get isLoading => _isLoading;
  bool get showHidden => _showHidden;
  FileSorting get sorting => _sorting;

  List<FileData> _getSortedFiles() {
    List<FileData> sortedFiles = List.from(_files);
    
    switch (_sorting) {
      case FileSorting.name:
        sortedFiles.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case FileSorting.size:
        sortedFiles.sort((a, b) => b.size.compareTo(a.size));
        break;
      case FileSorting.lastModified:
        sortedFiles.sort((a, b) => b.lastModified.compareTo(a.lastModified));
        break;
    }

    return sortedFiles;
  }

  Future<void> loadFiles() async {
    _isLoading = true;
    notifyListeners();

    try {
      _files = await SSHUtils.getDirectoryContents(showHidden: _showHidden);
    } catch (e) {
      print('Error loading files: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleShowHidden() {
    _showHidden = !_showHidden;
    loadFiles();
  }

  void cycleSorting() {
    _sorting = FileSorting.values[(_sorting.index + 1) % FileSorting.values.length];
    loadFiles();
  }
} 