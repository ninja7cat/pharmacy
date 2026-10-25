/// Arabic version of the business content.
///
/// Phone, WhatsApp, e-mail, social links and map links are shared with the
/// English site and stay in `BusinessConfig`. Only translatable text lives
/// here. Replace these texts when the final pharmacy content is ready.
class BusinessConfigAr {
  static const String businessName = 'صيدلية ديان';

  static const String tagline = 'صحتك، أولويتنا.';

  static const String description =
      'صيدليتكم المحلية الموثوقة، نقدم دعماً صحياً احترافياً '
      'وأدوية يومية ومنتجات للعناية بالصحة وخدمة ودودة '
      'لكم ولعائلتكم.';

  static const String aboutTitle = 'أكثر من مجرد صيدلية. مكان يمكنك الوثوق به.';

  static const String aboutText =
      'نلتزم بجعل الرعاية الصحية بسيطة ومتاحة وقريبة منك. '
      'فريق الصيدلية هنا لمساعدتك في إيجاد المنتجات والدعم '
      'الذي تحتاجه، بخدمة احترافية وأسلوب ودود.';

  static const String address = '649R+65Q، حلب، سوريا';

  static const String openingHoursOpen =
      'من السبت إلى الخميس: 9:30 ص – 10:30 م';

  static const String openingHoursClosed = 'الجمعة: مغلق';

  static const List<Map<String, String>> services = [
    {
      'icon': '💊',
      'title': 'الأدوية بوصفة طبية',
      'description':
          'وصول موثوق إلى الأدوية الموصوفة مع دعم صيدلاني '
          'احترافي.',
    },
    {
      'icon': '🩺',
      'title': 'نصائح صحية',
      'description':
          'إرشادات ودودة ونصائح عملية لاحتياجاتك الصحية '
          'اليومية.',
    },
    {
      'icon': '❤️',
      'title': 'العافية والفيتامينات',
      'description':
          'مجموعة من الفيتامينات والمكملات ومنتجات العافية '
          'لك ولعائلتك.',
    },
    {
      'icon': '👶',
      'title': 'رعاية العائلة',
      'description':
          'مستلزمات ومنتجات صحية للرضع والأطفال والبالغين '
          'والعائلات.',
    },
    {
      'icon': '🧴',
      'title': 'العناية الشخصية',
      'description':
          'منتجات العناية الشخصية والبشرة والنظافة والصحة '
          'اليومية.',
    },
    {
      'icon': '📍',
      'title': 'سهولة الوصول',
      'description':
          'اعثر على صيدليتنا بسرعة عبر الاتجاهات في خرائط '
          'جوجل.',
    },
  ];

  static const String footerText = '© 2026 صيدلية ديان. جميع الحقوق محفوظة.';
}
