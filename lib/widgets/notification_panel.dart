import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

// Model Notifikasi diperbarui dengan statusPengajuan
class Notifikasi {
  final String pesan;
  final String kategori;
  final DateTime waktu;
  final String? alasan;
  final String? statusPengajuan; // Field baru

  Notifikasi({
    required this.pesan,
    required this.kategori,
    required this.waktu,
    this.alasan,
    this.statusPengajuan, // Parameter baru
  });

  factory Notifikasi.fromJson(Map<String, dynamic> json) {
    return Notifikasi(
      pesan: json['pesan'],
      kategori: json['kategori'],
      waktu: DateTime.parse(json['waktu']),
      alasan: json['alasan'],
      statusPengajuan: json['status_pengajuan'], // Mapping dari JSON
    );
  }
}


class NotificationPanel extends StatelessWidget {
  final List<Notifikasi> data;
  final VoidCallback onClose;
  final String? selectedKategori;
  final void Function(String?) onFilterChange;
  final void Function(int) onDismiss;

  const NotificationPanel({
    super.key,
    required this.data,
    required this.onClose,
    required this.selectedKategori,
    required this.onFilterChange,
    required this.onDismiss,
  });

  // Fungsi ikon diperbarui untuk menangani status pengajuan
  Icon _getCategoryIcon(Notifikasi notif) {
    // Prioritaskan penanganan untuk pengajuan
    if (['cuti', 'izin', 'perjalanan dinas'].contains(notif.kategori)) {
      switch (notif.statusPengajuan) {
        case 'Disetujui':
          return const Icon(Icons.check_circle, color: Colors.green);
        case 'Ditolak':
          return const Icon(Icons.cancel, color: Colors.red);
        case 'Diajukan':
          return const Icon(Icons.hourglass_top, color: Colors.amber);
        default:
          return const Icon(Icons.event_note, color: Colors.grey);
      }
    }

    // Penanganan untuk kategori lain
    switch (notif.kategori) {
      case 'absen':
        return const Icon(Icons.login, color: Color(0xFF007ACC));
      default:
        return const Icon(Icons.notifications, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kategoriList = [
      {"label": "Tampilkan Semua", "value": null, "icon": Icons.list},
      {"label": "Absen", "value": "absen", "icon": Icons.login},
      {"label": "Cuti", "value": "cuti", "icon": Icons.beach_access},
      {"label": "Izin", "value": "izin", "icon": Icons.assignment_turned_in},
      {"label": "Perjalanan Dinas", "value": "perjalanan_dinas", "icon": Icons.business_center},
    ];

    final filteredData = selectedKategori == null
        ? data
        : data.where((e) => e.kategori == selectedKategori).toList();

    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(color: Colors.black.withOpacity(0.2)),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications, color: Colors.black87),
                      SizedBox(width: 8.w),
                      Text("Notifikasi Terbaru", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                      const Spacer(),
                      IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: selectedKategori,
                        isExpanded: true,
                        onChanged: onFilterChange,
                        items: kategoriList.map((item) {
                          return DropdownMenuItem<String?>(
                            value: item['value'] as String?,
                            child: Row(
                              children: [
                                Icon(item['icon'] as IconData, size: 20.sp),
                                SizedBox(width: 8.w),
                                Text(item['label'] as String),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 300.h),
                    child: filteredData.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text("Tidak ada notifikasi."),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredData.length,
                            itemBuilder: (_, index) {
                              final item = filteredData[index];
                              final formattedTime = DateFormat("dd MMM yyyy HH:mm", 'id_ID').format(item.waktu);
                              final realIndex = data.indexOf(item);

                              return Dismissible(
                                key: ValueKey(item.waktu.toIso8601String() + index.toString()),
                                onDismissed: (_) => onDismiss(realIndex),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20.w),
                                  color: Colors.red,
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: _getCategoryIcon(item), // Panggil dengan objek notifikasi
                                  title: Text(item.pesan, style: TextStyle(fontSize: 14.sp)),
                                  subtitle: Text(formattedTime, style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}