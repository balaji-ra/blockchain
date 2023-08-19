// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract LoyaltyToken is ERC20, AccessControl, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address private owner;
    uint256 private tokenRate;

    mapping(address => uint256) private rewardsBalance;
    mapping(address => bytes32) private encryptedEmails; // Hashed or encrypted email addresses

    // Privacy considerations
    mapping(address => bool) private hasAcceptedPrivacyPolicy;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _initialSupply);
        owner = msg.sender;
        tokenRate = 10;

        _setupRole(ADMIN_ROLE, msg.sender);
    }

    modifier onlyOwnerOrAdmin() {
        require(
            msg.sender == owner || hasRole(ADMIN_ROLE, msg.sender),
            "Unauthorized"
        );
        _;
    }

    function acceptPrivacyPolicy() external {
        hasAcceptedPrivacyPolicy[msg.sender] = true;
    }

    function hasAcceptedPrivacy() external view returns (bool) {
        return hasAcceptedPrivacyPolicy[msg.sender];
    }

    function setTokenRate(uint256 _newRate) external onlyOwnerOrAdmin {
        tokenRate = _newRate;
    }

    function purchase(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Purchase amount must be greater than 0");
        require(hasAcceptedPrivacyPolicy[msg.sender], "Privacy policy not accepted");
        
        uint256 tokensEarned = _amount * tokenRate;
        rewardsBalance[msg.sender] += tokensEarned;
        _mint(address(this), tokensEarned);
    }

    function redeemTokens(uint256 _amount) external whenNotPaused {
        require(rewardsBalance[msg.sender] >= _amount, "Insufficient tokens");
        rewardsBalance[msg.sender] -= _amount;
        _burn(address(this), _amount);

        // Example redemption logic: Discount on a fictional e-commerce platform
        uint256 discountPercentage = _amount / 10; // Assuming 1 token = 10% discount

        // Security considerations
        require(encryptedEmails[msg.sender] != 0x0, "Email not provided");
        require(!paused(), "Contract is paused");
        // Verify user identity and apply discount to their purchase
        // Implement relevant security measures here
        
        emit TokensRedeemed(msg.sender, _amount, discountPercentage);
    }

    function setEmail(bytes32 _encryptedEmail) external {
        require(!hasAcceptedPrivacyPolicy[msg.sender], "Email cannot be updated after accepting privacy policy");
        encryptedEmails[msg.sender] = _encryptedEmail;
    }

    function getEmail() external view returns (bytes32) {
        return encryptedEmails[msg.sender];
    }

    function pause() external onlyOwnerOrAdmin {
        _pause();
    }

    function unpause() external onlyOwnerOrAdmin {
        _unpause();
    }

    event TokensRedeemed(address indexed user, uint256 tokensRedeemed, uint256 discountPercentage);
}
