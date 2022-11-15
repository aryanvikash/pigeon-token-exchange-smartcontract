// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PigeonNft is Pausable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    IERC20 pigeonToken;
    // List price in pgn token
    uint256 nftGasfee = 6;
    // Store Token ID and price
    mapping(uint256 => NftToken) public listedTokens;
    //  Base URI
    string private baseURI = "https://gateway.pinata.cloud/ipfs/";

    constructor() ERC721("PiegonMarketPlace", "MPGN") {
        // erc20 token
        pigeonToken = IERC20(0x1c6c8bA54A97A63f8921e618C964Bfd920870644);
    }

    struct NftToken {
        uint256 tokenId;
        address creator;
        address seller;
        uint256 price;
        string tokenURI;
        bool forsale;
        uint256 soldCount;
        bool isPremium;
    }

    /** Start Pause */
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /** End Pause */

    function _setTokenAddress(address _tokenAddress) public onlyOwner {
        pigeonToken = IERC20(_tokenAddress);
    }

    // Mint nft with PGN Token
    function mintNft(string memory tokenURI, uint256 price)
        public
        returns (uint256)
    {
        // check paused
        require(!paused(), "Contract is paused");
        require(price > 0, "Price should be greater than 0");
        // Token Minting charge (platform charge)
        // TODO
        require(
            pigeonToken.balanceOf(msg.sender) >= nftGasfee,
            "You don't have enough PGN token"
        );

        pigeonToken.transferFrom(_msgSender(), owner(), nftGasfee);

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        // Add token and list for given price
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        _listNftOnMarket(newItemId, price);

        return newItemId;
    }

    /**
    List Nft Token on market place First time
    */
    function _listNftOnMarket(uint256 tokenid, uint256 price) internal {
        listedTokens[tokenid] = NftToken(
            tokenid,
            msg.sender,
            msg.sender,
            price,
            tokenURI(tokenid),
            true,
            0,
            false
        );

        approve(address(this), tokenid);
    }

    // Make it visible for sale on market place
    function SellNft(uint256 tokenid) public {
        require(listedTokens[tokenid].forsale == false, "Already for sale");
        require(
            ownerOf(tokenid) == msg.sender,
            "You are not the owner of this token"
        );

        listedTokens[tokenid].forsale = true;
    }

    // Make Nft Token for sale on market place with custom price
    function SellNft(uint256 tokenid, uint256 price) public {
        require(listedTokens[tokenid].forsale == false, "Already for sale");
        require(
            ownerOf(tokenid) == msg.sender,
            "You are not the owner of this token"
        );

        if (listedTokens[tokenid].price != price) {
            listedTokens[tokenid].price = price;
        }
        if (listedTokens[tokenid].forsale == false) {
            listedTokens[tokenid].forsale = true;
        }
    }

    function RemoveSell(uint256 tokenid) external {
        // Remove token from list
        require(
            listedTokens[tokenid].forsale == true,
            "Token is not listed for sale"
        );

        require(
            listedTokens[tokenid].seller == msg.sender,
            "You are not the owner of this token"
        );

        listedTokens[tokenid].forsale = false;
    }

    // override balance of
    function balanceOf(address owner) public view override returns (uint256) {
        return pigeonToken.balanceOf(owner);
    }

    function purchaseNft(uint256 tokenid) external {
        // Check pause
        require(!paused(), "Contract is paused");

        // Check if token is listed for sale
        require(
            listedTokens[tokenid].forsale == true,
            "Token is not for sale or sold out"
        );
        // Check if token is not sold
        require(listedTokens[tokenid].price > 0, "Token is already sold out");
        // Check if buyer has enough balance
        require(
            pigeonToken.balanceOf(msg.sender) >= listedTokens[tokenid].price,
            "You don't have enough PGN token"
        );

        // Transfer token to buyer
        _transfer(listedTokens[tokenid].seller, msg.sender, tokenid);
        // Transfer token to seller
        pigeonToken.transferFrom(
            msg.sender,
            listedTokens[tokenid].seller,
            listedTokens[tokenid].price
        );
        // Update token price
        listedTokens[tokenid].price = 0;
        // Update token sold count
        listedTokens[tokenid].soldCount += 1;
        listedTokens[tokenid].seller = msg.sender;
    }

    // function getNftToken(uint256 tokenid) public view returns (NftToken memory) {
    //     require(_exists(tokenid), "Token does not exist");
    //     return listedTokens[tokenid];
    // }

    /** Claim a nft Which is shared by Pigeon and owned by contract */
    function claimOpenNft(uint256 tokenid) external {
        // Check pause
        require(!paused(), "Contract is paused");

        // Check if token is listed for sale
        require(
            listedTokens[tokenid].forsale == true,
            "Token is not for sale or sold out"
        );
        // Check if creator is contract
        require(
            listedTokens[tokenid].seller == listedTokens[tokenid].creator,
            "Token is not open for claim"
        );

        require(
            listedTokens[tokenid].seller == address(this),
            "Token alredy claimed"
        );

        // Transfer token to buyer
        _transfer(listedTokens[tokenid].seller, _msgSender(), tokenid);
    }

    function fetchAllNfts() public view returns (NftToken[] memory) {
        NftToken[] memory tokens = new NftToken[](_tokenIds.current());
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            tokens[i] = listedTokens[i + 1];
        }
        return tokens;
    }

    // Get all nfts by user
    function fetchNftsByUser(address user)
        public
        view
        returns (NftToken[] memory)
    {
        NftToken[] memory tokens = new NftToken[](_tokenIds.current());
        uint256 count = 0;
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if (listedTokens[i + 1].seller == user) {
                tokens[count] = listedTokens[i + 1];
                count++;
            }
        }
        return tokens;
    }

    function fetchAllMyNfts() public view returns (NftToken[] memory) {
        NftToken[] memory tokens = new NftToken[](_tokenIds.current());
        uint256 count = 0;
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if (listedTokens[i + 1].seller == msg.sender) {
                tokens[count] = listedTokens[i + 1];
                count++;
            }
        }
        return tokens;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /** Base Uri Starts */
    //  baseuri from erc721Storage
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function baseUri() external view returns (string memory) {
        return baseURI;
    }

    /** Base Uri Ends */
}
