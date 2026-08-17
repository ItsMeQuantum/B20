# B20 -- Base Native Token Creator

B20 is a native token standard on Coinbase’s Layer-2 network Base, introduced with the Beryl network upgrade. It is a full ERC-20 superset implemented via Rust precompiles rather than custom smart contracts, offering lower gas costs, higher throughput, and built-in regulatory and compliance features.

B20 tokens operate directly inside the Base node software via Rust precompiles. When you interact with a B20 token, the network bypasses the EVM interpreter entirely. It executes the logic natively in Rust, which is significantly faster and more resource efficient.

```{=html}
<p align="center">
```
`<strong>`{=html}A small Solidity project that turns Base's B20 token
interface into a practical, developer-friendly creation
flow.`</strong>`{=html}
```{=html}
</p>
```
```{=html}
<p align="center">
```
Create an Asset token → configure its initial permissions → set its
supply cap → receive a deterministic token address.
```{=html}
</p>
```

------------------------------------------------------------------------

## ❖ What is this project?

This repository is a Solidity/Remix-oriented integration around the
**B20 token system**.

At first glance, the project looks like a collection of interfaces and
helper libraries. The important idea is simpler:

> **The code in this repository does not implement the entire B20
> protocol from scratch. It talks to the B20 factory precompile and
> gives developers a convenient way to create and configure B20
> tokens.**

The main entry point is `B20Creator.sol`.

A user calls:

``` solidity
createToken(
    name,
    symbol,
    decimals,
    maxSupply,
    salt
)
```

The creator then:

1.  Encodes the B20 Asset parameters.
2.  Builds initialization calls.
3.  Grants the caller `MINT_ROLE`.
4.  Sets the token's supply cap.
5.  Calls the B20 factory precompile.
6.  Stores and emits the newly created token address.

The result is a newly initialized **B20 Asset token**.

------------------------------------------------------------------------

# 🧠 The big picture

The easiest way to understand the repository is to think of it as three
layers:

``` text
┌──────────────────────────────────────────────────────────┐
│                    YOUR APPLICATION                      │
│                                                          │
│  Remix / dApp / frontend / backend / wallet              │
└───────────────────────────┬──────────────────────────────┘
                            │
                            │ createToken(...)
                            ▼
┌──────────────────────────────────────────────────────────┐
│                     B20Creator.sol                       │
│                                                          │
│  • prepares creation parameters                          │
│  • prepares initialization calls                         │
│  • calls the B20 factory                                 │
│  • remembers the created token                           │
└───────────────────────────┬──────────────────────────────┘
                            │
                            │ createB20(...)
                            ▼
┌──────────────────────────────────────────────────────────┐
│                 B20 FACTORY PRECOMPILE                   │
│                                                          │
│  0xB20f000000000000000000000000000000000000              │
│                                                          │
│  • determines the token address                          │
│  • creates the B20 token                                 │
│  • runs bootstrap initialization calls                   │
│  • finishes the creation process                         │
└───────────────────────────┬──────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────┐
│                    B20 ASSET TOKEN                       │
│                                                          │
│  ERC-20-like token surface + B20 features                │
│                                                          │
│  • transfers                                             │
│  • approvals                                             │
│  • minting                                               │
│  • burning                                               │
│  • roles                                                 │
│  • pausing                                               │
│  • policies                                              │
│  • supply cap                                            │
│  • permit                                                │
│  • Asset-specific features                               │
└──────────────────────────────────────────────────────────┘
```

------------------------------------------------------------------------

# 🏗️ Repository architecture

``` text
B20/
│
├── B20/
│   ├── B20Creator.sol
│   ├── B20Constants.sol
│   ├── B20FactoryLib.sol
│   ├── IB20.sol
│   ├── IB20Asset.sol
│   ├── IB20Factory.sol
│   ├── IERC165.sol
│   ├── IERC8056.sol
│   └── StdPrecompiles.sol
│
├── artifacts/
│   └── Compiled contracts, ABIs and metadata
│
├── .deps/
│   └── Remix/dependency information
│
├── ERC721.sol
│   └── Separate ERC-721 example contract
│
└── remix.config.json
    └── Remix project configuration
```

------------------------------------------------------------------------

# 🔍 What each file actually means

## `B20Creator.sol`

**The front door.**

This is the contract a developer can interact with to create a B20 Asset
without manually assembling every ABI-encoded initialization call.

