import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import '../theme/app_colors.dart';
import '../config/app_config.dart';
import 'premium_tab_bar.dart';

class IdeBottomPanel extends StatefulWidget {
  final double scale;
  const IdeBottomPanel({super.key, required this.scale});

  @override
  State<IdeBottomPanel> createState() => _IdeBottomPanelState();
}

class _IdeBottomPanelState extends State<IdeBottomPanel> {
  int _activeTab = 0;
  bool _isExpanded = false;
  final ScrollController _scrollController = ScrollController();
  
  final List<String> _tabs = ['Terminal', 'Problems', 'Output', 'Git'];
  
  // Terminal state
  final TextEditingController _terminalController = TextEditingController();
  final List<String> _terminalOutput = ['Coder Terminal Ready.'];
  bool _isRunningCommand = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _terminalController.dispose();
    super.dispose();
  }

  Future<void> _runCommand(String cmd) async {
    if (cmd.trim().isEmpty) return;
    setState(() {
      _terminalOutput.add('\n\$ $cmd');
      _isRunningCommand = true;
    });
    
    _terminalController.clear();
    
    try {
      final parts = cmd.split(' ');
      final executable = parts.first;
      final args = parts.sublist(1);
      
      final result = await runExecutableArguments(
        executable,
        args,
        workingDirectory: AppConfig.currentProjectDir,
      );
      
      if (mounted) {
        setState(() {
          if (result.stdout.toString().isNotEmpty) {
            _terminalOutput.add(result.stdout.toString());
          }
          if (result.stderr.toString().isNotEmpty) {
            _terminalOutput.add('Error: ${result.stderr.toString()}');
          }
          _isRunningCommand = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _terminalOutput.add('Command not found or failed: $e');
          _isRunningCommand = false;
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tab Header
        Container(
          height: 36 * s,
          decoration: const BoxDecoration(
            color: Color(0xFF161B22),
            border: Border(
              top: BorderSide(color: Color(0xFF30363D)),
              bottom: BorderSide(color: Color(0xFF30363D)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: PremiumTabBar(
                  tabs: _tabs.asMap().entries.map((e) => TabItem(
                    id: e.key.toString(),
                    label: e.value.toUpperCase(),
                  )).toList(),
                  activeTabId: _activeTab.toString(),
                  onTabSelected: (id) {
                    final i = int.parse(id);
                    setState(() {
                      if (_activeTab == i) {
                        _isExpanded = !_isExpanded;
                      } else {
                        _activeTab = i;
                        _isExpanded = true;
                      }
                    });
                  },
                ),
              ),
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                  color: Colors.white60,
                  size: 20 * s,
                ),
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
              ),
              SizedBox(width: 8 * s),
            ],
          ),
        ),
        
        // Expanded Content Area
        if (_isExpanded)
          Container(
            height: 250 * s,
            color: const Color(0xFF0D1117),
            width: double.infinity,
            child: _buildTabContent(s),
          ),
      ],
    );
  }

  Widget _buildTabContent(double s) {
    switch (_activeTab) {
      case 0: // Terminal
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(12 * s),
                itemCount: _terminalOutput.length,
                itemBuilder: (context, i) {
                  return Text(
                    _terminalOutput[i],
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'monospace',
                      fontSize: 12 * s,
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
              color: const Color(0xFF161B22),
              child: Row(
                children: [
                  Text('\$ ', style: TextStyle(color: AppColors.accentBlue, fontFamily: 'monospace', fontSize: 13 * s)),
                  Expanded(
                    child: TextField(
                      controller: _terminalController,
                      style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13 * s),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: _runCommand,
                    ),
                  ),
                  if (_isRunningCommand)
                    SizedBox(
                      width: 14 * s,
                      height: 14 * s,
                      child: const CircularProgressIndicator(color: AppColors.accentBlue, strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ],
        );
      case 1: // Problems
        return Center(
          child: Text('No problems have been detected in the workspace.', style: TextStyle(color: Colors.white54, fontSize: 12 * s)),
        );
      case 2: // Output
        return Center(
          child: Text('Output console is empty.', style: TextStyle(color: Colors.white54, fontSize: 12 * s)),
        );
      case 3: // Git
        return Center(
          child: Text('Git repository not initialized.', style: TextStyle(color: Colors.white54, fontSize: 12 * s)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
