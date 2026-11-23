# Audio (sudah ada placeholder)

Efek suara WAV kecil yang dibuat khusus untuk game ini:

| File | Dipakai saat |
| --- | --- |
| `klik.wav` | menekan tombol menu utama |
| `koin.wav` | pelanggan membayar (penjualan) |
| `beli.wav` | belanja bahan, rekrut karyawan, beli upgrade |
| `salah.wav` | aksi gagal (uang tidak cukup, bahan kurang) |
| `masak.wav` | mulai memasak |

Pemutaran dibungkus `lib/core/audio_service.dart` (aman-gagal: jika audio tidak
tersedia, game tetap berjalan). Musik latar bisa ditambahkan di `assets/audio/`
lalu diputar dengan `FlameAudio.bgm.play(...)`.

Ganti file dengan nama yang sama untuk memakai suara sendiri, atau tambahkan
entri baru di `_file` pada `audio_service.dart`.
