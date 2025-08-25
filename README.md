## Crypto Crowdfund + Supporter NFT (ERC20 + ERC721)

### A decentralized crowdfunding dApp where users can create campaigns, contribute in ETH/ERC20, and receive NFT supporter badges.

#### Features
- Create Campaigns - with funding goal, deadline, and ETH or ERC20 token.
- Contribute - supporters contribute ETH/ERC20 before deadline.
- Lifecycle:
     - If goal met - creator withdraws funds.
     - If not met - contributors claim refund.
- NFT Supporter Badge - each contribution mints an ERC-721 badge with metadata hosted on IPFS/Pinata.
- Events - CampaignCreated, Contributed, Withdrawn, Refunded.
- Tests - Full test suite + ERC20/ETH paths covered.
- Gas Reports - optimize storage and track gas usage.

### Setup
- Clone + install dependencies:

```shell
git clone https://github.com/Deepakkumar2206/crypto-crowdfund-erc20-erc721.git
cd crypto-crowdfund-erc20-erc721

# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Example .env file

```shell
RPC_URL=https://sepolia.infura.io/v3/<your-api-key>
PRIVATE_KEY=0xyourwalletprivatekey
OWNER_ADDRESS=0xyourwalletaddress

CROWDFUND_ADDR=0xDeployedCrowdfundAddress
NFT_ADDR=0xDeployedNFTAddress
```

### Contracts
#### Crowdfund.sol - Core crowdfunding logic.
- Create campaigns with goal, deadline, and funding currency (ETH or ERC20).
- Contribute in ETH or ERC20 before deadline.
- If goal met - creator can withdraw.
- If not met - contributors can claim refund.
- Emits events for campaign lifecycle (created, contributed, withdrawn, refunded).

#### SupporterNFT.sol - ERC721 NFT badge.
- Every contribution mints a unique NFT for the supporter.
- Metadata hosted on IPFS (Pinata).
- Acts as proof of contribution / supporter badge.

#### Demo.s.sol - Script that creates a campaign and shows contribution flow (with NFT mint).
- Used to test single campaign flow live.

#### Demo2.s.sol - Extended script that simulates:
- Success campaign - contributions, creator withdraws.
- Failure campaign - contributions, contributors refund.
- Demonstrates full lifecycle of campaigns.

#### Crowdfund.t.sol - Test suite covering:
- ETH contribution flow (create, contribute, withdraw).
- ERC20 contribution path (approve, contribute, withdraw).
- Refund path when goal not met.
- NFT minting checks per contribution.

### Metadata & Image Hosting (Pinata/IPFS)

#### - Image Upload - The supporter badge image (supporter.png) was uploaded to Pinata (IPFS pinning service).
#### - Metadata JSON - A JSON file was created pointing to this image CID, e.g.:

```shell
{
  "name": "Supporter Badge",
  "description": "NFT badge for crowdfund supporters",
  "image": "ipfs://<imageCID>/supporter.png"
}
```

#### - Pinata Gateway - The JSON + image is accessible via https://ipfs.io/ipfs/<CID> links.

#### - Each contribution mints an NFT - tokenURI points to the IPFS JSON metadata.


### Infura (Sepolia RPC Provider)
#### - We used Infura to connect Foundry (Forge/Cast) with the Sepolia testnet.


### Commands
#### Build & Test

```shell
# Compile
forge build

# Run tests with full traces
forge test -vvvv

# Gas report
forge snapshot
```

#### Deployment

```shell
# Deploy Crowdfund + NFT
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
```

### Interaction

```shell
# Create Campaign (Goal: 0.1 ETH, Duration: 1 hr, Token: ETH)
cast send $CROWDFUND_ADDR "createCampaign(uint256,uint64,address)" \
  100000000000000000 3600 0x0000000000000000000000000000000000000000 \
  --private-key $PRIVATE_KEY --rpc-url $RPC_URL

# Contribute 0.02 ETH to Campaign #1
cast send $CROWDFUND_ADDR "contributeETH(uint256)" 1 \
  --value 20000000000000000 \
  --private-key $PRIVATE_KEY --rpc-url $RPC_URL

# Check NFT balance
cast call $NFT_ADDR "balanceOf(address)(uint256)" $OWNER_ADDRESS --rpc-url $RPC_URL

# Check NFT owner
cast call $NFT_ADDR "ownerOf(uint256)(address)" 2 --rpc-url $RPC_URL

# Check NFT metadata (IPFS)
cast call $NFT_ADDR "tokenURI(uint256)(string)" 2 --rpc-url $RPC_URL
```

### Deployed Contracts (Sepolia)

```shell
Crowdfund Contract - https://sepolia.etherscan.io/address/0xF66Ba6b038FBF88EcD004CeBf2C1D4598DACfC45

Supporter NFT Contract - https://sepolia.etherscan.io/address/0xe319004B0C05EdBB59B45B4f791f051fdcC41457
```

### NFT Showcase
```shell
NFT Token #2 Owner → 0xF8A8F8BB42C680Fd5C1EEd2d1c5D638E2C4f4B78

NFT Metadata (Token #2) → https://ipfs.io/ipfs/bafybeifcg3rzin4nyeqkrkxw2zeo4mdzlwyvzrlxjr7rb2qebtcavonxje/2

NFT Image - https://ipfs.io/ipfs/bafybeib6hxjnialf2fqmjdrf3f5hlw5d4bfywnfc4p4cexrhj3ptex2l74
```

### Sample Output (Demo2.s.sol)

```shell
== Logs ==
  Created SUCCESS campaign id: 1
  Contributed 0.02 ETH to SUCCESS campaign
  Creator withdrew funds for SUCCESS campaign
  Created FAILURE campaign id: 2
  Contributed 0.01 ETH to FAILURE campaign
  Contributor claimed refund for FAILURE campaign
```

### Key Takeaways
- Built full crowdfunding lifecycle: create campaigns, contribute, withdraw, refund.
- Added supporter NFT badges for every contribution with IPFS metadata.
- Handled both ETH & ERC20 contributions with SafeERC20.
- Implemented access control (only creator can withdraw).
- Enforced time-based deadlines using block.timestamp.
- Emitted detailed events (creation, contribution, withdraw, refund) for transparency.
- Wrote a full Foundry test suite (covering success + refund paths).
- Generated gas reports and optimized storage with mappings/struct packing.
- Deployed & interacted via Forge scripts and Cast commands.
- Verified NFT metadata on IPFS/Pinata.

 #### Github Actions 
 - CI/CD (Continuous Integration & Deployment) can be added using GitHub Actions. 
 - A workflow (ci.yml) inside .github/workflows/ will automatically run formatting, build, tests, and gas snapshots on every push or pull request.
 - Since this project was built under the 15daysfoundary folder, GitHub Actions wasn’t added here. But in a standalone repo, just place the workflow file at the root to enable it.

## End of the Project.
