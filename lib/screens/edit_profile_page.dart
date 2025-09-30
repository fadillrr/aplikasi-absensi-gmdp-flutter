import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _birthDateController = TextEditingController();
  
  bool _isLoading = false;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // Fungsi untuk memuat data user dari penyimpanan lokal
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      _user = userModelFromJson(userString);
      // Menggunakan nama properti yang benar: noHp dan tglLahir
      _phoneController.text = _user?.noHp ?? '';
      _addressController.text = _user?.alamat ?? '';
      _birthDateController.text = _user?.tglLahir ?? '';
      setState(() {});
    }
  }

  // Fungsi untuk menyimpan profil yang sudah diubah
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    // Memanggil ApiService dengan parameter yang benar
    final result = await ApiService.updateProfil(
      noHp: _phoneController.text,
      alamat: _addressController.text,
      tglLahir: _birthDateController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['status'] == 'success') {
      // Update data user yang baru di SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(result['user']));
      
      // --- PERBAIKAN: Tambahkan pengecekan 'mounted' setelah operasi async ---
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil berhasil diperbarui"), backgroundColor: Colors.green),
      );
      // Kirim 'true' saat kembali untuk memberitahu halaman profil agar memuat ulang data
      Navigator.pop(context, true);
    } else {
      // Tidak ada operasi async di sini, tapi tetap aman untuk menambahkan pengecekan
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Gagal memperbarui profil"), backgroundColor: Colors.red),
      );
    }
  }

  // Fungsi untuk menampilkan date picker
  Future<void> _selectDate() async {
    DateTime initialDate;
    try {
      initialDate = _birthDateController.text.isNotEmpty 
        ? DateFormat('yyyy-MM-dd').parse(_birthDateController.text) 
        : DateTime.now();
    } catch(e) {
      initialDate = DateTime.now();
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ubah Profil"),
        backgroundColor: const Color(0xFF007ACC),
        foregroundColor: Colors.white,
      ),
      body: _user == null 
        ? const Center(child: CircularProgressIndicator())
        : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              _buildInputField(
                controller: _phoneController,
                label: "Nomor Telepon",
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16.h),
              _buildInputField(
                controller: _addressController,
                label: "Alamat",
                icon: Icons.location_on,
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _birthDateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: InputDecoration(
                  labelText: 'Tanggal Lahir',
                  prefixIcon: const Icon(Icons.cake),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
              SizedBox(height: 32.h),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007ACC),
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 48.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: const Text("Simpan Perubahan"),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }
}