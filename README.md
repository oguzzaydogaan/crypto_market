# CryptoMarket 📈

**CryptoMarket**, kripto para piyasasını anlık olarak takip etmenizi, favori varlıklarınızı yönetmenizi ve piyasa hareketlerini detaylı grafikler üzerinden incelemenizi sağlayan modern bir mobil uygulamadır.

---

## 📱 Özellikler

- **⚡ Anlık Veri Takibi:** Binance WebSocket (SignalR) bağlantısı ile fiyatlar ve değişim oranları gecikmesiz olarak güncellenir.
- **📋 Dinamik Liste Yönetimi:**
  - Kullanıcılar izlemek istedikleri coinleri sembol (örn: `BTCUSDT`) girerek ekleyebilirler.
  - Listelenen varlıklar **İsim**, **Fiyat** ve **24s Değişim** kriterlerine göre sıralanabilir (Canlı Sıralama).
- **👀 Görünüm Modları:** Kullanıcı tercihine göre **Liste (List)** ve **Izgara (Grid)** görünümü arasında tek tuşla geçiş yapılabilir.
- **📊 Detaylı Analiz:**
  - Etkileşimli mum grafikleri (Candlestick Charts).
  - Anlık gerçekleşen alım-satım (Recent Trades) işlemleri.
- **⭐ Favoriler:** Sık takip edilen coinler favorilere eklenerek ayrı bir sayfada filtrelenmiş olarak görüntülenebilir.
- **🔍 Arama:** Coin ismi veya sembolüne göre anlık filtreleme.

## 🛠️ Kullanılan Teknolojiler

### Mobile (Frontend)

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management:** `setState` (Performans optimize edilmiş)
- **Networking:** `http`, `signalr_netcore`
- **UI Components:** Custom Widgets (`CoinCard`, `CoinExplorer`), Material Design 3

### Backend (Sunucu)

- **Framework:** .NET Core Web API
- **Real-time Communication:** SignalR
- **Data Source:** Binance Public API (WebSocket Stream)

## 🚀 Kurulum ve Çalıştırma

Projeyi yerel ortamınızda çalıştırmak için aşağıdaki adımları izleyin:

### Gereksinimler

- Flutter SDK
- Dart SDK
- Android Studio / VS Code
- Bir Android/iOS Emülatörü veya fiziksel cihaz

### Adımlar

1.  **Depoyu klonlayın:**

    ```bash
    git clone [https://github.com/oguzzaydoagaan/crypto_market.git](https://github.com/oguzzaydoagaan/crypto_market.git)
    cd crypto_market
    ```

2.  **Bağımlılıkları yükleyin:**

    ```bash
    flutter pub get
    ```

3.  **Backend Bağlantısı:**

    - `lib/services/` klasörü altındaki servis dosyalarında (`coin_service.dart`, `signalr_service.dart`) yer alan `_baseUrl` değişkenini kendi yerel sunucu IP adresinizle güncelleyin.

4.  **Uygulamayı başlatın:**
    ```bash
    flutter run
    ```

## 👤 Geliştirici

**Ad Soyad:** Oğuzhan Aydoğan
**Bölüm:** Bilgisayar Mühendisliği

---

_Bu proje eğitim amaçlı geliştirilmiştir._
