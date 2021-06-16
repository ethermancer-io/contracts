//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../helpers/Deployable.sol";
import "../helpers/arbitration/Arbitrable.sol";
import "../helpers/arbitration/Arbitrator.sol";

/*
 * @title Simple bet contract
 * @author Alex Klos - <alexklos@prohobo.dev>
 * @notice This is a simple betting contract for one-off bets
 */
contract SimpleBet is Deployable, Arbitrable {
    enum Status {
        INITIAL,
        STARTED,
        ARBITRATING,
        COMPLETED,
        CANCELLED
    }
    Status public status;

    address public partyA;
    address public partyB;
    uint256 public pricePartyA;
    uint256 public pricePartyB;
    uint256 public deadline;

    uint256 public balancePartyA;
    uint256 public balancePartyB;
    uint256 public balanceArbitrationFee;
    uint256 public createdAt;

    modifier onlyBettingParties() {
        require(
            msg.sender == partyA || msg.sender == partyB,
            "SimpleBet: caller is not part of the bet"
        );
        _;
    }

    /// @notice
    event Deposited(address indexed depositor);

    /// @notice
    event BetStarted();

    /// @notice
    event BetArbitrationStarted();

    /// @notice Even triggered when bet is completed
    /// @param winner the address that won the bet
    event Completed(address indexed winner);

    constructor(
        address partyA_,
        address partyB_,
        uint256 pricePartyA_,
        uint256 pricePartyB_,
        uint256 deadline_,
        string memory metaEvidence
    )
        Arbitrable(
            Arbitrator(0x5bAdCEE6a4E3Dc11E6441400982676b799E1F514),
            metaEvidence
        )
    {
        partyA = partyA_;
        partyB = partyB_;
        pricePartyA = pricePartyA_;
        pricePartyB = pricePartyB_;
        deadline = deadline_;

        balancePartyA = 0;
        balancePartyB = 0;
        status = Status.INITIAL;
        createdAt = block.timestamp;
    }

    /// @notice
    function deposit() external payable onlyBettingParties {
        require(
            status == Status.INITIAL,
            "SimpleBet: bet is not in initial phase"
        );

        uint256 fee = arbitrator.arbitrationCost("");
        uint256 halfOfFee = fee / 2;
        uint256 amount = msg.value - halfOfFee;

        if (msg.sender == partyA) {
            require(
                amount == pricePartyA,
                "SimpleBet: must pay required amount (pricePartyA + fee / 2)"
            );

            balancePartyA += amount;
        } else {
            require(
                amount == pricePartyB,
                "SimpleBet: must pay required amount (pricePartyB + fee / 2)"
            );

            balancePartyB += amount;
        }

        balanceArbitrationFee += halfOfFee;

        if (
            balancePartyA == pricePartyA &&
            balancePartyB == pricePartyB &&
            balanceArbitrationFee == fee
        ) {
            status = Status.STARTED;
            emit BetStarted();
        } else {
            emit Deposited(msg.sender);
        }
    }

    /// @notice
    function submitEvidence(string memory evidence)
        external
        override
        onlyBettingParties
    {
        require(
            arbitrationStatus != ArbitrationStatus.RESOLVED,
            "SimpleBet: bet is resolved"
        );

        emit Evidence(arbitrator, evidenceGroupID, msg.sender, evidence);
    }

    /// @notice
    function resolveBet() external {
        require(
            status == Status.STARTED,
            "SimpleBet: parties haven't paid their bets yet"
        );

        require(
            block.timestamp >= deadline,
            "SimpleBet: deadline hasn't passed yet"
        );

        uint256 disputeId = arbitrator.createDispute{
            value: balanceArbitrationFee
        }(numberOfRulingOptions, "");

        arbitrationStatus = ArbitrationStatus.DISPUTED;
        emit Dispute(arbitrator, disputeId, metaEvidenceID, evidenceGroupID);

        status = Status.ARBITRATING;
        emit BetArbitrationStarted();
    }

    /// @notice
    function _executeRuling(uint256 disputeID, uint256 ruling)
        internal
        override
    {
        bool partyAWins = ruling == uint256(RulingOptions.SELLER_WINS);

        if (partyAWins) {
            payable(partyA).transfer(balancePartyA + balancePartyB);
        } else {
            payable(partyB).transfer(balancePartyA + balancePartyB);
        }

        status = Status.COMPLETED;
        if (partyAWins) {
            emit Completed(partyA);
        } else {
            emit Completed(partyB);
        }
    }
}
