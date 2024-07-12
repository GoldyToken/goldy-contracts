// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./IGoldyPriceOracle.sol";
import "./IGoldyToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract ICO is AccessControl {
    // supported buy currency
    enum Currency {
        USDC ,
        USDT ,
        ETH  ,
        EUROC
    }
    // kyc status
    enum KycStatuses {
        APPROVE ,
        REJECT
    }
    mapping (Currency => address) public currencyAddresses;
    uint public _saleTracker; // sale tracker
    uint public _refineryTracker; // refinery connect details tracker
    address public goldyOracle;
    mapping (address => bool) public kycStatus; // kyc status of user approved then true rejected or pending is false
    // Sale Structure
    struct Sale {
        address token; // token for sale;
        uint startDate; // timestamp start date
        uint endDate; // timestamp end date
        uint maximumToken; // max token for sale
        uint soldToken; // sold token count
        bool isActive; // Current state of sale
        bool isKycActive; // kyc active
    }

    struct RefineryBarDetails {
        string serial_number;
        uint bar_weight;
    }

    struct RefineryConnectDetail {
        uint orderDate;
        uint orderNumber;
        uint invoiceNumber;
        uint totalOrderQuantity; // it is multiple of 100
        uint priceFixForAllTransaction;
        RefineryBarDetails[] barDetails;
    }
    address[] public refineries;
    address[] public subAdmins;

    mapping (uint => Sale) public sales;
    mapping (uint => RefineryConnectDetail) public refineryDetails; // refinery details against the active sale
    uint public maxEuroPerSaleYear; // for one year
    uint public startDate; // year start date 1 jan 2024
    uint public fees; // platform fees

    event BuyToken (address indexed user, Currency currency, uint amount, uint goldyAmount, bool kyc, string goldBarNumber, uint goldBarWeight);
    event CreateSale (uint indexed id, address token, uint startDate, uint endDate, uint maximumToken, bool isKycActive);
    event KycAction (address indexed user, KycStatuses kycStatus, address actionBy, string message);
    constructor(address _goldyOracle, address _usdc, address _usdt, address _euroc, address _refinery) {
        fees = 560; // 5.6% fess
        goldyOracle = _goldyOracle;
        currencyAddresses[Currency.EUROC] = _euroc;
        currencyAddresses[Currency.USDC] = _usdc;
        currencyAddresses[Currency.USDT] = _usdt;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // grant owner admin role
        grantRole(keccak256(abi.encodePacked('Refinery')), msg.sender); // grant owner refinery role
        grantRole(keccak256(abi.encodePacked('SubAdmin')), msg.sender); // grant owner sub admin role
        _setRoleAdmin(keccak256(abi.encodePacked('Refinery')), DEFAULT_ADMIN_ROLE); // admin of this role is main owner
        _setRoleAdmin(keccak256(abi.encodePacked('SubAdmin')), DEFAULT_ADMIN_ROLE); // admin of this role is main owner
        maxEuroPerSaleYear = 5000000 * 1e18; // 5 millions
        grantRole(keccak256(abi.encodePacked('Refinery')), _refinery); // grant refinery role
        refineries.push(_refinery);
        startDate = 1704091734; // 1 jan 2024
    }

    modifier onlyOwner () {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'OO'); // only owner
        _;
    }

    modifier onlyAdmins () {
        require((hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(keccak256(abi.encodePacked('SubAdmin')), msg.sender)), 'OA'); // only admins
        _;
    }

    modifier onlyRefinery () {
        require(hasRole(keccak256(abi.encodePacked('Refinery')), msg.sender), 'OR'); // only refinery
        _;
    }

    function createSale(address _token, uint _startDate, uint _endDate, uint _maximumToken, bool _isKycActive) external onlyAdmins {

        require(_saleValueExceedCheckForMaxTokenSale(_maximumToken), 'EA'); // exceed maximum sale amount
        require(_refineryTracker > 0, 'RE'); // refinery connect empty
        if (_saleTracker != 0) {
            _burnUnsoldToken(sales[_saleTracker - 1].token, IERC20(sales[_saleTracker - 1].token).balanceOf(address(this)));
        }
        Sale storage sale = sales[_saleTracker];
        sale.token = _token;
        sale.startDate = _startDate;
        sale.endDate = _endDate;
        sale.maximumToken = _maximumToken;
        sale.isActive = true;
        sale.isKycActive = _isKycActive;
        if (sale.startDate > (startDate + 365 days)) {
            _updateStartDate(); // sale creating after one year than reset startDate for next year cycle
        }
        require((_maximumToken + _getTotalSoldToken()) <= _getTotalGoldyFromRefinery(), 'NGB'); // not enough gold bar
        IERC20(sale.token).transferFrom(msg.sender, address(this), _maximumToken);
        emit CreateSale(_saleTracker, _token, _startDate, _endDate, _maximumToken, _isKycActive);
        _saleTracker++;

    }

    function buyToken (uint amount, Currency _currency) external {
        uint totalAmount = amount - ((amount * fees) / 10000);
        IERC20(currencyAddresses[_currency]).transferFrom(msg.sender, address(this), totalAmount);
        Sale storage sale = sales[_saleTracker - 1];
        require(_isValidTx(sale));
        _buyToken(amount, _currency, sale.isKycActive);
    }

    function buyTokenPayable () external payable {
        uint value = msg.value - ((msg.value * fees) / 10000);
        Sale storage sale = sales[_saleTracker - 1];
        require(_isValidTx(sale));
        _buyToken(value,  Currency.ETH, sale.isKycActive);
    }

    function _buyToken(uint amount, Currency _currency, bool kyc) internal {
        require(amount > 0 && _saleTracker > 0, 'G1'); // either amount is less than 0 or sale not started
        Sale storage sale = sales[_saleTracker - 1];
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
        RefineryBarDetails memory barDetails = _getActiveRefineryBarDetails(transferAmount);
        sale.soldToken += transferAmount;
        require(sale.soldToken <= sale.maximumToken, 'G3'); // maximum token sale reach
        IERC20(sale.token).transfer(msg.sender, transferAmount);
        emit BuyToken(msg.sender, _currency, amount, transferAmount, kyc, barDetails.serial_number, barDetails.bar_weight);
    }

    function _calculateTransferAmount(uint price, uint amount) internal pure returns (uint) {
        return (1e18 * amount) / price;
    }

    function getCurrentSaleDetails() external view returns (Sale memory) {
        Sale memory sale;
        if (_saleTracker == 0) {
            return sale;
        }
        return sales[_saleTracker - 1];
    }

    function upgradeMaxToken(uint _maxToken) external onlyAdmins {
        require(_saleValueExceedCheckForMaxTokenSale(_maxToken), 'EA'); // exceed maximum sale amount
        Sale storage sale = sales[_saleTracker - 1];
        IERC20(sale.token).transferFrom(msg.sender, address(this), _maxToken);
        sale.maximumToken += _maxToken;
    }

    function toggleSaleStatus() external onlyAdmins {
        Sale storage sale = sales[_saleTracker - 1];
        sale.isActive = !sale.isActive;
    }

    function updateMaxTokenSale(uint _maxEuroPerSaleYear) external onlyAdmins {
        maxEuroPerSaleYear = _maxEuroPerSaleYear;
    }

    function addRefinery(address _user) external onlyOwner {
        grantRole(keccak256(abi.encodePacked('Refinery')), _user); // grant refinery role
        refineries.push(_user);
    }

    function removeRefinery(address _user) external onlyOwner {
        revokeRole(keccak256(abi.encodePacked('Refinery')), _user); // remove refinery role
    }

    function addSubAdmin(address _user) external onlyOwner {
        grantRole(keccak256(abi.encodePacked('SubAdmin')),_user); // grant sub admin role
        subAdmins.push(_user);
    }

    function removeSubAdmin(address _user) external onlyOwner {
        revokeRole(keccak256(abi.encodePacked('SubAdmin')), _user); // remove sub admin role
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
        refineryConnectDetail = refineryDetails[_refineryTracker];
        refineryConnectDetail.orderDate = _orderDate;
        refineryConnectDetail.orderNumber = _orderNumber;
        refineryConnectDetail.totalOrderQuantity = _totalOrderQuantity; // it is multiple of 100
        refineryConnectDetail.priceFixForAllTransaction = _priceFixForAllTransaction;
        refineryConnectDetail.invoiceNumber = _invoiceNumber;
        for (uint256 i = 0; i < _serial_number.length; i++) {
            RefineryBarDetails memory barDetails;
            barDetails.bar_weight = _bar_weights[i]; // adding bar weight in 100 multiple like 1 = 100, 1.5  = 150
            barDetails.serial_number = _serial_number[i];
            refineryConnectDetail.barDetails.push(barDetails);
        }
        _refineryTracker++;
    }

    function _saleValueExceedCheckForMaxTokenSale(uint _tokenValue) internal view returns (bool) {
        IGoldyPriceOracle goldyPriceOracle = IGoldyPriceOracle(goldyOracle);
        if (_saleTracker == 0) {
            return true;
        }
        uint sum = 0;
        for (uint256 i = 0; i < _saleTracker; i++) {
            Sale memory sale = sales[i];
            if (sale.startDate >= startDate) {
                sum += sale.maximumToken;
            }
        }
        sum += _tokenValue;
        uint maxGoldyPerSaleYear = _calculateTransferAmount(goldyPriceOracle.getGoldyEuroPrice(), maxEuroPerSaleYear);
        return sum <= maxGoldyPerSaleYear;
    }

    function _getActiveRefineryBarDetails(uint _transferTokenAmount) internal view returns (RefineryBarDetails memory) {
        require(_refineryTracker > 0 && _saleTracker > 0, 'RCSM'); // refinery connect details or sale missing
        uint totalWeight;
        RefineryConnectDetail memory refineryConnectDetail;
        for (uint i = 0; i < _refineryTracker; i++) {
            refineryConnectDetail = refineryDetails[i];
            RefineryBarDetails[] memory barDetails = refineryConnectDetail.barDetails;
            for (uint j = 0; j < barDetails.length; j++) {
                RefineryBarDetails memory barDetail = barDetails[j];
                totalWeight += barDetail.bar_weight;
                if ((_getTotalSoldToken() + _transferTokenAmount) <= ((totalWeight * 10000 * 1e18) / 100)) { // 1oz = 10000 GOLDY
                    return barDetails[j];
                }
            }
        }

        RefineryBarDetails[] memory _barDetails = refineryDetails[_refineryTracker - 1].barDetails;
        return _barDetails[_barDetails.length - 1];
    }

    function _getTotalGoldyFromRefinery() internal view returns (uint) {
        require(_refineryTracker > 0, 'RCM'); // refinery connect details missing
        uint totalWeight;
        RefineryConnectDetail memory refineryConnectDetail;
        for (uint i = 0; i < _refineryTracker; i++) {
            refineryConnectDetail = refineryDetails[i];
            RefineryBarDetails[] memory barDetails = refineryConnectDetail.barDetails;
            for (uint j = 0; j < barDetails.length; j++) {
                RefineryBarDetails memory barDetail = barDetails[j];
                totalWeight += barDetail.bar_weight;
            }
        }
        return(totalWeight * 10000 * 1e18) / 100; // 1oz = 10000 GOLDY and bar weight is hundred multiple than convert back
    }

    function withdrawAll() public onlyOwner {
        IERC20(currencyAddresses[Currency.EUROC]).transfer(msg.sender, IERC20(currencyAddresses[Currency.EUROC]).balanceOf(address(this)));
        IERC20(currencyAddresses[Currency.USDC]).transfer(msg.sender, IERC20(currencyAddresses[Currency.USDC]).balanceOf(address(this)));
        IERC20(currencyAddresses[Currency.USDT]).transfer(msg.sender, IERC20(currencyAddresses[Currency.USDT]).balanceOf(address(this)));
        payable(msg.sender).transfer(address(this).balance);
    }

    function _burnUnsoldToken(address token, uint256 amount) internal {
        if(amount > 0) {
            IGoldyToken goldyToken = IGoldyToken(token);
            goldyToken.burn(amount);
        }
    }

    function updateGoldyPriceOracle(address _goldyOracle) external onlyOwner {
        goldyOracle = _goldyOracle;
    }

    function _getTotalSoldToken() internal view returns (uint) {
        uint soldToken;
        for (uint256 i = 0; i < _saleTracker; i++) {
            Sale memory sale = sales[i];
            soldToken += sale.soldToken;
        }
        return soldToken;
    }

    function updateStartDate() external onlyOwner {
        _updateStartDate();
    }
    function _updateStartDate() internal {
        startDate = block.timestamp;
    }

    function toggleKycStatus() external onlyAdmins {
        Sale storage sale = sales[_saleTracker - 1];
        sale.isKycActive = !sale.isKycActive;
    }

    function _isValidTx(Sale memory sale) internal view returns (bool) {
        if(!sale.isKycActive) {
            return true;
        }
        return kycStatus[msg.sender];
    }

    function updateKycStatus(address[] memory _users, KycStatuses _kycStatus, string[] memory message) external onlyAdmins {
        require(_users.length > 0 && _users.length == message.length, 'length mismatch');
        if (KycStatuses.APPROVE == _kycStatus) {
            for(uint i = 0; i < _users.length; i++) {
                kycStatus[_users[i]] = true;
                emit KycAction(_users[i], KycStatuses.APPROVE, msg.sender, message[i]);
            }
        } else if (KycStatuses.REJECT == _kycStatus) {
            for(uint i = 0; i < _users.length; i++) {
                kycStatus[_users[i]] = false;
                emit KycAction(_users[i], KycStatuses.REJECT, msg.sender, message[i]);
            }
        }
    }

    function updateFees(uint _fees) external onlyOwner {
        require(_fees > 0, 'IV'); // Invalid value
        fees = _fees;
    }
}
