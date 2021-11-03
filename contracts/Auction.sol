// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../ethereum-erc721/src/contracts/tokens/nf-token-metadata.sol";
import "../ethereum-erc721/src/contracts/ownership/ownable.sol";


contract Auction is NFTokenMetadata, Ownable {
    
    struct MyNftoken {
        uint256 tokenid;
        string uri;
        bool on_auction;
    }

    uint256 _tokenId;
    mapping(uint256 =>bool) is_on_auction;
    mapping(uint256 =>uint) auction_begin_time;
    mapping(uint256 =>uint) auction_end_time;
    mapping(uint256 =>uint) auction_price;
    mapping(uint256 =>address payable) highest_bidder;
    mapping(uint256 =>address payable) beneficiary;

    event HighestPriceIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(){
        nftName = "3190104605";
        nftSymbol = "zynm";
        _tokenId = 0;
    }

    function mint(address _to, string calldata _uri) external onlyOwner {
        _tokenId++;
        super._mint(_to, _tokenId);
        super._setTokenUri(_tokenId, _uri);
        is_on_auction[_tokenId] = false;
    }

    function showMyNFT( address _address ) public view returns (MyNftoken[] memory) {
        MyNftoken[] memory count = new MyNftoken[](_tokenId);
        for(uint256 i=0;i<_tokenId;i++){
            count[i].tokenid = 0;
        }
        uint256 cou = 0;
        for (uint256 index = 0; index < _tokenId ; index++) {
           if( idToOwner[index+1] == _address ) {
                count[cou].tokenid = index+1;
                count[cou].uri = idToUri[index+1];
                count[cou].on_auction = is_on_auction[index+1];
                cou += 1;
            }
        }
        return count;
    }

    function beginAuction( uint begin_time, uint end_time, uint256 token, uint start_price, address payable beginner ) public {
        uint nowtime = block.timestamp;
        require( begin_time > nowtime );
        require( begin_time < end_time );
        require( token >0 );
        require( token <= _tokenId );
        require( is_on_auction[token] == false);

        is_on_auction[token] = true;
        auction_begin_time[token] = begin_time;
        auction_end_time[token] = end_time;
        auction_price[token] = start_price;
        beneficiary[token] = beginner;
        highest_bidder[token] = beginner;
    }

    function bid( address payable bidder, uint256 token ) public payable {
        uint nowtime = block.timestamp;
        uint amount = msg.value;
        require( nowtime >= auction_begin_time[token], "Auction starts later." );
        require( nowtime < auction_end_time[token], "Auction already ended." );
        require( amount > auction_price[token], "There already is a higher bid." );
        
        if(highest_bidder[token] != beneficiary[token])
            highest_bidder[token].transfer(auction_price[token]);
        auction_price[token] = amount;
        highest_bidder[token] = bidder;

        emit HighestPriceIncreased( bidder, amount );
    }

    function auctionEnd( uint256 token ) public onlyOwner {
        uint nowtime = block.timestamp;
        require( nowtime >= auction_end_time[token], "Auction not yet ended." );
        //require( !is_on_auction[token], "auctionEnd has already been called." );

        is_on_auction[token] = false;

        emit AuctionEnded( highest_bidder[token], auction_price[token] );

        beneficiary[token].transfer(auction_price[token]);
        address from = idToOwner[token];
        delete idToApproval[token];

        _removeNFToken(from, token);
        _addNFToken(highest_bidder[token], token);

        emit Transfer(from, highest_bidder[token], token);
    }
}

