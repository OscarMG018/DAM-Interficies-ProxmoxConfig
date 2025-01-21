import 'package:proxmox_config/models/ServerType.dart';

class ServerData {
  bool isRunning;
  ServerType type;
  int? pid;
  String path; // file if jar, folder if node

  ServerData({
    required this.isRunning,
    required this.type,
    required this.pid,
    required this.path,
  });
}