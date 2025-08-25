// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ISupporterNFT {
    function mintTo(address to) external returns (uint256);
}

contract Crowdfund is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    struct Campaign {
        address creator;
        address token;      // address(0) = ETH, otherwise ERC20 address
        uint256 goal;
        uint64  deadline;   // unix seconds
        uint256 totalRaised;
        bool    withdrawn;
    }

    event CampaignCreated(
        uint256 indexed id,
        address indexed creator,
        address indexed token,
        uint256 goal,
        uint64 deadline
    );

    event Contributed(
        uint256 indexed id,
        address indexed contributor,
        uint256 amount,
        address indexed token
    );

    event Withdrawn(uint256 indexed id, address indexed to, uint256 amount);
    event Refunded(uint256 indexed id, address indexed to, uint256 amount);

    error InvalidDeadline();
    error InvalidAmount();
    error NotCreator();
    error DeadlineNotPassed();
    error GoalNotMet();
    error AlreadyWithdrawn();
    error NothingToRefund();
    error WrongCurrency();

    ISupporterNFT public immutable nft;
    uint256 public nextCampaignId;

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public contributions; // id => user => amount

    constructor(address _nft, address _owner) Ownable(_owner) {
        nft = ISupporterNFT(_nft);
    }

    function createCampaign(
        uint256 goal,
        uint64 durationSeconds,
        address token // 0 for ETH, or ERC20 address
    ) external returns (uint256 id) {
        if (durationSeconds < 1 hours) revert InvalidDeadline();
        id = nextCampaignId++;

        uint64 deadline = uint64(block.timestamp) + durationSeconds;

        campaigns[id] = Campaign({
            creator: msg.sender,
            token: token,
            goal: goal,
            deadline: deadline,
            totalRaised: 0,
            withdrawn: false
        });

        emit CampaignCreated(id, msg.sender, token, goal, deadline);
    }

    // -------- Contributions --------

    function contributeETH(uint256 id) external payable nonReentrant {
        Campaign storage c = campaigns[id];
        if (c.token != address(0)) revert WrongCurrency();
        if (block.timestamp > c.deadline) revert DeadlineNotPassed(); // too late
        if (msg.value == 0) revert InvalidAmount();

        contributions[id][msg.sender] += msg.value;
        c.totalRaised += msg.value;

        emit Contributed(id, msg.sender, msg.value, address(0));
        nft.mintTo(msg.sender);
    }

    function contributeERC20(uint256 id, uint256 amount) external nonReentrant {
        Campaign storage c = campaigns[id];
        if (c.token == address(0)) revert WrongCurrency();
        if (block.timestamp > c.deadline) revert DeadlineNotPassed(); // too late
        if (amount == 0) revert InvalidAmount();

        IERC20(c.token).safeTransferFrom(msg.sender, address(this), amount);
        contributions[id][msg.sender] += amount;
        c.totalRaised += amount;

        emit Contributed(id, msg.sender, amount, c.token);
        nft.mintTo(msg.sender);
    }

    // -------- Payouts --------

    function withdraw(uint256 id) external nonReentrant {
        Campaign storage c = campaigns[id];
        if (msg.sender != c.creator) revert NotCreator();
        if (block.timestamp <= c.deadline) revert DeadlineNotPassed(); // not yet
        if (c.totalRaised < c.goal) revert GoalNotMet();
        if (c.withdrawn) revert AlreadyWithdrawn();

        c.withdrawn = true;
        uint256 amount = c.totalRaised;

        if (c.token == address(0)) {
            (bool ok, ) = payable(c.creator).call{value: amount}("");
            require(ok, "ETH send failed");
        } else {
            IERC20(c.token).safeTransfer(c.creator, amount);
        }

        emit Withdrawn(id, c.creator, amount);
    }

    function refund(uint256 id) external nonReentrant {
        Campaign storage c = campaigns[id];
        if (block.timestamp <= c.deadline) revert DeadlineNotPassed(); // not yet
        if (c.totalRaised >= c.goal) revert GoalNotMet();

        uint256 bal = contributions[id][msg.sender];
        if (bal == 0) revert NothingToRefund();
        contributions[id][msg.sender] = 0;

        if (c.token == address(0)) {
            (bool ok, ) = payable(msg.sender).call{value: bal}("");
            require(ok, "ETH refund failed");
        } else {
            IERC20(c.token).safeTransfer(msg.sender, bal);
        }

        emit Refunded(id, msg.sender, bal);
    }

    // -------- Views --------

    function getCampaign(uint256 id)
        external
        view
        returns (
            address creator,
            address token,
            uint256 goal,
            uint64 deadline,
            uint256 totalRaised,
            bool withdrawn_
        )
    {
        Campaign storage c = campaigns[id];
        return (c.creator, c.token, c.goal, c.deadline, c.totalRaised, c.withdrawn);
    }
}
