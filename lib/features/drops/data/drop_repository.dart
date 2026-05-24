import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/models/api_models.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/json_helpers.dart';
import '../../../core/network/network_providers.dart';

class DropOption {
  const DropOption({
    required this.id,
    required this.itemId,
    required this.title,
    required this.slug,
    required this.price,
    required this.isAvailable,
    this.campaignItemId,
    this.groupId,
    this.imageUrl,
    this.perWinnerLimit,
    this.taxDisplay,
    this.isSoldOut = false,
    this.isPurchased = false,
    this.productQuery = '',
  });

  final int id;
  final int itemId;
  final int? campaignItemId;
  final int? groupId;
  final String title;
  final String slug;
  final double price;
  final String? imageUrl;
  final int? perWinnerLimit;
  final TaxDisplay? taxDisplay;
  final bool isAvailable;
  final bool isSoldOut;
  final bool isPurchased;
  final String productQuery;

  bool get canChoose => isAvailable && !isPurchased;

  factory DropOption.fromJson(Map<String, dynamic> json) {
    final images = asMapList(json['images']);
    final firstImage =
        images.isEmpty ? const <String, dynamic>{} : images.first;
    return DropOption(
      id: asInt(json['id'], fallback: asInt(json['item_id'])),
      itemId: asInt(json['item_id'], fallback: asInt(json['id'])),
      campaignItemId: _optionalInt(json['campaign_item_id']),
      groupId: _optionalInt(json['group_id']),
      title: asString(json['title'], fallback: 'Untitled Item'),
      slug: asString(json['slug']),
      price: asDouble(json['price']),
      taxDisplay: _optionalTaxDisplay(json['price_tax_display']),
      imageUrl: absoluteMediaUrl(_firstNonBlank([
        firstImage['url'],
        firstImage['image'],
        firstImage['image_url'],
        json['image_url'],
        json['image_path'],
      ])),
      perWinnerLimit: _optionalInt(json['per_winner_limit']),
      isAvailable: asBool(json['is_available'], fallback: true),
      isSoldOut: asBool(json['is_sold_out']),
      isPurchased: asBool(json['is_purchased']),
      productQuery: asString(json['product_query']),
    );
  }

  ProductItem toProductItem(String entitlementId) {
    return ProductItem(
      id: itemId,
      slug: slug,
      title: title,
      price: price,
      imageUrl: imageUrl,
      stockQuantity: canChoose ? (perWinnerLimit ?? 1) : 0,
      availabilityStatus: canChoose ? 'active' : 'oos',
      myEntitlementId: entitlementId,
      myCampaignItemId: campaignItemId,
      campaignPerWinnerLimit: perWinnerLimit,
      taxDisplay: taxDisplay,
    );
  }

  String productPath(String entitlementId) {
    final query = <String, String>{
      'entitlement': entitlementId,
      if (campaignItemId != null) 'campaign_item': '$campaignItemId',
    };
    return Uri(path: '/product/$slug', queryParameters: query).toString();
  }
}

TaxDisplay? _optionalTaxDisplay(Object? value) {
  final map = asMap(value);
  return map.isEmpty ? null : TaxDisplay.fromJson(map);
}

class DropGroup {
  const DropGroup({
    required this.name,
    required this.position,
    required this.options,
    this.id,
  });

  final int? id;
  final String name;
  final int position;
  final List<DropOption> options;

  factory DropGroup.fromJson(Map<String, dynamic> json) {
    return DropGroup(
      id: _optionalInt(json['id']),
      name: asString(json['name'], fallback: 'Choice Group'),
      position: asInt(json['position']),
      options: asMapList(json['options']).map(DropOption.fromJson).toList(),
    );
  }
}

class DropClaim {
  const DropClaim({
    required this.id,
    required this.status,
    required this.expiresAt,
    required this.isExpired,
    required this.campaignName,
    required this.usesGroupedRules,
    required this.requiresSelection,
    required this.allPurchased,
    required this.items,
    required this.groups,
    required this.selectedItemIds,
    this.currentUserEmail = '',
  });

  final String id;
  final String status;
  final DateTime? expiresAt;
  final bool isExpired;
  final String campaignName;
  final bool usesGroupedRules;
  final bool requiresSelection;
  final bool allPurchased;
  final List<DropOption> items;
  final List<DropGroup> groups;
  final List<int> selectedItemIds;
  final String currentUserEmail;

  bool get hasConfirmedSelection => selectedItemIds.isNotEmpty;
  bool get isActive => status == 'active' && !isExpired && !allPurchased;

  List<DropOption> get selectedOptions {
    final selected = selectedItemIds.toSet();
    return items.where((item) => selected.contains(item.itemId)).toList();
  }

