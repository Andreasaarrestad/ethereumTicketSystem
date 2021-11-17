// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TicketIssuer is ERC721 {
    address private _admin;
    
    constructor(address admin) ERC721("Ticket", "TICK") {
          _admin = admin;
    }

    function exists(uint256 tokenID) public view returns (bool) {
        return _exists(tokenID);
    }

    function buy(address recepient, uint256 tokenID, string memory link) public {
        require(
            msg.sender == _admin, 
            "Only the administrator can mint new tickets"
        );
        _safeMint(recepient, tokenID, bytes(link));
    }

    function burn(uint256 ticketID) public {
        require(
            msg.sender == _admin, 
            "Only the administrator can burn tickets"
        );
        _burn(ticketID);
    }
    
    function transfer(address recepient, uint256 tokenID) public {
        require(
            msg.sender == _admin, 
            "Only the administrator can transfer tickets"
        );
        _transfer(ownerOf(tokenID), recepient, tokenID);
    }
}
