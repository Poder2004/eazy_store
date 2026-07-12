// Thai leading vowels (เ แ โ ใ ไ) are typed before their consonant but
// pronounced/alphabetized after it, so plain UTF-16 compareTo pushes every
// name starting with one of them (e.g. "เครื่องดื่ม") to the very end
// instead of sorting it near its consonant (ค). Swapping each leading
// vowel with the character that follows it produces a key that sorts in
// proper ก–ฮ dictionary order.
String thaiSortKey(String input) {
  const leadingVowels = {'เ', 'แ', 'โ', 'ใ', 'ไ'};
  final buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final ch = input[i];
    if (leadingVowels.contains(ch) && i + 1 < input.length) {
      buffer.write(input[i + 1]);
      buffer.write(ch);
      i++;
    } else {
      buffer.write(ch);
    }
  }
  return buffer.toString();
}
