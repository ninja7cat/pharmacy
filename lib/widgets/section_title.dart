import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Section heading with a small coloured eyebrow label above the title.
class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final bool centered;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final double width = MediaQuery.sizeOf(context).width;

    final TextAlign align = centered ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 3,
                decoration: BoxDecoration(
                  color: AppTheme.coral,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                eyebrow!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: rtl ? 0 : 1.4,
                  color: AppTheme.coral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        Text(
          title,
          textAlign: align,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: width < 700 ? 30 : 40,
            height: rtl ? 1.3 : 1.1,
            letterSpacing: rtl ? 0 : -1,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              subtitle!,
              textAlign: align,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ],
    );
  }
}
