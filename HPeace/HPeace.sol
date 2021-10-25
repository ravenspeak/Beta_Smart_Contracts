// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20.sol";

contract HPeace is
    Initializable,
    ERC20Upgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;

    struct FeePair {
        uint256 fee;
        address receiver;
    }

    bool public saleEnabled_;
    uint256 public price;
    address public collateral;

    mapping(uint256 => FeePair) public feeMap;

    function initialize() public initializer {
        __ERC20_init("CryptoHippies-Peace", "hPeace");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        setup();
    }
    function setup() public onlyOwner {
        saleEnabled_ = false;
        price = 1;
        //CryptoHippies
        collateral = address(0xc7EF8B763e6969f643558C91D0A7313577c1481f);
        _mint(msg.sender, 1 * 10**decimals());

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
        feeMap[5].receiver = 0x75d8fCEDf117F64DB6031683f33Fe21cd3ca405A;
        feeMap[5].fee = 1;
        //6-Burn
        feeMap[6].receiver = address(0xdEaD);
        feeMap[6].fee = 1;
    }
    function getImplementation() public virtual returns (address) {
        return super._getImplementation();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    //New

    function saleEnabled(bool status) public onlyOwner {
        saleEnabled_ = status;
    }

    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function setCollateral(address collateralAddress) public onlyOwner {
        collateral = collateralAddress;
    }

    function getCollateral() public view returns (address) {
        return collateral;
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

    function Buy(address buyer, uint256 amount) public {
        uint256 totalBuy = amount.mul(price);
        IERC20 collateralToken = IERC20(collateral);
        uint256 senderBalance = collateralToken.balanceOf(buyer);
        uint256 allowance = collateralToken.allowance(buyer, address(this));

        require(saleEnabled_, "Sales disabled");
        require(senderBalance >= totalBuy, "Insuficient collateral");
        require(allowance >= totalBuy, "Insuficient collateral allowance");

        collateralToken.transferFrom(
            buyer,
            feeMap[1].receiver,
            (totalBuy.mul(feeMap[1].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[2].receiver,
            (totalBuy.mul(feeMap[2].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[3].receiver,
            (totalBuy.mul(feeMap[3].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[4].receiver,
            (totalBuy.mul(feeMap[4].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[5].receiver,
            (totalBuy.mul(feeMap[5].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[6].receiver,
            (totalBuy.mul(feeMap[6].fee)).div(100)
        );

        _mint(buyer, amount);
    }
}