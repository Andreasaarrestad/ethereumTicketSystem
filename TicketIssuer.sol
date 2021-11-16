// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TicketIssuer is ERC721 {
    address private _owner;
    
    constructor(address owner) ERC721("Ticket", "TICK") {
          _owner = owner;
    }

    function exists(uint256 tokenID) public view returns (bool) {
        return _exists(tokenID);
    }

    function buy(address recepient, uint256 tokenID, string memory link) public {
        require(
            msg.sender == _owner, 
            "Only the SC owner can mint"
        );
        _safeMint(recepient, tokenID, bytes(link));
    }

    function burn(uint256 ticketID) public {
        _burn(ticketID);
    }
}