Its main function is:

``` solidity
createToken(
    string calldata name,
    string calldata symbol,
    uint8 decimals,
    uint256 maxSupply,
    bytes32 salt
)
```

Internally it creates the parameters and initialization calls needed by
the factory.

The important part is:

``` solidity
initCalls[0] =
    B20FactoryLib.encodeGrantRole(
        B20Constants.MINT_ROLE,
        msg.sender
    );
```

The caller receives `MINT_ROLE`.

Then:

``` solidity
initCalls[1] =
    B20FactoryLib.encodeUpdateSupplyCap(
        maxSupply
    );
```

The requested maximum supply is configured during token creation.

Finally:

``` solidity
token =
    StdPrecompiles.B20_FACTORY.createB20(
        IB20Factory.B20Variant.ASSET,
        salt,
        params,
        initCalls
    );
```

That is the moment where the actual B20 factory is asked to create the
token.

------------------------------------------------------------------------

# 🧩 `IB20Factory.sol`

This file describes the factory interface.

The factory supports two variants:

``` solidity
enum B20Variant {
    ASSET,
    STABLECOIN
}
```

### Asset

The Asset variant supports configurable decimals.

Allowed range:

``` text
6 → 18
```

### Stablecoin

The Stablecoin variant uses:

``` text
6 decimals
```

and has an immutable currency code.

This repository's `B20Creator` currently chooses:

``` solidity
B20Variant.ASSET
```

so it creates Asset tokens.

------------------------------------------------------------------------

# 🛠️ `B20FactoryLib.sol`

This is the project's **encoding toolbox**.

The B20 factory expects ABI-encoded creation parameters and
initialization calls.

Writing all of those encodings manually would make `B20Creator.sol` much
harder to read.

So `B20FactoryLib` provides helper functions such as:

``` text
encodeAssetCreateParams()
encodeStablecoinCreateParams()

encodeGrantRole()
encodeRevokeRole()
encodeSetRoleAdmin()

encodeUpdateSupplyCap()
encodeUpdateContractURI()
encodeUpdateName()
encodeUpdatePolicy()

encodeBatchMint()

encodeUpdateExtraMetadata()

encodeUpdateUIMultiplier()
encodeUpdateMultiplier()
encodeCancelUIMultiplierUpdate()
```

In other words:

``` text
Human-friendly configuration
            ↓
     B20FactoryLib
            ↓
ABI-encoded initialization calls
            ↓
       B20 Factory
```

------------------------------------------------------------------------

# 🧱 `B20Constants.sol`

This file contains the common B20 constants used by the rest of the
project.

Among the important roles are:

``` text
DEFAULT_ADMIN_ROLE
MINT_ROLE
BURN_ROLE
BURN_BLOCKED_ROLE
SEIZE_ROLE
PAUSE_ROLE
UNPAUSE_ROLE
METADATA_ROLE
OPERATOR_ROLE
```

It also defines policy scopes such as:

``` text
TRANSFER_SENDER_POLICY
TRANSFER_RECEIVER_POLICY
TRANSFER_EXECUTOR_POLICY
MINT_RECEIVER_POLICY
SEIZE_HOLDER_POLICY
SEIZE_RECEIVER_POLICY
```

These constants give the rest of the code a shared vocabulary for
permissions and policy enforcement.

------------------------------------------------------------------------

# 🔌 `StdPrecompiles.sol`

This file connects the Solidity interfaces to the protocol-level B20
factory.

The factory address is:

``` text
0xB20f000000000000000000000000000000000000
```

The important concept is that this is **not a normal factory contract
deployed by this repository**.

The repository simply exposes the address through:

``` solidity
StdPrecompiles.B20_FACTORY
```

and treats it as:

``` solidity
IB20Factory
```

------------------------------------------------------------------------

# 🪙 `IB20.sol`

This is the base interface implemented by B20 tokens.

It describes the common token functionality.

### Transfers

``` text
transfer()
transferFrom()
transferWithMemo()
transferFromWithMemo()
```

### Approvals

``` text
approve()
allowance()
```

### Minting

``` text
mint()
mintWithMemo()
```

### Burning

``` text
burn()
burnWithMemo()
```

### Administrative token movement

``` text
seizeWithMemo()
```

### Roles

B20 uses role-based authorization instead of relying on a single owner
for every operation.

### Pausing

B20 has feature-specific pause categories:

``` text
TRANSFER
MINT
BURN
SEIZE
```

This means the protocol can pause particular classes of operations
instead of treating the token as one giant on/off switch.

------------------------------------------------------------------------

# 🛡️ Permissions and roles

The role system is one of the most important parts of B20.

For example:

``` text
DEFAULT_ADMIN_ROLE
        │
        ├── manages roles
        │
        ├── manages configuration
        │
        └── manages administrative permissions

MINT_ROLE
        │
        └── can mint new tokens

BURN_ROLE
        │
        └── can perform authorized burns

SEIZE_ROLE
        │
        └── can perform authorized seizure operations

PAUSE_ROLE
        │
        └── can pause supported features
```

The exact role relationships are defined by the B20 token itself and its
initialization configuration.

The important idea is:

> **B20 separates capabilities into explicit roles instead of giving
> every administrative ability to every account.**

------------------------------------------------------------------------

# 🚦 The token creation flow

Here is the complete lifecycle.

``` text
                 USER
                  │
                  │
                  │ createToken(...)
                  ▼
        ┌───────────────────┐
        │   B20Creator      │
        └─────────┬─────────┘
                  │
                  │ 1. Encode parameters
                  ▼
        ┌───────────────────┐
        │ B20FactoryLib     │
        └─────────┬─────────┘
                  │
                  │ 2. Build initCalls
                  │
                  ├──────────────► Grant MINT_ROLE
                  │
                  └──────────────► Set supply cap
                  │
                  ▼
        ┌───────────────────┐
        │ B20 Factory       │
        │ Precompile        │
        └─────────┬─────────┘
                  │
                  │ 3. Derive deterministic address
                  │
                  │ 4. Create B20 Asset
                  │
                  │ 5. Execute initCalls
                  │
                  ▼
        ┌───────────────────┐
        │   B20 Token       │
        └─────────┬─────────┘
                  │
                  │ token address
                  ▼
        ┌───────────────────┐
        │ B20Creator        │
        │ lastCreatedToken  │
        └───────────────────┘
```

------------------------------------------------------------------------

# 🧬 What happens inside `createToken()`?

Let's walk through the actual code in human terms.

## Step 1 --- Prepare the token identity

The creator calls:

``` solidity
B20FactoryLib.encodeAssetCreateParams(
    name,
    symbol,
    msg.sender,
    decimals
);
```

So the token is created with:

-   `name`
-   `symbol`
-   `msg.sender` as the initial admin
-   `decimals`

The Asset's decimals are immutable after creation and must be between
`6` and `18`.

------------------------------------------------------------------------

## Step 2 --- Prepare initialization

The creator creates:

``` solidity
bytes[] memory initCalls = new bytes[](2);
```

There are two initialization operations.

### Initialization #1

``` solidity
grantRole(MINT_ROLE, msg.sender)
```

The person creating the token becomes a minter.

### Initialization #2

``` solidity
updateSupplyCap(maxSupply)
```

The maximum supply is configured.

So conceptually:

``` text
New token
   │
   ├── Admin → creator
   │
   ├── Minter → creator
   │
   └── Supply cap → maxSupply
```

------------------------------------------------------------------------

# 🧮 Deterministic addresses

The factory does something interesting.

The resulting token address is derived deterministically from:

``` text
variant
+
sender
+
salt
```

The interface exposes:

``` solidity
getB20Address(
    variant,
    sender,
    salt
)
```

This means the address can be predicted before creation.

Conceptually:

``` text
             ASSET
               +
             USER
               +
             SALT
               │
               ▼
       deterministic address
```

If the same combination already exists, the factory rejects the creation
with:

``` text
TokenAlreadyExists
```

Using a different salt produces another deterministic address.

------------------------------------------------------------------------

# 🧪 Why is `salt` important?

The salt is effectively a user-controlled identifier for a token
creation.

For example:

``` text
salt = 0x01
```

and:

``` text
salt = 0x02
```

can produce different token addresses for the same creator.

This makes deterministic deployment useful for applications that want
predictable addresses.

------------------------------------------------------------------------

# 🔐 The bootstrap window

One of the more interesting architectural details is the factory's
**bootstrap window**.

During creation, the factory executes the initialization calls on the
newly created token.

Some normal role/policy restrictions are temporarily bypassed for those
factory-originated initialization calls.

This allows operations such as:

