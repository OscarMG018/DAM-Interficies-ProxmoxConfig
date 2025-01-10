import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';

class SSHUtils {
  static Utf8Codec utf8 = const Utf8Codec();

  static Future<SSHClient> connect({
    required String host,
    required String username,
    required String password,
    required int port,
  }) async {
    try {
      final client = SSHClient(
        await SSHSocket.connect(host, port),
        username: username,
        onPasswordRequest: () => password,
      );
      return client;
    } catch (e) {
      throw Exception('Failed to connect to $host:$port - $e');
    }
  }

  static Future<({String stdout, String stderr})> executeCommand({
    required SSHClient client,
    required String command,
  }) async {
    try {
      final session = await client.execute(command);
      final stdout = await utf8.decodeStream(session.stdout);
      final stderr = await utf8.decodeStream(session.stderr);
      await session.done;
      session.close();
      return (stdout: stdout, stderr: stderr);
    } catch (e) {
      throw Exception('Error executing command "$command": $e');
    }
  }

  static void disconnect(SSHClient client) {
    client.close();
  }
}