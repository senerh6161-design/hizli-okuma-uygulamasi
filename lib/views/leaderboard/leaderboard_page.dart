import 'package:flutter/material.dart';
import '../../models/leaderboard_data.dart';
import '../../services/auth_service.dart';
import '../auth/auth_page.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<LeaderboardResult> _future;

  @override
  void initState() {
    super.initState();
    _future = LeaderboardData.todayRanking();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = LeaderboardData.todayRanking();
    });
    await _future;
  }

  String _rankLabel(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Bugünün Liderlik Tablosu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<LeaderboardResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final result = snapshot.data ?? const LeaderboardResult(entries: [], isDemo: true);
          final ranking = result.entries;
          final youIndex = ranking.indexWhere((e) => e.isYou);
          final youIsFirst = youIndex == 0;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: youIsFirst
                          ? [Colors.amber.shade600, Colors.orange.shade400]
                          : const [Color(0xFF4F46E5), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        youIsFirst ? Icons.emoji_events : Icons.groups_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          youIsFirst
                              ? '🎉 Bugün en çok okumayı SEN yaptın!'
                              : 'Bugün en çok kim okudu, hep birlikte bakalım!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (!AuthService.isLoggedIn) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.indigo, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Şu an örnek profillerle bir gösterim görüyorsun. Gerçek arkadaşlarınla karşılaştırmak için giriş yap.',
                            style: TextStyle(color: Colors.indigo, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AuthPage()),
                            );
                            if (!mounted) return;
                            _refresh();
                          },
                          child: const Text('Giriş Yap'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (ranking.isEmpty) ...[
                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      'Bugün henüz kimse alıştırma yapmadı.\nListeye ilk giren sen ol! 🚀',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ),
                ] else
                  ...List.generate(ranking.length, (index) {
                    final entry = ranking[index];
                    final rank = index + 1;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: entry.isYou
                            ? const Color(0xFF4F46E5).withValues(alpha: 0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: entry.isYou
                            ? Border.all(color: const Color(0xFF4F46E5), width: 1.5)
                            : null,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text(
                              _rankLabel(rank),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(entry.avatar, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: entry.isYou ? FontWeight.bold : FontWeight.w600,
                                fontSize: 15,
                                color: entry.isYou ? const Color(0xFF4F46E5) : Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            '${entry.count} alıştırma',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 12),
                Text(
                  result.isDemo
                      ? 'Not: Bu profiller bu cihazda gösterilen örnek profillerdir — gerçek diğer kullanıcılar değildir.'
                      : 'Bu liste, giriş yapmış tüm kullanıcıların bugünkü gerçek ilerlemesini gösterir.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
