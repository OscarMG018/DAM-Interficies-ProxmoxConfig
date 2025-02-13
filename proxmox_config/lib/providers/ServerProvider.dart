import 'package:flutter/material.dart';
import '../models/ServerData.dart';
import '../utils/SSHUtils.dart';

class ServerProvider extends ChangeNotifier {
  ServerData? _server;
  bool _isLoading = false;

  ServerData? get server => _server;
  bool get isLoading => _isLoading;

  Future<void> loadServer() async {
    _isLoading = true;
    notifyListeners();

    try {
      _server = await SSHUtils.DetectServers();
      print("Server detected: ${_server?.type}");
    } catch (e) {
      print('Error loading server: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startServer() async {
    if (_server == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      await SSHUtils.startServer(_server!);
      _server!.isRunning = true;
    } catch (e) {
      print('Error starting server: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> stopServer() async {
    if (_server == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      await SSHUtils.stopServer(_server!);
      _server!.isRunning = false;
    } catch (e) {
      print('Error stopping server: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restartServer() async {
    if (_server == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      await SSHUtils.restartServer(_server!);
    } catch (e) {
      print('Error restarting server: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 