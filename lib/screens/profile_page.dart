import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null && mounted) {
      setState(() {
        _currentUser = userModelFromJson(userString);
      });
    }
  }

  Future<void> _logout() async {
    // Panggil fungsi logout dari API service
    await ApiService.logout();
    if (!mounted) return;
    // Navigasi ke halaman login dan hapus semua halaman sebelumnya
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF007ACC),
        elevation: 0,
        centerTitle: true,
        title: Padding(
          padding: EdgeInsets.only(top: 20.h), // Tambahkan padding atas
          child: Text(
            "Akun",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
        ),
        toolbarHeight: 80.h, // Tambahkan tinggi agar padding tidak terpotong
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // Profile Header (menggunakan gaya dari kode lama)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, size: 40, color: Colors.grey),
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007ACC),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            // Menggunakan data dinamis
                            _currentUser!.pegawaiNama,
                            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // Info Detail (menggunakan gaya dari kode lama)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8.r,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Data pribadi anda", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                        SizedBox(height: 16.h),
                        // Menggunakan data dinamis
                        _buildInfoItem(Icons.badge, "Pegawai ID", _currentUser!.pegawaiId.toString()),
                        _buildInfoItem(Icons.credit_card, "Pegawai NIP", _currentUser!.pegawaiNip),
                        _buildInfoItem(Icons.work, "Jabatan", _currentUser!.jabatan),
                        _buildInfoItem(Icons.phone, "Nomor Telepon", _currentUser!.noHp ?? '-'),
                        _buildInfoItem(Icons.location_on, "Alamat", _currentUser!.alamat ?? '-'),
                        _buildInfoItem(Icons.cake, "Tanggal Lahir", _currentUser!.tglLahir ?? '-'),
                        _buildInfoItem(Icons.people, "Jenis Kelamin", _currentUser!.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan'),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // Tombol Aksi (menggunakan logika dari kode baru)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _logout, // Menggunakan fungsi logout yang benar
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: Size.fromHeight(48.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          child: Text("Log Out", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Navigasi ke halaman edit dan tunggu hasilnya
                            final result = await Navigator.pushNamed(context, '/edit_profile');
                            // Jika halaman edit mengembalikan 'true', muat ulang data
                            if (result == true) {
                              _loadUserData();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007ACC),
                            minimumSize: Size.fromHeight(48.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          child: Text("Ubah Profil", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // Menggunakan gaya _buildInfoItem dari kode lama
  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.sp, color: Colors.grey[700]),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: const Color(0xFF007ACC))),
                SizedBox(height: 2.h),
                Text(value, style: TextStyle(fontSize: 14.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}