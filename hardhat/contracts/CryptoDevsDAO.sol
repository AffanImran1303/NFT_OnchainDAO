//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

//Adding two interface to call the functions

//Interface for FakeNFTMarketplace
interface IFakeNFTmarketplace{
    //Returns price of an NFT
    function getPrice()external view returns(uint256);

    //Returns whether given _tokenID has purchased NFT or not
    function available(uint256 _tokenID)external view returns(bool);

    //Make a purchase of an NFT from FakeNFTmarketplace
    function purchase(uint256 _tokenID)external payable;
}

//Interface for CryptoDevs
interface ICryptoDevsNFT{

    //Returns no.of NFTs owned by the given address
    function balanceof(address owner)external view returns(uint256);

    //Returns a tokenID at given index for owner
    function tokenOfOwnerbyIndex(address owner, uint256 index) external view returns(uint256);
}

contract CryptoDevsDAO is Ownable(msg.sender){
    //Struct proposal containing all relevant information
    struct Proposal{
        
        //nftTokenID -> tokenID of NFT to purchase from FakeNFTMarketplace
        uint256 nftTokenID;

        //deadline -> UNIX timestamp until which proposal is active
        uint256 deadline;

        //Yesvotes -> Total no. of Yes votes for proposal
        uint256 yesVotes;

        //Novotes -> Total no. of No votes for proposal
        uint256 noVotes;

        //executed -> whether proposal is executed or not
        bool executed;

        //voters -> indicating whether that NFT has already been used to cast a vote or not
        mapping(uint256 => bool) voters;
    }

    //Mapping of ID to Proposal to hold all created proposals
    mapping(uint256 => Proposal) public proposals;

    //No. of proposals that have been created
    uint256 public numProposals;

    //An enum containing possible options for a vote
    enum Vote{
        YES, 
        NO
    }
    IFakeNFTmarketplace nftMarketplace;
    ICryptoDevsNFT cryptodevsNFT;
    //Will initialize the contract variables, accept ETH deposit from the deployer
    constructor(address _nftMarketplace, address _cryptoDevsNFT)payable{
        nftMarketplace=IFakeNFTmarketplace(_nftMarketplace);
        cryptodevsNFT=ICryptoDevsNFT(_cryptoDevsNFT);
        }
    
    //Someone who owns at least 1 CryptoDevsNFT can call this function
    modifier nftHolderOnly(){
        require(cryptodevsNFT.balanceof(msg.sender)>0,"NOT A DAO MEMBER");
        _;
    }

    //To be called if proposal's deadline has not been exceeded 
    modifier activeProposalOnly(uint256 proposalIndex){
        require(proposals[proposalIndex].deadline>block.timestamp,"DEADLINE_EXCEEDED");
    _;
    }

            //To be called if the given proposal deadline has been exceeded and if proposal has not been executed
        modifier inactiveProposalOnly(uint256 proposalIndex){
            require(proposals[proposalIndex].deadline<=block.timestamp,"DEADLINE_NOT_EXCEEDED");
            require(proposals[proposalIndex].executed==false,"PROPOSAL_ALREADY_EXECUTED");
            _;
        }
        
    //Allows CryptoDevsNFT holder to create new proposal in DAO
    //_nftTokenID -> tokenID of NFT to be purchased from FakeNFTMarketplace
    function createProposal(uint256 _nftTokenID)external nftHolderOnly returns(uint256){
        require(nftMarketplace.available(_nftTokenID),"NFT_NOT_FOR_SALE");
        Proposal storage proposal=proposals[numProposals];
        proposal.nftTokenID=_nftTokenID;

        //Setting the proposal's voting deadline
        proposal.deadline=block.timestamp+5 minutes;
        numProposals++;
        return numProposals-1;
    
    }

    //Allows CryptoDevsNFT holder to cast their vote on active proposal
    //proposalIndex -> index of proposal to vote on, in proposals array
    //vote -> type of vote they want to cast
    function voteOnProposal(uint256 proposalIndex, Vote vote)external nftHolderOnly activeProposalOnly(proposalIndex){
        Proposal storage proposal=proposals[proposalIndex];
        uint256 voterNFTBalance=cryptodevsNFT.balanceof(msg.sender);
        uint256 numVotes=0;


        //For loop to calculate how many NFTs are owned by voter that aren't used for voting on this proposal
        for (uint256 i=0;i<voterNFTBalance;i++){
            uint256 tokenId=cryptodevsNFT.tokenOfOwnerbyIndex(msg.sender,i);
            if (proposal.voters[tokenId]==false){
                numVotes++;
                proposal.voters[tokenId]=true;
            }
        }
        require(numVotes>0,"ALREADY_VOTED");
        if(vote==Vote.YES){
            proposal.yesVotes+=numVotes;
        }
        else{
            proposal.noVotes+=numVotes;
        }

    }

    //Allows any CryptoDevsNFT holder to execute a proposal after its deadline has been exceeded
    //proposalIndex -> index of proposal to execute in proposals array
    function executeProposal(uint256 proposalIndex)external nftHolderOnly inactiveProposalOnly(proposalIndex){
        Proposal storage proposal = proposals[proposalIndex];

        //If Yesvotes>Novotes, purchase the NFT from FakeNFTMarketplace
        if(proposal.yesVotes>proposal.noVotes){
            uint256 nftPrice=nftMarketplace.getPrice();
            require(address(this).balance>=nftPrice,"NOT_ENOUGH_FUNDS");
            nftMarketplace.purchase{value:nftPrice}
            (proposal.nftTokenID);

        }
        proposal.executed=true;
    }

    //Allows the contract owner (deployer) to withdraw the ETH from contract
    //IF EXECUTED, this will TRANSFER ENTIRE ETH BALANCE of the contract to OWNER ADDRESS
    function withdrawEther()external onlyOwner{
        uint256 amount=address(this).balance;
        require(amount>0,"Nothing to withdraw, balance empty");
        (bool sent,)=payable(owner()).call{value:amount}("");
        require(sent, "FAILED_TO_WITHDRAW_ETHER");
    }

    //Following 2 functions allow contract to accept the ETH deposits
    //Directly from a wallet without calling a function
    receive()external payable{

    }
    fallback()external payable{
        
    }
}