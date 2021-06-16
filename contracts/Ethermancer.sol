//SPDX-Licence-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './helpers/Deployable.sol';
import './trade/SimpleTrade.sol';
import './bets/SimpleBet.sol';

contract Ethermancer is Ownable {
  using Strings for uint256;

  uint256 public simpleTradeFee = 1 gwei;
  uint256 public simpleBetFee = 1 gwei;

  mapping(address => Deployable[]) private deployedContracts;

  event ContractDeployed(string contractName, address contractAddress, address creator);

  function deploySimpleTrade(
    address buyer,
    address seller,
    uint256 price,
    string memory metaEvidence
  ) external payable returns (address) {
    require(
      msg.value >= simpleTradeFee,
      string(abi.encodePacked('SimpleTrade fee:', ' ', simpleTradeFee.toString(), ' ', 'wei'))
    );
    SimpleTrade newTrade = new SimpleTrade(buyer, seller, price, metaEvidence);
    deployedContracts[msg.sender].push(newTrade);
    emit ContractDeployed('SimpleTrade', address(newTrade), msg.sender);
    payable(owner()).transfer(msg.value);

    return address(newTrade);
  }

  function updateSimpleTradeFee(uint256 fee) external onlyOwner {
    simpleTradeFee = fee;
  }

  function deploySimpleBet(
    address partyA,
    address partyB,
    uint256 pricePartyA,
    uint256 pricePartyB,
    uint256 deadline,
    string memory metaEvidence
  ) external payable returns (address) {
    require(
      msg.value >= simpleBetFee,
      string(abi.encodePacked('SimpleBet fee:', ' ', simpleBetFee.toString(), ' ', 'wei'))
    );
    SimpleBet newBet = new SimpleBet(
      partyA,
      partyB,
      pricePartyA,
      pricePartyB,
      deadline,
      metaEvidence
    );
    deployedContracts[msg.sender].push(newBet);
    emit ContractDeployed('SimpleBet', address(newBet), msg.sender);
    payable(owner()).transfer(msg.value);

    return address(newBet);
  }

  function updateSimpleBetFee(uint256 fee) external onlyOwner {
    simpleBetFee = fee;
  }

  function getDeployedContracts(address user) public view returns (Deployable[] memory) {
    return deployedContracts[user];
  }
}
