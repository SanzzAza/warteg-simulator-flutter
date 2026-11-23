# Sprites (opsional)

Saat ini seluruh visual digambar langsung lewat kode Canvas di
`lib/game/components/`, sehingga game tidak membutuhkan file gambar sama sekali.

Untuk mengganti placeholder dengan sprite asli:

1. Taruh PNG di folder ini, contoh: `pelanggan.png`, `meja.png`,
   `etalase.png` (atur ukuran 64/128 px, latar transparan).
2. Ganti `render()` komponen terkait di `lib/game/components/` dengan
   `SpriteComponent` / `SpriteAnimationComponent` dari Flame.
3. Nama file otomatis terdaftar karena `pubspec.yaml` mendeklarasikan folder
   `assets/sprites/`.

Rekomendasi gaya: warna hangat (oranye, kuning, krem, cokelat, merah bata),
garis tebal bersahabat, tanpa efek neon.
