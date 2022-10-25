// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "../contracts/token/ERC721/ERC721FCOMMON.sol";
import "../contracts/utils/AllowListWithAmount.sol";

/**
 * @title AllowListWithAmountExample
 * @dev Example implementation of [ERC721] with AllowListWithAmount validation using the AllowListsWithAmount.sol library
 */
contract AllowListWithAmountExample is ERC721FCOMMON, AllowListWithAmount {
    uint256 public constant MAX_TOKENS = 10000;
    uint public constant MAX_PURCHASE = 31;
    uint public tokenPrice = 1 ether;
    bool public preSaleIsActive;
    bool public saleIsActive;

    constructor() ERC721FCOMMON("AllowListWithAmount", "ALA") {
        setBaseTokenURI(
            "ipfs://QmVy7VQUFtTQawBsp4tbJPp9MgbTKS4L7WSDpZEdZUzsiD/"
        );
    }

    modifier validMintRequest(uint256 numberOfTokens) {
        require(numberOfTokens != 0, "numberOfNfts cannot be 0");
        require(
            numberOfTokens < MAX_PURCHASE,
            "Can only mint 30 tokens at a time"
        );
        require(
            tokenPrice * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );
        _;
    }

    /**
     * @notice Changes the state of preSaleIsActive from true to false and false to true
     */
    function flipPreSaleState() external onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    /**
     * @notice Changes the state of saleIsActive from true to false and false to true
     * @dev If saleIsActive becomes `true` sets preSaleIsActive to `false`
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
        if (saleIsActive) {
            preSaleIsActive = false;
        }
    }

    /**
     * @notice Mints a certain number of tokens
     * @param numberOfTokens Total tokens to be minted, must be larger than 0 and at most 30
     */
    function mint(uint256 numberOfTokens)
        external
        payable
        validMintRequest(numberOfTokens)
    {
        require(msg.sender == tx.origin, "No contracts allowed");
        require(saleIsActive, "Sale NOT active yet");
        uint256 supply = _totalMinted();
        require(
            supply + numberOfTokens <= MAX_TOKENS,
            "Purchase would exceed max supply of tokens"
        );

        for (uint256 i; i < numberOfTokens; ) {
            _mint(msg.sender, supply + i);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Mints a certain number of tokens
     * @param numberOfTokens Total tokens to be minted, must be larger than 0 and at most 30. Can't exceed available tokens of account within allowList
     * @dev Uses AllowList.onlyAllowListWithSufficientAvailableTokens modifier for whitelist functionality
     */
    function mintPreSale(uint256 numberOfTokens)
        external
        payable
        validMintRequest(numberOfTokens)
        onlyAllowListWithSufficientAvailableTokens(numberOfTokens)
    {
        require(preSaleIsActive, "PreSale is NOT active yet");
        uint256 supply = _totalMinted();
        require(
            supply + numberOfTokens <= MAX_TOKENS,
            "Purchase would exceed max supply of tokens"
        );

        for (uint256 i; i < numberOfTokens; ) {
            _safeMint(msg.sender, supply + i);
            decreaseAddressAvailableTokens(msg.sender, 1);
            unchecked {
                i++;
            }
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient balance");
        _withdraw(owner(), balance);
    }
}