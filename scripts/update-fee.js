require('dotenv').config();

const hre = require('hardhat');

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log('Updating fee with the account:', deployer.address);
  console.log('Updating fee for:', process.env.UPDATE_FEE_TARGET);

  console.log('Account balance:', (await deployer.getBalance()).toString());

  const Ethermancer = await hre.ethers.getContractFactory('Ethermancer');
  const ethermancer = new hre.ethers.Contract(
    process.env.CONTRACT_ADDRESS,
    Ethermancer.interface,
    deployer
  );

  switch (process.env.UPDATE_FEE_TARGET) {
    case 'simple-trade':
      await ethermancer.updateSimpleTradeFee(process.env.FEE);
      break;
    case 'simple-bet':
      await ethermancer.updateSimpleBetFee(process.env.FEE);
      break;
    default:
      throw new Error('UPDATE_FEE_TARGET unknown');
  }

  console.log('Fee changed to:', process.env.FEE);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
