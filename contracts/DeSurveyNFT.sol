// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DeSurveyNFT is ERC721 {
    using Strings for uint256;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constants **************************************** //
    // ---------------------------------------------------------------------------------------- //
    address public immutable FACTORY = msg.sender;

    // Level of this NFT
    uint256 public immutable level;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Limit supply for this NFT
    uint256 public limit;

    // Mint Price
    uint256 public price;

    // Current token ID
    // Each time a new token is minted, currentId will be increased by 1
    uint256 public currentId;

    // User address => Token Id
    // One user can only have one token for each achievement
    mapping(address => uint256) public userTokenId;

    string public baseURI;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event BaseURIChanged(string oldBaseURI, string newBaseURI);

    event MintPriceChanged(uint256 oldPrice, uint256 newPrice);

    event Mint(address indexed user, uint256 tokenId);
    event Burn(address indexed user, uint256 tokenId);

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    constructor(
        uint256 _level,
        uint256 _price,
        uint256 _limit
    )
        ERC721(
            string.concat("DeSurveyNFT-Level", _level.toString()),
            string.concat("DSNFT-L", _level.toString())
        )
    {
        level = _level;
        price = _price;
        limit = _limit;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    modifier onlyFactory() {
        require(
            msg.sender == FACTORY,
            "AchievementsNFT: Only factory contract can call"
        );
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Set the base URI for token metadata
     *         Only called by the factory contract
     */
    function setBaseURI(string memory _uri) external onlyFactory {
        emit BaseURIChanged(baseURI, _uri);
        baseURI = _uri;
    }

    function setLimit(uint256 _limit) external onlyFactory {
        require(_limit >= currentId, "DeSurveyNFT: Limit too low");

        limit = _limit;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Mint a new achievement NFT for a user
     *         Only the factory contract can call this function
     *         If this NFT has a mint price, check the user's value
     *
     * @param _to User address
     *
     * @return tokenId The token ID of the new NFT
     */
    function mint(
        address _to
    ) external payable onlyFactory returns (uint256 tokenId) {
        require(currentId <= limit, "DesurveyNFT: Exceed limit");
        require(userTokenId[_to] == 0, "DesurveyNFT: Already minted");

        if (price > 0) {
            require(msg.value >= price, "DesurveyNFT: Not enough value");
        }

        // Token ID starts from 1
        tokenId = ++currentId;

        // Mint NFT to user
        _safeMint(_to, tokenId);

        // Record the token id
        userTokenId[_to] = tokenId;

        emit Mint(_to, tokenId);
    }

    /**
     * @notice Burn an achievement NFT
     *
     * @param _to      User address
     * @param _tokenId Token ID
     */
    function burn(address _to, uint256 _tokenId) external onlyFactory {
        require(ownerOf(_tokenId) == _to, "DesurveyNFT: Not owner of token");

        // Burn NFT
        _burn(_tokenId);

        // Delete the record
        userTokenId[_to] = 0;

        emit Burn(_to, _tokenId);
    }
}
