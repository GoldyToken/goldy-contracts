// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IGoldyPriceOracle.sol";

contract ICO {
    using Counters for Counters.Counter;

    address private owner;
    Counters.Counter private _saleTracker; // sale tracker
    address public goldyOracle;
    // Sale Structure
    struct Sale {
        address token; // token for sale;
        uint startDate; // timestamp start date
        uint endDate; // timestamp end date
        uint maximumToken; // max token for sale
        uint soldToken; // sold token count
    }

    mapping (uint => Sale) public sales;

    constructor(address _goldyOracle) {
        owner = msg.sender;
        goldyOracle = _goldyOracle;
    }

    function createSale(address _token, uint _startDate, uint _endDate, uint _maximumToken) external {

        Sale storage sale = sales[_saleTracker.current()];
        sale.token = _token;
        sale.startDate = _startDate;
        sale.endDate = _endDate;
        sale.maximumToken = _maximumToken;
        _saleTracker.increment();

    }

    function buyToken(uint amount) external {
        IGoldyPriceOracle goldyPriceOracle = IGoldyPriceOracle(goldyOracle);
        uint goldyEuroPrice = goldyPriceOracle.getGoldyEuroPrice();
    }

}
