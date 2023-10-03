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
    string public goldBarNumber; // serial number
    string public goldBarWeight; // oz
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
        bool isAmlActive; // Aml Active state
        uint amlCheck; // aml check state
    }

    mapping (uint => Sale) public sales;
    uint public maxTokenSale; // for one year

    event BuyToken (address indexed user, Currency currency, uint amount, uint goldyAmount, bool aml, bytes32 message, string goldBarNumber, string goldBarWeight);
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
    function createSale(address _token, uint _startDate, uint _endDate, uint _maximumToken, bool _isAmlActive, uint _amlCheck) external onlyOwner {

        require(saleValueExceedCheckForMaxTokenSale(_maximumToken), 'current token sale amount exceed max token amount');
        Sale storage sale = sales[_saleTracker.current()];
        sale.token = _token;
        sale.startDate = _startDate;
        sale.endDate = _endDate;
        sale.maximumToken = _maximumToken;
        sale.isActive = true;
        sale.isAmlActive = _isAmlActive;
        sale.amlCheck = _amlCheck;
        IERC20(sale.token).transferFrom(msg.sender, address(this), _maximumToken);
        _saleTracker.increment();

    }

    function buyToken (uint amount, Currency _currency) external {
        // require(amount < sales[_saleTracker.current() - 1].amlCheck, 'Not AD'); //  Not Allowed to trade more than amlCheck amount
        IERC20(currencyAddresses[_currency]).transferFrom(msg.sender, address(this), amount);
        if (amount >= sales[_saleTracker.current() - 1].amlCheck) {
            _buyToken(amount, _currency, true, bytes32(0));
        } else {
            _buyToken(amount, _currency, false, bytes32(0));
        }
    }

    function buyTokenPayable () external payable {
        // require(msg.value < sales[_saleTracker.current() - 1].amlCheck, 'Not AD'); //  Not Allowed to trade more than amlCheck amount
        if (msg.value >= sales[_saleTracker.current() - 1].amlCheck) {
            _buyToken(msg.value, Currency.ETH, true, bytes32(0));
        } else {
            _buyToken(msg.value, Currency.ETH, false, bytes32(0));
        }
    }

    function verifiedBuyToken (bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s, uint amount, Currency _currency) external {
        require(verifyMessage(_hashedMessage, _v, _r, _s, msg.sender), 'invalid user');
        IERC20(currencyAddresses[_currency]).transferFrom(msg.sender, address(this), amount);
        _buyToken(amount, _currency, true, _hashedMessage);
    }

    function verifiedBuyTokenPayable (bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) external payable {
        require(verifyMessage(_hashedMessage, _v, _r, _s, msg.sender), 'invalid user');
        _buyToken(msg.value, Currency.ETH, true, _hashedMessage);
    }

    function _buyToken(uint amount, Currency _currency, bool aml, bytes32 message) internal {
        require(amount > 0 && _saleTracker.current() > 0, 'G1'); // either amount is less than 0 or sale not started
        Sale storage sale = sales[_saleTracker.current() - 1];
        require(block.timestamp >= sale.startDate && block.timestamp <= sale.endDate, 'G2'); // either sale not started or ended
        require((sale.soldToken + amount) <= sale.maximumToken, 'G3'); // maximum token sale reach
        require(sale.isActive, 'Sale Inactive'); // check sale active or not
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
        emit BuyToken(msg.sender, _currency, amount, transferAmount, aml, message, goldBarNumber, goldBarWeight);
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
        Sale storage sale = sales[_saleTracker.current() - 1];
        sale.isAmlActive = !sale.isAmlActive;
    }
    function updateAmlCheck(uint _amlCheck) external onlyOwner {
        Sale storage sale = sales[_saleTracker.current() - 1];
        sale.amlCheck = _amlCheck;
    }

    function verifyMessage(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s, address user) public pure returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return user == signer;
    }

    function updateGoldBarDetails (string memory _goldBarNumber, string memory _goldBarWeight) external onlyOwner {
        goldBarNumber = _goldBarNumber;
        goldBarWeight = _goldBarWeight;
    }

    function updateMaxTokenSale(uint _maxTokenSale) external onlyOwner {
        maxTokenSale = _maxTokenSale;
    }

    function saleValueExceedCheckForMaxTokenSale(uint _tokenValue) internal view returns (bool) {
        if (_saleTracker.current() == 0) {
            return true;
        }
        uint sum = 0;
        for (uint256 i = 0; i < _saleTracker.current(); i++) {
            Sale memory sale = sales[i];
            sum += sale.maximumToken;
        }
        sum += _tokenValue;
        return sum < maxTokenSale;
    }

}
