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

## Contribution Guidelines (Git Workflow) 
To maintain clean version control and avoid fatal merge conflicts, all contributors MUST adhere to the following Git workflow:
1. Whenever you are developing a new feature, fixing a bug, or editing anything, it must be done in a dedicated branch. Never edit files or write code directly on the main branch.
2. Use branch names that clearly represent the feature or service being worked on so the team can easily track progress.
Recommended format: feature/<feature-name>, fix/<bug-name>, or services/<service-name>
Examples: feature/free-explore, services/material-detection, fix/splash-screen-ui
3. You are not allowed to push directly to main. Always push your code to your own branch (git push origin your-branch-name), then create a Pull Request (PR) on GitHub to be reviewed before merging into main.
4. Ensure your code is always up-to-date. When pulling the latest updates, always pull from main (git pull origin main). Never pull from someone else's branch to avoid complex Git history conflicts.
