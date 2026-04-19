# 🐾 Pet Point: Digital Pet Shop & Adoption Ecosystem

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Powered-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-orange)](https://petpoint.web.app)

**Pet Point** adalah platform hybrid inovatif yang memisahkan ekosistem manajemen dan user experience. Dibangun dengan satu codebase Flutter untuk menangani **Web Dashboard (Admin)** dan **Mobile App (Customer)** secara sinkron menggunakan Firebase Real-time integration.

---

## 🛠️ Cara Menjalankan Project (Setup Guide)

Ikuti langkah-langkah berikut buat nge-run project ini di lokal lu:

### 1. Clone Repository
Buka terminal dan jalankan perintah berikut:
\`\`\`bash
git clone https://github.com/pranata/pet_point.git
cd pet_point
\`\`\`

### 2. Dapatkan File Secret (PENTING!)
Demi keamanan, file konfigurasi sensitif **tidak disertakan** dalam repository ini. Lu wajib minta file berikut ke pemilik repo (**Prana**) dan taruh di folder yang sesuai:

* **\`google-services.json\`**: Taruh di folder \`android/app/\`.
* **\`serviceAccountKey.json\`**: Taruh di folder \`assets/secret/\`.
* **\`firebase_options.dart\`**: Taruh di folder \`lib/\`.

### 3. Install Dependencies
Jalankan perintah ini buat download semua package yang dibutuhin:
\`\`\`bash
flutter pub get
\`\`\`

### 4. Running the Project
Project ini pake sistem platform detection, pilih salah satu:

* **Admin Dashboard (Web):**
\`\`\`bash
flutter run -d chrome --web-renderer canvaskit
\`\`\`

* **Customer App (Android):**
\`\`\`bash
flutter run -d android
\`\`\`

---

## 🏗️ Hybrid Architecture
Aplikasi ini menggunakan logika **Platform Detection** pada \`main.dart\`.

## 👥 Tim Pengembangan
•⁠  ⁠*Pranata Putrandana* - Lead Developer & Project Manager
•⁠  ⁠*Bunga Aulia Sari* 
•⁠  ⁠*Khoirun Nisa Fitriani* 
•⁠  ⁠*Muh. Zaky Dawamul Busro*

---
© 2026 Pet Point Project - Teknologi Informasi Politeknik Negeri Malang.
