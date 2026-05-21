import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../../core/theme/app_colors.dart';
import '../campaign_navigation.dart';

class CampaignRichText extends StatelessWidget {
  const CampaignRichText({
    required this.html,
    this.dense = false,
    super.key,
  });

  final String html;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeCampaignHtml(html);
    if (normalized.trim().isEmpty) return const SizedBox.shrink();

    return Html(
      data: normalized,
      onLinkTap: (url, attributes, element) => openCampaignUri(context, url),
      doNotRenderTheseTags: const {'script', 'style'},
      extensions: [
        TagExtension(
          tagsToExtend: const {'table'},
          builder: (extensionContext) => _CampaignHtmlTable(
            element: extensionContext.element,
            dense: dense,
          ),
        ),
      ],
      style: _campaignHtmlStyles(dense: dense),
    );
  }
}

String normalizeCampaignHtml(String value) {
  return value
      .replaceAll(RegExp(r'&nbsp;|&#160;|&#xA0;', caseSensitive: false), ' ')
      .replaceAll(String.fromCharCode(0x00a0), ' ')
      .replaceAll(
        RegExp(
          r'''<span[^>]*class=["'][^"']*\bql-table-cell-break\b[^"']*["'][^>]*>[\s\S]*?<\/span>''',
          caseSensitive: false,
        ),
        '<br>',
      )
      .replaceAll(String.fromCharCode(0x200b), '')
      .replaceAll(String.fromCharCode(0xfeff), '');
}

Map<String, Style> _campaignHtmlStyles({required bool dense}) {
  final bodySize = dense ? 13.0 : 15.0;
  final paragraphBottom = dense ? 6.0 : 12.0;
  final indentUnit = dense ? 12.0 : 18.0;

  return {
    'body': Style(
      margin: Margins.zero,
      padding: HtmlPaddings.zero,
      color: AppColors.pkmnGray,
      fontSize: FontSize(bodySize),
      lineHeight: const LineHeight(1.62),
    ),
    'p': Style(
      margin: Margins.only(bottom: paragraphBottom),
      lineHeight: const LineHeight(1.62),
    ),
    'a': Style(
      color: AppColors.pkmnBlue,
      textDecoration: TextDecoration.underline,
      fontWeight: FontWeight.w700,
    ),
    'h1': Style(
      margin: Margins.only(top: dense ? 8 : 18, bottom: dense ? 8 : 12),
      fontSize: FontSize(dense ? 20 : 26),
      fontWeight: FontWeight.w800,
      color: AppColors.pkmnText,
      lineHeight: const LineHeight(1.18),
    ),
    'h2': Style(
      margin: Margins.only(top: dense ? 8 : 16, bottom: dense ? 6 : 10),
      fontSize: FontSize(dense ? 18 : 22),
      fontWeight: FontWeight.w800,
      color: AppColors.pkmnText,
      lineHeight: const LineHeight(1.22),
    ),
    'h3': Style(
      margin: Margins.only(top: dense ? 6 : 14, bottom: dense ? 4 : 8),
      fontSize: FontSize(dense ? 16 : 19),
      fontWeight: FontWeight.w800,
      color: AppColors.pkmnText,
      lineHeight: const LineHeight(1.25),
    ),
    'blockquote': Style(
      margin: Margins.symmetric(vertical: 12),
      padding: HtmlPaddings.only(left: 14),
      border: const Border(
        left: BorderSide(color: AppColors.pkmnBlue, width: 4),
      ),
      color: AppColors.pkmnGray,
      fontStyle: FontStyle.italic,
    ),
    'ul': Style(margin: Margins.only(bottom: paragraphBottom)),
    'ol': Style(margin: Margins.only(bottom: paragraphBottom)),
    'li': Style(margin: Margins.only(bottom: dense ? 3 : 5)),
    'img': Style(
      margin: Margins.symmetric(vertical: dense ? 6 : 12),
      alignment: Alignment.center,
    ),
    '.ql-align-center': Style(
      textAlign: TextAlign.center,
      alignment: Alignment.center,
    ),
    '.ql-align-right': Style(
      textAlign: TextAlign.right,
      alignment: Alignment.centerRight,
    ),
    '.ql-align-justify': Style(textAlign: TextAlign.justify),
    '.ql-direction-rtl': Style(direction: TextDirection.rtl),
    '.ql-size-small': Style(fontSize: FontSize(bodySize * 0.88)),
    '.ql-size-large': Style(fontSize: FontSize(bodySize * 1.25)),
    '.ql-size-huge': Style(fontSize: FontSize(bodySize * 1.55)),
    for (var index = 1; index <= 8; index += 1)
      '.ql-indent-$index': Style(
        padding: HtmlPaddings.only(
          left: (indentUnit * index).clamp(0, 144).toDouble(),
        ),
      ),
  };
}

