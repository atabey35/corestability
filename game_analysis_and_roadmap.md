# 🚀 CoreStability - Kapsamlı Oyun Analizi ve Yol Haritası

## 📊 Mevcut Durum Analizi

**Temel Mekanikler:**
- **Kule Savunması:** İşlevsel boşta/aktif hibrit yapı.
- **İlerleme:** 
  - *Oturum:* Altın geliştirmeleri (Hasar, Hız, Menzil, HP, Savunma).
  - *Roguelite:* Her 5 dalgada bir gelen Perk kartları (7 tip).
  - *Meta:* Başarımlara dayalı kalıcı kilometre taşları.
- **Düşmanlar:** Temel birim + Healer (İyileştirici) destek birimi. Patron (Boss) dalgaları (her 10. dalga).
- **Yetenekler:** 6 aktif yetenek (Uzi, Roket, Dondurma, Lazer, Kalkan, EMP).

**Durum:** Oyun sağlam bir teknik temele sahip. Ana "çekicilik" şu an için istatistiklerin ölçeklenme tatmini, ancak uzun vadeli oyuncu tutma için **taktiksel çeşitlilik** ve **görsel "meyve suyu" (juice/vurgu)** eksikliği var.

---

## 🗺️ Önerilen Yol Haritası

### 1. ⚔️ İçerik Genişletme: Düşman Ekolojisi
*Oyunun "sadece kuleye doğru yürü" mantığından fazlasına ihtiyacı var. Düşmanlar oyuncuyu hedef önceliği belirlemeye zorlamalı.*

*   **🛡️ Tank Birimi ("Goliath"):** 
    *   *İstatistikler:* Çok yüksek HP, çok yavaş, yüksek hasar.
    *   *Davranış:* Atışları emer. Geri itilemez.
    *   *Görsel:* Büyük, zırhlı kare/altıgen.
*   **⚡ Hızcı ("Dasher"):**
    *   *İstatistikler:* Düşük HP, çok hızlı.
    *   *Davranış:* Zikzaklar çizerek veya hız patlamalarıyla hareket eder.
*   **🏹 Menzilli Birim ("Mortar"):**
    *   *İstatistikler:* Uzakta durur, kuleye mermi fırlatır.
    *   *Karşı Hamle:* Oyuncunun Menzil geliştirmesini veya aktif yeteneklerini (Roket/Lazer) kullanmasını zorunlu kılar.
*   **🦠 Sürü birimi ("Splitter"):**
    *   *Davranış:* Öldüğünde 3 küçük ve daha hızlı birime bölünür.
*   **👑 Patron (Boss) Yenilemesi:**
    *   10, 20, 50. dalgalar için benzersiz patronlar.
    *   *Mimari:* Minyonlarını koruyan duvarlar/kalkanlar oluşturur.

### 2. 🃏 Roguelite Derinliği (Perk Sistemi 2.0)
*Seçimlerin daha fazla anlam ifade etmesini sağlayın.*

*   **Sinerjiler:** 
    *   Örn: *Ağır Kalibre* + *Keskin Nişancı* = **"Railgun"** kilidini açar (Mermiler düşmanı deler geçer).
*   **Lanetli Perkler (Risk/Ödül):**
    *   Örn: *"Kanlı Para"*: +%50 Altın Değeri, ancak -%20 Maksimum HP.
    *   Örn: *"Aşırı Isınma"*: +%100 Ateş Hızı, ancak kule ateş ederken zamanla hasar alır.
*   **Yenileme (Reroll) ve Yasaklama:**
    *   Kötü kartları yenilemek için altın harcama veya bir kartı o oyun boyunca tekrar çıkmaması için yasaklama.

### 3. 🛠️ Meta-İlerleme: Atölye
*Oyunculara oyunlar arasında kazandıkları birimi harcamak için bir neden verin.*

*   **Eser (Artifact) Sistemi:** Benzersiz efektlere sahip donatılabilir eşyalar.
    *   *Enerji Çekirdeği:* Oyuna +100 Enerji ile başlar.
    *   *Nano-Zırh:* Saniyede 1 HP yeniler.
*   **Yetenek Ağacı:** 
    *   Dallanan yollar: "Saldırı" vs "Savunma" vs "Yardımcı".
    *   Örn: Kule etrafında bir "Mayın Tarlası" oluşturma yeteneği.

### 4. 🎨 "Vurgu" ve Cila (Juice)
*Oyunun yaşadığını hissettirin.*

*   **Uçan Hasar Sayıları:** Normal vuruşlar için beyaz, Kritikler için Turuncu 💥.
*   **Ekran Sallanması:** Patron doğduğunda, kule hasar aldığında veya roket patladığında.
*   **Dinamik Arka Planlar:** Dalga sayısı arttıkça arka plan renginin veya ızgara yoğunluğunun değişmesi.

### 5. 💰 Ekonomi ve Paraya Dönüştürme
*   **Çift Para Birimi:** 
    *   *Altın:* Yumuşak para (her oyunda sıfırlanır).
    *   *Kara Madde (Elmas):* Sert para (kalıcı, Patronlardan/Başarımlardan düşer). Atölye için kullanılır.

---

## 📅 Önerilen İlk Adımlar (Eylem Planı)

1.  **Hemen (Görsellik):** **Uçan Hasar Sayılarını** eklemek. "Tatmin duygusu" için en hızlı çözüm.
2.  **Kısa Vadeli (İçerik):** Stratejik Menzil geliştirmelerini zorunlu kılmak için **"Menzilli Düşman"** eklemek.
3.  **Orta Vadeli (Sistemler):** Perkler için **"Sinerjiler"** (örneğin delici atışlar) uygulamak.

İlk olarak hangisine odaklanmak istersiniz?
