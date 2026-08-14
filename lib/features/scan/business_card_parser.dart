class BusinessCardData {
  const BusinessCardData({
    this.name = '',
    this.company = '',
    this.mobile = '',
    this.email = '',
    this.address = '',
  });

  final String name;
  final String company;
  final String mobile;
  final String email;
  final String address;
}

class BusinessCardParser {
  static BusinessCardData parse(String rawText) {
    // OCR commonly inserts spaces around @, dots and hyphens. Normalising
    // those separators substantially improves contact extraction.
    // Normalise one OCR line at a time so punctuation at a line ending (for
    // example a logo reading "S.") cannot be attached to the next line.
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map(
          (line) => line
              .trim()
              .replaceAll(RegExp(r'\s+'), ' ')
              .replaceAll(RegExp(r'(?<=\d)\s*-\s*(?=\d)'), '-'),
        )
        .where((line) => line.length > 1)
        .toList();
    final text = lines.join('\n');
    final contactText = text
        .replaceAll(RegExp(r'[ \t]*@[ \t]*'), '@')
        .replaceAll(RegExp(r'(?<=\w)[ \t]*\.[ \t]*(?=\w)'), '.');
    final emailPattern = RegExp(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}');
    // Do not use `\s` here: it also matches newlines and can accidentally join
    // two phone numbers printed on consecutive lines into one invalid number.
    final phonePattern = RegExp(r'(?:\+?\d[\d \t().-]{7,}\d)');
    final email = emailPattern.firstMatch(contactText)?.group(0) ?? '';
    final phones = phonePattern
        .allMatches(text)
        .map((match) => match.group(0)!.trim())
        .where((value) {
          final count = value.replaceAll(RegExp(r'\D'), '').length;
          return count >= 10 && count <= 13;
        })
        .toList();

    bool isContact(String line) =>
        emailPattern.hasMatch(
          line
              .replaceAll(RegExp(r'[ \t]*@[ \t]*'), '@')
              .replaceAll(RegExp(r'(?<=\w)[ \t]*\.[ \t]*(?=\w)'), '.'),
        ) ||
        phonePattern.hasMatch(line) ||
        line.toLowerCase().contains('www.') ||
        line.toLowerCase().contains('http');
    bool isCompany(String line) => RegExp(
      r'\b(pvt|private|ltd|limited|llp|inc|company|systems?|solutions|technologies|tech|digitech|enterprises|industries|services|consultancy|consultants|corp|corporation|associates|agency|studio|traders|international|infotech)\b',
      caseSensitive: false,
    ).hasMatch(line);
    bool isAddress(String line) => RegExp(
      r'\b(road|rd|street|lane|avenue|floor|building|nagar|colony|city|india|pin|pincode|district|ward|bazar|bazaar|siliguri|kolkata|west bengal|maharashtra|delhi|karnataka)\b|\b\d{6}\b',
      caseSensitive: false,
    ).hasMatch(line);
    bool isDesignation(String line) => RegExp(
      r'\b(director|manager|proprietor|owner|founder|partner|ceo|cto|cfo|coo|president|executive|engineer|consultant|sales|marketing|officer|head)\b',
      caseSensitive: false,
    ).hasMatch(line);
    String cleanPersonName(String line) => line
        .replaceAll(
          RegExp(
            r'\s*[\[(,-]+\s*(director|manager|proprietor|owner|founder|partner|ceo|cto|cfo|coo|president|executive|engineer|consultant|sales|marketing|officer|head).*$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    bool isBusinessCopy(String line) => RegExp(
      r'\b(service|advertising|outdoor|screen|hoarding|board|acrylic|flex|vinyl|printing|camera|sales|repair|desktop|laptop|printer|sector|mobile|cell|office|email|website|software|development|consultancy|house)\b',
      caseSensitive: false,
    ).hasMatch(line);

    String company = lines.firstWhere(isCompany, orElse: () => '');
    final candidates = <({String value, int score})>[];
    for (var index = 0; index < lines.length; index++) {
      final originalLine = lines[index];
      final line = cleanPersonName(originalLine);
      if (line.length < 5 ||
          line.length > 45 ||
          isContact(originalLine) ||
          isCompany(originalLine) ||
          isAddress(originalLine) ||
          (isBusinessCopy(originalLine) && !isDesignation(originalLine))) {
        continue;
      }
      if (!RegExp(r"^[A-Za-z][A-Za-z .'-]+$").hasMatch(line)) continue;
      final words = line.split(' ').where((word) => word.isNotEmpty).toList();
      var score = 20 - index;
      if (words.length >= 2 && words.length <= 4) score += 12;
      if (words.every((word) => RegExp(r'^[A-Z]').hasMatch(word))) score += 8;
      if (isDesignation(originalLine) && line != originalLine) score += 14;
      if (line == line.toUpperCase()) score -= 8;
      candidates.add((value: line, score: score));
    }
    candidates.sort((a, b) => b.score.compareTo(a.score));
    final name = candidates.isEmpty ? '' : candidates.first.value;

    if (company.isEmpty) {
      final domainMatches = RegExp(
        r'(?:www\.)?([a-z0-9-]+)\.(?:com|in|net|org)',
        caseSensitive: false,
      ).allMatches(contactText);
      for (final match in domainMatches) {
        company = _companyFromDomain(match.group(1) ?? '');
        if (company.isNotEmpty) break;
      }
    }

    final addressLines = lines.where((line) {
      if (line == name ||
          line == company ||
          isContact(line) ||
          isBusinessCopy(line)) {
        return false;
      }
      return isAddress(line) || line.contains(',');
    }).toList();

    return BusinessCardData(
      name: name,
      company: company,
      mobile: phones.isEmpty
          ? ''
          : phones.first.replaceAll(RegExp(r'\s+'), ' '),
      email: email,
      address: addressLines.toSet().join(', '),
    );
  }

  static String _companyFromDomain(String domain) {
    var value = domain.toLowerCase().replaceAll(RegExp(r'\d+$'), '');
    if (value.isEmpty ||
        const {
          'gmail',
          'yahoo',
          'outlook',
          'hotmail',
          'icloud',
        }.contains(value)) {
      return '';
    }
    for (final word in const [
      'technologies',
      'technology',
      'advertising',
      'solutions',
      'enterprises',
      'services',
      'digital',
      'private',
      'limited',
      'group',
      'india',
      'and',
    ]) {
      value = value.replaceAll(word, ' $word ');
    }
    return value
        .replaceAll(RegExp(r'[-_]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
