// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OpenClaiming, IERC20MintBurnable, CLAIM_TYPEHASH} from "../../src/OpenClaiming.sol";

contract OpenClaimingMock is OpenClaiming {
    constructor(
        IERC20MintBurnable _token,
        uint256 _tokenSpendingLimit,
        uint256 _spendingPeriodDuration,
        address _signer
    ) OpenClaiming(_token, _tokenSpendingLimit, _spendingPeriodDuration, _signer) {}

    function createDigest(uint256 _proofId, address _claimer, uint256 _amount) external view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(CLAIM_TYPEHASH, _proofId, _claimer, _amount)));
    }
}
