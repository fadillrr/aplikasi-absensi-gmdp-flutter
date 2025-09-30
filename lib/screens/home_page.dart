import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/notification_panel.dart';
import 'absen_page.dart';
import 'absensi_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Logger _logger = Logger();

  int _navIndex = 0;
  bool _isLoading = true;
  UserModel? _currentUser;

  bool _sudahAbsenMasuk = false;
  bool _sudahAbsenPulang = false;

  bool _showUserInfo = false;
  bool _showNotifPage = false;
  DateTime? _lastBackPressed;
  String _currentQuote = "";

  List<Notifikasi> _notifikasi = [];
  String? _selectedKategori;
  bool _isNotifLoading = false;
  bool _hasNewNotification = false;
  Timer? _notificationTimer;

  String _jamKerjaText = "Memuat jadwal kerja...";

  final List<String> _quotes = [
    "Cara terbaik untuk memulai adalah dengan berhenti berbicara dan mulai melakukan.",
    "Kerja keras mengalahkan bakat ketika bakat tidak bekerja keras.",
    "Masa depanmu diciptakan oleh apa yang kamu lakukan hari ini, bukan besok.",
    "Kesuksesan bukanlah kunci kebahagiaan. Kebahagiaan adalah kunci kesuksesan.",
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _generateRandomQuote();
    _startNotificationTimer();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _startNotificationTimer() {
    _checkForNewNotifications();
    _notificationTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _checkForNewNotifications();
    });
  }

  Future<void> _checkForNewNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckString = prefs.getString('lastNotificationCheck');
      final notifList = await ApiService.getNotifikasi();

      if (notifList.isNotEmpty) {
        final newestNotifTime = DateTime.parse(notifList.first['waktu']);
        if (lastCheckString != null) {
          final lastCheckTime = DateTime.parse(lastCheckString);
          if (newestNotifTime.isAfter(lastCheckTime)) {
            if (mounted) setState(() => _hasNewNotification = true);
            NotificationService().showNotification(
              0,
              'Pemberitahuan Baru',
              notifList.first['pesan'],
            );
          }
        } else {
          if (mounted) setState(() => _hasNewNotification = true);
        }
      }
    } catch (e) {
      _logger.e("Gagal cek notifikasi baru: $e");
    }
  }

  Future<void> _loadInitialData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        _currentUser = UserModel.fromJson(json.decode(userString));
      }

      final results = await Future.wait([
        ApiService.getAbsensiStatus(),
        ApiService.getJadwalKerja(),
      ]);

      final absensiStatus = results[0] as Map<String, dynamic>;
      final jadwalKerja = results[1] as String;

      if (absensiStatus['status'] == 'sudah_absen') {
        final dataAbsen = absensiStatus['data'];
        setState(() {
          _sudahAbsenMasuk = dataAbsen['jam_masuk'] != null;
          _sudahAbsenPulang = dataAbsen['jam_pulang'] != null;
        });
      } else {
        setState(() {
          _sudahAbsenMasuk = false;
          _sudahAbsenPulang = false;
        });
      }

      setState(() => _jamKerjaText = jadwalKerja);
    } catch (e) {
      _logger.e('Error loading initial data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data. Periksa koneksi Anda.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _generateRandomQuote() {
    final random = Random();
    setState(() => _currentQuote = _quotes[random.nextInt(_quotes.length)]);
  }

  Future<void> _handleAbsen() async {
    if (_currentUser == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AbsenActionPage(
          type: _sudahAbsenMasuk ? AbsenType.pulang : AbsenType.masuk,
          user: _currentUser!,
        ),
      ),
    );

    if (result == true) {
      _logger.i('✅ Menerima result == true dari AbsenActionPage');
      await _loadInitialData();
    }
  }

  Widget _buildBerandaLayout() {
    String absenButtonText = "Absen Masuk";
    if (_sudahAbsenMasuk && !_sudahAbsenPulang) {
      absenButtonText = "Absen Pulang";
    } else if (_sudahAbsenMasuk && _sudahAbsenPulang) {
      absenButtonText = "Sudah Selesai Absen";
    }

    String statusAbsenText = "Anda Belum Absen";
    Color statusAbsenColor = Colors.red;
    if (_sudahAbsenMasuk) {
      statusAbsenText = _sudahAbsenPulang ? "Sudah Absen Pulang" : "Sudah Absen Masuk";
      statusAbsenColor = const Color(0xFF007ACC);
    }

    return Stack(
      children: [
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: CustomAppBar(
                  namaUser: _currentUser?.pegawaiNama ?? "Memuat...",
                  jabatanUser: _currentUser?.jabatan ?? "...",
                  showUserInfo: _showUserInfo,
                  showNotifPage: _showNotifPage,
                  hasNewNotification: _hasNewNotification,
                  onToggleUserInfo: () => setState(() => _showUserInfo = !_showUserInfo),
                  onToggleNotif: _toggleNotificationPopup,
                ),
              ),
              SizedBox(height: 60.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 18.sp, color: Colors.black87, fontFamily: 'Poppins'),
                      children: [
                        const TextSpan(text: "Hai 👋 "),
                        TextSpan(
                          text: _currentUser?.pegawaiNama ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF007ACC)),
                        ),
                        const TextSpan(text: "\nSemangat kerja ya!"),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
              constraints: BoxConstraints(minHeight: 350.h), // tambahkan ini jika mau tinggi minimum
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25.r),
                    topRight: Radius.circular(25.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Text("Status absen kamu sekarang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: Colors.black87)),
                    SizedBox(height: 4.h),
                    Text(_jamKerjaText, style: TextStyle(color: Colors.grey[600], fontSize: 14.sp)),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: (_sudahAbsenMasuk && _sudahAbsenPulang) ? null : _handleAbsen,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007ACC),
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      ),
                      child: Text(absenButtonText, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 16.h),
                    Align(
                      alignment: Alignment.center, // supaya tetap berada di tengah
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: statusAbsenColor, width: 1.5),
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                        child: Text(
                          statusAbsenText,
                          style: TextStyle(
                            color: statusAbsenColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Column(
                        children: [
                          Text("Quote Hari Ini:", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF007ACC))),
                          SizedBox(height: 8.h),
                          Text(_currentQuote, textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, fontStyle: FontStyle.italic, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        if (_showNotifPage)
          Positioned.fill(
            child: _isNotifLoading
                ? Container(color: Colors.black.withOpacity(0.4), child: const Center(child: CircularProgressIndicator(color: Colors.white)))
                : NotificationPanel(
                    data: _notifikasi,
                    onClose: _toggleNotificationPopup,
                    selectedKategori: _selectedKategori,
                    onFilterChange: (val) => setState(() => _selectedKategori = val),
                    onDismiss: (index) => setState(() => _notifikasi.removeAt(index)),
                  ),
          ),
      ],
    );
  }

  void _toggleNotificationPopup() async {
    if (!_showNotifPage) {
      await _fetchNotifikasi();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastNotificationCheck', DateTime.now().toIso8601String());
      if (mounted) setState(() => _hasNewNotification = false);
    }

    if (mounted) {
      setState(() {
        _showNotifPage = !_showNotifPage;
        if (!_showNotifPage) _selectedKategori = null;
      });
    }
  }

  Future<void> _fetchNotifikasi() async {
    if (mounted) setState(() => _isNotifLoading = true);
    try {
      final notifikasiData = await ApiService.getNotifikasi();
      if (mounted) {
        setState(() {
          _notifikasi = notifikasiData.map((e) => Notifikasi.fromJson(e)).toList();
        });
      }
    } catch (e) {
      _logger.e("Gagal fetch notifikasi: $e");
    } finally {
      if (mounted) setState(() => _isNotifLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        if (_showNotifPage) {
          _toggleNotificationPopup();
          return;
        }
        if (_navIndex != 0) {
          setState(() => _navIndex = 0);
        } else {
          DateTime now = DateTime.now();
          if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
            _lastBackPressed = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tekan sekali lagi untuk keluar'), duration: Duration(seconds: 2)),
            );
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF007ACC),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : IndexedStack(
                key: ValueKey('page-$_navIndex'),
                index: _navIndex,
                children: [
                  _buildBerandaLayout(),
                  const AbsensiPage(),
                  const ProfilePage(),
                ],
              ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _navIndex,
          selectedItemColor: const Color(0xFF007ACC),
          onTap: (index) => setState(() => _navIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Riwayat'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
