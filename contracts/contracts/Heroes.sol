pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/token/ERC721/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol";


contract Heroes is ERC721PresetMinterPauserAutoIdUpgradeable {

    event NewBaseURI(string newBaseURI);

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory newBaseURI) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Heroes: must have admin role");
        _baseTokenURI = newBaseURI;
        emit NewBaseURI(newBaseURI);
    }
}