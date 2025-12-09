// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from 'forge-std/Test.sol';
import { MyGovernor } from '../src/MyGovernor.sol';
import { GovToken } from '../src/GovToken.sol';
import { TimeLock } from '../src/TimeLock.sol';
import { Box } from '../src/Box.sol';
import { console2 } from 'forge-std/console2.sol';

contract MyGovernorTest is Test {
    GovToken token;
    TimeLock timelock;
    MyGovernor governor;
    Box box;

    uint256 public constant MIN_DELAY = 3600; // 1 hour - after a vote passes, you have 1 hour before you can enact
    uint256 public constant QUORUM_PERCENTAGE = 4; // Need 4% of voters to pass
    uint256 public constant VOTING_PERIOD = 50400; // This is how long voting lasts
    uint256 public constant VOTING_DELAY = 1; // How many blocks till a proposal vote becomes active

    address[] proposers;
    address[] executors;

    bytes[] functionCalls;
    address[] addressesToCall;
    uint256[] values;

    address public constant VOTER = address(1);

    function setUp() public {
        // Deploy the governance token and mint tokens to the voter
        token = new GovToken(address(this), 'GovToken', 'GTK');
        token.mint(VOTER, 100e18);

        // Delegate voting power to the voter
        // OpenZeppelin's ERC20Votes contract requires delegation for a token holder to have voting power.
        // This delegation can be performed by any token holder, as the contract does not require the caller to be the owner of the token contract.
        // In this case, the VOTER address is delegating its own voting power to itself, enabling it to participate in governance.
        vm.prank(VOTER);
        token.delegate(VOTER);

        // Deploy the timelock and governor contracts
        // The TimeLock contract enforces a delay between when a proposal is passed and when it can be executed.
        // This delay allows token holders to review and respond to governance decisions before execution.
        // The test contract deployer (address(this)) is the initial admin of the TimeLock.
        // Deploy the TimeLock contract
        // The TimeLock contract is responsible for enforcing a delay between when a proposal is queued and when it can be executed.
        // It is initialized with:
        // - MIN_DELAY: The minimum delay (in seconds) for proposal execution.
        // - proposers: The initial list of addresses with the PROPOSER_ROLE (can queue proposals).
        // - executors: The initial list of addresses with the EXECUTOR_ROLE (can execute proposals).
        timelock = new TimeLock(MIN_DELAY, proposers, executors);

        // The MyGovernor contract handles the governance logic, such as voting and proposal creation.
        // It interacts with the TimeLock to queue and execute proposals.
        governor = new MyGovernor(token, timelock);

        // Assign roles to the governor and revoke admin role from this contract
        // The governor contract needs the PROPOSER_ROLE to queue proposals in the TimeLock.
        // The EXECUTOR_ROLE is granted to address(0), allowing anyone to execute proposals after the delay.
        // Finally, the DEFAULT_ADMIN_ROLE is revoked from the deployer (address(this)) to decentralize control.
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));
        //timelock.revokeRole(adminRole, msg.sender);// in this case msg.sender is address(this)
        timelock.revokeRole(adminRole, address(this));

        // Deploy the Box contract and transfer ownership to the TimeLock
        // The TimeLock is made the owner of the Box contract to enforce governance decisions.
        // This ensures that:
        // - Only proposals approved by the Governor and queued in the TimeLock can modify the Box.
        // - A delay is enforced before any changes are executed, providing security and time for token holders to react.
        // - The governance system remains decentralized, as the Governor does not directly control the Box.
        box = new Box();
        box.transferOwnership(address(timelock));
    }

    function testCantUpdateBoxWithoutGovernance() public {
        // Expect the transaction to revert because the caller is not authorized
        vm.expectRevert();
        box.store(1);
    }

    function testGovernanceUpdatesBox() public {
        uint256 valueToStore = 777;
        string memory description = 'Store 1 in Box';

        // Encode the function call to store a value in the Box contract
        // This encoding is necessary because the governance system interacts with the Box contract indirectly.
        // The encoded function call is passed to the Governor contract, which queues it in the TimeLock.
        // When the proposal is executed, the TimeLock decodes the function call and executes it on the Box contract.
        // This approach ensures that the governance system can handle arbitrary function calls securely and flexibly.
        bytes memory encodedFunctionCall = abi.encodeWithSignature(
            'store(uint256)',
            valueToStore
        );
        addressesToCall.push(address(box));
        // The `values` array specifies the Ether (in wei) to send with the function call.
        // Since the `store(uint256)` function does not require Ether, we push `0`.
        // If the function were payable, this is where you would specify the Ether amount to send.
        values.push(0);

        // The `functionCalls` array contains the encoded function call, including the function selector and arguments.
        // In this case, it encodes the `store(uint256)` function with `valueToStore` as the argument.
        functionCalls.push(encodedFunctionCall);

        // 1. Propose to the DAO
        // Only the governor can propose due to the PROPOSER_ROLE assigned in the setUp() function.
        // The `governor.propose` function creates a proposal with the specified target addresses, Ether values, and function calls.
        // The `description` provides a human-readable explanation of the proposal.
        uint256 proposalId = governor.propose(
            addressesToCall,
            values,
            functionCalls,
            description
        );

        // Proposal states are defined in OpenZeppelin's Governor.sol:
        // 0 = Pending: Proposal is created but not yet active.
        // 1 = Active: Voting is open.
        // 2 = Canceled: Proposal has been canceled.
        // 3 = Defeated: Proposal did not pass.
        // 4 = Succeeded: Proposal passed the vote.
        // 5 = Queued: Proposal is queued in the timelock for execution.
        // 6 = Expired: Proposal is no longer executable.
        // 7 = Executed: Proposal has been executed.

        console2.log('Proposal State:', uint256(governor.state(proposalId))); // Pending, 0
        assertEq(uint256(governor.state(proposalId)), 0);

        // Advance time and blocks to make the proposal active
        // Note: In this test, `VOTING_DELAY` is used for both time (seconds) and blocks.
        // This assumes a block time of 1 second for simplicity. In a real blockchain, the block time is usually longer (e.g., 12 seconds on Ethereum).
        // To simulate a realistic block time, you could define a `BLOCK_TIME` constant and adjust the delays:
        // vm.warp(block.timestamp + VOTING_DELAY * BLOCK_TIME);
        // vm.roll(block.number + VOTING_DELAY);
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        console2.log('Proposal State:', uint256(governor.state(proposalId))); // Active, 1
        assertEq(uint256(governor.state(proposalId)), 1);

        // 2. Vote
        // The `VOTER` address can vote because:
        // - It holds tokens (minted in the `setUp()` function).
        // - It delegated its voting power to itself, which is required to gain voting power in OpenZeppelin's ERC20Votes.
        // The `vm.prank(VOTER)` cheat code simulates the `VOTER` address as the caller (msg.sender) for the next transaction.
        // The Governor contract enforces voting eligibility by checking that the voter has non-zero voting power.
        string memory reason = 'I like a do da cha cha';
        // 0 = Against, 1 = For, 2 = Abstain for this example
        uint8 voteWay = 1;
        vm.prank(VOTER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        // Advance time and blocks to end the voting period
        // The proposal succeeds because:
        // - The `VOTER` address holds 100 tokens and has delegated its voting power to itself.
        // - The quorum requirement is 4% of the total supply (100 tokens), which equals 4 votes.
        // - The `VOTER` casts 100 votes "For," exceeding the quorum and ensuring the proposal passes.
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        console2.log('Proposal State:', uint256(governor.state(proposalId))); // Succeeded, 4
        assertEq(uint256(governor.state(proposalId)), 4);

        // 3. Queue the proposal in the timelock
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(addressesToCall, values, functionCalls, descriptionHash);
        vm.roll(block.number + MIN_DELAY + 1);
        vm.warp(block.timestamp + MIN_DELAY + 1);

        console2.log('Proposal State:', uint256(governor.state(proposalId))); // Queued, 5
        assertEq(uint256(governor.state(proposalId)), 5);

        // 4. Execute the proposal
        governor.execute(
            addressesToCall,
            values,
            functionCalls,
            descriptionHash
        );

        console2.log('Proposal State:', uint256(governor.state(proposalId))); // Executed, 7
        assertEq(uint256(governor.state(proposalId)), 7);

        // Verify that the Box contract was updated
        assert(box.getNumber() == valueToStore);
    }
}
