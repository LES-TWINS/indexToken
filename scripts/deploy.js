const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying with address:", deployer.address);
  console.log(
    "Deployer balance:",
    ethers.formatEther(await deployer.getBalance()),
    "ETH"
  );

  const IndexToken = await ethers.getContractFactory("IndexToken");
  const indexToken = await IndexToken.deploy("IndexToken", "IDX");

  await indexToken.waitForDeployment();

  const addr = await indexToken.getAddress();
  console.log("IndexToken deployed to:", addr);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
