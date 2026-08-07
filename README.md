# SonAR 

Welcome to the SonAR project!

## Architecture & Folder Structure

This project uses a modular, feature-driven architecture. This ensures that as the app grows, different team members can work on different features or services simultaneously without causing merge conflicts.

Here is the "helicopter view" of the project structure:

```text
SonAR/
├── App/                  # Folder utama aplikasi, tempat UI dan siklus hidup aplikasi diatur
│   ├── ContentView.swift # Tampilan UI root/utama yang pertama kali dilihat pengguna
│   └── SonARApp.swift    # Entry point aplikasi (berisi @main)
│
├── ARBridge/             # Jembatan penghubung antara teknologi AR (ARKit/RealityKit) dengan aplikasi
│
├── Config/               # Tempat menyimpan pengaturan global, konstanta, atau environment variables
│
├── Core/                 # Fondasi aplikasi (Data, Logic murni) yang bebas dari elemen UI
│   ├── Enums/            # Koleksi enumerasi (Enum) yang digunakan secara global di banyak fitur
│   └── Models/           # Struktur data / Blueprint objek aplikasi (misal: struct WaveData)
│
├── Features/             # Fitur-fitur utama aplikasi (arsitektur modular untuk kemudahan tim)
│   ├── FreeExplore/      # Modul layar untuk fitur Eksplorasi Bebas
│   ├── GuidedWalkthrough/# Modul layar untuk fitur Tutorial atau Panduan Interaktif
│   │   └── Components/   # Komponen UI spesifik yang HANYA digunakan di mode Walkthrough
│   └── SplashScreen/     # Modul layar pemuatan awal (Loading Screen) saat aplikasi dibuka
│
├── FeedbackRobot/        # Package Reality Composer Pro (Aset 3D, Material, dan Scene AR/visionOS)
│
├── GlobalComponents/     # Komponen UI (Tombol, Card kustom) yang bisa dipakai ulang di SEMUA fitur
│
├── Resources/            # Tempat menyimpan aset statis dan media
│   └── Assets.xcassets/  # Katalog Apple untuk gambar, icon, dan warna kustom (Color Sets)
│
├── Services/             # Pengolahan algoritma berat, kalkulasi, dan koneksi eksternal/hardware
│   ├── MaterialDetection/# Algoritma untuk mendeteksi dan mengklasifikasikan jenis material
│   ├── SensorPlacement/  # Logic kalkulasi untuk menentukan penempatan sensor virtual di ruang AR
│   ├── Visualization/    # Pengolahan data angka menjadi bentuk visualisasi agar bisa dirender
│   └── WaveLogic/        # Inti pemrosesan gelombang (rumus fisika, pantulan, transmisi)
│
└── project.yml           # File konfigurasi XcodeGen (pembentuk struktur project otomatis)
```

## Getting Started (XcodeGen)

This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to manage the `.xcodeproj` file and prevent merge conflicts.

**Do NOT commit the `.xcodeproj` file.**

To generate the project locally on your machine:
1. Ensure you have XcodeGen installed: `brew install xcodegen`
2. Run the following command in the terminal at the root of this project:
   ```bash
   xcodegen
   ```
3. Open the newly generated `SonAR.xcodeproj` and start coding!
