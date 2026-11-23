# Assets

Semua grafis saat ini **digambar lewat kode** (lihat `lib/game/components/`),
sehingga game bisa jalan tanpa file gambar. Folder ini disiapkan agar aset
sprite asli mudah dipasang nanti:

- `assets/sprites/` — sprite NPC, meja, etalase, ikon menu (PNG, 1x/2x/3x).
- `assets/audio/` — efek suara & musik latar (`flame_audio`).

Ganti placeholder kode dengan menambahkan `SpriteComponent` di
`lib/game/components/` lalu daftarkan aset di `pubspec.yaml` (sudah ada
entri `assets/`).
