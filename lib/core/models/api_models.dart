import '../network/api_endpoints.dart';
import '../network/json_helpers.dart';

String? absoluteMediaUrl(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final base = Uri.parse(ApiEndpoints.baseUrl);
  final origin =
      '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
  return '$origin${trimmed.startsWith('/') ? trimmed : '/$trimmed'}';
}

String? _firstNonBlankString(Iterable<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }
  }
  return null;
}

String? _firstImageUrl(List<Map<String, dynamic>> images) {
  if (images.isEmpty) {
    return null;
  }
  final first = images.first;
  return _firstNonBlankString(
      [first['url'], first['image'], first['image_url']]);
}

String? _absoluteFirstMediaUrl(Iterable<Object?> values) {
  return absoluteMediaUrl(_firstNonBlankString(values));
}

double _money(double value) => ((value + 0.0000001) * 100).round() / 100;

String formatMoney(double value) => '\$${_money(value).toStringAsFixed(2)}';

class TaxDisplay {
  const TaxDisplay({
    required this.grossTotal,
    required this.preTaxSubtotal,
    required this.salesTax,
    required this.taxRatePercent,
  });

  final double grossTotal;
  final double preTaxSubtotal;
  final double salesTax;
  final double taxRatePercent;

  factory TaxDisplay.fromJson(Map<String, dynamic> json) {
    return TaxDisplay(
      grossTotal: asDouble(json['gross_total']),
      preTaxSubtotal: asDouble(json['pre_tax_subtotal']),
      salesTax: asDouble(json['sales_tax']),
      taxRatePercent: asDouble(json['tax_rate_percent'], fallback: 9.25),
    );
  }

  factory TaxDisplay.split(double grossTotal, [double taxRatePercent = 9.25]) {
    final gross = _money(grossTotal);
    final rate = _money(taxRatePercent);
    if (gross <= 0 || rate <= 0) {
      return TaxDisplay(
        grossTotal: gross,
        preTaxSubtotal: gross,
        salesTax: 0,
        taxRatePercent: rate,
      );
    }
    final preTax = _money(gross / (1 + rate / 100));
    return TaxDisplay(
      grossTotal: gross,
      preTaxSubtotal: preTax,
      salesTax: _money(gross - preTax),
      taxRatePercent: rate,
    );
  }

  Map<String, dynamic> toJson() => {
        'gross_total': grossTotal.toStringAsFixed(2),
        'pre_tax_subtotal': preTaxSubtotal.toStringAsFixed(2),
        'sales_tax': salesTax.toStringAsFixed(2),
        'tax_rate_percent': taxRatePercent.toStringAsFixed(2),
      };
}

TaxDisplay? _optionalTaxDisplay(Object? value) {
  final map = asMap(value);
  return map.isEmpty ? null : TaxDisplay.fromJson(map);
}

class ProductItem {
  const ProductItem({
    required this.id,
    required this.slug,
    required this.title,
    required this.price,
    this.description = '',
    this.imageUrl,
    this.stockQuantity = 0,
    this.category = '',
    this.subcategory = '',
    this.setName = '',
    this.rarity = '',
    this.isActive = true,
    this.availabilityStatus = '',
    this.purchaseLimitDaily,
    this.purchaseLimitWeekly,
    this.purchaseLimitLifetime,
    this.myEntitlementId,
    this.myCampaignItemId,
    this.campaignPrice,
    this.campaignPerWinnerLimit,
    this.taxDisplay,
  });

  final int id;
  final String slug;
  final String title;
  final double price;
  final String description;
  final String? imageUrl;
  final int stockQuantity;
  final String category;
  final String subcategory;
  final String setName;
  final String rarity;
  final bool isActive;
  final String availabilityStatus;
  final int? purchaseLimitDaily;
  final int? purchaseLimitWeekly;
  final int? purchaseLimitLifetime;
  final String? myEntitlementId;
  final int? myCampaignItemId;
  final double? campaignPrice;
  final int? campaignPerWinnerLimit;
  final TaxDisplay? taxDisplay;

  bool get inStock => availabilityStatus == 'active' || stockQuantity > 0;
  String get cartKey =>
      '$id|${myEntitlementId ?? ''}|${myCampaignItemId ?? ''}';
  TaxDisplay get resolvedTaxDisplay => taxDisplay ?? TaxDisplay.split(price);
  String get customerPriceLabel => price <= 0
      ? 'FREE'
      : formatMoney(resolvedTaxDisplay.preTaxSubtotal);

