/// Buyurtma holatlari.
enum OrderStatus {
  fresh('Yangi'),
  preparing('Tayyorlanmoqda'),
  delivering('Yetkazilmoqda'),
  delivered('Yetkazildi'),
  cancelled('Bekor qilindi');

  const OrderStatus(this.label);
  final String label;

  static OrderStatus fromName(String name) {
    return OrderStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => OrderStatus.fresh,
    );
  }
}

/// To'lov usullari (hozircha test rejimi; keyinchalik serverga ulanadi).
enum PaymentMethod {
  click('Click', 'Click orqali to\u2018lov'),
  payme('Payme', 'Payme orqali to\u2018lov'),
  uzcard('Uzcard', 'Uzcard kartasi orqali'),
  humo('Humo', 'Humo kartasi orqali'),
  cash('Naqd', 'Yetkazilganda naqd pul');

  const PaymentMethod(this.label, this.description);
  final String label;
  final String description;

  static PaymentMethod fromName(String name) {
    return PaymentMethod.values.firstWhere(
      (m) => m.name == name,
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// Yetkazib berish usullari.
enum DeliveryMethod {
  standard('Oddiy yetkazish', '1\u20132 ish kuni'),
  express('Tez yetkazish', 'Bugun ichida');

  const DeliveryMethod(this.label, this.description);
  final String label;
  final String description;

  static DeliveryMethod fromName(String name) {
    return DeliveryMethod.values.firstWhere(
      (m) => m.name == name,
      orElse: () => DeliveryMethod.standard,
    );
  }
}

/// Mahsulotlarni saralash turlari.
enum ProductSort {
  popular('Mashhurligi bo\u2018yicha'),
  newest('Yangiligi bo\u2018yicha'),
  priceAsc('Arzonidan qimmatiga'),
  priceDesc('Qimmatidan arzoniga'),
  rating('Reytingi bo\u2018yicha'),
  discount('Chegirma bo\u2018yicha');

  const ProductSort(this.label);
  final String label;
}

/// PC Builder komponent turlari.
enum PcPartType {
  cpu('Protsessor', 'cpu', 'Protsessor tanlanmagan'),
  motherboard('Ona plata', 'mb', 'Ona plata tanlanmagan'),
  ram('Operativ xotira', 'ram', 'RAM tanlanmagan'),
  gpu('Videokarta', 'gpu', 'Videokarta tanlanmagan'),
  ssd('SSD', 'ssd', 'SSD tanlanmagan'),
  hdd('HDD', 'hdd', 'HDD tanlanmagan'),
  psu('Quvvat bloki', 'psu', 'Quvvat bloki tanlanmagan'),
  caseUnit('Korpus', 'case', 'Korpus tanlanmagan'),
  cooler('Sovutgich', 'cooler', 'Sovutgich tanlanmagan');

  const PcPartType(this.label, this.specValue, this.emptyLabel);
  final String label;

  /// Mahsulot specs JSON'idagi `pc_part` qiymati.
  final String specValue;
  final String emptyLabel;
}
