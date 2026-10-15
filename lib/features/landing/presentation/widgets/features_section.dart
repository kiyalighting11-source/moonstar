// lib/features/landing/presentation/widgets/features_section.dart

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/scroll_animations.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getHorizontalPadding(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: isMobile ? 60 : 100,
      ),
      // ⭐ شفاف عشان AnimatedGradientBackground يبان
      color: Colors.transparent,
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
                        Icons.star,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'لماذا نحن؟',
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
                  'مميزاتنا',
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
                    'بنقدملك مجموعة من المميزات اللي بتخلي تجربتك معانا مختلفة',
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

          // Features Grid
          isMobile ? _buildMobileGrid(context) : _buildDesktopGrid(context),
        ],
      ),
    );
  }

  // =====================================================
  // Desktop: 4 columns
  // =====================================================
  Widget _buildDesktopGrid(BuildContext context) {
    return Row(
      children: CompanyInfo.features.asMap().entries.map((entry) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FadeInOnScroll(
              delay: Duration(milliseconds: 100 * entry.key),
              child: _buildFeatureCard(
                context: context,
                title: entry.value['title']!,
                description: entry.value['description']!,
                icon: _getIcon(entry.value['icon']!),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // =====================================================
  // Mobile: 2x2 grid
  // =====================================================
  Widget _buildMobileGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FadeInOnScroll(
                child: _buildFeatureCard(
                  context: context,
                  title: CompanyInfo.features[0]['title']!,
                  description: CompanyInfo.features[0]['description']!,
                  icon: _getIcon(CompanyInfo.features[0]['icon']!),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInOnScroll(
                delay: const Duration(milliseconds: 100),
                child: _buildFeatureCard(
                  context: context,
                  title: CompanyInfo.features[1]['title']!,
                  description: CompanyInfo.features[1]['description']!,
                  icon: _getIcon(CompanyInfo.features[1]['icon']!),
                ),
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
                child: _buildFeatureCard(
                  context: context,
                  title: CompanyInfo.features[2]['title']!,
                  description: CompanyInfo.features[2]['description']!,
                  icon: _getIcon(CompanyInfo.features[2]['icon']!),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInOnScroll(
                delay: const Duration(milliseconds: 300),
                child: _buildFeatureCard(
                  context: context,
                  title: CompanyInfo.features[3]['title']!,
                  description: CompanyInfo.features[3]['description']!,
                  icon: _getIcon(CompanyInfo.features[3]['icon']!),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =====================================================
  // Feature Card (معتم عشان يبان على الخلفية)
  // =====================================================
  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // ⭐ خلفية شبه معتمة
        color: isDark
            ? const Color(0xFF151A23).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryLight,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),

          const SizedBox(height: 20),

          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor(context),
              height: 1.3,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            description,
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
  // Icon Mapper
  // =====================================================
  IconData _getIcon(String key) {
    switch (key) {
      case 'speed':
        return Icons.bolt;
      case 'quality':
        return Icons.verified;
      case 'experience':
        return Icons.emoji_events;
      case 'support':
        return Icons.headset_mic;
      default:
        return Icons.star;
    }
  }
}