  int? get localQuantityLimit {
    final candidates = <int>[
      if (campaignPerWinnerLimit != null) campaignPerWinnerLimit!,
      if (stockQuantity > 0) stockQuantity,
      if (purchaseLimitDaily != null) purchaseLimitDaily!,
      if (purchaseLimitWeekly != null) purchaseLimitWeekly!,
      if (purchaseLimitLifetime != null) purchaseLimitLifetime!,
    ];
    if (candidates.isEmpty) return null;
    candidates.sort();
    return candidates.first;
  }

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final images = asMapList(json['images']);
    final firstImage = _firstImageUrl(images);
    final campaignPrice = _optionalDouble(json['campaign_price']);
    final taxDisplay =
        _optionalTaxDisplay(json['effective_price_tax_display']) ??
            _optionalTaxDisplay(json['campaign_price_tax_display']) ??
            _optionalTaxDisplay(json['price_tax_display']);
    return ProductItem(
      id: asInt(json['id'], fallback: asInt(json['item_id'])),
      slug: asString(json['slug'],
          fallback:
              asInt(json['id'], fallback: asInt(json['item_id'])).toString()),
      title: asString(json['title'],
          fallback: asString(json['name'], fallback: 'Untitled Item')),
      price: campaignPrice ?? asDouble(json['price']),
      description: asString(json['description']),
      imageUrl: _absoluteFirstMediaUrl(
          [firstImage, json['image_url'], json['image_path']]),
      stockQuantity: asInt(json['stock'],
          fallback:
              asInt(json['stock_quantity'], fallback: asInt(json['quantity']))),
      category: asString(json['category_name'],
          fallback: asString(asMap(json['category'])['name'],
              fallback: asString(json['category_slug']))),
      subcategory: asString(json['subcategory_name'],
          fallback: asString(asMap(json['subcategory'])['name'])),
      setName:
          asString(json['set_name'], fallback: asString(json['tcg_set_name'])),
      rarity: asString(json['rarity']),
      isActive: asBool(json['is_active'], fallback: true),
      availabilityStatus: asString(json['availability_status']),
      purchaseLimitDaily:
          _optionalInt(json['purchase_limit_daily'] ?? json['max_per_user']),
      purchaseLimitWeekly:
          _optionalInt(json['purchase_limit_weekly'] ?? json['max_per_week']),
      purchaseLimitLifetime: _optionalInt(
          json['purchase_limit_lifetime'] ?? json['max_total_per_user']),
      myEntitlementId:
          _nullableString(json['my_entitlement_id'] ?? json['entitlement_id']),
      myCampaignItemId:
          _optionalInt(json['my_campaign_item_id'] ?? json['campaign_item_id']),
      campaignPrice: campaignPrice,
      campaignPerWinnerLimit: _optionalInt(
          json['campaign_per_winner_limit'] ?? json['per_winner_limit']),
      taxDisplay: taxDisplay,
    );
  }

  static int? _optionalInt(Object? value) {
    if (value == null) return null;
    final parsed = asInt(value);
    return parsed <= 0 ? null : parsed;
  }

  static double? _optionalDouble(Object? value) {
    if (value == null) return null;
    final parsed = asDouble(value, fallback: -1);
    return parsed < 0 ? null : parsed;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'item_id': id,
        'slug': slug,
        'title': title,
        'price': price,
        'description': description,
        'image_url': imageUrl,
        'stock_quantity': stockQuantity,
        'category_name': category,
        'subcategory_name': subcategory,
        'set_name': setName,
        'rarity': rarity,
        'is_active': isActive,
        'availability_status': availabilityStatus,
        'purchase_limit_daily': purchaseLimitDaily,
        'purchase_limit_weekly': purchaseLimitWeekly,
        'purchase_limit_lifetime': purchaseLimitLifetime,
        'my_entitlement_id': myEntitlementId,
        'my_campaign_item_id': myCampaignItemId,
        'campaign_price': campaignPrice,
        'campaign_per_winner_limit': campaignPerWinnerLimit,
        'price_tax_display': taxDisplay?.toJson(),
      };
}

