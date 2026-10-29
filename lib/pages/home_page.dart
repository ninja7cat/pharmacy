import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:url_launcher/url_launcher.dart';

import '../config/business_config.dart';
import '../config/opening_hours.dart';
import '../l10n/app_strings.dart';
import '../l10n/language_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/reveal_on_scroll.dart';
import '../widgets/section_title.dart';
import '../widgets/service_card.dart';
import '../widgets/social_button.dart';
import '../widgets/whatsapp_icon.dart';

/// Turns every "fade and slide in while scrolling" animation on or off.
///
/// Leave it `true` for the full lively experience. If a strange blank-page
/// problem ever shows up in an in-app browser again, set it to `false`:
/// everything is then visible immediately.
const bool kScrollReveal = true;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// Live "open / closed" information, calculated in the pharmacy's own time.
class _OpenStatus {
  final bool isOpen;
  final String title;
  final String detail;
  final int weekday;

  const _OpenStatus({
    required this.isOpen,
    required this.title,
    required this.detail,
    required this.weekday,
  });
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _servicesKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  final ScrollController _scrollController = ScrollController();

  late final AnimationController _heroEntrance;
  late final AnimationController _heroFloat;
  // Language-switch curtain: 0 = hidden, 0 to 1 = sweeping in,
  // 1 to 2 = sweeping out the other side.
  late final AnimationController _langWipe;
  bool _switchingLanguage = false;
  bool _wipeFromRight = false;
  String _wipeLabel = '';
  int _switchToken = 0;

  // Smooth mouse-wheel scrolling (desktop browsers).
  late final Ticker _wheelTicker;
  Duration _lastWheelTick = Duration.zero;
  double _wheelTarget = 0;

  final ValueNotifier<double> _scrollProgress = ValueNotifier<double>(0);
  final ValueNotifier<int> _minuteTick = ValueNotifier<int>(0);

  // Bumped when the header / scroll-to-top / marquee state changes while
  // scrolling, so only those small parts rebuild instead of the whole page.
  final ValueNotifier<int> _scrollUi = ValueNotifier<int>(0);

  Timer? _statusTimer;

  bool _scrolled = false;
  bool _showScrollToTop = false;
  bool _mobileMenuOpen = false;
  bool _nearTop = true;
  bool _heroAnimating = true;
  int _activeSection = 0;

