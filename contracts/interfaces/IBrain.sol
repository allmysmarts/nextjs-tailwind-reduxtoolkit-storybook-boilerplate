pragma solidity ^0.8.0;


interface IBrain {
    function getURIVersion(uint tokenId) external view returns (uint);
}