import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeshop_app/features/campaign/presentation/campaign_navigation.dart';
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
}
