import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final logger = Logger();

class HolidayService {
  static Future<Map<DateTime, String>> fetchNationalHolidays() async {
    final Map<DateTime, String> holidays = {};
    final int year = DateTime.now().year;
    final String url = 'https://date.nager.at/api/v3/PublicHolidays/$year/ID'; // ID = Indonesia

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        for (final item in data) {
          try {
            final dateStr = item['date']; // e.g. "2025-08-17"
            final localName = item['localName'] ?? 'Hari Libur';
            final date = DateTime.parse(dateStr);
            holidays[DateTime(date.year, date.month, date.day)] = localName;
          } catch (e) {
            logger.w('Gagal parsing item libur: $e');
          }
        }
      } else {
        logger.e('Gagal mengambil data libur dari Nager. Status: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error saat mengambil data libur: $e');
    }

    // Fallback dummy jika kosong
    if (holidays.isEmpty) {
      holidays[DateTime(2025, 6, 25)] = 'Dummy Libur Idul Adha';
      holidays[DateTime(2025, 8, 17)] = 'Dummy HUT RI';
    }

    return holidays;
  }
}
