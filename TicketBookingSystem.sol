// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TicketIssuer.sol";
import "./PosterIssuer.sol";

contract TicketBookingSystem  {
    address private _owner;
    string private _showTitle;
    string private _link;
    uint32[] private _rowPrice;
    uint16[] private _numCols; // max ticket x coordinate given y coordinate
    uint16 private _numRows; // max ticket y coordinate
    mapping(uint40 => uint8) private _activeTimestamps; // unix time[s] => 0/1
    mapping(uint256 => Swap) private _marketplace;  // offeredTokenID => Swap
    PosterIssuer private _posterIssuer;
    TicketIssuer private _ticketIssuer;

    struct Swap {
        uint256 requestedTokenID;
        uint32 requestedPrice;
    }

    modifier onlyOwner {
        require(
            msg.sender == _owner,
            "Function only callable by owner"
        );_;
    }
    
    event UpForTrade(
        address seller, 
        uint256 offeredTokenID, 
        uint256 requestedTokenID, 
        uint32 requestedPrice
    );
    event Trade(
        address seller, 
        uint256 tokenSentToSeller, 
        address buyer, 
        uint256 tokenSentToBuyer, 
        uint32 price
    );
    
    constructor(
        string memory showTitle,
        string memory link,
        uint40[] memory timestamps,
        uint32[] memory rowPrice, 
        uint16[] memory numCols
    ){
        _owner = msg.sender;
        _showTitle = showTitle;
        _link = link;
        _numRows = uint16(numCols.length);
        _numCols = numCols;
        _rowPrice = rowPrice;
        _ticketIssuer = new TicketIssuer(address(this));
        _posterIssuer = new PosterIssuer(address(this));

        require(
            _numRows == _rowPrice.length,
            "Seat layout mismatch" 
        );
        
        for (uint16 i = 0; i<timestamps.length; i++) {
            _activeTimestamps[timestamps[i]] = 1;
        } 
    }
    
    function buy(uint16 seatRow, uint16 seatNumber, uint40 timestamp) external payable returns (uint256) {
        require(
            msg.value >= _rowPrice[seatRow-1], 
            "Not enough funds provided"
        );
        require(
            1 <= seatRow && seatRow <= _numRows && 1 <= seatNumber && seatNumber <= _numCols[seatRow-1],
            "Seat is unvalid"
        );
        require(
            _activeTimestamps[timestamp] == 1, 
            "The show is not available for this date and time"
        );

        /*Does not need to verify that the specific seat at a specific timestamp is taken 
        yet, as the tokenID uniquely represents these. Hence, if the ticket already is minted, 
        the seat for the given show and timestamp is taken. */
        uint256 newTokenID = _toID(seatRow, seatNumber, timestamp);
        _ticketIssuer.buy(msg.sender, newTokenID, _link);
        uint40 ticketPrice = _rowPrice[seatRow-1];
        payable(_owner).transfer(ticketPrice);
        return newTokenID;
    }

    function refund(uint40 timestamp) onlyOwner external payable {     
        // Cancels the show
        _activeTimestamps[timestamp] = 0;
        
        /*The downside of the tokenID system is evident here; we have to check if each set is 
        bought or not before refunding. However, refunds are usually rather rare, and  we hence 
        think the gas savings in other parts of the system from the tokenID system outweights 
        the additional gas usage here.*/
        for (uint16 seatRow = 1; seatRow <= _numRows; seatRow++) {
             for (uint16 seatNumber = 1; seatNumber <= _numCols[seatRow-1]; seatNumber++) {
                uint256 tokenID = _toID(seatRow, seatNumber, timestamp);
                if (_ticketIssuer.exists(tokenID) == true) {
                    address ticketOwner = _ticketIssuer.ownerOf(tokenID);
                    uint40 ticketPrice = _rowPrice[seatRow-1];
                    payable(ticketOwner).transfer(ticketPrice);
                    _ticketIssuer.burn(tokenID);
                }
            }
        }
    }

    function validate(uint256 tokenID) external {
        (uint160 showID, uint40 timestamp,,) = _fromID(tokenID);
        address ticketOwner = verifyTicket(tokenID);
        require(
            showID == uint160(address(this)),
            "TokenID does not correspond to the given movie"
        );
        require(
            // Using signed integers as the difference in either will be negative
            (int40(timestamp) - int256(block.timestamp) <= 900) && (int256(block.timestamp) - int40(timestamp) <= 900), 
            "Entrance is only possible from 15 minutes before the show start to 15 minutes after"
        );
        require(
            ticketOwner == msg.sender,
            "Only the owner of the ticket can validate"
        );

        _ticketIssuer.burn(tokenID);
        _posterIssuer.mint(ticketOwner, tokenID);
    }
    
    function putOnMarket(uint256 offeredTokenID, uint256 requestedTokenID, uint32 requestedPrice) external {
        require(
             (requestedTokenID != 0 && requestedPrice == 0) || (requestedTokenID == 0 && requestedPrice != 0), 
            "Ether or a ticket must be requested"
        );
        require(
            _ticketIssuer.ownerOf(offeredTokenID) == msg.sender, 
            "Only the owner of the ticket can trade it"
        );
        Swap memory swap = Swap(requestedTokenID, requestedPrice);
        _marketplace[offeredTokenID] = swap;
        emit UpForTrade(msg.sender, offeredTokenID, requestedTokenID, requestedPrice);
    }

    function tradeTicket(uint256 requestedTokenID, uint256 offeredTokenID) external payable {
        require(
            _marketplace[requestedTokenID].requestedTokenID != 0 || _marketplace[requestedTokenID].requestedPrice != 0,
            "Requested ticket is not on the marketplace"
        );
        address seller = _ticketIssuer.ownerOf(requestedTokenID);
        uint32 price = _marketplace[requestedTokenID].requestedPrice;
        
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
                seller, 
                offeredTokenID
            );
        }
        // Trade token for ether
        else {
            require(
                msg.value >= _marketplace[requestedTokenID].requestedPrice,
                "Not enough ether provided"
            );
            payable(seller).transfer(price);
        }
  
        _ticketIssuer.transfer(msg.sender, requestedTokenID);
        delete _marketplace[requestedTokenID];
        emit Trade(seller, offeredTokenID, msg.sender, requestedTokenID, price);
    }

    function verifyTicket(uint256 tokenID) public view returns (address) {
        /*As long as the ticketIssuer is sure that it has minted the given tokenID, 
        its existence in itself is verification of the ticket because of the 
        tokenID scheme constructed*/
        return _ticketIssuer.ownerOf(tokenID);
    }

    function verifyPoster(uint256 tokenID) external view returns (address) {
        return _posterIssuer.ownerOf(tokenID);
    }

    function addShowTimestamp(uint40 timestamp) onlyOwner external {
        _activeTimestamps[timestamp] = 1;
    }

    function _fromID(uint256 tokenID) private pure returns (uint160, uint40, uint16, uint16) {
        uint160 showID = uint160(tokenID);
        tokenID >>= 160;
        uint40 timestamp = uint40(tokenID);
        tokenID >>= 40;
        uint16 seatRow = uint16(tokenID);
        tokenID >>= 16;
        uint16 seatNumber = uint16(tokenID);
        return (showID, timestamp, seatRow, seatNumber);
    }

    function _toID(uint16 seatRow, uint16 seatNumber, uint40 timestamp) private view returns (uint256) {
        uint160 showID = uint160(address(this));
        uint256 tokenID = seatNumber;
        tokenID <<= 16;
        tokenID += seatRow;
        tokenID <<= 40;
        tokenID += timestamp;
        tokenID <<= 160;
        tokenID += showID;
        return tokenID;
    }
}
