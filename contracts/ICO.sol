// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IGoldyPriceOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract ICO {
    using Counters for Counters.Counter;
    // supported buy currency
    enum Currency {
        USDC ,
        USDT
    }
    Currency private defaultCurrency;
    address private defaultCurrencyAddress;
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

    constructor(address _goldyOracle, address _defaultCurrencyAddress) {
        owner = msg.sender;
        goldyOracle = _goldyOracle;
        defaultCurrencyAddress = _defaultCurrencyAddress;
        defaultCurrency = Currency.USDC;
    }

    modifier onlyOwner () {
        require(msg.sender == owner, 'Only Admin');
        _;
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
        require(amount > 0 && _saleTracker.current() > 0, 'G1'); // either amount is less than 0 or sale not started
        Sale storage sale = sales[_saleTracker.current() - 1];
        require(block.timestamp >= sale.startDate && block.timestamp <= sale.endDate, 'G2'); // either sale not started or ended
        require((sale.soldToken + amount) <= sale.maximumToken, 'G3'); // maximum token sale reach
        sale.soldToken += amount;
        IGoldyPriceOracle goldyPriceOracle = IGoldyPriceOracle(goldyOracle);
        uint price;
        IERC20(defaultCurrencyAddress).transferFrom(msg.sender, address(this), amount);
        if (defaultCurrency == Currency.USDC) {
            price = goldyPriceOracle.getGoldyUSDCPrice();
            IERC20(sale.token).transfer(msg.sender, (1e18 * amount) / price);
        } else if (defaultCurrency == Currency.USDT) {
            price = goldyPriceOracle.getGoldyUSDTPrice();
            IERC20(sale.token).transfer(msg.sender, (1e18 * amount) / price);
        }
    }

    function changeDefaultCurrency (Currency _defaultCurrency, address _defaultCurrencyAddress) external onlyOwner {
        defaultCurrency = _defaultCurrency;
        defaultCurrencyAddress = _defaultCurrencyAddress;
    }
}
