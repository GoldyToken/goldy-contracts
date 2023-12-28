// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGoldyToken {
    function burn(uint256 amount) external returns (bool);
}
