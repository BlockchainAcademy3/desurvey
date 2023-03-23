// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IDeSurveyNFT {
    function mint(address user) external returns (uint256);

    function burn(address user) external;

    function setBaseURI(string memory baseURI) external;
}