class StoreCategory {
  const StoreCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.itemCount = 0,
  });

  final int id;
  final String name;
  final String slug;
  final int itemCount;

  factory StoreCategory.fromJson(Map<String, dynamic> json) {
    return StoreCategory(
      id: asInt(json['id']),
      name: asString(json['name']),
      slug: asString(json['slug']),
      itemCount: asInt(json['item_count']),
    );
  }
}

class HomepageSection {
  const HomepageSection(
      {required this.id,
      required this.title,
      this.subtitle = '',
      this.kind = '',
      this.isActive = true});

  final int id;
  final String title;
  final String subtitle;
  final String kind;
  final bool isActive;

  factory HomepageSection.fromJson(Map<String, dynamic> json) {
    return HomepageSection(
      id: asInt(json['id']),
      title: asString(json['title'],
          fallback: asString(json['name'], fallback: 'Featured')),
      subtitle: asString(json['subtitle']),
      kind: asString(json['section_type'], fallback: asString(json['kind'])),
      isActive: asBool(json['is_active'], fallback: true),
    );
  }
}

class StorefrontCampaignBanner {
  const StorefrontCampaignBanner({
    required this.id,
    required this.title,
    required this.slug,
    this.subtitle = '',
    this.heroImageUrl,
    this.ctaLabel = 'Shop Now',
    this.ctaUrl = '',
    this.displayOrder = 0,
  });

  final int id;
  final String title;
  final String subtitle;
  final String slug;
  final String? heroImageUrl;
  final String ctaLabel;
  final String ctaUrl;
  final int displayOrder;

  factory StorefrontCampaignBanner.fromJson(Map<String, dynamic> json) {
    return StorefrontCampaignBanner(
      id: asInt(json['id']),
      title: asString(json['title'], fallback: 'Campaign'),
      subtitle: asString(json['subtitle']),
      slug: asString(json['slug']),
      heroImageUrl: absoluteMediaUrl(asString(json['hero_display_url'])),
      ctaLabel: asString(json['cta_label'], fallback: 'Shop Now'),
      ctaUrl: asString(json['cta_url']),
      displayOrder: asInt(json['display_order']),
    );
  }
}

class StorefrontCampaignDetail extends StorefrontCampaignBanner {
  const StorefrontCampaignDetail({
    required super.id,
    required super.title,
    required super.slug,
    super.subtitle,
    super.heroImageUrl,
    super.ctaLabel,
    super.ctaUrl,
    super.displayOrder,
    this.body = '',
    this.productLineSlug,
    this.startsAt,
    this.endsAt,
  });

  final String body;
  final String? productLineSlug;
  final String? startsAt;
  final String? endsAt;

  factory StorefrontCampaignDetail.fromJson(Map<String, dynamic> json) {
    return StorefrontCampaignDetail(
      id: asInt(json['id']),
      title: asString(json['title'], fallback: 'Campaign'),
      subtitle: asString(json['subtitle']),
      slug: asString(json['slug']),
      heroImageUrl: absoluteMediaUrl(asString(json['hero_display_url'])),
      ctaLabel: asString(json['cta_label'], fallback: 'Shop Now'),
      ctaUrl: asString(json['cta_url']),
      displayOrder: asInt(json['display_order']),
      body: asString(json['body']),
      productLineSlug: _nullableString(json['product_line_slug']),
      startsAt: _nullableString(json['starts_at']),
      endsAt: _nullableString(json['ends_at']),
    );
  }
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

class StoreSettings {
  const StoreSettings({
    this.storeAnnouncement = '',
    this.announcementExpiresAt,
    this.showFooterNewsletter = true,
    this.tradeCreditPercentage = 85,
    this.tradeCashPercentage = 65,
    this.salesTaxRatePercent = 9.25,
    this.maxTradeCardsPerOrder = 5,
    this.discordWebhookUrl = '',
    this.payVenmo = true,
    this.payZelle = true,
    this.payPaypal = true,
    this.payCash = true,
    this.payTrade = true,
    this.tradeInsEnabled = true,
    this.isOoo = false,
    this.oooUntil,
    this.ordersDisabled = false,
    this.ucscDiscordInvite,
    this.publicDiscordInvite,
    this.standardLegalMarks = const [],
    this.standardIllegalMarks = const [],
    this.regulationMarkOptions = const [],
  });

