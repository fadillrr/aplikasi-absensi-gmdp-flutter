import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

enum AbsenType { masuk, pulang }
enum AbsenState { checkingLocation, capturing, previewing, sending, success, error }

class AbsenActionPage extends StatefulWidget {
  final AbsenType type;
  final UserModel user;

  const AbsenActionPage({required this.type, required this.user, super.key});

  @override
  State<AbsenActionPage> createState() => _AbsenActionPageState();
}

class _AbsenActionPageState extends State<AbsenActionPage> {
  AbsenState _currentState = AbsenState.checkingLocation;
  String _statusMessage = 'Mempersiapkan...';
  XFile? _processedImageFile;

  String? _alamatLengkap;
  double? _lat;
  double? _lon;

  static const double maxDistanceMeters = 150.0;

  @override
  void initState() {
    super.initState();
    _startLocationAndCameraProcess();
  }

  Future<void> _startLocationAndCameraProcess() async {
    setState(() {
      _currentState = AbsenState.checkingLocation;
      _statusMessage = 'Mengecek lokasi...';
    });

    try {
      // 🔹 Cek izin lokasi
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak. Silakan aktifkan di pengaturan.');
      }

      // 🔹 Ambil posisi
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _lat = pos.latitude;
      _lon = pos.longitude;

      // 🔹 Ambil alamat lengkap
      String address = "Alamat tidak tersedia";
      try {
        final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          address = [
            p.street,
            p.subLocality,
            p.locality,
            p.subAdministrativeArea,
            p.administrativeArea,
            p.postalCode,
            p.country,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        }
      } catch (e) {
        debugPrint("Geocoding gagal: $e");
      }

      _alamatLengkap = address;

      // 🔹 Validasi lokasi kantor
      if (widget.user.geolocatorActive) {
        if (widget.user.kantor == null) {
          throw Exception('Lokasi kantor Anda tidak terdaftar.');
        }

        final officeLat = double.parse(widget.user.kantor!.latitude);
        final officeLon = double.parse(widget.user.kantor!.longitude);
        final distance = _calculateDistance(pos.latitude, pos.longitude, officeLat, officeLon);

        if (distance > maxDistanceMeters) {
          throw Exception(
            'Anda berada di luar area kantor! Jarak ${distance.round()} m.',
          );
        }
      }

      // 🔹 Buka kamera
      setState(() => _statusMessage = 'Lokasi valid, buka kamera...');
      final cams = await availableCameras();
      final frontCamera = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );

      if (!mounted) return;
      final capturedImage = await Navigator.push<XFile?>(
        context,
        MaterialPageRoute(builder: (_) => CameraCapturePage(camera: frontCamera)),
      );

      if (capturedImage == null) {
        if (mounted) Navigator.pop(context, false);
        return;
      }

      _processImageWithWatermark(capturedImage);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = e.toString().replaceAll('Exception: ', '');
        _currentState = AbsenState.error;
      });
    }
  }

