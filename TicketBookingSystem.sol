// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TicketIssuer.sol";
import "./PosterIssuer.sol";

contract TicketBookingSystem  {
    struct Swap {
        uint256 requestedTokenID;
        uint16 requestedPrice;
    }
    address private _owner;
    string private _showTitle;
    uint16 private _numRows; // max ticket y coordinate
    uint16[] private _numCols; // max ticket x coordinate given y coordinate
    uint16[] private _rowPrice;
    mapping(uint40 => bool) private _cancelledDates;
    mapping(address => address) private _offeredTickets;
    mapping(uint256 => Swap) private _marketplace;  // offeredTokenID => Swap
    PosterIssuer private _posterIssuer;
    TicketIssuer private _ticketIssuer;

    constructor(string memory showTitle, uint16 numRows, uint16[] memory numCols, uint16[] memory rowPrice) {
        _owner = msg.sender;
        _showTitle = showTitle;
        _numRows = numRows;
        _numCols = numCols;
        _rowPrice = rowPrice;
        _ticketIssuer = new TicketIssuer(address(this));
        _posterIssuer = new PosterIssuer(address(this));
    }

    function buy(uint16 seatRow, uint16 seatNumber, uint40 date) external payable returns (uint256) {
        require(
            msg.value >= _rowPrice[seatRow-1], 
            "You need to pay more"
        );
        uint256 newTokenID = _toID(seatRow, seatNumber, date);
        _ticketIssuer.buy(msg.sender, newTokenID, "https://seatplan.com/");
        payable(_owner).transfer(_rowPrice[seatRow-1]);
        return newTokenID;
    }

    function refund(uint256 tokenID) external {
        (uint160 showID, uint40 date, uint16 seatRow, uint16 seatNumber) = _fromID(tokenID);
        require(
            _ticketIssuer.ownerOf(tokenID) == msg.sender,
            "Only the owner of the ticket can refund"
        );
        require(
            _cancelledDates[date], 
            "This show is not cancelled"
        );
        payable(msg.sender).transfer(_rowPrice[seatRow]);
        _ticketIssuer.burn(tokenID); // To prohibit a user to refund an infinite amount of times
    }

    function validate(uint256 tokenID) external {
        (uint160 showID, uint40 date, uint16 seatRow,uint16 seatNumber) = _fromID(tokenID);
        address ticketOwner = verifyTicket(tokenID);

        require(
            showID == uint160(address(this)),
            "TokenID does not correspond to the given movie"
        );
        /*
        require(
            block.timestamp - date <= 72000 || block.timestamp - date >= 0, 
            "You can only enter 2 hours before show start"
        );
        */
        require(
            ticketOwner == msg.sender,
            "Only the owner of the ticket can validate"
        );
        require(
            1 <= seatRow && seatRow <= _numRows && 1 <= seatNumber && seatNumber <= _numCols[seatRow-1],
            "Seat is unvalid"
        );

        _ticketIssuer.burn(tokenID);
        _posterIssuer.mint(ticketOwner, tokenID);
    }
    
    function putOnMarket( uint256 offeredTokenID, uint256 requestedTokenID, uint16 requestedPrice) external {
        require(
             (requestedTokenID != 0 && requestedPrice == 0) || (requestedTokenID == 0 && requestedPrice != 0), 
            "Either a ticket or ether must be requested"
        );
        require(
            _ticketIssuer.ownerOf(offeredTokenID) == msg.sender, 
            "Only the owner of the ticket can trade it"
        );
        Swap memory swap = Swap(requestedTokenID, requestedPrice);
        _marketplace[offeredTokenID] = swap;
    }

    function tradeTicket(uint256 requestedTokenID, uint256 offeredTokenID) external payable {
        require(
            _marketplace[requestedTokenID].requestedTokenID != 0 || _marketplace[requestedTokenID].requestedPrice != 0,
            "Requested ticket is not on the marketplace"
        );
        
        // Trade token for token
        if (_marketplace[requestedTokenID].requestedTokenID != 0) {
            require(
                _ticketIssuer.ownerOf(offeredTokenID) == msg.sender, 
                "Only the owner of the ticket can trade it"
            );
            require(
                offeredTokenID == _marketplace[requestedTokenID].requestedTokenID, 
                "Required ticket not provided"
            );
            _ticketIssuer.transfer(
                _ticketIssuer.ownerOf(requestedTokenID), 
                offeredTokenID
            );
        }

        // Trade token for ether
        else {
            require(
                msg.value >= _marketplace[requestedTokenID].requestedPrice,
                "Not enough ether provided"
            );
            payable(_ticketIssuer.ownerOf(requestedTokenID)).transfer(_marketplace[requestedTokenID].requestedPrice);
        }
  
        _ticketIssuer.transfer(
            msg.sender, 
            requestedTokenID
        );
        delete _marketplace[requestedTokenID];
    }

    function verifyTicket(uint256 tokenID) public view returns (address) {
        return _ticketIssuer.ownerOf(tokenID);
    }

    function verifyPoster(uint256 tokenID) external view returns (address) {
        return _posterIssuer.ownerOf(tokenID);
    }

    function cancelShow(uint40 date) external  {
        require(
            msg.sender == _owner,
            "Only the owner of the show can cancel it"
        );
        _cancelledDates[date] = true;
    }

    function _fromID(uint256 tokenID) private pure returns (uint160, uint40, uint16, uint16) {
        uint160 showID = uint160(tokenID);
        tokenID >>= 160;
        uint40 date = uint40(tokenID);
        tokenID >>= 40;
        uint16 seatRow = uint16(tokenID);
        tokenID >>= 16;
        uint16 seatNumber = uint16(tokenID);
        return (showID, date, seatRow, seatNumber);
    }

    function _toID(uint16 seatRow, uint16 seatNumber, uint40 date) private view returns (uint256) {
        uint160 showID = uint160(address(this));
        uint256 tokenID = seatNumber;
        tokenID <<= 16;
        tokenID += seatRow;
        tokenID <<= 40;
        tokenID += date;
        tokenID <<= 160;
        tokenID += showID;
        return tokenID;
    }
}
