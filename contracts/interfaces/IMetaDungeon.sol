pragma solidity ^0.8.0;



import "../contracts/OZ_forks/IaNFT.sol";


interface IMetaDungeon is IaNFT {

    function baseURI() external view returns (string memory);

    function setBaseURI(string memory newBaseTokenURI) external;

    function mint(address to, address brain) external returns (uint);

    function mint(address to, address brain, string[] memory tokenURIs) external returns (uint tokenId);

    function setTokenURIs(uint256 tokenId, string[] memory tokenURIs) external;

    function pause() external;

    function unpause() external;

    function tokenURI(uint256 tokenId) external view returns (string memory);
}