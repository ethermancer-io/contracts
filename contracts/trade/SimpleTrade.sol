//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import './BaseTrade.sol';
import '../helpers/arbitration/Arbitrable.sol';
import '../helpers/arbitration/Arbitrator.sol';

/*
 * @title Simple trade contract
 * @author Alex Klos - <alexklos@prohobo.dev>
 * @notice This is a simple escrow service for one-off trades
 */
contract SimpleTrade is BaseTrade, Arbitrable {
  enum Status {
    INITIAL,
    PAID,
    SUBMITTED,
    COMPLETED,
    CANCELLED
  }
  Status public status;

  uint256 public price;
  uint256 public balance;
  uint256 public createdAt;
  uint256 public submittedAt;

  /// @notice Even triggered when trade is completed
  /// @param initiator the address that triggered the cancellation
  event Completed(address indexed initiator);

  /// @notice Event triggered when either party cancels the trade
  /// @param initiator the address that triggered the cancellation
  event Cancelled(address indexed initiator);

  /// @notice Event triggered when agreed service is submitted by the seller
  event Submitted();

  /// @notice
  /// @param weiAmount the amount added to the deposit
  event Deposited(uint256 weiAmount);

  /// @notice
  event FullPricePaid();

  /// @notice
  /// @param payee the address that withdrew funds
  /// @param weiAmount the amount withdrawn
  event Withdrawn(address indexed payee, uint256 weiAmount);

  constructor(
    address buyer_,
    address seller_,
    uint256 price_,
    string memory metaEvidence
  )
    BaseTrade(buyer_, seller_)
    Arbitrable(Arbitrator(0x5bAdCEE6a4E3Dc11E6441400982676b799E1F514), metaEvidence)
  {
    price = price_;

    balance = 0;
    status = Status.INITIAL;
    createdAt = block.timestamp;
  }

  /// @notice Add funds to deposit
  function deposit() public payable onlyBuyer {
    uint256 amount = msg.value;
    balance += amount;
    emit Deposited(amount);

    if (balance >= price) {
      status = Status.PAID;
      emit FullPricePaid();
    }
  }

  /// @notice
  function submit() external onlySeller {
    require(status == Status.PAID, 'SimpleTrade: trade price has not been paid yet');

    submittedAt = block.timestamp;

    status = Status.SUBMITTED;
    emit Submitted();
  }

  /// @notice
  function confirm() external onlyBuyer {
    require(
      status == Status.SUBMITTED && arbitrationStatus == ArbitrationStatus.INITIAL,
      'SimpleTrade: trade is not in submitted state'
    );

    _completeTrade();
  }

  /// @notice
  function reclaim() external payable onlyBuyer {
    require(status == Status.SUBMITTED, 'SimpleTrade: trade is not in submitted state');

    require(
      arbitrationStatus == ArbitrationStatus.INITIAL ||
        arbitrationStatus == ArbitrationStatus.RECLAIMED,
      'SimpleTrade: arbitration is not in initial or reclaimed state'
    );

    require(
      block.timestamp - submittedAt <= reclamationPeriod,
      'SimpleTrade: reclamation period ended'
    );

    if (arbitrationStatus == ArbitrationStatus.INITIAL) {
      require(
        msg.value == arbitrator.arbitrationCost(''),
        "SimpleTrade: can't reclaim without depositing arbitration fee"
      );

      balance += msg.value;
      reclaimedAt = block.timestamp;
      arbitrationStatus = ArbitrationStatus.RECLAIMED;
    } else {
      require(
        block.timestamp - reclaimedAt > arbitrationFeeDepositPeriod,
        'SimpleTrade: seller still has time to challenge reclaim'
      );

      _cancelTrade();
    }
  }

  /// @notice
  function challengeReclaim() external payable onlySeller {
    require(
      arbitrationStatus == ArbitrationStatus.RECLAIMED,
      'SimpleTrade: arbitration is not in reclaimed state'
    );

    require(
      msg.value == arbitrator.arbitrationCost(''),
      "SimpleTrade: can't challenge reclaim without paying arbitration fee"
    );

    uint256 disputeId = arbitrator.createDispute{ value: msg.value }(numberOfRulingOptions, '');

    arbitrationStatus = ArbitrationStatus.DISPUTED;

    emit Dispute(arbitrator, disputeId, metaEvidenceID, evidenceGroupID);
  }

  /// @notice
  function submitEvidence(string memory evidence) external override eitherBuyerOrSeller {
    require(arbitrationStatus != ArbitrationStatus.RESOLVED, 'SimpleTrade: trade is resolved');

    emit Evidence(arbitrator, evidenceGroupID, msg.sender, evidence);
  }

  /// @notice
  function cancel() external eitherBuyerOrSeller {
    require(
      status == Status.INITIAL || status == Status.PAID,
      "SimpleTrade: can't cancel trade once it's submitted"
    );

    require(
      msg.sender == seller || (msg.sender == buyer && status != Status.PAID),
      "SimpleTrade: can't cancel once full price has been paid"
    );

    _cancelTrade();
  }

  /// @notice Sends deposited funds to seller and ends contract
  function _completeTrade() private {
    payable(seller).transfer(balance);
    emit Withdrawn(seller, balance);

    status = Status.COMPLETED;
    emit Completed(msg.sender);
  }

  /// @notice Sends deposited funds back to buyer and ends contract
  function _cancelTrade() private {
    payable(buyer).transfer(balance);
    emit Withdrawn(buyer, balance);

    status = Status.CANCELLED;
    emit Cancelled(msg.sender);
  }

  /// @notice
  function _executeRuling(uint256 disputeID, uint256 ruling) internal override {
    if (ruling == uint256(RulingOptions.BUYER_WINS)) {
      _cancelTrade();
    } else {
      _completeTrade();
    }
  }
}
