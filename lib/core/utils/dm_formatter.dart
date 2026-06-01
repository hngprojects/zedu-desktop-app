String parseHtmlToMarkdown(String input) {
  if (input.isEmpty) return input;

  var result = input;

  result = result.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

  result = result.replaceAll(
    RegExp(r'</?(b|strong)>', caseSensitive: false),
    '**',
  );

  result = result.replaceAll(RegExp(r'</?(i|em)>', caseSensitive: false), '*');

  result = result.replaceAll(RegExp(r'</?code>', caseSensitive: false), '`');

  result = result.replaceAllMapped(
    RegExp(r'<a\s+href="([^"]+)">([^<]*)</a>', caseSensitive: false),
    (match) => '[${match.group(2)}](${match.group(1)})',
  );

  result = result.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n');
  result = result.replaceAll(RegExp(r'<p>', caseSensitive: false), '');

  result = result.replaceAll(RegExp(r'<[^>]*>'), '');

  result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  return result.trim();
}
