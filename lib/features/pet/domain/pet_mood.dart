/// What the circle companion is doing right now.
///
/// Never stored on the pet: it follows the trip and the time of day, so it
/// can flip back to [idle] without a write.
enum PetMood { idle, traveling, celebrating, sleeping }

/// No care for this long reads as a long nap rather than a quiet moment.
const Duration petInactivityWindow = Duration(hours: 8);

bool isNightAt(DateTime time) => time.hour >= 22 || time.hour < 6;

/// Picks the sticker state for a circle.
///
/// Trip state wins over rest: a destination means the crew is moving, and any
/// arrival turns the mood into a celebration. Without a trip, late hours, an
/// exhausted companion, or a long quiet stretch put it to sleep.
PetMood derivePetMood({
  required bool hasDestination,
  required bool arrived,
  required bool everyoneArrived,
  required DateTime now,
  required double energy,
  DateTime? lastActivityAt,
}) {
  if (hasDestination) {
    return arrived || everyoneArrived
        ? PetMood.celebrating
        : PetMood.traveling;
  }
  final quietFor = lastActivityAt == null
      ? null
      : now.difference(lastActivityAt);
  final rested = quietFor != null && quietFor >= petInactivityWindow;
  if (isNightAt(now) || energy < 25 || rested) return PetMood.sleeping;
  return PetMood.idle;
}