``` text
grantRole()
updatePolicy()
updateSupplyCap()
```

to happen during creation without the factory permanently keeping those
roles.

But this bypass is deliberately limited.

### It does NOT bypass everything

The factory still respects:

``` text
MINT_RECEIVER_POLICY
```

Pause state is also not bypassed.

And core accounting invariants remain enforced.

After `createB20()` completes:

``` text
bootstrap window → closed
```

The factory does not keep persistent control over the token.

That is an important security property.

------------------------------------------------------------------------

# 📈 Supply cap

The creator configures:

``` solidity
maxSupply
```

through:

``` solidity
updateSupplyCap(maxSupply)
```

The B20 token prevents minting from pushing total supply above the
configured cap.

The cap can be no greater than:

``` text
uint128.max
```

and it cannot be reduced below the token's current total supply.

Conceptually:

``` text
Current supply
      │
      │ must remain ≤
      ▼
Supply cap
      │
      │ must remain ≤
      ▼
uint128.max
```

------------------------------------------------------------------------

# 🧠 B20 is more than a basic ERC-20

Although B20 exposes familiar ERC-20-style functions, its architecture
adds several layers around them.

``` text
                     B20
                      │
        ┌─────────────┼─────────────┐
        │             │             │
     ERC-20         Roles         Policies
        │             │             │
        │             │             │
   transfers       minting       transfer rules
   approvals       burning       receiver rules
   allowances      pausing       mint rules
                                  seizure rules
        │
        ├───────────────┐
        │               │
     Supply Cap       Permit
        │               │
        └───────┬───────┘
                │
        Asset-specific layer
                │
        ┌───────┼────────┐
        │       │        │
     Metadata  Memo   UI multiplier
```

------------------------------------------------------------------------

# 🧩 Asset-specific functionality

`IB20Asset.sol` extends the base B20 interface.

The Asset variant adds functionality around things such as:

-   announcements
-   extra metadata
-   batched issuance
-   UI amount scaling
-   multiplier updates

The UI multiplier is particularly interesting.

It allows the protocol to represent a different UI amount without
necessarily changing the underlying accounting model.

There is also a newer scheduled multiplier mechanism:

``` solidity
updateUIMultiplier(
    newMultiplier,
    effectiveAt
)
```

and a cancellation function:

``` solidity
cancelUIMultiplierUpdate()
```

The older multiplier update mechanism is retained as a deprecated
interface.

------------------------------------------------------------------------

# 📝 Memo-enabled operations

B20 also introduces memo-enabled token operations.

Examples:

``` text
transferWithMemo()
transferFromWithMemo()
mintWithMemo()
burnWithMemo()
seizeWithMemo()
```

A memo is represented as:

``` solidity
bytes32
```

The protocol emits a corresponding `Memo` event.

This gives applications a compact way to attach an application-level
identifier or piece of metadata to an operation without changing the
normal token amount accounting.

------------------------------------------------------------------------

# 🔎 Policy architecture

B20 separates **who can call something** from **whether the operation is
allowed**.

For example:

``` text
                    Transfer
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
      Sender         Receiver     Executor
       Policy         Policy       Policy
```

This is different from simply saying:

> "Alice has permission."

Instead, the system can also ask:

> "Even if Alice is allowed to call this function, is this particular
> sender/receiver/execution context currently permitted?"

This creates a more flexible compliance and control layer.

------------------------------------------------------------------------

# ⏸️ Feature-specific pausing

B20 defines:

``` solidity
enum PausableFeature {
    TRANSFER,
    MINT,
    BURN,
    SEIZE
}
```

So the system can conceptually have:

``` text
Transfer  → ACTIVE
Mint      → ACTIVE
Burn      → PAUSED
Seize     → ACTIVE
```

rather than only:

``` text
Token → PAUSED
```

That gives applications more granular operational control.

------------------------------------------------------------------------

# ✍️ Permit support

The base interface also exposes EIP-2612-style permit functionality.

The important idea is:

``` text
Traditional approval:

User → sends transaction → approve()

Permit:

User → signs message
             │
             ▼
       another party
             │
             ▼
       submits permit
```

This can reduce the need for a separate on-chain approval transaction in
supported application flows.

------------------------------------------------------------------------

# 🖼️ Overall system architecture

