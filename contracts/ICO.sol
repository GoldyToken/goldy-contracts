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
        USDT ,
        ETH  ,
        EUROC
    }
    mapping (Currency => address) public currencyAddresses;
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
        bool isActive; // Current state of sale
    }

    mapping (uint => Sale) public sales;
    bool public isAmlActive;
    constructor(address _goldyOracle, address _usdc, address _usdt, address _euroc) {
        owner = msg.sender;
        goldyOracle = _goldyOracle;
        currencyAddresses[Currency.EUROC] = _euroc;
        currencyAddresses[Currency.USDC] = _usdc;
        currencyAddresses[Currency.USDT] = _usdt;
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

    function buyToken (uint amount, Currency _currency) external {
        IERC20(currencyAddresses[_currency]).transferFrom(msg.sender, address(this), amount);
        _buyToken(amount, _currency);
    }

    function buyTokenPayable () external payable {
        _buyToken(msg.value, Currency.ETH);
    }

    function _buyToken(uint amount, Currency _currency) internal {
        require(amount > 0 && _saleTracker.current() > 0, 'G1'); // either amount is less than 0 or sale not started
        Sale storage sale = sales[_saleTracker.current() - 1];
        require(block.timestamp >= sale.startDate && block.timestamp <= sale.endDate, 'G2'); // either sale not started or ended
        require((sale.soldToken + amount) <= sale.maximumToken, 'G3'); // maximum token sale reach
        IGoldyPriceOracle goldyPriceOracle = IGoldyPriceOracle(goldyOracle);
        uint transferAmount;
        if (Currency.USDC == _currency) {
            transferAmount = _calculateTransferAmount(goldyPriceOracle.getGoldyUSDCPrice(), amount);
            IERC20(sale.token).transfer(msg.sender, transferAmount);
        } else if (Currency.USDT == _currency) {
            transferAmount = _calculateTransferAmount(goldyPriceOracle.getGoldyUSDTPrice(), amount);
            IERC20(sale.token).transfer(msg.sender, transferAmount);
        } else if (Currency.EUROC == _currency) {
            transferAmount = _calculateTransferAmount(goldyPriceOracle.getGoldyEuroPrice(), amount);
            IERC20(sale.token).transfer(msg.sender, transferAmount);
        } else if (Currency.ETH == _currency) {
            transferAmount = _calculateTransferAmount(goldyPriceOracle.getGoldyETHPrice(), amount);
            IERC20(sale.token).transfer(msg.sender, transferAmount);
        }
        sale.soldToken += transferAmount;
    }

    function _calculateTransferAmount(uint price, uint amount) internal pure returns (uint) {
        return (1e18 * amount) / price;
    }

    function getCurrentSaleDetails() external view returns (Sale memory) {
        return sales[_saleTracker.current() - 1];
    }

    function updateMaxToken(uint _maxToken) external onlyOwner {
        Sale storage sale = sales[_saleTracker.current() - 1];
        sale.maximumToken = _maxToken;
    }

    function toggleSaleStatus() external onlyOwner {
        Sale storage sale = sales[_saleTracker.current() - 1];
        sale.isActive = !sale.isActive;
    }

    function toggleAmlStatus() external onlyOwner {
        isAmlActive = !isAmlActive;
    }

}