  List<DropOption> get unlockedOptions =>
      requiresSelection ? selectedOptions : items;

  factory DropClaim.fromJson(Map<String, dynamic> json) {
    return DropClaim(
      id: asString(json['id']),
      status: asString(json['status'], fallback: 'active'),
      expiresAt: DateTime.tryParse(asString(json['expires_at'])),
      isExpired: asBool(json['is_expired']),
      campaignName: asString(json['campaign_name'], fallback: 'Drop'),
      usesGroupedRules: asBool(json['uses_grouped_rules']),
      requiresSelection: asBool(json['requires_selection']),
      allPurchased: asBool(json['all_purchased']),
      items: asMapList(json['items']).map(DropOption.fromJson).toList(),
      groups: asMapList(json['groups']).map(DropGroup.fromJson).toList(),
      selectedItemIds: _asIntList(json['selected_item_ids']),
      currentUserEmail: asString(json['current_user_email']),
    );
  }
}

class MyDropSummary {
  const MyDropSummary({
    required this.entitlementId,
    required this.campaignId,
    required this.campaignName,
    required this.expiresAt,
    required this.usesGroupedRules,
    required this.requiresSelection,
    required this.items,
    required this.groups,
    required this.selectedItemIds,
  });

  final String entitlementId;
  final int campaignId;
  final String campaignName;
  final DateTime? expiresAt;
  final bool usesGroupedRules;
  final bool requiresSelection;
  final List<DropOption> items;
  final List<DropGroup> groups;
  final List<int> selectedItemIds;

  bool get hasConfirmedSelection => selectedItemIds.isNotEmpty;
  List<DropOption> get visibleOptions {
    if (!requiresSelection || selectedItemIds.isEmpty) return items;
    final selected = selectedItemIds.toSet();
    return items.where((item) => selected.contains(item.itemId)).toList();
  }

  factory MyDropSummary.fromJson(Map<String, dynamic> json) {
    return MyDropSummary(
      entitlementId: asString(json['entitlement_id']),
      campaignId: asInt(json['campaign_id']),
      campaignName: asString(json['campaign_name'], fallback: 'Drop'),
      expiresAt: DateTime.tryParse(asString(json['expires_at'])),
      usesGroupedRules: asBool(json['uses_grouped_rules']),
      requiresSelection: asBool(json['requires_selection']),
      items: asMapList(json['items']).map(DropOption.fromJson).toList(),
      groups: asMapList(json['groups']).map(DropGroup.fromJson).toList(),
      selectedItemIds: _asIntList(json['selected_item_ids']),
    );
  }
}

class DropSelectionResult {
  const DropSelectionResult({required this.items});

  final List<DropSelectionLink> items;

  factory DropSelectionResult.fromJson(Map<String, dynamic> json) {
    return DropSelectionResult(
      items: asMapList(json['items']).map(DropSelectionLink.fromJson).toList(),
    );
  }
}

class DropSelectionLink {
  const DropSelectionLink({required this.slug, required this.productQuery});

  final String slug;
  final String productQuery;

  factory DropSelectionLink.fromJson(Map<String, dynamic> json) {
    return DropSelectionLink(
      slug: asString(json['slug']),
      productQuery: asString(json['product_query']),
    );
  }
}

class DropRepository {
  DropRepository(this._dio);

  final Dio _dio;

  Future<List<MyDropSummary>> myDrops() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.myDrops);
      return asMapList(response.data).map(MyDropSummary.fromJson).toList();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<DropClaim> claim(String entitlementId) async {
    try {
      final response = await _dio
          .get<Map<String, dynamic>>(ApiEndpoints.dropClaim(entitlementId));
      return DropClaim.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<DropSelectionResult> selectItems(
      String entitlementId, List<int> itemIds) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.dropSelect(entitlementId),
        data: {'item_ids': itemIds},
      );
      return DropSelectionResult.fromJson(
          response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }
}

final dropRepositoryProvider =
    Provider<DropRepository>((ref) => DropRepository(ref.watch(dioProvider)));

final myDropsProvider = FutureProvider<List<MyDropSummary>>(
    (ref) => ref.watch(dropRepositoryProvider).myDrops());

final dropClaimProvider = FutureProvider.family<DropClaim, String>(
    (ref, entitlementId) =>
        ref.watch(dropRepositoryProvider).claim(entitlementId));

String? _firstNonBlank(Iterable<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) return text;
  }
  return null;
}

int? _optionalInt(Object? value) {
  if (value == null) return null;
  final parsed = asInt(value);
  return parsed <= 0 ? null : parsed;
}

List<int> _asIntList(Object? value) {
  if (value is! List) return const [];
  return value.map(asInt).where((id) => id > 0).toList();
}
