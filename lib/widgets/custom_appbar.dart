import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomAppBar extends StatelessWidget {
  final String namaUser;
  final String jabatanUser;
  final bool showUserInfo;
  final bool showNotifPage;
  final bool hasNewNotification;
  final VoidCallback onToggleUserInfo;
  final VoidCallback onToggleNotif;

  const CustomAppBar({
    super.key,
    required this.namaUser,
    required this.jabatanUser,
    required this.showUserInfo,
    required this.showNotifPage,
    required this.hasNewNotification,
    required this.onToggleUserInfo,
    required this.onToggleNotif,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bagian Nama & Notifikasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nama + toggle
              GestureDetector(
                onTap: onToggleUserInfo,
                child: Row(
                  children: [
                    Text(
                      namaUser,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      showUserInfo ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ],
                ),
              ),

              // Notifikasi
              if (!showNotifPage)
                GestureDetector(
                  onTap: onToggleNotif,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications, color: Colors.white, size: 28),
                      if (hasNewNotification)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 10.w,
                            height: 10.w,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),

          // Jabatan muncul di bawah nama (posisi tetap)
          Positioned(
            top: 15.h,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: showUserInfo ? 1.0 : 0.0,
              child: Visibility(
                visible: showUserInfo,
                child: Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    jabatanUser,
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
