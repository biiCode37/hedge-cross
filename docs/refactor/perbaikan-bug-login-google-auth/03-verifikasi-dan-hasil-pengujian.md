# 03. Verifikasi & Hasil Pengujian: Penyelarasan Kredensial OAuth & Quality Gates

**Tanggal:** 2026-11-24  
**Branch:** `devmode`  
**Hasil Akhir:** Seluruh sertifikat terverifikasi, analisis statis 0 issue, dan 145/145 unit test lulus (100%).

---

## 1. Verifikasi Sertifikat & Konfigurasi Google Cloud/Firebase

### 1.1. Pemeriksaan Sertifikat Terdaftar via API
```bash
python -c "
# Kueri endpoint https://firebase.googleapis.com/v1beta1/projects/hedge-mikrotrans/androidApps/.../sha
"
```
**Hasil Output:**
* Sertifikat `497877eca7bcfd5beff37bf623a6e9209af3f564` (SHA_1): TERDAFTAR
* Sertifikat `71ffe7432e9be6f8be7d855b4953f90e87d5a674` (SHA_1): TERDAFTAR
* Sertifikat `8619170b6890a2118d18a5dd0347efe1ac281dbb7e104683333c614988042ac7` (SHA_256): TERDAFTAR
* Sertifikat `bce43710e39f80d98d1a062f6c583c4bb98c42adf445edb3f8ddf093e5d3caa5` (SHA_256): TERDAFTAR

### 1.2. Verifikasi Keystore Terkunci di `android/app/`
```bash
keytool -list -v -keystore android/app/hedge_debug.keystore -alias androiddebugkey -storepass android
```
**Hasil:**
* SHA-1: `71:FF:E7:43:2E:9B:E6:F8:BE:7D:85:5B:49:53:F9:0E:87:D5:A6:74` (Cocok 100% dengan Firebase).

---

## 2. Verifikasi Quality Gates Flutter

### 2.1. Static Analysis (`flutter analyze`)
```bash
flutter analyze
```
**Hasil:**
```
Analyzing HEDGE-FLUTTER...
No issues found! (ran in 147.3s)
```

### 2.2. Unit & Widget Test Suite (`flutter test`)
```bash
flutter test
```
**Hasil:**
```
00:41 +145: All tests passed!
```
145 dari 145 skenario pengujian berhasil lulus tanpa kegagalan (100% Pass Rate).

---

## 3. Matriks Whitelist 7 Dispatcher Terverifikasi Aktif
Koleksi `authorized_dispatchers` di Firestore telah diverifikasi memuat 7 akun operasional:
1. `biicode37@gmail.com` — Role: `superadmin` (Status: `active`, `is_authorized: true`)
2. `muhammadabyn37@gmail.com` — Role: `superadmin` (Status: `active`, `is_authorized: true`)
3. `tj.biipro@gmail.com` — Role: `superadmin` (Status: `active`, `is_authorized: true`)
4. `biiaby370@gmail.com` — Role: `pdo` (Status: `active`, `is_authorized: true`)
5. `inputdata.jaklingkotj@gmail.com` — Role: `pdo` (Status: `active`, `is_authorized: true`)
6. `miqdads92@gmail.com` — Role: `admin` (Status: `active`, `is_authorized: true`)
7. `bionex37@gmail.com` — Role: `pdo` (Status: `pending`, `is_authorized: false`)
