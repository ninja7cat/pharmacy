import '../config/business_config.dart';
import '../config/business_config_ar.dart';

/// All visible website text in English and Arabic.
class AppStrings {
  final bool isArabic;

  const AppStrings(this.isArabic);

  String _t(String en, String ar) => isArabic ? ar : en;

  /// Keeps phone numbers and e-mails left-to-right inside Arabic text.
  String ltr(String value) => isArabic ? '\u200E$value\u200E' : value;

  // ── Business content ───────────────────────────────────────────
  String get businessName =>
      isArabic ? BusinessConfigAr.businessName : BusinessConfig.businessName;

  String get tagline =>
      isArabic ? BusinessConfigAr.tagline : BusinessConfig.tagline;

  String get description =>
      isArabic ? BusinessConfigAr.description : BusinessConfig.description;

  String get aboutTitle =>
      isArabic ? BusinessConfigAr.aboutTitle : BusinessConfig.aboutTitle;

  String get aboutText =>
      isArabic ? BusinessConfigAr.aboutText : BusinessConfig.aboutText;

  String get address =>
      isArabic ? BusinessConfigAr.address : BusinessConfig.address;

  String get hoursOpen => isArabic
      ? BusinessConfigAr.openingHoursOpen
      : BusinessConfig.openingHoursOpen;

  String get hoursClosed => isArabic
      ? BusinessConfigAr.openingHoursClosed
      : BusinessConfig.openingHoursClosed;

  List<Map<String, String>> get services =>
      isArabic ? BusinessConfigAr.services : BusinessConfig.services;

  String get footerText =>
      isArabic ? BusinessConfigAr.footerText : BusinessConfig.footerText;

  // ── Language switch ────────────────────────────────────────────
  String get languageSwitchLabel => _t('العربية', 'English');
  String get languageSwitchShort => _t('عربي', 'EN');

  // ── Navigation ─────────────────────────────────────────────────
  String get navHome => _t('Home', 'الرئيسية');
  String get navAbout => _t('About', 'من نحن');
  String get navServices => _t('Services', 'خدماتنا');
  String get navContact => _t('Contact', 'تواصل معنا');
  String get menuOpen => _t('Open menu', 'فتح القائمة');
  String get menuClose => _t('Close menu', 'إغلاق القائمة');
  String get backToTop => _t('Back to top', 'العودة للأعلى');

  // ── Buttons ────────────────────────────────────────────────────
  String get whatsapp => _t('WhatsApp', 'واتساب');
  String get chatOnWhatsApp => _t('Chat on WhatsApp', 'تواصل عبر واتساب');
  String get findPharmacy => _t('Find Our Pharmacy', 'موقع الصيدلية');
  String get callUs => _t('Call Us', 'اتصل بنا');
  String get directions => _t('Directions', 'الاتجاهات');
  String get callSub => _t('Choose a number', 'اختر رقماً للاتصال');
  String get callSheetTitle =>
      _t('Which number would you like to call?', 'بأي رقم تريد الاتصال؟');
  String get instagram => _t('Instagram', 'إنستغرام');

  // ── Mobile action bar ──────────────────────────────────────────
  String get barWhatsApp => _t('WhatsApp', 'واتساب');
  String get barCall => _t('Call', 'اتصال');
  String get barLocation => _t('Location', 'الموقع');

  // ── Live opening status ────────────────────────────────────────
  String get statusOpen => _t('Open now', 'مفتوح الآن');
  String get statusClosed => _t('Closed now', 'مغلق الآن');

  String closesAt(String time) => _t('closes at $time', 'يغلق الساعة $time');
  String opensTodayAt(String time) =>
      _t('opens today at $time', 'يفتح اليوم الساعة $time');
  String opensTomorrowAt(String time) =>
      _t('opens tomorrow at $time', 'يفتح غداً الساعة $time');
  String opensDayAt(String day, String time) =>
      _t('opens $day at $time', 'يفتح يوم $day الساعة $time');

  /// Formats minutes since midnight as a 12-hour clock, e.g. 9:30 AM.
  String clock(int minutesSinceMidnight) {
    final int hour24 = (minutesSinceMidnight ~/ 60) % 24;
    final int minute = minutesSinceMidnight % 60;
    final int hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final String mm = minute.toString().padLeft(2, '0');
    final bool pm = hour24 >= 12;
    final String suffix = isArabic ? (pm ? 'م' : 'ص') : (pm ? 'PM' : 'AM');

    return '$hour12:$mm $suffix';
  }

  /// [weekday] follows DateTime: Monday = 1 … Sunday = 7.
  String weekdayLong(int weekday) {
    const List<String> en = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const List<String> ar = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];

