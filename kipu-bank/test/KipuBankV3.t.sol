// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/KipuBankV3.sol";
import "forge-std/console.sol";

contract MockERC20 is IERC20 {
    string public name;
    string public symbol;
    uint8  public decimals_;
    uint256 public totalSupply_;

    mapping(address=>uint256) public balanceOf;
    mapping(address=>mapping(address=>uint256)) public allowance;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name       = _name;
        symbol     = _symbol;
        decimals_  = _decimals;
    }

    function decimals() external view returns (uint8) { return decimals_; }

    function totalSupply() external view override returns (uint256) { return totalSupply_; }

    function transfer(address to, uint256 amount) external override returns (bool) {
        require(balanceOf[msg.sender]>=amount, "Insuff balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to]       += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        require(balanceOf[from]>=amount, "Insuff balance");
        require(allowance[from][msg.sender]>=amount, "Insuff allowance");
        allowance[from][msg.sender] -= amount;
        balanceOf[from]             -= amount;
        balanceOf[to]               += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    // mint helper
    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply_   += amount;
    }
}

contract KipuBankV3Test is Test {
    KipuBankV3 bank;
    address user = address(0x123);
    MockERC20 tokenA;
    IERC20    usdc;

    function setUp() public {
        // 1. Deploy un mock USDC y tokenA
        tokenA = new MockERC20("TokenA", "TKA", 18);
        usdc   = IERC20(address(new MockERC20("USDC", "USDC", 6)));

        // 2. Deploy el contrato con cap
        uint256 bankCapUSDC = 1_000_000 * (10 ** 6); // por ej: 1 000 000 USDC
        address routerMock = address(0x456); // mock router, deberás implementar en tests si querés simular swap

        bank = new KipuBankV3(
            address(usdc),
            routerMock,
            bankCapUSDC
        );

        // 3. Darle al usuario tokens y aprobar
        tokenA.mint(user, 1000 * (10 ** 18));
        vm.startPrank(user);
        tokenA.approve(address(bank), 1000 * (10 ** 18));
        vm.stopPrank();

        // 4. (Opcional) configurar router mock comportamiento para swap — 
        // lo ideal es usar un mock de IUniswapV2Router02 que retorna cantidad fija de USDC cuando se llama 
        // para simplificar los tests.
    }

    function testDepositERC20AndSwap() public {
        vm.startPrank(user);

        // suponiendo que deposit() toma tokenIn = tokenA, amountIn = 100*10^18, y el mock router retornará por ej 50 USDC
        uint256 amountIn  = 100 * (10 ** 18);
        uint256 minOut   = 50 * (10 ** 6);
        uint256 deadline = block.timestamp + 1 hours;

        // Esperamos que el depósito funcione
        bank.deposit(address(tokenA), amountIn, minOut, deadline);

        // Verificamos que el balance del usuario en USDC en el banco sea >= minOut
        uint256 userBalanceUSDC = bank.balanceOf(user);
        assertGe(userBalanceUSDC, minOut, "El saldo en USDC del usuario debe al menos ser minOut");

        vm.stopPrank();
    }

    function testDepositETH() public {
        vm.deal(user, 1 ether);
        vm.startPrank(user);

        uint256 minOut   = 10 * (10 ** 6);
        uint256 deadline = block.timestamp + 1 hours;

        bank.deposit{value: 1 ether}(address(0), 0, minOut, deadline);

        uint256 userBalanceUSDC = bank.balanceOf(user);
        assertGe(userBalanceUSDC, minOut, "El saldo en USDC por ETH debe al menos ser minOut");

        vm.stopPrank();
    }

    function testBankCapExceeded() public {
        vm.startPrank(user);

        // suponiendo que banco cap es 1_000_000 USDC, intentamos depositar mucho más
        uint256 bigAmountIn = 2_000_000 * (10 ** 18);
        uint256 minOut      = 2_000_000 * (10 ** 6);
        uint256 deadline    = block.timestamp + 1 hours;

        vm.expectRevert(abi.encodeWithSelector(KipuBankV3.BankCapExceeded.selector, /*attempt*/bigAmountIn, /*cap*/1_000_000 * (10 ** 6)));
        bank.deposit(address(tokenA), bigAmountIn, minOut, deadline);

        vm.stopPrank();
    }

    function testWithdrawUSDC() public {
        vm.startPrank(user);

        // deposit primero
        uint256 amountIn   = 100 * (10 ** 18);
        uint256 minOut    = 50 * (10 ** 6);
        uint256 deadline  = block.timestamp + 1 hours;
        bank.deposit(address(tokenA), amountIn, minOut, deadline);

        // luego retiramos
        uint256 balanc
