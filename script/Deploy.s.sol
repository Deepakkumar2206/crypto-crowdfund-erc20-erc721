// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SupporterNFT.sol";
import "../src/Crowdfund.sol";

contract Deploy is Script {
    function run() external {
        // load env
        address owner = vm.envAddress("OWNER_ADDRESS");
        string memory baseURI = vm.envString("NFT_BASE_URI");

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // 1) Deploy NFT
        SupporterNFT nft = new SupporterNFT("Backer", "BACK", baseURI, owner);

        // 2) Deploy Crowdfund (owner receives ownership)
        Crowdfund cf = new Crowdfund(address(nft), owner);

        // 3) Allow crowdfund to mint NFTs
        nft.setMinter(address(cf));

        vm.stopBroadcast();

        console2.log("SupporterNFT:", address(nft));
        console2.log("Crowdfund  :", address(cf));
    }
}
