// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Crowdfund.sol";
import "../src/SupporterNFT.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("MockUSD", "mUSD") {}

    function mint(address to, uint256 amt) external {
        _mint(to, amt);
    }
}

contract CrowdfundTest is Test {
    Crowdfund public cf;
    SupporterNFT public nft;
    address public creator = address(0xC0FFEE);
    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    function setUp() public {
        vm.deal(alice, 100 ether);
        vm.deal(bob, 50 ether);

        nft = new SupporterNFT("Backer", "BACK", "ipfs://CID/", address(this));
        cf = new Crowdfund(address(nft), address(this));
        nft.setMinter(address(cf));
    }

    function test_Create_ContributeETH_Withdraw() public {
        vm.prank(creator);
        uint256 id = cf.createCampaign(10 ether, 7 days, address(0));

        vm.prank(alice);
        cf.contributeETH{value: 6 ether}(id);

        vm.prank(bob);
        cf.contributeETH{value: 4 ether}(id);

        // too early to withdraw
        vm.expectRevert();
        vm.prank(creator);
        cf.withdraw(id);

        // after deadline and goal met
        vm.warp(block.timestamp + 7 days + 1);
        uint256 before = creator.balance;
        vm.prank(creator);
        cf.withdraw(id);
        assertEq(creator.balance, before + 10 ether, "creator received funds");
    }

    function test_Refund_WhenGoalNotMet() public {
        vm.prank(creator);
        uint256 id = cf.createCampaign(5 ether, 3 days, address(0));

        vm.prank(alice);
        cf.contributeETH{value: 1 ether}(id);

        vm.warp(block.timestamp + 3 days + 1);
        uint256 before = alice.balance;
        vm.prank(alice);
        cf.refund(id);
        assertEq(alice.balance, before + 1 ether, "alice refunded");
    }

    function test_ERC20_Path() public {
        // setup ERC20
        MockERC20 tok = new MockERC20();
        tok.mint(alice, 1_000e18);

        vm.prank(creator);
        uint256 id = cf.createCampaign(200e18, 2 days, address(tok));

        vm.startPrank(alice);
        tok.approve(address(cf), 200e18);
        cf.contributeERC20(id, 200e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days + 1);
        uint256 before = tok.balanceOf(creator);
        vm.prank(creator);
        cf.withdraw(id);
        assertEq(tok.balanceOf(creator) - before, 200e18, "creator got tokens");
    }
}
