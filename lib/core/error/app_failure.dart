enum FailureKind {
  network,
  unauthorized,
  validation,
  notFound,
  conflict,
  businessRule,
  server,
  unknown,
}

class AppFailure implements Exception {
  const AppFailure(this.kind, {this.code, this.fields = const []});
  final FailureKind kind;
  final String? code;
  final List<String> fields;
  String get message => switch (code) {
    'INVALID_CREDENTIALS' => 'E-posta veya parola hatalı.',
    'PROFILE_LOAD_FAILED_AFTER_AUTH' => 'Giriş yapıldı, ancak profilin yüklenemedi. Bağlantını kontrol edip tekrar dene.',
    'SESSION_NOT_ACTIVE' => 'Bu tekrar oturumu artık aktif değil.',
    'REVIEW_ITEM_NOT_PENDING' => 'Bu soru daha önce işlendi.',
    'SUBJECT_NOT_SELECTABLE' => 'Bu ders aktif sınavın için seçilemiyor.',
    'EMAIL_ALREADY_REGISTERED' =>
      'Bu e-posta zaten kayıtlı. Giriş yapabilirsin.',
    'ANALYSIS_EXPIRED' => 'Analizin süresi doldu. Fotoğrafı yeniden yükle.',
    'ANALYSIS_ALREADY_CONSUMED' =>
      'Bu analizle bir soru zaten kaydedildi. Defterini kontrol et.',
    'NO_ACTIVE_EXAM' => 'Önce sınav seçimini tamamla.',
    'EXPORT_EMPTY' => 'Bu filtreye uygun dışa aktarılacak soru bulunamadı.',
    'EXPORT_TOO_LARGE' =>
      'Tek seferde çok fazla soru seçildi. Filtreyi daraltıp tekrar deneyin.',
    'EXPORT_NOT_READY' => 'Dosya henüz hazır değil. Birazdan tekrar dene.',
    'TOPIC_NOT_SELECTABLE' => 'Bu konu seçilemiyor. Konu listesini yenile.',
    'FILE_TOO_LARGE' ||
    'PAYLOAD_TOO_LARGE' => 'Görsel çok büyük. Daha küçük bir görsel seç.',
    'UNSUPPORTED_FILE_TYPE' ||
    'INVALID_FILE' => 'JPEG, PNG veya WebP biçiminde geçerli bir görsel seç.',
    'IMAGE_PERMISSION' =>
      'Kamera veya fotoğraf erişimini cihaz ayarlarından aç.',
    _ => switch (kind) {
      FailureKind.network =>
        'Bağlantı kurulamadı. Bağlantını kontrol edip tekrar dene.',
      FailureKind.unauthorized =>
        'Oturumun sona erdi. Lütfen yeniden giriş yap.',
      FailureKind.validation => 'Gerekli alanları kontrol et.',
      FailureKind.notFound => 'Kayıt bulunamadı veya artık erişilemiyor.',
      FailureKind.conflict =>
        'Kayıt değişmiş olabilir. Kontrol edip yeniden dene.',
      FailureKind.businessRule =>
        'İşlem tamamlanamadı. Seçimlerini kontrol et.',
      FailureKind.server =>
        'Hizmete şu an ulaşılamıyor. Biraz sonra tekrar dene.',
      FailureKind.unknown => 'İşlem tamamlanamadı. Lütfen tekrar dene.',
    },
  };
}
