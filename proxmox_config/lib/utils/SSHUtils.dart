import 'dart:convert';
import 'package:ssh2/ssh2.dart';
import '../models/FileData.dart';

class SSHUtils {
  static Future<SSHClient> connect({
    required String host,
    required int port,
    required String username,
    required String passwordOrKey,
  }) async {
    // Create the SSHClient instance
    final client = SSHClient(
      host: host,
      port: port,
      username: username,
      passwordOrKey: passwordOrKey,
    );

    // Attempt connection
    String? result = await client.connect();
    if (result != null) {
      throw Exception('Failed to connect: $result');
    }

    // Return the connected client
    return client;
  }

  static Future<String> executeCommand({
    required SSHClient client,
    required String command,
  }) async {
      // Execute the command
      String? result = await client.execute(command);
      if (result == null) {
        throw Exception('Failed to execute command "$command"');
      }
      return result;
  }

  static void disconnect(SSHClient client) {
    client.disconnect();
  }

  static Future<List<FileData>> getDirectoryContents({
    required SSHClient client,
    required String path,
  }) async {
    try {
      final result = await executeCommand(
        client: client,
        command: 'ls -la "$path"',
      );
      

      final lines = result.split('\n')
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