// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";

contract NFTeeStaker is ERC20 {

    //we need a way for people to stake 1 or more NFTs

    // Every 24hours, they should be getting 1000 tokens - proparted for smaller times
    // unstake

    // Claim tokens

    //---
    // NFTee Contract
    // struct Staker

    IERC721 nftContract;

    uint256 constant SECONDS_PER_DAY = 24* 60 * 60;
    uint256 constant BASE_YIELD_RATE = 1000 ether; //1000 tokens

    struct Staker {
        // X numbers of tokens every 24h
        uint256 currYield;
        // How many tokens have they accumulated, bu tnot claimed so far
        uint256 rewards;
        //when last time reward were calculated on-chain
        uint256 lastCheckpoint;
        //which nft are they staking
        uint256[] stakedNFTs;
    }

    mapping(address => Staker) public stakers;
    mapping(uint256 => address) public tokenOwner;

    constructor(
        address _nftContract,
        string memory name, 
        string memory symbol
    ) ERC20(name, symbol){
        nftContract = IERC721(_nftContract);
    }

    function stake(uint256[] memory tokenIds) public{

        Staker storage user = stakers[msg.sender];

        uint256 yield = user.currYield;

        uint256 length = tokenIds.length;
        //for loop checks that the token is actually owener by the staker
        for (uint256 i = 0; i < length; i++){
            require(
                nftContract.ownerOf(tokenIds[i]) == msg.sender,
                "You can only stake your own NFTs"
            );

            nftContract.safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            tokenOwners[tokenIds[i]] = msg.sender;

            yield += BASE_YIELD_RATE;
            user.stakedNFTs.push(tokenIds[i]);
        }

        accumulate(msg.sender);

        user.currYield = yield;



    }

    function unstake(uint[] memory tokenIds) public{
        Staker storage user = stakers[msg.sender];

        uint256 yield = user.currYield;
        for(uint256 i = 0; i < tokenIds.length; i++){
            require(
                tokenOwner[tokenIds[i]] == msg.sender, "Not Orginal Owner"
            );

            require(
                nftContract.ownerOf(tokenIds[i] == address(this)), "NOT STAKED"
            );
        }

        tokenOwners[tokenIds[i]] = address(0);

        if (yield != 0) {
            yield -= BASE_YIELD_RATE;

        }

        nftContract.safeTransferFrom(
            address(this),
            msg.sender,
            tokenIds[i]
        );
   
        accumulate(smsg.sender);

        user.currYield = yield;


    }

    function claim() public{
        Staker storage user = stakers[msg.sender];

       accumulate(msg.sender);

       _mint(msg.sender, user.rewards);
       user.rewards = 0 ;

    }

    function accumulate(address staker) internal{
        stakers[staker].rewards += getRewards(staker);
        stakers[staker].lastCheckpoint = block.timestamp;

    }

    function getRewards(address staker) public view returns (uint256){
        Staker memory user = stakers[staker];
        

        if (user.lastCheckpoint == 0){
            return 0;
        }

        return 
        ((block.timestamp - user.lastCheckpoint) * user.currYield) / 
        SECONDS_PER_DAY;
    }

    function onERC721Received(
        address ,
        address ,
        uint256 tokenId,
        bytes calldata 
    ) eternal pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
        
    }
    
}
