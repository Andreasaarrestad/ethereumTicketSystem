// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/Extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TicketIssuer is ERC721Burnable, Ownable {

    constructor () ERC721("Ticket", "TICK");
    
    function exists (uint256 tokenID) public view returns (bool) {
        return _exists(tokenID);
    }
    
    function buy (address recepient, uint256 tokenID, Seat seatData) public onlyOwner {
        string seatDataBytes=append(uint2str(seatData[date]),uint2str(seatData[seatNumber]),uint2str(seatData[seatRow]),seatData[link]);
        _safeMint(recepient, tokenID, seatDataBytes);
    }

    function append(string a, string b, string c) internal pure returns (string) {
        a=string(abi.encodePacked(a, ','));
        b=string(abi.encodePacked(b, ','));
        return string(abi.encodePacked(a, b, c));

    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
}