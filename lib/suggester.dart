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
    return suggestions.first.text;
  }

  void clear() => _entries.clear();
}

class Suggestion {
  final String text;

  Suggestion(this.text);

  String _removeNumbers(String text) {
    return text.replaceAll(RegExp(r'[0-9]'), '');
  }

  String _removeLetters(String text) {
    return text.replaceAll(RegExp(r'[a-zA-Z]'), '');
  }

  Set<String> tokenize() {
    String context = text.replaceAll(' ', '').toLowerCase();
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
      for (Match match in lowered.allMatches(token)) {
        score += match.end -
            match
                .start; // Add the length of the match, to weigh single characters lower than trigrams
      }
    }
    return score;
  }
}
