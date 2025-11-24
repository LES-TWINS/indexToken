// scripts/initialize.js
const { ethers } = require("ethers");
require("dotenv").config();

async function main() {
  // --- Provider & Wallet ---
  const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC);
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

  console.log("Deployer address:", wallet.address);
  const balance = await provider.getBalance(wallet.address);
  console.log("Balance:", ethers.formatEther(balance), "ETH");

  console.log("Initializing Index...");

  // --- აქ ხელით ჩაწერე ზუსტად შენი IndexToken-ის მისამართი ---
  const contractAddress = "0xBFDB2eD6728d296F8eE9DD9619793EcC438be5c2";

  // დამატებითი შემოწმება – რომ არ იყოს ზედმეტი სიმბოლო
  console.log("Contract address length:", contractAddress.length);
  if (contractAddress.length !== 42) {
    throw new Error("Contract address is not 42 chars – remove spaces/newlines");
  }

  // --- ABI ავტო-ამოტანა artifacts-დან, რომ ხელით არ ვიწვალოთ ---
  const contractJson = require("../artifacts/contracts/IndexToken.sol/IndexToken.json");
  const contractABI = contractJson.abi;

  const idx = new ethers.Contract(contractAddress, contractABI, wallet);

  // --- Index-ის assets (შეიყვანე შენი ტოკენების მისამართები) ---
  const assets = [
    {
      token: "0x7b430a5eef6bdd2004f33d29344ef1b72a2de0b8", // ტესტ ტოკენი Sepolia-ზე
      weightBps: 5000,
      active: true,
    },
    {
      token: "0x7b430a5eef6bdd2004f33d29344ef1b72a2de0b8",
      weightBps: 5000,
      active: true,
    },
  ];

  console.log("Assets:", assets);

  // 1 000 000 * 1e18
  const totalMarketCap = ethers.parseUnits("1000000", 18);
  // 1 000 * 1e18
  const indexPrice = ethers.parseUnits("1000", 18);

  console.log("Total Market Cap:", totalMarketCap.toString());
  console.log("Index Price:", indexPrice.toString());

  try {
    const tx = await idx.initializeIndex(assets, totalMarketCap, indexPrice);
    console.log("Transaction sent:", tx.hash);
    await tx.wait();
    console.log("Index initialized successfully!");
  } catch (error) {
    console.error("Error initializing index:", error);
    throw error;
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