Future<void> _processImageWithWatermark(XFile originalImage) async {
  setState(() {
    _currentState = AbsenState.capturing;
    _statusMessage = 'Memproses gambar...';
  });

  try {
    final bytes = await originalImage.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image != null) {
      image = img.bakeOrientation(image);
final flippedImage = image; // mirror kamera depan

      final timestamp = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now());

      // 🔹 pecah alamat per koma biar tidak kepanjangan 1 baris
      final alamatLines = (_alamatLengkap ?? "Alamat tidak tersedia")
          .split(", ")
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final List<String> watermarkLines = [
        "Waktu: $timestamp",
        "Lokasi: ${alamatLines.isNotEmpty ? alamatLines.first : ''}",
        ...alamatLines.skip(1).map((e) => "        $e"), // indentasi biar rapi
        if (_lat != null && _lon != null)
          "Lat: ${_lat!.toStringAsFixed(5)}, Long: ${_lon!.toStringAsFixed(5)}",
      ];

      final font = img.arial_24;
      const int lineHeight = 28;
      const int padding = 10;
      const int margin = 20;

      final boxHeight = watermarkLines.length * lineHeight + padding * 2;
      final boxWidth = flippedImage.width - (margin * 2);

      final boxLeft = flippedImage.width - boxWidth - margin;
      final boxTop = flippedImage.height - boxHeight - margin;

      // 🔹 Background transparan hitam
      img.fillRect(
        flippedImage,
        boxLeft,
        boxTop,
        boxLeft + boxWidth,
        boxTop + boxHeight,
        img.getColor(0, 0, 0, 120),
      );

      // 🔹 Tulis watermark
      for (int i = 0; i < watermarkLines.length; i++) {
        img.drawString(
          flippedImage,
          font,
          boxLeft + padding,
          boxTop + padding + (i * lineHeight),
          watermarkLines[i],
        );
      }

      // 🔹 Simpan hasil
      final tempDir = await getTemporaryDirectory();
      final newPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newFile = File(newPath);
      await newFile.writeAsBytes(img.encodeJpg(flippedImage));

      setState(() {
        _processedImageFile = XFile(newPath);
        _currentState = AbsenState.previewing;
      });
    } else {
      throw Exception("Gagal memproses gambar.");
    }
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _statusMessage = "Error: ${e.toString()}";
      _currentState = AbsenState.error;
    });
  }
}

  Future<void> _sendAbsen() async {
    if (_processedImageFile == null) return;

    setState(() {
      _currentState = AbsenState.sending;
      _statusMessage = 'Mengirim data absen...';
    });

    try {
      final locationStr =
          "Alamat: $_alamatLengkap | Lat: ${_lat?.toStringAsFixed(6)}, Lon: ${_lon?.toStringAsFixed(6)}";

      final absenResult = widget.type == AbsenType.masuk
          ? await ApiService.checkIn(File(_processedImageFile!.path), locationStr)
          : await ApiService.checkOut(File(_processedImageFile!.path), locationStr);

      if (absenResult['status'] == 'success') {
        final successMessage =
            widget.type == AbsenType.masuk ? 'Absen masuk berhasil!' : 'Absen pulang berhasil!';
        setState(() {
          _statusMessage = successMessage;
          _currentState = AbsenState.success;
        });

        if (widget.type == AbsenType.pulang) {
          NotificationService().showNotification(
            2, 'Absen Pulang Berhasil', 'Terima kasih, selamat beristirahat!',
          );
        }

        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        throw Exception(absenResult['message'] ?? 'Gagal mengirim data absen.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = e.toString().replaceAll('Exception: ', '');
        _currentState = AbsenState.error;
      });
    }
  }

  void _openFullPreview() {
    if (_processedImageFile == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Preview Gambar Watermark")),
          body: Center(child: Image.file(File(_processedImageFile!.path))),
        ),
      ),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000;
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  @override
  Widget build(BuildContext context) {
    final jenis = widget.type == AbsenType.masuk ? 'Absen Masuk' : 'Absen Pulang';
    return Scaffold(
      appBar: AppBar(title: Text(jenis)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_currentState == AbsenState.checkingLocation ||
                  _currentState == AbsenState.capturing ||
                  _currentState == AbsenState.sending)
                const CircularProgressIndicator()
              else if (_currentState == AbsenState.previewing && _processedImageFile != null)
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(_processedImageFile!.path),
                          height: 300, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _openFullPreview,
                      icon: const Icon(Icons.fullscreen),
                      label: const Text("Lihat Penuh"),
                    ),
                  ],
                )
              else if (_currentState == AbsenState.success)
                const Icon(Icons.check_circle_outline,
                    color: Colors.green, size: 64)
              else if (_currentState == AbsenState.error)
                const Icon(Icons.error_outline,
                    color: Colors.red, size: 64),
              const SizedBox(height: 24),
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 18,
                  color: _currentState == AbsenState.error ? Colors.red : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_currentState == AbsenState.previewing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _startLocationAndCameraProcess,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Ulangi'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    ),
                    ElevatedButton.icon(
                      onPressed: _sendAbsen,
                      icon: const Icon(Icons.send),
                      label: const Text('Kirim'),
                    ),
                  ],
                )
              else if (_currentState == AbsenState.error)
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// CAMERA PREVIEW PAGE
// ============================================
class CameraCapturePage extends StatefulWidget {
  final CameraDescription camera;

  const CameraCapturePage({required this.camera, super.key});

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  late CameraController _controller;
  late Future<void> _initFuture;
  bool _isProcessing = false;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high, enableAudio: false);
    _initFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _initFuture;
      final image = await _controller.takePicture();
      setState(() {
        _capturedImage = image;
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint("Gagal ambil gambar: $e");
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  void _confirmAndReturnImage() {
    if (_capturedImage != null) {
      Navigator.of(context).pop(_capturedImage);
    }
  }

  void _previewImageFullScreen() {
    if (_capturedImage == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Preview Gambar')),
          body: Center(child: Image.file(File(_capturedImage!.path))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ambil Foto Selfie')),
      body: Stack(
        children: [
          if (_capturedImage == null)
            FutureBuilder(
            future: _initFuture,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.done) {
                  return Center(
                    child: CameraPreview(_controller), // ✅ tanpa rotasi, tanpa mirror
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            )
          else
            GestureDetector(
              onTap: _previewImageFullScreen,
              child: Center(
                child: Image.file(File(_capturedImage!.path), fit: BoxFit.contain),
              ),
            ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _capturedImage == null
          ? FloatingActionButton(
              onPressed: _takePicture,
              child: const Icon(Icons.camera_alt),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.replay),
                  label: const Text("Ulangi"),
                  onPressed: () => setState(() => _capturedImage = null),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text("Gunakan"),
                  onPressed: _confirmAndReturnImage,
                ),
              ],
            ),
    );
  }
}
