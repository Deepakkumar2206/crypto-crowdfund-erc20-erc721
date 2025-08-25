// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Crowdfund.sol";

contract Demo2 is Script {
    function run() external {
        // Load deployed Crowdfund
        address cfAddr = vm.parseAddress(vm.envString("CROWDFUND_ADDR"));
        Crowdfund cf = Crowdfund(cfAddr);

        // Load funded EOA from PRIVATE_KEY
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address creator = vm.addr(pk);

        vm.startBroadcast(pk);

        /**
         * 1) SUCCESS CASE – Goal met → Withdraw
         */
        uint256 successId = cf.createCampaign(
            0.01 ether,  // small goal
            1 days,      // deadline
            address(0)   // ETH
        );
        console2.log("Created SUCCESS campaign id:", successId);

        // Contribute more than goal
        cf.contributeETH{value: 0.02 ether}(successId);
        console2.log("Contributed 0.02 ETH to SUCCESS campaign");

        // Warp forward in time past deadline
        vm.warp(block.timestamp + 2 days);

        // Creator withdraws
        cf.withdraw(successId);
        console2.log("Creator withdrew funds for SUCCESS campaign");

        /**
         * 2) FAILURE CASE – Goal not met → Refund
         */
        uint256 failId = cf.createCampaign(
            1 ether,   // big goal
            1 days,
            address(0)
        );
        console2.log("Created FAILURE campaign id:", failId);

        // Contribute less than goal
        cf.contributeETH{value: 0.01 ether}(failId);
        console2.log("Contributed 0.01 ETH to FAILURE campaign");

        // Warp forward in time past deadline
        vm.warp(block.timestamp + 2 days);

        // Contributor refunds
        cf.refund(failId);
        console2.log("Contributor claimed refund for FAILURE campaign");

        vm.stopBroadcast();
    }
}
