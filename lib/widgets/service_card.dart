import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A service card with its own soft colour. On hover (or press on touch
/// screens) it fills with the brand green, the icon tilts and the arrow
/// slides, so the page feels responsive under the finger or the mouse.
class ServiceCard extends StatefulWidget {
  final String icon;
  final IconData? iconData;
  final String title;
  final String description;

  /// Small number shown in the corner, e.g. "01".
  final String number;

  /// Resting background colour of the card.
  final Color tint;

  /// When set, the card is tappable and shows an arrow.
  final VoidCallback? onTap;

  /// Small label shown next to the arrow (e.g. "Ask us").
  final String? actionLabel;

  const ServiceCard({
    super.key,
    required this.icon,
    this.iconData,
    required this.title,
    required this.description,
    this.number = '',
    this.tint = AppTheme.mint,
    this.onTap,
    this.actionLabel,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _active => _hovered || _pressed;

  @override
  Widget build(BuildContext context) {
    final bool tappable = widget.onTap != null;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;

    final TextStyle base = DefaultTextStyle.of(context).style;

    final Color titleColor = _active ? Colors.white : AppTheme.textPrimary;
    final Color bodyColor = _active
        ? Colors.white.withValues(alpha: 0.86)
        : AppTheme.textSecondary;

    return MouseRegion(
      cursor: tappable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: tappable ? (_) => setState(() => _pressed = true) : null,
        onTapUp: tappable ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: tappable ? () => setState(() => _pressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _active ? -6.0 : 0.0, 0),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: _active ? AppTheme.primary : widget.tint,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: _active ? 0.28 : 0),
                blurRadius: _active ? 30 : 0,
                offset: Offset(0, _active ? 16 : 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedRotation(
                    turns: _active ? -0.035 : 0,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: _active
                            ? Colors.white.withValues(alpha: 0.16)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: widget.iconData != null
                            ? Icon(
                                widget.iconData,
                                size: 28,
                                color: _active
                                    ? Colors.white
                                    : AppTheme.primary,
                              )
                            : Text(
                                widget.icon,
                                style: const TextStyle(fontSize: 25),
                              ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (widget.number.isNotEmpty)
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 280),
                      style: base.copyWith(
                        fontSize: 34,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: _active
                            ? Colors.white.withValues(alpha: 0.28)
                            : AppTheme.ink.withValues(alpha: 0.12),
                      ),
                      child: Text(widget.number),
                    ),
                ],
              ),

              const SizedBox(height: 26),

              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 280),
                style: base.copyWith(
                  fontSize: 20,
                  height: rtl ? 1.4 : 1.25,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
                child: Text(widget.title),
              ),

              const SizedBox(height: 10),

              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 280),
                style: base.copyWith(
                  fontSize: 14.5,
                  height: 1.65,
                  fontWeight: FontWeight.w400,
                  color: bodyColor,
                ),
                child: Text(widget.description),
              ),

              if (tappable) ...[
                const SizedBox(height: 22),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.actionLabel != null) ...[
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 280),
                        style: base.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _active ? Colors.white : AppTheme.primary,
                        ),
                        child: Text(widget.actionLabel!),
                      ),
                      const SizedBox(width: 8),
                    ],
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      offset: Offset(_active ? (rtl ? -0.25 : 0.25) : 0, 0),
                      child: Icon(
                        rtl
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded,
                        size: 19,
                        color: _active ? Colors.white : AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
