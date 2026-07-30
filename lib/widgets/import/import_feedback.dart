import 'package:flutter/material.dart';
import '../../theme/plutus_tokens.dart';

/// Shared result feedback for the import tabs (spec §7).
///
/// Content ink is plain white on both the success and error `.dot` fills —
/// both are dark enough in light and dark themes for AA contrast against
/// white text. This is a blessed precedent from PR2's final review, reused
/// here rather than re-deriving a contrast-aware ink per call site.
void showResultSnackBar(BuildContext context, String message, {required bool isError}) {
  final PlutusTokens t = context.tokens;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: isError ? t.error.dot : t.success.dot,
      content: Text(message, style: const TextStyle(color: Colors.white)),
    ),
  );
}
