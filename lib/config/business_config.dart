class BusinessConfig {
  // ═════════════════════════════════════════════════════════════
  // PHARMACY INFORMATION
  // ═════════════════════════════════════════════════════════════

  static const String businessName = 'Diane Pharmacy';

  static const String tagline = 'Your health, our priority.';

  static const String description =
      'Your trusted local pharmacy, providing professional '
      'healthcare support, everyday medicines, wellness products, '
      'and friendly service for you and your family.';

  // ═════════════════════════════════════════════════════════════
  // CONTACT INFORMATION
  // ═════════════════════════════════════════════════════════════

  static const String phone = '+963 986 889 132';

  static const String whatsapp = '+963986889132';

  static const String address = '649R+65Q, Aleppo, Syria';

  // Every number offered when a visitor taps "Call". The first one is the
  // main number shown elsewhere on the site.
  static const List<String> phones = [
    phone,
    '+963 954 556 425',
    '+963 958 460 803',
  ];

  // ═════════════════════════════════════════════════════════════
  // OPENING HOURS
  // ═════════════════════════════════════════════════════════════

  // IMPORTANT: confirm AM/PM before publishing.
  static const String openingHoursOpen =
      'Saturday – Thursday: 9:30 AM – 10:30 PM';

  static const String openingHoursClosed = 'Friday: Closed';

  // These numbers drive the live "Open now / Closed now" badge and the
  // highlighted day in the opening hours card. Keep them in sync with the
  // text above. Times are minutes after midnight, 24-hour clock.
  //
  // The badge always uses the pharmacy's local time (Syria, UTC+3), no
  // matter where the visitor is.
  static const int utcOffsetHours = 3;
  static const int openMinutes = 9 * 60 + 30; // 9:30 AM
  static const int closeMinutes = 22 * 60 + 30; // 10:30 PM
  static const List<int> closedWeekdays = [DateTime.friday];

  // ═════════════════════════════════════════════════════════════
  // SOCIAL MEDIA
  // ═════════════════════════════════════════════════════════════

  static const String instagram = 'https://www.instagram.com/diane_pharmacy';

  // ═════════════════════════════════════════════════════════════
  // LOCATION / WEBSITE
  // ═════════════════════════════════════════════════════════════

  static const String googleMaps =
      'https://www.google.com/maps/search/?api=1&query=649R%2B65Q%20Aleppo%2C%20Syria';

  // The live public address of the website.
  static const String website = 'https://dianepharmacy.netlify.app';

  // ═════════════════════════════════════════════════════════════
  // BRANDING
  // ═════════════════════════════════════════════════════════════

  // File must exist at assets/images/pharmacy_logo.jpg
  // (lowercase, exact extension) and assets/images/ must be
  // declared in pubspec.yaml.
  static const String logoAsset = 'assets/images/pharmacy_logo.jpg';

  // ═════════════════════════════════════════════════════════════
  // ABOUT THE PHARMACY
  // ═════════════════════════════════════════════════════════════

  static const String aboutTitle =
      'More than a pharmacy. A place you can trust.';

  static const String aboutText =
      'We are committed to making healthcare simple, accessible, '
      'and personal. Our pharmacy team is here to help you find '
      'the products and support you need, with professional care '
      'and a friendly approach.';

  // ═════════════════════════════════════════════════════════════
  // PHARMACY SERVICES
  // ═════════════════════════════════════════════════════════════

  static const List<Map<String, String>> services = [
    {
      'icon': '💊',
      'title': 'Prescription Medicines',
      'description':
          'Reliable access to prescription medicines with '
          'professional pharmacy support.',
    },
    {
      'icon': '🩺',
      'title': 'Health Advice',
      'description':
          'Friendly guidance and practical advice for your '
          'everyday healthcare needs.',
    },
    {
      'icon': '❤️',
      'title': 'Wellness & Vitamins',
      'description':
          'A selection of vitamins, supplements, and wellness '
          'products for you and your family.',
    },
    {
      'icon': '👶',
      'title': 'Family Care',
      'description':
          'Healthcare essentials and products for babies, '
          'children, adults, and families.',
    },
    {
      'icon': '🧴',
      'title': 'Personal Care',
      'description':
          'Personal care, skincare, hygiene, and everyday '
          'health products.',
    },
    {
      'icon': '📍',
      'title': 'Easy to Reach',
      'description':
          'Find our pharmacy quickly with directions through '
          'Google Maps.',
    },
  ];

  // ═════════════════════════════════════════════════════════════
  // QUICK PHARMACY FEATURES
  // ═════════════════════════════════════════════════════════════

  static const List<Map<String, String>> features = [
    {
      'icon': '✓',
      'title': 'Professional',
      'description': 'Friendly and professional pharmacy service.',
    },
    {
      'icon': '♥',
      'title': 'Patient Focused',
      'description': 'Your health and wellbeing come first.',
    },
    {
      'icon': '⌚',
      'title': 'Convenient',
      'description': 'Easy contact, directions, and pharmacy information.',
    },
  ];

  // ═════════════════════════════════════════════════════════════
  // FOOTER
  // ═════════════════════════════════════════════════════════════

  static const String footerText =
      '© 2026 Diane Pharmacy. All rights reserved.';
}
