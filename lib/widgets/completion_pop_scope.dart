import 'package:flutter/material.dart';

/// Bir egzersiz sayfasını sarar: kullanıcı geri gidince (sistem geri tuşu,
/// geri kaydırma, AppBar oku) sayfa gerçekten tamamlandıysa `true`,
/// tamamlanmadan çıkıldıysa `false` ile pop eder. Klasör 1'deki "Oturumu
/// Başlat" akışı bu sonucu kullanarak etkinliği sadece GERÇEKTEN
/// bitirildiyse tikler — sadece açıp kapatmak yetmez.
///
/// Not: Sayfa içindeki kendi "Bitir" gibi butonların yaptığı DOĞRUDAN
/// Navigator.pop(context, ...) çağrıları bundan etkilenmez (bilinçli
/// olarak); bu sarmalayıcı sadece sistem geri hareketlerini yakalar.
class CompletionPopScope extends StatelessWidget {
  final bool Function() isCompleted;
  final Widget child;

  const CompletionPopScope({super.key, required this.isCompleted, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, isCompleted());
      },
      child: child,
    );
  }
}