``` text
                         ┌────────────────────┐
                         │       USER         │
                         │                    │
                         │ MetaMask / Wallet  │
                         └─────────┬──────────┘
                                   │
                                   │ transaction
                                   ▼
                         ┌────────────────────┐
                         │    B20Creator      │
                         │                    │
                         │ createToken(...)   │
                         └─────────┬──────────┘
                                   │
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
                    ▼                             ▼
          ┌──────────────────┐          ┌──────────────────┐
          │ B20FactoryLib    │          │ B20Constants     │
          │                  │          │                  │
          │ ABI encoding     │          │ Roles            │
          │ Init calls       │          │ Policies         │
          └────────┬─────────┘          │ Limits           │
                   │                    └──────────────────┘
                   │
                   │ encoded params + initCalls
                   ▼
          ┌─────────────────────────────────────┐
          │          B20 FACTORY                │
          │          PRECOMPILE                  │
          │                                     │
          │  0xB20f...0000                     │
          └──────────────────┬──────────────────┘
                             │
                 ┌───────────┼───────────┐
                 │           │           │
                 ▼           ▼           ▼
             Identity    Bootstrap    Address
              sealed      setup      determined
                 │           │           │
                 └───────────┼───────────┘
                             ▼
                  ┌──────────────────────┐
                  │     B20 ASSET       │
                  │                      │
                  │ Transfer            │
                  │ Approve             │
                  │ Mint                │
                  │ Burn                │
                  │ Seize               │
                  │ Pause               │
                  │ Roles               │
                  │ Policies            │
                  │ Supply Cap          │
                  │ Permit              │
                  │ Metadata            │
                  │ UI Multiplier       │
                  └──────────┬───────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │    APPLICATION       │
                  │                      │
                  │ DApp / Exchange /    │
                  │ Wallet / Protocol    │
                  └──────────────────────┘
```

------------------------------------------------------------------------

# 🔄 End-to-end working

A complete creation looks like this:

``` text
1. User chooses:

   Name
   Symbol
   Decimals
   Max supply
   Salt

              ↓

2. B20Creator receives the request

              ↓

3. Creation parameters are ABI encoded

              ↓

4. Initialization calls are created

       ┌────────────────────────────┐
       │ Grant MINT_ROLE to caller  │
       ├────────────────────────────┤
       │ Set supply cap             │
       └────────────────────────────┘

              ↓

5. B20 factory receives:

       variant
       salt
       encoded parameters
       initialization calls

              ↓

6. Factory determines deterministic address

              ↓

7. B20 Asset identity is sealed

              ↓

8. Initialization calls execute

              ↓

9. Bootstrap window closes

              ↓

10. Token address is returned

              ↓

11. B20Creator stores:

       lastCreatedToken

              ↓

12. TokenCreated event is emitted

              ↓

13. Creator can interact with the B20 token
```

------------------------------------------------------------------------

# 📦 Project components at a glance

  File                   Responsibility
  ---------------------- -----------------------------------------
  `B20Creator.sol`       High-level B20 Asset creation
  `IB20Factory.sol`      Factory interface and creation types
  `B20FactoryLib.sol`    ABI encoding and initialization helpers
  `B20Constants.sol`     Roles, policies and protocol constants
  `StdPrecompiles.sol`   B20 factory precompile reference
  `IB20.sol`             Base B20 token interface
  `IB20Asset.sol`        Asset-specific interface
  `IERC165.sol`          Interface detection
  `IERC8056.sol`         Scaling/UI amount interfaces
  `artifacts/`           Compiled ABIs and metadata
  `.deps/`               Dependency information
  `remix.config.json`    Remix configuration
  `ERC721.sol`           Separate ERC-721 example

------------------------------------------------------------------------

# 🧪 Creating a token --- conceptual example

Suppose the we wants:

``` text
Name:        Quantum Token
Symbol:      QTM
Decimals:    18
Max Supply:  1,000,000
Salt:        chosen bytes32 value
```

The call becomes conceptually:

``` solidity
createToken(
    "Quantum Token",
    "QTM",
    18,
    1_000_000 ether,
    salt
);
```

The creator then prepares:

``` text
Token identity
      │
      ├── Quantum Token
      ├── QTM
      ├── 18 decimals
      └── creator as admin

Initialization
      │
      ├── creator gets MINT_ROLE
      └── cap = 1,000,000 tokens
```

Then the B20 factory creates the token.

------------------------------------------------------------------------

# ⚠️ Important details

### Decimals

