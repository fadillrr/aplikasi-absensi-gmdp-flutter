import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';
import '../services/holidays_id.dart';

class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  Map<DateTime, String> _holidayMap = {};
  bool _isLoading = true;

  // State untuk dialog pengajuan
  final TextEditingController _reasonController = TextEditingController();
  String _requestType = 'Izin';
  XFile? _proofImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchData();
  }
  
  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (_events.isEmpty) {
      if (mounted) setState(() => _isLoading = true);
    }
    
    try {
      final results = await Future.wait([
        ApiService.getRiwayatAbsensi(),
        ApiService.getRiwayatPengajuan(),
        HolidayService.fetchNationalHolidays(),
      ]);

      final riwayatAbsensi = results[0] as List<dynamic>;
      final riwayatPengajuan = results[1] as List<dynamic>;
      final holidays = results[2] as Map<DateTime, String>;

      Map<DateTime, List<dynamic>> events = {};
      
      for (var item in riwayatAbsensi) {
        final date = DateTime.parse(item['tanggal_absen']).toLocal();
        final normalizedDate = DateTime.utc(date.year, date.month, date.day);
        if (events[normalizedDate] == null) events[normalizedDate] = [];
        events[normalizedDate]!.add({...item, 'type': 'absensi'});
      }

      for (var item in riwayatPengajuan) {
        final startDate = DateTime.parse(item['tanggal_mulai']).toLocal();
        final endDate = DateTime.parse(item['tanggal_selesai']).toLocal();
        for (var day = startDate; day.isBefore(endDate.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
          final normalizedDate = DateTime.utc(day.year, day.month, day.day);
          if (events[normalizedDate] == null) events[normalizedDate] = [];
          events[normalizedDate]!.add({...item, 'type': 'pengajuan'});
        }
      }
      
      if (mounted) {
        setState(() {
          _events = events;
          _holidayMap = holidays;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data riwayat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  Future<void> _pickImage(ImageSource source, StateSetter setDialogState) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setDialogState(() => _proofImage = picked);
    }
  }

  void _showRequestDialog() {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih tanggal terlebih dahulu!')),
      );
      return;
    }

    _requestType = 'Izin';
    _reasonController.clear();
    _proofImage = null;
    _isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx2).viewInsets.bottom,
                top: 20.h, left: 20.w, right: 20.w,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ajukan Izin/Cuti/Dinas', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16.h),
                    DropdownButtonFormField<String>(
                      value: _requestType,
                      items: const [
                        DropdownMenuItem(value: 'Izin', child: Text('Izin')),
                        DropdownMenuItem(value: 'Cuti', child: Text('Cuti')),
                        DropdownMenuItem(value: 'Perjalanan Dinas', child: Text('Perjalanan Dinas')),
                      ],
                      decoration: const InputDecoration(labelText: 'Tipe', border: OutlineInputBorder()),
                      onChanged: (v) => setSheetState(() => _requestType = v!),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: _reasonController,
                      decoration: const InputDecoration(labelText: 'Alasan', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    SizedBox(height: 12.h),
                    if (_proofImage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Image.file(File(_proofImage!.path), width: 100, height: 100, fit: BoxFit.cover),
                      ),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery, setSheetState),
                            icon: const Icon(Icons.photo_library),
                            label: Text(_proofImage == null ? 'Pilih dari Galeri' : 'Ganti dari Galeri'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera, setSheetState),
                            icon: const Icon(Icons.camera_alt),
                            label: Text(_proofImage == null ? 'Ambil Foto' : 'Ganti dengan Kamera'),
                          ),
                        ],
                      ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx2).pop(),
                          child: const Text('Batal'),
                        ),
                        SizedBox(width: 8.w),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : () async {
                            final navigator = Navigator.of(ctx2);
                            setSheetState(() => _isSubmitting = true);
                            
                            final result = await ApiService.submitPengajuan(
                              tipe: _requestType,
                              tglMulai: DateFormat('yyyy-MM-dd').format(_selectedDay!),
                              tglSelesai: DateFormat('yyyy-MM-dd').format(_selectedDay!),
                              alasan: _reasonController.text,
                              buktiFoto: _proofImage != null ? File(_proofImage!.path) : null,
                            );

                            if (!mounted) return;
                            
                            setSheetState(() => _isSubmitting = false);
                            
                            if (result['status'] == 'success') {
                              navigator.pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pengajuan berhasil dikirim!'), backgroundColor: Colors.green),
                              );
                              _fetchData(); 
                            } else {
                               ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result['message'] ?? 'Gagal mengirim pengajuan'), backgroundColor: Colors.red),
                              );
                            }
                          },
                          child: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Kirim'),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF007ACC),
        elevation: 0,
        centerTitle: true,
        title: Padding(
          padding: EdgeInsets.only(top: 20.h),
          child: Text(
            "Riwayat",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
        ),
        toolbarHeight: 80.h,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  TableCalendar(
                    locale: 'id_ID',
                    firstDay: DateTime.utc(2022, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    eventLoader: _getEventsForDay,
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isNotEmpty) {
                          return Positioned(
                            right: 1,
                            bottom: 1,
                            child: _buildEventMarker(events),
                          );
                        }
                        return null;
                      },
                      holidayBuilder: (context, day, focusedDay) {
                         final holiday = _holidayMap[DateTime.utc(day.year, day.month, day.day)];
                         if (holiday != null) {
                           return Center(
                             child: Text(day.day.toString(), style: const TextStyle(color: Colors.red)),
                           );
                         }
                         return null;
                      },
                    ),
                  ),
                  const Divider(),
                  _buildEventList(),
                ],
              ),
      ),
       floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestDialog,
        backgroundColor: const Color(0xFF007ACC),
        icon: const Icon(
          Icons.edit_calendar,
          color: Colors.white,
        ),
        label: const Text(
          "Ajukan Izin/Cuti",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEventMarker(List<dynamic> events) {
    String status = events.first['type'] == 'absensi' ? events.first['status'] : events.first['tipe_pengajuan'];
    Color markerColor = Colors.grey;
    if (status == 'Hadir') markerColor = Colors.green;
    if (status == 'Terlambat') markerColor = Colors.orange;
    if (status == 'Alpha') markerColor = Colors.red;
    if (['Izin', 'Cuti', 'Perjalanan Dinas'].contains(status)) markerColor = Colors.blue;

    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(color: markerColor, shape: BoxShape.circle),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);
    final holiday = _holidayMap[DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)];

    if (events.isEmpty && holiday == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text("Tidak ada data pada tanggal ini."),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Detail untuk ${DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDay!)}", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (holiday != null)
            ListTile(
              leading: const Icon(Icons.celebration, color: Colors.red),
              title: Text(holiday, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ...events.map((item) {
            if (item['type'] == 'absensi') {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.fingerprint),
                  title: Text("Status: ${item['status']}"),
                  subtitle: Text("Masuk: ${item['jam_masuk'] != null ? DateFormat('HH:mm').format(DateTime.parse(item['jam_masuk'])) : '-'} | Pulang: ${item['jam_pulang'] != null ? DateFormat('HH:mm').format(DateTime.parse(item['jam_pulang'])) : '-'}"),
                ),
              );
            } else { // type == 'pengajuan'
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.event_note),
                  title: Text("Pengajuan: ${item['tipe_pengajuan']}"),
                  subtitle: Text("Status: ${item['status_pengajuan']}"),
                ),
              );
            }
          }),
        ],
      ),
    );
  }
}
