# 🌟 EventKu: Pusat Informasi Acara Kampus Anda

> <blockquote>"Jangan pernah ketinggalan acara penting lagi. Semua seminar, workshop, dan kompetisi di kampus, dalam satu genggaman."</blockquote>

[![Bahasa](https://img.shields.io/badge/Bahasa-Dart-blue.svg)](https://dart.dev/)
[![Framework](https://img.shields.io/badge/Framework-Flutter-02569B.svg)](https://flutter.dev/)
[![Backend](https://img.shields.io/badge/Backend-Firebase%20%7C%20Supabase-FFCA28.svg)]()
[![Lisensi](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## ✨ Deskripsi Proyek

**EventKu (EventHub)** adalah aplikasi *mobile* yang dikembangkan menggunakan **Flutter** untuk menjadi **pusat informasi (aggregator)** terpusat bagi berbagai acara kampus seperti seminar, *workshop*, konser, dan kompetisi[cite: 4, 5].

Proyek ini mengatasi masalah informasi acara yang tersebar di berbagai platform media sosial dengan menyajikan semuanya dalam satu antarmuka yang mudah diakses dan interaktif[cite: 5].

Aplikasi ini melayani dua jenis pengguna utama:
1.  **Pengguna (User):** Mahasiswa yang mencari, melihat detail, mendaftar, dan mengatur pengingat untuk acara yang diminati[cite: 8, 53].
2.  **Admin:** Pengguna khusus yang mengelola (CRUD) data acara dan kategori melalui panel admin terpisah (menggunakan *backend* yang sama)[cite: 9, 62].

## 🌟 Fitur Utama

Berdasarkan fungsionalitas yang didefinisikan dalam Use Case Diagram:

* **Pencarian & Filter Acara:** Jelajahi daftar acara, cari acara spesifik berdasarkan kata kunci, atau saring berdasarkan kategori (Akademik, Olahraga, Seni, dll.)[cite: 29, 85].
* **Detail Acara Lengkap:** Lihat informasi rinci seperti deskripsi, pembicara, lokasi, harga, dan tautan pendaftaran eksternal[cite: 30, 33].
* **Pengingat Otomatis:** Atur notifikasi **H-1** untuk acara yang diminati (membutuhkan Login/Registrasi)[cite: 31, 34].
* **Autentikasi Aman:** Login/Registrasi untuk mengakses fitur personal[cite: 34].
* **Modul Admin:** Fungsionalitas lengkap untuk Admin, termasuk:
    * Mengelola Data Acara (Buat, Baca, Ubah, Hapus)[cite: 35].
    * Mengelola Kategori Acara[cite: 37].

## 🛠️ Memulai (Getting Started)

Aplikasi ini dibangun dengan Flutter. Untuk menjalankan proyek secara lokal, pastikan Anda telah menyiapkan Flutter SDK.

### Prasyarat

* **Flutter SDK:** Versi [Masukkan Versi Flutter Anda di sini]
* **Dart SDK:** Sudah termasuk dalam instalasi Flutter.
* **Git**
* **Editor Code:** (VS Code / Android Studio)

### Instalasi

1.  **Kloning Repositori:**
    ```bash
    git clone [https://github.com/user/nama-repo-anda.git](https://github.com/user/nama-repo-anda.git)
    cd nama-repo-anda
    ```

2.  **Instal Dependensi (Package):**
    Di dalam direktori proyek, jalankan:
    ```bash
    flutter pub get
    ```

3.  **Konfigurasi Backend:**
    EventKu menggunakan **Firebase/Supabase** [cite: 153] untuk data.
    * Siapkan proyek baru di platform pilihan Anda.
    * Buat *file* `lib/firebase_options.dart` atau konfigurasi serupa dengan kunci dan kredensial API Anda. (Anda mungkin perlu membuat *file* `.env` untuk *key* sensitif.)

4.  **Jalankan Aplikasi:**
    Pastikan perangkat virtual atau fisik terhubung, lalu jalankan:
    ```bash
    flutter run
    ```

## 📂 Struktur Data (Class Diagram Overview)

Aplikasi ini berpusat pada entitas utama berikut[cite: 39, 55, 63, 78, 86]:

| Class | Peran | Atribut Kunci |
| :--- | :--- | :--- |
| **User** | Mewakili pengguna aplikasi umum. | `userId`, `name`, `email` [cite: 41, 42, 43] |
| **Admin** | Turunan dari User, mengelola data acara dan kategori[cite: 61, 62]. | `adminId`, `role` [cite: 56, 118] |
| **Event** | Data inti acara (seminar, workshop, dll.)[cite: 76]. | `eventId`, `title`, `date`, `location`, `price` [cite: 65, 66, 68, 69, 72] |
| **Category** | Digunakan Admin untuk mengelompokkan acara[cite: 85]. | `categoryId`, `name` [cite: 80, 81] |
| **Notification** | Digunakan untuk mengirim pengingat H-1 ke User[cite: 94]. | `notificationId`, `userId`, `eventId`, `sendDate` [cite: 88, 89, 90, 92] |

*Terdapat hubungan **Many-to-Many** antara User dan Event (User dapat mendaftar banyak event, dan event dapat diikuti banyak user).* [cite: 96]

## 🤝 Kontribusi (Contributing)

Kami menyambut kontribusi kode, laporan *bug*, atau saran fitur!

1.  *Fork* repositori ini.
2.  Buat cabang fitur baru dari `main` (`git checkout -b feature/NamaFitur`).
3.  Lakukan perubahan dan *commit* dengan pesan yang jelas.
4.  Buka *Pull Request* baru.

## ✍️ Lisensi

Proyek ini berada di bawah **Lisensi MIT** [cite: 96, 4] - lihat *file* [LICENSE](LICENSE) untuk detail selengkapnya.

---

Apakah Anda ingin saya memberikan contoh kode **Dart/Flutter** sederhana berdasarkan salah satu Use Case, misalnya fungsi `setReminder()` pada Class `User`?
