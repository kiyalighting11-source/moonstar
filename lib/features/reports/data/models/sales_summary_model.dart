// lib/features/reports/data/models/sales_summary_model.dart

class SalesSummaryModel {
  final double totalSales;
  final double totalPaid;
  final double totalDue;
  final double totalDiscount;
  final double totalTax;
  final int invoicesCount;
  final int paidCount;
  final int partialCount;
  final int cancelledCount;

  SalesSummaryModel({
    this.totalSales = 0,
    this.totalPaid = 0,
    this.totalDue = 0,
    this.totalDiscount = 0,
    this.totalTax = 0,
    this.invoicesCount = 0,
    this.paidCount = 0,
    this.partialCount = 0,
    this.cancelledCount = 0,
  });

  factory SalesSummaryModel.fromJson(Map<String, dynamic> json) {
    return SalesSummaryModel(
      totalSales: _d(json['total_sales']),
      totalPaid: _d(json['total_paid']),
      totalDue: _d(json['total_due']),
      totalDiscount: _d(json['total_discount']),
      totalTax: _d(json['total_tax']),
      invoicesCount: _i(json['invoices_count']),
      paidCount: _i(json['paid_count']),
      partialCount: _i(json['partial_count']),
      cancelledCount: _i(json['cancelled_count']),
    );
  }

  /// متوسط الفاتورة
  double get averageInvoice =>
      invoicesCount == 0 ? 0 : totalSales / invoicesCount;

  /// نسبة التحصيل
  double get collectionRate =>
      totalSales == 0 ? 0 : (totalPaid / totalSales) * 100;

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
