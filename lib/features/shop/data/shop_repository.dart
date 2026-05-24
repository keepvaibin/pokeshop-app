import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/models/api_models.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/json_helpers.dart';
import '../../../core/network/network_providers.dart';

class ShopQuery {
  const ShopQuery(
      {this.search = '',
      this.homeFeed,
      this.page = 1,
      this.category,
      this.sort = 'featured',
      this.inStockOnly = false,
      this.filters = const {}});

  final String search;
  final String? homeFeed;
  final int page;
  final String? category;
  final String sort;
  final bool inStockOnly;
  final Map<String, String> filters;

  Map<String, dynamic> toQuery() {
    return {
      if (search.trim().isNotEmpty) 'q': search.trim(),
      if (homeFeed != null) 'home_feed': homeFeed,
      if (category != null) 'category': category,
      if (sort.isNotEmpty && sort != 'featured') 'sort': sort,
      if (inStockOnly) 'in_stock': '1',
      'page': page,
      ...filters,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ShopQuery &&
        other.search == search &&
        other.homeFeed == homeFeed &&
        other.page == page &&
        other.category == category &&
        other.sort == sort &&
        other.inStockOnly == inStockOnly &&
        other.filters.toString() == filters.toString();
  }

  @override
  int get hashCode => Object.hash(
      search, homeFeed, page, category, sort, inStockOnly, filters.toString());
}

class ProductLookup {
  const ProductLookup({
    required this.slug,
    this.entitlementId,
    this.campaignItemId,
  });

  final String slug;
  final String? entitlementId;
  final int? campaignItemId;

  Map<String, dynamic> get queryParameters => {
        if (entitlementId != null && entitlementId!.isNotEmpty)
          'entitlement': entitlementId,
        if (campaignItemId != null) 'campaign_item': campaignItemId,
      };

  @override
  bool operator ==(Object other) {
    return other is ProductLookup &&
        other.slug == slug &&
        other.entitlementId == entitlementId &&
        other.campaignItemId == campaignItemId;
  }

  @override
  int get hashCode => Object.hash(slug, entitlementId, campaignItemId);
}

class HomeData {
  const HomeData(
      {required this.settings,
      required this.sections,
      required this.items,
      required this.newArrivals});

  final StoreSettings settings;
  final List<HomepageSection> sections;
  final List<ProductItem> items;
  final List<ProductItem> newArrivals;
}

class ShopRepository {
  ShopRepository(this._dio);

  final Dio _dio;

  Future<List<ProductItem>> getItems(ShopQuery query) async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.items,
          queryParameters: query.toQuery());
      return asMapList(response.data).map(ProductItem.fromJson).toList();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<ProductItem> getItem(ProductLookup lookup) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.itemBySlug(lookup.slug),
        queryParameters: lookup.queryParameters,
      );
      return ProductItem.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<StoreSettings> getSettings() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiEndpoints.settings);
      return StoreSettings.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  /// Fire-and-forget: registers the current app version with the backend so
  /// it appears in the admin minimum-version dropdown.
  Future<void> registerAppVersion(String version) async {
    try {
      await _dio.post<void>(
        ApiEndpoints.registerAppVersion,
        data: {'version': version},
      );
    } catch (_) {
      // Non-critical — ignore all errors.
    }
  }

  Future<List<HomepageSection>> getHomepageSections() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.homepageSections);
      return asMapList(response.data)
          .map(HomepageSection.fromJson)
          .where((section) => section.isActive)
          .toList();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<List<StoreCategory>> getCategories() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.categories);
      return asMapList(response.data).map(StoreCategory.fromJson).toList();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<List<RecurringTimeslot>> getRecurringTimeslots() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.recurringTimeslots);
      return asMapList(response.data)
          .map(RecurringTimeslot.fromJson)
          .where((slot) => slot.isActive)
          .toList();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<HomeData> getHomeData() async {
    final results = await Future.wait<dynamic>([
      getSettings(),
      getHomepageSections(),
      getItems(const ShopQuery(homeFeed: 'all_products')),
      getItems(const ShopQuery(homeFeed: 'new_arrivals')),
    ]);
    return HomeData(
      settings: results[0] as StoreSettings,
      sections: results[1] as List<HomepageSection>,
      items: results[2] as List<ProductItem>,
      newArrivals: results[3] as List<ProductItem>,
    );
  }
}

final shopRepositoryProvider =
    Provider<ShopRepository>((ref) => ShopRepository(ref.watch(dioProvider)));
final homeDataProvider = FutureProvider<HomeData>(
    (ref) => ref.watch(shopRepositoryProvider).getHomeData());
final shopItemsProvider = FutureProvider.family<List<ProductItem>, ShopQuery>(
    (ref, query) => ref.watch(shopRepositoryProvider).getItems(query));
final shopCategoriesProvider = FutureProvider<List<StoreCategory>>(
    (ref) => ref.watch(shopRepositoryProvider).getCategories());
final productProvider = FutureProvider.family<ProductItem, ProductLookup>(
    (ref, lookup) => ref.watch(shopRepositoryProvider).getItem(lookup));
final recurringTimeslotsProvider = FutureProvider<List<RecurringTimeslot>>(
    (ref) => ref.watch(shopRepositoryProvider).getRecurringTimeslots());
final storeSettingsProvider = FutureProvider<StoreSettings>(
    (ref) => ref.watch(shopRepositoryProvider).getSettings());
