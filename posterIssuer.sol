pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract PosterIssuer is ERC721 {
    address private _owner;
    
    constructor (address owner) ERC721("Poster", "PSTR"){
        _owner = owner;
    }
    
    function mint (address recepient, uint256 tokenID) public{
        require(msg.sender == _owner,"Only the SC owner can mint");
        _safeMint(recepient, tokenID);
    }
    
    function exists (uint256 tokenID) public view returns (bool) {
        return _exists(tokenID);
    }
  
}