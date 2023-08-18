// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract GoldyToken is ERC20 {

    address private minter;
    constructor(string memory name, string memory symbol) {
        ERC20(name, symbol);
        _mint(msg.sender, 8500);
        minter = msg.sender;
    }

    modifier onlyMinter() {
        require(minter == msg.sender, 'Only Minter');
        _;
    }
    function mint(uint _value) external onlyMinter {
        _mint(msg.sender, _value);
    }
}
