const int wordsPerMinute = 200;
const int wordsPerPage = 300;

int minutesToPages(int minutes) {
  if (minutes <= 0) return 0;
  final words = minutes * wordsPerMinute;
  return ((words) / wordsPerPage).ceil();
}

int wordsToPages(int words) {
  if (words <= 0) return 0;
  return (words / wordsPerPage).ceil();
}

int pagesFromPageRange(String range) {
  // Expect formats like "1-10" or single page "5". Returns number of pages.
  try {
    if (range.isEmpty) return 0;
    if (!range.contains('-')) return int.parse(range.trim()) > 0 ? 1 : 0;
    final parts = range.split('-');
    final a = int.tryParse(parts[0].trim()) ?? 0;
    final b = int.tryParse(parts[1].trim()) ?? 0;
    if (a <= 0 || b <= 0) return 0;
    return (b - a + 1).clamp(0, 1000000);
  } catch (_) {
    return 0;
  }
}
