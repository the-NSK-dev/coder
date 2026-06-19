import 'package:flutter/material.dart';

class TabItem {
  final String id;
  final String label;
  final IconData? icon;
  final bool isDirty;
  final bool hasError;
  
  TabItem({
    required this.id, 
    required this.label, 
    this.icon,
    this.isDirty = false, 
    this.hasError = false
  });
}

class PremiumTabBar extends StatefulWidget {
  final List<TabItem> tabs;
  final String activeTabId;
  final ValueChanged<String> onTabSelected;
  final ValueChanged<String>? onTabClosed;
  final bool scrollable;

  const PremiumTabBar({
    required this.tabs,
    required this.activeTabId,
    required this.onTabSelected,
    this.onTabClosed,
    this.scrollable = true,
    super.key,
  });

  @override
  State<PremiumTabBar> createState() => _PremiumTabBarState();
}

class _PremiumTabBarState extends State<PremiumTabBar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisSize: widget.scrollable ? MainAxisSize.max : MainAxisSize.min,
      children: widget.tabs.map((tab) => _buildTab(tab)).toList(),
    );

    if (widget.scrollable) {
      content = Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: content,
          ),
          // Fade-out gradients
          Positioned(
            left: 0, top: 0, bottom: 0, width: 24,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF000000), Colors.transparent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0, top: 0, bottom: 0, width: 24,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xFF000000)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0F),
        border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF), width: 1)),
      ),
      child: content,
    );
  }

  Widget _buildTab(TabItem tab) {
    final isActive = tab.id == widget.activeTabId;
    final hoverState = ValueNotifier<bool>(false);

    return MouseRegion(
      onEnter: (_) => hoverState.value = true,
      onExit: (_) => hoverState.value = false,
      child: ValueListenableBuilder<bool>(
        valueListenable: hoverState,
        builder: (context, isHovering, child) {
          return GestureDetector(
            onTap: () => widget.onTabSelected(tab.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? const Color(0x143B6FE8) : (isHovering ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? const Color(0xFF3B6FE8) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tab.icon != null) ...[
                    Icon(
                      tab.icon,
                      size: 14,
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    tab.label,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (widget.onTabClosed != null || tab.isDirty) ...[
                    const SizedBox(width: 8),
                    _buildCloseOrDirtyIndicator(tab, isActive, isHovering),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCloseOrDirtyIndicator(TabItem tab, bool isActive, bool isHovering) {
    if (tab.isDirty && !isHovering) {
      return Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(color: Color(0xFFEAB308), shape: BoxShape.circle),
      );
    }
    
    if (widget.onTabClosed != null && (isActive || isHovering)) {
      return GestureDetector(
        onTap: () => widget.onTabClosed!(tab.id),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.transparent,
          ),
          child: Icon(Icons.close_rounded, size: 14, color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6)),
        ),
      );
    }
    
    return const SizedBox(width: 14); // Placeholder to prevent jumping
  }
}
