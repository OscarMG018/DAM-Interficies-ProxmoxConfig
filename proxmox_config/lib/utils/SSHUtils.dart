import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:proxmox_config/models/RedirectionData.dart';
import '../models/FileData.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
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
    print(command);
    try {
      final session = await SSHUtils.client!.execute(command);
      final stdout = await utf8.decodeStream(session.stdout);
      final stderr = await utf8.decodeStream(session.stderr);
      print(stdout);
      print(stderr);
      session.close();
      return (stdout: stdout, stderr: stderr);
    } catch (e) {
      throw Exception('Error executing command "$command": $e');
    }
  }

  static void disconnect() {
    client!.close();
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

  static Future<List<FileData>> getDirectoryContents({
    required bool showHidden,
  }) async {
    try {
      final result = await executeCommand(
        command: showHidden ? 'ls -la "$currentDirectory"':'ls -l "$currentDirectory"',
      );
      
      if (result.stderr.isNotEmpty) {
        throw Exception('Error listing directory: ${result.stderr}');
      }

      final lines = result.stdout.split('\n')
        ..removeWhere((line) => line.isEmpty || line.startsWith('total') || line.startsWith('.'));

      return lines.map((line) {
        final parts = line.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
        if (parts.length < 9) return null;

        final permissions = parts[0];
        final isFolder = permissions.startsWith('d');
        final owner = parts[2];
        final size = int.tryParse(parts[4]) ?? 0;

        // Parse the last modified date and time
        final dateString = "${parts[5]} ${parts[6]} ${parts[7]}";
        final lastModified = DateTime.tryParse(dateString) ?? DateTime.now();

        final name = parts.sublist(8).join(' ');

        final lastDotIndex = name.lastIndexOf('.');
        final extension = lastDotIndex != -1 && !isFolder
            ? name.substring(lastDotIndex + 1)
            : '';

        return FileData(
          name: name,
          extension: extension,
          isFolder: isFolder,
          size: size,
          lastModified: lastModified,
          owner: owner,
          permissions: permissions,
        );
      }).where((file) => file != null && file.name != "." && file.name != "..").cast<FileData>().toList();
    } catch (e) {
      throw Exception('Failed to get directory contents: $e');
    }
  }

  static Future<void> renameFile({
    required String oldName,
    required String newName,
  }) async {
    try {
      final result = await executeCommand(
        command: 'mv "$oldName" "$newName"',
      );

      if (result.stderr.isNotEmpty) {
        throw Exception('Error renaming file: ${result.stderr}');
      }
    } catch (e) {
      throw Exception('Failed to rename file: $e');
    }
  }

  static Future<void> deleteFile({
    required String name,
  }) async {
    try {
      final result = await executeCommand(
        command: 'rm "$name"',
      );

      if (result.stderr.isNotEmpty) {
        throw Exception('Error deleting file: ${result.stderr}');
      }
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  static Future<void> downloadFile({
    required String name,
    required String destination,
  }) async {
    final sftp = await client!.sftp();
    final remoteFile = await sftp.open(currentDirectory + "/" + name, mode: SftpFileOpenMode.read);
    final localFile = File(destination).openWrite();

    try {
      final stream = remoteFile.read();
      await stream.forEach(localFile.add);
    } catch (e) {
      rethrow;
    } finally {
      await remoteFile.close();
      await localFile.close();
    }
  }

  static Future<String> uploadFile({
    required String name,
    required String sourcePath,
  }) async {
    if (client == null) {
      throw Exception('No SSH client connected.');
    }

    final sftp = await client!.sftp();
    final filePath = '$currentDirectory/$name';
    print('Uploading $filePath');

    try {
      // Open the remote file in write mode
      final remoteFile = await sftp.open(
        filePath,
        mode: SftpFileOpenMode.write | SftpFileOpenMode.create | SftpFileOpenMode.truncate,
      );

      // Read the local file as bytes
      final localFile = File(sourcePath);
      if (!await localFile.exists()) {
        throw Exception('Source file does not exist: $sourcePath');
      }

      // Convert the local file bytes to a Stream<Uint8List>
      final fileBytes = await localFile.readAsBytes();
      final fileStream = Stream<Uint8List>.fromIterable(
        [Uint8List.fromList(fileBytes)],
      );

      // Write the stream to the remote file
      await remoteFile.write(fileStream);

      // Close the remote file
      await remoteFile.close();
      return "File Uploaded Succesfully";
    } catch (e) {
      return 'Failed to upload file: $e';
    }
  }

  static Future<String> uploadFolder({
    required String folderPath,
    required String remoteFolderPath,
  }) async {
    if (client == null) {
      throw Exception('No SSH client connected.');
    }

    final sftp = await client!.sftp();
    final dir = Directory(folderPath);

    if (!await dir.exists()) {
      return 'The specified folder does not exist: $folderPath';
    }

    try {
      // Create the remote folder if it does not exist
      await sftp.mkdir(remoteFolderPath);

      // Iterate over all files and subdirectories in the local folder
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        final relativePath = entity.path.substring(folderPath.length + 1);
        final remotePath = '$remoteFolderPath/$relativePath';

        if (entity is File) {
          // Upload each file
          await uploadFile(name: relativePath, sourcePath: entity.path);
        } else if (entity is Directory) {
          // Create subdirectories on the remote server
          await sftp.mkdir(remotePath);
        }
      }

      return "Folder uploaded successfully.";
    } catch (e) {
      return 'Failed to upload folder: $e';
    }
  }

  static Future<void> extractFile({
    required String name,
  }) async {
    final directory = await getTemporaryDirectory();
    final  filePath = '${directory.path}/extract.zip';
    final  extractPath = '${directory.path}/extract';
    await downloadFile(name: name, destination: filePath);

    final targetDir = Directory(extractPath);
    if (!targetDir.existsSync()) {
      targetDir.createSync();
    }
    final bytes = File(filePath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final filename = file.name;
      final filePath = '${targetDir.path}/$filename';
      final outFile = File(filePath);

      await outFile.create(recursive: true);
      await outFile.writeAsBytes(file.content as List<int>);
    }
    uploadFolder(folderPath: extractPath, remoteFolderPath: '$currentDirectory/$name');
  }

  static Future<List<RedirectionData>> getRedirections() async {
    List<RedirectionData> redirections = [];
    final result = await executeCommand(
        command: 'sudo iptables -t nat -L PREROUTING -n -v');
    
    if (result.stderr.isNotEmpty) {
      throw Exception('Error executing command: ${result.stderr}');
    }

    final lines = result.stdout.split('\n');
    final regex = RegExp(
        r'(?<protocol>\S+)\s+(?<dport>\d+)\s+(?<target>\S+)\s+(?<tport>\d+)');

    for (final line in lines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        try {
          final dport = int.parse(match.namedGroup('dport')!);
          final tport = int.parse(match.namedGroup('tport')!);
          redirections.add(RedirectionData(dport: dport, tport: tport));
        } catch (e) {
          throw Exception('Failed to get directory contents: $e');
        }
      }
    }

    return redirections;
  }

  static Future<void> saveRedirections(List<RedirectionData> redirections) async {
    // Delete all existing redirection
    await executeCommand(command: 'sudo iptables -t nat -F');

    // Add all redirections
    for (final redirection in redirections) {
        await executeCommand(
            command: 'sudo iptables -t nat -A PREROUTING --dport ${redirection.dport??""} -j REDIRECT --to-port ${redirection.tport??""}');
    }
  }

}