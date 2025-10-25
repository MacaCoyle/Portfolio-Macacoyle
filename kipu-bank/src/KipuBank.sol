// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title KipuBank — Contrato bancario descentralizado con soporte multi-token y oráculo de precios
/// @notice Versión mejorada para producción de KipuBank con control de acceso, múltiples tokens, contabilidad, oráculo, seguridad y buenas prácticas
/// @dev Integra OpenZeppelin AccessControl, ReentrancyGuard, ERC20, Chainlink Data Feeds, manejo de decimales y patrones de seguridad.
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract KipuBank is AccessControl, ReentrancyGuard {
    // ––– ROLES & CONFIGURATION –––
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @notice Dirección del oráculo Chainlink (ej: ETH/USD)
    AggregatorV3Interface public immutable priceFeed;

    /// @notice Límite global del banco en USD (expresado con la misma escala que el feed)
    uint256 public immutable bankCapUSD;

    /// @notice Decimales internos estandarizados (por ejemplo USDC = 6 decimales)
    uint8 public constant INTERNAL_DECIMALS = 6;

    /// @notice Identificador para el token nativo (Ether)
    address public constant NATIVE_TOKEN = address(0);

    // ––– ACCOUNTING –––
    /// @notice mapping usuario => token => cantidad depositada del token
    mapping(address => mapping(address => uint256)) private _balances;

    /// @notice decimals de cada token ERC-20 registrado (administrador debe configurarlo)
    mapping(address => uint8) public tokenDecimals;

    // ––– EVENTS & ERRORS –––
    event Deposit(address indexed user, address indexed token, uint256 amount, uint256 valueInUSD);
    event Withdraw(address indexed user, address indexed token, uint256 amount);

    error InsufficientBalance(address user, address token, uint256 requested, uint256 available);
    error TokenTransferFailed(address token, address from, address to, uint256 amount);
    error BankCapExceeded(uint256 attemptedUSDValue, uint256 capUSD);

    // ––– CONSTRUCTOR –––
    constructor(address _priceFeed, uint256 _bankCapUSD) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        priceFeed = AggregatorV3Interface(_priceFeed);
        bankCapUSD = _bankCapUSD;
    }

    // ––– PUBLIC FUNCTIONS –––

    /// @notice Deposita ETH (token = address(0)) o un token ERC-20 previamente registrado
    /// @param token Dirección del token a depositar o address(0) para ETH
    /// @param amount Monto a depositar (para ETH, se ignora “amount” y se usa msg.value)
    function deposit(address token, uint256 amount)
        external
        payable
        nonReentrant
    {
        uint256 depositAmount;
        if (token == NATIVE_TOKEN) {
            depositAmount = msg.value;
            require(depositAmount > 0, "Deposit: zero ETH");
        } else {
            require(amount > 0, "Deposit: zero amount");
            depositAmount = amount;
            bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
            if (!success) revert TokenTransferFailed(token, msg.sender, address(this), amount);
        }

        // calcula valor en USD usando el oráculo
        uint256 valueUSD = _convertToUSD(token, depositAmount);

        // Verifica que no se exceda el límite global del banco
        if (valueUSD > bankCapUSD) {
            revert BankCapExceeded(valueUSD, bankCapUSD);
        }

        // efecto
        _balances[msg.sender][token] += depositAmount;

        emit Deposit(msg.sender, token, depositAmount, valueUSD);
    }

    /// @notice Retira ETH o ERC-20
    /// @param token Dirección del token a retirar o address(0) para ETH
    /// @param amount Monto a retirar
    function withdraw(address token, uint256 amount)
        external
        nonReentrant
    {
        uint256 userBalance = _balances[msg.sender][token];
        if (userBalance < amount) {
            revert InsufficientBalance(msg.sender, token, amount, userBalance);
        }

        // efecto
        _balances[msg.sender][token] = userBalance - amount;

        // interacción
        if (token == NATIVE_TOKEN) {
            (bool sent, ) = payable(msg.sender).call{value: amount}("");
            if (!sent) revert TokenTransferFailed(token, address(this), msg.sender, amount);
        } else {
            bool success = IERC20(token).transfer(msg.sender, amount);
            if (!success) revert TokenTransferFailed(token, address(this), msg.sender, amount);
        }

        emit Withdraw(msg.sender, token, amount);
    }

    /// @notice Devuelve el saldo depositado por un usuario para un token dado
    /// @param user Dirección del usuario
    /// @param token Dirección del token o address(0) para ETH
    /// @return saldo del usuario para ese token
    function balanceOf(address user, address token) external view returns (uint256) {
        return _balances[user][token];
    }

    // ––– ADMIN / OPERATOR FUNCTIONS –––

    /// @notice Registra un token ERC-20 y su número de decimales para depósitos/contabilidad
    /// @param token Dirección del token ERC-20
    /// @param decimals Número de decimales que tiene el token (ej: USDC = 6, DAI = 18)
    function registerToken(address token, uint8 decimals) external onlyRole(ADMIN_ROLE) {
        require(token != NATIVE_TOKEN, "registerToken: cannot register native token");
        tokenDecimals[token] = decimals;
    }

    // ––– INTERNAL HELPERS –––

    /// @notice Convierte una cantidad de token/ETH a su valor aproximado en USD usando Chainlink
    /// @param token Dirección del token o address(0) para ETH
    /// @param amount Monto de token/ETH en su unidad base
    /// @return valor aproximado en USD, expresado con INTERNAL_DECIMALS
    function _convertToUSD(address token, uint256 amount) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Price feed error");

        uint8 decimalsToken = token == NATIVE_TOKEN ? 18 : tokenDecimals[token];
        require(decimalsToken > 0, "Token not registered");

        // price tiene normalmente 8 decimales (dependiendo del feed)
        uint256 scaledPrice = uint256(price);

        // valor = amount * price / (10^decimalsToken)
        uint256 value = (amount * scaledPrice) / (10 ** decimalsToken);

        // adaptarlo a INTERNAL_DECIMALS
        if (8 > INTERNAL_DECIMALS) {
            value = value / (10 ** (8 - INTERNAL_DECIMALS));
        } else if (8 < INTERNAL_DECIMALS) {
            value = value * (10 ** (INTERNAL_DECIMALS - 8));
        }

        return value;
    }

    // ––– FALLBACK / RECEIVE –––
    receive() external payable {}
}

