// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/Extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TicketIssuer is ERC721Burnable, Ownable {

    constructor () ERC721("Ticket", "TICK") {};
    
    function exists (uint256 tokenID) public view returns (bool) {
        return _exists(tokenID);
    }
    
    function mint (address recepient, uint256 tokenID, Struct seatData) public onlyOwner {
        _safeMint(recepient, tokenID, seatData);
    }
    
}