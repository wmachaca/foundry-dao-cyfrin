// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.18;

import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {GovernorVotesQuorumFraction} from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {GovernorTimelockControl} from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

/// @title MyGovernor
/// @notice Simple Governor implementation wired with a timelock and a voting token.
contract MyGovernor is
    Governor,
 GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    /**
     * @notice Deploys the governor with governance parameters and dependencies.
     * @param _token Governance token that exposes the IVotes interface.
     * @param _timelock Timelock that will queue and execute approved proposals.
     */
    constructor(IVotes _token, TimelockController _timelock)
        Governor("MyGovernor")
        GovernorSettings(1, /* 1 block */ 50400, /* 1 week */ 0)
    GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
        GovernorTimelockControl(_timelock)
    {}

    // The following functions are overrides required by Solidity.

    /// @notice Provides the delay between proposal creation and voting start.
    /// @return Number of blocks that need to elapse before voting begins.
    function votingDelay() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    /// @notice Returns the length of the voting window.
    /// @return Number of blocks available for casting votes.
    function votingPeriod() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    /// @notice Calculates quorum based on a fraction of total supply.
    /// @param blockNumber Snapshot block to evaluate. Calculate the totalsupply at this block.
    /// @return Required voting power for a proposal to succeed.
    function quorum(uint256 blockNumber)
        public
        view
        override(Governor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    /// @notice Exposes the lifecycle state for a proposal.
    /// @param proposalId Identifier returned by propose.
    /// @return Current state in the Governor state machine.
    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    /**
     * @notice Creates a new proposal describing which calls should be executed.
     * @param targets Contract addresses that will receive the calls.
     * @param values Native token values to send with each call.
     * @param calldatas Encoded function selectors and arguments per target.
     * @param description Human readable summary that is also hashed off-chain.
     * @return proposalId Unique identifier assigned to the proposal.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    /// @notice Minimum voting power required to create a proposal.
    /// @return Threshold expressed in number of votes.
    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }

    /**
     * @notice Places the proposal operations in the timelock queue.
     * @dev Automatically called by Governor after a successful vote.
     */
    function _queueOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint48) {
        return super._queueOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    /**
     * @notice Executes queued operations once the timelock delay has elapsed.
     */
    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._executeOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    /**
     * @notice Cancels queued proposal operations when prerequisites are not met.
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    /// @notice Address that executes queued operations (the timelock contract).
    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }

    /**
     * @notice Reports whether an interface is supported.
     * @param interfaceId EIP-165 interface identifier.
     * @return True if the interface is implemented, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Determines if a proposal needs to be queued before execution.
     * @param proposalId Identifier of the proposal.
     * @return True if the proposal needs to be queued, false otherwise.
     */
    function proposalNeedsQueuing(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.proposalNeedsQueuing(proposalId);
    }
}
