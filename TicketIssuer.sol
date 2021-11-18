// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TicketIssuer is ERC721 {
    address private _admin;

    modifier onlyAdmin {
      require(
        msg.sender == _admin,
        "Not authorized to handle tickets"
      );_;
    }
    
    constructor(address admin) ERC721("Ticket", "TICK") {
          _admin = admin;
    }

    function exists(uint256 tokenID) public view returns (bool) {
        return _exists(tokenID);
    }

    function buy(address recepient, uint256 tokenID, string memory link) onlyAdmin public {
        _safeMint(recepient, tokenID, bytes(link));
    }

    function burn(uint256 ticketID) onlyAdmin public {
        _burn(ticketID);
    }
    
    function transfer(address recepient, uint256 tokenID) onlyAdmin public {
        _transfer(ownerOf(tokenID), recepient, tokenID);
    }
}
