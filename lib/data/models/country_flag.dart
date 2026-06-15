import 'package:flutter/foundation.dart';

/// Maps country names / ISO codes to flag emojis.
/// Covers the most common countries used in VPN subscriptions.
const Map<String, String> _countryFlagMap = {
  // Direct country name matches (english)
  'germany': '🇩🇪', 'deutschland': '🇩🇪', 'de': '🇩🇪',
  'netherlands': '🇳🇱', 'nl': '🇳🇱',
  'france': '🇫🇷', 'fr': '🇫🇷',
  'united kingdom': '🇬🇧',
  'uk': '🇬🇧',
  'gb': '🇬🇧',
  'britain': '🇬🇧',
  'great britain': '🇬🇧',
  'united states': '🇺🇸',
  'usa': '🇺🇸',
  'us': '🇺🇸',
  'united states of america': '🇺🇸',
  'canada': '🇨🇦', 'ca': '🇨🇦',
  'japan': '🇯🇵', 'jp': '🇯🇵',
  'south korea': '🇰🇷', 'korea': '🇰🇷', 'kr': '🇰🇷',
  'singapore': '🇸🇬', 'sg': '🇸🇬',
  'australia': '🇦🇺', 'au': '🇦🇺',
  'switzerland': '🇨🇭', 'ch': '🇨🇭',
  'sweden': '🇸🇪', 'se': '🇸🇪',
  'norway': '🇳🇴', 'no': '🇳🇴',
  'denmark': '🇩🇰', 'dk': '🇩🇰',
  'finland': '🇫🇮', 'fi': '🇫🇮',
  'poland': '🇵🇱', 'pl': '🇵🇱',
  'italy': '🇮🇹', 'it': '🇮🇹',
  'spain': '🇪🇸', 'es': '🇪🇸',
  'portugal': '🇵🇹', 'pt': '🇵🇹',
  'austria': '🇦🇹', 'at': '🇦🇹',
  'belgium': '🇧🇪', 'be': '🇧🇪',
  'czech': '🇨🇿', 'czech republic': '🇨🇿', 'cz': '🇨🇿',
  'romania': '🇷🇴', 'ro': '🇷🇴',
  'hungary': '🇭🇺', 'hu': '🇭🇺',
  'ukraine': '🇺🇦', 'ua': '🇺🇦',
  'turkey': '🇹🇷', 'tr': '🇹🇷', 'turkiye': '🇹🇷',
  'india': '🇮🇳', 'in': '🇮🇳',
  'brazil': '🇧🇷', 'br': '🇧🇷',
  'mexico': '🇲🇽', 'mx': '🇲🇽',
  'argentina': '🇦🇷', 'ar': '🇦🇷',
  'hong kong': '🇭🇰', 'hk': '🇭🇰',
  'taiwan': '🇹🇼', 'tw': '🇹🇼',
  'israel': '🇮🇱', 'il': '🇮🇱',
  'bulgaria': '🇧🇬', 'bg': '🇧🇬',
  'russia': '🇷🇺', 'ru': '🇷🇺',
  'istanbul': '🇹🇷', 'berlin': '🇩🇪', 'frankfurt': '🇩🇪',
  'paris': '🇫🇷', 'london': '🇬🇧', 'amsterdam': '🇳🇱',
  'zurich': '🇨🇭', 'stockholm': '🇸🇪', 'oslo': '🇳🇴',
  'tokyo': '🇯🇵', 'seoul': '🇰🇷', 'sydney': '🇦🇺',
  'moscow': '🇷🇺', 'dubai': '🇦🇪', 'mumbai': '🇮🇳',
  'new york': '🇺🇸', 'los angeles': '🇺🇸', 'chicago': '🇺🇸',
  'san francisco': '🇺🇸', 'miami': '🇺🇸', 'dallas': '🇺🇸',
  'atlanta': '🇺🇸', 'seattle': '🇺🇸', 'denver': '🇺🇸',
  'brussels': '🇧🇪', 'vienna': '🇦🇹', 'prague': '🇨🇿',
  'bucharest': '🇷🇴', 'warsaw': '🇵🇱', 'lisbon': '🇵🇹',
  'madrid': '🇪🇸', 'milan': '🇮🇹', 'rome': '🇮🇹',
  // Russian city/country names commonly used in VPN subs
  'германия': '🇩🇪', 'нидерланды': '🇳🇱', 'франция': '🇫🇷',
  'соединенное королевство': '🇬🇧', 'великобритания': '🇬🇧',
  'сша': '🇺🇸', 'соединенные штаты': '🇺🇸', 'америка': '🇺🇸',
  'канада': '🇨🇦', 'япония': '🇯🇵', 'южная корея': '🇰🇷',
  'сингапур': '🇸🇬', 'австралия': '🇦🇺', 'швейцария': '🇨🇭',
  'швеция': '🇸🇪', 'норвегия': '🇳🇴', 'дания': '🇩🇰',
  'финляндия': '🇫🇮', 'польша': '🇵🇱', 'италия': '🇮🇹',
  'испания': '🇪🇸', 'португалия': '🇵🇹', 'австрия': '🇦🇹',
  'бельгия': '🇧🇪', 'чехия': '🇨🇿', 'румыния': '🇷🇴',
  'венгрия': '🇭🇺', 'украина': '🇺🇦', 'турция': '🇹🇷',
  'индия': '🇮🇳', 'бразилия': '🇧🇷', 'мексика': '🇲🇽',
  'аргентина': '🇦🇷', 'гонконг': '🇭🇰', 'тайвань': '🇹🇼',
  'израиль': '🇮🇱', 'болгария': '🇧🇬', 'россия': '🇷🇺',
  'оаэ': '🇦🇪', 'дубай': '🇦🇪',
  'франкфурт': '🇩🇪', 'берлин': '🇩🇪', 'мюнхен': '🇩🇪',
  'амстердам': '🇳🇱', 'париж': '🇫🇷', 'лондон': '🇬🇧',
  'цюрих': '🇨🇭', 'стокгольм': '🇸🇪', 'осло': '🇳🇴',
  'токио': '🇯🇵', 'сеул': '🇰🇷', 'сидней': '🇦🇺',
  'москва': '🇷🇺', 'санкт-петербург': '🇷🇺', 'спб': '🇷🇺',
};

