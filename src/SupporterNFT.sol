// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SupporterNFT is ERC721, Ownable {
    string private _baseTokenURI;
    address public minter;
    uint256 public nextId = 1;

    error NotMinter();

    constructor(string memory name_, string memory symbol_, string memory baseURI_, address owner_)
        ERC721(name_, symbol_)
        Ownable(owner_)
    {
        _baseTokenURI = baseURI_;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMinter(address m) external onlyOwner {
        minter = m;
    }

    function mintTo(address to) external returns (uint256 tokenId) {
        if (msg.sender != minter) revert NotMinter();
        tokenId = nextId++;
        _safeMint(to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
