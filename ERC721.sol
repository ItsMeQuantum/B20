// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyERC721 is ERC721, Ownable {

    uint256 public tokenIdCounter;

    constructor() ERC721("PudgyPenguin", "PP") Ownable(msg.sender) {}

    function mintNFT(address to) public onlyOwner {
        _safeMint(to, tokenIdCounter);
        tokenIdCounter++;
    }
}