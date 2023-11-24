// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IGoldyPriceOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract ICO is AccessControl{
    using Counters for Counters.Counter;
    // supported buy currency
    enum Currency {
        USDC ,
        USDT ,
        ETH  ,
        EUROC
    }
    mapping (Currency => address) public currencyAddresses;
    Counters.Counter private _saleTracker; // sale tracker
    Counters.Counter private _refineryTracker; // refinery connect details tracker
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

    struct RefineryBarDetails {
        string serial_number;
        uint bar_weight;
    }

    struct RefineryConnectDetail {
        uint orderDate;
        uint orderNumber;
        uint invoiceNumber;
        uint totalOrderQuantity;
        uint priceFixForAllTransaction;
        RefineryBarDetails[] barDetails;
    }
    string private constant REFINERY_ROLE = 'Refinery';
    string private constant SUB_ADMIN_ROLE = 'SubAdmin';
    address[] public refineries;
    address[] public subAdmins;

    mapping (uint => Sale) public sales;
    mapping (uint => mapping (uint => RefineryConnectDetail)) public refineryDetails; // refinery details against the active sale
    uint public maxEuroPerSaleYear; // for one year

    event BuyToken (address indexed user, Currency currency, uint amount, uint goldyAmount, bool aml, string message, string goldBarNumber, uint goldBarWeight);
    event CreateSale (uint indexed id, address token, uint startDate, uint endDate, uint maximumToken, bool isAmlActive, uint amlCheck);
    constructor(address _goldyOracle, address _usdc, address _usdt, address _euroc, address _refinery) {
        goldyOracle = _goldyOracle;
        currencyAddresses[Currency.EUROC] = _euroc;
        currencyAddresses[Currency.USDC] = _usdc;
        currencyAddresses[Currency.USDT] = _usdt;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // grant owner admin role
        grantRole(keccak256(abi.encodePacked(REFINERY_ROLE)), msg.sender); // grant owner refinery role
        grantRole(keccak256(abi.encodePacked(SUB_ADMIN_ROLE)), msg.sender); // grant owner sub admin role
        _setRoleAdmin(keccak256(abi.encodePacked(REFINERY_ROLE)), DEFAULT_ADMIN_ROLE); // admin of this role is main owner
        _setRoleAdmin(keccak256(abi.encodePacked(SUB_ADMIN_ROLE)), DEFAULT_ADMIN_ROLE); // admin of this role is main owner
        maxEuroPerSaleYear = 5000000 * 1e18; // 5 millions
        grantRole(keccak256(abi.encodePacked(REFINERY_ROLE)), _refinery); // grant refinery role
        refineries.push(_refinery);
    }

    modifier onlyOwner () {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'OO'); // only owner
        _;
    }

    modifier onlyAdmins () {
        require((hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(keccak256(abi.encodePacked(SUB_ADMIN_ROLE)), msg.sender)), 'OA'); // only admins
        _;
    }

    modifier onlyRefinery () {
        require(hasRole(keccak256(abi.encodePacked(REFINERY_ROLE)), msg.sender), 'OR'); // only refinery
        _;
    }

    function createSale(address _token, uint _startDate, uint _endDate, uint _maximumToken, bool _isAmlActive, uint _amlCheck) external onlyAdmins {

        require(_saleValueExceedCheckForMaxTokenSale(_maximumToken), 'exceed max token amount');
        require(_refineryTracker.current() > 0, 'RCD Empty');
        Sale storage sale = sales[_saleTracker.current()];
        sale.token = _token;
        sale.startDate = _startDate;
        sale.endDate = _endDate;
        sale.maximumToken = _maximumToken;
        sale.isActive = true;
        sale.isAmlActive = _isAmlActive;
        sale.amlCheck = _amlCheck;
        IERC20(sale.token).transferFrom(msg.sender, address(this), _maximumToken);
        emit CreateSale(_saleTracker.current(), _token, _startDate, _endDate, _maximumToken, _isAmlActive, _amlCheck);
        _saleTracker.increment();

    }

    function buyToken (uint amount, Currency _currency) external {
        require(amount < sales[_saleTracker.current() - 1].amlCheck, 'Not AD'); //  Not Allowed to trade more than amlCheck amount
        IERC20(currencyAddresses[_currency]).transferFrom(msg.sender, address(this), amount);
        string memory message = 'native function';
        _buyToken(amount, _currency, false, message);
    }

    function buyTokenPayable () external payable {
        require(msg.value < sales[_saleTracker.current() - 1].amlCheck, 'Not AD'); //  Not Allowed to trade more than amlCheck amount
        string memory message = 'native function';
        _buyToken(msg.value, Currency.ETH, false, message);
    }

    function verifiedBuyToken (string memory message, bytes calldata sig, uint amount, Currency _currency) external {
        require(recoverStringFromRaw(message, sig) == msg.sender, 'invalid user');
        IERC20(currencyAddresses[_currency]).transferFrom(msg.sender, address(this), amount);
        _buyToken(amount, _currency, true, message);
    }

    function verifiedBuyTokenPayable (string memory message, bytes calldata sig) external payable {
        require(recoverStringFromRaw(message, sig) == msg.sender, 'invalid user');
        _buyToken(msg.value, Currency.ETH, true, message);
    }

    function _buyToken(uint amount, Currency _currency, bool aml, string memory message) internal {
        require(amount > 0 && _saleTracker.current() > 0, 'G1'); // either amount is less than 0 or sale not started
        Sale storage sale = sales[_saleTracker.current() - 1];
        require(block.timestamp >= sale.startDate && block.timestamp <= sale.endDate, 'G2'); // either sale not started or ended
        require(sale.isActive, 'Sale Inactive'); // check sale active or not
        IGoldyPriceOracle goldyPriceOracle = IGoldyPriceOracle(goldyOracle);
        uint transferAmount;
        if (Currency.USDC == _currency) {
            transferAmount = _calculateTransferAmount(goldyPriceOracle.getGoldyUSDCPrice(), amount);
        } else if (Currency.USDT == _currency) {
            transferAmount = _calculateTransferAmount(goldyPriceOracle.getGoldyUSDTPrice(), amount);
        } else if (Currency.EUROC == _currency) {
            transferAmount = _calculateTransferAmount(goldyPriceOracle.getGoldyEuroPrice(), amount);
        } else if (Currency.ETH == _currency) {
            transferAmount = _calculateTransferAmount(goldyPriceOracle.getGoldyETHPrice(), amount);
        }
        sale.soldToken += transferAmount;
        require((sale.soldToken <= sale.maximumToken, 'G3'); // maximum token sale reach
        IERC20(sale.token).transfer(msg.sender, transferAmount);
        RefineryBarDetails memory barDetails = getActiveRefineryBarDetails();
        emit BuyToken(msg.sender, _currency, amount, transferAmount, aml, message, barDetails.serial_number, barDetails.bar_weight);
    }

    function _calculateTransferAmount(uint price, uint amount) internal pure returns (uint) {
        return (1e18 * amount) / price;
    }

    function getCurrentSaleDetails() external view returns (Sale memory) {
        Sale memory sale;
        if (_saleTracker.current() == 0) {
            return sale;
        }
        return sales[_saleTracker.current() - 1];
    }

    function updateMaxToken(uint _maxToken) external onlyAdmins {
        Sale storage sale = sales[_saleTracker.current() - 1];
        sale.maximumToken = _maxToken;
    }

    function toggleSaleStatus() external onlyAdmins {
        Sale storage sale = sales[_saleTracker.current() - 1];
        sale.isActive = !sale.isActive;
    }

    function toggleAmlStatus() external onlyAdmins {
        Sale storage sale = sales[_saleTracker.current() - 1];
        sale.isAmlActive = !sale.isAmlActive;
    }
    function updateAmlCheck(uint _amlCheck) external onlyAdmins {
        Sale storage sale = sales[_saleTracker.current() - 1];
        sale.amlCheck = _amlCheck;
    }

    function verifyMessage(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s, address user) public pure returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return user == signer;
    }

    function updateMaxTokenSale(uint _maxEuroPerSaleYear) external onlyAdmins {
        maxEuroPerSaleYear = _maxEuroPerSaleYear;
    }

    function addRefinery(address _user) external onlyOwner {
        grantRole(keccak256(abi.encodePacked(REFINERY_ROLE)), _user); // grant refinery role
        refineries.push(_user);
    }

    function removeRefinery(address _user) external onlyOwner {
        revokeRole(keccak256(abi.encodePacked(REFINERY_ROLE)), _user); // remove refinery role
    }

    function addSubAdmin(address _user) external onlyOwner {
        grantRole(keccak256(abi.encodePacked(SUB_ADMIN_ROLE)),_user); // grant sub admin role
        subAdmins.push(_user);
    }

    function removeSubAdmin(address _user) external onlyOwner {
        revokeRole(keccak256(abi.encodePacked(SUB_ADMIN_ROLE)), _user); // remove sub admin role
    }

    function getSubAdminsCount() external view returns (uint) {
        return subAdmins.length;
    }

    function getRefineriesCount() external view returns (uint) {
        return refineries.length;
    }

    function addRefineryConnectDetails(uint _orderDate, uint _orderNumber, uint _totalOrderQuantity, uint _priceFixForAllTransaction, uint _invoiceNumber, string[] memory _serial_number, uint[] memory _bar_weights) external onlyRefinery {
        require(_serial_number.length > 0 && _bar_weights.length > 0, 'invalid input');
        RefineryConnectDetail storage refineryConnectDetail;
        if (_saleTracker.current() == 0) {
            refineryConnectDetail = refineryDetails[_saleTracker.current()][_refineryTracker.current()];
        }
        else {
            refineryConnectDetail = refineryDetails[_saleTracker.current() - 1][_refineryTracker.current()];
        }
        refineryConnectDetail.orderDate = _orderDate;
        refineryConnectDetail.orderNumber = _orderNumber;
        refineryConnectDetail.totalOrderQuantity = _totalOrderQuantity;
        refineryConnectDetail.priceFixForAllTransaction = _priceFixForAllTransaction;
        refineryConnectDetail.invoiceNumber = _invoiceNumber;
        for (uint256 i = 0; i < _serial_number.length; i++) {
            RefineryBarDetails memory barDetails;
            barDetails.bar_weight = _bar_weights[i];
            barDetails.serial_number = _serial_number[i];
            refineryConnectDetail.barDetails.push(barDetails);
        }
        _refineryTracker.increment();
    }

    function _saleValueExceedCheckForMaxTokenSale(uint _tokenValue) internal view returns (bool) {
        IGoldyPriceOracle goldyPriceOracle = IGoldyPriceOracle(goldyOracle);
        if (_saleTracker.current() == 0) {
            return true;
        }
        uint sum = 0;
        for (uint256 i = 0; i < _saleTracker.current(); i++) {
            Sale memory sale = sales[i];
            sum += sale.maximumToken;
        }
        sum += _tokenValue;
        uint maxGoldyPerSaleYear = _calculateTransferAmount(goldyPriceOracle.getGoldyEuroPrice(), maxEuroPerSaleYear);
        return sum <= maxGoldyPerSaleYear;
    }

    function getActiveRefineryBarDetails() public view returns (RefineryBarDetails memory) {
        require(_refineryTracker.current() > 0, 'RCD Missing'); // refinery connect details missing
        require(_saleTracker.current() > 0, 'SALE Missing'); // refinery connect details missing
        RefineryConnectDetail memory refineryConnectDetail;
        Sale memory sale = sales[_saleTracker.current() - 1];
        refineryConnectDetail = refineryDetails[_saleTracker.current() - 1][_refineryTracker.current() - 1];
        RefineryBarDetails[] memory barDetails = refineryConnectDetail.barDetails;
        require(barDetails.length > 0, 'RCD Missing'); // refinery connect details missing
        uint totalWeight;
        for (uint i = 0; i < barDetails.length; i++) {
            RefineryBarDetails memory barDetail = barDetails[i];
            totalWeight += barDetail.bar_weight;
            if (sale.soldToken <= (totalWeight * 1000)) { // 1oz = 10000 GOLDY
                return barDetails[i];
            }
        }
        return barDetails[barDetails.length - 1];
    }

    function recoverStringFromRaw(string memory message, bytes calldata sig) public pure returns (address) {

        // Sanity check before using assembly
        require(sig.length == 65, "invalid signature");

        // Decompose the raw signature into r, s and v (note the order)
        uint8 v;
        bytes32 r;
        bytes32 s;
        assembly {
            r := calldataload(sig.offset)
            s := calldataload(add(sig.offset, 0x20))
            v := calldataload(add(sig.offset, 0x21))
        }

        return _ecrecover(message, v, r, s);
    }

    // Helper function
    function _ecrecover(string memory message, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // Compute the EIP-191 prefixed message
        bytes memory prefixedMessage = abi.encodePacked(
            "\x19Ethereum Signed Message:\n",
            itoa(bytes(message).length),
            message
        );

        // Compute the message digest
        bytes32 digest = keccak256(prefixedMessage);

        // Use the native ecrecover provided by the EVM
        return ecrecover(digest, v, r, s);
    }

    function itoa(uint value) public pure returns (string memory) {

        // Count the length of the decimal string representation
        uint length = 1;
        uint v = value;
        while ((v /= 10) != 0) { length++; }

        // Allocated enough bytes
        bytes memory result = new bytes(length);

        // Place each ASCII string character in the string,
        // right to left
        while (true) {
            length--;

            // The ASCII value of the modulo 10 value
            result[length] = bytes1(uint8(0x30 + (value % 10)));

            value /= 10;

            if (length == 0) { break; }
        }

        return string(result);
    }

    function withdrawAll() public onlyOwner {
        IERC20(currencyAddresses[Currency.EUROC]).transfer(msg.sender, IERC20(currencyAddresses[Currency.EUROC]).balanceOf(address(this)));
        IERC20(currencyAddresses[Currency.USDC]).transfer(msg.sender, IERC20(currencyAddresses[Currency.USDC]).balanceOf(address(this)));
        IERC20(currencyAddresses[Currency.USDT]).transfer(msg.sender, IERC20(currencyAddresses[Currency.USDT]).balanceOf(address(this)));
        payable(msg.sender).transfer(address(this).balance);
    }

}
