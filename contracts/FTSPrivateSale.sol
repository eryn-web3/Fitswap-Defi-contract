// SPDX-License-Identifier: GPL-3.0-or-later Or MIT

/**
 *Submitted for verification at BscScan.com on 2021-05-28
*/

pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool ok);
}

contract FTSPrivateSale {
    using SafeMath for uint256;

    IBEP20 public FTS;
    
    address payable public owner;

    uint256 public startDate = 1633651200;                  // 2021/10/08 00:00:00 UTC
    uint256 public endDate = 1635551999;                    // 2021/10/29 23:59:59 UTC
    
    uint256 public totalTokensToSell = 30000000 * 10**18;          // 30000000 FTS tokens for sell
    uint256 public ftsPerBnb = 10000 * 10**18;             // 1 BNB = 10000 FTS
    uint256 public minPerTransaction = 2500 * 10**18;         // min amount per transaction (0.25BNB)
    uint256 public maxPerUser = 100000 * 10**18;                // max amount per user (10BNB)
    uint256 public totalSold;

    bool public saleEnded;
    
    mapping(address => uint256) public ftsPerAddresses;

    event tokensBought(address indexed user, uint256 amountSpent, uint256 amountBought, string tokenName, uint256 date);
    event tokensClaimed(address indexed user, uint256 amount, uint256 date);

    modifier checkSaleRequirements(uint256 buyAmount) {
        require(now >= startDate && now < endDate, 'Presale time passed');
        require(saleEnded == false, 'Sale ended');
        require(
            buyAmount > 0 && buyAmount <= unsoldTokens(),
            'Insufficient buy amount'
        );
        _;
    }

    constructor(
        address _FTS        
    ) public {
        owner = msg.sender;
        FTS = IBEP20(_FTS);
    }

    // Function to buy FTS using BNB token
    function buyWithBNB(uint256 buyAmount) public payable checkSaleRequirements(buyAmount) {
        uint256 amount = calculateBNBAmount(buyAmount);
        require(msg.value >= amount, 'Insufficient BNB balance');
        require(buyAmount >= minPerTransaction, 'Lower than the minimal transaction amount');
        
        uint256 sumSoFar = ftsPerAddresses[msg.sender].add(buyAmount);
        require(sumSoFar <= maxPerUser, 'Greater than the maximum purchase limit');

        ftsPerAddresses[msg.sender] = sumSoFar;
        totalSold = totalSold.add(buyAmount);
        
        FTS.transfer(msg.sender, buyAmount);
        emit tokensBought(msg.sender, amount, buyAmount, 'BNB', now);
    }

    //function to change the owner
    //only owner can call this function
    function changeOwner(address payable _owner) public {
        require(msg.sender == owner);
        owner = _owner;
    }

    // function to set the presale start date
    // only owner can call this function
    function setStartDate(uint256 _startDate) public {
        require(msg.sender == owner && saleEnded == false);
        startDate = _startDate;
    }

    // function to set the presale end date
    // only owner can call this function
    function setEndDate(uint256 _endDate) public {
        require(msg.sender == owner && saleEnded == false);
        endDate = _endDate;
    }

    // function to set the total tokens to sell
    // only owner can call this function
    function setTotalTokensToSell(uint256 _totalTokensToSell) public {
        require(msg.sender == owner);
        totalTokensToSell = _totalTokensToSell;
    }

    // function to set the minimal transaction amount
    // only owner can call this function
    function setMinPerTransaction(uint256 _minPerTransaction) public {
        require(msg.sender == owner);
        minPerTransaction = _minPerTransaction;
    }

    // function to set the maximum amount which a user can buy
    // only owner can call this function
    function setMaxPerUser(uint256 _maxPerUser) public {
        require(msg.sender == owner);
        maxPerUser = _maxPerUser;
    }

    // function to set the total tokens to sell
    // only owner can call this function
    function setTokenPricePerBNB(uint256 _ftsPerBnb) public {
        require(msg.sender == owner);
        require(_ftsPerBnb > 0, "Invalid FTS price per BNB");
        ftsPerBnb = _ftsPerBnb;
    }

    //function to end the sale
    //only owner can call this function
    function endSale() public {
        require(msg.sender == owner && saleEnded == false);
        saleEnded = true;
    }

    //function to withdraw collected tokens by sale.
    //only owner can call this function

    function withdrawCollectedTokens() public {
        require(msg.sender == owner);
        require(address(this).balance > 0, "Insufficient balance");
        owner.transfer(address(this).balance);
    }

    //function to withdraw unsold tokens
    //only owner can call this function
    function withdrawUnsoldTokens() public {
        require(msg.sender == owner);
        uint256 remainedTokens = unsoldTokens();
        require(remainedTokens > 0, "No remained tokens");
        FTS.transfer(owner, remainedTokens);
    }

    //function to return the amount of unsold tokens
    function unsoldTokens() public view returns (uint256) {
        // return totalTokensToSell.sub(totalSold);
        return FTS.balanceOf(address(this));
    }

    //function to calculate the quantity of FTS token based on the FTS price of bnbAmount
    function calculateFTSAmount(uint256 bnbAmount) public view returns (uint256) {
        uint256 ftsAmount = ftsPerBnb.mul(bnbAmount).div(10**18);
        return ftsAmount;
    }

    //function to calculate the quantity of bnb needed using its FTS price to buy `buyAmount` of FTS tokens.
    function calculateBNBAmount(uint256 ftsAmount) public view returns (uint256) {
        require(ftsPerBnb > 0, "FTS price per BNB should be greater than 0");
        uint256 bnbAmount = ftsAmount.mul(10**18).div(ftsPerBnb);
        return bnbAmount;
    }
}