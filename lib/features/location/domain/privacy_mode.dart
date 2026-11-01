enum PrivacyMode {
  /// Share the precise pin.
  exact,

  /// Share a softened area only; place names are withheld.
  approximate,

  /// Share nothing, while battery and presence stay visible for safety.
  paused,
}
