// lib/features/invoices/presentation/widgets/invoice_item_row.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/models/invoice_item_model.dart';

class InvoiceItemRow extends StatefulWidget {
  final InvoiceItemModel item;
  final ValueChanged<InvoiceItemModel> onChanged;
  final VoidCallback onRemove;

  const InvoiceItemRow({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<InvoiceItemRow> createState() => _InvoiceItemRowState();
}

class _InvoiceItemRowState extends State<InvoiceItemRow> {
  late final TextEditingController _qtyController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: widget.item.quantity.toStringAsFixed(
        widget.item.quantity == widget.item.quantity.round() ? 0 : 2,
      ),
    );
    _priceController = TextEditingController(
      text: widget.item.unitPrice.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _update() {
    final qty = Helpers.parseDouble(_qtyController.text);
    final price = Helpers.parseDouble(_priceController.text);

    final updated = widget.item.copyWith(
      quantity: qty,
      unitPrice: price,
      lineTotal: (qty * price) - widget.item.discount + widget.item.tax,
    );

    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.item.quantity * widget.item.unitPrice;
    final isStock = widget.item.isStockItem;
    final isDark = AppTheme.isDark(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : AppTheme.lightBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isStock
              ? AppTheme.infoColor.withValues(alpha: 0.3)
              : AppTheme.warningColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // ==================== الصف الأول ====================
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isStock
                      ? AppTheme.infoColor.withValues(alpha: 0.15)
                      : AppTheme.warningColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isStock ? Icons.inventory_2 : Icons.work_outline,
                  size: 14,
                  color: isStock ? AppTheme.infoColor : AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    if (widget.item.productSku != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        widget.item.productSku!,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppTheme.errorColor,
                  size: 18,
                ),
                onPressed: widget.onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 30,
                  minHeight: 30,
                ),
                tooltip: 'حذف البند',
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ==================== الصف الثاني ====================
          Row(
            children: [
              Expanded(
                child: _inputField(
                  context: context,
                  controller: _qtyController,
                  label: 'الكمية',
                  icon: Icons.numbers,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _inputField(
                  context: context,
                  controller: _priceController,
                  label: 'السعر',
                  icon: Icons.attach_money,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ==================== الإجمالي ====================
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الإجمالي:',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
                Text(
                  Helpers.formatCurrency(total),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => _update(),
      style: TextStyle(
        fontSize: 13,
        color: AppTheme.textColor(context),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 16),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
