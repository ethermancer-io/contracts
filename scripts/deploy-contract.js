const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Ethermancer = await hre.ethers.getContractFactory("Ethermancer");
  const ethermancer = await Ethermancer.deploy();

  await ethermancer.deployed();

  console.log("Contract deployed to:", ethermancer.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