/// Unicode ranges for regional indicator symbols (flag emojis).
/// Each flag emoji is made of two regional indicator letters.
/// Regional Indicator A = 0x1F1E6, Regional Indicator Z = 0x1F1FF.
const int _regionalIndicatorA = 0x1F1E6;
const int _regionalIndicatorZ = 0x1F1FF;

class CountryFlagUtil {
  /// Try to extract a flag emoji from a server name.
  ///
  /// Strategy:
  /// 1. Check if the name already starts with a flag emoji (two regional indicators).
  /// 2. Look up country/city name (english or russian) in the map.
  /// 3. Fallback: return null.
  static String? extractFlag(String name) {
    if (name.isEmpty) return null;

    final trimmed = name.trim();

    // 1. Check if name starts with a flag emoji (regional indicator pair)
    final flagFromEmoji = _extractLeadingFlagEmoji(trimmed);
    if (flagFromEmoji != null) return flagFromEmoji;

    // 2. Look up by country/city name in the map
    final lower = trimmed.toLowerCase();
    // Try full match first
    if (_countryFlagMap.containsKey(lower)) {
      return _countryFlagMap[lower]!;
    }
    // Try partial match — check if any key is contained in the name
    for (final entry in _countryFlagMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    // 3. Try to extract country from common patterns like "DE-..." or "...-DE"
    final codeMatch = RegExp(r'\b([a-zA-Z]{2})\b').firstMatch(lower);
    if (codeMatch != null) {
      final code = codeMatch.group(1)!;
      if (_countryFlagMap.containsKey(code)) {
        return _countryFlagMap[code]!;
      }
    }

    return null;
  }

  /// Returns the server name with the leading flag emoji removed.
  static String stripFlag(String name) {
    if (name.isEmpty) return name;
    final runes = name.runes.toList();
    if (runes.length >= 2) {
      final first = runes[0];
      final second = runes[1];
      if (_isRegionalIndicator(first) && _isRegionalIndicator(second)) {
        return String.fromCharCodes(runes.sublist(2)).trimLeft();
      }
    }
    return name;
  }

  static bool _isRegionalIndicator(int codePoint) {
    return codePoint >= _regionalIndicatorA && codePoint <= _regionalIndicatorZ;
  }

  static String? _extractLeadingFlagEmoji(String name) {
    final runes = name.runes.toList();
    if (runes.length < 2) return null;
    final first = runes[0];
    final second = runes[1];
    if (_isRegionalIndicator(first) && _isRegionalIndicator(second)) {
      return String.fromCharCodes(runes.sublist(0, 2));
    }
    return null;
  }
}
