// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {EIP712} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import {IERC20MintBurnable} from "../lib/open-token/src/IERC20MintBurnable.sol";
import {Openmesh} from "../lib/openmesh-admin/src/Openmesh.sol";
import {IOpenClaiming} from "./IOpenClaiming.sol";

bytes32 constant CLAIM_TYPEHASH = keccak256("Claim(uint256 proofId,address claimer,uint256 amount)");

contract OpenClaiming is Ownable, EIP712, Openmesh, IOpenClaiming {
    IERC20MintBurnable public immutable token;
    uint256 public tokenSpendingLimit;
    uint256 public spendingPeriodDuration;
    mapping(uint256 proofId => bool claimed) public proofClaimed;

    uint256 public currentTokenSpending;
    uint256 public currentSpendingPeriod;

    constructor(
        IERC20MintBurnable _token,
        uint256 _tokenSpendingLimit,
        uint256 _spendingPeriodDuration,
        address _signer
    ) Ownable(_signer) EIP712("OpenClaiming", "1") {
        token = _token;
        tokenSpendingLimit = _tokenSpendingLimit;
        spendingPeriodDuration = _spendingPeriodDuration;
    }

    /// @inheritdoc IOpenClaiming
    function claim(uint8 _v, bytes32 _r, bytes32 _s, uint256 _proofId, address _claimer, uint256 _amount) external {
        if (proofClaimed[_proofId]) {
            revert ProofAlreadyClaimed();
        }

        uint256 spendingPeriod = block.timestamp / spendingPeriodDuration;
        uint256 tokenSpending = _amount;
        if (spendingPeriod == currentSpendingPeriod) {
            // Withing the same spending period
            tokenSpending += currentTokenSpending;
        }
        if (tokenSpending > tokenSpendingLimit) {
            revert TokenSpendingLimitReached();
        }

        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(CLAIM_TYPEHASH, _proofId, _claimer, _amount))), _v, _r, _s
        );
        if (signer != owner()) {
            revert InvalidProof();
        }

        token.mint(_claimer, _amount);
        emit TokensClaimed(_claimer, _amount);

        proofClaimed[_proofId] = true;
        if (currentSpendingPeriod != spendingPeriod) {
            currentSpendingPeriod = spendingPeriod;
        }
        if (currentTokenSpending != tokenSpending) {
            currentTokenSpending = tokenSpending;
        }
    }

    /// @inheritdoc IOpenClaiming
    function updateSpendingLimit(uint256 _tokenSpendingLimit, uint256 _spendingPeriodDuration) external {
        if (msg.sender != OPENMESH_ADMIN) {
            revert SenderIsNotOpenmeshAdmin();
        }

        tokenSpendingLimit = _tokenSpendingLimit;
        spendingPeriodDuration = _spendingPeriodDuration;
    }
}
