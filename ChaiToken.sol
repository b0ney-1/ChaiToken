// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChaiToken is ERC20, Ownable {
    uint256 private _initialSupply = 100000000 * 10**decimals(); // 100 million tokens
    uint256 public maxTxAmount = _initialSupply;
    uint256 public cooldownTime = 1 minutes;
    uint256 public taxFees = 5;
    uint256 public SlippageFees = 2; 

    mapping(address=>bool) private _blacklist;
    mapping(address=>bool) private _whitelist;
    mapping(address=>uint256) private _lastTxTime; 
    
    bool private _whiteListingEnabled = false;
    bool private _TaxEnabled = false;

    address public taxAddress; 

    constructor(address initialOwner, address _taxAddress)
        ERC20("ChaiToken", "Chai")
        Ownable(initialOwner)
    {
        _mint(initialOwner, _initialSupply); // Mint initial supply to the initial owner
        _whitelist[initialOwner] = true;
        taxAddress = _taxAddress;
    }

    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
    }

    function addToBlacklist(address account) external onlyOwner
    {
        _blacklist[account] = true;
        _whitelist[account] = false;
    }
    function removeFromBlacklist(address account) external onlyOwner
    {
        _blacklist[account] = false;
    }
    function isBlacklisted(address account) external view returns(bool)  
    {
        return _blacklist[account];
    }

    function enableWhiteListing() external onlyOwner
    {
        _whiteListingEnabled = true;
    }

    function disableWhiteListing() external onlyOwner
    {
        _whiteListingEnabled = false;
    }

    function addToWhitelist(address account) external onlyOwner
    {
        require(!_blacklist[account], "Blacklisted address cannot be whitelisted");
        _whitelist[account] = true;
    }
    function removeFromWhitelist(address account) external onlyOwner
    {
        _whitelist[account] = false;
    }
    function isWhitelisted(address account) external view returns(bool)  
    {
        return _whitelist[account];
    }

    function isWhiteListingEnabled() external view returns(bool)
    {
        return _whiteListingEnabled;
    }

    function setMaxTxAmount(uint256 newMaxTxAmount) external onlyOwner
    {
        maxTxAmount = newMaxTxAmount; 
    }

    function getMaxTxAmount() external view returns(uint256)
    {
        return maxTxAmount;
    }

    function setCoolDownTime(uint256 newCoolDowntime) external onlyOwner
    {
        cooldownTime = newCoolDowntime;
    }

    function getContractDetails() external view returns (address, uint256, uint256,uint256)
    {
        return (owner(), maxTxAmount, cooldownTime, _initialSupply);
    }

    function setTaxes(uint256 newTaxFee) external onlyOwner
    {
        require(newTaxFee <= 10 , "Tax fee must be less than 10%");
        taxFees = newTaxFee;
    }

    function setSlippageFees(uint256 newSlippageFees) external onlyOwner
    {
        require(newSlippageFees <= 5 , "Slippage fees must be less than 5%");
        SlippageFees = newSlippageFees;
    }

    function enableTax() external onlyOwner
    {
        _TaxEnabled = true;
    }

    function disableTax() external onlyOwner
    {
        _TaxEnabled = false;
    }

    function _update(address from, address to, uint256 value) internal override 
    {
        require(!_blacklist[from] && !_blacklist[to] , "Blacklisted Addresses");
        if(_whiteListingEnabled)
        {
            require(_whitelist[from] && _whitelist[to] , "Both addresses must be whitelisted");
        }
        require(value <= maxTxAmount , "Token Transfer Limit Exceeded");
        require(block.timestamp >= _lastTxTime[from]+cooldownTime , "Token Transfer in cooldown");
        
        uint256 transferAmount = value;
        if(_TaxEnabled)
        {
            uint256 totalFees = taxFees + SlippageFees; // percentage
            uint256 feeAmount = (value * totalFees)/100;
            transferAmount = value - feeAmount;
            super._update(from, taxAddress , feeAmount);
        }
        
        _lastTxTime[from] = block.timestamp;
        super._update(from, to, transferAmount); // token transfer from ERC20 Contract
    }

}