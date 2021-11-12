// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import ./TicketIssuer.sol;

contract TicketBookingSystem is Ownable {
    struct Seat {
        string showTitle;
        uint64 date;
        uint32 seatNumber;
        uint32 seatRow;
        uint32 price;
        string link;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string private _showTitle;
    uint32 private _capacity;
    uint32 private _price;
    bool private _active;
    TicketIssuer private _ticketIssuer;

    constructor(string memory showTitle, uint32 capacity, uint32 price) {
        _showTitle = showTitle;
        _capacity = capacity;
        _price = price;
        _active = true;
        _ticketIssuer = new TicketIssuer(address(this));
    }
    
    function buy(uint32 seatRow, uint32 seatNumber, uint32 date) public payable returns (uint256) {
        uint256 newTokenID = current(_tokenIds);
        Seat seat = Seat(_showTitle, date, seatNumber, seatRow, _price, "bruh");
        _ticketIssuer.mint(msg.sender, newTokenID, seat);
        payable(owner()).transfer(price);
        increment(_tokenIds);
        return newTokenID;
    }

    function verify(uint256 tokenID) public view returns (address) {
        return _ticketIssuer.ownerOf(tokenID);
    }

    function cancelShow() public onlyOwner {
        _active = false;
    }

    function refund(uint256 tickerID) public {
        require(_ticketIssuer.ownerOf(tickerID) == msg.sender, "Only the owner of the ticket can refund");
        require(!_active, "This show is not cancelled");
        payable(msg.sender).transfer(price);
    }
}