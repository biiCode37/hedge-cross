# AGENTS.md — HEDGE (Headway Generator) By Mikrotrans Utara

Aturan dan panduan operasional wajib bagi AI Agent (AntiGravity) saat bekerja di repositori ini.

---

## 1. Aturan Mutlak Branch Git (STRICT)

1. **Wajib Bekerja di Branch `devmode`:**
   - Mulai saat ini dan seterusnya, **SEMUA** perubahan kode, pembuatan file baru, perbaikan bug, styling, dan eksekusi task apapun **HANYA BOLEH** dilakukan pada branch `devmode`.
2. **Larangan Menyentuh Branch `main`:**
   - Agen **DILARANG KERAS** melakukan commit langsung, checkout untuk edit, atau merge ke branch `main`, kecuali jika USER secara eksplisit memberikan instruksi khusus untuk itu.
3. **Pemeriksaan Branch Sebelum Eksekusi:**
   - Setiap kali memulai instruksi atau tugas baru, agen **WAJIB** memverifikasi bahwa branch yang sedang aktif adalah `devmode` melalui perintah:
     ```bash
     git branch --show-current
     ```
   - Jika branch aktif bukan `devmode`, segera beralih dengan:
     ```bash
     git checkout devmode
     ```

---

## 2. Standar Tooling & Command Line

- **Package Manager:** Selalu gunakan `pnpm` (dilarang menggunakan `npm` atau `yarn` tanpa alasan kuat).
- **Execution Script:** `pnpm run <script>`, `pnpm add <dep>`, `pnpm dlx <pkg>`.
- **Terminal Shell:** Selalu berikan instruksi dan sintaks command yang kompatibel dengan **Git Bash / zsh**.
- **Kompatibilitas:** Pastikan perintah aman (*non-destructive*) dan menyertakan context working directory bila relevan.

---

## 3. Standar Kualitas Desain & UI/UX

- **Brand Identity:**
  - Main Title: **HEDGE**
  - Sub Title: **Headway Generator**
  - Operator: **By Mikrotrans Utara**
- **Color Palette & Design Tokens:**
  - Mengacu pada logo visual resmi HEDGE:
    - Primary Amber/Orange Glow: `#FF9800` / `#FF7A00` / `#F59E0B`
    - Cyan / Electric Blue Accent: `#00E5FF` / `#00B0FF` / `#38BDF8`
    - Deep Obsidian Surface: `#070B12` / `#0C1017` / `#141A24`
    - Sleek Silver/White: `#F8FAFC` / `#E2E8F0`
- **Dual Theme Support:** Selalu pertahankan dukungan kontras tinggi untuk Dark Mode dan Light Mode melalui CSS Variables.
- **Mobile-First Ergonomics:** 90%+ pengguna adalah dispatcher smartphone Android di lapangan. Utamakan akses satu jempol (*thumb-first*), zero unnecessary scroll, dan ukuran touch-target minimal 44–48px.

---

## 4. Format Komunikasi & Output

Setiap penyelesaian tugas wajib menyertakan:
1. Ringkasan perubahan (3–8 bullet).
2. Daftar file yang berubah/ditambah (dengan clickable markdown link `file:///...`).
3. Cara menjalankan/verifikasi (`pnpm ...`).
4. Checklist verifikasi (termasuk verifikasi tema & branch aktif).

## 5. Build APK hanya atas perintah user (WAJIB)

**LAKUKAN BUILD APK HANYA KETIKA SAYA PERINTAHKAN.**

- Jangan menjalankan `flutter build apk`, Gradle assemble/package APK, atau skrip build APK sebagai langkah otomatis setelah edit, pengujian atau verifikasi.
- Instruksi implementasi/perbaikan tidak berarti izin build APK. Tunggu perintah eksplisit user untuk membuat APK.
- Analisis statis, pengujian Dart/Flutter dan kompilasi/unit test Kotlin yang tidak menghasilkan APK tetap boleh dilakukan sesuai task.
- Tanpa perintah build, laporkan perubahan source dan hasil verifikasi; pertahankan APK yang sudah ada.