pragma solidity ^0.8.0;


interface IBrainOracle {
    function wethAddr() external view returns (address);
    function getRandFightNum() external view returns (uint);
}