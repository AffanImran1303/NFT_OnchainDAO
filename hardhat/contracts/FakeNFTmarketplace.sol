//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;


contract FakeNFTmarketplace{
    //Maintain a mapping of fake tokenID => Owner Address
    mapping(uint256=>address)public tokens;

    //Base price (for purchasing) of fake NFT
    uint256 nftPrice=0.001 ether;

//function purchase() accepts ETH and marks owner of given tokenID as caller address
    function purchase(uint256 _tokenID)external payable{
        require(msg.value==nftPrice,"Sorry, insufficent balance. Base cost of NFT is 0.001ether");
        tokens[_tokenID]=msg.sender;
    }
    //function getPrice() returns the price of one NFT
    function getPrice()external view returns(uint256){
        return nftPrice;
    }
    //function available() checks whether tokenID has already been sold or not
    function available(uint256 _tokenID)external view returns(bool){
        if(tokens[_tokenID]==address(0)){
            return true;
        }
        return false;
    }
}