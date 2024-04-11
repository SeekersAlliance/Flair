// contracts/PrizeItems.sol
// SPDX-License-Identifier: MIT
pragma solidity = 0.8.23;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract PrizeItems is ERC1155, ERC1155Supply, AccessControl  {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private _baseTokenURI;

    constructor(address _initialAdmin, string memory baseTokenURI) ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, _initialAdmin);
        _baseTokenURI = baseTokenURI;
    }
    
    function setBaseTokenURI(string calldata newBaseTokenURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = newBaseTokenURI;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return bytes(_baseTokenURI).length > 0
            ? string(abi.encodePacked(_baseTokenURI, tokenIdToString(tokenId), ".json"))
            : '';
    }

    function tokenIdToString(uint256 tokenId) internal pure returns (string memory) {
        if (tokenId == 0) {
            return "0";
        }

        uint256 length;
        uint256 temp = tokenId;

        while (temp > 0) {
            temp /= 10;
            length++;
        }

        bytes memory result = new bytes(length);

        for (uint256 i = length; i > 0; i--) {
            result[i - 1] = bytes1(uint8(48 + tokenId % 10));
            tokenId /= 10;
        }

        return string(result);
    }

    function mint (
        address _account, 
        uint256 _id, 
        uint256 _amount,
        bytes memory data
    ) onlyRole(MINTER_ROLE) external {
        _mint(_account, _id, _amount, data);
    }

    function mintBatch(
        address _account, 
        uint256[] memory _ids, 
        uint256[] memory _amounts,
        bytes memory data
    ) external onlyRole(MINTER_ROLE) {
        _mintBatch(_account, _ids, _amounts, data);
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}