  AppStrings get _t => AppStrings(LanguageController.instance.isArabic);
  bool get _ar => LanguageController.instance.isArabic;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_handleScroll);
    LanguageController.instance.addListener(_onLanguageChanged);

    _wheelTicker = createTicker(_onWheelTick);

    _heroEntrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _heroFloat = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );

    _langWipe = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: 2,
      value: 0,
      duration: const Duration(milliseconds: 500),
    );

    _statusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _minuteTick.value++;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _heroEntrance.forward();
      _heroFloat.repeat();

      // Safety net for in-app browsers (Instagram, Facebook...): if the
      // entrance animation is stalled, show the hero anyway.
      Future<void>.delayed(const Duration(milliseconds: 2200), () {
        if (mounted && _heroEntrance.value < 1) {
          _heroEntrance.value = 1;
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();

    LanguageController.instance.removeListener(_onLanguageChanged);
    _statusTimer?.cancel();
    _heroEntrance.dispose();
    _heroFloat.dispose();
    _langWipe.dispose();
    _wheelTicker.dispose();
    _scrollProgress.dispose();
    _minuteTick.dispose();
    _scrollUi.dispose();

    super.dispose();
  }

  /// A brand-coloured curtain sweeps across the screen, the language (and
  /// reading direction) changes while the page is covered, then the curtain
  /// carries on off the other side to reveal the new language.
  Future<void> _switchLanguage() async {
    if (_switchingLanguage) {
      return;
    }

    _switchingLanguage = true;
    _closeMobileMenu();

    final int token = ++_switchToken;
    bool toggled = false;

    void toggleOnce() {
      if (!toggled) {
        toggled = true;
        LanguageController.instance.toggle();
        _replayHeroEntrance();
      }
    }

    // Safety net: never leave the curtain over the page if frames stall.
    Future<void>.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted || token != _switchToken || !_switchingLanguage) {
        return;
      }

      toggleOnce();
      _langWipe.value = 0;
      _switchingLanguage = false;
    });

    try {
      // Heading to Arabic (right-to-left)? Sweep in from the right.
      _wipeFromRight = !_ar;
      _wipeLabel = _t.languageSwitchLabel;

      await _langWipe.animateTo(
        1,
        duration: const Duration(milliseconds: 460),
        curve: Curves.easeInOutCubic,
      );

      if (!mounted || token != _switchToken || !_switchingLanguage) {
        return;
      }

      toggleOnce();

      await Future<void>.delayed(const Duration(milliseconds: 160));

      if (!mounted || token != _switchToken || !_switchingLanguage) {
        return;
      }

      await _langWipe.animateTo(
        2,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
      );
    } finally {
      if (mounted && token == _switchToken) {
        _langWipe.value = 0;
        _switchingLanguage = false;
      }
    }
  }

  /// Plays the hero entrance again so the new language arrives with a bit of
  /// life, as the curtain leaves.
  void _replayHeroEntrance() {
    if (!_scrollController.hasClients || _scrollController.offset > 500) {
      return;
    }

    _heroEntrance.forward(from: 0);

    Future<void>.delayed(const Duration(milliseconds: 2400), () {
      if (mounted && _heroEntrance.value < 1) {
        _heroEntrance.value = 1;
      }
    });
  }

  Widget _languageTransition(Widget child) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _langWipe,
              builder: (context, _) {
                final double v = _langWipe.value;

                if (v <= 0) {
                  return const SizedBox.shrink();
                }

                final double width = MediaQuery.sizeOf(context).width;

                final double x = _wipeFromRight
                    ? (v <= 1 ? width * (1 - v) : -width * (v - 1))
                    : (v <= 1 ? -width * (1 - v) : width * (v - 1));

                return ClipRect(
                  child: Transform.translate(
                    offset: Offset(x, 0),
                    child: _languageCurtain(),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _languageCurtain() {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primary, AppTheme.primaryDark],
          ),
        ),
        child: Stack(
          children: [
            // Gold edge on the side the curtain is travelling toward.
            Align(
              alignment: _wipeFromRight
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Container(
                width: 8,
                decoration: const BoxDecoration(
                  gradient: AppTheme.goldGradient,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: _buildLogo(size: 84),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Sparkle(size: 22, color: AppTheme.sun),
                      const SizedBox(width: 12),
                      Text(
                        _wipeLabel,
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const _Sparkle(size: 22, color: AppTheme.sun),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // ═════════════════════════════════════════════════════════════
  // SCROLL HANDLING
  // ═════════════════════════════════════════════════════════════

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final ScrollPosition position = _scrollController.position;
    final double offset = position.pixels;

    _updateHeroActivity(offset);

    final double max = position.maxScrollExtent;

    _scrollProgress.value = max > 0
        ? (offset / max).clamp(0.0, 1.0).toDouble()
        : 0.0;

    final bool scrolled = offset > 12;
    final bool showTop = offset > 650;
    final bool nearTop = offset < 1700;
    final int active = _computeActiveSection();

    final bool changed =
        scrolled != _scrolled ||
        showTop != _showScrollToTop ||
        nearTop != _nearTop ||
        active != _activeSection;

    if (!changed && !_mobileMenuOpen) {
      return;
    }

    _scrolled = scrolled;
    _showScrollToTop = showTop;
    _nearTop = nearTop;
    _activeSection = active;

    if (_mobileMenuOpen) {
      // Closing the menu changes the page layout: full rebuild (rare).
      setState(() {
        _mobileMenuOpen = false;
      });
    } else {
      // Only the header, scroll-to-top button and marquee depend on these.
      _scrollUi.value++;
    }
  }

  int _computeActiveSection() {
    final List<GlobalKey> keys = [
      _homeKey,
      _aboutKey,
      _servicesKey,
      _contactKey,
    ];

    int active = 0;

    for (int i = 0; i < keys.length; i++) {
      final RenderObject? renderObject = keys[i].currentContext
          ?.findRenderObject();

      if (renderObject is RenderBox &&
          renderObject.attached &&
          renderObject.hasSize) {
        final double top = renderObject.localToGlobal(Offset.zero).dy;

        if (top <= 160) {
          active = i;
        }
      }
    }

    return active;
  }

  // Pauses the floating hero animation while the hero is out of view so the
  // rest of the page scrolls smoothly.
  void _updateHeroActivity(double offset) {
    final RenderObject? renderObject = _homeKey.currentContext
        ?.findRenderObject();

    final double heroHeight = renderObject is RenderBox && renderObject.hasSize
        ? renderObject.size.height
        : 900;

    final bool shouldAnimate = offset < heroHeight;

    if (shouldAnimate == _heroAnimating) {
      return;
    }

    _heroAnimating = shouldAnimate;

    if (shouldAnimate) {
      _heroFloat.repeat();
    } else {
      _heroFloat.stop();
    }
  }

  // ── Smooth mouse wheel ─────────────────────────────────────────
  //
  // A normal mouse wheel jumps in big steps. Instead of fighting the browser
  // we only take over those big wheel steps and glide to the target position.
  // Touch, trackpads, the keyboard and the scrollbar are left untouched, so
  // they keep working exactly as before.

  void _onWheelSignal(PointerSignalEvent event) {
    if (!kIsWeb || event is! PointerScrollEvent) {
      return;
    }

    final double dy = event.scrollDelta.dy;
    final double dx = event.scrollDelta.dx;

    // Small deltas come from trackpads (already smooth) and horizontal
    // scrolling is not used on this page: let Flutter handle those.
    if (dy.abs() < 40 || dx.abs() > dy.abs()) {
      return;
    }

    GestureBinding.instance.pointerSignalResolver.register(event, _handleWheel);
  }

  void _handleWheel(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_scrollController.hasClients) {
      return;
    }

    final ScrollPosition position = _scrollController.position;

    if (!_wheelTicker.isActive) {
      _wheelTarget = position.pixels;
    }

    _wheelTarget = (_wheelTarget + event.scrollDelta.dy)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();

    if (!_wheelTicker.isActive) {
      _lastWheelTick = Duration.zero;
      _wheelTicker.start();
    }
  }

  void _onWheelTick(Duration elapsed) {
    if (!_scrollController.hasClients) {
      _wheelTicker.stop();
      return;
    }

    final double dt = ((elapsed - _lastWheelTick).inMicroseconds / 1000000)
        .clamp(0.0, 0.05)
        .toDouble();

    _lastWheelTick = elapsed;

    final ScrollPosition position = _scrollController.position;
    final double current = position.pixels;
    final double difference = _wheelTarget - current;

    if (difference.abs() < 0.5) {
      position.jumpTo(_wheelTarget);
      _wheelTicker.stop();
      return;
    }

    // Exponential easing: fast at first, then settles gently.
    final double factor = 1 - math.exp(-dt * 9);

    position.jumpTo(current + difference * factor);
  }

  void _closeMobileMenu() {
    if (!_mobileMenuOpen) {
      return;
    }

    setState(() {
      _mobileMenuOpen = false;
    });
  }

  Future<void> _navigateFromHeader(GlobalKey key) async {
    _closeMobileMenu();

    await Future<void>.delayed(const Duration(milliseconds: 80));

    if (!mounted) {
      return;
    }

    await _scrollTo(key);
  }

  Future<void> _scrollTo(GlobalKey key) async {
    _wheelTicker.stop();

    final BuildContext? target = key.currentContext;

    if (target == null) {
      return;
    }

    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeInOutCubic,
      alignment: 0.02,
    );
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) {
      return;
    }

    _wheelTicker.stop();

    _closeMobileMenu();

    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ACTIONS
  // ═════════════════════════════════════════════════════════════

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String get _whatsAppBase =>
      'https://wa.me/${BusinessConfig.whatsapp.replaceAll(RegExp(r'\D'), '')}';

  /// Lets the visitor pick which of the pharmacy's numbers to call.
  Future<void> _call() async {
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (sheetContext) {
        return _CallSheet(
          title: _t.callSheetTitle,
          numbers: BusinessConfig.phones,
          format: _t.ltr,
          onSelect: (String number) {
            Navigator.of(sheetContext).pop();

            _openUrl('tel:${number.replaceAll(RegExp(r'[^\d+]'), '')}');
          },
        );
      },
    );
  }

  Future<void> _whatsapp() async {
    await _openUrl(_whatsAppBase);
  }

  Future<void> _whatsappAbout(String service) async {
    final String text = Uri.encodeComponent(_t.askAboutService(service));

    await _openUrl('$_whatsAppBase?text=$text');
  }

  Future<void> _location() async {
    await _openUrl(BusinessConfig.googleMaps);
  }

  Future<void> _instagram() async {
    await _openUrl(BusinessConfig.instagram);
  }

  // ═════════════════════════════════════════════════════════════
  // LIVE OPENING STATUS
  // ═════════════════════════════════════════════════════════════

  _OpenStatus _computeStatus() {
    final OpeningState state = OpeningHours.at(OpeningHours.pharmacyNow());

    if (state.isOpen) {
      return _OpenStatus(
        isOpen: true,
        title: _t.statusOpen,
        detail: _t.closesAt(_t.clock(BusinessConfig.closeMinutes)),
        weekday: state.weekday,
      );
    }

    final String openTime = _t.clock(BusinessConfig.openMinutes);

    final String detail = switch (state.nextOpening) {
      NextOpening.laterToday => _t.opensTodayAt(openTime),
      NextOpening.tomorrow => _t.opensTomorrowAt(openTime),
      NextOpening.laterDay => _t.opensDayAt(
        _t.weekdayLong(state.opensOnWeekday),
        openTime,
      ),
    };

    return _OpenStatus(
      isOpen: false,
      title: _t.statusClosed,
      detail: detail,
      weekday: state.weekday,
    );
  }

  // ═════════════════════════════════════════════════════════════
  // SMALL HELPERS
  // ═════════════════════════════════════════════════════════════

  /// Fade + slide in when scrolled into view (or nothing if switched off).
  Widget _reveal(
    Widget child, {
    int index = 0,
    Offset slide = const Offset(0, 34),
    double startScale = 1,
  }) {
    if (!kScrollReveal) {
      return child;
    }

    return RevealOnScroll(
      delay: Duration(milliseconds: 90 * index),
      slide: slide,
      startScale: startScale,
      // Phones slide only: no fading layers (safer in in-app browsers).
      fade: MediaQuery.sizeOf(context).width >= 700,
      child: child,
    );
  }

  Widget _buildLogo({double size = 48}) {
    if (BusinessConfig.logoAsset.isNotEmpty) {
      // The logo is a round plate on a square photo: crop to the circle.
      return ClipOval(
        child: Transform.scale(
          scale: 1.18,
          child: Image.asset(
            BusinessConfig.logoAsset,
            width: size,
            height: size,
            fit: BoxFit.cover,
            cacheWidth: (size * 3).round(),
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
            errorBuilder: (_, _, _) {
              return _fallbackLogo(size);
            },
          ),
        ),
      );
    }

    return _fallbackLogo(size);
  }

  Widget _fallbackLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Center(
        child: Icon(
          Icons.local_pharmacy_rounded,
          color: Colors.white,
          size: size * 0.56,
        ),
      ),
    );
  }

  IconData _serviceIcon(String emoji) {
    if (emoji.contains('💊')) {
      return Icons.medication_rounded;
    }

    if (emoji.contains('🩺')) {
      return Icons.health_and_safety_rounded;
    }

    if (emoji.contains('❤')) {
      return Icons.favorite_rounded;
    }

    if (emoji.contains('👶')) {
      return Icons.child_care_rounded;
    }

    if (emoji.contains('🧴')) {
      return Icons.clean_hands_rounded;
    }

    if (emoji.contains('📍')) {
      return Icons.location_on_rounded;
    }

    return Icons.local_pharmacy_rounded;
  }

  // ═════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;

    final bool isMobile = width < 700;
    final bool isTablet = width >= 700 && width < 1050;
    final bool isSmallDesktop = width >= 1050 && width < 1200;

    final double horizontalPadding = width < 500
        ? 20
        : width < 700
        ? 24
        : width < 1050
        ? 32
        : 48;

    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final bool compactHeader = isMobile || isTablet;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _languageTransition(
        Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerSignal: _onWheelSignal,
                child: Column(
                  children: [
                    RepaintBoundary(
                      child: _buildHero(
                        context,
                        isMobile,
                        isTablet,
                        isSmallDesktop,
                        horizontalPadding,
                      ),
                    ),
                    _buildMarquee(isMobile),
                    RepaintBoundary(
                      child: _buildQuickActions(
                        context,
                        isMobile,
                        horizontalPadding,
                      ),
                    ),
                    RepaintBoundary(
                      child: _buildAbout(
                        context,
                        isMobile,
                        isTablet,
                        horizontalPadding,
                      ),
                    ),
                    RepaintBoundary(
                      child: _buildServices(
                        context,
                        isMobile,
                        horizontalPadding,
                      ),
                    ),
                    RepaintBoundary(
                      child: _buildContact(
                        context,
                        isMobile,
                        isTablet,
                        horizontalPadding,
                      ),
                    ),
                    RepaintBoundary(
                      child: _buildFooter(context, isMobile, horizontalPadding),
                    ),
                  ],
                ),
              ),
            ),

            if (_mobileMenuOpen && compactHeader)
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (_) => _closeMobileMenu(),
                ),
              ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerSignal: _onWheelSignal,
                child: ListenableBuilder(
                  listenable: _scrollUi,
                  builder: (context, _) => _buildHeader(
                    context,
                    isMobile,
                    isTablet,
                    horizontalPadding,
                  ),
                ),
              ),
            ),

            Positioned(
              right: isMobile ? 16 : 28,
              bottom: isMobile ? 20 + bottomInset : 28,
              child: ListenableBuilder(
                listenable: _scrollUi,
                builder: (context, _) => IgnorePointer(
                  ignoring: !_showScrollToTop,
                  child: AnimatedOpacity(
                    opacity: _showScrollToTop ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: AnimatedSlide(
                      offset: _showScrollToTop
                          ? Offset.zero
                          : const Offset(0, 0.7),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      child: _ScrollTopButton(
                        onTap: _scrollToTop,
                        tooltip: _t.backToTop,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // HEADER
  // ═════════════════════════════════════════════════════════════

  Widget _buildHeader(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    double horizontalPadding,
  ) {
    final bool compactHeader = isMobile || isTablet;
    final bool showLanguageInHeader = MediaQuery.sizeOf(context).width >= 400;

    final double logoSize = _scrolled
        ? (isMobile ? 40 : 46)
        : (isMobile ? 50 : 60);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: _scrolled || _mobileMenuOpen
                ? AppTheme.surface.withValues(alpha: 0.96)
                : AppTheme.background.withValues(alpha: 0),
            border: Border(
              bottom: BorderSide(
                color: _scrolled ? AppTheme.border : Colors.transparent,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _scrolled ? 0.06 : 0),
                blurRadius: _scrolled ? 22 : 0,
                offset: Offset(0, _scrolled ? 6 : 0),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: _scrolled ? 8 : (isMobile ? 12 : 16),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Row(
                    children: [
                      _HeaderLogoButton(
                        onTap: () => _navigateFromHeader(_homeKey),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          width: logoSize,
                          height: logoSize,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: _buildLogo(size: 64),
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 10 : 14),

                      Expanded(
                        child: _HeaderLogoButton(
                          onTap: () => _navigateFromHeader(_homeKey),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              _t.businessName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isMobile ? 17 : 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: _ar ? 0 : -0.4,
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (!compactHeader) ...[
                        _NavItem(
                          title: _t.navHome,
                          active: _activeSection == 0,
                          onTap: () => _navigateFromHeader(_homeKey),
                        ),
                        _NavItem(
                          title: _t.navAbout,
                          active: _activeSection == 1,
                          onTap: () => _navigateFromHeader(_aboutKey),
                        ),
                        _NavItem(
                          title: _t.navServices,
                          active: _activeSection == 2,
                          onTap: () => _navigateFromHeader(_servicesKey),
                        ),
                        _NavItem(
                          title: _t.navContact,
                          active: _activeSection == 3,
                          onTap: () => _navigateFromHeader(_contactKey),
                        ),
                        const SizedBox(width: 14),
                        _languageButton(),
                        const SizedBox(width: 14),
                        _StickerButton(
                          label: _t.whatsapp,
                          icon: Icons.chat_rounded,
                          isWhatsApp: true,
                          onTap: _whatsapp,
                          compact: true,
                        ),
                      ] else ...[
                        if (showLanguageInHeader) ...[
                          _languageButton(compact: true),
                          const SizedBox(width: 4),
                        ],
                        _headerMenuButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Thin reading-progress line under the header.
        ValueListenableBuilder<double>(
          valueListenable: _scrollProgress,
          builder: (context, progress, _) {
            return SizedBox(
              height: 3,
              width: double.infinity,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(color: AppTheme.coral),
                  ),
                ),
              ),
            );
          },
        ),

        if (compactHeader)
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _mobileMenuOpen
                ? _buildMobileMenu(horizontalPadding: horizontalPadding)
                : const SizedBox(width: double.infinity),
          ),
      ],
    );
  }

  Widget _buildMobileMenu({required double horizontalPadding}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(bottom: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              8,
              horizontalPadding,
              18,
            ),
            child: Column(
              children: [
                _MobileMenuItem(
                  icon: Icons.home_rounded,
                  title: _t.navHome,
                  onTap: () => _navigateFromHeader(_homeKey),
                ),
                _MobileMenuItem(
                  icon: Icons.info_outline_rounded,
                  title: _t.navAbout,
                  onTap: () => _navigateFromHeader(_aboutKey),
                ),
                _MobileMenuItem(
                  icon: Icons.medical_services_outlined,
                  title: _t.navServices,
                  onTap: () => _navigateFromHeader(_servicesKey),
                ),
                _MobileMenuItem(
                  icon: Icons.phone_outlined,
                  title: _t.navContact,
                  onTap: () => _navigateFromHeader(_contactKey),
                ),
                _MobileMenuItem(
                  icon: Icons.language_rounded,
                  title: _t.languageSwitchLabel,
                  onTap: _switchLanguage,
                ),
                const SizedBox(height: 12),
                _StickerButton(
                  label: _t.chatOnWhatsApp,
                  icon: Icons.chat_rounded,
                  isWhatsApp: true,
                  fullWidth: true,
                  onTap: () {
                    _closeMobileMenu();
                    _whatsapp();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _languageButton({bool compact = false}) {
    return _HoverScale(
      scale: 1.05,
      child: OutlinedButton.icon(
        onPressed: _switchLanguage,
        icon: const Icon(Icons.language_rounded, size: 18),
        label: Text(compact ? _t.languageSwitchShort : _t.languageSwitchLabel),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textPrimary,
          side: const BorderSide(color: AppTheme.ink, width: 1.6),
          minimumSize: const Size(0, 40),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 8 : 10,
          ),
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _headerMenuButton() {
    return IconButton(
      tooltip: _mobileMenuOpen ? _t.menuClose : _t.menuOpen,
      onPressed: () {
        setState(() {
          _mobileMenuOpen = !_mobileMenuOpen;
        });
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return RotationTransition(
            turns: Tween<double>(begin: 0.75, end: 1).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Icon(
          _mobileMenuOpen ? Icons.close_rounded : Icons.menu_rounded,
          key: ValueKey<bool>(_mobileMenuOpen),
          color: AppTheme.ink,
          size: 28,
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // HERO
  // ═════════════════════════════════════════════════════════════

  Widget _buildHero(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    bool isSmallDesktop,
    double horizontalPadding,
  ) {
    final bool compactHero = isMobile || isTablet;

    final Widget content = _heroContent(context, isMobile, compactHero);
    final Widget visual = _HeroEntrance(
      animation: _heroEntrance,
      start: 0.25,
      end: 1,
      slide: const Offset(0, 40),
      startScale: 0.9,
      minOpacity: isMobile ? 1 : 0,
      child: _heroVisual(isMobile),
    );

    return Container(
      key: _homeKey,
      width: double.infinity,
      color: AppTheme.background,
      child: Stack(
        children: [
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _HeroBackdropPainter()),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Padding(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: isMobile
                      ? 112
                      : isTablet
                      ? 130
                      : 150,
                  bottom: isMobile
                      ? 56
                      : isTablet
                      ? 70
                      : 90,
                ),
                child: compactHero
                    ? Column(
                        children: [
                          content,
                          SizedBox(height: isMobile ? 46 : 56),
                          visual,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: isSmallDesktop ? 11 : 12,
                            child: content,
                          ),
                          SizedBox(width: isSmallDesktop ? 30 : 60),
                          Expanded(flex: 10, child: Center(child: visual)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroContent(BuildContext context, bool isMobile, bool compact) {
    final double width = MediaQuery.sizeOf(context).width;

    final double titleSize = isMobile
        ? (width < 380 ? 42 : 50)
        : compact
        ? 66
        : width < 1200
        ? 66
        : 78;

    final CrossAxisAlignment align = isMobile
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    final TextAlign textAlign = isMobile ? TextAlign.center : TextAlign.start;

    // Phones slide in without fading (no off-screen layers).
    final double minOpacity = isMobile ? 1 : 0;

    // Split "Your health, our priority." into two lines at the comma.
    final String tagline = _t.tagline.trim();
    final Match? comma = RegExp(r'[,،]\s*').firstMatch(tagline);

    final String line1 = comma == null
        ? tagline
        : tagline.substring(0, comma.end).trim();
    final String line2 = comma == null ? '' : tagline.substring(comma.end);

    final TextStyle headline = TextStyle(
      fontSize: titleSize,
      height: _ar ? 1.3 : 1.0,
      letterSpacing: _ar ? 0 : (isMobile ? -1.6 : -2.6),
      fontWeight: FontWeight.w800,
      color: AppTheme.ink,
    );

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: align,
        children: [
          _HeroEntrance(
            animation: _heroEntrance,
            start: 0,
            end: 0.4,
            minOpacity: minOpacity,
            child: _statusPill(),
          ),
          const SizedBox(height: 26),

          _HeroEntrance(
            animation: _heroEntrance,
            start: 0.08,
            end: 0.55,
            minOpacity: minOpacity,
            slide: const Offset(0, 36),
            child: Text(line1, textAlign: textAlign, style: headline),
          ),

          if (line2.isNotEmpty)
            _HeroEntrance(
              animation: _heroEntrance,
              start: 0.18,
              end: 0.68,
              minOpacity: minOpacity,
              slide: const Offset(0, 36),
              child: _Squiggle(
                color: AppTheme.coral,
                child: Padding(
                  padding: EdgeInsets.only(bottom: _ar ? 6 : 10),
                  child: Text(
                    line2,
                    textAlign: textAlign,
                    style: headline.copyWith(color: AppTheme.primary),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 26),

          _HeroEntrance(
            animation: _heroEntrance,
            start: 0.3,
            end: 0.78,
            minOpacity: minOpacity,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Text(
                _t.description,
                textAlign: textAlign,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: isMobile ? 16 : 18,
                  height: 1.7,
                ),
              ),
            ),
          ),

          const SizedBox(height: 34),

          _HeroEntrance(
            animation: _heroEntrance,
            start: 0.4,
            end: 0.88,
            minOpacity: minOpacity,
            child: Wrap(
              alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
              spacing: 16,
              runSpacing: 18,
              children: [
                _StickerButton(
                  label: _t.chatOnWhatsApp,
                  icon: Icons.chat_rounded,
                  isWhatsApp: true,
                  onTap: _whatsapp,
                ),
                _StickerButton(
                  label: _t.findPharmacy,
                  icon: Icons.location_on_rounded,
                  onTap: _location,
                  background: Colors.white,
                  foreground: AppTheme.ink,
                ),
              ],
            ),
          ),

          const SizedBox(height: 34),

          _HeroEntrance(
            animation: _heroEntrance,
            start: 0.5,
            end: 1,
            minOpacity: minOpacity,
            child: Wrap(
              alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
              spacing: 22,
              runSpacing: 10,
              children: [
                _trustIndicator(_t.trustProfessional),
                _trustIndicator(_t.trustAvailable),
                _trustIndicator(_t.trustPatient),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "Open now · closes at 10:30 PM" with a softly pulsing dot.
  Widget _statusPill() {
    return ValueListenableBuilder<int>(
      valueListenable: _minuteTick,
      builder: (context, _, _) {
        final _OpenStatus status = _computeStatus();

        final Color dot = status.isOpen
            ? const Color(0xFF16A34A)
            : const Color(0xFFC2410C);

        // The height is capped on purpose: whatever the browser does with the
        // text, this badge can never grow into a giant box.
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 64),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppTheme.ink, width: 1.8),
              boxShadow: const [
                BoxShadow(color: AppTheme.ink, offset: Offset(3, 3)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulseDot(color: dot),
                const SizedBox(width: 10),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: status.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        TextSpan(
                          text: '  ·  ${status.detail}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _trustIndicator(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppTheme.mint,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 14,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════
  // HERO VISUAL (sticker style illustration made of simple shapes)
  // ═════════════════════════════════════════════════════════════

  Widget _heroVisual(bool isMobile) {
    final double box = isMobile ? 310 : 480;
    final double card = isMobile ? 172 : 255;

    return AnimatedBuilder(
      animation: _heroFloat,
      builder: (context, _) {
        final double v = _heroFloat.value;

        // Smooth looping motion: each piece uses its own phase.
        double bob(double phase, double amplitude) {
          return math.sin((v + phase) * 2 * math.pi) * amplitude;
        }

        return SizedBox(
          width: box,
          height: box,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Brushed-silver plate with blue rings and gold screws,
              // like the logo.
              Transform.rotate(
                angle: bob(0, 0.025),
                child: CustomPaint(
                  size: Size.square(box * 0.92),
                  painter: const _PlaquePainter(),
                ),
              ),

              // Back card.
              Transform.translate(
                offset: Offset(box * 0.06, box * 0.03 + bob(0.3, 5)),
                child: Transform.rotate(
                  angle: 0.17 + bob(0.1, 0.02),
                  child: _StickerBox(
                    size: card,
                    color: AppTheme.coral,
                    gradient: AppTheme.goldGradient,
                    radius: card * 0.2,
                    child: const SizedBox.shrink(),
                  ),
                ),
              ),

              // Front card with the pharmacy cross (or the hero photo).
              Transform.translate(
                offset: Offset(-box * 0.03, bob(0, 8)),
                child: Transform.rotate(
                  angle: -0.09 + bob(0.5, 0.015),
                  child: _StickerBox(
                    size: card,
                    color: AppTheme.primary,
                    radius: card * 0.2,
                    child: BusinessConfig.heroImageAsset.isNotEmpty
                        ? Image.asset(
                            BusinessConfig.heroImageAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) {
                              return Center(
                                child: _CrossMark(size: card * 0.52),
                              );
                            },
                          )
                        : Center(child: _CrossMark(size: card * 0.52)),
                  ),
                ),
              ),

              // Capsules and a tablet drifting around the cards.
              Positioned(
                left: box * 0.0,
                top: box * 0.30,
                child: Transform.translate(
                  offset: Offset(0, bob(0.2, 10)),
                  child: Transform.rotate(
                    angle: -0.7 + bob(0.3, 0.09),
                    child: _Capsule(
                      length: box * 0.31,
                      thickness: box * 0.12,
                      a: AppTheme.primary,
                      b: Color(0xFFF4F4F2),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: box * 0.0,
                bottom: box * 0.30,
                child: Transform.translate(
                  offset: Offset(0, bob(0.65, 10)),
                  child: Transform.rotate(
                    angle: 0.75 + bob(0.8, 0.09),
                    child: _Capsule(
                      length: box * 0.32,
                      thickness: box * 0.125,
                      a: AppTheme.coral,
                      b: Color(0xFFF4F4F2),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: box * 0.17,
                top: box * 0.05,
                child: Transform.translate(
                  offset: Offset(bob(0.4, 5), bob(0.1, 9)),
                  child: Transform.rotate(
                    angle: bob(0, 0.5),
                    child: _Tablet(size: box * 0.12, color: AppTheme.sunSoft),
                  ),
                ),
              ),

              // Little sparkles.
              Positioned(
                right: box * 0.2,
                bottom: box * 0.03,
                child: Transform.rotate(
                  angle: v * 2 * math.pi,
                  child: _Sparkle(
                    size: isMobile ? 26 : 38,
                    color: AppTheme.sun,
                  ),
                ),
              ),
              Positioned(
                left: box * 0.06,
                bottom: box * 0.30,
                child: Transform.rotate(
                  angle: -v * 2 * math.pi,
                  child: _Sparkle(
                    size: isMobile ? 18 : 26,
                    color: AppTheme.primary,
                  ),
                ),
              ),

              // Sticker badges.
              Positioned(
                top: box * 0.07,
                right: isMobile ? -4 : 0,
                child: Transform.translate(
                  offset: Offset(0, bob(0.15, 7)),
                  child: Transform.rotate(
                    angle: 0.06,
                    child: _floatingBadge(
                      Icons.local_pharmacy_rounded,
                      _t.badgePharmacyTitle,
                      _t.badgePharmacySub,
                      AppTheme.mint,
                      compact: isMobile,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: box * 0.06,
                left: isMobile ? -4 : 0,
                child: Transform.translate(
                  offset: Offset(0, bob(0.7, 7)),
                  child: Transform.rotate(
                    angle: -0.06,
                    child: _floatingBadge(
                      Icons.favorite_rounded,
                      _t.badgeHealthTitle,
                      _t.badgeHealthSub,
                      AppTheme.blush,
                      compact: isMobile,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _floatingBadge(
    IconData icon,
    String title,
    String subtitle,
    Color iconBackground, {
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 8 : 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(color: AppTheme.ink, width: 2),
        boxShadow: const [BoxShadow(color: AppTheme.ink, offset: Offset(4, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 30 : 38,
            height: compact ? 30 : 38,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: compact ? 16 : 20,
              color: AppTheme.primaryDark,
            ),
          ),
          SizedBox(width: compact ? 8 : 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: compact ? 12 : 14,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: compact ? 10.5 : 12,
                  height: 1.2,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // MARQUEE (scrolling strip of services)
  // ═════════════════════════════════════════════════════════════

  Widget _buildMarquee(bool isMobile) {
    final List<String> items = [
      for (final Map<String, String> service in _t.services)
        service['title'] ?? '',
    ];

    return Container(
      width: double.infinity,
      height: isMobile ? 64 : 76,
      decoration: const BoxDecoration(
        gradient: AppTheme.silver,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppTheme.primary, width: 3),
        ),
      ),
      child: Stack(
        children: [
          // Thin second line inside, like the double ring on the logo.
          Positioned(
            top: 5,
            left: 0,
            right: 0,
            height: 1.5,
            child: ColoredBox(color: AppTheme.primary.withValues(alpha: 0.7)),
          ),
          Positioned(
            bottom: 5,
            left: 0,
            right: 0,
            height: 1.5,
            child: ColoredBox(color: AppTheme.primary.withValues(alpha: 0.7)),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: ListenableBuilder(
                listenable: _scrollUi,
                builder: (context, _) => _Marquee(
                  items: items,
                  running: _nearTop,
                  fontSize: isMobile ? 19 : 23,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // QUICK ACTIONS
  // ═════════════════════════════════════════════════════════════

  Widget _buildQuickActions(
    BuildContext context,
    bool isMobile,
    double horizontalPadding,
  ) {
    return Container(
      width: double.infinity,
      color: AppTheme.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isMobile ? 64 : 90,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reveal(
                  SectionTitle(
                    eyebrow: _t.quickEyebrow,
                    title: _t.quickTitle,
                    subtitle: _t.quickSubtitle,
                  ),
                ),
                SizedBox(height: isMobile ? 30 : 44),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double availableWidth = constraints.maxWidth;

                    final int columns = availableWidth >= 1050
                        ? 4
                        : availableWidth >= 330
                        ? 2
                        : 1;

                    final double spacing = isMobile ? 14 : 18;

                    final double tileWidth = columns == 1
                        ? availableWidth
                        : (availableWidth - spacing * (columns - 1)) / columns;

                    final List<Widget> tiles = [
                      SocialButton(
                        title: _t.whatsapp,
                        subtitle: _t.cardWhatsAppSub,
                        icon: Icons.chat_rounded,
                        isWhatsApp: true,
                        iconColor: const Color(0xFF1FA855),
                        onTap: _whatsapp,
                      ),
                      SocialButton(
                        title: _t.callUs,
                        subtitle: _t.callSub,
                        icon: Icons.phone_rounded,
                        iconColor: AppTheme.primary,
                        onTap: _call,
                      ),
                      SocialButton(
                        title: _t.cardFindTitle,
                        subtitle: _t.cardFindSub,
                        icon: Icons.location_on_rounded,
                        iconColor: AppTheme.coral,
                        onTap: _location,
                      ),
                      SocialButton(
                        title: _t.instagram,
                        subtitle: _t.cardInstagramSub,
                        icon: Icons.camera_alt_rounded,
                        iconColor: const Color.fromARGB(255, 210, 8, 55),
                        onTap: _instagram,
                      ),
                    ];

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (int i = 0; i < tiles.length; i++)
                          SizedBox(
                            width: tileWidth,
                            child: _reveal(
                              tiles[i],
                              index: i % columns,
                              startScale: 0.94,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ABOUT
  // ═════════════════════════════════════════════════════════════

  Widget _buildAbout(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    double horizontalPadding,
  ) {
    final bool stacked = isMobile || isTablet;

    return Container(
      key: _aboutKey,
      width: double.infinity,
      color: AppTheme.stone,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isMobile ? 70 : 100,
            ),
            child: stacked
                ? Column(
                    children: [
                      _reveal(
                        _aboutVisual(isMobile),
                        slide: const Offset(0, 40),
                        startScale: 0.96,
                      ),
                      SizedBox(height: isMobile ? 56 : 70),
                      _aboutContent(),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _reveal(
                          _aboutVisual(false),
                          slide: const Offset(-50, 0),
                          startScale: 0.96,
                        ),
                      ),
                      const SizedBox(width: 90),
                      Expanded(child: _aboutContent()),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _aboutVisual(bool isMobile) {
    final double height = isMobile ? 370 : 500;

    const BorderRadius arch = BorderRadius.only(
      topLeft: Radius.circular(500),
      topRight: Radius.circular(500),
      bottomLeft: Radius.circular(36),
      bottomRight: Radius.circular(36),
    );

    final Widget artwork = BusinessConfig.aboutImageAsset.isNotEmpty
        ? Image.asset(
            BusinessConfig.aboutImageAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _aboutArtwork(isMobile),
          )
        : _aboutArtwork(isMobile);

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PositionedDirectional(
                start: 26,
                end: 10,
                top: 0,
                bottom: 34,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: arch,
                    border: Border.all(color: AppTheme.ink, width: 2.5),
                    boxShadow: const [
                      BoxShadow(color: AppTheme.ink, offset: Offset(8, 8)),
                    ],
                  ),
                  child: ClipRRect(borderRadius: arch, child: artwork),
                ),
              ),
              PositionedDirectional(
                start: 0,
                bottom: 0,
                child: Transform.rotate(
                  angle: -0.04,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isMobile ? 240 : 280),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.ink, width: 2),
                        boxShadow: const [
                          BoxShadow(color: AppTheme.ink, offset: Offset(4, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: AppTheme.sunSoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_pharmacy_rounded,
                              size: 22,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _t.aboutFallbackTitle,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.25,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _t.aboutFallbackSub,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.3,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Illustration used inside the arch when no photo has been added.
  Widget _aboutArtwork(bool isMobile) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned(
          top: 22,
          left: 0,
          right: 0,
          child: Center(child: _Rivet(size: 14)),
        ),
        const Positioned(
          bottom: 22,
          left: 0,
          right: 0,
          child: Center(child: _Rivet(size: 14)),
        ),
        Align(
          alignment: const Alignment(0, -0.12),
          child: _CrossMark(size: isMobile ? 150 : 200),
        ),
        Positioned(
          top: isMobile ? 70 : 90,
          left: isMobile ? 26 : 40,
          child: Transform.rotate(
            angle: -0.6,
            child: _Capsule(
              length: isMobile ? 74 : 96,
              thickness: isMobile ? 30 : 38,
              a: AppTheme.coral,
              b: Colors.white,
            ),
          ),
        ),
        Positioned(
          top: isMobile ? 120 : 150,
          right: isMobile ? 24 : 38,
          child: Transform.rotate(
            angle: 0.8,
            child: _Capsule(
              length: isMobile ? 70 : 90,
              thickness: isMobile ? 28 : 36,
              a: AppTheme.grey,
              b: Colors.white,
            ),
          ),
        ),
        Positioned(
          bottom: isMobile ? 80 : 100,
          right: isMobile ? 44 : 70,
          child: _Tablet(size: isMobile ? 34 : 44, color: AppTheme.stone),
        ),
      ],
    );
  }

  Widget _aboutContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reveal(
          SectionTitle(
            eyebrow: _t.aboutPill,
            title: _t.aboutTitle,
            subtitle: _t.aboutText,
          ),
          slide: const Offset(0, 28),
        ),
        const SizedBox(height: 26),
        _reveal(
          _aboutPoint(
            Icons.verified_user_rounded,
            _t.aboutPoint1Title,
            _t.aboutPoint1Text,
          ),
          index: 1,
        ),
        _aboutDivider(),
        _reveal(
          _aboutPoint(
            Icons.favorite_rounded,
            _t.aboutPoint2Title,
            _t.aboutPoint2Text,
          ),
          index: 2,
        ),
        _aboutDivider(),
        _reveal(
          _aboutPoint(
            Icons.people_alt_rounded,
            _t.aboutPoint3Title,
            _t.aboutPoint3Text,
          ),
          index: 3,
        ),
      ],
    );
  }

  Widget _aboutDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppTheme.primary.withValues(alpha: 0.16),
    );
  }

  Widget _aboutPoint(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.6,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // SERVICES
  // ═════════════════════════════════════════════════════════════

  Widget _buildServices(
    BuildContext context,
    bool isMobile,
    double horizontalPadding,
  ) {
    const List<Color> tints = [
      AppTheme.mint,
      AppTheme.silverSoft,
      AppTheme.sunSoft,
      AppTheme.silverSoft,
      AppTheme.mint,
      AppTheme.sunSoft,
    ];

    return Container(
      key: _servicesKey,
      width: double.infinity,
      color: AppTheme.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isMobile ? 70 : 100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reveal(
                  SectionTitle(
                    eyebrow: _t.servicesEyebrow,
                    title: _t.servicesTitle,
                    subtitle: _t.servicesSubtitle,
                  ),
                ),
                SizedBox(height: isMobile ? 32 : 48),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double availableWidth = constraints.maxWidth;

                    final int columns = availableWidth >= 1000
                        ? 3
                        : availableWidth >= 640
                        ? 2
                        : 1;

                    const double gap = 20;

                    final List<Map<String, String>> services = _t.services;

                    final List<Widget> cards = List<Widget>.generate(
                      services.length,
                      (int index) {
                        final Map<String, String> service = services[index];

                        return _reveal(
                          ServiceCard(
                            icon: service['icon'] ?? '',
                            iconData: _serviceIcon(service['icon'] ?? ''),
                            title: service['title'] ?? '',
                            description: service['description'] ?? '',
                            number: (index + 1).toString().padLeft(2, '0'),
                            tint: tints[index % tints.length],
                            actionLabel: _t.askAboutThis,
                            onTap: () => _whatsappAbout(service['title'] ?? ''),
                          ),
                          index: index % columns,
                        );
                      },
                    );

                    final List<Widget> rows = [];

                    for (
                      int start = 0;
                      start < cards.length;
                      start += columns
                    ) {
                      final int end = math.min(start + columns, cards.length);
                      final List<Widget> rowCards = cards.sublist(start, end);

                      Widget row;

                      if (columns == 1) {
                        row = rowCards.first;
                      } else {
                        row = IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (int i = 0; i < columns; i++) ...[
                                if (i > 0) const SizedBox(width: gap),
                                Expanded(
                                  child: i < rowCards.length
                                      ? rowCards[i]
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ],
                          ),
                        );
                      }

                      rows.add(
                        Padding(
                          padding: EdgeInsets.only(top: start == 0 ? 0 : gap),
                          child: row,
                        ),
                      );
                    }

                    return Column(children: rows);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // CONTACT
  // ═════════════════════════════════════════════════════════════

  Widget _buildContact(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    double horizontalPadding,
  ) {
    return Container(
      key: _contactKey,
      width: double.infinity,
      color: AppTheme.sunSoft,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isMobile ? 64 : 100,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double availableWidth = constraints.maxWidth;
                final bool wide = availableWidth >= 900;
                final bool narrow = availableWidth < 520;

                final double padding = availableWidth < 400
                    ? 24
                    : isMobile
                    ? 28
                    : wide
                    ? 56
                    : 40;

                final Widget texts = _contactContent(isMobile: isMobile);
                final Widget buttons = _contactButtons(fullWidth: narrow);

                final Widget callout = Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark,
                    borderRadius: BorderRadius.circular(narrow ? 30 : 40),
                    border: Border.all(color: AppTheme.ink, width: 2.5),
                    boxShadow: const [
                      BoxShadow(color: AppTheme.ink, offset: Offset(8, 8)),
                    ],
                  ),
                  child: Stack(
                    children: [
                      PositionedDirectional(
                        top: -80,
                        end: -60,
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.grey.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        bottom: -100,
                        start: 40,
                        child: Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.sun.withValues(alpha: 0.13),
                          ),
                        ),
                      ),
                      const PositionedDirectional(
                        top: 0,
                        bottom: 0,
                        start: 9,
                        child: Center(child: _Rivet(size: 11)),
                      ),
                      const PositionedDirectional(
                        top: 0,
                        bottom: 0,
                        end: 9,
                        child: Center(child: _Rivet(size: 11)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(padding),
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(child: texts),
                                  const SizedBox(width: 40),
                                  Flexible(flex: 0, child: buttons),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  texts,
                                  const SizedBox(height: 30),
                                  buttons,
                                ],
                              ),
                      ),
                    ],
                  ),
                );

                return Column(
                  children: [
                    _reveal(callout, startScale: 0.97),
                    const SizedBox(height: 40),
                    _reveal(_buildVisitInfo(availableWidth), index: 1),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactContent({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t.contactEyebrow,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            letterSpacing: _ar ? 0 : 1.4,
            color: AppTheme.sun,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _t.contactTitle,
          style: TextStyle(
            fontSize: isMobile ? 36 : 50,
            height: _ar ? 1.3 : 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: _ar ? 0 : -1.4,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _t.contactBody,
          style: TextStyle(
            fontSize: isMobile ? 15 : 17,
            height: 1.65,
            color: Colors.white.withValues(alpha: 0.78),
          ),
        ),
      ],
    );
  }

  Widget _contactButtons({required bool fullWidth}) {
    final List<Widget> buttons = [
      _StickerButton(
        label: _t.whatsapp,
        icon: Icons.chat_rounded,
        isWhatsApp: true,
        onTap: _whatsapp,
        background: AppTheme.sun,
        foreground: AppTheme.ink,
        fullWidth: fullWidth,
      ),
      _StickerButton(
        label: _t.callUs,
        icon: Icons.phone_rounded,
        onTap: _call,
        background: Colors.white,
        foreground: AppTheme.ink,
        fullWidth: fullWidth,
      ),
      _StickerButton(
        label: _t.directions,
        icon: Icons.location_on_rounded,
        onTap: _location,
        background: Colors.white,
        foreground: AppTheme.ink,
        fullWidth: fullWidth,
      ),
    ];

    if (fullWidth) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            buttons[i],
            if (i != buttons.length - 1) const SizedBox(height: 18),
          ],
        ],
      );
    }

    return Wrap(spacing: 16, runSpacing: 18, children: buttons);
  }

  Widget _buildVisitInfo(double availableWidth) {
    const TextStyle bodyStyle = TextStyle(
      fontSize: 14.5,
      height: 1.6,
      color: AppTheme.textSecondary,
    );

    final Widget addressCard = _infoCard(
      icon: Icons.location_on_rounded,
      iconBackground: AppTheme.blush,
      title: _t.visitAddressTitle,
      onTap: _location,
      actionLabel: _t.cardFindSub,
      children: [Text(_t.address, style: bodyStyle)],
    );

    final Widget hoursCard = ValueListenableBuilder<int>(
      valueListenable: _minuteTick,
      builder: (context, _, _) {
        final int today = _computeStatus().weekday;

        // Saturday first, matching the opening hours text.
        const List<int> order = [6, 7, 1, 2, 3, 4, 5];

        return _infoCard(
          icon: Icons.access_time_rounded,
          iconBackground: AppTheme.sunSoft,
          title: _t.visitHoursTitle,
          children: [
            Text(_t.hoursOpen, style: bodyStyle),
            const SizedBox(height: 4),
            Text(
              _t.hoursClosed,
              style: bodyStyle.copyWith(
                color: const Color(0xFFC2410C),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          footer: Row(
            children: [
              for (int i = 0; i < order.length; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(
                  child: _dayChip(
                    weekday: order[i],
                    isToday: order[i] == today,
                    closed: BusinessConfig.closedWeekdays.contains(order[i]),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );

    if (availableWidth >= 760) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: addressCard),
            const SizedBox(width: 20),
            Expanded(child: hoursCard),
          ],
        ),
      );
    }

    return Column(
      children: [addressCard, const SizedBox(height: 16), hoursCard],
    );
  }

  Widget _dayChip({
    required int weekday,
    required bool isToday,
    required bool closed,
  }) {
    final Color background = isToday
        ? AppTheme.primary
        : closed
        ? AppTheme.blush
        : AppTheme.mint;

    final Color foreground = isToday
        ? Colors.white
        : closed
        ? const Color(0xFFC2410C)
        : AppTheme.primaryDark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 50,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday ? AppTheme.ink : Colors.transparent,
          width: 1.8,
        ),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _t.weekdayShort(weekday),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: foreground,
                decoration: closed
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconBackground,
    required String title,
    required List<Widget> children,
    Widget? footer,
    VoidCallback? onTap,
    String? actionLabel,
  }) {
    final bool rtl = _ar;

    final Widget card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.ink, width: 2),
        boxShadow: const [BoxShadow(color: AppTheme.ink, offset: Offset(5, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 24, color: AppTheme.primaryDark),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...children,
                    if (actionLabel != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            actionLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            rtl
                                ? Icons.arrow_back_rounded
                                : Icons.arrow_forward_rounded,
                            size: 17,
                            color: AppTheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 20), footer],
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return _HoverScale(
      scale: 1.012,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: card,
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // FOOTER
  // ═════════════════════════════════════════════════════════════

  Widget _buildFooter(
    BuildContext context,
    bool isMobile,
    double horizontalPadding,
  ) {
    return Container(
      width: double.infinity,
      color: AppTheme.ink,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              48,
              horizontalPadding,
              40,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildLogo(size: isMobile ? 48 : 58),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _t.businessName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _t.tagline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _footerIcon(
                      Icons.chat_rounded,
                      _t.whatsapp,
                      _whatsapp,
                      whatsApp: true,
                    ),
                    _footerIcon(Icons.phone_rounded, _t.callUs, _call),
                    _footerIcon(
                      Icons.camera_alt_rounded,
                      _t.instagram,
                      _instagram,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Divider(color: AppTheme.grey.withValues(alpha: 0.4), height: 1),
                const SizedBox(height: 22),
                Text(
                  _t.footerText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footerIcon(
    IconData icon,
    String tooltip,
    VoidCallback onTap, {
    bool whatsApp = false,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6),
      child: _HoverScale(
        scale: 1.12,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          icon: whatsApp ? const WhatsAppIcon(size: 22) : Icon(icon, size: 20),
          color: Colors.white,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.09),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// HERO ENTRANCE (staggered fade + slide on first load)
// ═════════════════════════════════════════════════════════════

class _HeroEntrance extends StatelessWidget {
  final Animation<double> animation;
  final double start;
  final double end;
  final Offset slide;
  final double startScale;

  /// Starting opacity. Phones start slightly visible so the very first
  /// frame is never completely blank, even in in-app browsers.
  final double minOpacity;

  final Widget child;

  const _HeroEntrance({
    required this.animation,
    required this.child,
    this.start = 0,
    this.end = 1,
    this.slide = const Offset(0, 28),
    this.startScale = 1,
    this.minOpacity = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final Curve curve = Interval(start, end, curve: Curves.easeOutCubic);

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final double t = curve.transform(
          animation.value.clamp(0.0, 1.0).toDouble(),
        );
        final double remaining = 1 - t;

        Widget result = Transform.translate(
          offset: Offset(
            slide.dx * (rtl ? -1 : 1) * remaining,
            slide.dy * remaining,
          ),
          child: child,
        );

        if (startScale != 1) {
          result = Transform.scale(
            scale: startScale + (1 - startScale) * t,
            child: result,
          );
        }

        return Opacity(
          opacity: minOpacity + (1 - minOpacity) * t,
          child: result,
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════
// STICKER BUTTON (outlined, hard shadow, presses down like a real button)
// ═════════════════════════════════════════════════════════════

class _StickerButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  final bool compact;
  final bool fullWidth;
  final bool isWhatsApp;

  const _StickerButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isWhatsApp = false,
    this.background = AppTheme.primary,
    this.foreground = Colors.white,
    this.compact = false,
    this.fullWidth = false,
  });

  @override
  State<_StickerButton> createState() => _StickerButtonState();
}

class _StickerButtonState extends State<_StickerButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final double rest = widget.compact ? 3 : 4;

    final double depth = _pressed
        ? 0
        : _hovered
        ? rest + 2
        : rest;

    // Moves the button toward its shadow when pressed, away when hovered.
    final double shift = rest - depth;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Padding(
          padding: EdgeInsets.only(right: rest + 2, bottom: rest + 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(shift, shift, 0),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 16 : 24,
              vertical: widget.compact ? 10 : 16,
            ),
            decoration: BoxDecoration(
              color: widget.background,
              borderRadius: BorderRadius.circular(widget.compact ? 14 : 18),
              border: Border.all(color: AppTheme.ink, width: 2),
              boxShadow: [
                BoxShadow(color: AppTheme.ink, offset: Offset(depth, depth)),
              ],
            ),
            child: Row(
              mainAxisSize: widget.fullWidth
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.isWhatsApp
                    ? WhatsAppIcon(
                        size: widget.compact ? 20 : 24,
                        color: widget.foreground,
                      )
                    : Icon(
                        widget.icon,
                        size: widget.compact ? 17 : 20,
                        color: widget.foreground,
                      ),
                SizedBox(width: widget.compact ? 8 : 10),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: widget.compact ? 14 : 15.5,
                      fontWeight: FontWeight.w800,
                      color: widget.foreground,
                    ),
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

// ═════════════════════════════════════════════════════════════
// PULSING DOT (live status)
// ═════════════════════════════════════════════════════════════

class _PulseDot extends StatefulWidget {
  final Color color;

  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final double t = _controller.value;
          final double ring = 10 + 12 * t;

          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: ring,
                height: ring,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.38 * (1 - t)),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// HAND-DRAWN SQUIGGLE UNDER THE HEADLINE
// ═════════════════════════════════════════════════════════════

class _Squiggle extends StatelessWidget {
  final Color color;
  final Widget child;

  const _Squiggle({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SquigglePainter(color), child: child);
  }
}

class _SquigglePainter extends CustomPainter {
  final Color color;

  const _SquigglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    const double amplitude = 3.2;
    const double wavelength = 18;

    final double y = size.height - 6;
    final double right = size.width - 3;

    final Path path = Path()..moveTo(3, y);

    double x = 3;
    bool up = true;

    while (x < right) {
      final double next = math.min(x + wavelength / 2, right);

      path.quadraticBezierTo(
        (x + next) / 2,
        up ? y - amplitude * 2 : y + amplitude * 2,
        next,
        y,
      );

      x = next;
      up = !up;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SquigglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ═════════════════════════════════════════════════════════════
// STICKER SHAPES (cards, cross, capsule, tablet, blob)
// ═════════════════════════════════════════════════════════════

class _StickerBox extends StatelessWidget {
  final double size;
  final Color color;
  final double radius;
  final Widget child;
  final Gradient? gradient;

  const _StickerBox({
    required this.size,
    required this.color,
    required this.radius,
    required this.child,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTheme.ink, width: 2.5),
        boxShadow: const [BoxShadow(color: AppTheme.ink, offset: Offset(6, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(math.max(radius - 2.5, 0)),
        child: child,
      ),
    );
  }
}

class _CrossMark extends StatelessWidget {
  final double size;

  const _CrossMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _CrossPainter()),
    );
  }
}

class _CrossPainter extends CustomPainter {
  const _CrossPainter();

  Path _cross(double s, double dx, double dy) {
    final double t = s * 0.34;
    final double a = (s - t) / 2;
    final double b = a + t;

    return Path()
      ..moveTo(a + dx, 0 + dy)
      ..lineTo(b + dx, 0 + dy)
      ..lineTo(b + dx, a + dy)
      ..lineTo(s + dx, a + dy)
      ..lineTo(s + dx, b + dy)
      ..lineTo(b + dx, b + dy)
      ..lineTo(b + dx, s + dy)
      ..lineTo(a + dx, s + dy)
      ..lineTo(a + dx, b + dy)
      ..lineTo(0 + dx, b + dy)
      ..lineTo(0 + dx, a + dy)
      ..lineTo(a + dx, a + dy)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double s = math.min(size.width, size.height);

    canvas.drawPath(_cross(s, 5, 5), Paint()..color = AppTheme.ink);

    canvas.drawPath(_cross(s, 0, 0), Paint()..color = Colors.white);

    canvas.drawPath(
      _cross(s, 0, 0),
      Paint()
        ..color = AppTheme.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Capsule extends StatelessWidget {
  final double length;
  final double thickness;
  final Color a;
  final Color b;

  const _Capsule({
    required this.length,
    required this.thickness,
    required this.a,
    required this.b,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: length,
      height: thickness,
      child: CustomPaint(painter: _CapsulePainter(a, b)),
    );
  }
}

/// A two-colour pill: left half [a], right half [b], with a hard shadow,
/// outline and a little shine. Drawn directly so the two colours always show.
class _CapsulePainter extends CustomPainter {
  final Color a;
  final Color b;

  const _CapsulePainter(this.a, this.b);

  @override
  void paint(Canvas canvas, Size size) {
    final RRect shape = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );

    // Hard shadow.
    canvas.drawRRect(
      shape.shift(const Offset(3, 3)),
      Paint()..color = AppTheme.ink,
    );

    canvas.save();
    canvas.clipRRect(shape);

    final double mid = size.width / 2;

    canvas.drawRect(Rect.fromLTWH(0, 0, mid, size.height), Paint()..color = a);
    canvas.drawRect(
      Rect.fromLTWH(mid, 0, size.width - mid, size.height),
      Paint()..color = b,
    );

    // Soft shade along the bottom.
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );

    // Shine along the top.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.height * 0.4,
          size.height * 0.14,
          math.max(size.width - size.height * 0.8, 1),
          size.height * 0.17,
        ),
        Radius.circular(size.height),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );

    canvas.restore();

    final Paint line = Paint()
      ..color = AppTheme.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Line between the two halves, then the outline.
    canvas.drawLine(Offset(mid, 0), Offset(mid, size.height), line);
    canvas.drawRRect(shape.deflate(1), line);
  }

  @override
  bool shouldRepaint(covariant _CapsulePainter oldDelegate) {
    return oldDelegate.a != a || oldDelegate.b != b;
  }
}

class _Tablet extends StatelessWidget {
  final double size;
  final Color color;

  const _Tablet({required this.size, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.ink, width: 2),
        boxShadow: const [BoxShadow(color: AppTheme.ink, offset: Offset(3, 3))],
      ),
      child: Center(
        child: Container(width: size * 0.62, height: 2.4, color: AppTheme.ink),
      ),
    );
  }
}

/// Round brushed-silver plate with a double blue ring and two gold screws,
/// echoing the logo.
class _PlaquePainter extends CustomPainter {
  const _PlaquePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.width / 2;
    final Rect rect = Rect.fromCircle(center: c, radius: r);

    // Hard shadow, same style as the other stickers.
    canvas.drawCircle(c + const Offset(8, 8), r, Paint()..color = AppTheme.ink);

    // Brushed metal.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const SweepGradient(
          colors: [
            Color(0xFFF4F4F2),
            Color(0xFFCFCFCC),
            Color(0xFFF1F1EF),
            Color(0xFFBDBDBA),
            Color(0xFFF4F4F2),
            Color(0xFFCFCFCC),
            Color(0xFFF1F1EF),
            Color(0xFFBDBDBA),
            Color(0xFFF4F4F2),
          ],
        ).createShader(rect),
    );

    // Edge.
    canvas.drawCircle(
      c,
      r - 1.2,
      Paint()
        ..color = AppTheme.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Double blue ring.
    canvas.drawCircle(
      c,
      r * 0.92,
      Paint()
        ..color = AppTheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    canvas.drawCircle(
      c,
      r * 0.85,
      Paint()
        ..color = AppTheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Gold screws at the top and bottom.
    for (final double dy in [-r * 0.92, r * 0.92]) {
      final Offset p = c + Offset(0, dy);

      canvas.drawCircle(
        p,
        8,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, -0.3),
            colors: [Color(0xFFF3E2B5), Color(0xFFB8935C), Color(0xFF8A6A3F)],
          ).createShader(Rect.fromCircle(center: p, radius: 8)),
      );

      canvas.drawCircle(
        p,
        8,
        Paint()
          ..color = AppTheme.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Small gold screw.
class _Rivet extends StatelessWidget {
  final double size;

  const _Rivet({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFF3E2B5), Color(0xFFB8935C), Color(0xFF8A6A3F)],
        ),
        border: Border.all(color: AppTheme.ink, width: 1.3),
      ),
    );
  }
}

/// Four-point star, like the one on the logo.
class _Sparkle extends StatelessWidget {
  final double size;
  final Color color;

  const _Sparkle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SparklePainter(color)),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;

  const _SparklePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Path star = Path()
      ..moveTo(w / 2, 0)
      ..quadraticBezierTo(w / 2, h / 2, w, h / 2)
      ..quadraticBezierTo(w / 2, h / 2, w / 2, h)
      ..quadraticBezierTo(w / 2, h / 2, 0, h / 2)
      ..quadraticBezierTo(w / 2, h / 2, w / 2, 0)
      ..close();

    canvas.drawPath(star, Paint()..color = color);

    canvas.drawPath(
      star,
      Paint()
        ..color = AppTheme.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _HeroBackdropPainter extends CustomPainter {
  const _HeroBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Big warm circle top-right and a soft green one bottom-left.
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.1),
      math.min(size.width, 560) * 0.36,
      Paint()..color = AppTheme.sunSoft,
    );

    canvas.drawCircle(
      Offset(size.width * 0.04, size.height),
      270,
      Paint()..color = AppTheme.mintSoft,
    );

    // A silver circle at the bottom.
    canvas.drawCircle(
      Offset(size.width * 0.58, size.height * 1.04),
      210,
      Paint()..color = AppTheme.stone.withValues(alpha: 0.5),
    );

    // Paper-like dot pattern.
    final Paint dot = Paint()..color = AppTheme.primary.withValues(alpha: 0.12);

    for (double x = 15; x < size.width; x += 30) {
      for (double y = 15; y < size.height; y += 30) {
        canvas.drawCircle(Offset(x, y), 1.5, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═════════════════════════════════════════════════════════════
// MARQUEE
// ═════════════════════════════════════════════════════════════

class _Marquee extends StatefulWidget {
  final List<String> items;
  final bool running;
  final double fontSize;

  const _Marquee({
    required this.items,
    required this.running,
    required this.fontSize,
  });

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee>
    with SingleTickerProviderStateMixin {
  static const double _pixelsPerSecond = 55;

  final ScrollController _controller = ScrollController();
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker(_onTick)..start();
    _ticker.muted = !widget.running;
  }

  @override
  void didUpdateWidget(covariant _Marquee oldWidget) {
    super.didUpdateWidget(oldWidget);

    _ticker.muted = !widget.running;
  }

  void _onTick(Duration elapsed) {
    if (!_controller.hasClients) {
      return;
    }

    _controller.jumpTo(elapsed.inMicroseconds / 1000000.0 * _pixelsPerSecond);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return ExcludeSemantics(
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final String text = widget.items[index % widget.items.length];

          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Text(
                    text,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w800,
                      // Alternate royal blue and navy words.
                      color: index.isEven
                          ? AppTheme.primary
                          : AppTheme.primaryDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Icon(
                  Icons.add_rounded,
                  size: widget.fontSize * 1.25,
                  color: AppTheme.sun,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// NAV ITEM (with sliding underline)
// ═════════════════════════════════════════════════════════════

class _NavItem extends StatefulWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool highlighted = widget.active || _hovering;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<Color?>(
                duration: const Duration(milliseconds: 200),
                tween: ColorTween(
                  end: highlighted ? AppTheme.primary : AppTheme.textSecondary,
                ),
                builder: (context, color, _) {
                  return Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                height: 3,
                width: widget.active
                    ? 26
                    : _hovering
                    ? 12
                    : 0,
                decoration: BoxDecoration(
                  color: AppTheme.coral,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// MOBILE MENU ITEM
// ═════════════════════════════════════════════════════════════

class _MobileMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MobileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  State<_MobileMenuItem> createState() => _MobileMenuItemState();
}

class _MobileMenuItemState extends State<_MobileMenuItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: _hovering ? AppTheme.mintSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _hovering ? AppTheme.primary : AppTheme.mint,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 21,
                      color: _hovering ? Colors.white : AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 160),
                    offset: _hovering
                        ? Offset(rtl ? -0.15 : 0.15, 0)
                        : Offset.zero,
                    child: Icon(
                      rtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      size: 22,
                      color: _hovering ? AppTheme.primary : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// HOVER SCALE
// ═════════════════════════════════════════════════════════════

class _HoverScale extends StatefulWidget {
  final Widget child;
  final double scale;

  const _HoverScale({required this.child, this.scale = 1.04});

  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? widget.scale : 1,
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// HEADER LOGO BUTTON
// ═════════════════════════════════════════════════════════════

class _HeaderLogoButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _HeaderLogoButton({required this.onTap, required this.child});

  @override
  State<_HeaderLogoButton> createState() => _HeaderLogoButtonState();
}

class _HeaderLogoButtonState extends State<_HeaderLogoButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovering ? 1.04 : 1,
          duration: const Duration(milliseconds: 160),
          child: widget.child,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// SCROLL TO TOP
// ═════════════════════════════════════════════════════════════

class _ScrollTopButton extends StatefulWidget {
  final VoidCallback onTap;
  final String tooltip;

  const _ScrollTopButton({required this.onTap, required this.tooltip});

  @override
  State<_ScrollTopButton> createState() => _ScrollTopButtonState();
}

class _ScrollTopButtonState extends State<_ScrollTopButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, _hovering ? -3.0 : 0.0, 0),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.ink, width: 2),
          boxShadow: const [
            BoxShadow(color: AppTheme.ink, offset: Offset(3, 3)),
          ],
        ),
        child: IconButton(
          onPressed: widget.onTap,
          tooltip: widget.tooltip,
          icon: const Icon(
            Icons.keyboard_arrow_up_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// CALL SHEET (choose which number to call)
// ═════════════════════════════════════════════════════════════

class _CallSheet extends StatelessWidget {
  final String title;
  final List<String> numbers;
  final String Function(String) format;
  final ValueChanged<String> onSelect;

  const _CallSheet({
    required this.title,
    required this.numbers,
    required this.format,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.paddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: EdgeInsets.fromLTRB(14, 0, 14, 16 + bottom),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.ink, width: 2),
            boxShadow: const [
              BoxShadow(color: AppTheme.ink, offset: Offset(5, 5)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.stone,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              for (int i = 0; i < numbers.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _CallNumberTile(
                  number: format(numbers[i]),
                  onTap: () => onSelect(numbers[i]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CallNumberTile extends StatefulWidget {
  final String number;
  final VoidCallback onTap;

  const _CallNumberTile({required this.number, required this.onTap});

  @override
  State<_CallNumberTile> createState() => _CallNumberTileState();
}

class _CallNumberTileState extends State<_CallNumberTile> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _active => _hovered || _pressed;

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _active ? -2.0 : 0.0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          decoration: BoxDecoration(
            color: _active ? AppTheme.primary : AppTheme.mint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                Icons.phone_rounded,
                size: 21,
                color: _active ? Colors.white : AppTheme.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.number,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: _active ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
              Icon(
                rtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                size: 19,
                color: _active ? Colors.white : AppTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
