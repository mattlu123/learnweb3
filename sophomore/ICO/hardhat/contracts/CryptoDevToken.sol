// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoDevs.sol";

contract CryptoDevToken is ERC20, Ownable {
    uint256 public constant tokenPrice = 0.001 ether; //price of one token
    uint256 public constant tokensPerNFT = 10 * 10**18;
    uint256 public constant maxTotalSupply = 10000 * 10**18;
    ICryptoDevs CryptoDevsNFT;
    mapping(uint256 => bool) public tokenIdsClaimed; // Mapping to keep track of which tokenIds have been claimed

    constructor(address _cryptoDevsContract) ERC20("Crypto Dev Token", "CD"){
        CryptoDevsNFT = ICryptoDevs(_cryptoDevsContract);
    }  

    function mint(uint256 amount) public payable {
        // the value of ether that should be equal or greater than tokenPrice * amount;
        uint256 _requiredAmount = tokenPrice * amount;
        require(msg.value >= _requiredAmount, "Ether sent is correct");
        // total tokens + amount <= 10000, otherwise revert the transaction
        uint256 amountWithDecimals = amount * 10**18;
        require(
            (totalSupply() + amountWithDecimals) <= maxTotalSupply,
            "Exceeds the max total supply available."
        );
        _mint(msg.sender, amountWithDecimals);
    }

    //Mints tokens based on the number of NFT's held by the sender
    function claim() public {
        address sender = msg.sender;
        uint256 balance = CryptoDevsNFT.balanceOf(sender); //get the balance
        require(balance > 0, "You don't own any CD");
        uint256 amount; //keeps track of unclaimed tokenIds

        //loop through balance and get the token ID owned by `sender` at a given `index` of its token list.
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = CryptoDevsNFT.tokenOfOwnerByIndex(sender, i);
            // if the tokenId has not been claimed, increase the amount
            if (!tokenIdsClaimed[tokenId]) {
                amount += 1;
                tokenIdsClaimed[tokenId] = true;
            }
        }

        require(amount > 0, "you have already claimed all the tokens");
        _mint(msg.sender, amount * tokensPerNFT);
    }
    
    //withdraws all ETH and tokens sent to the contract
    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}