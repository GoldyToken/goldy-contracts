// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";

contract ICO {
    using Counters for Counters.Counter;

    address private owner;
    Counters.Counter private _saleTracker; // sale tracker
    // Sale Structure
    struct Sale {
        address token; // token for sale;
        uint startDate; // timestamp start date
        uint endDate; // timestamp end date
        uint maximumToken; // max token for sale
        uint soldToken; // sold token count
    }

    constructor(){
        owner = msg.sender;
    }

    function createSale(address _token, uint _startDate, uint _endDate, uint _maximumToken, uint _soldToken) external {

        Sale storage sale = Sale[_saleTracker.current()];
        sale.token = _token;
        sale.startDate = _startDate;
        sale.endDate = _endDate;
        sale.maximumToken = _maximumToken;
        _saleTracker.increment();

    }

    function buyToken(uint amount) external {

    }

}
