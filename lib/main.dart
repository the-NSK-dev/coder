import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'providers/ide_provider.dart';
import 'providers/workspace_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/editor_provider.dart';
import 'providers/preview_provider.dart';
import 'providers/github_provider.dart';
import 'providers/agent_activity_provider.dart';
import 'services/persistence_service.dart';
import 'models/project_folder.dart';
import 'theme/app_theme.dart';
import 'theme/animations.dart';
import 'screens/s1_splash_screen.dart';
import 'screens/s1b_startup_choice_screen.dart';
import 'screens/s1c_terms_screen.dart';
import 'screens/s2_main_empty_screen.dart';
import 'screens/s5_file_manager_screen.dart';
import 'screens/s6_preview_modal.dart';
import 'screens/s7_preview_fullscreen.dart';
import 'screens/s8_profile_screen.dart';
import 'screens/s9_connect_github_screen.dart';
import 'screens/s10_github_repo_screen.dart';
import 'screens/s11_code_editor_screen.dart';
import 'screens/s12_github_connected_screen.dart';
import 'screens/s13_github_push_success_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PersistenceService().loadAppConfig();
  runApp(const CoderApp());
}

/// Helper to build custom page transitions for GoRouter.
CustomTransitionPage<void> _buildPage(
  Widget child, {
  Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
      transitionBuilder,
}) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: AppAnimations.defaultDuration,
    reverseTransitionDuration: AppAnimations.defaultDuration,
    transitionsBuilder: transitionBuilder ?? AppAnimations.fadeTransition,
  );
}

final _router = GoRouter(
  initialLocation: '/startup',

  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _buildPage(
        // In a real app we would check persistence.
        S1SplashScreen(onFinished: () => context.go('/terms')),
      ),
    ),
    GoRoute(
      path: '/terms',
      pageBuilder: (context, state) => _buildPage(
        const S1cTermsScreen(),
      ),
    ),
    GoRoute(
      path: '/startup',
      pageBuilder: (context, state) => _buildPage(
        const S1bStartupChoiceScreen(),
      ),
    ),
    GoRoute(
      path: '/main',
      pageBuilder: (context, state) => _buildPage(
        const S2MainEmptyScreen(),
        transitionBuilder: AppAnimations.slideUpTransition,
      ),
    ),
    // /main/chat and /main/chat/expanded are now handled within /main
    // (unified workspace screen). Redirect any deep links.
    GoRoute(
      path: '/main/chat',
      redirect: (context, state) => '/main',
    ),
    GoRoute(
      path: '/main/chat/expanded',
      redirect: (context, state) => '/main',
    ),
    GoRoute(
      path: '/files',
      pageBuilder: (context, state) => _buildPage(
        const S5FileManagerScreen(),
        transitionBuilder: AppAnimations.slideRightTransition,
      ),
    ),
    GoRoute(
      path: '/preview/modal',
      pageBuilder: (context, state) => _buildPage(
        const S6PreviewModal(),
        transitionBuilder: AppAnimations.scaleTransition,
      ),
    ),
    GoRoute(
      path: '/preview/full',
      pageBuilder: (context, state) => _buildPage(
        const S7PreviewFullscreen(),
        transitionBuilder: AppAnimations.slideUpTransition,
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => _buildPage(
        const S8ProfileScreen(),
        transitionBuilder: AppAnimations.slideRightTransition,
      ),
    ),
    GoRoute(
      path: '/github/connect',
      pageBuilder: (context, state) => _buildPage(
        const S9ConnectGithubScreen(),
        transitionBuilder: AppAnimations.slideRightTransition,
      ),
    ),
    GoRoute(
      path: '/github/repo',
      pageBuilder: (context, state) => _buildPage(
        const S10GithubRepoScreen(),
        transitionBuilder: AppAnimations.slideRightTransition,
      ),
    ),
    GoRoute(
      path: '/github/connected',
      pageBuilder: (context, state) => _buildPage(
        const S12GithubConnectedScreen(),
        transitionBuilder: AppAnimations.slideRightTransition,
      ),
    ),
    GoRoute(
      path: '/github/push_success',
      pageBuilder: (context, state) => _buildPage(
        const S13GithubPushSuccessScreen(),
        transitionBuilder: AppAnimations.scaleTransition,
      ),
    ),
    GoRoute(
      path: '/editor',
      pageBuilder: (context, state) {
        final filePath = state.extra as String? ?? '';
        return _buildPage(
          S11CodeEditorScreen(filePath: filePath),
          transitionBuilder: AppAnimations.slideRightTransition,
        );
      },
    ),
  ],
);

class CoderApp extends StatefulWidget {
  const CoderApp({super.key});

  @override
  State<CoderApp> createState() => _CoderAppState();
}

class _CoderAppState extends State<CoderApp> {
  bool _splashComplete = false;
  bool _providersWired = false;

  void _wireProviders(BuildContext context) {
    if (_providersWired) return;
    _providersWired = true;

    final chat = context.read<ChatProvider>();
    final agentActivity = context.read<AgentActivityProvider>();
    final ide = context.read<IdeProvider>();
    final workspace = context.read<WorkspaceProvider>();
    final preview = context.read<PreviewProvider>();

    chat.bindAgentActivity(agentActivity);

    chat.onFilesGenerated = (result) async {
      await ide.saveGeneratedFiles(result.files);
      await workspace.refreshTree();
      if (AppConfig.currentProjectDir != null) {
        await preview.startPreview(AppConfig.currentProjectDir!);
      }
    };

    chat.workspaceContextProvider = () {
      final tree = workspace.projectTree;
      if (tree == null) return '';
      return _summarizeTree(tree, workspace.currentProjectPath ?? '');
    };

    workspace.onProjectLoaded = () async {
      await chat.loadProjectChat();
    };

    chat.connectBandRoom();
  }

  String _summarizeTree(ProjectFolder tree, String rootPath) {
    final files = <String>[];
    void walk(ProjectFolder node) {
      for (final f in node.files) {
        files.add(f.path);
      }
      for (final sub in node.subfolders) {
        walk(sub);
      }
    }
    walk(tree);
    return files.take(50).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<IdeProvider>(create: (_) => IdeProvider()),
        ChangeNotifierProvider<WorkspaceProvider>(create: (_) {
          final provider = WorkspaceProvider();
          provider.initialize();
          return provider;
        }),
        ChangeNotifierProvider<ChatProvider>(create: (_) => ChatProvider()),
        ChangeNotifierProvider<AgentActivityProvider>(
            create: (_) => AgentActivityProvider()),
        ChangeNotifierProvider<EditorProvider>(create: (_) => EditorProvider()),
        ChangeNotifierProvider<PreviewProvider>(create: (_) => PreviewProvider()),
        ChangeNotifierProvider<GitHubProvider>(create: (_) {
          final provider = GitHubProvider();
          provider.initialize();
          return provider;
        }),
      ],
      child: Builder(
        builder: (context) {
          _wireProviders(context);
          return _splashComplete
              ? MaterialApp.router(
                  key: ValueKey(AppConfig.darkTheme),
                  title: 'Coder',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.theme,
                  routerConfig: _router,
                )
              : MaterialApp(
                  key: ValueKey(AppConfig.darkTheme),
                  title: 'Coder',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.theme,
                  home: S1SplashScreen(
                    onFinished: () {
                      if (mounted) {
                        setState(() => _splashComplete = true);
                      }
                    },
                  ),
                );
        },
      ),
    );
  }
}
