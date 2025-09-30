// import 'package:flutter/material.dart'; // Keep for context, though not directly used in the service class itself
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:googleapis_auth/auth_io.dart';
// import 'package:googleapis/calendar/v3.dart' as calendar;
// import 'package:http/http.dart' as http;
// import 'package:logger/logger.dart'; // Import the logger package

// class GoogleCalendarService {
//   // Inisialisasi Logger
//   final Logger _logger = Logger(
//     printer: PrettyPrinter(
//       methodCount: 0, // number of method calls to be displayed
//       errorMethodCount: 5, // number of method calls if stacktrace is provided
//       lineLength: 120, // width of the output
//       colors: true, // Colorful log messages
//       printEmojis: true, // Print an emoji for each log message
//       printTime: false, // Should each log message contain a timestamp
//     ),
//   );

//   final GoogleSignIn _googleSignIn = GoogleSignIn(
//     scopes: <String>[
//       calendar.CalendarApi.calendarScope, // Akses baca/tulis penuh ke kalender
//     ],
//   );

//   AuthedClient? _client;

//   // Mendapatkan kredensial dari Google Sign-In
//   Future<void> signInWithGoogle() async {
//     try {
//       GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently(suppressErrors: false);
//       if (googleUser == null) {
//         googleUser = await _googleSignIn.signIn();
//       }

//       if (googleUser != null) {
//         final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

//         final AccessCredentials credentials = AccessCredentials(
//           AccessToken(
//             'Bearer',
//             googleAuth.accessToken!,
//             _googleSignIn.expirationTime ?? DateTime.now().add(const Duration(hours: 1)).toUtc(),
//           ),
//           googleAuth.idToken,
//           _googleSignIn.scopes,
//         );

//         _client = AuthedClient(credentials, http.Client());
//         _logger.i('Google Sign-In Berhasil! User: ${googleUser.displayName}, Email: ${googleUser.email}');
//       } else {
//         _logger.w('Pengguna tidak login.');
//       }
//     } catch (error, stackTrace) {
//       _logger.e('Error Google Sign-In: $error', error: error, stackTrace: stackTrace);
//     }
//   }

//   calendar.CalendarApi? get calendarApi {
//     if (_client != null) {
//       return calendar.CalendarApi(_client!);
//     }
//     return null;
//   }

//   Future<void> signOutGoogle() async {
//     await _googleSignIn.signOut();
//     _client = null;
//     _logger.i('Google Sign-Out Berhasil.');
//   }

//   bool get isSignedIn => _googleSignIn.currentUser != null;

//   GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

//   // 1. Mendapatkan Daftar Kalender Pengguna
//   Future<List<calendar.CalendarListEntry>?> getCalendarList() async {
//     if (calendarApi == null) {
//       _logger.w('Belum terautentikasi untuk mengambil daftar kalender.');
//       return null;
//     }
//     try {
//       final calendarList = await calendarApi!.calendarList.list();
//       _logger.d('Berhasil mengambil ${calendarList.items?.length ?? 0} daftar kalender.');
//       return calendarList.items;
//     } catch (e, stackTrace) {
//       _logger.e('Error saat mengambil daftar kalender: $e', error: e, stackTrace: stackTrace);
//       return null;
//     }
//   }

//   // 2. Membuat Acara Baru di Kalender Primer
//   Future<calendar.Event?> createEvent({
//     required String summary,
//     String? description,
//     required DateTime start,
//     required DateTime end,
//     String calendarId = 'primary',
//   }) async {
//     if (calendarApi == null) {
//       _logger.w('Belum terautentikasi untuk membuat acara.');
//       return null;
//     }

//     final event = calendar.Event(
//       summary: summary,
//       description: description,
//       start: calendar.EventDateTime(dateTime: start.toUtc()),
//       end: calendar.EventDateTime(dateTime: end.toUtc()),
//       reminders: calendar.EventReminders(
//         useDefault: false,
//         overrides: [
//           calendar.EventReminder(method: 'email', minutes: 30),
//           calendar.EventReminder(method: 'popup', minutes: 10),
//         ],
//       ),
//     );