  final String storeAnnouncement;
  final String? announcementExpiresAt;
  final bool showFooterNewsletter;
  final double tradeCreditPercentage;
  final double tradeCashPercentage;
  final double salesTaxRatePercent;
  final int maxTradeCardsPerOrder;
  final String discordWebhookUrl;
  final bool payVenmo;
  final bool payZelle;
  final bool payPaypal;
  final bool payCash;
  final bool payTrade;
  final bool tradeInsEnabled;
  final bool isOoo;
  final String? oooUntil;
  final bool ordersDisabled;
  final String? ucscDiscordInvite;
  final String? publicDiscordInvite;
  final List<String> standardLegalMarks;
  final List<String> standardIllegalMarks;
  final List<String> regulationMarkOptions;

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    return StoreSettings(
      storeAnnouncement: asString(json['store_announcement']),
      announcementExpiresAt: json['announcement_expires_at']?.toString(),
      showFooterNewsletter:
          asBool(json['show_footer_newsletter'], fallback: true),
      tradeCreditPercentage:
          asDouble(json['trade_credit_percentage'], fallback: 85),
      tradeCashPercentage:
          asDouble(json['trade_cash_percentage'], fallback: 65),
      salesTaxRatePercent:
          asDouble(json['sales_tax_rate_percent'], fallback: 9.25),
      maxTradeCardsPerOrder:
          asInt(json['max_trade_cards_per_order'], fallback: 5),
      discordWebhookUrl: asString(json['discord_webhook_url']),
      payVenmo: asBool(json['pay_venmo_enabled'], fallback: true),
      payZelle: asBool(json['pay_zelle_enabled'], fallback: true),
      payPaypal: asBool(json['pay_paypal_enabled'], fallback: true),
      payCash: asBool(json['pay_cash_enabled'], fallback: true),
      payTrade: asBool(json['pay_trade_enabled'], fallback: true),
      tradeInsEnabled: asBool(json['trade_ins_enabled'], fallback: true),
      isOoo: asBool(json['is_ooo']),
      oooUntil: json['ooo_until']?.toString(),
      ordersDisabled: asBool(json['orders_disabled']),
      ucscDiscordInvite: json['ucsc_discord_invite']?.toString(),
      publicDiscordInvite: json['public_discord_invite']?.toString(),
      standardLegalMarks: _asStringList(json['standard_legal_marks']),
      standardIllegalMarks: _asStringList(json['standard_illegal_marks']),
      regulationMarkOptions: _asStringList(json['regulation_mark_options']),
    );
  }
}

List<String> _asStringList(dynamic value) {
  if (value is List) return value.map((e) => e.toString()).toList();
  return const [];
}

class RecurringTimeslot {
  const RecurringTimeslot({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.location = '',
    this.maxBookings = 0,
    this.bookingsThisWeek = 0,
    this.pickupDate,
    this.isActive = true,
    this.isAvailable = true,
  });

  final int id;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String location;
  final int maxBookings;
  final int bookingsThisWeek;
  final String? pickupDate;
  final bool isActive;
  final bool isAvailable;

  int get spotsLeft => maxBookings - bookingsThisWeek;
  bool get isFull => !isAvailable;

  factory RecurringTimeslot.fromJson(Map<String, dynamic> json) {
    return RecurringTimeslot(
      id: asInt(json['id']),
      dayOfWeek: asInt(json['day_of_week']),
      startTime: asString(json['start_time']),
      endTime: asString(json['end_time']),
      location: asString(json['location']),
      maxBookings: asInt(json['max_bookings']),
      bookingsThisWeek: asInt(json['bookings_this_week']),
      pickupDate: json['pickup_date']?.toString(),
      isActive: asBool(json['is_active'], fallback: true),
      isAvailable: json.containsKey('is_available')
          ? asBool(json['is_available'], fallback: true)
          : asInt(json['max_bookings']) > asInt(json['bookings_this_week']),
    );
  }
}

class TimeslotSelection {
  const TimeslotSelection(
      {required this.recurringTimeslotId, required this.pickupDate});

  final int recurringTimeslotId;
  final String pickupDate;

  Map<String, dynamic> toJson() => {
        'recurring_timeslot': recurringTimeslotId,
        'recurring_timeslot_id': recurringTimeslotId,
        'pickup_date': pickupDate,
      };
}

