import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/edit_profile_page.dart';
import 'services/notification_service.dart'; // <-- 1. Import service notifikasi

void main() async {
  // Pastikan semua binding Flutter siap sebelum menjalankan kode async
  WidgetsFlutterBinding.ensureInitialized();
  
  // <-- 2. Inisialisasi service notifikasi saat aplikasi dimulai
  await NotificationService().init(); 
  
  // Inisialisasi format tanggal untuk bahasa Indonesia
  await initializeDateFormatting('id_ID', null);
  
  // Cek apakah ada token yang tersimpan
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  runApp(MyApp(token: token));
}

class MyApp extends StatelessWidget {
  final String? token;
  const MyApp({this.token, super.key});

  @override
  Widget build(BuildContext context) {
    // ScreenUtilInit untuk membuat UI responsif
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Aplikasi Absensi',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.white,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          // Logika utama: jika token ada, ke HomePage, jika tidak, ke LoginPage
          home: token != null ? const HomePage() : const LoginPage(),
          // Daftarkan rute lain untuk navigasi yang mudah
          routes: {
            '/login': (context) => const LoginPage(),
            '/home': (context) => const HomePage(),
            '/edit_profile': (context) => const EditProfilePage(),
          },
        );
      },
    );
  }
}
