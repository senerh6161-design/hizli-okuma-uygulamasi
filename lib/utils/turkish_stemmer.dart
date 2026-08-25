/// Türkçe sözlük aramaları (TDK + yerel sözlük) için basit bir ek ayırma
/// yardımcısı. Gerçek bir morfolojik çözümleyici DEĞİL — sadece en yaygın
/// çekim eklerini kural tabanlı olarak deneyip çıkarıyor. Metindeki
/// kelimelerin BÜYÜK ÇOĞUNLUĞU ek aldığı için (ör. "ülkelerin", "keşfetmeyi"),
/// sözlükte doğrudan kelimenin kendisini aramak çoğu zaman "bulunamadı"
/// sonucu veriyordu — bu yüzden kelimeye önce olduğu gibi, sonra kökten
/// giderek daha fazla ek çıkarılmış hâlleriyle bakılır.
library;

// Uzun ekler önce denenmeli ki "lerinden" gibi birleşik bir ek, yanlışlıkla
// sadece "den" olarak (kökü bozacak şekilde) ayrılmasın.
const List<String> _suffixes = [
  'lerinden', 'larından', 'lerinde', 'larında', 'leriyle', 'larıyla',
  'sinden', 'sından', 'sinde', 'sında', 'lerini', 'larını', 'sinin',
  'sının', 'ndaki', 'deki', 'daki', 'ları', 'leri', 'sini', 'sını',
  'ndan', 'nden', 'dığı', 'diği', 'dığında', 'diğinde', 'ecek', 'acak',
  'yorlar', 'meye', 'maya', 'meyi', 'mayı', 'mesi', 'ması', 'yordu',
  'muşlar', 'mişler', 'mış', 'miş', 'muş', 'müş', 'yor', 'ler', 'lar',
  'nın', 'nin', 'nun', 'nün', 'dan', 'den', 'tan', 'ten', 'dır', 'dir',
  'dur', 'dür', 'tır', 'tir', 'tur', 'tür', 'da', 'de', 'ta', 'te',
  'ye', 'ya', 'ın', 'in', 'un', 'ün', 'sı', 'si', 'su', 'sü', 'yı',
  'yi', 'yu', 'yü', 'la', 'le', 'a', 'e', 'ı', 'i', 'u', 'ü',
];

// Ünsüz yumuşamasının tersi: kök sözlükte hangi sert sesle yazılıyorsa
// (kelebek, kitap, ağaç, kanat) onu üretir. Eşleşme yoksa null döner.
const Map<String, String> _softToHardConsonant = {
  'ğ': 'k',
  'b': 'p',
  'c': 'ç',
  'd': 't',
};

String? _hardenFinalConsonant(String stem) {
  if (stem.isEmpty) return null;
  final hard = _softToHardConsonant[stem[stem.length - 1]];
  if (hard == null) return null;
  return '${stem.substring(0, stem.length - 1)}$hard';
}

/// [word] için, kelimenin kendisinden başlayıp gittikçe daha fazla ek
/// çıkarılmış (2 tura kadar) aday köklerin listesini döner. Fiil kökü
/// olabilecek adaylar için ayrıca "+mek"/"+mak" mastar hâli de eklenir
/// (ör. "keşfet" -> "keşfetmek") — sözlükler fiilleri genelde mastar
/// hâliyle listeler.
List<String> turkishStemCandidates(String word) {
  final candidates = <String>[word];
  final seen = <String>{word};

  void addIfNew(String candidate) {
    if (candidate.length < 2 || seen.contains(candidate)) return;
    seen.add(candidate);
    candidates.add(candidate);
  }

  List<String> stripOneRound(String base) {
    final results = <String>[];
    for (final suffix in _suffixes) {
      if (base.length - suffix.length >= 3 && base.endsWith(suffix)) {
        final stem = base.substring(0, base.length - suffix.length);
        results.add(stem);
        // Ünsüz yumuşaması: "kelebek"+in -> "kelebeğin" gibi ekli hâllerde
        // kökün son sesi yumuşamış olur (k->ğ, p->b, ç->c, t->d) — sözlük
        // kökü SERT haliyle listeler, o yüzden tersini de deneriz.
        final hardened = _hardenFinalConsonant(stem);
        if (hardened != null) results.add(hardened);
      }
    }
    return results;
  }

  final round1 = stripOneRound(word);
  for (final stem in round1) {
    addIfNew(stem);
    addIfNew('${stem}mek');
    addIfNew('${stem}mak');
  }
  for (final stem in round1) {
    for (final stem2 in stripOneRound(stem)) {
      addIfNew(stem2);
      addIfNew('${stem2}mek');
      addIfNew('${stem2}mak');
    }
  }

  return candidates;
}
