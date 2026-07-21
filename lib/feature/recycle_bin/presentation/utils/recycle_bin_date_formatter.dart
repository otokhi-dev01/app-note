String formatRecycleBinDate(DateTime date) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime target = DateTime(date.year, date.month, date.day);
  final int difference = today.difference(target).inDays;

  if (difference == 0) {
    return 'Today';
  }

  if (difference == 1) {
    return 'Yesterday';
  }

  if (difference > 1 && difference < 7) {
    return '${difference}d ago';
  }

  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[date.month - 1]} ${date.day}';
}
