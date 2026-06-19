import 'dart:async';
import 'dart:io';
import 'package:process_run/process_run.dart';

class ProcessRunnerService {
  Process? _runningProcess;

  /// Runs a shell command in a specified directory.
  Future<String> runCommand(
    String command,
    String workingDirectory, {
    int timeoutSeconds = 120,
  }) async {
    try {
      if (Platform.isWindows) {
        return await _runWindows(command, workingDirectory, timeoutSeconds);
      }

      final results = await run(
        command,
        workingDirectory: workingDirectory,
      ).timeout(Duration(seconds: timeoutSeconds));

      if (results.isEmpty) return '';

      final result = results.first;
      if (result.exitCode != 0) {
        throw Exception(
            'Command failed (${result.exitCode}): ${result.stderr}');
      }
      return result.stdout.toString();
    } catch (e) {
      throw Exception('Failed to execute: $command\n$e');
    }
  }

  Future<String> _runWindows(
    String command,
    String workingDirectory,
    int timeoutSeconds,
  ) async {
    final process = await Process.start(
      'cmd.exe',
      ['/c', command],
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    _runningProcess = process;

    final buffer = StringBuffer();
    final subOut = process.stdout.listen((data) {
      buffer.write(String.fromCharCodes(data));
    });
    final subErr = process.stderr.listen((data) {
      buffer.write(String.fromCharCodes(data));
    });

    final exitCode = await process.exitCode
        .timeout(Duration(seconds: timeoutSeconds), onTimeout: () {
      process.kill();
      throw TimeoutException('Command timed out: $command');
    });

    await subOut.cancel();
    await subErr.cancel();
    _runningProcess = null;

    if (exitCode != 0) {
      throw Exception('Command failed ($exitCode): $buffer');
    }
    return buffer.toString();
  }

  Future<void> stop() async {
    _runningProcess?.kill();
    _runningProcess = null;
  }
}
