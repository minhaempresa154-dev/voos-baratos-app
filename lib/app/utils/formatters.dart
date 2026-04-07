String formatShortDate(DateTime date) {
  const months = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}';
}

String formatLongDate(DateTime date) {
  const months = [
    'janeiro',
    'fevereiro',
    'marco',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  return '${date.day.toString().padLeft(2, '0')} de ${months[date.month - 1]} de ${date.year}';
}

String formatHourMinute(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatDateTime(DateTime date) {
  return '${formatLongDate(date)} as ${formatHourMinute(date)}';
}

String formatCurrencyBrl(double value) {
  final normalized = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $normalized';
}

String formatDurationIso(String value) {
  final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?');
  final match = regex.firstMatch(value);
  if (match == null) return value;
  final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
  final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
  if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
  if (hours > 0) return '${hours}h';
  return '${minutes}m';
}
