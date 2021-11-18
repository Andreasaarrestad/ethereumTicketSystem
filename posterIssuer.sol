pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract PosterIssuer is ERC721 {
    address private _admin;
    
    modifier onlyAdmin {
      require(
        msg.sender == _admin,
        "Not authorized to handle posters"
      );_;
    }

    constructor (address admin) ERC721("Poster", "PSTR") {
        _admin = admin;
    }
    
    function mint (address recepient, uint256 tokenID) onlyAdmin public{
        _safeMint(recepient, tokenID);
    }
    
    function exists (uint256 tokenID) public view returns (bool) {
        return _exists(tokenID);
    }
  
}