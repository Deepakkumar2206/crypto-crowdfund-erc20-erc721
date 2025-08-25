// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Crowdfund.sol";

contract Demo is Script {
    function run() external {
        // Load the deployed Crowdfund address from .env
        address cfAddr = vm.parseAddress(vm.envString("CROWDFUND_ADDR"));
        Crowdfund cf = Crowdfund(cfAddr);

        // Load funded EOA from PRIVATE_KEY
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address contributor = vm.addr(pk);

        vm.startBroadcast(pk);

        // 1) Creator creates a campaign: 0.5 ETH goal, 3 days deadline, ETH as token
        uint256 id = cf.createCampaign(
            0.5 ether,    // goal
            3 days,       // duration
            address(0)    // ETH
        );

        console2.log("Created campaign id:", id);

        // 2) Calculate safe contribution (10% of balance)
        uint256 balance = contributor.balance;
        uint256 contribution = balance / 10; // 10% of current balance

        require(contribution > 0, "Not enough ETH to contribute");

        cf.contributeETH{value: contribution}(id);

        console2.log("Contributed", contribution, "wei from:", contributor);

        vm.stopBroadcast();
    }
}
