// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract GoldyToken is ERC20, AccessControl {

    string private constant MinterRole = 'MinterRole';
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 50000 * (10 ** decimals()));
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // grant owner admin role
        grantRole(keccak256(abi.encodePacked(MinterRole)), msg.sender); // grant owner minter role
    }

    modifier onlyMinter() {
        require(hasRole(keccak256(abi.encodePacked(MinterRole)), msg.sender), 'Only Minter');
        _;
    }

    function mint(uint _value) external onlyMinter {
        _mint(msg.sender, _value);
    }
}