    return (isArabic ? ar : en)[(weekday - 1) % 7];
  }

  String weekdayShort(int weekday) {
    const List<String> en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const List<String> ar = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];

    return (isArabic ? ar : en)[(weekday - 1) % 7];
  }

  String get todayLabel => _t('Today', 'اليوم');

  // ── Hero ───────────────────────────────────────────────────────
  String get trustedPharmacy =>
      _t('Trusted local pharmacy', 'صيدلية محلية موثوقة');
  String get trustProfessional => _t('Professional care', 'رعاية احترافية');
  String get trustAvailable => _t('Here when you need us', 'معك عندما تحتاجنا');
  String get trustPatient => _t('Patient focused', 'المريض أولاً');
  String get explore => _t('Explore', 'استكشف');
  String get badgePharmacyTitle => _t('Pharmacy', 'صيدلية');
  String get badgePharmacySub => _t('Professional care', 'رعاية احترافية');
  String get badgeHealthTitle => _t('Your health', 'صحتك');
  String get badgeHealthSub => _t('Comes first', 'تأتي أولاً');

  // ── Quick actions ──────────────────────────────────────────────
  String get quickEyebrow => _t('SAY HELLO', 'تواصل معنا');
  String get quickTitle => _t('Got a question? Ask us.', 'عندك سؤال؟ اسألنا.');
  String get quickSubtitle => _t(
    'Message, call or come by. Whatever is easiest for you.',
    'راسلنا أو اتصل بنا أو زرنا. الأسهل بالنسبة لك.',
  );
  String get cardWhatsAppSub => _t('Message our pharmacy', 'راسل صيدليتنا');
  String get cardFindTitle => _t('Find Us', 'موقعنا');
  String get cardFindSub => _t('Get directions', 'احصل على الاتجاهات');
  String get cardInstagramSub => _t('Follow our pharmacy', 'تابع صيدليتنا');

  // ── About ──────────────────────────────────────────────────────
  String get aboutPill => _t('ABOUT OUR PHARMACY', 'عن صيدليتنا');
  String get aboutFallbackTitle =>
      _t('Professional pharmacy care', 'رعاية صيدلانية احترافية');
  String get aboutFallbackSub =>
      _t('Here for you and your family', 'هنا من أجلك ومن أجل عائلتك');
  String get aboutPoint1Title => _t('Professional support', 'دعم احترافي');
  String get aboutPoint1Text => _t(
    'Friendly assistance for your everyday healthcare needs.',
    'مساعدة ودودة لاحتياجاتك الصحية اليومية.',
  );
  String get aboutPoint2Title => _t('Patient focused', 'المريض أولاً');
  String get aboutPoint2Text => _t(
    'We put your comfort and wellbeing first.',
    'نضع راحتك وسلامتك في المقام الأول.',
  );
  String get aboutPoint3Title =>
      _t('For the whole family', 'لجميع أفراد العائلة');
  String get aboutPoint3Text => _t(
    'Healthcare essentials for adults, children, and families.',
    'مستلزمات صحية للكبار والأطفال والعائلات.',
  );

  // ── Services ───────────────────────────────────────────────────
  String get servicesEyebrow => _t('WHAT WE DO', 'ما نقدمه');
  String get servicesTitle => _t('How we can help', 'كيف نساعدك');
  String get servicesSubtitle => _t(
    'Healthcare essentials and pharmacy support for everyday life. Tap any card to ask us about it.',
    'مستلزمات صحية ودعم صيدلاني لحياتك اليومية. اضغط على أي بطاقة لتسألنا عنها.',
  );
  String get askAboutThis => _t('Ask us', 'اسألنا');

  /// Pre-filled WhatsApp message when a service card is tapped.
  String askAboutService(String service) => _t(
    "Hello, I'd like to ask about: $service",
    'مرحباً، أريد الاستفسار عن: $service',
  );

  // ── Visit us ───────────────────────────────────────────────────
  String get visitAddressTitle => _t('Visit us', 'زرنا');
  String get visitHoursTitle => _t('Opening hours', 'ساعات العمل');

  // ── Contact ────────────────────────────────────────────────────
  String get contactEyebrow =>
      _t('NEED HELP WITH YOUR HEALTH?', 'هل تحتاج مساعدة بخصوص صحتك؟');
  String get contactTitle => _t('We are here for you.', 'نحن هنا من أجلك.');
  String get contactBody => _t(
    'Contact $businessName or visit us at our pharmacy.',
    'تواصل مع $businessName أو قم بزيارتنا في الصيدلية.',
  );
}
