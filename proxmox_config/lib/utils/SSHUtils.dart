import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import '../models/FileData.dart';
import 'dart:io';

class SSHUtils {
  static Utf8Codec utf8 = const Utf8Codec();
  static String currentDirectory = '/home';
  static SSHClient? client;

  static Future<void> connect({
    required String host,
    required String username,
    required String keyFilePath,
    required int port,
  }) async {
    try {
      final socket = await SSHSocket.connect(host, port);
      final keyFile = File(keyFilePath);
      final keyContents = await keyFile.readAsString();
      
      final client = SSHClient(
        socket,
        username: username,
        identities: SSHKeyPair.fromPem(keyContents),
      );
      currentDirectory = '/home';

      SSHUtils.client = client;
    } catch (e) {
      throw Exception('Failed to establish SSH connection: $e');
    }
  }

  static Future<({String stdout, String stderr})> executeCommand({
    required String command,
  }) async {
    try {
      final session = await SSHUtils.client!.execute(command);
      final stdout = await utf8.decodeStream(session.stdout);
      final stderr = await utf8.decodeStream(session.stderr);
      session.close();
      return (stdout: stdout, stderr: stderr);
    } catch (e) {
      throw Exception('Error executing command "$command": $e');
    }
  }

  static void disconnect(SSHClient client) {
    client.close();
  }

  static void changeDirectory({required String path}) {
    if (path == '..') {
      final parts = currentDirectory.split('/');
      parts.removeLast();
      currentDirectory = parts.join('/');
      if (currentDirectory.isEmpty) {
        currentDirectory = '/';
      }
    } else if (path == '.') {
      return;
    } else {
      if (currentDirectory != '/') {
        currentDirectory += '/';
      }
      currentDirectory += path;
    }
    print(currentDirectory);
  }

  static Future<List<FileData>> getDirectoryContents() async {
    try {
      final result = await executeCommand(
        command: 'ls -la "$currentDirectory"',
      );
      
      if (result.stderr.isNotEmpty) {
        throw Exception('Error listing directory: ${result.stderr}');
      }

      final lines = result.stdout.split('\n')
        ..removeWhere((line) => line.isEmpty || line.startsWith('total') || line.startsWith('.'));

      return lines.map((line) {
        final parts = line.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
        if (parts.length < 9) return null;

        final name = parts.sublist(8).join(' ');
        final isFolder = line.startsWith('d');
        
        final lastDotIndex = name.lastIndexOf('.');
        final extension = lastDotIndex != -1 && !isFolder
            ? name.substring(lastDotIndex + 1)
            : '';

        return FileData(
          name: name,
          extension: extension,
          isFolder: isFolder,
        );
      })
      .where((file) => file != null)
      .cast<FileData>()
      .toList();
    } catch (e) {
      throw Exception('Failed to get directory contents: $e');
    }
  }
}