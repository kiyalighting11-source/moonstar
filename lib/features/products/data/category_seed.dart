// lib/features/products/data/category_seed.dart

/// شجرة التصنيفات الافتراضية (Seed)
/// - تستخدم كـ fallback لو الـ DB فاضية
/// - أو في شاشة إدارة التصنيفات
class CategorySeed {
  static const List<Map<String, dynamic>> tree = [
    // =====================================================
    // 1) LED Screen
    // =====================================================
    {
      'name': 'LED Screen',
      'children': [
        {'name': 'Indoor'},
        {'name': 'Outdoor'},
      ],
    },

    // =====================================================
    // 2) Stage Lighting
    // =====================================================
    {
      'name': 'Stage Lighting',
      'children': [
        {
          'name': 'Moving Heads',
          'children': [
            {'name': 'Beam'},
            {'name': 'LED'},
          ],
        },
        {
          'name': 'Par Lights',
          'children': [
            {'name': 'Indoor'},
            {'name': 'Outdoor'},
          ],
        },
        {
          'name': 'Wall Washer',
          'children': [
            {'name': 'Indoor'},
            {'name': 'Outdoor'},
          ],
        },
        {'name': 'Laser Light'},
        {'name': 'Effect Light'},
        {'name': 'Smoke Machine'},
        {'name': 'Strobe Light'},
        {'name': 'Console'},
        {'name': 'Theater Lighting'},
        {'name': 'Video Light'},
        {'name': 'COB'},
      ],
    },

    // =====================================================
    // 3) Truss
    // =====================================================
    {
      'name': 'Truss',
      'children': [
        {
          'name': 'Aluminum',
          'children': [
            {'name': '28.5'},
            {'name': '40'},
          ],
        },
        {
          'name': 'Iron',
          'children': [
            {'name': 'Layer'},
          ],
        },
        {'name': 'Stage'},
        {'name': 'Truss Accessories'},
      ],
    },
  ];

  /// عدّاد سريع
  static int get totalCategories {
    int count = 0;
    for (final main in tree) {
      count++;
      count += (main['children'] as List?)?.length ?? 0;
      for (final sub in (main['children'] as List? ?? [])) {
        count += (sub['children'] as List?)?.length ?? 0;
      }
    }
    return count;
  }
}
