//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../helpers/Deployable.sol";

/*
 * @title Base trade contract
 * @author Alex Klos
 * @notice This provides context for other trade contracts and utilities
 */
abstract contract BaseTrade is Deployable {
    address public buyer;
    address public seller;

    modifier onlyBuyer() {
        require(msg.sender == buyer, "BaseTrade: caller is not the buyer");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "BaseTrade: caller is not the seller");
        _;
    }

    modifier eitherBuyerOrSeller() {
        require(
            msg.sender == buyer || msg.sender == seller,
            "BaseTrade: caller is not the buyer or seller"
        );
        _;
    }

    constructor(address buyer_, address seller_) {
        buyer = buyer_;
        seller = seller_;
    }
}
