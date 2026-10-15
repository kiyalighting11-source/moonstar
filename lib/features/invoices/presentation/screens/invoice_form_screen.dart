// lib/features/invoices/presentation/screens/invoice_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../customers/data/providers/customers_provider.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/providers/products_provider.dart';
import '../../../warehouses/data/providers/warehouses_provider.dart';
import '../../data/models/invoice_item_model.dart';
import '../../data/models/invoice_model.dart';
import '../../providers/invoices_provider.dart';
import '../widgets/invoice_item_row.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

// =====================================================
// Save Choice Enum — MUST be before the class
// =====================================================
enum _SaveChoice { draft, confirm }

class InvoiceFormScreen extends ConsumerStatefulWidget {
  final String? invoiceId;

  const InvoiceFormScreen({super.key, this.invoiceId});

  bool get isEdit => invoiceId != null;

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _discountValueController = TextEditingController(text: '0');
  final _taxValueController = TextEditingController(text: '0');

  String _type = 'sale';
  String _paymentMethod = 'cash';
  String? _customerId;
  String? _warehouseId;
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  DateTime? _expectedPaymentDate;

  String _discountType = 'fixed';
  String _taxType = 'fixed';
  bool _taxIncluded = false;

  final List<InvoiceItemModel> _items = [];

  bool _isLoading = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _loadInvoice();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _discountValueController.dispose();
    _taxValueController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoice() async {
    setState(() => _isLoadingData = true);
    try {
      final invoice = await ref
          .read(invoicesRepositoryProvider)
          .getInvoiceById(widget.invoiceId!);

      if (invoice == null) {
        if (mounted) {
          Helpers.showError(context, 'البيان غير موجود');
          context.go('/invoices');
        }
        return;
      }

      _type = invoice.type;
      _paymentMethod = invoice.paymentMethod;
      _customerId = invoice.customerId;
      _warehouseId = invoice.warehouseId;
      _invoiceDate = invoice.invoiceDate;
      _dueDate = invoice.dueDate;
      _expectedPaymentDate = invoice.expectedPaymentDate;
      _notesController.text = invoice.notes ?? '';
      _discountType = invoice.discountType;
      _discountValueController.text = invoice.discountValue.toStringAsFixed(0);
      _taxType = invoice.taxType;
      _taxValueController.text = invoice.taxValue.toStringAsFixed(0);
      _taxIncluded = invoice.taxIncluded;

      _items.clear();
      _items.addAll(invoice.items);
    } catch (e) {
      if (mounted) Helpers.showError(context, 'فشل التحميل: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  double get _subtotal {
    return _items
        .where((i) => i.isStockItem)
        .fold(0.0, (s, i) => s + (i.quantity * i.unitPrice));
  }

  double get _totalExtra {
    return _items
        .where((i) => !i.isStockItem)
        .fold(0.0, (s, i) => s + (i.quantity * i.unitPrice));
  }

  double get _discountValue =>
      Helpers.parseDouble(_discountValueController.text);

  double get _taxValue => Helpers.parseDouble(_taxValueController.text);

  double get _discountAmount {
    if (_discountType == 'percentage') {
      return (_subtotal + _totalExtra) * _discountValue / 100;
    }
    return _discountValue;
  }

  double get _taxAmount {
    final base = _subtotal + _totalExtra - _discountAmount;

    if (_taxType == 'percentage') {
      if (_taxIncluded) {
        return base * _taxValue / (100 + _taxValue);
      } else {
        return base * _taxValue / 100;
      }
    }

    return _taxValue;
  }

  double get _total {
    final base = _subtotal + _totalExtra - _discountAmount;
    return _taxIncluded ? base : base + _taxAmount;
  }

  double get _subtotalWithoutTax {
    final base = _subtotal + _totalExtra - _discountAmount;
    return _taxIncluded ? base - _taxAmount : base;
  }

  Future<void> _pickDate({required String field}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
    );
    if (picked == null) return;

    setState(() {
      if (field == 'invoice') _invoiceDate = picked;
      if (field == 'due') _dueDate = picked;
      if (field == 'expected') _expectedPaymentDate = picked;
    });
  }

  void _addStockItem(ProductModel product) {
    setState(() {
      _items.add(InvoiceItemModel(
        id: '',
        invoiceId: widget.invoiceId ?? '',
        productId: product.id,
        productName: product.name,
        productSku: product.sku,
        productImageUrl: product.mainImageUrl,
        quantity: 1,
        unitPrice: product.price,
        isStockItem: true,
        unit: product.unit,
      ));
    });
  }

  void _addExtraItem() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final isDark = AppTheme.isDark(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF151A23) : Colors.white,
        title: const Text('بند إضافي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'اسم البند',
                hintText: 'شحن، تركيب، خدمة...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'السعر',
                suffixText: 'ج.م',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final price = Helpers.parseDouble(priceController.text);
              if (name.isEmpty || price <= 0) return;

              setState(() {
                _items.add(InvoiceItemModel(
                  id: '',
                  invoiceId: widget.invoiceId ?? '',
                  quantity: 1,
                  unitPrice: price,
                  isStockItem: false,
                  itemName: name,
                ));
              });
              Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showProductPicker() {
    final isDark = AppTheme.isDark(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151A23) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'اختر منتج',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ),
              Expanded(
                child: Consumer(
                  builder: (_, ref, __) {
                    final productsAsync = ref.watch(productsListProvider);
                    return productsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('خطأ: $e')),
                      data: (products) => ListView.builder(
                        controller: scrollController,
                        itemCount: products.length,
                        itemBuilder: (_, i) {
                          final p = products[i];
                          return ListTile(
                            leading: const Icon(Icons.inventory_2),
                            title: Text(p.name),
                            subtitle: Text(
                              '${p.sku} • ${Helpers.formatCurrency(p.price)}',
                            ),
                            onTap: () {
                              _addStockItem(p);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // ⭐ حفظ البيان — مع Bottom Sheet للاختيار
  // =====================================================
  Future<void> _saveWithChoice() async {
    // 1) نتحقق من الفورم الأول
    if (!_formKey.currentState!.validate()) return;
    if (_customerId == null) {
      Helpers.showError(context, 'اختر العميل');
      return;
    }
    if (_items.isEmpty) {
      Helpers.showError(context, 'أضف بند واحد على الأقل');
      return;
    }

    // 2) نعرض الـ Bottom Sheet
    final choice = await _showSaveChoiceSheet();

    if (choice == null) return; // المستخدم أغلق

    // 3) ننفذ الحفظ حسب الاختيار
    await _save(asDraft: choice == _SaveChoice.draft);
  }

  Future<_SaveChoice?> _showSaveChoiceSheet() async {
    final isDark = AppTheme.isDark(context);
    final total = _total;
    final itemsCount = _items.length;

    return showModalBottomSheet<_SaveChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151A23) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // العنوان
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.save_outlined,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حفظ البيان',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                      Text(
                        '$itemsCount بند • ${Helpers.formatCurrency(total)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // الخيار 1: مسودة
            _choiceTile(
              context,
              icon: Icons.edit_note,
              iconColor: AppTheme.infoColor,
              title: 'حفظ كمسودة',
              subtitle: 'يمكنك تعديله لاحقاً — لن يؤثر على المخزون',
              onTap: () => Navigator.pop(ctx, _SaveChoice.draft),
            ),

            const SizedBox(height: 12),

            // الخيار 2: تأكيد
            _choiceTile(
              context,
              icon: Icons.check_circle,
              iconColor: AppTheme.successColor,
              title: 'حفظ وتأكيد',
              subtitle: 'سيتم خصم المخزون وتسجيل البيان نهائياً',
              onTap: () => Navigator.pop(ctx, _SaveChoice.confirm),
            ),

            const SizedBox(height: 16),

            // إلغاء
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('إلغاء'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choiceTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = AppTheme.isDark(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor(context),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppTheme.textSecondaryColor(context),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // الحفظ الفعلي
  // =====================================================
  Future<void> _save({required bool asDraft}) async {
    setState(() => _isLoading = true);

    final invoice = InvoiceModel(
      id: widget.invoiceId ?? '',
      invoiceNumber: '',
      type: _type,
      customerId: _customerId,
      warehouseId: _warehouseId,
      invoiceDate: _invoiceDate,
      dueDate: _dueDate,
      expectedPaymentDate: _expectedPaymentDate,
      paymentMethod: _paymentMethod,
      status: asDraft ? 'draft' : 'confirmed',
      discountType: _discountType,
      discountValue: _discountValue,
      taxType: _taxType,
      taxValue: _taxValue,
      taxIncluded: _taxIncluded,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final controller = ref.read(invoicesControllerProvider.notifier);

    if (widget.isEdit) {
      final success = await controller.updateInvoiceWithItems(
        invoice: invoice,
        items: _items,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        Helpers.showSuccess(
          context,
          asDraft ? 'تم تحديث المسودة' : 'تم تحديث البيان وتأكيده',
        );
        if (!mounted) return;
        context.go('/invoices/${widget.invoiceId}');
      } else {
        final error = ref.read(invoicesControllerProvider).error;
        Helpers.showError(context, 'فشل التحديث: $error');
      }
      return;
    }

    final created = await controller.createInvoice(
      invoice: invoice,
      items: _items,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (created == null) {
      final error = ref.read(invoicesControllerProvider).error;
      Helpers.showError(context, 'فشل الإنشاء: $error');
      return;
    }

    // لو تأكيد → نأكد البيان
    if (!asDraft) {
      final confirmed = await controller.confirmInvoice(created.id);
      if (!mounted) return;

      if (confirmed == null) {
        final error = ref.read(invoicesControllerProvider).error;
        Helpers.showError(context, 'تم الحفظ لكن فشل التأكيد: $error');
        context.go('/invoices/${created.id}');
        return;
      }
    }

    if (!mounted) return;
    Helpers.showSuccess(
      context,
      asDraft ? 'تم حفظ المسودة' : 'تم إنشاء البيان',
    );
    context.go('/invoices/${created.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: widget.isEdit ? 'تعديل بيان' : 'بيان جديد',
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  _buildTypeSelector(),
                  const SizedBox(height: 16),
                  _buildCustomerDropdown(),
                  const SizedBox(height: 12),
                  _buildWarehouseDropdown(),
                  const SizedBox(height: 12),
                  _buildDatesRow(),
                  const SizedBox(height: 20),
                  _buildItemsSection(),
                  const SizedBox(height: 20),
                  _buildDiscountSection(),
                  const SizedBox(height: 12),
                  _buildTaxSection(),
                  const SizedBox(height: 12),
                  _buildPaymentMethodDropdown(),
                  const SizedBox(height: 12),
                  _buildNotesField(),
                  const SizedBox(height: 20),
                  _buildTotalsSection(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _typeButton('بيع', 'sale', Icons.shopping_cart),
        ),
        const SizedBox(width: 8),
        Expanded(
          child:
              _typeButton('مرتجع بيع', 'sale_return', Icons.assignment_return),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _typeButton('عرض سعر', 'quote', Icons.request_quote),
        ),
      ],
    );
  }

  Widget _typeButton(String label, String value, IconData icon) {
    final selected = _type == value;
    final isDark = AppTheme.isDark(context);

    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppTheme.dividerColor),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected
                  ? Colors.white
                  : AppTheme.textSecondaryColor(context),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.textColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDropdown() {
    final customersAsync = ref.watch(customersListProvider);

    return customersAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('خطأ: $e'),
      data: (customers) => DropdownButtonFormField<String>(
        initialValue: _customerId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'العميل *',
          prefixIcon: Icon(Icons.person),
        ),
        items: customers
            .map((c) => DropdownMenuItem<String>(
                  value: c.id,
                  child: Text('${c.name} (${c.code})'),
                ))
            .toList(),
        onChanged: (v) => setState(() => _customerId = v),
        validator: (v) => v == null ? 'اختر العميل' : null,
      ),
    );
  }

  Widget _buildWarehouseDropdown() {
    final warehousesAsync = ref.watch(warehousesListProvider);

    return warehousesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('خطأ: $e'),
      data: (warehouses) => DropdownButtonFormField<String>(
        initialValue: _warehouseId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'المخزن (اختياري)',
          prefixIcon: Icon(Icons.warehouse),
        ),
        items: warehouses
            .map((w) => DropdownMenuItem<String>(
                  value: w.id,
                  child: Text(w.name),
                ))
            .toList(),
        onChanged: (v) => setState(() => _warehouseId = v),
      ),
    );
  }

  Widget _buildDatesRow() {
    return Column(
      children: [
        InkWell(
          onTap: () => _pickDate(field: 'invoice'),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'تاريخ البيان',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              DateFormat('dd/MM/yyyy', 'ar').format(_invoiceDate),
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(field: 'due'),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'تاريخ الاستحقاق',
                    prefixIcon: Icon(Icons.event, size: 20),
                  ),
                  child: Text(
                    _dueDate == null
                        ? '—'
                        : DateFormat('dd/MM/yyyy', 'ar').format(_dueDate!),
                    style: TextStyle(
                      fontSize: 13,
                      color: _dueDate == null
                          ? AppTheme.textSecondaryColor(context)
                          : AppTheme.textColor(context),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(field: 'expected'),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'السداد المتوقع',
                    prefixIcon: Icon(Icons.schedule, size: 20),
                  ),
                  child: Text(
                    _expectedPaymentDate == null
                        ? '—'
                        : DateFormat('dd/MM/yyyy', 'ar')
                            .format(_expectedPaymentDate!),
                    style: TextStyle(
                      fontSize: 13,
                      color: _expectedPaymentDate == null
                          ? AppTheme.textSecondaryColor(context)
                          : AppTheme.textColor(context),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsSection() {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt,
                  color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'بنود البيان',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Text(
                'مفيش بنود — اضغط "إضافة بند"',
                style: TextStyle(color: AppTheme.textSecondaryColor(context)),
              ),
            )
          else
            ...List.generate(_items.length, (i) {
              return InvoiceItemRow(
                item: _items[i],
                onChanged: (updated) {
                  setState(() => _items[i] = updated);
                },
                onRemove: () {
                  setState(() => _items.removeAt(i));
                },
              );
            }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showProductPicker,
                  icon: const Icon(Icons.inventory_2, size: 18),
                  label: const Text(
                    'منتج من المخزن',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addExtraItem,
                  icon: const Icon(Icons.add_box_outlined, size: 18),
                  label: const Text(
                    'بند إضافي',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountSection() {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_outlined,
                  color: AppTheme.warningColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'الخصم',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _discountValueController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'قيمة الخصم',
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'fixed',
                      label: Text('مبلغ', style: TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: 'percentage',
                      label: Text('نسبة %', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  selected: {_discountType},
                  onSelectionChanged: (s) =>
                      setState(() => _discountType = s.first),
                ),
              ),
            ],
          ),
          if (_discountAmount > 0) ...[
            const SizedBox(height: 8),
            Text(
              'الخصم: -${Helpers.formatCurrency(_discountAmount)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.warningColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaxSection() {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_outlined,
                  color: AppTheme.infoColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'الضريبة',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _taxValueController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'قيمة الضريبة',
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'fixed',
                      label: Text('مبلغ', style: TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: 'percentage',
                      label: Text('نسبة %', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  selected: {_taxType},
                  onSelectionChanged: (s) => setState(() => _taxType = s.first),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _taxIncluded,
            onChanged: (v) => setState(() => _taxIncluded = v),
            title: const Text(
              'الضريبة داخل السعر',
              style: TextStyle(fontSize: 13),
            ),
            subtitle: Text(
              _taxIncluded
                  ? 'الضريبة مستخرجة من السعر'
                  : 'الضريبة تُضاف فوق السعر',
              style: const TextStyle(fontSize: 11),
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          if (_taxAmount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.infoColor,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _taxIncluded
                          ? 'الضريبة (مستخرجة): ${Helpers.formatCurrency(_taxAmount)}'
                          : 'الضريبة (مضافة): +${Helpers.formatCurrency(_taxAmount)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.infoColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _paymentMethod,
      decoration: const InputDecoration(
        labelText: 'طريقة الدفع',
        prefixIcon: Icon(Icons.payment),
      ),
      items: const [
        DropdownMenuItem(value: 'cash', child: Text('كاش')),
        DropdownMenuItem(
          value: 'vodafone_cash',
          child: Text('فودافون كاش'),
        ),
        DropdownMenuItem(value: 'instapay', child: Text('إنستاباي')),
      ],
      onChanged: (v) => setState(() => _paymentMethod = v ?? 'cash'),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'ملاحظات',
        prefixIcon: Icon(Icons.note_outlined),
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _totalRow('المجموع الفرعي', _subtotal, Colors.white70),
          if (_totalExtra > 0)
            _totalRow('بنود إضافية', _totalExtra, Colors.white70),
          if (_discountAmount > 0)
            _totalRow('الخصم', -_discountAmount, Colors.yellow.shade200),
          if (_taxIncluded && _taxAmount > 0)
            _totalRow('الصافي بدون ضريبة', _subtotalWithoutTax, Colors.white70),
          if (_taxAmount > 0)
            _totalRow(
              _taxIncluded ? 'الضريبة (جوّه)' : 'الضريبة',
              _taxAmount,
              Colors.white70,
            ),
          const Divider(color: Colors.white30, height: 20),
          _totalRow('الإجمالي', _total, Colors.white, bold: true, big: true),
        ],
      ),
    );
  }

  Widget _totalRow(
    String label,
    double value,
    Color color, {
    bool bold = false,
    bool big = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: big ? 16 : 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            Helpers.formatCurrency(value),
            style: TextStyle(
              color: color,
              fontSize: big ? 20 : 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isEdit = widget.isEdit;

    return Column(
      children: [
        // ⭐ زرار حفظ واحد — بيفتح Bottom Sheet
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveWithChoice,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(
              isEdit ? 'حفظ التعديلات' : 'حفظ البيان',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: () => context.go('/invoices'),
            child: const Text('إلغاء'),
          ),
        ),
      ],
    );
  }
}
