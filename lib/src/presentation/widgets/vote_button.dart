import 'package:flutter/material.dart';

class PostVoteButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color color;
  final Color activeColor;
  final String semanticLabel;
  final VoidCallback onTap;

  const PostVoteButton({
    super.key,
    required this.icon,
    required this.active,
    required this.color,
    required this.activeColor,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: semanticLabel,
      enabled: true,
      child: Tooltip(
        message: semanticLabel,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: Center(child: Icon(icon, size: 20, color: color)),
          ),
        ),
      ),
    );
  }
}
