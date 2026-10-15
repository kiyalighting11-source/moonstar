// lib/features/landing/presentation/about_page_screen.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/widgets/scroll_animations.dart';
import 'widgets/landing_footer.dart';
import 'widgets/landing_navbar.dart';
import 'widgets/mobile_menu_drawer.dart';

class AboutPageScreen extends StatefulWidget {
  const AboutPageScreen({super.key});

  @override
  State<AboutPageScreen> createState() => _AboutPageScreenState();
}

class _AboutPageScreenState extends State<AboutPageScreen> {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showBackToTop = false;

  // =====================================================
  // ⭐ فريق العمل (غيّر البيانات والصور)
  // =====================================================
  static final List<_TeamMember> _team = [
    _TeamMember(
      name: 'محمد أحمد',
      title: 'المدير التنفيذي',
      description: 'خبرة 20+ سنة في صناعة الإضاءة والشاشات',
      imageUrl: 'assets/images/team_1.jpg',
      color: const Color(0xFF6A1B9A),
      social: [
        _Social(Icons.facebook, 'https://facebook.com'),
        _Social(Icons.business, 'https://linkedin.com'),
      ],
    ),
    _TeamMember(
      name: 'سارة محمود',
      title: 'مدير المبيعات',
      description: 'خبرة 10+ سنوات في خدمة العملاء',
      imageUrl: 'assets/images/team_2.jpg',
      color: const Color(0xFF00ACC1),
      social: [
        _Social(Icons.facebook, 'https://facebook.com'),
        _Social(Icons.camera_alt, 'https://instagram.com'),
      ],
    ),
    _TeamMember(
      name: 'خالد عبدالله',
      title: 'مدير الإنتاج',
      description: 'متخصص في تركيب الأنظمة المعقدة',
      imageUrl: 'assets/images/team_3.jpg',
      color: const Color(0xFFFB8C00),
      social: [
        _Social(Icons.facebook, 'https://facebook.com'),
      ],
    ),
    _TeamMember(
      name: 'منى إبراهيم',
      title: 'مدير التسويق',
      description: 'متخصصة في التسويق الرقمي',
      imageUrl: 'assets/images/team_4.jpg',
      color: const Color(0xFF43A047),
      social: [
        _Social(Icons.camera_alt, 'https://instagram.com'),
        _Social(Icons.business, 'https://linkedin.com'),
      ],
    ),
  ];

  // =====================================================
  // ⭐ Timeline (رحلة الشركة)
  // =====================================================
  static const List<_TimelineEvent> _timeline = [
    _TimelineEvent(
      year: '2009',
      title: 'التأسيس',
      description: 'بدأنا رحلتنا في القاهرة كمزود صغير لحلول الإضاءة',
      icon: Icons.flag,
      color: Color(0xFF6A1B9A),
    ),
    _TimelineEvent(
      year: '2013',
      title: 'التوسع الأول',
      description: 'افتتاح أول معرض رئيسي وتوسيع قاعدة العملاء',
      icon: Icons.storefront,
      color: Color(0xFF00ACC1),
    ),
    _TimelineEvent(
      year: '2017',
      title: 'التوسع الإقليمي',
      description: 'بدأنا نخدم عملاء في الشرق الأوسط',
      icon: Icons.public,
      color: Color(0xFFFB8C00),
    ),
    _TimelineEvent(
      year: '2020',
      title: 'التحول الرقمي',
      description: 'إطلاق منصتنا الرقمية لخدمة العملاء',
      icon: Icons.computer,
      color: Color(0xFF43A047),
    ),
    _TimelineEvent(
      year: '2024',
      title: 'الريادة',
      description: '+500 منتج و+1000 عميل حول العالم',
      icon: Icons.emoji_events,
      color: Color(0xFFE53935),
    ),
  ];

