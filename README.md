# ODTÜ Blockchain NFT Kontratı - Teknik Dokümantasyon

## 📋 İçindekiler
- [Genel Bakış](#genel-bakış)
- [Teknik Mimari](#teknik-mimari)
- [Fonksiyon Detayları](#fonksiyon-detayları)
- [Kullanım Örnekleri](#kullanım-örnekleri)
- [Güvenlik Özellikleri](#güvenlik-özellikleri)
- [Metadata Yapısı](#metadata-yapısı)
- [Deployment Rehberi](#deployment-rehberi)

---

## 🎯 Genel Bakış

**OdtuBlockchainNFT**, ODTÜ Blockchain Topluluğu'nun etkinlik katılımcılarına hatıra NFT'leri dağıtmak için tasarlanmış bir ERC-1155 akıllı kontratıdır.

### Proje Amacı
- Etkinlik katılımcılarına dijital hatıra NFT'leri dağıtmak
- Topluluk üyelerinin blockchain üzerinde doğrulanabilir katılım kayıtları oluşturmak
- Gaz verimli ve ölçeklenebilir bir NFT dağıtım sistemi kurmak

### Temel Özellikler
- ✅ **ERC-1155 Standardı**: Toplu işlemler için optimize edilmiş
- ✅ **Event-Based System**: Her etkinlik için ayrı token ID
- ✅ **Batch Mint**: Tek işlemde çoklu dağıtım
- ✅ **Güvenlik**: Ownable, Pausable, Burnable özellikleri
- ✅ **Metadata Tracking**: Supply takibi ve şeffaflık

---

## 🏗️ Teknik Mimari

### Neden ERC-1155?

**ERC-1155** standardı, bu proje için ERC-721'den çok daha uygun çünkü:

1. **Toplu İşlem Verimliliği**: 
   - ERC-721: 50 kişiye NFT = 50 ayrı işlem
   - ERC-1155: 50 kişiye NFT = Tek işlem (döngü içinde)
   - **Gaz maliyeti %70-80 daha düşük**

2. **Tek Kontrat Mimarisi**:
   - Tüm etkinlikler tek kontrat altında
   - Her yeni etkinlik için yeni kontrat deploy gerekmez
   - Yönetim ve bakım kolaylığı

3. **Ölçeklenebilirlik**:
   - Gelecekte fungible token'lar eklenebilir (katılım puanları vs.)
   - Aynı kontrat üzerinden farklı token türleri yönetilebilir

### OpenZeppelin Kütüphaneleri

Kontratımız, güvenlik ve güvenilirlik için OpenZeppelin'in savaşta test edilmiş kütüphanelerini kullanır:

- **ERC1155**: Temel token standardı
- **Ownable**: Erişim kontrolü (sadece owner mint edebilir)
- **Pausable**: Acil durum durdurma mekanizması
- **ERC1155Burnable**: Token yakma özelliği
- **ERC1155Supply**: Arz takibi ve şeffaflık

---

## 🔧 Fonksiyon Detayları

### Constructor (Satır 38-40)

```solidity
constructor(address initialOwner, string memory baseURI_) ERC1155(baseURI_)
```

**Ne İşe Yarar:**
- Kontrat deploy edildiğinde çağrılır
- İlk sahibi (`initialOwner`) belirler
- Metadata için temel URI ayarlar

**Neden Böyle:**
- **Multi-sig cüzdan**: Güvenlik için tek kişi yerine çoklu imza cüzdanı önerilir
- **Base URI**: Tüm NFT'ler için merkezi metadata yönetimi
- **Format**: `ipfs://<FOLDER_CID>/{id}.json` şeklinde

**Örnek Kullanım:**
```solidity
constructor(multiSigWallet, "ipfs://QmRvSoppQ5MKfsT4p5Snheae1DG3Af2NhYXWpKNZBvz2Eo/{id}.json")
```

---

### setURI (Satır 46-48)

```solidity
function setURI(string memory newuri) public onlyOwner
```

**Ne İşe Yarar:**
- Tüm token'lar için metadata URI'sini günceller
- Backup/kurtarma için kritik fonksiyon

**Neden Böyle:**
- **Esneklik**: Metadata depolama çözümü değiştiğinde (IPFS → Arweave) URI güncellenebilir
- **Backup**: IPFS pinleme sorunlarında alternatif depolama alanına geçiş
- **İyileştirme**: Daha iyi bir metadata yapısına geçiş imkanı

**Örnek Kullanım:**
```solidity
// IPFS'ten Arweave'e geçiş
setURI("ar://<transaction_id>/{id}.json")
```

---

### createEvent (Satır 54-62)

```solidity
function createEvent(uint256 tokenId) public onlyOwner
```

**Ne İşe Yarar:**
- Yeni bir etkinlik (token ID) oluşturur
- Token ID'nin geçerli olduğunu kayıt altına alır

**Neden Böyle:**
- **Basitlik**: Token ID doğrudan event ID olarak kullanılır (1, 2, 3...)
- **Hash Kaldırıldı**: `keccak256` hesaplama gereksizdi, gaz tasarrufu sağlandı
- **Mapping Azaltıldı**: `eventToTokenId` ve `tokenIdToEvent` mapping'leri kaldırıldı
- **Validation**: Token ID > 0 kontrolü ile geçersiz ID'ler engellenir

**Tasarım Kararları:**
1. **Hash Kullanmama**: `keccak256(eventId)` yerine doğrudan `tokenId` kullanımı
   - Daha az gaz maliyeti
   - Daha basit kod
   - Daha kolay debug

2. **Tek Mapping**: Sadece `eventTokenIds` mapping'i
   - Gereksiz karmaşıklık kaldırıldı
   - Daha az storage maliyeti

**Örnek Kullanım:**
```solidity
// İlk etkinlik
createEvent(1);

// İkinci etkinlik
createEvent(2);
```

---

### mint (Satır 71-73)

```solidity
function mint(address to, uint256 id, uint256 amount, bytes memory data) public onlyOwner
```

**Ne İşe Yarar:**
- Tek bir adrese, belirli bir token ID ve miktarda NFT basar
- Özel durumlar için kullanılır (örn: konuşmacılar, özel ödüller)

**Neden Böyle:**
- **Esneklik**: `mintEvent` ile toplu dağıtım yapılamayan durumlar için
- **Özel Durumlar**: Tek kişiye özel NFT dağıtımı
- **OpenZeppelin Standart**: `_mint` internal fonksiyonunu kullanır

**Kullanım Senaryoları:**
- Konuşmacılara özel rozet NFT'leri
- Hata düzeltme durumunda tek kişiye mint
- Test amaçlı küçük mint işlemleri

---

### mintEvent (Satır 81-97) ⭐ ANA FONKSİYON

```solidity
function mintEvent(address[] calldata recipients, uint256 tokenId, uint256 amount) public onlyOwner
```

**Ne İşe Yarar:**
- Bir etkinlik için toplu NFT dağıtımı yapar
- Tüm katılımcılara aynı token ID'li NFT basar

**Neden Böyle:**
- **Toplu Dağıtım**: Tek işlemde çoklu alıcıya dağıtım
- **Aynı Token ID**: Aynı etkinlikteki herkes aynı NFT'ye sahip
- **Validation**: Event ID kontrolü, boş liste kontrolü

**Kritik Tasarım Kararı:**

**❌ Başlangıçta Yanlış Yaklaşım:**
```solidity
_mintBatch(recipients, tokenIds, amounts, "");
```

**❌ Sorun:** `_mintBatch` fonksiyonu, **birçok farklı token'ı tek bir adrese** göndermek için tasarlanmıştır. Bizim ihtiyacımız ise **tek bir token'ı birçok farklı adrese** göndermektir.

**✅ Doğru Yaklaşım:**
```solidity
for (uint256 i = 0; i < recipients.length; i++) {
    _mint(recipients[i], tokenId, amount, "");
}
```

**Neden Döngü?**
- Base L2 ağı üzerinde olduğumuz için gaz maliyeti kabul edilebilir
- OpenZeppelin'in `_mintBatch` tasarımı bizim use case'imize uymuyor
- Döngü kullanımı daha basit ve anlaşılır

**Gaz Optimizasyonu:**
- Base L2: Düşük gaz ücretleri
- 50 kişi için ~$2-5 maliyet
- ERC-721'e göre %70-80 daha ucuz

**Örnek Kullanım:**
```solidity
address[] memory recipients = [
    0x1234...abcd,
    0x5678...efgh,
    // ... 50 kişi
];

mintEvent(recipients, 1, 1); // Event ID: 1, Herkese 1 adet
```

---

### batchMint (Satır 106-117)

```solidity
function batchMint(address[] calldata recipients, uint256[] calldata ids, uint256[] calldata amounts, bytes memory data) public onlyOwner
```

**Ne İşe Yarar:**
- Farklı token ID'leri, farklı miktarlarda, birden fazla adrese basar
- Farklı etkinliklerden NFT'leri tek seferde dağıtmak için

**Neden Böyle:**
- **Esneklik**: Farklı etkinliklerden NFT'leri karışık dağıtım
- **Çoklu Token**: Bir kişiye birden fazla farklı NFT basma
- **Özel Senaryolar**: Karmaşık dağıtım ihtiyaçları için

**Kullanım Senaryoları:**
- Aynı kişiye birden fazla etkinlik NFT'si
- Farklı etkinliklerden özel paketler
- Toplu ödül dağıtımları

**Örnek Kullanım:**
```solidity
address[] memory recipients = [addr1, addr2, addr3];
uint256[] memory ids = [1, 2, 1]; // Farklı token ID'leri
uint256[] memory amounts = [1, 1, 1];

batchMint(recipients, ids, amounts, "");
```

---

### pause / unpause (Satır 122-131)

```solidity
function pause() public onlyOwner
function unpause() public onlyOwner
```

**Ne İşe Yarar:**
- Acil durumlarda tüm token transferlerini durdurur
- Sorun çözülünce normal işlemlere devam eder

**Neden Böyle:**
- **Güvenlik**: Hata veya saldırı durumunda anında durdurma
- **Risk Yönetimi**: Sorunlu durumları değerlendirmek için zaman kazanma
- **Kullanıcı Koruması**: Yanlış mint işlemlerini önleme

**Kullanım Senaryoları:**
- Kontrat hatası tespit edildiğinde
- Saldırı durumunda
- Metadata sorunlarında geçici durdurma

**Örnek Kullanım:**
```solidity
// Acil durum
pause();

// Sorun çözüldü
unpause();
```

---

### isValidEvent (Satır 138-140)

```solidity
function isValidEvent(uint256 tokenId) public view returns (bool)
```

**Ne İşe Yarar:**
- Token ID'nin geçerli bir etkinlik olup olmadığını kontrol eder
- View fonksiyonu (gas ücreti yok)

**Neden Böyle:**
- **Doğrulama**: Frontend ve diğer kontratlar için bilgi sorgulama
- **Şeffaflık**: Hangi token ID'lerin geçerli olduğunu görme
- **Basitlik**: Tek satırda kontrol

**Kullanım Senaryoları:**
- Frontend'de etkinlik listesi oluşturma
- Diğer kontratlardan kontrat kullanımı
- Topluluk tarafından doğrulama

---

### _update (Satır 145-152)

```solidity
function _update(address from, address to, uint256[] memory ids, uint256[] memory amounts) internal override(ERC1155, ERC1155Pausable, ERC1155Supply)
```

**Ne İşe Yarar:**
- Her token transferinden önce çağrılır
- Pausable ve Supply eklentilerinin işlevselliğini uygular

**Neden Böyle:**
- **Çoklu Miras**: Pausable ve Supply eklentileriyle uyumluluk
- **Transfer Hook**: Her transferde kontrol mekanizması
- **OpenZeppelin Pattern**: Standart override pattern'i

**İşlevleri:**
1. **Pausable Kontrolü**: `pause()` durumunda transferleri engeller
2. **Supply Takibi**: Arz miktarını günceller (`totalSupply()`)

---

## 🔒 Güvenlik Özellikleri

### 1. Ownable
- **Sadece owner mint edebilir**: Yetkisiz mint engellenir
- **Multi-sig önerilir**: Tek kişi riski azaltılır

### 2. Pausable
- **Acil durum durdurma**: Sorunlu durumları anında durdurma
- **Transfer kontrolü**: `_update` hook'u ile her transfer kontrol edilir

### 3. Validation
- **Event ID kontrolü**: `createEvent` öncesi mevcut kontrolü
- **Boş liste kontrolü**: `mintEvent` için recipient kontrolü
- **Miktar kontrolü**: Negatif veya sıfır miktar engellenir

### 4. ERC1155Burnable
- **Kullanıcı kontrolü**: Kullanıcılar kendi token'larını yakabilir
- **Hata düzeltme**: Owner yanlış mint'leri yakabilir

---

## 📄 Metadata Yapısı

### Pinata Klasör Yapısı
```
/odtu-blockchain-nfts/
  /1/
    - image.png
    - metadata.json (1.json)
  /2/
    - image.png
    - metadata.json (2.json)
```

### URI Formatı
```
Base URI: ipfs://<FOLDER_CID>/{id}.json
Örnek: ipfs://QmRvSoppQ5MKfsT4p5Snheae1DG3Af2NhYXWpKNZBvz2Eo/1.json
```

### Metadata Örneği
```json
{
  "name": "ODTÜ Blockchain: Solidity Bootcamp",
  "description": "Etkinlik açıklaması...",
  "image": "ipfs://<IMAGE_CID>/image.png",
  "attributes": [
    {"trait_type": "Event", "value": "Solidity Bootcamp"},
    {"trait_type": "Date", "value": "2024-01-15"}
  ]
}
```

---

## 🚀 Deployment Rehberi

### 1. Hazırlık
```bash
# Dependencies
npm install @openzeppelin/contracts
npm install hardhat
```

### 2. Base Sepolia Testnet
```bash
# Testnet'e deploy
npx hardhat run scripts/deploy.js --network baseSepolia
```

### 3. Base Mainnet
```bash
# Mainnet'e deploy
npx hardhat run scripts/deploy.js --network baseMainnet
```

### 4. İlk Kullanım
```solidity
// 1. Etkinlik oluştur
createEvent(1);

// 2. URI ayarla
setURI("ipfs://<CID>/{id}.json");

// 3. Dağıt
mintEvent(recipients, 1, 1);
```

---

## 📊 Maliyet Analizi

### Tek Seferlik
- **Kontrat Deploy**: ~$1-2
- **Pinata Yükleme**: Ücretsiz (500 dosya + 1GB)

### Her Etkinlik
- **createEvent**: ~$0.50
- **mintEvent (50 kişi)**: ~$2-5
- **Toplam/Etkinlik**: ~$3-6

### ERC-721 Karşılaştırması
- **ERC-721**: 50 kişi = 50 işlem = ~$15-20
- **ERC-1155**: 50 kişi = 1 işlem = ~$2-5
- **Tasarruf**: %70-80 daha ucuz

---

## 🎯 Kullanım Senaryoları

### Senaryo 1: İlk Etkinlik
```solidity
// 1. Etkinlik oluştur
createEvent(1);

// 2. Metadata yükle (Pinata)
// 3. URI ayarla
setURI("ipfs://QmRvSoppQ5MKfsT4p5Snheae1DG3Af2NhYXWpKNZBvz2Eo/{id}.json");

// 4. 50 kişiye dağıt
address[] memory recipients = [addr1, addr2, ..., addr50];
mintEvent(recipients, 1, 1);
```

### Senaryo 2: İkinci Etkinlik
```solidity
// 1. Yeni etkinlik
createEvent(2);

// 2. Yeni metadata yükle
// 3. URI güncelle (veya aynı klasörde tut)
setURI("ipfs://<NEW_CID>/{id}.json");

// 4. Dağıt
mintEvent(recipients, 2, 1);
```

### Senaryo 3: Acil Durum
```solidity
// Sorun tespit edildi
pause();

// Sorun çözüldü
unpause();
```

---

## 📝 Önemli Notlar

1. **Token ID**: Event ID ile aynıdır (1, 2, 3...)
2. **Metadata**: Pinata'da saklanır, kontrat üzerinde değil
3. **Batch Mint**: Döngü kullanılır, `_mintBatch` değil
4. **Base L2**: Düşük gaz maliyetleri
5. **Multi-sig**: Owner için çoklu imza cüzdan önerilir

---

## 🔗 Kaynaklar

- [OpenZeppelin ERC1155](https://docs.openzeppelin.com/contracts/4.x/erc1155)
- [Base Network](https://base.org/)
- [Pinata IPFS](https://www.pinata.cloud/)
- [ERC-1155 Standard](https://eips.ethereum.org/EIPS/eip-1155)

---

## 👥 Katkıda Bulunanlar

ODTÜ Blockchain Topluluğu

---

## 📄 Lisans

MIT License
