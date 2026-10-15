// lib/features/invoices/presentation/widgets/invoice_status_badge.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class InvoiceStatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const InvoiceStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    final label = _statusLabel;
    final icon = _statusIcon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (status) {
      case 'draft':
        return AppTheme.textSecondary;
      case 'quote':
        return AppTheme.infoColor;
      case 'confirmed':
        return AppTheme.primaryColor;
      case 'paid':
        return AppTheme.successColor;
      case 'partial':
        return AppTheme.warningColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'draft':
        return 'مسودة';
      case 'quote':
        return 'عرض سعر';
      case 'confirmed':
        return 'مؤكدة';
      case 'paid':
        return 'مدفوعة';
      case 'partial':
        return 'مدفوعة جزئياً';
      case 'cancelled':
        return 'ملغية';
      default:
        return status;
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case 'draft':
        return Icons.edit_note;
      case 'quote':
        return Icons.request_quote;
      case 'confirmed':
        return Icons.verified;
      case 'paid':
        return Icons.check_circle;
      case 'partial':
        return Icons.pending_actions;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}