class CartLine {
  const CartLine({required this.item, required this.quantity});

  final ProductItem item;
  final int quantity;

  double get subtotal => item.price * quantity;

  CartLine copyWith({ProductItem? item, int? quantity}) {
    return CartLine(
        item: item ?? this.item, quantity: quantity ?? this.quantity);
  }

  factory CartLine.fromJson(Map<String, dynamic> json) {
    final nestedItem = asMap(json['item']);
    final itemPayload = nestedItem.isNotEmpty
        ? nestedItem
        : <String, dynamic>{
            'id': json['item_id'],
            'item_id': json['item_id'],
            'slug': json['slug'],
            'title': json['title'],
            'price': json['price'],
            'description': json['description'],
            'image_path': json['image_path'],
            'stock': json['stock'],
            'max_per_user': json['max_per_user'],
            'campaign_item_id': json['campaign_item_id'],
            'entitlement_id': json['entitlement_id'],
            'campaign_per_winner_limit': json['campaign_per_winner_limit'],
            'price_tax_display': json['price_tax_display'],
          };
    return CartLine(
        item: ProductItem.fromJson(itemPayload),
        quantity: asInt(json['quantity'], fallback: 1));
  }

  Map<String, dynamic> toJson() =>
      {'item': item.toJson(), 'quantity': quantity};
  Map<String, dynamic> toCheckoutJson() {
    final payload = <String, dynamic>{
      'item': item.id,
      'item_id': item.id,
      'quantity': quantity,
    };
    if (item.myCampaignItemId != null) {
      payload['campaign_item'] = item.myCampaignItemId;
      payload['campaign_item_id'] = item.myCampaignItemId;
    }
    if (item.myEntitlementId != null) {
      payload['entitlement'] = item.myEntitlementId;
      payload['entitlement_id'] = item.myEntitlementId;
    }
    return payload;
  }
}

class OrderLine {
  const OrderLine(
      {required this.title,
      required this.quantity,
      required this.price,
      this.id,
      this.orderItemIds = const [],
      this.priceTaxDisplay,
      this.subtotalTaxDisplay,
      this.imageUrl});

  final int? id;
  final String title;
  final int quantity;
  final double price;
  final List<int> orderItemIds;
  final TaxDisplay? priceTaxDisplay;
  final TaxDisplay? subtotalTaxDisplay;
  final String? imageUrl;

