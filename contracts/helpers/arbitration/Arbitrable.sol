/**
 *  @authors: [@clesaege]
 *  @reviewers: [@remedcu]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

import './Arbitrator.sol';
import './IArbitrable.sol';

/** @title Arbitrable
 *  @author Clément Lesaege - <clement@lesaege.com>
 *  Arbitrable abstract contract.
 *  When developing arbitrable contracts, we need to:
 *  -Define the action taken when a ruling is received by the contract. We should do so in executeRuling.
 *  -Allow dispute creation. For this a function must:
 *      -Call arbitrator.createDispute.value(_fee)(_choices,_extraData);
 *      -Create the event Dispute(_arbitrator,_disputeID,_rulingOptions);
 */
abstract contract Arbitrable is IArbitrable {
  Arbitrator public arbitrator;

  uint256 public constant reclamationPeriod = 3 days;
  uint256 public constant arbitrationFeeDepositPeriod = 3 days;

  uint256 public reclaimedAt;

  enum ArbitrationStatus {
    INITIAL,
    RECLAIMED,
    DISPUTED,
    RESOLVED
  }
  ArbitrationStatus public arbitrationStatus;

  enum RulingOptions {
    SELLER_WINS,
    BUYER_WINS
  }
  uint256 constant numberOfRulingOptions = 2;

  uint256 constant metaEvidenceID = 0;
  uint256 constant evidenceGroupID = 0;

  /// @notice Event triggered when buyer reclaims their balance
  event Reclaimed();

  modifier onlyArbitrator {
    require(
      msg.sender == address(arbitrator),
      'Arbitrable: can only be called by the arbitrator'
    );
    _;
  }

  /** @dev Constructor. Choose the arbitrator.
   *  @param arbitrator_ The arbitrator of the contract.
   *  @param metaEvidence Meta evidence for the arbitrator.
   */
  constructor(Arbitrator arbitrator_, string memory metaEvidence) {
    arbitrator = arbitrator_;
    arbitrationStatus = ArbitrationStatus.INITIAL;

    emit MetaEvidence(metaEvidenceID, metaEvidence);
  }

  /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
   *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
   *  @param _disputeID ID of the dispute in the Arbitrator contract.
   *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
   */
  function rule(uint256 _disputeID, uint256 _ruling) public override onlyArbitrator {
    require(
      arbitrationStatus == ArbitrationStatus.DISPUTED,
      'Arbitrable: there should be dispute to execute a ruling'
    );

    require(_ruling <= numberOfRulingOptions, 'Arbitrable: ruling out of bounds');

    arbitrationStatus = ArbitrationStatus.RESOLVED;

    emit Ruling(Arbitrator(msg.sender), _disputeID, _ruling);
    _executeRuling(_disputeID, _ruling);
  }

  /** @dev
   */
  function submitEvidence(string memory evidence_) external virtual;

  /** @dev Execute a ruling of a dispute.
   *  @param _disputeID ID of the dispute in the Arbitrator contract.
   *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
   */
  function _executeRuling(uint256 _disputeID, uint256 _ruling) internal virtual;
}
