// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*
PPPPPPPPPPPPPPPPP   IIIIIIIIII      GGGGGGGGGGGGGEEEEEEEEEEEEEEEEEEEEEE     OOOOOOOOO     NNNNNNNN        NNNNNNNN
P::::::::::::::::P  I::::::::I   GGG::::::::::::GE::::::::::::::::::::E   OO:::::::::OO   N:::::::N       N::::::N
P::::::PPPPPP:::::P I::::::::I GG:::::::::::::::GE::::::::::::::::::::E OO:::::::::::::OO N::::::::N      N::::::N
PP:::::P     P:::::PII::::::IIG:::::GGGGGGGG::::GEE::::::EEEEEEEEE::::EO:::::::OOO:::::::ON:::::::::N     N::::::N
  P::::P     P:::::P  I::::I G:::::G       GGGGGG  E:::::E       EEEEEEO::::::O   O::::::ON::::::::::N    N::::::N
  P::::P     P:::::P  I::::IG:::::G                E:::::E             O:::::O     O:::::ON:::::::::::N   N::::::N
  P::::PPPPPP:::::P   I::::IG:::::G                E::::::EEEEEEEEEE   O:::::O     O:::::ON:::::::N::::N  N::::::N
  P:::::::::::::PP    I::::IG:::::G    GGGGGGGGGG  E:::::::::::::::E   O:::::O     O:::::ON::::::N N::::N N::::::N
  P::::PPPPPPPPP      I::::IG:::::G    G::::::::G  E:::::::::::::::E   O:::::O     O:::::ON::::::N  N::::N:::::::N
  P::::P              I::::IG:::::G    GGGGG::::G  E::::::EEEEEEEEEE   O:::::O     O:::::ON::::::N   N:::::::::::N
  P::::P              I::::IG:::::G        G::::G  E:::::E             O:::::O     O:::::ON::::::N    N::::::::::N
  P::::P              I::::I G:::::G       G::::G  E:::::E       EEEEEEO::::::O   O::::::ON::::::N     N:::::::::N
PP::::::PP          II::::::IIG:::::GGGGGGGG::::GEE::::::EEEEEEEE:::::EO:::::::OOO:::::::ON::::::N      N::::::::N
P::::::::P          I::::::::I GG:::::::::::::::GE::::::::::::::::::::E OO:::::::::::::OO N::::::N       N:::::::N
P::::::::P          I::::::::I   GGG::::::GGG:::GE::::::::::::::::::::E   OO:::::::::OO   N::::::N        N::::::N
PPPPPPPPPP          IIIIIIIIII      GGGGGG   GGGGEEEEEEEEEEEEEEEEEEEEEE     OOOOOOOOO     NNNNNNNN         NNNNNNN
*/

contract PgnExchange is Ownable {
    IERC20 token;

    // 1 PGN Token usd price
    uint256 public usdPrice = 1;
    // Total PGN tokens in circulation;
    uint256 total_bnb = 0;
    // Minimum amount of PGN to be exchanged
    uint16 public min_token_limit = 1;
    AggregatorV3Interface internal priceFeed;

    constructor() {
        token = IERC20(0x1c6c8bA54A97A63f8921e618C964Bfd920870644);

        //  Bnb Main net
        // priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE );

        // Bnb testnet
        priceFeed = AggregatorV3Interface(
            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        );
    }

    // only owner
    function getTotalBnb() public view onlyOwner returns (uint256) {
        return total_bnb;
    }

    function setPricefeedAddress(address _priceFeedAddress) public onlyOwner {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function UpdateTokenAddress(address _tokenAddress) public onlyOwner {
        token = IERC20(_tokenAddress);
    }

    function UpdateTokensTotalSupply() public view returns (uint256) {
        return token.totalSupply();
    }

    function setPigeonUsdPrice(uint256 _usdPrice) public onlyOwner {
        usdPrice = _usdPrice;
    }

    function ContractAllowance() external view returns (uint256) {
        return token.allowance(owner(), address(this));
    }

    // Purchase PGN tokens from binance smart chain
    function buyPgnFromBnc() external payable {
        require(msg.value > 0, "No BNB sent");
        uint256 pgn_amount = usdToTokens(bnbToUSD(msg.value));
        require(
            pgn_amount >= min_token_limit,
            "Minimum amount of PGN to be exchanged is 1"
        );
        token.transferFrom(owner(), msg.sender, pgn_amount);
    }

    function MyPgnBalance() external view returns (uint256) {
        return token.balanceOf(msg.sender);
    }

    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price / 10**8;
    }

    function bnbToUSD(uint256 amount) public view returns (uint256) {
        return (amount * uint256(getLatestPrice())) / 10**18;
    }

    // BNB to PGN token
    function bnbToPgn(uint256 amount) public view returns (uint256) {
        return usdToTokens(bnbToUSD(amount));
    }

    function usdToTokens(uint256 amount) public view returns (uint256) {
        return amount / usdPrice;
    }

    function getContractTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function withdraw() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    event TokenPurchase(
        address indexed purchaser,
        uint256 value,
        uint256 amount
    );
}
