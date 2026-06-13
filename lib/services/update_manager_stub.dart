import 'package:flutter/material.dart';
import 'update_info.dart';

class UpdateDownloadState {
  final double progress;
  final int receivedBytes;
  final int totalBytes;
  final String status;
  final String? error;

  const UpdateDownloadState({
    required this.progress,
    required this.receivedBytes,
    required this.totalBytes,
    required this.status,
    this.error,
  });

  static const idle = UpdateDownloadState(
    progress: 0,
    receivedBytes: 0,
    totalBytes: 0,
    status: 'idle',
  );
}

class UpdateManager {
  static final UpdateManager instance = UpdateManager._();
  UpdateManager._();

  final UpdateDownloadState _state = UpdateDownloadState.idle;
  UpdateDownloadState get state => _state;

  UpdateInfo? get availableUpdate => null;
  bool get isUpdateReady => false;

  Stream<UpdateDownloadState> get progressStream => const Stream.empty();

  Future<void> initialize() async {}
  Future<void> checkForUpdate() async {}
  Future<void> downloadAndInstall(BuildContext context) async {}
  Future<dynamic> getDownloadedApk(String version) async => null;
}