  double get subtotal => price * quantity;

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    final images = asMapList(json['images']);
    return OrderLine(
      id: json['id'] == null ? null : asInt(json['id']),
      title: asString(json['item_title'], fallback: asString(json['title'])),
      quantity: asInt(json['quantity'], fallback: 1),
      price: asDouble(json['price_at_purchase'],
          fallback: asDouble(json['item_price'])),
      orderItemIds: _asIntList(json['order_item_ids']),
      priceTaxDisplay: _optionalTaxDisplay(json['price_tax_display']),
      subtotalTaxDisplay: _optionalTaxDisplay(json['subtotal_tax_display']),
      imageUrl: _absoluteFirstMediaUrl(
          [_firstImageUrl(images), json['image_path'], json['image_url']]),
    );
  }

  static List<int> _asIntList(Object? value) {
    if (value is! List) return const [];
    return value.map((item) => asInt(item)).where((id) => id > 0).toList();
  }
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.orderId,
    required this.status,
    required this.paymentMethod,
    required this.deliveryMethod,
    required this.createdAt,
    this.pickupLabel = '',
    this.items = const [],
    this.total = 0,
    this.discountApplied = 0,
    this.tradeCreditApplied = 0,
    this.storeCreditApplied = 0,
    this.taxSummary,
    this.counterofferMessage = '',
    this.itemsSummary = '',
    this.customerEmail = '',
    this.discordHandle = '',
    this.couponCode = '',
    this.isAcknowledged = false,
    this.pickupDate = '',
  });

  final int id;
  final String orderId;
  final String status;
  final String paymentMethod;
  final String deliveryMethod;
  final String createdAt;
  final String pickupLabel;
  final List<OrderLine> items;
  final double total;
  final double discountApplied;
  final double tradeCreditApplied;
  final double storeCreditApplied;
  final TaxDisplay? taxSummary;
  final String counterofferMessage;
  final String itemsSummary;
  final String customerEmail;
  final String discordHandle;
  final String couponCode;
  final bool isAcknowledged;
  final String pickupDate;

  double get netDue =>
      (taxIncludedTotalAfterDiscount - tradeCreditApplied - storeCreditApplied)
          .clamp(0, double.infinity)
          .toDouble();
  double get taxIncludedTotalAfterDiscount =>
      taxSummary?.grossTotal ??
      (total - discountApplied).clamp(0, double.infinity).toDouble();

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final lineData = asMapList(json['display_items']).isNotEmpty
        ? asMapList(json['display_items'])
        : asMapList(json['order_items']);
    final lines = lineData.map(OrderLine.fromJson).toList();
    final computedTotal =
        lines.fold<double>(0, (sum, line) => sum + line.subtotal);
    final taxSummaryMap = asMap(json['tax_summary']);
    final snapshotTaxSummary = taxSummaryMap.isNotEmpty
        ? TaxDisplay.fromJson(taxSummaryMap)
        : (json['pre_tax_subtotal'] != null &&
                json['sales_tax_amount'] != null &&
                json['tax_inclusive_total'] != null &&
                json['sales_tax_rate_percent'] != null)
            ? TaxDisplay(
                grossTotal: asDouble(json['tax_inclusive_total']),
                preTaxSubtotal: asDouble(json['pre_tax_subtotal']),
                salesTax: asDouble(json['sales_tax_amount']),
                taxRatePercent: asDouble(json['sales_tax_rate_percent']),
              )
            : null;
    return OrderSummary(
      id: asInt(json['id']),
      orderId: asString(json['order_id']),
      status: asString(json['status'], fallback: 'pending'),
      paymentMethod: asString(json['payment_method']),
      deliveryMethod: asString(json['delivery_method']),
      createdAt: asString(json['created_at']),
      pickupLabel: asString(json['delivery_details'],
          fallback: asString(json['pickup_timeslot'],
              fallback: asString(json['recurring_timeslot']))),
      items: lines,
      total: asDouble(json['total'], fallback: computedTotal),
      discountApplied: asDouble(json['discount_applied']),
      tradeCreditApplied: asDouble(json['trade_credit_applied']),
      storeCreditApplied: asDouble(json['store_credit_applied']),
      taxSummary: snapshotTaxSummary,
      counterofferMessage: asString(json['counteroffer_message']),
      itemsSummary: asString(json['items_summary']),
      customerEmail: asString(json['user_email'],
          fallback: asString(json['customer_email'])),
      discordHandle: asString(json['discord_handle']),
      couponCode: asString(json['coupon_code']),
      isAcknowledged: asBool(json['is_acknowledged']),
      pickupDate: asString(json['pickup_date']),
    );
  }
}

class CouponValidation {
  const CouponValidation(
      {required this.code,
      required this.computedDiscount,
      this.disabledReason});

  final String code;
  final double computedDiscount;
  final String? disabledReason;

  bool get isUsable => disabledReason == null || disabledReason!.isEmpty;

  factory CouponValidation.fromJson(Map<String, dynamic> json) {
    return CouponValidation(
      code: asString(json['code']),
      computedDiscount: asDouble(json['computed_discount']),
      disabledReason: json['disabled_reason']?.toString(),
    );
  }
}

class TradeCardEntry {
  const TradeCardEntry({
    required this.cardName,
    required this.estimatedValue,
    this.setName = '',
    this.cardNumber = '',
    this.condition = 'near_mint',
    this.quantity = 1,
    this.imageUrl = '',
    this.tcgProductId,
    this.tcgSubType = '',
    this.baseMarketPrice,
    this.tcgplayerUrl = '',
  });

  final String cardName;
  final double estimatedValue;
  final String setName;
  final String cardNumber;
  final String condition;
  final int quantity;
  final String imageUrl;
  final int? tcgProductId;
  final String tcgSubType;
  final double? baseMarketPrice;
  final String tcgplayerUrl;

  Map<String, dynamic> toJson() => {
        'card_name': cardName,
        'set_name': setName,
        'card_number': cardNumber,
        'condition': condition,
        'quantity': quantity,
        'estimated_value': estimatedValue,
        'user_estimated_price': estimatedValue,
        'image_url': imageUrl,
        'tcg_product_id': tcgProductId,
        'tcg_sub_type': tcgSubType,
        'base_market_price': baseMarketPrice,
        'tcgplayer_url': tcgplayerUrl,
      };
}

