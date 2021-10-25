// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract IHCryptoHippies {
    function approve(address spender, uint256 amount)
        external
        virtual
        returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        virtual
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual returns (bool);

    function allowance(address owner, address spender)
        external
        view
        virtual
        returns (uint256);

    function balanceOf(address account) external view virtual returns (uint256);
}