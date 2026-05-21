import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeshop_app/core/models/api_models.dart';
import 'package:pokeshop_app/features/campaign/data/campaign_repository.dart';
import 'package:pokeshop_app/features/campaign/presentation/campaign_navigation.dart';
import 'package:pokeshop_app/features/campaign/presentation/widgets/campaign_carousel.dart';
import 'package:pokeshop_app/features/campaign/presentation/widgets/campaign_rich_text.dart';

void main() {
  group('campaign links', () {
    test('accepts safe web and relative campaign URLs', () {
      expect(
        safeCampaignUri(
          'https://santacruztcg.com/search?tcg_set_name=Chaos%20Rising',
        )?.path,
        '/search',
      );
      expect(safeCampaignUri('/campaigns/chaos-rising')?.path,
          '/campaigns/chaos-rising');
    });

    test('rejects unsafe URL schemes and control characters', () {
      expect(safeCampaignUri('javascript:alert(1)'), isNull);
      expect(safeCampaignUri('https://santacruztcg.com/se\narch'), isNull);
    });
  });

  group('CampaignRichText', () {
    test('normalizes Quill spacing and table cell break spans', () {
      final zeroWidthSpace = String.fromCharCode(0x200b);

      expect(
        normalizeCampaignHtml(
          '<p>A&nbsp;B<span class="ql-table-cell-break">ignored</span>C$zeroWidthSpace</p>',
        ),
        '<p>A B<br>C</p>',
      );
    });

    testWidgets('renders uneven tables without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: CampaignRichText(
                html: '''
<table class="table-bordered"><tbody>
<tr><td>Alpha</td><td>Beta</td></tr>
<tr><td>Gamma</td></tr>
</tbody></table>
''',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Alpha'), findsOneWidget);
      expect(find.textContaining('Gamma'), findsOneWidget);
    });
  });

  group('StorefrontCampaignCarousel', () {
    testWidgets('keeps long CTA labels constrained on compact screens',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            campaignBannersProvider('global').overrideWith((ref) async => [
                  const StorefrontCampaignBanner(
                    id: 1,
                    title: 'Chaos Rising Raffle: The Storm is Here',
                    slug: 'chaos-rising',
                    subtitle: 'A long enough subtitle to exercise wrapping.',
                    ctaLabel: 'Shop the complete Chaos Rising collection',
                    ctaUrl: '/search?tcg_set_name=Chaos%20Rising',
                  ),
                ]),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                child: StorefrontCampaignCarousel(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('CHAOS RISING'), findsOneWidget);
    });
  });
}
