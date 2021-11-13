// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TicketIssuer.sol";
import "./PosterIssuer.sol";

contract TicketBookingSystem is Ownable {
    using Counters for Counters.Counter;

    /* 
      Showtitle and capacity is implicitly given to the token by the owner of 
      the TicketIssuer object, i.e. the TicketBookingSystem SC
    */
    struct Seat {
        uint64 date;
        uint32 seatNumber;
        uint32 seatRow;
        string link;
    }

    string private _showTitle;
    uint32 private _capacity;
    uint32 private _price;
    bool private _active;
    PosterIssuer private _posterIssuer;
    TicketIssuer private _ticketIssuer;
    Counters.Counter private _tokenIDs;

    constructor(string memory showTitle, uint32 capacity, uint32 price) {
        _showTitle = showTitle;
        _capacity = capacity;
        _price = price;
        _active = true;
        _ticketIssuer = new TicketIssuer(address(this));
        _posterIssuer = new PosterIssuer(address(this));
    }
    
    function buy(uint32 seatRow, uint32 seatNumber, uint32 date) external payable returns (uint256) {
        uint256 newTokenID = current(_tokenIDs);
      
        for (uint i=0; i<_tokenIDs; i++) {
            string json_string = _ticketIssuer.tokenURI(i);
            uint[] seatData = decodeJson(json_string);

            require(
              seatRow != seatRow2 &&
              seatNumber != seatNumber2 &&
              date != date2, 
              "Seat is already booked"
            );
        }

        Seat seat = Seat(_showTitle, date, seatNumber, seatRow, _price, "placeholder");
        _ticketIssuer.buy(msg.sender, newTokenID, seat);
        payable(owner()).transfer(price);
        increment(_tokenIDs);
        return newTokenID;
    }

    function decodeJson(string json_string) {
        
    }

    function verifyTicket(uint256 tokenID) external view returns (address) {
      return _ticketIssuer.ownerOf(tokenID);
    }
    
    function verifyPoster(uint256 tokenID) external view returns (address) {
      return _posterIssuer.ownerOf(tokenID);
    }

    function cancelShow() external onlyOwner {
        _active = false;
    }

    function refund(uint256 tokenID) external {
        require(_ticketIssuer.ownerOf(tokenID) == msg.sender, "Only the owner of the ticket can refund");
        require(!_active, "This show is not cancelled");
        payable(msg.sender).transfer(price);
    }

    function validate(uint256 tokenID) external  {
      require(block.timestamp - getDateFromID(tokenID) <= 72000 || block.timestamp - getDateFromID(tokenID) >= 0, "You can only enter 2 hours before show start");
      require(owner == msg.sender, "Only the owner of show can valditate the ticket");
      address recepient = verifyTicket(tokenID);
      _ticketIssuer.burn(tokenID);
      _posterIssuer.mint(recepient, tokenID);  
    }

    function tradeTicket(address from, address to, uint256 tokenID) external {
      require(_ticketIssuer.ownerOf(tokenID) == msg.sender, "Only the owner of the ticket can transfer");
      _ticketIssuer.transfer(from, to, tokenID);
    }
}