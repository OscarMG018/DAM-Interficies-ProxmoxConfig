import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class FileData {
  final String name;
  final String extension;
  final bool isFolder;
  final int size;
  final DateTime lastModified;
  final String owner;
  final String permissions;

  FileData({
    required this.name,
    required this.extension,
    required this.isFolder,
    required this.size,
    required this.lastModified,
    required this.owner,
    required this.permissions
  });

  String getImagePath() {
    if (isFolder) {
      return 'assets/images/folder.png';
    } else {
      if (extension.toLowerCase() == 'txt' || extension.toLowerCase() == 'md') {
        return 'assets/images/txt.png';
      } else if (extension.toLowerCase() == 'png' || extension.toLowerCase() == 'jpg' || extension.toLowerCase() == 'jpeg') {
        return 'assets/images/png.png';
      } else if (extension.toLowerCase() == 'zip') {
        return 'assets/images/zip.png';
      } else if (extension.toLowerCase() == 'jar') {
        return 'assets/images/jar.png';
      } else if (extension.toLowerCase() == 'js') {
        return 'assets/images/js.png';
      }
      else {
        return 'assets/images/file.png';
      }
    }
  }

  String getFormattedSize() {
    if (size >= 1 << 30) {
      return '${(size / (1 << 30)).toStringAsFixed(2)} GB';
    } else if (size >= 1 << 20) {
      return '${(size / (1 << 20)).toStringAsFixed(2)} MB';
    } else if (size >= 1 << 10) {
      return '${(size / (1 << 10)).toStringAsFixed(2)} KB';
    } else {
      return '$size B';
    }
  }
  //day of week,day month name year, time
  String getFormatedDate() {
    return DateFormat('EEEE, d MMMM y, h:mm a').format(lastModified);
  }

  //Owener permision:(read/write/execute) group:(read) everyone(read)
  String getFormattedPermissions() {
    String formatSection(String section) {
      String read = section[0] == 'r' ? 'read' : '';
      String write = section[1] == 'w' ? 'write' : '';
      String execute = section[2] == 'x' ? 'execute' : '';

      return [read, write, execute].where((perm) => perm.isNotEmpty).join('/');
    }

    if (permissions.length != 10) {
      throw FormatException("Invalid permission string");
    }

    final owner = formatSection(permissions.substring(1, 4));
    final group = formatSection(permissions.substring(4, 7));
    final everyone = formatSection(permissions.substring(7, 10));

    return "Owner permission: ($owner) group: ($group) everyone: ($everyone)";
  }

  Color getFileTypeColor() {
    if (isFolder) {
      return Colors.blue;
    }
    switch (extension.toLowerCase()) {
      case 'txt':
      case 'md':
        return Colors.black;
      case 'jar':
        return Colors.red;
      case 'js':
        return Colors.yellow;
      case 'zip':
      case 'rar':
        return Colors.purple;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}