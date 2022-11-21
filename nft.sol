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
    mapping(uint256 => NftToken)  listedTokens;
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
        bool forSell;
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

    // listing price

    function getListingPrice() public view returns (uint256) {
        return nftGasfee;
    }


    function getListedToken(uint256 tokenId)public view returns (NftToken memory){
        require(_exists(tokenId), "Token does not exist");
        return listedTokens[tokenId] ;

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
            true
        );

        approve(address(this), tokenid);
    }

    function buyNft(uint256 tokenid) external {

            // Check pause
            require(!paused(), "Contract is paused");

            // Check if token is listed for sale
            require(
                listedTokens[tokenid].forSell == true,
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
        // Transfer token to owner
        pigeonToken.transferFrom(
            msg.sender,
            listedTokens[tokenid].seller,
            listedTokens[tokenid].price
        );
        // Update token price
        listedTokens[tokenid].price = 0;
        // Update token sold count
        listedTokens[tokenid].seller = msg.sender;
    }


    function ToggleoggleNftForSell(uint256 tokenid) public  {
        // require(listedTokens[tokenid].forSell == false, "Already for sale");
        require(
            ownerOf(tokenid) == msg.sender,
            "You are not the owner of this token"
        );

        listedTokens[tokenid].forSell = true;
    }

    // function UpdateNftPrice(uint256 tokenid, uint256 price) public {

    //     require(
    //         ownerOf(tokenid) == msg.sender,
    //         "You are not the owner of this token"
    //     );

    //     if (listedTokens[tokenid].price != price) {
    //         listedTokens[tokenid].price = price;
    //     }
    //     if (listedTokens[tokenid].forSell == false) {
    //         listedTokens[tokenid].forSell = true;
    //     }
    // }



    function balanceOf(address owner) public view override returns (uint256) {
        return pigeonToken.balanceOf(owner);
    }


    // function getNftToken(uint256 tokenid) public view returns (NftToken memory) {
    //     require(_exists(tokenid), "Token does not exist");
    //     return listedTokens[tokenid];
    // }

    function fetchAllNfts() public view returns (NftToken[] memory) {
        NftToken[] memory tokens = new NftToken[](_tokenIds.current());
        uint256 index = 0;
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if (listedTokens[i + 1].forSell == true) {
                tokens[index] = listedTokens[i + 1];
                index++;
            }
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
