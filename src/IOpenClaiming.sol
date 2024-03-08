// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOpenClaiming {
    error ProofAlreadyClaimed();
    error TokenSpendingLimitReached();
    error InvalidProof();

    error SenderIsNotOpenmeshAdmin();

    event TokensClaimed(address indexed account, uint256 amount);

    /// Claim your tokens, with a proof granted to you from our server for performing a certain action.
    /// @param _v V component of the server proof signature.
    /// @param _r R component of the server proof signature.
    /// @param _s S component of the server proof signature.
    /// @param _proofId Unique identifier of the proof.
    /// @param _claimer To which address the tokens are sent.
    /// @param _amount How many tokens are sent.
    function claim(uint8 _v, bytes32 _r, bytes32 _s, uint256 _proofId, address _claimer, uint256 _amount) external;

    /// Changes how many tokens this contract is allowed to mint (spend) withing a single spending period.
    /// @param _tokenSpendingLimit How many tokens are allowed to be minted by this contract.
    /// @param _spendingPeriodDuration How long a spending period lasts.
    /// @dev THe spending period is a hard cut. Every spending duration seconds (starting from unix 0) the current spending will reset to 0.
    function updateSpendingLimit(uint256 _tokenSpendingLimit, uint256 _spendingPeriodDuration) external;
}
