// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";

import {OPEN, AccessControl} from "../lib/open-token/src/OPEN.sol";
import {Openmesh} from "../lib/openmesh-admin/src/Openmesh.sol";
import {OpenClaimingMock} from "./mocks/OpenClaimingMock.sol";

contract OpenClaimingTest is Openmesh, Test {
    OPEN public erc20;
    OpenClaimingMock public openClaiming;

    uint256 constant signerPrivateKey = 0x1414;
    address signer = vm.addr(signerPrivateKey);

    error ProofAlreadyClaimed();
    error TokenSpendingLimitReached();
    error InvalidProof();
    error SenderIsNotOpenmeshAdmin();

    struct Claim {
        uint256 proofId;
        address claimer;
        uint256 amount;
    }

    function setUp() external {
        erc20 = new OPEN();
        openClaiming = new OpenClaimingMock(erc20, erc20.maxSupply(), type(uint256).max, signer);
        bytes32 MINT_ROLE = erc20.MINT_ROLE(); // This is also an external call, meaning that it will swallow any prank calls
        vm.prank(OPENMESH_ADMIN);
        erc20.grantRole(MINT_ROLE, address(openClaiming));
    }

    function test_claim(Claim calldata _claim) external {
        vm.assume(_claim.claimer != address(0)); // Zero address not allowed to recieve tokens
        vm.assume(_claim.amount < openClaiming.tokenSpendingLimit()); // Cannot claim more than the spending limit
        bytes32 digest = openClaiming.createDigest(_claim.proofId, _claim.claimer, _claim.amount);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);
        openClaiming.claim(v, r, s, _claim.proofId, _claim.claimer, _claim.amount);
        assertEq(erc20.balanceOf(_claim.claimer), _claim.amount);
    }

    function test_claim_revertIf_wrongSigner(Claim calldata _claim, uint248 _signerPrivateKey) external {
        vm.assume(_claim.claimer != address(0)); // Zero address not allowed to recieve tokens
        vm.assume(_claim.amount < openClaiming.tokenSpendingLimit()); // Cannot claim more than the spending limit
        vm.assume(_signerPrivateKey != 0);
        vm.assume(_signerPrivateKey != signerPrivateKey);
        bytes32 digest = openClaiming.createDigest(_claim.proofId, _claim.claimer, _claim.amount);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_signerPrivateKey, digest);

        vm.expectRevert(InvalidProof.selector);
        openClaiming.claim(v, r, s, _claim.proofId, _claim.claimer, _claim.amount);
    }

    function test_claim_revertIf_doubleClaim(Claim calldata _claim) external {
        vm.assume(_claim.claimer != address(0)); // Zero address not allowed to recieve tokens
        vm.assume(_claim.amount < openClaiming.tokenSpendingLimit()); // Cannot claim more than the spending limit
        bytes32 digest = openClaiming.createDigest(_claim.proofId, _claim.claimer, _claim.amount);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);
        openClaiming.claim(v, r, s, _claim.proofId, _claim.claimer, _claim.amount);

        vm.expectRevert(ProofAlreadyClaimed.selector);
        openClaiming.claim(v, r, s, _claim.proofId, _claim.claimer, _claim.amount);
    }

    function test_claim_tokenSpending(
        Claim[] calldata _claims,
        bool[] calldata _startNewPeriod,
        uint256 _tokenSpendingLimit,
        uint32 _spendingPeriodDuration
    ) external {
        vm.assume(_startNewPeriod.length >= _claims.length); // Need to know for each claim if we transaction to a new period or not
        vm.assume(_spendingPeriodDuration != 0); // Period needs to last at least 1 second

        uint256 maxSupply = erc20.maxSupply();
        for (uint256 i; i < _claims.length; i++) {
            vm.assume(_claims[i].claimer != address(0)); // Zero address not allowed to recieve tokens
            vm.assume(_claims[i].amount < maxSupply);
        }

        vm.prank(OPENMESH_ADMIN);
        openClaiming.updateSpendingLimit(_tokenSpendingLimit, _spendingPeriodDuration);

        uint256 totalSum;
        uint256 periodSum;
        for (uint256 i; i < _claims.length; i++) {
            if (_startNewPeriod[i]) {
                skip(_spendingPeriodDuration);
                periodSum = 0;
            }

            uint256 newTotalSum = totalSum + _claims[i].amount;
            uint256 newPeriodSum = periodSum + _claims[i].amount;

            if (newTotalSum > maxSupply) {
                // Cannot claim more tokens than max supply, all calls will revert
                break;
            }

            bytes32 digest = openClaiming.createDigest(i, _claims[i].claimer, _claims[i].amount);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);
            bool overSpendingLimit = newPeriodSum > _tokenSpendingLimit;
            if (overSpendingLimit) {
                vm.expectRevert(TokenSpendingLimitReached.selector);
            }
            openClaiming.claim(v, r, s, i, _claims[i].claimer, _claims[i].amount);

            if (!overSpendingLimit) {
                totalSum = newTotalSum;
                periodSum = newPeriodSum;

                assertEq(openClaiming.currentTokenSpending(), periodSum);
            }
        }
    }
}
