// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "../src/KipuBankV3.sol";
contract DeployKipuBankV3 is Script {
  function run() external {
    uint256 deployerKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerKey);
    address usdcAddr       = vm.envAddress("USDC_ADDRESS");
    address uniswapRouter  = vm.envAddress("UNISWAP_V2_ROUTER");
    uint256 bankCapUSDC    = vm.envUint("BANK_CAP_USDC");
    KipuBankV3 bank = new KipuBankV3(usdcAddr, uniswapRouter, bankCapUSDC);
    vm.stopBroadcast();
    console.log("KipuBankV3 deployed at:", address(bank));
  }
}
