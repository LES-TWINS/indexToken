const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("IndexToken", function () {
  it("initializes with correct divisor", async function () {
    const [owner] = await ethers.getSigners();

    const IndexToken = await ethers.getContractFactory("IndexToken");
    const indexToken = await IndexToken.deploy("MyIndex", "IDX");
    const indexTokenAddress = await indexToken.getAddress();

    const assets = [
      { token: owner.address, weightBps: 5000, active: true },
      { token: indexTokenAddress, weightBps: 5000, active: true },
    ];

    const totalCap = ethers.parseUnits("45000000000", 18);
    const indexPrice = ethers.parseUnits("100", 18);

    await indexToken.initializeIndex(assets, totalCap, indexPrice);

    const divisor = await indexToken.divisor();
    const expectedDivisor = (totalCap * 10n ** 18n) / indexPrice;

    expect(divisor).to.equal(expectedDivisor);
  });
});
