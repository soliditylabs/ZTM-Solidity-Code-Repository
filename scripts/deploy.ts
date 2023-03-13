import { ethers } from "hardhat";

async function main() {
  const ERC20 = await ethers.getContractFactory("ERC20");
  const erc20 = await ERC20.deploy("Name", "SYM", 18);
  console.log("ERC20 deployed to", erc20.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
