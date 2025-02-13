import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:proxmox_config/models/RedirectionData.dart';
import 'package:proxmox_config/models/ServerType.dart';
import '../models/FileData.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:proxmox_config/models/ServerData.dart';
import 'package:path/path.dart' as path;

class SSHUtils {
  static Utf8Codec utf8 = const Utf8Codec();
  static String currentDirectory = '/home';
  static SSHClient? client;
  static const String SERER_DETECT_DIR = '/home';

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
      print("stdout: $stdout");
      print("stderr: $stderr");
      session.close();
      return (stdout: stdout, stderr: stderr);
    } catch (e) {
      throw Exception('Error executing command "$command": $e');
    }
  }

  static Future<void> executeCommandWithoutResult({required String command}) async {
    try {
      await SSHUtils.client!.execute(command);
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
        command: showHidden
        ? 'LC_TIME=C ls -la "$currentDirectory"'
        : 'LC_TIME=C ls -l "$currentDirectory"'
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

  static Future<void> deleteFolder({
    required String name,
  }) async {
    try {
      final result = await executeCommand(
        command: 'rm -r "$name"',
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

  static Future<String> extractFile({
    required String name,
  }) async {
    final result = await executeCommand(
        command: 'which unzip');
    if (result.stderr.isNotEmpty) {
      throw Exception('Error executing command: ${result.stderr}');
    }
    if (result.stdout.isEmpty || result.stdout.contains('not found') || result.stdout.contains('no unzip')) {
      return 'unzip not found on the server';
    }
    final String filePath = currentDirectory + "/" + name;
    final extractResult = await executeCommand( command: "unzip $filePath");
    if (extractResult.stderr.isNotEmpty) {
      throw Exception('Error extracting file: ${extractResult.stderr}');
    }
    return "File extracted successfully.";
  }

  static Future<List<RedirectionData>> getRedirections() async {
    List<RedirectionData> redirections = [];
    final result = await executeCommand(
      command: 'sudo iptables -t nat -L PREROUTING -n -v',
    );

    if (result.stderr.isNotEmpty) {
      throw Exception('Error executing command: ${result.stderr}');
    }

    final lines = result.stdout.split('\n');
    final regex = RegExp(
      r'REDIRECT\s+(?<protocol>\S+)\s+.*dpt:(?<dport>\d+)\s+redir\s+ports\s+(?<tport>\d+)',
    );

    for (final line in lines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        try {
          final dport = int.parse(match.namedGroup('dport')!);
          final tport = int.parse(match.namedGroup('tport')!);
          redirections.add(RedirectionData(dport: dport, tport: tport));
        } catch (e) {
          throw Exception('Failed to parse redirection data: $e');
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
        command: 'sudo iptables -t nat -A PREROUTING -p tcp --dport ${redirection.dport??""}' 
                ' -j REDIRECT --to-port ${redirection.tport??""}');
    }
  }

  static Future<ServerData?> DetectServers() async {
    //Detect node servers
    var result = await executeCommand(command: 'find $SERER_DETECT_DIR -type f -name "package.json" -exec dirname {} \\;');
    if (result.stderr.isNotEmpty) {
      throw Exception(result.stderr);
    }
    if (result.stdout.isNotEmpty) {
      return ServerData(
        isRunning: false,
        type: ServerType.node,
        pid: null,
        path: result.stdout.trim().split("\n").first,
      );
    }
    //Detect jar servers
    result = await executeCommand(command: 'find $SERER_DETECT_DIR -type f -name "*.jar"');
    if (result.stderr.isNotEmpty) {
      throw Exception(result.stderr);
    }
    if (result.stdout.isNotEmpty) {
      return ServerData(
        isRunning: false,
        type: ServerType.java,
        pid: null,
        path: result.stdout.trim().split("\n").first,
      );
    }
    return null;
  }

  static Future<void> startServer(ServerData server) async {
    final nodeInstalled  = await executeCommand(command: 'which node');
    if (server.type == ServerType.node && nodeInstalled.stderr.isNotEmpty) {
      throw Exception('Node not found on the server');
    }
    final jarInstalled  = await executeCommand(command: 'which java');
    if (server.type == ServerType.java && jarInstalled.stderr.isNotEmpty) {
      throw Exception('Java not found on the server');
    }
    if (server.type == ServerType.node) {
      // Check for Node.js installation
      final nodeInstalled = await executeCommand(command: 'which node');
      if (nodeInstalled.stderr.isNotEmpty) {
        throw Exception('Node not found on the server');
      }

      // Kill any existing instances
      await executeCommand(
        command: 'pkill -f "node ${server.path}/server.js"'
      );

      // Start Node with explicit foreground process creation
      final startScript = '''
        cd /home/super
        node ${server.path}/server.js &
        NODE_PID=\$!
        disown \$NODE_PID
        echo \$NODE_PID
      ''';
      
      // Write the script to a temp file and execute it
      final startResult = await executeCommand(
        command: '''
          echo '$startScript' > /tmp/start_node_server.sh
          chmod +x /tmp/start_node_server.sh
          bash /tmp/start_node_server.sh
        '''
      );

      if (startResult.stderr.isNotEmpty && !startResult.stderr.contains('disown')) {
        throw Exception('Error starting Node server: ${startResult.stderr}');
      }

      // Get PID of the Node process
      final psList = await executeCommand(
        command: 'ps -ef | grep "${server.path}/server.js" | grep -v grep'
      );
      
      print('Full process list output:');
      print(psList.stdout);
      
      if (psList.stdout.trim().isEmpty) {
        throw Exception('Failed to find Node process after starting');
      }
      
      // Extract PID from ps output
      final pid = int.parse(psList.stdout.trim().split(RegExp(r'\s+')).elementAt(1));
      server.pid = pid;
      
      // Verify process exists and get its state
      final processState = await executeCommand(
        command: 'ps -o state= -p $pid'
      );
      
      print('Process state: ${processState.stdout}');
      
      if (processState.stdout.trim().isEmpty) {
        throw Exception('Node process failed to start or terminated immediately');
      }
    }
    else if (server.type == ServerType.java) {
      // First, let's ensure no old instances are running
      await executeCommand(
        command: 'pkill -f "${server.path}"'
      );
      
      // Start Java with explicit foreground process creation
      final startScript = '''
        cd /home/super
        java -jar ${server.path} &
        JAVA_PID=\$!
        disown \$JAVA_PID
        echo \$JAVA_PID
      ''';
      
      // Write the script to a temp file and execute it
      executeCommand(
        command: '''
          echo '$startScript' > /tmp/start_server.sh
          chmod +x /tmp/start_server.sh
          bash /tmp/start_server.sh
        '''
      );
      
      // Get PID of the Java process
      final psList = await executeCommand(
        command: 'ps -ef | grep "${server.path}" | grep -v grep'
      );
      
      print('Full process list output:');
      print(psList.stdout);
      print(psList.stderr);
      
      if (psList.stdout.trim().isEmpty) {
        throw Exception('Failed to find Java process after starting');
      }
      
      // Extract PID from ps output
      final pid = int.parse(psList.stdout.trim().split(RegExp(r'\s+')).elementAt(1));
      server.pid = pid;
      
      // Verify process exists and get its state
      final processState = await executeCommand(
        command: 'ps -o state= -p $pid'
      );
      
      print('Process state: ${processState.stdout}');
      
      // Get parent process info
      final parentInfo = await executeCommand(
        command: 'ps -o ppid= -p $pid'
      );
      
      print('Parent process ID: ${parentInfo.stdout}');
    }
  
  server.isRunning = true;
  }

  static Future<void> stopServer(ServerData server) async {
    if (server.pid == null) {
      throw Exception('Server has no PID');
    }
    final result = await executeCommand(command: 'kill ${server.pid}');
    if (result.stderr.isNotEmpty) {
      throw Exception('Error stopping server: ${result.stderr}');
    }
    server.isRunning = false;
    server.pid = null;
  }

  static Future<void> restartServer(ServerData server) async {
    await stopServer(server);
    await startServer(server);
  }

}