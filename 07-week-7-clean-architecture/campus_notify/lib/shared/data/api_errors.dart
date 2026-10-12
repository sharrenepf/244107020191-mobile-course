import 'package:dio/dio.dart';

String friendlyError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Coba lagi beberapa saat.';
      case DioExceptionType.connectionError:
        return 'Tidak ada koneksi internet.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 401) return 'Sesi berakhir. Silakan login ulang.';
        if (code == 403) return 'Kamu tidak punya akses ke data ini.';
        if (code != null && code >= 500) return 'Server sedang bermasalah.';
        return 'Permintaan gagal (kode $code).';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      default:
        return 'Terjadi kesalahan jaringan.';
    }
  }
  final text = error.toString();
  return text.startsWith('Exception: ') ? text.substring(11) : text;
}