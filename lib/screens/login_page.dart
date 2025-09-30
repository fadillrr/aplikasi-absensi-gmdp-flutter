import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/api_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Listener untuk menghapus pesan error saat user mulai mengetik lagi
    _usernameController.addListener(() {
      if (_errorMessage.isNotEmpty) setState(() => _errorMessage = '');
    });
    _passwordController.addListener(() {
      if (_errorMessage.isNotEmpty) setState(() => _errorMessage = '');
    });
  }

  // Menggabungkan logika login dari kode baru ke dalam struktur lama
  Future<void> _handleLogin() async {
    // Validasi sederhana
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'ID Pegawai dan NIP tidak boleh kosong!');
      return;
    }

    setState(() => _isLoading = true);

    // Panggil fungsi login dari ApiService
    final result = await ApiService.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success']) {
      // Jika berhasil, navigasi ke HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      // Jika gagal, tampilkan pesan error dari API
      setState(() {
        _errorMessage = result['message'];
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    // Tentukan tinggi bagian atas secara dinamis
    final double topSectionHeight = keyboardHeight > 0 ? 50.h : 350.h;

    return Scaffold(
      backgroundColor: const Color(0xFF3072D7),
      body: Column(
        children: [
          // Bagian atas dengan animasi
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            width: double.infinity,
            height: topSectionHeight,
            color: const Color(0xFF3072D7),
            alignment: Alignment.bottomCenter,
            child: keyboardHeight == 0
                ? Image.asset(
                    'assets/images/baruuu copy.png', // Pastikan path aset ini benar
                    height: 300.h,
                    width: 400.w,
                    fit: BoxFit.contain,
                  )
                : const SizedBox.shrink(),
          ),
          // Bagian form login
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.r),
                  topRight: Radius.circular(30.r),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3072D7),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    
                    Text('ID Pegawai', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.black54)),
                    SizedBox(height: 6.h),
                    TextField(
                      controller: _usernameController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Masukkan ID Pegawai Anda',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    Text('NIP (Password)', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.black54)),
                    SizedBox(height: 6.h),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Masukkan NIP Anda',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    
                    // Menampilkan pesan error jika ada
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text(_errorMessage, style: TextStyle(color: Colors.red, fontSize: 14.sp)),
                      ),
                      
                    SizedBox(height: 20.h),
                    
                    // Tombol Login dengan indikator loading
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3072D7),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              ),
                              child: Text('LOGIN', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}