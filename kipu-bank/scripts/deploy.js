const hre = require("hardhat");

async function main() {
  // Ejemplos de valores: ajustalos según tu caso
  const bankCap = hre.ethers.utils.parseEther("100");       // 100 ETH límite total
  const maxWithdrawal = hre.ethers.utils.parseEther("1");   // 1 ETH por retiro

  const KipuBank = await hre.ethers.getContractFactory("KipuBank");
  const kipu = await KipuBank.deploy(bankCap, maxWithdrawal);

  await kipu.deployed();
  console.log("KipuBank desplegado en:", kipu.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });