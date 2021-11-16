// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TicketIssuer.sol";
import "./PosterIssuer.sol";

contract TicketBookingSystem is Ownable {
    string private _showTitle;
    uint16 private _numRows; // max ticket y coordinate
    uint16[] private _numCols; // max ticket x coordinate given y coordinate
    uint16[] private _rowPrice;
    mapping(uint40 => bool) private _cancelledDates;
    PosterIssuer private _posterIssuer;
    TicketIssuer private _ticketIssuer;

    constructor(string memory showTitle, uint16 numRows, uint16[] memory numCols, uint16[] memory rowPrice) {
        _showTitle = showTitle;
        _numRows = numRows;
        _numCols = numCols;
        _rowPrice = rowPrice;
        _ticketIssuer = new TicketIssuer();
        _posterIssuer = new PosterIssuer();
    }

    function buy(uint16 seatRow, uint16 seatNumber, uint40 date) external payable returns (uint256) {
        require(
            msg.value >= _rowPrice[seatRow], 
            "You need to pay more"
        );
        uint256 newTokenID = _toID(seatRow, seatNumber, date);
        _ticketIssuer.buy(msg.sender, newTokenID, "https://seatplan.com/");
        payable(owner()).transfer(_rowPrice[seatRow]);
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
            1 <= seatRow && seatRow <= _numRows && 1 <= seatNumber && seatNumber <= _numCols[seatRow],
            "Seat is unvalid"
        );

        _ticketIssuer.burn(tokenID);
        _posterIssuer.mint(ticketOwner, tokenID);
    }

    function tradeTicket(address from, address to, uint256 tokenID) external {
        require(
            _ticketIssuer.ownerOf(tokenID) == msg.sender,
            "Only the owner of the ticket can transfer"
        );
        _ticketIssuer.safeTransferFrom(from, to, tokenID);
    }

    function verifyTicket(uint256 tokenID) public view returns (address) {
        return _ticketIssuer.ownerOf(tokenID);
    }

    function verifyPoster(uint256 tokenID) external view returns (address) {
        return _posterIssuer.ownerOf(tokenID);
    }

    function cancelShow(uint40 date) external onlyOwner {
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