//     try {
//       final createdEvent = await calendarApi!.events.insert(event, calendarId);
//       _logger.i('Acara "${createdEvent.summary}" berhasil dibuat: ${createdEvent.htmlLink}');
//       return createdEvent;
//     } catch (e, stackTrace) {
//       _logger.e('Error saat membuat acara "$summary": $e', error: e, stackTrace: stackTrace);
//       return null;
//     }
//   }

//   // 3. Mendapatkan Daftar Acara dari Kalender Tertentu
//   Future<List<calendar.Event>?> getEvents({
//     String calendarId = 'primary',
//     DateTime? timeMin,
//     DateTime? timeMax,
//     int maxResults = 2500,
//     bool singleEvents = true,
//     String orderBy = 'startTime',
//   }) async {
//     if (calendarApi == null) {
//       _logger.w('Belum terautentikasi untuk mengambil acara.');
//       return null;
//     }
//     try {
//       final events = await calendarApi!.events.list(
//         calendarId,
//         timeMin: (timeMin ?? DateTime.now().subtract(const Duration(days: 30))).toUtc(),
//         timeMax: (timeMax ?? DateTime.now().add(const Duration(days: 365))).toUtc(),
//         maxResults: maxResults,
//         singleEvents: singleEvents,
//         orderBy: orderBy,
//       );
//       _logger.d('Berhasil mengambil ${events.items?.length ?? 0} acara dari kalender $calendarId.');
//       return events.items;
//     } catch (e, stackTrace) {
//       _logger.e('Error saat mengambil acara dari kalender $calendarId: $e', error: e, stackTrace: stackTrace);
//       return null;
//     }
//   }

//   // 4. Update Event (Contoh Sederhana: Mengubah Deskripsi)
//   Future<calendar.Event?> updateEvent({
//     required String calendarId,
//     required String eventId,
//     String? newSummary,
//     String? newDescription,
//     DateTime? newStart,
//     DateTime? newEnd,
//   }) async {
//     if (calendarApi == null) {
//       _logger.w('Belum terautentikasi untuk memperbarui acara.');
//       return null;
//     }
//     try {
//       final existingEvent = await calendarApi!.events.get(calendarId, eventId);
//       if (existingEvent == null) {
//         _logger.w('Acara dengan ID $eventId tidak ditemukan di kalender $calendarId.');
//         return null;
//       }

//       if (newSummary != null) existingEvent.summary = newSummary;
//       if (newDescription != null) existingEvent.description = newDescription;
//       if (newStart != null) existingEvent.start = calendar.EventDateTime(dateTime: newStart.toUtc());
//       if (newEnd != null) existingEvent.end = calendar.EventDateTime(dateTime: newEnd.toUtc());

//       final updatedEvent = await calendarApi!.events.update(
//         existingEvent,
//         calendarId,
//         eventId,
//       );
//       _logger.i('Acara "${updatedEvent.summary}" (ID: $eventId) berhasil diperbarui: ${updatedEvent.htmlLink}');
//       return updatedEvent;
//     } catch (e, stackTrace) {
//       _logger.e('Error saat memperbarui acara (ID: $eventId) di kalender $calendarId: $e', error: e, stackTrace: stackTrace);
//       return null;
//     }
//   }

//   // 5. Menghapus Acara
//   Future<void> deleteEvent({
//     required String calendarId,
//     required String eventId,
//   }) async {
//     if (calendarApi == null) {
//       _logger.w('Belum terautentikasi untuk menghapus acara.');
//       return;
//     }
//     try {
//       await calendarApi!.events.delete(calendarId, eventId);
//       _logger.i('Acara dengan ID $eventId berhasil dihapus dari kalender $calendarId.');
//     } catch (e, stackTrace) {
//       _logger.e('Error saat menghapus acara (ID: $eventId) dari kalender $calendarId: $e', error: e, stackTrace: stackTrace);
//     }
//   }
// }