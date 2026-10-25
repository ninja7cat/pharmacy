import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'whatsapp_icon.dart';

class MobileActionBar extends StatelessWidget {
  final VoidCallback onWhatsApp;
  final VoidCallback onCall;
  final VoidCallback onLocation;

  final String whatsAppLabel;
  final String callLabel;
  final String locationLabel;

  /// The actual visual height of the action bar.
  static const double totalHeight = 78;

  const MobileActionBar({
    super.key,
    required this.onWhatsApp,
    required this.onCall,
    required this.onLocation,
    this.whatsAppLabel = 'WhatsApp',
    this.callLabel = 'Call',
    this.locationLabel = 'Location',
  });

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: totalHeight + bottomPadding,
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: bottomPadding > 0 ? bottomPadding : 12,
        ),
        child: Container(
          height: totalHeight - 12,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.ink.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: _Action(
                  icon: Icons.chat_rounded,
                  isWhatsApp: true,
                  label: whatsAppLabel,
                  color: const Color(0xFF25D366),
                  onTap: onWhatsApp,
                ),
              ),
              Expanded(
                child: _Action(
                  icon: Icons.phone_rounded,
                  label: callLabel,
                  color: AppTheme.sun,
                  onTap: onCall,
                ),
              ),
              Expanded(
                child: _Action(
                  icon: Icons.location_on_rounded,
                  label: locationLabel,
                  color: AppTheme.coral,
                  onTap: onLocation,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isWhatsApp;

  const _Action({
    this.isWhatsApp = false,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_Action> createState() => _ActionState();
}

class _ActionState extends State<_Action> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted) {
      return;
    }

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: Center(
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: _pressed ? 1 : 0.92),
                    borderRadius: BorderRadius.circular(_pressed ? 19 : 13),
                  ),
                  child: Center(
                    child: widget.isWhatsApp
                        ? const WhatsAppIcon(size: 23, color: AppTheme.ink)
                        : Icon(widget.icon, color: AppTheme.ink, size: 20),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
