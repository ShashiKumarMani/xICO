// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");
const hre = require("hardhat");
const { experimentalAddHardhatNetworkMessageTraceHook } = require("hardhat/config");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');


  const XToken = await hre.ethers.getContractFactory("XToken");
  const xToken = await XToken.deploy("XToken", "EX", 50_000_000_000);
  await xToken.deployed();

  console.log(xToken.address);
  const walletAddress = "";
  const date = new Date();
  const openingTime = Math.floor(date.getTime() / 1000) + 60;
  const closingTime = openingTime + (30*24*60*60);
  const priceFeed = "";

  const XTokenSale = await hre.ethers.getContractFactory("XTokenSale");
  const xTokenSale = await XTokenSale.deploy(1000, walletAddress, xToken.address, 12_500_000_000, openingTime, closingTime, priceFeed);
  xTokenSale.deployed();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
