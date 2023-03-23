// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "./IDeSurveyNFT.sol";
import "./DeSurveyNFT.sol";

contract DeSurveyNFTFactory is OwnableUpgradeable {
    using ECDSAUpgradeable for bytes32;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constants **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // EIP712 related variables
    // When updating the contract, directly update these constants
    bytes32 public constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant HASHED_NAME =
        keccak256(bytes("DeSurveyNFTFactory"));
    bytes32 public constant HASHED_VERSION = keccak256(bytes("1.0"));

    bytes32 public constant MINT_REQUEST_TYPEHASH =
        keccak256("MintRequest(address user,uint256 level,uint256 validUntil)");

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    struct MintRequest {
        address user; // User address
        uint256 level; // Level of NFT
        uint256 validUntil; // Signature valid until
    }

    mapping(address => bool) public isValidSigner;

    uint256 public currentLevel;

    mapping(uint256 => address) public levelToNFTAddress;

    mapping(uint256 => uint256) public levelToPrice;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event SignerAdded(address newSigner);
    event SignerRemoved(address oldSigner);
    event DeSurveyNFTCreated(uint256 level, address nftAddress);
    event DeSurveyNFTMinted(address user, uint256 level, uint256 tokenId);

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize() public initializer {
        __Ownable_init();
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Modifiers **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    function getDomainSeparatorV4()
        public
        view
        returns (bytes32 domainSeparator)
    {
        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                HASHED_NAME,
                HASHED_VERSION,
                block.chainid,
                address(this)
            )
        );
    }

    function getStructHash(
        MintRequest memory _mintRequest
    ) public pure returns (bytes32 structHash) {
        structHash = keccak256(
            abi.encode(
                MINT_REQUEST_TYPEHASH,
                _mintRequest.user,
                _mintRequest.level,
                _mintRequest.validUntil
            )
        );
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    function addSigner(address _signer) external onlyOwner {
        isValidSigner[_signer] = true;
        emit SignerAdded(_signer);
    }

    function removeSigner(address _signer) external onlyOwner {
        isValidSigner[_signer] = false;
        emit SignerRemoved(_signer);
    }

    function setBaseURI(uint256 _level, string memory _uri) external onlyOwner {
        IDeSurveyNFT(levelToNFTAddress[_level]).setBaseURI(_uri);
    }

    function setLimit(uint256 _level, uint256 _limit) external onlyOwner {
        IDeSurveyNFT(levelToNFTAddress[_level]).setLimit(_limit); 
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    function createDeSurveyNFT(
        uint256 _price,
        uint256 _limit
    ) external onlyOwner {
        uint256 level = ++currentLevel;

        require(
            levelToNFTAddress[level] == address(0),
            "DeSurveyNFTFactory: NFT already exists"
        );

        address newDeSurveyNFT = address(
            new DeSurveyNFT(level, _price, _limit)
        );

        levelToNFTAddress[level] = newDeSurveyNFT;
        levelToPrice[level] = _price;

        emit DeSurveyNFTCreated(level, newDeSurveyNFT);
    }

    function mintDeSurveyNFT(
        uint256 _level,
        uint256 _validUntil,
        bytes calldata _signature
    ) external payable {
        require(
            levelToNFTAddress[_level] != address(0),
            "DeSurveyNFTFactory: NFT does not exist"
        );

        _checkEIP712Signature(msg.sender, _level, _validUntil, _signature);

        uint256 tokenId = IDeSurveyNFT(levelToNFTAddress[_level]).mint(
            msg.sender
        );

        emit DeSurveyNFTMinted(msg.sender, _level, tokenId);
    }

    function _checkEIP712Signature(
        address _user,
        uint256 _level,
        uint256 _validUntil,
        bytes calldata _signature
    ) public view {
        MintRequest memory req = MintRequest({
            user: _user,
            level: _level,
            validUntil: _validUntil
        });

        bytes32 digest = getDomainSeparatorV4().toTypedDataHash(
            getStructHash(req)
        );

        address recoveredAddress = digest.recover(_signature);

        require(
            isValidSigner[recoveredAddress],
            "DeSurveyNFTFactory: Invalid signer"
        );

        require(
            block.timestamp <= _validUntil,
            "DeSurveyNFTFactory: Signature expired"
        );
    }
}
