<div align="center">

# 🏛️ First DAO

### Token-governed timelocked Box built with Foundry, OpenZeppelin Governor, and forge-std.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Foundry](https://img.shields.io/badge/Foundry-Forge-blue)](https://book.getfoundry.sh/)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.18%2B-black)](https://docs.soliditylang.org/en/latest/)

[Quick Start](#-quick-start) • [Architecture](#-architecture-overview) • [Contracts](#-core-contracts) • [Tech Stack](#-technology-stack)

</div>

---

## 🛰️ Project Overview

This repository contains a minimal yet production-inspired DAO stack:

- **`GovToken.sol`** mints the vote-escrowed ERC20 supply that powers governance.
- **`MyGovernor.sol`** wraps OpenZeppelin's Governor modules for proposals, vote accounting, quorum checks, and timelock hand-offs.
- **`TimeLock.sol`** guards state-changing calls behind a configurable delay and strict proposer/executor roles.
- **`Box.sol`** is the target contract controlled exclusively by the DAO.
- **`test/MyGovernorTest.t.sol`** drives the full lifecycle (mint, delegate, propose, vote, queue, execute) using forge-std cheats.

Everything lives inside a standard Foundry workspace (`src/`, `test/`, `lib/`) with OpenZeppelin contracts vendored as submodules.

---

## ✨ Key Features

- **Token-weighted voting** via ERC20Votes delegation snapshots.
- **Module-based governor** (settings, counting, quorum fraction, timelock control) configured for a 1 block delay and ~1 week voting window.
---

## 🧱 Architecture Overview

```
Token Holders (GovToken + delegation)
          |
          v
    MyGovernor.sol (propose / vote / queue)
          |
          v
    TimeLock.sol (delay + role ACL) #Access Control List
          |
          v
        Box.sol (store/get only via DAO)
```

**Why this shape?**
- Separates **voting logic** (Governor) from **execution control** (TimeLock) to prevent direct admin shortcuts.
- Makes **Box** ownership programmatic: only queued proposals that survive the delay can touch state.
- Uses **GovToken snapshots** so voting power cannot be manipulated mid-vote.

---

## 🔁 Governance Flow

1. **Bootstrap**: deploy GovToken, mint to participants, call `delegate()` so voting power is recorded.
2. **Propose**: `MyGovernor.propose()` encodes calls (e.g., `Box.store(777)`) and emits a pending proposal.
3. **Vote**: after `votingDelay` blocks, token holders cast votes (`Against | For | Abstain`) optionally with reasons.
4. **Queue**: if quorum (4% of total supply) and majority are met, Governor schedules the payload in `TimeLock` with `descriptionHash`.
5. **Execute**: once `minDelay` (1 hour) passes, anyone may call `execute()` to forward the calldata to Box; TimeLock then clears the operation.

All of these stages are exercised in `test/MyGovernorTest.t.sol`, making it the best living documentation of the happy path and revert cases.

---

## 🧠 Core Contracts

| File | Purpose | Highlights |
| --- | --- | --- |
| `src/GovToken.sol` | ERC20Votes-powered governance token with permit + burn. | `mint()` gated by `Ownable`; `_update()` keeps vote checkpoints in sync; `nonces()` resolves diamond inheritance. |
| `src/MyGovernor.sol` | Aggregates OZ governor extensions. | `GovernorSettings(1, 50400, 0)` sets delay/period/threshold; `GovernorVotesQuorumFraction(4)` enforces 4% quorum; overrides expose state, queue, execute internals. |
| `src/TimeLock.sol` | Thin wrapper over `TimelockController`. | Constructor wire accepts `minDelay`, proposers, executors; deployer logged via `console2` for debugging. |
| `src/Box.sol` | Example target contract. | Simple `store()`/`getNumber()` with `Ownable` guard; ownership transferred to TimeLock during setup. |
| `test/MyGovernorTest.t.sol` | End-to-end Foundry test. | Demonstrates role assignment (`PROPOSER_ROLE`, `EXECUTOR_ROLE`), delegation, voting, timelock queue/execute, and Box assertions. |

---

## 🛠 Tooling & Commands

- `forge build` / `forge build --sizes` ➜ compile contracts and inspect bytecode footprints.
- `forge test -vvv` runs the governance integration tests with full logs.
- `forge test --match-test testGovernanceUpdatesBox -vvv` runs the specific test with full logs.
- `forge fmt` / `forge fmt --check` enforce Solidity formatting (also run in CI).
- `npm run format` (Prettier) and `npm run lint` (Solhint) cover JS/JSON configs and Solidity linting respectively.
- `foundry.toml` remaps `@openzeppelin/contracts` to `lib/openzeppelin-contracts/contracts` so OZ imports stay clean.

---

## 🚀 Quick Start

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation) (`forge`, `cast`, `anvil`).
- Node.js 18+ for formatting/linting scripts.

### Setup
```bash
git clone https://github.com/wmachaca/foundry-dao-cyfrin.git
cd foundry-dao-cyfrin
npm install        # installs prettier, solhint, plugins
git submodule update --init --recursive
forge build
```

### Common Commands
```bash
forge test -vvv                     # run governance scenario
npm run format && npm run lint      # keep style checks green
```

---

## 🧪 Testing & Simulation

- Primary coverage lives in `test/MyGovernorTest.t.sol` and uses forge-std's `vm` cheats to warp time, roll blocks, and impersonate voters.
- Add new proposals or targets by copying the *addresses / values / calldatas* pattern from the test to ensure encoding matches Governor expectations.
- Run `FOUNDRY_PROFILE=ci forge test -vvv` locally to mirror the GitHub Actions workflow defined in `.github/workflows/test.yml`.

---

## 🧰 Technology Stack

| Layer | Stack |
| --- | --- |
| Smart Contracts | Solidity 0.8.18, OpenZeppelin Governor/Timelock/ERC20Votes, Foundry toolchain, forge-std cheats. |
| Tooling | Prettier + prettier-plugin-solidity, Solhint, GitHub Actions CI (fmt, build, test). |
| Utilities | `console2` logging, Foundry remappings, Ownable pattern for initial role hand-off. |

---

## 🗂 Project Structure

```
.
├── src/
│   ├── Box.sol
│   ├── GovToken.sol
│   ├── MyGovernor.sol
│   └── TimeLock.sol
├── test/
│   └── MyGovernorTest.t.sol
├── lib/
│   ├── forge-std/
│   └── openzeppelin-contracts/
├── foundry.toml
├── package.json
└── .github/workflows/test.yml
```

---

## 📎 References & Further Reading

- `.github/copilot-instructions.md` for agent-oriented guidelines about this repo.
- `foundry.toml`, `.prettierrc`, `.solhint.json` for formatting/linting policies.
- [OpenZeppelin Governor docs](https://docs.openzeppelin.com/contracts/5.x/governance) for deeper module explanations.