  // =====================================================
  // ⭐ قيمنا
  // =====================================================
  static const List<_Value> _values = [
    _Value(
      icon: Icons.verified,
      title: 'الجودة',
      description: 'منتجات أصلية بأعلى المعايير',
      color: Color(0xFF6A1B9A),
    ),
    _Value(
      icon: Icons.bolt,
      title: 'السرعة',
      description: 'تنفيذ سريع وتوصيل فوري',
      color: Color(0xFF00ACC1),
    ),
    _Value(
      icon: Icons.handshake,
      title: 'الثقة',
      description: 'علاقات دائمة مع عملائنا',
      color: Color(0xFFFB8C00),
    ),
    _Value(
      icon: Icons.headset_mic,
      title: 'الدعم',
      description: 'فريق دعم متاح 24/7',
      color: Color(0xFF43A047),
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

              // 2. Intro / Stats
              SliverToBoxAdapter(child: _buildIntro(context)),

              // 3. Timeline
              SliverToBoxAdapter(child: _buildTimeline(context)),

              // 4. Team
              SliverToBoxAdapter(child: _buildTeam(context)),

              // 5. Values
              SliverToBoxAdapter(child: _buildValues(context)),

              // 6. CTA
              SliverToBoxAdapter(child: _buildCTA(context)),

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
          // Badge
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
                    Icons.info_outline,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'من نحن',
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

          // Title
          FadeInOnScroll(
            delay: const Duration(milliseconds: 100),
            child: Text(
              'Moonstar',
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

          // Subtitle
          FadeInOnScroll(
            delay: const Duration(milliseconds: 200),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Text(
                '16 عام من النجاح ولسه زى ما احنا',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 20 : 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
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
  // 2. Intro / Stats
  // =====================================================
  Widget _buildIntro(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getHorizontalPadding(context);
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: 60,
      ),
      child: Column(
        children: [
          // About text
          FadeInOnScroll(
            child: Container(
              padding: EdgeInsets.all(isMobile ? 24 : 40),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF151A23).withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
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
                          Icons.storefront,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'قصتنا',
                        style: TextStyle(
                          fontSize: isMobile ? 24 : 32,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    CompanyInfo.aboutDescription,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: AppTheme.textSecondaryColor(context),
                      height: 1.9,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Mission
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.track_changes,
                            color: AppTheme.primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'رسالتنا',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor(context),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                CompanyInfo.aboutMission,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondaryColor(context),
                                  height: 1.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Stats
          FadeInOnScroll(
            delay: const Duration(milliseconds: 150),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 40,
                vertical: isMobile ? 24 : 40,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryDark,
                    AppTheme.primaryColor,
                    AppTheme.primaryLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      value: CompanyInfo.statsProducts,
                      suffix: '+',
                      label: 'منتج',
                      icon: Icons.inventory_2,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.white.withValues(alpha: 0.2),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      value: CompanyInfo.statsClients,
                      suffix: '+',
                      label: 'عميل',
                      icon: Icons.people,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.white.withValues(alpha: 0.2),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      value: CompanyInfo.statsYears,
                      suffix: '+',
                      label: 'سنة خبرة',
                      icon: Icons.emoji_events,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required int value,
    required String suffix,
    required String label,
    required IconData icon,
  }) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 8 : 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: isMobile ? 20 : 28,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 16),
        CountUpOnScroll(
          end: value,
          prefix: suffix,
          style: TextStyle(
            fontSize: isMobile ? 24 : 42,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 11 : 14,
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // 3. Timeline
  // =====================================================
  Widget _buildTimeline(BuildContext context) {
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
                        Icons.timeline,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'رحلتنا',
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
                  'من 2009 حتى اليوم',
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 42,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textColor(context),
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Timeline items
          isMobile
              ? _buildMobileTimeline(context)
              : _buildDesktopTimeline(context),
        ],
      ),
    );
  }

  Widget _buildDesktopTimeline(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // الخط الرأسي
        Positioned.fill(
          child: Center(
            child: Container(
              width: 2,
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              margin: const EdgeInsets.only(top: 40, bottom: 40),
            ),
          ),
        ),
        // الأحداث
        Column(
          children: _timeline.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            final isLeft = index % 2 == 0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: FadeInOnScroll(
                delay: Duration(milliseconds: 100 * index),
                offset: Offset(isLeft ? -50 : 50, 0),
                child: Row(
                  children: [
                    // يسار
                    Expanded(
                      child: isLeft
                          ? _buildTimelineCard(context, event)
                          : const SizedBox.shrink(),
                    ),
                    // النقطة في النص
                    _buildTimelineDot(event),
                    // يمين
                    Expanded(
                      child: !isLeft
                          ? _buildTimelineCard(context, event)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMobileTimeline(BuildContext context) {
    return Column(
      children: _timeline.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: FadeInOnScroll(
            delay: Duration(milliseconds: 100 * index),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // النقطة
                Column(
                  children: [
                    _buildTimelineDot(event),
                    if (index < _timeline.length - 1)
                      Container(
                        width: 2,
                        height: 60,
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // الكارت
                Expanded(child: _buildTimelineCard(context, event)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimelineDot(_TimelineEvent event) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: event.color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: event.color.withValues(alpha: 0.4),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Icon(event.icon, color: Colors.white, size: 26),
    );
  }

  Widget _buildTimelineCard(BuildContext context, _TimelineEvent event) {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF151A23).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: event.color.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: event.color.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // السنة
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: event.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              event.year,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            event.title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event.description,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor(context),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 4. Team
  // =====================================================
  Widget _buildTeam(BuildContext context) {
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
                        Icons.people_alt,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'فريقنا',
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
                  'تعرف على فريق Moonstar',
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
                    'فريق من الخبراء المتخصصين في الإضاءة والصوتيات والشاشات',
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

          // Team grid
          _buildTeamGrid(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildTeamGrid(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Column(
        children: _team
            .asMap()
            .entries
            .map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: FadeInOnScroll(
                    delay: Duration(milliseconds: 100 * entry.key),
                    child: _buildTeamCard(context, entry.value, isMobile),
                  ),
                ))
            .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.75,
      ),
      itemCount: _team.length,
      itemBuilder: (context, index) {
        return FadeInOnScroll(
          delay: Duration(milliseconds: 100 * index),
          child: _buildTeamCard(context, _team[index], false),
        );
      },
    );
  }

  Widget _buildTeamCard(
    BuildContext context,
    _TeamMember member,
    bool isMobile,
  ) {
    return _TeamCard(member: member, isMobile: isMobile);
  }

  // =====================================================
  // 5. Values
  // =====================================================
  Widget _buildValues(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getHorizontalPadding(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: 60,
      ),
      child: Column(
        children: [
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
                        Icons.star,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'قيمنا',
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
                  'اللي بنؤمن بيه',
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 42,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textColor(context),
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          isMobile ? _buildMobileValues(context) : _buildDesktopValues(context),
        ],
      ),
    );
  }

  Widget _buildDesktopValues(BuildContext context) {
    return Row(
      children: _values.asMap().entries.map((entry) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FadeInOnScroll(
              delay: Duration(milliseconds: 100 * entry.key),
              child: _buildValueCard(context, entry.value),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileValues(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FadeInOnScroll(
                child: _buildValueCard(context, _values[0]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInOnScroll(
                delay: const Duration(milliseconds: 100),
                child: _buildValueCard(context, _values[1]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FadeInOnScroll(
                delay: const Duration(milliseconds: 200),
                child: _buildValueCard(context, _values[2]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInOnScroll(
                delay: const Duration(milliseconds: 300),
                child: _buildValueCard(context, _values[3]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValueCard(BuildContext context, _Value value) {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF151A23).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value.color.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: value.color.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: value.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(value.icon, color: value.color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            value.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 6. CTA
  // =====================================================
  Widget _buildCTA(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getHorizontalPadding(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: 60,
      ),
      child: FadeInOnScroll(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 60,
            vertical: isMobile ? 40 : 60,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryDark,
                AppTheme.primaryColor,
                AppTheme.primaryLight,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'جاهز تبدأ مشروعك؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 28 : 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'تواصل معانا لاستشارة مجانية وفريقنا جاهز يساعدك',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat),
                    label: const Text('تواصل معانا'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24 : 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.call),
                    label: const Text('اتصل بنا'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 2,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24 : 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
}

// =====================================================
// Team Card (Stateful - hover effect)
// =====================================================
class _TeamCard extends StatefulWidget {
  final _TeamMember member;
  final bool isMobile;

  const _TeamCard({
    required this.member,
    required this.isMobile,
  });

  @override
  State<_TeamCard> createState() => _TeamCardState();
}

class _TeamCardState extends State<_TeamCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final member = widget.member;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          0,
          _isHovered ? -8 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF151A23).withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                _isHovered ? member.color : member.color.withValues(alpha: 0.2),
            width: _isHovered ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: member.color.withValues(alpha: _isHovered ? 0.4 : 0.15),
              blurRadius: _isHovered ? 30 : 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // الصورة
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildAvatar(context),

                    // Overlay gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            member.color.withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),

                    // Social icons (تظهر عند hover)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: _isHovered ? 1.0 : 0.0,
                      child: Container(
                        color: member.color.withValues(alpha: 0.85),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: member.social
                                .map((s) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: _socialButton(s),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // المعلومات
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(widget.isMobile ? 16 : 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      member.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.isMobile ? 16 : 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    SizedBox(height: widget.isMobile ? 6 : 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: member.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        member.title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: widget.isMobile ? 11 : 10,
                          fontWeight: FontWeight.w700,
                          color: member.color,
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

  Widget _buildAvatar(BuildContext context) {
    return Image.asset(
      widget.member.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.member.color,
              widget.member.color.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Center(
          child: Text(
            _initials(widget.member.name),
            style: TextStyle(
              fontSize: widget.isMobile ? 40 : 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0];
    return '${parts[0][0]}${parts[1][0]}';
  }

  Widget _socialButton(_Social social) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          social.icon,
          color: widget.member.color,
          size: 18,
        ),
      ),
    );
  }
}

// =====================================================
// Models
// =====================================================
class _TeamMember {
  final String name;
  final String title;
  final String description;
  final String imageUrl;
  final Color color;
  final List<_Social> social;

  _TeamMember({
    required this.name,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.color,
    required this.social,
  });
}

class _Social {
  final IconData icon;
  final String url;

  _Social(this.icon, this.url);
}

class _TimelineEvent {
  final String year;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _TimelineEvent({
    required this.year,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _Value {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _Value({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
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
