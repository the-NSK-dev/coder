import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/code_result.dart';
import '../models/file_item.dart';

/// GitHub service for authentication, repository management, commit, and push.
class GithubService {
  String _token = '';
  String _username = '';

  void updateCredentials(String token, String username) {
    _token = token.isNotEmpty ? token : AppConfig.githubToken;
    _username = username.isNotEmpty ? username : AppConfig.githubUsername;
  }

  bool get isConfigured => _token.isNotEmpty && _username.isNotEmpty;

  Future<bool> validateToken(String token) async {
    if (token.isEmpty) return false;

    try {
      final github = GitHub(auth: Authentication.withToken(token));
      final user = await github.users.getCurrentUser();
      return user.login != null && user.login!.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String token) async {
    try {
      final headers = {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github.v3+json',
      };

      final userRes =
          await http.get(Uri.parse('https://api.github.com/user'), headers: headers);
      if (userRes.statusCode != 200) return null;
      final userData = jsonDecode(userRes.body);

      final orgsRes = await http.get(
          Uri.parse('https://api.github.com/user/orgs'),
          headers: headers);
      final orgsData =
          orgsRes.statusCode == 200 ? jsonDecode(orgsRes.body) as List : [];

      final starredRes = await http.get(
          Uri.parse('https://api.github.com/user/starred?per_page=100'),
          headers: headers);
      final starredData = starredRes.statusCode == 200
          ? jsonDecode(starredRes.body) as List
          : [];

      return {
        'username': userData['login'],
        'avatarUrl': userData['avatar_url'],
        'createdAt': userData['created_at'],
        'followers': userData['followers'],
        'following': userData['following'],
        'publicRepos': userData['public_repos'],
        'totalPrivateRepos': userData['total_private_repos'],
        'orgsCount': orgsData.length,
        'starredCount': starredData.length,
      };
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, String>>> listRepos(String token) async {
    if (token.isEmpty) return [];

    try {
      final github = GitHub(auth: Authentication.withToken(token));
      final repos = await github.repositories.listRepositories().toList();

      return repos
          .map((r) => {
                'name': r.name,
                'fullName': r.fullName,
                'description': r.description,
                'private': r.isPrivate.toString(),
                'url': r.htmlUrl,
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> createRepo(String token, String name,
      {bool isPrivate = true}) async {
    try {
      final github = GitHub(auth: Authentication.withToken(token));
      final repo = await github.repositories.createRepository(CreateRepository(
        name,
        description: 'Created by Coder IDE',
        private: isPrivate,
      ));
      return repo.fullName;
    } catch (_) {
      return null;
    }
  }

  Future<List<FileItem>> loadFilesFromDisk(String projectPath) async {
    final items = <FileItem>[];
    final dir = Directory(projectPath);
    if (!await dir.exists()) return items;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final rel = entity.path
            .substring(projectPath.length)
            .replaceAll(RegExp(r'^[/\\]'), '');
        if (_shouldIgnore(rel)) continue;
        try {
          final content = await entity.readAsString();
          items.add(FileItem(
            path: rel.replaceAll('\\', '/'),
            name: rel.split(Platform.pathSeparator).last,
            content: content,
          ));
        } catch (_) {}
      }
    }
    return items;
  }

  bool _shouldIgnore(String relPath) {
    const ignore = {
      '.git',
      'node_modules',
      'build',
      '.dart_tool',
      'dist',
      '.next',
      '.coder',
    };
    return ignore.any((i) => relPath.contains(i));
  }

  /// Push project files to GitHub — creates repo if needed or uses [repoSlug].
  Future<bool> pushProject(
    CodeResult code, {
    String? repoSlug,
    void Function(double progress)? onProgress,
  }) async {
    updateCredentials(AppConfig.githubToken, AppConfig.githubUsername);

    if (!isConfigured) return false;

    CodeResult toPush = code;
    if (AppConfig.currentProjectDir != null) {
      final diskFiles =
          await loadFilesFromDisk(AppConfig.currentProjectDir!);
      if (diskFiles.isNotEmpty) {
        toPush = CodeResult(
          projectName: code.projectName,
          version: code.version,
          files: diskFiles,
          currentFilePath: code.currentFilePath,
          projectType: code.projectType,
        );
      }
    }

    if (toPush.files.isEmpty) return false;

    try {
      final github = GitHub(auth: Authentication.withToken(_token));
      final currentUser = await github.users.getCurrentUser();
      final login = currentUser.login!;
      _username = login;

      Repository repo;
      String fullName;

      if (repoSlug != null && repoSlug.isNotEmpty) {
        fullName = repoSlug.contains('/') ? repoSlug : '$login/$repoSlug';
        final parts = fullName.split('/');
        repo = await github.repositories
            .getRepository(RepositorySlug(parts[0], parts[1]));
      } else {
        final repoName =
            toPush.projectName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
        try {
          repo = await github.repositories.createRepository(CreateRepository(
            repoName,
            description: 'Generated by Coder',
            private: true,
          ));
        } catch (_) {
          repo = await github.repositories
              .getRepository(RepositorySlug(login, repoName));
        }
        fullName = repo.fullName;
      }

      final total = toPush.files.length;
      for (var i = 0; i < total; i++) {
        final file = toPush.files[i];
        final contentBytes = utf8.encode(file.content);
        final base64Content = base64Encode(contentBytes);
        final normalizedPath = file.path.replaceAll('\\', '/');

        try {
          await github.repositories.createFile(
            repo.slug(),
            CreateFile(
              path: normalizedPath,
              content: base64Content,
              message: 'Update ${file.name} via Coder',
            ),
          );
        } catch (_) {
          try {
            final existing = await github.repositories.getContents(
              repo.slug(),
              normalizedPath,
            );
            final sha = existing.file?.sha;
            if (sha == null) {
              debugPrint('GitHub push: no sha for $normalizedPath');
              return false;
            }
            await github.repositories.updateFile(
              repo.slug(),
              normalizedPath,
              'Update ${file.name} via Coder',
              base64Content,
              sha,
            );
          } catch (e) {
            debugPrint('GitHub push file failed: $normalizedPath — $e');
            return false;
          }
        }

        onProgress?.call((i + 1) / total);
      }

      AppConfig.githubUsername = login;
      return true;
    } catch (e) {
      debugPrint('GitHub pushProject error: $e');
      return false;
    }
  }

  String repoUrl(CodeResult code, {String? repoSlug}) {
    if (repoSlug != null && repoSlug.isNotEmpty) {
      if (repoSlug.contains('/')) {
        return 'https://github.com/$repoSlug';
      }
      final username = _username.isNotEmpty ? _username : 'user';
      return 'https://github.com/$username/$repoSlug';
    }
    final repoName =
        code.projectName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
    final username = _username.isNotEmpty ? _username : 'user';
    return 'https://github.com/$username/$repoName';
  }
}
