import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import '../utility/constants.dart';

class ApiService {
  // Mendapatkan header standar untuk request yang butuh otentikasi
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Fungsi Login
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/login'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user', jsonEncode(data['user']));
        return {'success': true, 'message': 'Login Berhasil'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login Gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server. Periksa koneksi Anda.'};
    }
  }

  
  static Future<void> logout() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
          try {
            await http.post(
                Uri.parse('$apiBaseUrl/api/logout'),
                headers: await _getHeaders(),
            );
          } catch (e) {
            // Abaikan error jika logout gagal (misal server mati), yang penting token lokal dihapus
          }
      }
      await prefs.remove('token');
      await prefs.remove('user');
  }

  // Fungsi mendapatkan status absensi hari ini
  static Future<Map<String, dynamic>> getAbsensiStatus() async {
  try {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/api/absensi/status'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      debugPrint('Gagal ambil status absen: ${response.statusCode} - ${response.body}');
      throw Exception('Gagal mengambil status absensi: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('❌ Exception di getAbsensiStatus(): $e');
    throw Exception('Tidak dapat memuat status absensi.');
  }
}


  // --- FUNGSI BARU DITAMBAHKAN DI SINI ---
  // Fungsi untuk mendapatkan jadwal kerja saat ini
  static Future<String> getJadwalKerja() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/jadwal-kerja'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['jam_kerja'] ?? 'Jadwal tidak ditentukan';
      }
    } catch (e) {
      debugPrint('Gagal mengambil jadwal kerja: $e');
    }
    return 'Gagal memuat jadwal';
  }
  
  // Fungsi untuk Absen Masuk (Check-In)
  static Future<Map<String, dynamic>> checkIn(File image, String? location) async {
    var request = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/api/absensi/check-in'));
    request.headers.addAll(await _getHeaders());
    
    request.files.add(await http.MultipartFile.fromPath(
      'foto',
      image.path,
      contentType: MediaType('image', 'jpeg'),
    ));
    
    if (location != null) {
      request.fields['lokasi'] = location;
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }

  // Fungsi untuk Absen Pulang (Check-Out)
  static Future<Map<String, dynamic>> checkOut(File image, String? location) async {
    var request = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/api/absensi/check-out'));
    request.headers.addAll(await _getHeaders());
    
    request.files.add(await http.MultipartFile.fromPath(
      'foto',
      image.path,
      contentType: MediaType('image', 'jpeg'),
    ));
    
    if (location != null) {
      request.fields['lokasi'] = location;
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }

  // Fungsi untuk mendapatkan riwayat absensi
  static Future<List<dynamic>> getRiwayatAbsensi() async {
      final response = await http.get(
          Uri.parse('$apiBaseUrl/api/absensi/riwayat'),
          headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
          return jsonDecode(response.body)['data'];
      }
      return [];
  }
  
  // Fungsi untuk mendapatkan riwayat pengajuan
  static Future<List<dynamic>> getRiwayatPengajuan() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/pengajuan/riwayat'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'];
      }
    } catch (e) {
      debugPrint('Gagal mengambil riwayat pengajuan: $e');
    }
    return [];
  }

  // Fungsi untuk mengirim pengajuan (Izin/Cuti/dll)
  static Future<Map<String, dynamic>> submitPengajuan({
    required String tipe,
    required String tglMulai,
    required String tglSelesai,
    required String alasan,
    File? buktiFoto,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/api/pengajuan/submit'));
    request.headers.addAll(await _getHeaders());

    request.fields['tipe_pengajuan'] = tipe;
    request.fields['tanggal_mulai'] = tglMulai;
    request.fields['tanggal_selesai'] = tglSelesai;
    request.fields['alasan'] = alasan;

    if (buktiFoto != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'bukti_foto',
        buktiFoto.path,
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }

  // Fungsi untuk mendapatkan notifikasi
  static Future<List<dynamic>> getNotifikasi() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/notifikasi'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'];
      }
    } catch (e) {
      debugPrint('Gagal mengambil notifikasi: $e');
    }
    return [];
  }

  // Fungsi untuk update profil
  static Future<Map<String, dynamic>> updateProfil({
    required String noHp,
    required String alamat,
    required String tglLahir,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/api/profil/update'),
      headers: await _getHeaders()..addAll({'Content-Type': 'application/json'}),
      body: jsonEncode({
        'noHp': noHp,
        'alamat': alamat,
        'tgl_lahir': tglLahir,
      }),
    );
    return jsonDecode(response.body);
  }
}
