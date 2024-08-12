// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract GoldyToken is ERC20, Ownable {

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 50000 * (10 ** decimals()));
    }

    function mint(uint _value) external onlyOwner {
        _mint(msg.sender, _value);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

}
