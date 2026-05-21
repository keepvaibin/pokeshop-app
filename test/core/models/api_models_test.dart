import 'package:flutter_test/flutter_test.dart';
import 'package:pokeshop_app/core/models/api_models.dart';
import 'package:pokeshop_app/features/shop/data/shop_repository.dart';

void main() {
  group('ProductItem', () {
    test('parses web/backend item fields', () {
      final item = ProductItem.fromJson({
        'id': 7,
        'slug': 'pikachu-ex',
        'title': 'Pikachu ex',
        'price': '12.50',
        'stock': 3,
        'category_slug': 'cards',
      });

      expect(item.id, 7);
      expect(item.slug, 'pikachu-ex');
      expect(item.price, 12.5);
      expect(item.inStock, isTrue);
      expect(item.stockQuantity, 3);
      expect(item.category, 'cards');
    });

    test('prefers uploaded item images over blank or remote image paths', () {
      final item = ProductItem.fromJson({
        'id': 8,
        'slug': 'mega-battle-deck',
        'title': 'Mega Battle Deck',
        'price': '39.99',
        'image_path': 'https://images.example.com/old-art.png',
        'images': [
          {'url': '/media/inventory_images/mega-battle.png'}
        ],
      });

      expect(item.imageUrl,
          'https://api.santacruztcg.com/media/inventory_images/mega-battle.png');
    });
  });

  group('StorefrontCampaign', () {
    test('parses public campaign detail payloads', () {
      final campaign = StorefrontCampaignDetail.fromJson({
        'id': 1,
        'title': 'Chaos Rising',
        'subtitle': 'The storm is here',
        'slug': 'chaos-rising',
        'hero_display_url': '/media/campaign_heroes/chaos.png',
        'body': '<p>Enter the raffle</p>',
        'cta_label': 'Shop Chaos Rising',
        'cta_url':
            'https://santacruztcg.com/search?tcg_set_name=Chaos%20Rising',
        'product_line_slug': '',
      });

      expect(campaign.slug, 'chaos-rising');
      expect(campaign.heroImageUrl,
          'https://api.santacruztcg.com/media/campaign_heroes/chaos.png');
      expect(campaign.productLineSlug, isNull);
      expect(campaign.body, contains('raffle'));
    });
  });

  group('OrderLine', () {
    test('falls back when backend image path is blank', () {
      final line = OrderLine.fromJson({
        'item_title': 'Perfect Order ETB',
        'quantity': 1,
        'price_at_purchase': '59.99',
        'image_path': '',
        'image_url': 'https://images.example.com/perfect-order.png',
      });

      expect(line.imageUrl, 'https://images.example.com/perfect-order.png');
    });
  });

  group('checkout models', () {
    test('serializes cart lines using backend-compatible keys', () {
      final item = ProductItem.fromJson(
          {'id': 1, 'slug': 'card', 'title': 'Card', 'price': '4.00'});
      final line = CartLine(item: item, quantity: 2);

      expect(line.toCheckoutJson(), {'item': 1, 'item_id': 1, 'quantity': 2});
    });

    test('serializes timeslot selection with both legacy and explicit ids', () {
      const selection =
          TimeslotSelection(recurringTimeslotId: 5, pickupDate: '2026-05-15');

      expect(selection.toJson()['recurring_timeslot'], 5);
      expect(selection.toJson()['recurring_timeslot_id'], 5);
      expect(selection.toJson()['pickup_date'], '2026-05-15');
    });
  });
  group('ShopQuery', () {
    test('uses frontend-compatible inventory query parameters', () {
      const query = ShopQuery(
        search: 'pikachu',
        category: 'cards',
        sort: 'price-low',
        inStockOnly: true,
      );

      expect(query.toQuery(), containsPair('q', 'pikachu'));
      expect(query.toQuery(), containsPair('category', 'cards'));
      expect(query.toQuery(), containsPair('sort', 'price-low'));
      expect(query.toQuery(), containsPair('in_stock', '1'));
      expect(query.toQuery(), isNot(contains('search')));
    });
  });
}
