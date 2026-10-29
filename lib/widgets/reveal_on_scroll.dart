import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Fades and slides its child in when it scrolls into view.
///
/// Built to be safe inside in-app browsers (Instagram, Facebook, WhatsApp),
/// where the viewport size can change or be reported wrongly right after load:
///  - it listens to the real scroll position of the page,
///  - it re-checks several times shortly after the first frame,
///  - it uses the larger of the scroll viewport and the screen height,
///  - if the viewport still has not been measured after [safetyTimeout],
///    the content is shown anyway so the page can never stay blank,
///  - content that was scrolled past without being seen appears instantly
///    (no animation), so it is never left invisible.
class RevealOnScroll extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  /// Starting offset in logical pixels. The horizontal part is mirrored
  /// automatically in right-to-left layouts.
  final Offset slide;

  /// Starting scale (1 = no scale animation).
  final double startScale;

  final Curve curve;
  final Duration safetyTimeout;

  /// Set to false to slide only (no fading). Fading uses an off-screen layer,
  /// which some phone in-app browsers draw badly, so phones skip it.
  final bool fade;

  const RevealOnScroll({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 700),
    this.delay = Duration.zero,
    this.slide = const Offset(0, 32),
    this.startScale = 1,
    this.curve = Curves.easeOutCubic,
    this.safetyTimeout = const Duration(seconds: 2),
    this.fade = true,
  });

  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<RevealOnScroll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  ScrollPosition? _position;
  final List<Timer> _timers = [];
  bool _started = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());

    // In-app browsers resize the viewport after load, so check again.
    for (final int ms in const [150, 400, 800, 1500]) {
      _timers.add(Timer(Duration(milliseconds: ms), _checkVisibility));
    }

    // Safety net: only when the viewport could not be measured at all.
    _timers.add(Timer(widget.safetyTimeout, _safetyReveal));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final ScrollPosition? newPosition = Scrollable.maybeOf(context)?.position;

    if (newPosition != _position) {
      _position?.removeListener(_checkVisibility);
      _position = newPosition;

      if (!_started) {
        _position?.addListener(_checkVisibility);
      }
    }
  }

  /// Once the reveal has started there is nothing left to watch: stop
  /// listening to every scroll frame and cancel the pending re-checks.
  void _stopWatching() {
    _position?.removeListener(_checkVisibility);

    for (final Timer timer in _timers) {
      timer.cancel();
    }

    _timers.clear();
  }

  void _safetyReveal() {
    if (!mounted || _started) {
      return;
    }

    final ScrollPosition? position = _position;

    final bool measured =
        position != null &&
        position.hasViewportDimension &&
        position.viewportDimension > 0;

    if (!measured) {
      _showInstantly();
    }
  }

  void _showInstantly() {
    if (!mounted) {
      return;
    }

    _started = true;
    _stopWatching();
    _controller.value = 1;
  }

  void _checkVisibility() {
    if (!mounted || _started) {
      return;
    }

    final RenderObject? renderObject = context.findRenderObject();

    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return;
    }

    final ScrollPosition? position = _position;

    // No scroll view above us: just show the content.
    if (position == null) {
      _startAnimation();
      return;
    }

    final RenderAbstractViewport? viewport = RenderAbstractViewport.maybeOf(
      renderObject,
    );

    // Layout is not measured yet (common in in-app browsers): try again later.
    if (viewport == null ||
        !position.hasViewportDimension ||
        position.viewportDimension <= 0) {
      return;
    }

    final double viewportHeight = math.max(
      position.viewportDimension,
      MediaQuery.sizeOf(context).height,
    );

    final double top =
        viewport.getOffsetToReveal(renderObject, 0.0).offset - position.pixels;
    final double bottom = top + renderObject.size.height;

    if (bottom <= 0) {
      // Already scrolled past without being seen: show it without animating.
      _showInstantly();
      return;
    }

    if (top < viewportHeight * 0.92) {
      _startAnimation();
    }
  }

  Future<void> _startAnimation() async {
    if (_started || !mounted) {
      return;
    }

    _started = true;
    _stopWatching();

    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
    }

    if (!mounted) {
      return;
    }

    await _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;

    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final double progress = _animation.value.clamp(0.0, 1.0).toDouble();
        final double remaining = 1.0 - progress;

        final Offset offset = Offset(
          widget.slide.dx * (rtl ? -1 : 1) * remaining,
          widget.slide.dy * remaining,
        );

        Widget result = Transform.translate(offset: offset, child: child);

        if (widget.startScale != 1) {
          result = Transform.scale(
            scale: widget.startScale + (1 - widget.startScale) * progress,
            child: result,
          );
        }

        if (!widget.fade) {
          return result;
        }

        return Opacity(opacity: progress, child: result);
      },
    );
  }

  @override
  void dispose() {
    _position?.removeListener(_checkVisibility);

    for (final Timer timer in _timers) {
      timer.cancel();
    }

    _controller.dispose();
    super.dispose();
  }
}
