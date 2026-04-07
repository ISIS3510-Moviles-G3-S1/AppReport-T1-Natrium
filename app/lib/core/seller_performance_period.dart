/// Periods used to answer the seller-performance Type 2 business question.
enum SellerPerformancePeriod { currentMonth, last15Days }

class SellerPerformanceWindow {
  final DateTime start;
  final DateTime end;

  const SellerPerformanceWindow({required this.start, required this.end});
}

extension SellerPerformancePeriodX on SellerPerformancePeriod {
  String get label {
    switch (this) {
      case SellerPerformancePeriod.currentMonth:
        return 'This month';
      case SellerPerformancePeriod.last15Days:
        return 'Last 15 days';
    }
  }

  String get shortPhrase {
    switch (this) {
      case SellerPerformancePeriod.currentMonth:
        return 'this month';
      case SellerPerformancePeriod.last15Days:
        return 'in the last 15 days';
    }
  }

  SellerPerformanceWindow get window {
    final now = DateTime.now();
    switch (this) {
      case SellerPerformancePeriod.currentMonth:
        return SellerPerformanceWindow(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case SellerPerformancePeriod.last15Days:
        return SellerPerformanceWindow(
          start: now.subtract(const Duration(days: 15)),
          end: now,
        );
    }
  }
}
