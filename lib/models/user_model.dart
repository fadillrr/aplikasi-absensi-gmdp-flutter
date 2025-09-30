import 'dart:convert';

UserModel userModelFromJson(String str) => UserModel.fromJson(json.decode(str));

class UserModel {
    final int pegawaiId;
    final String pegawaiNama;
    final String pegawaiNip;
    final String jabatan;
    final String jenisKelamin;
    final String? noHp;
    final String? alamat;
    final String? tglLahir;
    final int? kantorId;
    final bool geolocatorActive;
    final Kantor? kantor;

    UserModel({
        required this.pegawaiId,
        required this.pegawaiNama,
        required this.pegawaiNip,
        required this.jabatan,
        required this.jenisKelamin,
        this.noHp,
        this.alamat,
        this.tglLahir,
        this.kantorId,
        required this.geolocatorActive,
        this.kantor,
    });

    factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        pegawaiId: json["pegawai_id"],
        pegawaiNama: json["pegawai_nama"],
        pegawaiNip: json["pegawai_nip"],
        jabatan: json["jabatan"],
        jenisKelamin: json["jenis_kelamin"],
        noHp: json["noHp"],
        alamat: json["alamat"],
        tglLahir: json["tgl_lahir"],
        kantorId: json["kantor_id"],
        geolocatorActive: json["geolocator_active"] == 1,
        kantor: json["kantor"] == null ? null : Kantor.fromJson(json["kantor"]),
    );

    Map<String, dynamic> toJson() => {
        "pegawai_id": pegawaiId,
        "pegawai_nama": pegawaiNama,
        "pegawai_nip": pegawaiNip,
        "jabatan": jabatan,
        "jenis_kelamin": jenisKelamin,
        "noHp": noHp,
        "alamat": alamat,
        "tgl_lahir": tglLahir,
    };
}

class Kantor {
    final int id;
    final String namaKantor;
    final String latitude;
    final String longitude;

    Kantor({
        required this.id,
        required this.namaKantor,
        required this.latitude,
        required this.longitude,
    });

    factory Kantor.fromJson(Map<String, dynamic> json) => Kantor(
        id: json["id"],
        namaKantor: json["nama_kantor"],
        latitude: json["latitude"],
        longitude: json["longitude"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "nama_kantor": namaKantor,
        "latitude": latitude,
        "longitude": longitude,
    };
}