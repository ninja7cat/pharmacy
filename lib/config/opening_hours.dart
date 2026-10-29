import 'business_config.dart';

/// When a closed pharmacy opens next.
enum NextOpening { laterToday, tomorrow, laterDay }

/// Open / closed state at one moment, in the pharmacy's own time.
class OpeningState {
  final bool isOpen;

  /// Day of the week right now (DateTime.monday ... DateTime.sunday).
  final int weekday;

  /// Only meaningful while closed.
  final NextOpening nextOpening;

  /// Only meaningful while closed: the weekday it opens again.
  final int opensOnWeekday;

  const OpeningState({
    required this.isOpen,
    required this.weekday,
    this.nextOpening = NextOpening.laterToday,
    this.opensOnWeekday = 0,
  });
}

/// The opening-hours rules from [BusinessConfig], kept free of any UI so
/// they can be tested on their own.
class OpeningHours {
  const OpeningHours._();

  /// The current date and time in the pharmacy's own time zone.
  static DateTime pharmacyNow([DateTime? now]) {
    return (now ?? DateTime.now()).toUtc().add(
      const Duration(hours: BusinessConfig.utcOffsetHours),
    );
  }

  /// Whether the pharmacy is open at [time] (already in pharmacy time),
  /// and if not, when it opens next.
  static OpeningState at(DateTime time) {
    final int minutes = time.hour * 60 + time.minute;
    final bool closedToday = BusinessConfig.closedWeekdays.contains(
      time.weekday,
    );

    if (!closedToday &&
        minutes >= BusinessConfig.openMinutes &&
        minutes < BusinessConfig.closeMinutes) {
      return OpeningState(isOpen: true, weekday: time.weekday);
    }

    if (!closedToday && minutes < BusinessConfig.openMinutes) {
      return OpeningState(
        isOpen: false,
        weekday: time.weekday,
        nextOpening: NextOpening.laterToday,
        opensOnWeekday: time.weekday,
      );
    }

    int day = time.weekday;
    int daysAhead = 0;

    do {
      day = day % 7 + 1;
      daysAhead++;
    } while (BusinessConfig.closedWeekdays.contains(day) && daysAhead < 7);

    return OpeningState(
      isOpen: false,
      weekday: time.weekday,
      nextOpening: daysAhead == 1 ? NextOpening.tomorrow : NextOpening.laterDay,
      opensOnWeekday: day,
    );
  }
}
