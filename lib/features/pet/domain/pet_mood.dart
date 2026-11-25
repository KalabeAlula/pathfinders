/// What the circle companion is doing right now.
///
/// Priority (highest wins):
///   loved → celebrating → traveling → hyped → curious → hungry → sleeping → idle
///
/// [loved] is an ephemeral UI-only state triggered by Feed/Clean/Play.
/// [hyped] requires 2+ members online and a countdown within 48 h (or 3+ chat
///   messages in the last hour).
/// [curious] fires when a new memory or 5+ chat messages arrived in the last 2 h.
/// [hungry] shows when energy drops below the [petHungryThreshold].
///
/// None of these are stored on the pet — they derive from live providers so they
/// flip back without a database write.
enum PetMood {
  idle,
  traveling,
  celebrating,
  sleeping,
  hyped,
  curious,
  hungry,
  loved,
}

/// No care for this long reads as a long nap rather than a quiet moment.
const Duration petInactivityWindow = Duration(hours: 8);

/// Energy threshold below which the pet shows the hungry mood.
const double petHungryThreshold = 35;

/// Energy threshold below which the pet falls asleep.
const double petSleepingThreshold = 20;

bool isNightAt(DateTime time) => time.hour >= 22 || time.hour < 6;

/// Picks the sticker state for a circle.
///
/// Priority: loved (ephemeral, handled in provider) → celebrating → traveling →
/// hyped → curious → hungry → sleeping → idle.
///
/// Trip state wins over all contextual moods: a destination means the crew is
/// moving, and any arrival turns the mood into a celebration. Without a trip,
/// contextual signals like crew activity and countdowns add colour before
/// falling back to energy-based rest states.
PetMood derivePetMood({
  required bool hasDestination,
  required bool arrived,
  required bool everyoneArrived,
  required DateTime now,
  required double energy,
  DateTime? lastActivityAt,
  // Contextual signals for new moods.
  int onlineCount = 0,
  bool countdownSoon = false, // milestone within 48 h
  int recentChatCount = 0, // messages in last 2 h
  bool recentMemory = false, // memory posted in last 2 h
}) {
  // Trip beats everything.
  if (hasDestination) {
    return arrived || everyoneArrived ? PetMood.celebrating : PetMood.traveling;
  }

  // Contextual moods (only outside a trip).
  final hyped = onlineCount >= 2 && (countdownSoon || recentChatCount >= 3);
  if (hyped) return PetMood.hyped;

  final curious = recentMemory || recentChatCount >= 5;
  if (curious) return PetMood.curious;

  // Energy / time-based rest.
  final quietFor = lastActivityAt == null
      ? null
      : now.difference(lastActivityAt);
  final rested = quietFor != null && quietFor >= petInactivityWindow;

  // Very low energy forces sleep regardless of time.
  if (energy < petSleepingThreshold || isNightAt(now) || rested) {
    return PetMood.sleeping;
  }
  if (energy < petHungryThreshold) {
    return PetMood.hungry;
  }
  return PetMood.idle;
}
