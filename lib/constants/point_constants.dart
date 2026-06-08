class PointConstants {
  // ── Earn ──────────────────────────────────────────
  static const double minBelanjaEarnPoin = 10000; // min Rp10.000
  static const double poinPerTransaksi   = 10.0;  // dapat 10 poin flat

  // ── Redeem ────────────────────────────────────────
  static const double poinPerRedeem      = 100.0;  // kelipatan 100 poin
  static const double diskonPerRedeem    = 1000.0; // = Rp1.000

  // ── Tier ──────────────────────────────────────────
  static const double tierSilver   = 300.0;
  static const double tierGold     = 1000.0;
  static const double tierPlatinum = 2500.0;
  static const double tierDiamond  = 5000.0;

  static String getTier(double maxPoin) {             
    if (maxPoin >= tierDiamond)  return '💎 Diamond Member';
    if (maxPoin >= tierPlatinum) return '🛡️ Platinum Member';
    if (maxPoin >= tierGold)     return '🥇 Gold Member';
    if (maxPoin >= tierSilver)   return '🥈 Silver Member';
    return '🥉 Bronze Member';
  }

  static double getMultiplier(double maxPoin) {
    if (maxPoin >= tierDiamond)  return 2.0;
    if (maxPoin >= tierPlatinum) return 1.8;
    if (maxPoin >= tierGold)     return 1.5;
    if (maxPoin >= tierSilver)   return 1.2;
    return 1.0;
  }

  static double getMinPoinRedeem(double maxPoin) {
    if (maxPoin >= tierPlatinum) return 100.0; // Platinum & Diamond
    if (maxPoin >= tierSilver) return 200.0; // Silver, Gold
    return 300.0; // Bronze
  }

  // ── Helper ────────────────────────────────────────

  /// Hitung poin dari total belanja berdasarkan tier multiplier.
  static double hitungPoin(double totalHarga, double maxPoin) {
    if (totalHarga < minBelanjaEarnPoin) return 0;
    final multiplier = getMultiplier(maxPoin);
    return (totalHarga / 1000) * multiplier;
  }

  /// Hitung nominal diskon dari poin yang dimiliki.
  static double hitungDiskon(double poin, double maxPoin) {
    final minRedeem = getMinPoinRedeem(maxPoin);
    if (poin < minRedeem) return 0;
    final kelipatan = (poin / poinPerRedeem).floor();
    return kelipatan * diskonPerRedeem;
  }

  /// Hitung berapa poin yang akan terpakai.
  static double hitungPoinTerpakai(double poin, double maxPoin) {
    final minRedeem = getMinPoinRedeem(maxPoin);
    if (poin < minRedeem) return 0;
    final kelipatan = (poin / poinPerRedeem).floor();
    return kelipatan * poinPerRedeem;
  }

  /// Hitung sisa poin setelah redeem.
  static double sisaPoin(double poin, double maxPoin) {
    return poin - hitungPoinTerpakai(poin, maxPoin);
  }

  /// Cek apakah poin cukup untuk ditukarkan
  static bool canRedeem(double poin, double maxPoin) {
    return poin >= getMinPoinRedeem(maxPoin);
  }
}