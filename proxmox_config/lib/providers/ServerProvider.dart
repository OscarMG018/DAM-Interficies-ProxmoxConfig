import 'package:flutter/material.dart';
import '../models/ServerData.dart';
import '../utils/SSHUtils.dart';

class ServerProvider extends ChangeNotifier {
  ServerData? _server;
  bool _isLoading = false;
  bool _isServerOperation = false;
  String _currentOperation = '';

  ServerData? get server => _server;
  bool get isLoading => _isLoading;
  bool get isServerOperation => _isServerOperation;
  String get currentOperation => _currentOperation;

  Future<void> loadServer() async {
    _isLoading = true;
    _currentOperation = 'Refreshing';
    notifyListeners();

    try {
      _server = await SSHUtils.DetectServers();
      print("Server detected: ${_server?.type}");
    } catch (e) {
      print('Error loading server: $e');
    } finally {
      _isLoading = false;
      _currentOperation = '';
      notifyListeners();
    }
  }

  Future<void> startServer() async {
    if (_server == null) return;
    
    _isServerOperation = true;
    _currentOperation = 'Starting';
    notifyListeners();

    try {
      await SSHUtils.startServer(_server!);
      _server!.isRunning = true;
    } catch (e) {
      print('Error starting server: $e');
    } finally {
      _isServerOperation = false;
      _currentOperation = '';
      notifyListeners();
    }
  }

  Future<void> stopServer() async {
    if (_server == null) return;
    
    _isServerOperation = true;
    _currentOperation = 'Stopping';
    notifyListeners();

    try {
      await SSHUtils.stopServer(_server!);
      _server!.isRunning = false;
    } catch (e) {
      print('Error stopping server: $e');
    } finally {
      _isServerOperation = false;
      _currentOperation = '';
      notifyListeners();
    }
  }

  Future<void> restartServer() async {
    if (_server == null) return;
    
    _isServerOperation = true;
    _currentOperation = 'Restarting';
    notifyListeners();

    try {
      await SSHUtils.restartServer(_server!);
    } catch (e) {
      print('Error restarting server: $e');
    } finally {
      _isServerOperation = false;
      _currentOperation = '';
      notifyListeners();
    }
  }
} 