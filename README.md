# Pactum Smart Contract

**A guild governance and venture coordination protocol driven by reputation and council deliberation.**

## Overview

Pactum is a decentralized protocol that enables guild craftsmen to initiate ventures, deliberate in council, endorse or object to proposals, and allocate treasury resources. The system uses a reputation-based governance model where guild standing determines influence, ensuring collective decision-making aligns with merit.

## Key Features

- **Venture Initiation**: Guild craftsmen can propose new ventures with detailed charters
- **Council Deliberation**: Reputation-weighted voting system for venture approval
- **Treasury Management**: Secure fund allocation for approved ventures
- **Reputation System**: Guild standing points that determine voting power
- **Multi-Venture Coordination**: Batch processing for efficient operations

## Core Concepts

### Guild Standing (Reputation)
- Each craftsman has a reputation score that determines their influence
- Guild standing can be transferred between members
- Total guild reputation is tracked and maintained
- Minimum standing of 1 required to participate in governance

### Venture Lifecycle
1. **Initiation**: Craftsman proposes venture with charter and treasury requirements
2. **Council Deliberation**: Guild members vote to endorse or object (1440 blocks/~10 days)
3. **Commencement**: Approved ventures receive treasury funds and begin execution

### Council Process
- Voting period: 1440 blocks (~10 days on Stacks blockchain)
- Each craftsman can vote once per venture
- Vote weight equals craftsman's guild standing
- Ventures approved when endorsements exceed objections

## Smart Contract Functions

### Read-Only Functions

#### `inspect-craftsman-standing`
```clarity
(inspect-craftsman-standing (guild-member principal))
```
Returns the guild standing (reputation) of a specific craftsman.

#### `examine-guild-venture`
```clarity
(examine-guild-venture (venture-id uint))
```
Retrieves complete details of a guild venture by ID.

#### `craftsman-has-deliberated`
```clarity
(craftsman-has-deliberated (venture-id uint) (guild-member principal))
```
Checks if a craftsman has already voted on a specific venture.

### Public Functions

#### `initiate-guild-venture`
```clarity
(initiate-guild-venture 
  (expedition-name (string-ascii 50)) 
  (venture-charter (string-utf8 500)) 
  (treasury-requirement uint) 
  (venture-beneficiary principal))
```
Creates a new venture proposal. Requires:
- Craftsman must have guild standing ≥ 1
- Valid treasury amount (1 to 1,000,000,000 microSTX)
- Valid expedition name (≤ 50 characters)
- Valid charter (≤ 500 characters)
- Valid beneficiary address

#### `participate-in-council`
```clarity
(participate-in-council (venture-id uint) (endorse-venture bool))
```
Allows craftsmen to vote on venture proposals. Features:
- Must vote before council deadline
- One vote per craftsman per venture
- Vote weight equals craftsman's guild standing
- `endorse-venture`: true to support, false to object

#### `commence-approved-venture`
```clarity
(commence-approved-venture (venture-id uint))
```
Executes approved ventures after council period ends. Requirements:
- Council deliberation period must be complete
- Venture not already commenced
- Guild endorsements must exceed objections
- Transfers treasury funds to venture beneficiary

#### `contribute-to-guild-coffers`
```clarity
(contribute-to-guild-coffers (amount uint))
```
Allows members to contribute STX to the guild treasury.

#### `bestow-guild-standing`
```clarity
(bestow-guild-standing (amount uint) (apprentice principal))
```
Distributes guild standing points to members. Restricted to contract calls only.

#### `transfer-guild-standing`
```clarity
(transfer-guild-standing (amount uint) (fellow-craftsman principal))
```
Transfers guild standing between craftsmen. Sender must have sufficient standing.

### Batch Operations

#### `mass-commence-ventures`
```clarity
(mass-commence-ventures (venture-ids (list 10 uint)))
```
Executes multiple approved ventures in a single transaction (up to 10).

#### `guild-collective-deliberation`
```clarity
(guild-collective-deliberation (deliberation-list (list 10 {venture-id: uint, endorse-venture: bool})))
```
Processes multiple council votes in a single transaction (up to 10).

## Data Structures

### Guild Venture Record
```clarity
{
  venture-master: principal,      // Venture proposer
  expedition-name: string-ascii,  // Venture name (≤50 chars)
  venture-charter: string-utf8,   // Detailed description (≤500 chars)
  treasury-requirement: uint,     // Required funding amount
  venture-beneficiary: principal, // Fund recipient
  guild-endorsements: uint,       // Total endorsement weight
  craftsman-objections: uint,     // Total objection weight
  council-deadline: uint,         // Voting deadline (block height)
  commenced: bool                 // Execution status
}
```

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | ERR_NOT_GUILD_CRAFTSMAN | Caller lacks required guild standing |
| u101 | ERR_CRAFTSMAN_ALREADY_DELIBERATED | Member already voted on this venture |
| u102 | ERR_COUNCIL_SESSION_ENDED | Voting period has expired |
| u103 | ERR_INVALID_TREASURY_AMOUNT | Invalid funding amount |
| u104 | ERR_INSUFFICIENT_GUILD_STANDING | Insufficient reputation for action |
| u105 | ERR_VENTURE_PROPOSAL_MISSING | Venture ID not found |
| u106 | ERR_VENTURE_ALREADY_COMMENCED | Venture already executed |
| u107 | ERR_DEFECTIVE_VENTURE_RECORD | Invalid venture data |
| u108 | ERR_INVALID_GUILD_MEMBER | Invalid member address |
| u109 | ERR_GUILD_COORDINATION_FAILURE | Batch operation failed |

## Usage Examples

### Proposing a New Venture
```clarity
(contract-call? .pactum initiate-guild-venture 
  "Market Expansion" 
  "Establish trading post in the northern territories to expand guild influence and generate revenue through merchant partnerships."
  u5000000
  'SP1ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789)
```

### Participating in Council
```clarity
;; Endorse a venture
(contract-call? .pactum participate-in-council u1 true)

;; Object to a venture  
(contract-call? .pactum participate-in-council u1 false)
```

### Executing Approved Venture
```clarity
(contract-call? .pactum commence-approved-venture u1)
```

## Security Considerations

- **Access Control**: Most functions require guild membership (standing ≥ 1)
- **Single Vote**: Each craftsman can only vote once per venture
- **Time Locks**: Council deliberation period prevents rushed decisions
- **Amount Validation**: Treasury amounts capped at 1 billion microSTX
- **Address Validation**: Prevents transfers to invalid addresses

## Guild Treasury

The contract maintains a treasury funded through:
- Member contributions via `contribute-to-guild-coffers`
- Initial contract deployment funds
- Treasury funds are allocated to approved ventures automatically

## Governance Model

Pactum implements a **reputation-weighted democracy** where:
- Guild standing determines voting power
- Higher reputation members have greater influence
- Collective wisdom guides resource allocation
- Merit-based participation ensures quality decisions

## Technical Specifications

- **Blockchain**: Stacks Network
- **Language**: Clarity Smart Contract Language
- **Council Period**: 1440 blocks (~10 days)
- **Max Batch Size**: 10 operations
- **String Limits**: Names (50 chars), Charters (500 chars)

## Getting Started

1. **Join the Guild**: Acquire guild standing through contributions or transfers
2. **Propose Ventures**: Submit detailed proposals with funding requirements
3. **Participate in Council**: Vote on active proposals during deliberation periods
4. **Execute Ventures**: Commence approved projects and coordinate execution

## Contract Deployment

Deploy with sufficient STX balance to fund initial guild operations and venture approvals.

