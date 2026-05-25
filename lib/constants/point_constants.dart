class PointConstants {
  // ── Earn ──────────────────────────────────────────
  static const double minBelanjaEarnPoin = 10000; // min Rp10.000
  static const double poinPerTransaksi   = 10.0;  // dapat 10 poin flat

  // ── Redeem ────────────────────────────────────────
  static const double minPoinRedeem      = 100.0;  // min 100 poin
  static const double poinPerRedeem      = 100.0;  // kelipatan 100 poin
  static const double diskonPerRedeem    = 1000.0; // = Rp1.000

  // ── Helper ────────────────────────────────────────

  /// Hitung poin dari total belanja.
  /// Return 10.0 jika >= Rp10.000, return 0 jika di bawah minimum.
  static double hitungPoin(double totalHarga) {
    if (totalHarga < minBelanjaEarnPoin) return 0;
    return poinPerTransaksi;
  }

  /// Hitung nominal diskon dari poin yang dimiliki.
  /// Contoh: 250 poin → 2 × Rp1.000 = Rp2.000
  static double hitungDiskon(double poin) {
    if (poin < minPoinRedeem) return 0;
    final kelipatan = (poin / poinPerRedeem).floor();
    return kelipatan * diskonPerRedeem;
  }

  /// Hitung berapa poin yang akan terpakai.
  static double hitungPoinTerpakai(double poin) {
    if (poin < minPoinRedeem) return 0;
    final kelipatan = (poin / poinPerRedeem).floor();
    return kelipatan * poinPerRedeem;
  }

  /// Hitung sisa poin setelah redeem.
  static double sisaPoin(double poin) {
    return poin - hitungPoinTerpakai(poin);
  }

  /// Tentukan apakah user boleh redeem.
  static bool canRedeem(double poin) {
    return poin >= minPoinRedeem;
  }
}