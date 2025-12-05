// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.18;

import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import { ERC20Permit } from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';
import { ERC20Votes } from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol';
import { ERC20Burnable } from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import { Nonces } from '@openzeppelin/contracts/utils/Nonces.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

/// @title GovToken Governance Token
/// @notice ERC20 token with permit, votes and burn support tailored for governance flows.
contract GovToken is ERC20, ERC20Permit, ERC20Votes, ERC20Burnable, Ownable {
    /// @notice Initializes token metadata, permit domain separator, and sets the initial owner.
    /// @param initialOwner The address that will be set as the initial owner.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    constructor(
        address initialOwner,
        string memory name,
        string memory symbol
    )
        ERC20(name, symbol) // Pass the name and symbol to the ERC20 constructor
        ERC20Permit(name) // Pass the name to the ERC20Permit constructor
        Ownable(initialOwner) // Pass the initial owner to the Ownable constructor
    {}

    /**
     * @notice Mints governance tokens to an address.
     * @dev Restricted to the owner so distribution can be handled by governance logic.
     * @param to Recipient of the minted tokens.
     * @param amount Number of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Burns governance tokens from an address.
     * @dev Restricted to the owner so burning can be handled by governance logic.
     * @param account The address from which tokens will be burned.
     * @param amount The number of tokens to burn.
     */
    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount); // Call the existing _burn function in ERC20
    }

    /**
     * @notice Hook that is called after any transfer of tokens.
     * @dev This function keeps voting power in sync with token balances by calling `_update`.
     * It is marked as `virtual` to allow further customization in derived contracts.
     * @param from The address losing tokens.
     * @param to The address gaining tokens.
     * @param amount The number of tokens transferred.
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Votes) {
        // Call the ERC20Votes implementation of _update
        super._update(from, to, amount);
    }

    /**
     * @notice Exposes the current permit nonce for an address.
     * @dev Forwarded to both ERC20Permit and Nonces to satisfy the diamond inheritance.
     * @param owner Address whose nonce is being queried.
     * @return Current nonce value that must be used in the next permit signature.
     */
    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
