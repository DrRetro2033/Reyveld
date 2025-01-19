import 'package:arceus/arceus.dart';

class Suggester {
  final Set<String> _entries = {};

  Suggester addEntries(List<String> entries) {
    _entries.addAll(entries);
    return this;
  }

  Suggester addEntry(String entry) {
    _entries.add(entry);
    return this;
  }

  String suggest(String query) {
    List<Suggestion> suggestions = _entries.map((e) => Suggestion(e)).toList();
    suggestions.sort((a, b) => b.calulateScore(query) - a.calulateScore(query));
    Arceus.talker.info(
        "Suggestions generated for '$query': ${suggestions.map((e) => "${e.text} (${e.calulateScore(query)})").join(", ")}");
    return suggestions.first.text;
  }

  void clear() => _entries.clear();
}

/// # `class` Suggestion
/// ## A class that represents a suggestion.
/// It contains the text of the suggestion and a method to calculate the score of the suggestion based on a query.
///
/// How scoring is calculated:
/// First, the suggestion formatted to remove characters or punctuation to make sure that those are not added to the score.
/// If we don't do this, then it could lead to false positives.
/// Then we tokenize the suggestion with tokens that represent:
/// 1. The letters used in the suggestion.
/// 2. The trigrams of the suggestion (3 consecutive characters).
/// 3. The numbers used in the suggestion.
///
/// Then we calculate the score of the suggestion based on the query.
/// The score is calculated by adding the length of the token to the score for every match of the token in the query.
class Suggestion {
  final String text;

  Suggestion(this.text);

  String _removeNumbers(String text) {
    return text.replaceAll(RegExp(r'[\d]'), '');
  }

  String _removeLetters(String text) {
    return text.replaceAll(RegExp(r'[\w]'), '');
  }

  String _format(String text) {
    return text.replaceAll(RegExp(r'[^\w\d]'), '').toLowerCase();
  }

  Set<String> tokenize() {
    String context = _format(text);
    Set<String> tokens = {};
    tokens.addAll(_getTrigrams(_removeNumbers(context)));
    tokens.addAll(_getTrigrams(_removeLetters(context)));

    tokens.addAll(_getUsedCharacters(context));

    return tokens;
  }

  Set<String> _getTrigrams(String context) {
    Set<String> tokens = {};
    while (context.isNotEmpty) {
      if (context.length < 3) {
        tokens.add(context);
        break;
      }
      tokens.add(context.substring(0, 3));
      context = context.substring(3);
    }
    return tokens;
  }

  Set<String> _getUsedCharacters(String context) {
    Set<String> tokens = {};
    for (int i = 0; i < context.length; i++) {
      tokens.add(context.substring(i, i + 1));
    }
    return tokens;
  }

  int calulateScore(String query) {
    String lowered = query.toLowerCase();
    int score = 0;
    for (String token in tokenize()) {
      for (Match match in RegExp(token).allMatches(lowered)) {
        final tokenScore = match.end - match.start;
        score += tokenScore;
      }
    }
    return score;
  }
}
