// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTFixedMarketPlace is IERC721Receiver, ReentrancyGuard {

  /////////////////////
  //   List struct   //
  /////////////////////
  struct List {
    uint256 tokenId;
    address payable NFTSeller;
    address payable thisAddress;
    uint256 NFTPrice;
    bool isSold;
  }

  address payable thisAddress;
  // listingFee is 1 ether.
  uint256 listingFee = 1 ether;

  mapping(uint256 => List) public vaultItems;

  /////////////////////
  //  EVENT NFTList  //
  /////////////////////

  event NFTListCreated (
    uint256 indexed tokenId,
    address NFTSeller,
    address thisAddress,
    uint256 NFTPrice,
    bool isSold
  );

  //Listed NFT Price
  function getListNFTPrice() public view returns (uint256) {
    return listingFee;
  }

  ERC721A nft;

   constructor(ERC721A _nft) {
    thisAddress = payable(msg.sender);
    nft = _nft;
  }

  function listSale(uint256 tokenId, uint256 NFTPrice) public payable nonReentrant {
      require(nft.ownerOf(tokenId) == msg.sender, "Not your NFT!!!");
      require(vaultItems[tokenId].tokenId == 0, "This NFT is already listed!");
      require(NFTPrice > 0, "!Amount over than 0!");
      require(msg.value == listingFee, "!transfer 0.0025 eth!");
      
      vaultItems[tokenId] =  List(tokenId, payable(msg.sender), payable(address(this)), NFTPrice, false);
      nft.transferFrom(msg.sender, address(this), tokenId);
      emit NFTListCreated(tokenId, msg.sender, address(this), NFTPrice, false);
  }

  function buyNft(uint256 tokenId) public payable nonReentrant {
      uint256 NFTPrice = vaultItems[tokenId].NFTPrice;
      require(msg.value == NFTPrice, "!msg.value is not same with NFTPrice!");
      vaultItems[tokenId].NFTSeller.transfer(msg.value);
      //Add your owner address, get comission
      payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4).transfer(listingFee);
      nft.transferFrom(address(this), msg.sender, tokenId);
      vaultItems[tokenId].isSold = true;
      delete vaultItems[tokenId];
  }

  function cancelSale(uint256 tokenId) public nonReentrant {
      require(vaultItems[tokenId].NFTSeller == msg.sender, "!NFT is not yours!");
      //Add your owner address, get comission
      payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4).transfer(listingFee);
      nft.transferFrom(address(this), msg.sender, tokenId);
      delete vaultItems[tokenId];
  }

 function nftListings() public view returns (List[] memory) {
    uint256 nftCount = nft.totalSupply();
    uint currentIndex = 0;
    List[] memory items = new List[](nftCount);
    for (uint i = 0; i < nftCount; i++) {
      // (vaultItems[i + 1]) 1번부터 먹게되어있어서 tokenid가 0부터 시작하면 vaultItems[i]로 만들어야 함!
        if (vaultItems[i].thisAddress == address(this)) {
        uint currentId = i;
        List storage currentItem = vaultItems[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send nfts to Vault directly");
      return IERC721Receiver.onERC721Received.selector;
    }

}