class TradeCardSearchResult {
  const TradeCardSearchResult({
    required this.name,
    this.setName = '',
    this.cardNumber = '',
    this.rarity = '',
    this.imageUrl = '',
    this.marketPrice = 0,
    this.tcgProductId,
    this.tcgSubType = '',
    this.tcgplayerUrl = '',
    this.source = 'search',
  });

  final String name;
  final String setName;
  final String cardNumber;
  final String rarity;
  final String imageUrl;
  final double marketPrice;
  final int? tcgProductId;
  final String tcgSubType;
  final String tcgplayerUrl;
  final String source;

  String get subtitle {
    final parts = [
      if (setName.isNotEmpty) setName,
      if (cardNumber.isNotEmpty) cardNumber,
      if (rarity.isNotEmpty) rarity,
    ];
    return parts.join(' - ');
  }

  TradeCardEntry toEntry() => TradeCardEntry(
        cardName: name,
        estimatedValue: marketPrice,
        setName: setName,
        cardNumber: cardNumber,
        imageUrl: imageUrl,
        tcgProductId: tcgProductId,
        tcgSubType: tcgSubType,
        baseMarketPrice: marketPrice > 0 ? marketPrice : null,
        tcgplayerUrl: tcgplayerUrl,
      );

  factory TradeCardSearchResult.fromTcgJson(Map<String, dynamic> json) {
    return TradeCardSearchResult(
      name: asString(json['name'], fallback: 'Unknown card'),
      setName:
          asString(json['set_name'], fallback: asString(json['group_name'])),
      cardNumber:
          asString(json['number'], fallback: asString(json['card_number'])),
      rarity: asString(json['rarity']),
      imageUrl: asString(json['image_large'],
          fallback: asString(json['image_small'],
              fallback: asString(json['image_url']))),
      marketPrice: asDouble(json['market_price']),
      tcgProductId:
          asInt(json['product_id']) > 0 ? asInt(json['product_id']) : null,
      tcgSubType: asString(json['sub_type_name'],
          fallback: asString(json['tcg_price_sub_type'])),
      tcgplayerUrl: asString(json['tcgplayer_url']),
      source: 'search',
    );
  }

  factory TradeCardSearchResult.fromWantedJson(Map<String, dynamic> json) {
    final tcgData = asMap(json['tcg_card_data']);
    final images = asMapList(json['images']);
    final firstImage = _firstImageUrl(images);
    return TradeCardSearchResult(
      name: asString(json['name'], fallback: asString(tcgData['name'])),
      setName: asString(tcgData['set_name'],
          fallback: asString(tcgData['group_name'])),
      cardNumber: asString(tcgData['card_number']),
      rarity: asString(tcgData['rarity']),
      imageUrl: _firstNonBlankString([firstImage, tcgData['image_url']]) ?? '',
      marketPrice: asDouble(json['estimated_value'],
          fallback: asDouble(tcgData['market_price'])),
      tcgProductId: asInt(tcgData['product_id']) > 0
          ? asInt(tcgData['product_id'])
          : null,
      tcgSubType: asString(tcgData['sub_type_name']),
      tcgplayerUrl: asString(tcgData['tcgplayer_url']),
      source: 'wanted',
    );
  }
}

class WalletSummary {
  const WalletSummary({required this.balance});

  final double balance;

  factory WalletSummary.fromJson(Map<String, dynamic> json) =>
      WalletSummary(balance: asDouble(json['balance']));
}

class TradeInRequestSummary {
  const TradeInRequestSummary(
      {required this.id,
      required this.status,
      required this.payoutLabel,
      required this.createdAt,
      required this.estimatedValue});

  final int id;
  final String status;
  final String payoutLabel;
  final String createdAt;
  final double estimatedValue;

  factory TradeInRequestSummary.fromJson(Map<String, dynamic> json) {
    return TradeInRequestSummary(
      id: asInt(json['id']),
      status: asString(json['status']),
      payoutLabel: asString(json['payout_label']),
      createdAt: asString(json['created_at']),
      estimatedValue: asDouble(json['estimated_total_value']),
    );
  }
}
