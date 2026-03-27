abstract class IConsentService {
  /// Check if the given email has accepted T&C in DynamoDB.
  /// Returns true if accepted, false if not found.
  /// Throws on network errors so callers can fall back to local.
  Future<bool> hasAcceptedTerms(String email);

  /// Record that the given email accepted T&C.
  /// Throws on network errors.
  Future<void> recordAcceptance(String email);
}
