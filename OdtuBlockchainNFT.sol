// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/**
 * @title OdtuBlockchainNFT
 * @dev ODTU Blockchain Topluluğu etkinlikleri için hatıra NFT'leri üreten ERC1155 kontratı.
 * Her etkinlik için ayrı ID'li NFT'ler, aynı etkinlikteki tüm katılımcılar aynı NFT'ye sahip olur.
 * 
 * Özellikler:
 * - ERC1155: Çoklu token standardı, toplu işlemler için verimli
 * - Ownable: Sadece sahip mint edebilir
 * - Pausable: Acil durumlarda transferleri durdurma
 * - ERC1155Burnable: Kullanıcılar token'larını yakabilir
 * - ERC1155Supply: Her token ID'sinin toplam arzını takip eder
 * - Batch Mint: Gaz verimli toplu mint işlemleri
 */
contract OdtuBlockchainNFT is ERC1155, Ownable, Pausable, ERC1155Burnable, ERC1155Supply {
    
    // Sadece hangi token ID'lerin (etkinliklerin) oluşturulduğunu takip edin
    mapping(uint256 => bool) public eventTokenIds;
    
    // Events
    event EventCreated(uint256 indexed tokenId);
    event EventMinted(uint256 indexed tokenId, address[] recipients, uint256 amount);
    
    /**
     * @dev Kontrat oluşturucu
     * @param initialOwner Kontratın ilk sahibi (multi-sig cüzdan önerilir)
     * @param baseURI_ Tüm token'ların metadata'si için temel URI
     *                 Format: ipfs://<FOLDER_CID>/{id}.json
     */
    constructor(address initialOwner, string memory baseURI_) ERC1155(baseURI_) {
        _transferOwnership(initialOwner);
    }
    
    /**
     * @dev Tüm token türleri için yeni bir temel URI belirler
     * @param newuri Yeni base URI (ipfs://<FOLDER_CID>/{id}.json formatında)
     */
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
    
    /**
     * @dev Yeni bir etkinlik NFT'si (token ID) oluşturur
     * @param tokenId Etkinlik ID'si (örn: 1, 2, 3...)
     */
    function createEvent(uint256 tokenId) public onlyOwner {
        require(!eventTokenIds[tokenId], "Token ID (event) already exists");
        require(tokenId > 0, "Token ID must be greater than 0");
        
        // Sadece bu ID'nin geçerli olduğunu kaydet
        eventTokenIds[tokenId] = true;
        
        emit EventCreated(tokenId);
    }
    
    /**
     * @dev Belirtilen bir adrese, belirli bir ID ve miktarda token basar
     * @param to Alıcı adres
     * @param id Token ID (eventId'den türetilmiş)
     * @param amount Basılacak miktar
     * @param data Ek veri
     */
    function mint(address to, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        _mint(to, id, amount, data);
    }
    
    /**
     * @dev Bir etkinlik için toplu mint işlemi
     * @param recipients Alıcı adresleri listesi
     * @param tokenId Etkinlik token ID'si
     * @param amount Her alıcıya basılacak miktar
     */
    function mintEvent(
        address[] calldata recipients,
        uint256 tokenId,
        uint256 amount
    ) public onlyOwner {
        require(eventTokenIds[tokenId], "Token ID (event) does not exist");
        require(recipients.length > 0, "No recipients");
        require(amount > 0, "Amount must be greater than 0");
        
        // DÜZELTME: _mintBatch yerine _mint döngüsü
        for (uint256 i = 0; i < recipients.length; i++) {
            // Her alıcıya tek tek mint et
            _mint(recipients[i], tokenId, amount, "");
        }
        
        emit EventMinted(tokenId, recipients, amount);
    }
    
    /**
     * @dev Birden fazla alıcıya, birden fazla token türünü toplu olarak basar
     * @param recipients Alıcı adresleri
     * @param ids Token ID'leri
     * @param amounts Miktarlar
     * @param data Ek veri
     */
    function batchMint(
        address[] calldata recipients,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) public onlyOwner {
        require(recipients.length == ids.length && ids.length == amounts.length, "Array lengths must match");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], ids[i], amounts[i], data);
        }
    }
    
    /**
     * @dev Acil durumlarda tüm token transferlerini durdurur
     */
    function pause() public onlyOwner {
        _pause();
    }
    
    /**
     * @dev Duraklatılmış token transferlerini yeniden başlatır
     */
    function unpause() public onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Token ID'nin geçerli bir etkinlik olup olmadığını kontrol eder
     * @param tokenId Token ID
     * @return Geçerli etkinlik mi
     */
    function isValidEvent(uint256 tokenId) public view returns (bool) {
        return eventTokenIds[tokenId];
    }
    
    /**
     * @dev _beforeTokenTransfer kancası, Pausable ve Supply eklentilerinin işlevselliğini uygular
     */
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal override(ERC1155, ERC1155Pausable, ERC1155Supply) {
        super._update(from, to, ids, amounts);
    }
}
