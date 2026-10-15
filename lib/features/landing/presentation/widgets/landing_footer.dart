// lib/features/landing/presentation/widgets/landing_footer.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';

// =====================================================
// ⭐ لينك تحميل التطبيق
// غيّر اللينك ده باللينك النهائي بتاع الـ APK
// =====================================================
const String _appDownloadUrl =
    'https://github.com/kiyalighting11-source/moonstar/releases/latest/download/moonstar-erp.apk';

class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getHorizontalPadding(context);

    return Container(
      color: const Color(0xFF0A0E14),
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: isMobile ? 40 : 60,
      ),
      child: Column(
        children: [
          // Main Content
          isMobile
              ? _buildMobileContent(context)
              : _buildDesktopContent(context),

          const SizedBox(height: 40),

          // Divider
          Divider(
            color: Colors.white.withValues(alpha: 0.1),
            height: 1,
          ),

          const SizedBox(height: 24),

          // Copyright
          isMobile
              ? Column(
                  children: [
                    _buildCopyright(),
                    const SizedBox(height: 12),
                    _buildMadeWith(),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCopyright(),
                    _buildMadeWith(),
                  ],
                ),
        ],
      ),
    );
  }

  // =====================================================
  // Desktop Content
  // =====================================================
  Widget _buildDesktopContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand
        Expanded(
          flex: 2,
          child: _buildBrandSection(context),
        ),
        const SizedBox(width: 40),

        // Quick Links
        Expanded(
          child: _buildLinksSection(
            context,
            title: 'روابط سريعة',
            links: [
              _Link('الرئيسية', () => context.go('/')),
              _Link('منتجاتنا', () => context.go('/shop')),
              _Link('عن الشركة', () => context.go('/about')),
              _Link('اتصل بنا', () => context.go('/contact')),
              _Link('تسجيل الدخول', () => context.go('/login')),
              _Link('تحميل التطبيق 📱', () => _launchUrl(_appDownloadUrl)),
            ],
          ),
        ),

        const SizedBox(width: 40),

        // Categories
        Expanded(
          child: _buildLinksSection(
            context,
            title: 'التصنيفات',
            links: [
              _Link('LED Screen', () => context.go('/shop')),
              _Link('Stage Lighting', () => context.go('/shop')),
              _Link('Truss', () => context.go('/shop')),
            ],
          ),
        ),

        const SizedBox(width: 40),

        // Contact + Download
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContactSection(context),
              const SizedBox(height: 20),
              _buildDownloadButton(context),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
  // Mobile Content
  // =====================================================
  Widget _buildMobileContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBrandSection(context),
        const SizedBox(height: 24),
        _buildDownloadButton(context),
        const SizedBox(height: 32),
        _buildLinksSection(
          context,
          title: 'روابط سريعة',
          links: [
            _Link('الرئيسية', () => context.go('/')),
            _Link('منتجاتنا', () => context.go('/shop')),
            _Link('عن الشركة', () => context.go('/about')),
            _Link('اتصل بنا', () => context.go('/contact')),
            _Link('تسجيل الدخول', () => context.go('/login')),
            _Link('تحميل التطبيق 📱', () => _launchUrl(_appDownloadUrl)),
          ],
        ),
        const SizedBox(height: 32),
        _buildContactSection(context),
      ],
    );
  }

  // =====================================================
  // Brand Section
  // =====================================================
  Widget _buildBrandSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Moonstar',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'الوكيل الوحيد لشركة Moonstar فى مصر والشرق الأوسط',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.7),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        // Social Icons
        Row(
          children: [
            _socialIcon(Icons.facebook, () {}),
            const SizedBox(width: 10),
            _socialIcon(Icons.camera_alt, () {}),
            const SizedBox(width: 10),
            _socialIcon(Icons.chat, () {}),
          ],
        ),
      ],
    );
  }

  Widget _socialIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.8),
          size: 18,
        ),
      ),
    );
  }

  // =====================================================
  // Download Button
  // =====================================================
  Widget _buildDownloadButton(BuildContext context) {
    return InkWell(
      onTap: () => _launchUrl(_appDownloadUrl),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF43A047),
              Color(0xFF2E7D32),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF43A047).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.android,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'حمّل التطبيق',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Android APK',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // Links Section
  // =====================================================
  Widget _buildLinksSection(
    BuildContext context, {
    required String title,
    required List<_Link> links,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: link.onTap,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 10,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        link.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  // =====================================================
  // Contact Section
  // =====================================================
  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تواصل معنا',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Phone
        _contactRow(
          icon: Icons.phone,
          text: CompanyInfo.phone,
          onTap: () => _launchUrl('tel:${CompanyInfo.phone}'),
        ),
        const SizedBox(height: 10),

        // WhatsApp
        _contactRow(
          icon: Icons.chat,
          text: CompanyInfo.whatsapp,
          onTap: () => _launchUrl('https://wa.me/2${CompanyInfo.whatsapp}'),
        ),
        const SizedBox(height: 10),

        // Address
        _contactRow(
          icon: Icons.location_on,
          text: CompanyInfo.address,
          onTap: () => _launchUrl(CompanyInfo.googleMapsUrl),
        ),
      ],
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // Copyright
  // =====================================================
  Widget _buildCopyright() {
    return Text(
      '© 2026 Moonstar ERP — جميع الحقوق محفوظة',
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildMadeWith() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'صُنع بـ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.favorite, color: Colors.red, size: 12),
        const SizedBox(width: 4),
        Text(
          'في مصر',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // Helper — Launch URL
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
// Model: Link
// =====================================================
class _Link {
  final String label;
  final VoidCallback onTap;

  _Link(this.label, this.onTap);
}
