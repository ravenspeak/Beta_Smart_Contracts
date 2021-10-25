// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20.sol";

contract HippieJob is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;

    CountersUpgradeable.Counter private _tokenIdCounter;

    struct FeePair {
        uint256 fee;
        address receiver;
    }

    mapping(uint256 => FeePair) public feeMap;

    struct JobProps {
        uint256 typeID;
        string jobName;
        uint256 salaryRate;
        uint256 slots;
        address collateral;
        uint256 price;
        bool saleEnabled;
        string fullURI;
    }

    mapping(string => JobProps) public jProps;
    mapping(uint256 => string) public typeOfJobByNFTId;
    mapping(string => address) public collaterals;
    mapping(uint256 => uint256) public builtAtBlock;
    mapping(address => mapping(string => uint256)) public balancesbyTypeMap;
    bool public applyTaxes;
    event BuyJob(address buyer, address feeReceiver, uint256 price, uint256 nftId);
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {
        __ERC721_init("CryptoHippies-Job", "hJobs");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        setup();
    }

    function setup() public onlyOwner {
        applyTaxes = true;

        collaterals["wHIPPIE"] = address(
            0xc7EF8B763e6969f643558C91D0A7313577c1481f
        );
        collaterals["hMagicTree"] = address(
            0x680c7aa138F1c23cC5b1d70BDBce8D4c32A56d67
        );
        collaterals["hWeedSeed"] = address(
            0x77e74557B42139Bc9180a3d569A36cA282f7b116
        );
        collaterals["hPeace"] = address(
            0x6E67a8CfaDe59BF51ADB9CD5dE51e5eEa6fCFA0A
        );

        //HippieBus - Settings
        JobProps memory hippieBus;
        hippieBus.typeID = 1;
        hippieBus.jobName = "HippieBus";
        hippieBus.collateral = collaterals["hPeace"];
        hippieBus.price = 450;
        hippieBus.slots = 3;
        hippieBus.saleEnabled = true;
        hippieBus
            .fullURI = "https://storageapi.fleek.co/c62eb97d-92b1-41e4-8dfe-30f91c83bdbf-bucket/CryptoHippies/HippieBus.json";
        jProps["HippieBus"] = hippieBus;

        //HealersHouse - Settings
        JobProps memory hippieHealersHouse;
        hippieHealersHouse.typeID = 2;
        hippieHealersHouse.jobName = "HealersHouse";
        hippieHealersHouse.collateral = collaterals["hMagicTree"];
        hippieHealersHouse.price = 900;
        hippieHealersHouse.slots = 3;
        hippieHealersHouse.saleEnabled = true;
        hippieHealersHouse
            .fullURI = "https://storageapi.fleek.co/c62eb97d-92b1-41e4-8dfe-30f91c83bdbf-bucket/CryptoHippies/HealersHouse.json";
        jProps["HealersHouse"] = hippieHealersHouse;

        //WeedFarm - Settings
        JobProps memory hippieWeedFarm;
        hippieWeedFarm.typeID = 3;
        hippieWeedFarm.jobName = "WeedFarm";
        hippieWeedFarm.collateral = collaterals["hWeedSeed"];
        hippieWeedFarm.price = 1800;
        hippieWeedFarm.slots = 3;
        hippieWeedFarm.saleEnabled = true;
        hippieHealersHouse
            .fullURI = "https://storageapi.fleek.co/c62eb97d-92b1-41e4-8dfe-30f91c83bdbf-bucket/CryptoHippies/HippieWeedFarms.json";
        jProps["WeedFarm"] = hippieWeedFarm;

        //1-Play2Earn
        feeMap[1].receiver = 0x040E04C39F0f1B5700066754452107d5E599F31a;
        feeMap[1].fee = 50;
        //2-Liquidity
        feeMap[2].receiver = 0x75d8fCEDf117F64DB6031683f33Fe21cd3ca405A;
        feeMap[2].fee = 47;
        //3-Developers
        feeMap[3].receiver = 0x75d8fCEDf117F64DB6031683f33Fe21cd3ca405A;
        feeMap[3].fee = 0;
        //4-Marketing
        feeMap[4].receiver = 0xc8074f62a8AD7052b7666772b18ea35450Bb3e87;
        feeMap[4].fee = 0;
        //5-GameEcosys
        feeMap[5].receiver = 0x040E04C39F0f1B5700066754452107d5E599F31a;
        feeMap[5].fee = 1;
        //6-Burn
        feeMap[6].receiver = address(0xdEaD);
        feeMap[6].fee = 1;

    }

    function setJobProps(
        uint256 typeID,
        string memory jobName,
        uint256 salaryRate,
        uint256 slots,
        address collateral,
        uint256 price,
        bool isOnSale,
        string memory fullURI
    ) public onlyOwner {
        JobProps memory job;
        job.typeID = typeID;
        job.salaryRate = salaryRate;
        job.jobName = jobName;
        job.collateral = collateral;
        job.price = price;
        job.slots = slots;
        job.saleEnabled = isOnSale;
        job.fullURI = fullURI;
        jProps[jobName] = job;
    }

    function transferFrom(address from,address to,uint256 tokenId) public override (ERC721Upgradeable) {
        balancesbyTypeMap[from][typeOfJobByNFTId[tokenId]] -= 1;
        balancesbyTypeMap[to][typeOfJobByNFTId[tokenId]] += 1;
        super.transferFrom(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // function Mint(address to, string memory jobName) internal {
    //     uint256 currentNFTId = _tokenIdCounter.current();
    //     balancesbyTypeMap[to][jobName]++;
    //     builtAtBlock[currentNFTId] = block.number;
    //     typeOfJobByNFTId[currentNFTId] = jobName;
    //     _setTokenURI(currentNFTId, jProps[jobName].fullURI);
    //     _mint(to, currentNFTId);
    //     _tokenIdCounter.increment();
    // }

    function setBuiltBlock(uint256 blockNumber, uint256 jobID)
        public
        onlyOwner
    {
        builtAtBlock[jobID] = blockNumber;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //Our methods
    function saleEnabled(string memory jobName, bool status)
        public
        onlyOwner
    {
        jProps[jobName].saleEnabled = status;
    }

    function setPrice(string memory jobName, uint256 price_)
        public
        onlyOwner
    {
        jProps[jobName].price = price_;
    }

    function setCollateral(
        string memory jobName,
        address collateralAddress
    ) public onlyOwner {
        jProps[jobName].collateral = collateralAddress;
    }

    function setPlay2Earn(address addr, uint256 fee) public onlyOwner {
        feeMap[1].receiver = addr;
        feeMap[1].fee = fee;
    }

    function getPlay2Earn() public view virtual returns (address, uint256) {
        return (feeMap[1].receiver, feeMap[1].fee);
    }

    function setLiquidityFee(address addr, uint256 fee) public onlyOwner {
        feeMap[2].receiver = addr;
        feeMap[2].fee = fee;
    }

    function setMarketingFee(address addr, uint256 fee) public onlyOwner {
        feeMap[4].receiver = addr;
        feeMap[4].fee = fee;
    }

    function setDevelopersFee(address addr, uint256 fee) public onlyOwner {
        feeMap[3].receiver = addr;
        feeMap[3].fee = fee;
    }

    function setGameEcosysFee(address addr, uint256 fee) public onlyOwner {
        feeMap[5].receiver = addr;
        feeMap[5].fee = fee;
    }

    function setBurnFee(address addr, uint256 fee) public onlyOwner {
        feeMap[6].receiver = addr;
        feeMap[6].fee = fee;
    }

    function balanceOf(string memory jobTypeName, address own)
        public
        view
        virtual
        returns (uint256)
    {
        require(
            own != address(0),
            "ERC721: balance query for the zero address"
        );
        uint256 value = balancesbyTypeMap[own][jobTypeName];
        return value;
    }
    function getTypeIDByNftID(uint256 nftID) public view returns (uint256 typeID) {
        return jProps[typeOfJobByNFTId[nftID]].typeID;
    }
    function Buy(string memory jobName) public {
        address buyer = address(msg.sender);
        uint256 price = jProps[jobName].price;
        IERC20 collateralToken = IERC20(jProps[jobName].collateral);
        uint256 senderBalance = collateralToken.balanceOf(buyer);
        uint256 allowance = collateralToken.allowance(buyer, address(this));

        require(jProps[jobName].saleEnabled, "Sales of are disabled");
        require(senderBalance >= price, "Insuficient collateral");
        require(allowance >= price, "Insuficient collateral allowance");
        
        collateralToken.transferFrom(buyer, feeMap[1].receiver, price); 
        //Mint
        uint256 currentNFTId = _tokenIdCounter.current();
        balancesbyTypeMap[buyer][jobName]++;
        builtAtBlock[currentNFTId] = block.number;
        typeOfJobByNFTId[currentNFTId] = jobName;
        _mint(buyer, currentNFTId);
        _setTokenURI(currentNFTId, jProps[jobName].fullURI);
        emit BuyJob(buyer, feeMap[1].receiver, price, _tokenIdCounter.current());
        _tokenIdCounter.increment();

    // if(applyTaxes){
    //     collateralToken.transferFrom(
    //         buyer,
    //         feeMap[1].receiver,
    //         (price.mul(feeMap[1].fee)).div(100)
    //     );
    //     collateralToken.transferFrom(
    //         buyer,
    //         feeMap[2].receiver,
    //         (price.mul(feeMap[2].fee)).div(100)
    //     );
    //     collateralToken.transferFrom(
    //         buyer,
    //         feeMap[3].receiver,
    //         (price.mul(feeMap[3].fee)).div(100)
    //     );
    //     collateralToken.transferFrom(
    //         buyer,
    //         feeMap[4].receiver,
    //         (price.mul(feeMap[4].fee)).div(100)
    //     );
    //     collateralToken.transferFrom(
    //         buyer,
    //         feeMap[5].receiver,
    //         (price.mul(feeMap[5].fee)).div(100)
    //     );
    //     collateralToken.transferFrom(
    //         buyer,
    //         feeMap[6].receiver,
    //         (price.mul(feeMap[6].fee)).div(100)
    //     );
    //     Mint(buyer, jobName);
    // }
    // else
    // {
    }
}