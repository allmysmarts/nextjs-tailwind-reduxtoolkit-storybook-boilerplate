pragma solidity 0.8.6;


contract EVMMaths {
    function aDivBDivC(uint a, uint b, uint c) external pure returns (uint) {
        return a / (b / c);
    }
}