String normalizePlayerName(String value) {
  return value.trim().toLowerCase();
}

bool hasExactNormalizedPlayerNameMatch({
  required String proposedName,
  required Iterable<String> existingNames,
}) {
  final normalizedProposedName = normalizePlayerName(proposedName);

  return existingNames.any(
    (existingName) => normalizePlayerName(existingName) == normalizedProposedName,
  );
}

bool hasPartialPlayerNameMatch({
  required String query,
  required String existingName,
}) {
  final normalizedQuery = normalizePlayerName(query);
  final normalizedExistingName = normalizePlayerName(existingName);

  if (normalizedQuery.isEmpty) {
    return false;
  }

  return normalizedExistingName.contains(normalizedQuery) ||
      normalizedQuery.contains(normalizedExistingName);
}