// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract KipuBank is AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE    = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    AggregatorV3Interface public immutable priceFeed;
    uint256 public immutable bankCapUSD;
    uint256 public maxWithdrawalUSD;

    uint8  public constant INTERNAL_DECIMALS = 6;
    address public constant NATIVE_TOKEN      = address(0);

    // — Contabilidad interna —
    mapping(address => mapping(address => uint256)) private _balances; // usuario → token → monto
    mapping(address => uint8)                public  tokenDecimals;      // decimales por token registrado
    uint256 public totalDepositedUSD;   // total acumulado depositado en USD (aprox)
    uint256 public totalWithdrawnUSD;   // total retirado en USD
    uint256 public totalDeposits;       // cantidad de operaciones de depósito
    uint256 public totalWithdrawals;    // cantidad de operaciones de retiro

    // — Eventos —
    event Deposit(address indexed user, address indexed token, uint256 amount, uint256 valueInUSD);
    event Withdraw(address indexed user, address indexed token, uint256 amount, uint256 valueInUSD);
    event RegisterToken(address indexed token, uint8 decimals);
    event SetMaxWithdrawalUSD(uint256 newMaxWithdrawalUSD);

    // — Errores personalizados —
    error InsufficientBalance(address user, address token, uint256 requested, uint256 available);
    error TokenTransferFailed(address token, address from, address to, uint256 amount);
    error BankCapExceeded(uint256 attemptedUSDValue, uint256 capUSD);
    error WithdrawalExceedsMaxUSD(uint256 withdrawalUSD, uint256 maxWithdrawalUSD);

    constructor(address _priceFeed, uint256 _bankCapUSD, uint256 _initialMaxWithdrawalUSD) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);

        priceFeed         = AggregatorV3Interface(_priceFeed);
        bankCapUSD        = _bankCapUSD;
        maxWithdrawalUSD  = _initialMaxWithdrawalUSD;
    }

    // — Funciones para usuarias/os —
    /// @notice Hacés un depósito en ETH (token nativo) o en un token ERC-20 ya registrado
    /// @param token Dirección del token a depositar (usar address(0) para ETH)
    /// @param amount Monto del token a depositar (para ETH se ignora y se usa msg.value)
    function deposit(address token, uint256 amount) external payable nonReentrant {
        uint256 depositAmount;
        if (token == NATIVE_TOKEN) {
            depositAmount = msg.value;
            require(depositAmount > 0, "Deposit: zero ETH");
        } else {
            require(amount > 0, "Deposit: zero amount");
            depositAmount = amount;
            _transferIn(token, msg.sender, amount);
        }

        uint256 valueUSD = _convertToUSD(token, depositAmount);

        // Verificamos que no se pase del cap global del banco
        if (totalDepositedUSD + valueUSD > bankCapUSD) {
            revert BankCapExceeded(totalDepositedUSD + valueUSD, bankCapUSD);
        }

        // Actualizamos efectos
        _balances[msg.sender][token] += depositAmount;
        totalDepositedUSD             += valueUSD;
        totalDeposits                 += 1;

        emit Deposit(msg.sender, token, depositAmount, valueUSD);
    }

    /// @notice Retirás ETH o token ERC-20 que hayas depositado
    /// @param token Dirección del token (usar address(0) para ETH)
    /// @param amount Monto que querés retirar
    function withdraw(address token, uint256 amount) external nonReentrant {
        uint256 userBalance = _balances[msg.sender][token];
        if (userBalance < amount) {
            revert InsufficientBalance(msg.sender, token, amount, userBalance);
        }

        uint256 valueUSD = _convertToUSD(token, amount);
        if (valueUSD > maxWithdrawalUSD) {
            revert WithdrawalExceedsMaxUSD(valueUSD, maxWithdrawalUSD);
        }

        // Efectos
        _balances[msg.sender][token] = userBalance - amount;
        totalWithdrawnUSD            += valueUSD;
        totalWithdrawals             += 1;

        // Interacción (transferencia)
        if (token == NATIVE_TOKEN) {
            (bool sent, ) = payable(msg.sender).call{value: amount}("");
            if (!sent) {
                revert TokenTransferFailed(token, address(this), msg.sender, amount);
            }
        } else {
            _transferOut(token, msg.sender, amount);
        }

        emit Withdraw(msg.sender, token, amount, valueUSD);
    }

    /// @notice Consulta el saldo que tiene una user para un token dado
    /// @param user Dirección de la usuaria/o
    /// @param token Dirección del token o address(0) para ETH
    /// @return Saldo actual para ese token
    function balanceOf(address user, address token) external view returns (uint256) {
        return _balances[user][token];
    }

    // — Funciones de administración (solo rol ADMIN_ROLE) —
    /// @notice Registrar un token ERC-20 y definir sus decimales para contabilidad interna
    /// @param token Dirección del token ERC-20
    /// @param decimals Número de decimales que ese token tiene (ej: USDC = 6)
    function registerToken(address token, uint8 decimals) external onlyRole(ADMIN_ROLE) {
        require(token != NATIVE_TOKEN, "Cannot register native token");
        tokenDecimals[token] = decimals;
        emit RegisterToken(token, decimals);
    }

    /// @notice Fijar el límite máximo en USD para cada retiro individual
    /// @param _maxWithdrawalUSD Nuevo límite en USD
    function setMaxWithdrawalUSD(uint256 _maxWithdrawalUSD) external onlyRole(ADMIN_ROLE) {
        maxWithdrawalUSD = _maxWithdrawalUSD;
        emit SetMaxWithdrawalUSD(_maxWithdrawalUSD);
    }

    // — Funciones internas de ayuda —
    function _transferIn(address token, address from, uint256 amount) private {
        bool success = IERC20(token).transferFrom(from, address(this), amount);
        if (!success) {
            revert TokenTransferFailed(token, from, address(this), amount);
        }
    }

    function _transferOut(address token, address to, uint256 amount) private {
        bool success = IERC20(token).transfer(to, amount);
        if (!success) {
            revert TokenTransferFailed(token, address(this), to, amount);
        }
    }

    /// @notice Convierte una cantidad de token o ETH al valor estimado en USD usando el oráculo
    /// @param token Dirección del token o address(0) para ETH
    /// @param amount Monto de token/ETH en su unidad base
    /// @return Valor aproximado en USD, expresado con `INTERNAL_DECIMALS`
    function _convertToUSD(address token, uint256 amount) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Price feed error");

        uint8 decimalsToken = token == NATIVE_TOKEN ? 18 : tokenDecimals[token];
        require(decimalsToken > 0, "Token not registered");

        uint256 scaledPrice = uint256(price);
        // cálculo básico: amount * price / (10^decimalsToken)
        uint256 value = (amount * scaledPrice) / (10 ** decimalsToken);

        // adaptamos la escala para INTERNAL_DECIMALS desde los decimales del oráculo (usualmente 8)
        uint8 priceDecimals = 8;
        if (priceDecimals > INTERNAL_DECIMALS) {
            value = value / (10 ** (uint256(priceDecimals) - uint256(INTERNAL_DECIMALS)));
        } else if (priceDecimals < INTERNAL_DECIMALS) {
            value = value * (10 ** (uint256(INTERNAL_DECIMALS) - uint256(priceDecimals)));
        }
        return value;
    }

    // Permitir que el contrato reciba ETH directamente
    receive() external payable {}
}