For an Asset token:

``` text
6 ≤ decimals ≤ 18
```

Decimals are immutable after creation.

### Salt

The combination of:

``` text
variant + sender + salt
```

determines the token address.

If that address already exists, creation fails.

### Supply cap

The supply cap cannot be set below the current total supply and cannot
exceed `uint128.max`.

### Factory access

The factory's bootstrap privileges are temporary.

The factory does not permanently retain token roles after creation.

### Mint policy

The mint receiver policy is still enforced during initialization.

### Pause

Pause checks are not bypassed during bootstrap.

### Accounting

Supply and balance invariants remain enforced during creation.

------------------------------------------------------------------------

# 🛠️ Technology stack

``` text
Solidity
   │
   ├── Solidity ^0.8.20 / >=0.8.20 <0.9.0
   │
   ├── B20 interfaces
   │
   ├── ABI encoding
   │
   └── Protocol precompile integration

Development
   │
   └── Remix-oriented project structure

Standards / concepts
   │
   ├── ERC-20
   ├── ERC-165
   ├── EIP-2612 Permit
   ├── EIP-712-style signing domain
   └── ERC-8056-related scaling interfaces
```

------------------------------------------------------------------------

# 🚀 Why this architecture is useful

The project separates responsibilities cleanly.

Instead of putting everything inside one enormous contract:

``` text
B20Creator
     ↓
Factory
     ↓
B20 token
```

and each supporting component has a specific job.

### `B20Creator`

Makes token creation convenient.

### `B20FactoryLib`

Makes complicated ABI construction readable and reusable.

### `IB20Factory`

Defines how token creation works.

### `IB20`

Defines common token behavior.

### `IB20Asset`

Defines Asset-specific behavior.

### `B20Constants`

Keeps roles and policy identifiers consistent.

### `StdPrecompiles`

Connects the code to the protocol-level factory.

This makes the system easier to understand, integrate and extend.

------------------------------------------------------------------------

# 🔗 Contract relationship

``` text
                 B20Creator
                     │
                     │ imports
                     ▼
              B20FactoryLib
                     │
                     │ uses
                     ▼
              B20Constants
                     │
                     │ role identifiers
                     │
                     ▼
              B20Factory
                     │
                     │ creates
                     ▼
                  IB20
                     │
                     └──────► IB20Asset
```

------------------------------------------------------------------------

# 📚 Reading the code in the right order

If you are learning the repository, don't start with the 600+ line
`IB20.sol`.

A much easier order is:

``` text
1. B20Creator.sol
        ↓
2. StdPrecompiles.sol
        ↓
3. IB20Factory.sol
        ↓
4. B20FactoryLib.sol
        ↓
5. B20Constants.sol
        ↓
6. IB20.sol
        ↓
7. IB20Asset.sol
        ↓
8. ERC721.sol
```

Why is that?

Because `B20Creator.sol` tells you **why the other files exist**.

Once you understand:

``` text
createToken()
      ↓
createB20()
      ↓
initCalls
      ↓
B20 token
```

the rest of the repository becomes much easier to follow.

------------------------------------------------------------------------

# 🧭 Mental model

If you remember only one thing from this repository, remember this:

``` text
                 B20 is the token system
                          │
                          ▼
              ┌─────────────────────┐
              │    B20 Factory      │
              └──────────┬──────────┘
                         │
                   creates token
                         │
                         ▼
              ┌─────────────────────┐
              │     B20 Asset       │
              └─────────────────────┘
                         ▲
                         │
              configured during creation
                         │
              ┌──────────┴──────────┐
              │                     │
          B20Creator          initialization
              │                     │
              └─────────────────────┘
```

**`B20Creator` is the convenient entry point.\
`B20Factory` is the creation engine.\
`B20` is the resulting token system.**

------------------------------------------------------------------------

# 📖 Official source

This README is based on the code currently present in the repository:

**GitHub:**\
https://github.com/ItsMeQuantum/B20

The repository currently contains the B20 interfaces/helpers, generated
artifacts, Remix configuration and a separate ERC-721 example.

------------------------------------------------------------------------

## 📜 License

The Solidity B20 source files in the repository are marked:

``` text
MIT License
```

------------------------------------------------------------------------

```{=html}
<p align="center">
```
`<strong>`{=html}Built around B20. Author Quantum.`</strong>`{=html}
```{=html}
</p>
```
