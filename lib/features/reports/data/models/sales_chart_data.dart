// lib/features/reports/data/models/sales_chart_data.dart

/// نقطة واحدة على الرسم البياني
class SalesChartPoint {
  final DateTime date;
  final double value;
  final int count;

  SalesChartPoint({
    required this.date,
    required this.value,
    this.count = 0,
  });

  factory SalesChartPoint.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String?;
    DateTime date;
    try {
      date = DateTime.parse(dateStr ?? '');
    } catch (_) {
      date = DateTime.now();
    }
    return SalesChartPoint(
      date: date,
      value: _d(json['value'] ?? json['total']),
      count: _i(json['count']),
    );
  }

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

/// بيانات الرسم البياني كاملة
class SalesChartData {
  final List<SalesChartPoint> points;
  final String label; // "يومي" / "أسبوعي" / "شهري"

  SalesChartData({
    this.points = const [],
    this.label = 'يومي',
  });

  double get total => points.fold(0.0, (sum, p) => sum + p.value);

  double get max => points.isEmpty
      ? 0
      : points.map((p) => p.value).reduce((a, b) => a > b ? a : b);

  double get min => points.isEmpty
      ? 0
      : points.map((p) => p.value).reduce((a, b) => a < b ? a : b);

  double get average => points.isEmpty ? 0 : total / points.length;

  bool get isEmpty => points.isEmpty;

  /// فلترة لنطاق معين
  SalesChartData filterByDate(DateTime from, DateTime to) {
    return SalesChartData(
      label: label,
      points: points
          .where((p) =>
              p.date.isAfter(from.subtract(const Duration(seconds: 1))) &&
              p.date.isBefore(to.add(const Duration(seconds: 1))))
          .toList(),
    );
  }
}

/// للمنتجات الأكثر مبيعاً (لرسم دائري أو أعمدة)
class CategorySalesData {
  final String name;
  final double value;
  final int count;

  CategorySalesData({
    required this.name,
    required this.value,
    this.count = 0,
  });
}
