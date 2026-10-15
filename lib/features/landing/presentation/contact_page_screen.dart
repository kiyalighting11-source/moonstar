// lib/features/landing/presentation/contact_page_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/widgets/scroll_animations.dart';
import 'widgets/landing_footer.dart';
import 'widgets/landing_navbar.dart';
import 'widgets/mobile_menu_drawer.dart';

class ContactPageScreen extends StatefulWidget {
  const ContactPageScreen({super.key});

  @override
  State<ContactPageScreen> createState() => _ContactPageScreenState();
}

class _ContactPageScreenState extends State<ContactPageScreen> {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showBackToTop = false;

  // ⭐ إحداثيات Moonstar
  static const double _companyLat = 30.0903605;
  static const double _companyLng = 31.2577515;

  // =====================================================
  // ⭐ السوشيال ميديا
  // =====================================================
  static final List<_SocialLink> _socials = [
    _SocialLink(
      name: 'Facebook',
      handle: '@moonstar',
      icon: Icons.facebook,
      color: const Color(0xFF1877F2),
      url: 'https://facebook.com/moonstar',
    ),
    _SocialLink(
      name: 'Instagram',
      handle: '@moonstar',
      icon: Icons.camera_alt,
      color: const Color(0xFFE4405F),
      url: 'https://instagram.com/moonstar',
    ),
    _SocialLink(
      name: 'WhatsApp',
      handle: '01026265026',
      icon: Icons.chat,
      color: const Color(0xFF25D366),
      url: 'https://wa.me/201026265026',
    ),
    _SocialLink(
      name: 'YouTube',
      handle: '@moonstar',
      icon: Icons.play_circle_fill,
      color: const Color(0xFFFF0000),
      url: 'https://youtube.com/@moonstar',
    ),
    _SocialLink(
      name: 'TikTok',
      handle: '@moonstar',
      icon: Icons.music_note,
      color: const Color(0xFF000000),
      url: 'https://tiktok.com/@moonstar',
    ),
    _SocialLink(
      name: 'LinkedIn',
      handle: 'moonstar',
      icon: Icons.business,
      color: const Color(0xFF0A66C2),
      url: 'https://linkedin.com/company/moonstar',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final show = _scrollController.offset > 600;
    if (show != _showBackToTop) {
      setState(() => _showBackToTop = show);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const MobileMenuDrawer(),
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Navbar
              SliverPersistentHeader(
                pinned: true,
                delegate: _NavbarDelegate(
                  child: LandingNavbar(
                    scrollController: _scrollController,
                    isTransparent: true,
                    showNavLinks: true,
                    onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                  ),
                ),
              ),

              // 1. Hero
              SliverToBoxAdapter(child: _buildHero(context)),

              // 2. Contact Cards (تليفون / واتساب / إيميل / عنوان)
              SliverToBoxAdapter(child: _buildContactCards(context)),

              // 3. Social Media Grid
              SliverToBoxAdapter(child: _buildSocialGrid(context)),

              // 4. Map
              SliverToBoxAdapter(child: _buildMap(context)),

              // 5. Contact Form
              SliverToBoxAdapter(child: _buildContactForm(context)),

              // Footer
              const SliverToBoxAdapter(child: LandingFooter()),
            ],
          ),

          // Back to Top
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            bottom: _showBackToTop ? 30 : -80,
            right: 30,
            child: _buildBackToTopButton(),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 1. Hero
  // =====================================================
  Widget _buildHero(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getHorizontalPadding(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: isMobile ? 60 : 100,
      ),
      child: Column(
        children: [
          FadeInOnScroll(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'تواصل معنا',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeInOnScroll(
            delay: const Duration(milliseconds: 100),
            child: Text(
              'اتصل بنا',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 48 : 80,
                fontWeight: FontWeight.w900,
                color: AppTheme.textColor(context),
                height: 1,
                letterSpacing: -2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeInOnScroll(
            delay: const Duration(milliseconds: 200),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Text(
                'فريقنا جاهز يساعدك في أي وقت — تواصل معانا من أي مكان',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondaryColor(context),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 2. Contact Cards
  // =====================================================
  Widget _buildContactCards(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getHorizontalPadding(context);

    final cards = [
      _ContactCard(
        icon: Icons.call,
        title: 'اتصل بنا',
        value: CompanyInfo.phone,
        subtitle: 'متاح من 13:30 حتى 22:30',
        color: const Color(0xFF43A047),
        onTap: () => _launchUrl('tel:${CompanyInfo.phone}'),
      ),
      _ContactCard(
        icon: Icons.chat,
        title: 'واتساب',
        value: CompanyInfo.whatsapp,
        subtitle: 'رد فوري خلال دقايق',
        color: const Color(0xFF25D366),
        onTap: () => _launchUrl('https://wa.me/2${CompanyInfo.whatsapp}'),
      ),
      _ContactCard(
        icon: Icons.email,
        title: 'البريد الإلكتروني',
        value: CompanyInfo.email,
        subtitle: 'نرد خلال 24 ساعة',
        color: const Color(0xFF1E88E5),
        onTap: () => _launchUrl('mailto:${CompanyInfo.email}'),
      ),
      _ContactCard(
        icon: Icons.location_on,
        title: 'العنوان',
        value: CompanyInfo.address,
        subtitle: 'افتح الخريطة للوصول',
        color: const Color(0xFFE53935),
        onTap: () => _launchUrl(CompanyInfo.googleMapsUrl),
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: 40,
      ),
      child: isMobile
          ? Column(
              children: cards
                  .asMap()
                  .entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FadeInOnScroll(
                          delay: Duration(milliseconds: 100 * e.key),
                          child: _buildContactCard(context, e.value),
                        ),
                      ))
                  .toList(),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 2.8,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                return FadeInOnScroll(
                  delay: Duration(milliseconds: 100 * index),
                  child: _buildContactCard(context, cards[index]),
                );
              },
            ),
    );
  }

  Widget _buildContactCard(BuildContext context, _ContactCard card) {
    return _ContactCardWidget(card: card);
  }

  // =====================================================
  // 3. Social Media Grid
  // =====================================================
  Widget _buildSocialGrid(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getHorizontalPadding(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: 60,
      ),
      child: Column(
        children: [
          // Header
          FadeInOnScroll(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.share,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'تابعنا',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'على السوشيال ميديا',
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 42,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textColor(context),
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Text(
                    'تابعنا عشان تشوف أحدث منتجاتنا ومشاريعنا',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: AppTheme.textSecondaryColor(context),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isMobile ? 1.1 : 1.4,
            ),
            itemCount: _socials.length,
            itemBuilder: (context, index) {
              return FadeInOnScroll(
                delay: Duration(milliseconds: 100 * index),
                child: _SocialCard(social: _socials[index]),
              );
            },
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 4. Map
  // =====================================================
  Widget _buildMap(BuildContext context) {
    final padding = ResponsiveHelper.getHorizontalPadding(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: 40,
      ),
      child: FadeInOnScroll(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'موقعنا',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'زورونا',
              style: TextStyle(
                fontSize: isMobile ? 28 : 42,
                fontWeight: FontWeight.w900,
                color: AppTheme.textColor(context),
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              height: isMobile ? 350 : 500,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    FlutterMap(
                      options: const MapOptions(
                        initialCenter: LatLng(_companyLat, _companyLng),
                        initialZoom: 16,
                        minZoom: 5,
                        maxZoom: 18,
                        interactionOptions: InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.moonstar.erp',
                          tileProvider: NetworkTileProvider(),
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: const LatLng(
                                _companyLat,
                                _companyLng,
                              ),
                              width: 80,
                              height: 80,
                              alignment: Alignment.topCenter,
                              child: _buildMarker(),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Badge
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.successColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Moonstar',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // زرار Google Maps
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: ElevatedButton.icon(
                        onPressed: () => _launchUrl(CompanyInfo.googleMapsUrl),
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('فتح في Google Maps'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on,
            color: Colors.white,
            size: 24,
          ),
        ),
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // 5. Contact Form
  // =====================================================
  Widget _buildContactForm(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getHorizontalPadding(context);
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: 60,
      ),
      child: FadeInOnScroll(
        child: Container(
          padding: EdgeInsets.all(isMobile ? 24 : 40),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF151A23).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.email_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أرسل لنا رسالة',
                          style: TextStyle(
                            fontSize: isMobile ? 22 : 28,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'هنرد عليك في أقرب وقت ممكن',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondaryColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Form fields
              isMobile
                  ? Column(
                      children: [
                        _buildFormField(
                          context,
                          label: 'الاسم بالكامل',
                          hint: 'ادخل اسمك',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          context,
                          label: 'رقم الموبايل',
                          hint: '01xxxxxxxxx',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            context,
                            label: 'الاسم بالكامل',
                            hint: 'ادخل اسمك',
                            icon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            context,
                            label: 'رقم الموبايل',
                            hint: '01xxxxxxxxx',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 16),
              _buildFormField(
                context,
                label: 'البريد الإلكتروني',
                hint: 'example@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                context,
                label: 'الموضوع',
                hint: 'اكتب موضوع الرسالة',
                icon: Icons.subject,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                context,
                label: 'الرسالة',
                hint: 'اكتب رسالتك هنا...',
                icon: Icons.message_outlined,
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إرسال رسالتك بنجاح! هنرد عليك قريب.'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  },
                  icon: const Icon(Icons.send),
                  label: const Text(
                    'إرسال الرسالة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  Widget _buildFormField(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final isDark = AppTheme.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppTheme.textSecondaryColor(context),
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: AppTheme.primaryColor),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppTheme.lightBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // Back to Top
  // =====================================================
  Widget _buildBackToTopButton() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _showBackToTop ? 1.0 : 0.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _scrollToTop,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryLight,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.keyboard_arrow_up,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // Helper
  // =====================================================
  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}

// =====================================================
// Contact Card Widget
// =====================================================
class _ContactCardWidget extends StatefulWidget {
  final _ContactCard card;

  const _ContactCardWidget({required this.card});

  @override
  State<_ContactCardWidget> createState() => _ContactCardWidgetState();
}

class _ContactCardWidgetState extends State<_ContactCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final card = widget.card;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: card.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF151A23).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  _isHovered ? card.color : card.color.withValues(alpha: 0.2),
              width: _isHovered ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: card.color.withValues(alpha: _isHovered ? 0.3 : 0.1),
                blurRadius: _isHovered ? 30 : 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: card.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(card.icon, color: card.color, size: 26),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      card.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: card.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// Social Card Widget
// =====================================================
class _SocialCard extends StatefulWidget {
  final _SocialLink social;

  const _SocialCard({required this.social});

  @override
  State<_SocialCard> createState() => _SocialCardState();
}

class _SocialCardState extends State<_SocialCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final social = widget.social;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          try {
            final uri = Uri.parse(social.url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } catch (_) {}
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isHovered
                ? social.color
                : (isDark
                    ? const Color(0xFF151A23).withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: social.color.withValues(alpha: _isHovered ? 0 : 0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: social.color.withValues(alpha: _isHovered ? 0.5 : 0.1),
                blurRadius: _isHovered ? 30 : 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? Colors.white.withValues(alpha: 0.2)
                      : social.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  social.icon,
                  color: _isHovered ? Colors.white : social.color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                social.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color:
                      _isHovered ? Colors.white : AppTheme.textColor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                social.handle,
                style: TextStyle(
                  fontSize: 12,
                  color: _isHovered
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppTheme.textSecondaryColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// Models
// =====================================================
class _ContactCard {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _SocialLink {
  final String name;
  final String handle;
  final IconData icon;
  final Color color;
  final String url;

  _SocialLink({
    required this.name,
    required this.handle,
    required this.icon,
    required this.color,
    required this.url,
  });
}

// =====================================================
// Navbar Delegate
// =====================================================
class _NavbarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _NavbarDelegate({required this.child});

  @override
  double get minExtent => 72;

  @override
  double get maxExtent => 72;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _NavbarDelegate oldDelegate) {
    return false;
  }
}