class _CampaignHtmlTable extends StatelessWidget {
  const _CampaignHtmlTable({required this.element, required this.dense});

  final dynamic element;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final row in _rowsFor(element)) _cellsFor(row),
    ].where((cells) => cells.isNotEmpty).toList(growable: false);
    if (rows.isEmpty) return const SizedBox.shrink();
    final columnCount = rows.fold<int>(
        0, (count, cells) => cells.length > count ? cells.length : count);

    final classes =
        element?.classes?.map((entry) => entry.toString()).toSet() ??
            <String>{};
    final bordered = classes.contains('table-bordered');
    final invisible = classes.contains('table-invisible');
    final border = bordered && !invisible
        ? TableBorder.all(color: const Color(0xFFCBD5E1), width: 1)
        : null;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 6 : 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fallbackWidth = MediaQuery.sizeOf(context).width - 32;
          final minWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : fallbackWidth.clamp(0, double.infinity).toDouble();
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minWidth),
              child: Table(
                border: border,
                defaultVerticalAlignment: TableCellVerticalAlignment.top,
                columnWidths: _columnWidths(rows),
                children: [
                  for (final row in rows)
                    TableRow(
                      children: [
                        for (var index = 0; index < columnCount; index += 1)
                          if (index < row.length)
                            _CampaignTableCell(
                              cell: row[index],
                              dense: dense,
                              bordered: bordered && !invisible,
                            )
                          else
                            const SizedBox.shrink(),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CampaignTableCell extends StatelessWidget {
  const _CampaignTableCell({
    required this.cell,
    required this.dense,
    required this.bordered,
  });

  final dynamic cell;
  final bool dense;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final isHeader = cell?.localName?.toString().toLowerCase() == 'th';
    return Align(
      alignment: _cellAlignment(cell),
      child: Container(
        color: bordered ? Colors.white : Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10,
          vertical: dense ? 6 : 8,
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontWeight: isHeader ? FontWeight.w800 : FontWeight.w400,
          ),
          child: CampaignRichText(
            html: cell?.innerHtml?.toString() ?? '',
            dense: true,
          ),
        ),
      ),
    );
  }
}

List<dynamic> _rowsFor(dynamic element) {
  final rows = <dynamic>[];
  void visit(dynamic node) {
    for (final child in node?.children ?? const []) {
      final name = child.localName?.toString().toLowerCase();
      if (name == 'tr') {
        rows.add(child);
      } else if (name == 'thead' || name == 'tbody' || name == 'tfoot') {
        visit(child);
      }
    }
  }

  visit(element);
  return rows;
}

List<dynamic> _cellsFor(dynamic row) {
  return [
    for (final child in row?.children ?? const [])
      if (child.localName?.toString().toLowerCase() == 'td' ||
          child.localName?.toString().toLowerCase() == 'th')
        child,
  ];
}

Map<int, TableColumnWidth> _columnWidths(List<List<dynamic>> rows) {
  final widths = <int, TableColumnWidth>{};
  for (final cells in rows) {
    for (var index = 0; index < cells.length; index += 1) {
      if (widths.containsKey(index)) continue;
      final flex = _cellWidthFlex(cells[index]);
      if (flex != null && flex > 0) widths[index] = FlexColumnWidth(flex);
    }
  }
  return widths;
}

double? _cellWidthFlex(dynamic cell) {
  final style = cell?.attributes?['style']?.toString() ?? '';
  final match =
      RegExp(r'width\s*:\s*([0-9.]+)%', caseSensitive: false).firstMatch(style);
  return double.tryParse(match?.group(1) ?? '');
}

Alignment _cellAlignment(dynamic cell) {
  final style = cell?.attributes?['style']?.toString().toLowerCase() ?? '';
  if (style.contains('vertical-align: bottom') ||
      style.contains('vertical-align:bottom')) {
    return Alignment.bottomLeft;
  }
  if (style.contains('vertical-align: middle') ||
      style.contains('vertical-align:middle')) {
    return Alignment.centerLeft;
  }
  return Alignment.topLeft;
}
