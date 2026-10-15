// lib/features/landing/presentation/landing_page_screen.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'widgets/about_section.dart';
import 'widgets/contact_section.dart';
import 'widgets/counters_section.dart';
import 'widgets/featured_products_section.dart';
import 'widgets/features_section.dart';
import 'widgets/gallery_section.dart'; // ⭐ جديد
import 'widgets/hero_section.dart';
import 'widgets/landing_footer.dart';
import 'widgets/landing_navbar.dart';
import 'widgets/mobile_menu_drawer.dart';
import 'widgets/video_section.dart'; // ⭐ جديد

class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showBackToTop = false;

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

              // Hero
              const SliverToBoxAdapter(child: HeroSection()),

              // About
              const SliverToBoxAdapter(child: AboutSection()),

              // Counters
              const SliverToBoxAdapter(child: CountersSection()),

              // Featured Products
              const SliverToBoxAdapter(child: FeaturedProductsSection()),

              // ⭐ Gallery (3D Carousel)
              const SliverToBoxAdapter(child: GallerySection()),

              // Features
              const SliverToBoxAdapter(child: FeaturesSection()),

              // ⭐ Video Section
              const SliverToBoxAdapter(child: VideoSection()),

              // Contact
              const SliverToBoxAdapter(child: ContactSection()),

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
