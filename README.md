# Flair: Flexible Hierarchical Drawing Pools

## Introduction
This repository contains the smart contracts for the Flexible Hierarchical Drawing Pools. The main contract is deployed on opBNB. The contract allows for the customization of Hierarchical Drawing Pools so that game developers can freely customize pool probabilities at each level according to their game design at launch, updates, and new releases while maintaining constant and fair pull rates.

The following document contains the setup instructions for our smart contracts, which has several roles to setup. Follow the steps below to set up each contract:
## Contracts Structure
![Alt text](./FlowChart.png?raw=true "Contract Structure")
### Roles
1. Owner: The owner of the contracts, who can set up configurations, grant and revoke roles.
3. Seller: The seller of the drawing contract, who can call ```setUserDrawable``` to set users drawable amount.
4. Fulfiller: The fulfiller of the drawing contract, who can call ```fulfillRandomWords``` to return random words to the request.
5. Executor: The executor of the drawing contract, who can call ```execRequest``` for drawing.
6. User: Calls ```purchashPack``` from marketplace contracts to buy the game pack, and call ```sendRequest``` from drawing contract to draw the prize.

---

## Setup steps
### Hierarchical Prize Pool Contract
1. setNFTcontract and setVRFGenerator.
2. setTokenPool and setTokenMaxAmount.
3. setUnitPool.
4. setDrawingPool.
6. Grants Seller role to Marketplace contract.
7. Grants Fulfiller role to VRF Generator contract.
8. Grants Executor role to EOA or automatic contract.

### VRF Generator Contract
1. In this repo we fulfilled by ourself, but you can set your contract using https://oracle.binance.com/docs/vrf/overview.

### ERC-1155 NFT Contract 
1. Grant Minter role to Hierarchical Prize Pool Contract.

---

## Deployed Contracts:
### opBNB Testnet
1. Hierarchical drawing contract: `0x5701d7610dEFa4fA2d79ec32b29977c447CD3888`  
2. ERC-1155 NFT contract: `0x81F3476F47A62aC1A225F2aB5B11F4ce72aCC0d9`  
3. VRF Manager:
`0xf0bd274008aA62BF8cbD7d0c308CF599138F257B`  
4. Marketplace: `0x1d39dc8a779024285e3b4Ac5ca9F68A799Bb27f3`  
5. USDT test token: `0xDE9504986Db4fec3C23BBFA36cd8199c3967bb02`
---

## Resources
1. VRF Request Status URL: https://oracle.binance.com/docs/vrf/overview
