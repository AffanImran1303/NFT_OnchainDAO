//CryptoDevs -> basic contract that allows anyone to mint new NFT

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


contract CryptoDevsNFT is ERC721Enumerable{
    //Initializing the ERC-721 Contract
    constructor()ERC721("CryptoDevs","CD"){
    }

    //Public mint function, anyone can call to mint the NFT
    function mint()public{
        _safeMint(msg.sender,totalSupply());
    }
}