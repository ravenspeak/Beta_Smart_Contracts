// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IHippies {
  function hMagicFlowerAddr (  ) external view returns ( address );
  function CryptoHippiesAddr (  ) external view returns ( address );
  function hFoodAddr (  ) external view returns ( address );
  function hWeedSeedsAddr (  ) external view returns ( address );
  function hPeaceAddr (  ) external view returns ( address );
  function hMagicTreeAddr (  ) external view returns ( address );
  function hippies ( uint256 ) external view returns ( uint256 idx, uint256 id, uint8 level, uint256 age, string memory edition, uint256 bornAt, bool onSale, uint256 price );
  function approve ( address to, uint256 tokenId ) external;
  function balanceOf ( address owner ) external view returns ( uint256 );
  function bnbAddr (  ) external view returns ( address );
  function buy ( uint256 _tokenId ) external;
  function devWallet (  ) external view returns ( address );
  function evolvePrice (  ) external view returns ( uint256 );
  function getApproved ( uint256 tokenId ) external view returns ( address );
  function getOwned (  ) external view returns ( uint256[] memory );
  function grow ( uint256 _tokenIdx ) external;
  function growPrice (  ) external view returns ( uint256 );
  function initialize (  ) external;
  function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
  function liquidityWallet (  ) external view returns ( address );
  function listToSell ( uint256 _idx, uint256 _price ) external;
  function manualMint ( string memory _name, string memory _tokenURI, uint256 _level, uint256 _age, string memory _edition, address _owner ) external;
  function marketingWallet (  ) external view returns ( address );
  function migrate ( uint256 _tokenId ) external;
  function mintPrice (  ) external view returns ( uint256 );
  function mintWithFee ( string memory _name, string memory _tokenURI ) external;
  function name (  ) external view returns ( string memory );
  function owner (  ) external view returns ( address );
  function ownerOf ( uint256 tokenId ) external view returns ( address );
  function pancakeAddr (  ) external view returns ( address );
  function renounceOwnership (  ) external;
  function salariesWallet (  ) external view returns ( address );
  function safeMint ( address to, uint256 tokenId ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId, bytes memory _data ) external;
  function setHMagicFlowerAddr ( address ba ) external;
  function setCRyptoHippieAddr ( address aa ) external;
  function setHFoodAddr ( address pa ) external;
  function setHWeedSeedsAddr ( address sa ) external;
  function setHPeaceAddr ( address sa ) external;
  function setHMagicTreeAddr ( address wa ) external;
  function setApprovalForAll ( address operator, bool approved ) external;
  function setBNBAddr ( address ba ) external;
  function setDevWallet ( address dw ) external;
  function setEvolvePrice ( uint256 ep ) external;
  function setGrowPrice ( uint256 gp ) external;
  function setLiquidityWallet ( address lw ) external;
  function setMarketingWallet ( address mw ) external;
  function setMintPrice ( uint256 mp ) external;
  function setPancakeAddr ( address pa ) external;
  function setSalariesWallet ( address rw ) external;
  function setWCRyptoHippiesAddr ( address waa ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory );
  function tokenByIndex ( uint256 index ) external view returns ( uint256 );
  function tokenIdToName ( uint256 ) external view returns ( string memory );
  function tokenOfOwnerByIndex ( address owner, uint256 index ) external view returns ( uint256 );
  function tokenURI ( uint256 tokenId ) external view returns ( string memory );
  function totalSupply (  ) external view returns ( uint256 );
  function transferFrom ( address from, address to, uint256 tokenId ) external;
  function transferOwnership ( address newOwner ) external;
  function upgradeTo ( address newImplementation ) external;
  function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
  function wCRyptoHippiesAddr (  ) external view returns ( address );
  function withdrawFromSell ( uint256 _idx ) external;
  function getTypeIdByNftId (uint256 u) external view returns(uint256);
}