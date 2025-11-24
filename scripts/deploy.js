const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying with:", deployer.address);
  const balance = await deployer.provider.getBalance(deployer.address);
  console.log("Balance:", ethers.formatEther(balance), "ETH");

  const IndexToken = await ethers.getContractFactory("IndexToken");

  // constructor(name, symbol)
  const token = await IndexToken.deploy("Index Token", "INDX");

  console.log("Waiting for deployment...");
  await token.waitForDeployment();

  console.log("Deployed at:", await token.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
