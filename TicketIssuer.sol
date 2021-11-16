// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TicketIssuer is ERC721, Ownable {
    constructor() ERC721("Ticket", "TICK") {}

    function exists(uint256 tokenID) public view returns (bool) {
        return _exists(tokenID);
    }

    function mint(address recepient, uint256 tokenID, string memory link) public onlyOwner {
        _safeMint(recepient, tokenID, bytes(link));
    }

    function burn(uint256 ticketID) public {
        _burn(ticketID);
    }
}
