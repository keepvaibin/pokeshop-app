import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/models/api_models.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/json_helpers.dart';
import '../../../core/network/network_providers.dart';

class CampaignRepository {
  CampaignRepository(this._dio);

  final Dio _dio;

  Future<List<StorefrontCampaignBanner>> getCampaigns(
      {String scope = 'global'}) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.campaigns,
        queryParameters: {'scope': scope},
        options: Options(extra: {'skipAuth': true}),
      );
      return asMapList(response.data)
          .map(StorefrontCampaignBanner.fromJson)
          .where((campaign) => campaign.slug.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<StorefrontCampaignDetail> getCampaign(String slug) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.campaignBySlug(slug),
        options: Options(extra: {'skipAuth': true}),
      );
      return StorefrontCampaignDetail.fromJson(
          response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }
}

final campaignRepositoryProvider = Provider<CampaignRepository>(
    (ref) => CampaignRepository(ref.watch(dioProvider)));

final campaignBannersProvider =
    FutureProvider.family<List<StorefrontCampaignBanner>, String>(
        (ref, scope) =>
            ref.watch(campaignRepositoryProvider).getCampaigns(scope: scope));

final campaignDetailProvider =
    FutureProvider.family<StorefrontCampaignDetail, String>(
        (ref, slug) => ref.watch(campaignRepositoryProvider).getCampaign(slug));
