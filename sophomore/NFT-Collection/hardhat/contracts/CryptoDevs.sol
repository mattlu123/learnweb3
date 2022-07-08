// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

contract CryptoDevs is ERC721Enumerable, Ownable{
    string _baseTokenURI;
    uint256 public _price = 0.01 ether; //price of one cryptodev nft
    bool public _paused;
    uint256 public maxTokenIds = 20; //max # of tokens
    uint256 public tokenIds; //# of tokens minted
    IWhitelist whitelist; //whitelist contract
    bool public presaleStarted; //whether presale started or not
    uint256 public presaleEnded; //timestamp for when presale ends
    

    modifier onlyWhenNotPaused {
        require(!_paused, "Contract currently paused");
        _;
    }

    constructor(string memory baseURI, address whitelistContract) ERC721("Crypto Devs", "CD") {
        _baseTokenURI = baseURI;
        whitelist = IWhitelist(whitelistContract);
    }

    //starts presale, ends presale after 5 minutes
    function startPresale() public onlyOwner {
        presaleStarted = true;
        presaleEnded = block.timestamp + 5 minutes;
    }

    //allows a user to mint one NFT per transaction
    function presaleMint() public payable onlyWhenNotPaused {
        //check if presale has started
        require(presaleStarted && block.timestamp < presaleEnded, "Presale is not running");
        //check if whitelisted
        require(whitelist.whitelistedAddresses(msg.sender), "You are not whitelisted");
        //check if exceeded max tokens minted
        require(tokenIds < maxTokenIds, "Max tokens exceeded");
        //check if ether sent is correct
        require(msg.value >= _price, "Incorrect amount of ether");
        tokenIds += 1;

        //_mint
        _safeMint(msg.sender, tokenIds);
    }

    //allows user to mint one nft per transaction after presale has ended
    function mint() public payable onlyWhenNotPaused {
        require(presaleStarted && block.timestamp >=  presaleEnded, "Presale has not ended yet");
        require(tokenIds < maxTokenIds, "Exceed maximum Crypto Devs supply");
        require(msg.value >= _price, "Ether sent is not correct");
        tokenIds += 1;
        _safeMint(msg.sender, tokenIds);
    }

    //overrides the Openzeppelin's ERC721 implementation which by default
    function _baseURI() internal view virtual override returns (string memory) {
        //returns empty string
        return _baseTokenURI;
    }

    //pauses or unpauses function
    function setPaused(bool val) public onlyOwner {
        _paused = val;
    }

    //sends all ether in contract to owner of contract
    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "failed to send");
    }

    //receive ether
    receive() external payable {}
    fallback() external payable{}
}