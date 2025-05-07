# VaultManager.clar

**VaultManager.clar** is a Clarity smart contract that manages BTC-collateralized vaults for the **BitFinance Protocol**. It enables users to deposit BTC as collateral, borrow against it, manage risk through over-collateralization, and ensure protocol-wide solvency through liquidation thresholds and admin oversight.

---

## 🧠 Key Features

* **Vault Creation**: Users can create individual vaults tied to their principal.
* **Collateral Management**: Vault owners can add or remove BTC collateral.
* **Debt Management**: Interacts with external loan contracts to update debt positions.
* **Collateral Ratio Enforcement**: Ensures a minimum collateral ratio of **150%**.
* **Liquidation Checks**: Vaults with collateral ratio below **130%** are eligible for liquidation.
* **Protocol Stats Tracking**: Monitors total system collateral and outstanding debt.
* **Admin Privileges**: The protocol admin can update control settings.

---

## 📚 Functions Overview

### 🔓 Public Functions

| Function                        | Description                                               |
| ------------------------------- | --------------------------------------------------------- |
| `create-vault`                  | Initializes a vault for the caller.                       |
| `add-collateral (amount)`       | Adds BTC collateral to the caller’s vault.                |
| `remove-collateral (amount)`    | Removes BTC collateral if safety checks pass.             |
| `update-debt (owner, new-debt)` | Updates the user's debt after loan contract interactions. |
| `set-admin (new-admin)`         | Sets a new protocol admin (admin only).                   |

### 🔍 Read-Only Functions

| Function                       | Description                                  |
| ------------------------------ | -------------------------------------------- |
| `get-vault (owner)`            | Returns vault details for the given address. |
| `get-collateral-ratio (owner)` | Returns the collateral-to-debt ratio.        |
| `can-liquidate (owner)`        | Checks if a vault is under-collateralized.   |
| `get-protocol-stats`           | Returns total system collateral and debt.    |

---

## ⚠️ Constants & Error Codes

| Constant                | Value | Description                                      |
| ----------------------- | ----- | ------------------------------------------------ |
| `MIN_COLLATERAL_RATIO`  | 150%  | Minimum safe ratio to avoid liquidation.         |
| `LIQUIDATION_THRESHOLD` | 130%  | Below this, vaults are eligible for liquidation. |

| Error                         | Code   | Description                                  |
| ----------------------------- | ------ | -------------------------------------------- |
| `ERR_UNAUTHORIZED`            | `u100` | Caller is not the protocol admin.            |
| `ERR_INSUFFICIENT_COLLATERAL` | `u101` | Not enough collateral to remove.             |
| `ERR_VAULT_NOT_FOUND`         | `u102` | No vault exists for user.                    |
| `ERR_BELOW_MIN_COLLATERAL`    | `u103` | Operation would breach min collateral ratio. |
| `ERR_VAULT_ALREADY_EXISTS`    | `u104` | Vault already exists for caller.             |

---

## 🛠️ Deployment & Usage

1. Deploy the contract on the Stacks blockchain using Clarity-compatible tools (e.g., Clarinet or Hiro Wallet).
2. Call `create-vault` to initialize a vault.
3. Use `add-collateral` and `remove-collateral` to manage BTC backing.
4. The external loan contract can call `update-debt` to reflect borrow/repay actions.
5. Monitor health using `get-collateral-ratio` and `can-liquidate`.

---

## 🔐 Security Considerations

* **Collateral Transfers**: Simulated as internal balance updates; must be integrated with actual BTC token logic for production.
* **Admin Privileges**: `set-admin` is restricted to the current admin and should be used carefully.
* **Debt Updates**: Should only be called by trusted loan contract(s).
