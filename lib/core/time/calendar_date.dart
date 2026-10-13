String calendarDateLabel(DateTime? date, {DateTime? now}) {
  if (date == null) return 'Tarih henüz açıklanmadı';
  final value = DateTime(date.year, date.month, date.day);
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final label = '${date.day}.${date.month}.${date.year}';
  return value.isBefore(today) ? '$label · Sınav yapıldı' : label;
}

// Estimates use the latest earlier edition's month; never an official day.
DateTime? estimateExamMonth(int year, Iterable<DateTime> earlierDates) {
  final dates = earlierDates.where((d) => d.year < year).toList()..sort();
  return dates.isEmpty ? null : DateTime(year, dates.last.month);
}

bool isPastExam(DateTime? officialDate, int year, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  return officialDate == null ? year < today.year : DateTime(officialDate.year, officialDate.month, officialDate.day).isBefore(today);
}

String examDateLabel(DateTime? officialDate, {DateTime? estimatedDate, int? year}) {
  if (officialDate != null) return calendarDateLabel(officialDate);
  const months = ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
  final period = estimatedDate == null ? (year == null ? 'tarih bekleniyor' : '$year') : '${months[estimatedDate.month - 1]} ${estimatedDate.year}';
  return 'Yaklaşık $period · Resmî tarih açıklanmadı';
}
