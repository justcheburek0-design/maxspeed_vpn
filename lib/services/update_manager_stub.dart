import 'package:flutter/material.dart';
import 'update_info.dart';

/// Stub for web — no-op UpdateManager.
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

  UpdateInfo? get availableUpdate => null;
  Stream<UpdateDownloadState> get progressStream => const Stream.empty();

  Future<void> initialize() async {}
  Future<void> checkForUpdate() async {}
  Future<void> downloadAndInstall(BuildContext context) async {}
}
