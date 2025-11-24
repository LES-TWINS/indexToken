// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IndexToken is ERC20, Ownable {
    struct Asset {
        address token;      // ERC20 ტოკენის მისამართი
        uint256 weightBps;  // წილი basis points-ში (მაგ. 5000 = 50%)
        bool active;
    }

    Asset[] public assets;

    // divisor, indexPrice, totalMarketCap - 1e18 precision
    uint256 public divisor;        // divider (scaled by 1e18)
    uint256 public indexPrice;     // მიმდინარე index price (scaled by 1e18)
    uint256 public totalMarketCap; // მიმდინარე total market cap (scaled by 1e18)

    event IndexInitialized(
        uint256 totalMarketCap,
        uint256 indexPrice,
        uint256 divisor
    );

    event MarketCapUpdated(
        uint256 newTotalMarketCap,
        uint256 newIndexPrice,
        uint256 divisor
    );

    event Rebalanced(
        uint256 newTotalMarketCap,
        uint256 newIndexPrice,
        uint256 newDivisor
    );

    event AssetListUpdated();

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
        Ownable(msg.sender)
    {}

    // ========= VIEW FUNCTIONS =========

    function assetCount() external view returns (uint256) {
        return assets.length;
    }

    function getAssets() external view returns (Asset[] memory) {
        return assets;
    }

    function getIndexPrice() external view returns (uint256) {
        return indexPrice;
    }

    // ========= ADMIN FUNCTIONS =========

    /**
     * @dev საწყისი ინიციალიზაცია.
     * totalMarketCap_ და indexPrice_ მოგვდის off-chain ოპერატორიდან (scaled by 1e18).
     */
    function initializeIndex(
        Asset[] memory _assets,
        uint256 totalMarketCap_,
        uint256 indexPrice_
    ) external onlyOwner {
        require(divisor == 0, "Already initialized");
        require(totalSupply() == 0, "Token already minted");
        require(_assets.length > 0, "No assets");
        require(indexPrice_ > 0, "IndexPrice zero");
        require(totalMarketCap_ > 0, "MarketCap zero");

        delete assets;
        uint256 sumWeights;

        for (uint256 i = 0; i < _assets.length; i++) {
            require(_assets[i].token != address(0), "Zero token");
            require(_assets[i].weightBps > 0, "Zero weight");

            assets.push(
                Asset({
                    token: _assets[i].token,
                    weightBps: _assets[i].weightBps,
                    active: true
                })
            );
            sumWeights += _assets[i].weightBps;
        }

        // ვაიძულებთ 10000 bps = 100%
        require(sumWeights == 10000, "Weights must sum to 10000 bps");

        totalMarketCap = totalMarketCap_;
        indexPrice = indexPrice_;

        // divisor = totalMarketCap / indexPrice (ორივე 1e18-ზეა)
        divisor = (totalMarketCap * 1e18) / indexPrice;

        emit IndexInitialized(totalMarketCap, indexPrice, divisor);

        // სურვილისამებრ: დავმინტოთ 1000 IDX (1e18 precision-ით)
        _mint(msg.sender, 1000 * 1e18);
    }

    /**
     * constituents არ იცვლება, divisor უცვლელია.
     */
    function updateMarketCapSameConstituents(
        uint256 newTotalMarketCap_,
        uint256 newIndexPrice_
    ) external onlyOwner {
        require(divisor != 0, "Not initialized");
        require(newIndexPrice_ > 0, "IndexPrice zero");
        require(newTotalMarketCap_ > 0, "MarketCap zero");

        totalMarketCap = newTotalMarketCap_;
        indexPrice = newIndexPrice_;

        emit MarketCapUpdated(totalMarketCap, indexPrice, divisor);
    }

    /**
     * constituents იცვლება -> divisor თავიდან ითვლება:
     * divisor = newTotalCap / newIndexPrice
     */
    function rebalanceWithConstituentChange(
        Asset[] memory _newAssets,
        uint256 newTotalMarketCap_,
        uint256 newIndexPrice_
    ) external onlyOwner {
        require(divisor != 0, "Not initialized");
        require(_newAssets.length > 0, "No assets");
        require(newTotalMarketCap_ > 0, "MarketCap zero");
        require(newIndexPrice_ > 0, "IndexPrice zero");

        delete assets;
        uint256 sumWeights;

        for (uint256 i = 0; i < _newAssets.length; i++) {
            require(_newAssets[i].token != address(0), "Zero token");
            require(_newAssets[i].weightBps > 0, "Zero weight");

            assets.push(
                Asset({
                    token: _newAssets[i].token,
                    weightBps: _newAssets[i].weightBps,
                    active: true
                })
            );
            sumWeights += _newAssets[i].weightBps;
        }

        require(sumWeights == 10000, "Weights must sum to 10000 bps");

        totalMarketCap = newTotalMarketCap_;
        indexPrice = newIndexPrice_;

        divisor = (totalMarketCap * 1e18) / indexPrice;

        emit AssetListUpdated();
        emit Rebalanced(totalMarketCap, indexPrice, divisor);
    }
}
