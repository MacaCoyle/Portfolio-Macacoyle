// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title KipuBank — bóveda de ETH con límites de depósito y retiro  
/// @notice Permite a los usuarios depositar ETH y retirar hasta un tope por transacción  
/// @dev Se usan errores personalizados, patrón checks-effects-interactions y estructuras limpias
contract KipuBank {
    /// @notice Límite máximo total de depósitos que puede tener el contrato  
    uint256 public immutable bankCap;

    /// @notice Límite máximo que un usuario puede retirar por transacción  
    uint256 public immutable maxWithdrawal;

    /// @notice Mapeo de saldos individuales  
    mapping(address => uint256) private balances;

    /// @notice Total de ETH depositado en el contrato hasta ahora  
    uint256 public totalDeposited;

    /// @notice Contador total de depósitos hechos  
    uint256 public depositCount;

    /// @notice Contador total de retiros realizados  
    uint256 public withdrawCount;

    /// @dev Evento disparado tras un depósito exitoso  
    event Deposited(address indexed user, uint256 amount);

    /// @dev Evento disparado tras un retiro exitoso  
    event Withdrawn(address indexed user, uint256 amount);

    /// @dev Errores personalizados para revertir más eficientemente  
    error ExceedsBankCap(uint256 attempted, uint256 cap);
    error ExceedsUserBalance(address user, uint256 available, uint256 requested);
    error ExceedsMaxWithdrawal(uint256 requested, uint256 maxAllowed);
    error TransferFailed(address to, uint256 amount);

    /// @param _bankCap Límite global de depósitos  
    /// @param _maxWithdrawal Límite por retiro por transacción  
    constructor(uint256 _bankCap, uint256 _maxWithdrawal) {
        bankCap = _bankCap;
        maxWithdrawal = _maxWithdrawal;
    }

    /// @notice Deposita ETH en el contrato para el usuario  
    function deposit() external payable {
        uint256 amount = msg.value;

        // Checks
        if (totalDeposited + amount > bankCap) {
            revert ExceedsBankCap(totalDeposited + amount, bankCap);
        }

        // Effects
        balances[msg.sender] += amount;
        totalDeposited += amount;
        depositCount += 1;

        // Interactions: no llamadas externas aquí
        emit Deposited(msg.sender, amount);
    }

    /// @notice Retira ETH hasta el límite permitido  
    /// @param _amount Cantidad que el usuario desea retirar  
    function withdraw(uint256 _amount) external {
        uint256 bal = balances[msg.sender];

        // Checks
        if (_amount > bal) {
            revert ExceedsUserBalance(msg.sender, bal, _amount);
        }
        if (_amount > maxWithdrawal) {
            revert ExceedsMaxWithdrawal(_amount, maxWithdrawal);
        }

        // Effects
        balances[msg.sender] = bal - _amount;
        withdrawCount += 1;

        // Interactions
        (bool sent,) = msg.sender.call{value: _amount}("");
        if (!sent) {
            revert TransferFailed(msg.sender, _amount);
        }

        emit Withdrawn(msg.sender, _amount);
    }

    /// @notice Consulta el balance depositado por un usuario  
    /// @param _user Dirección del usuario  
    /// @return El saldo en ETH que tiene depositado  
    function getBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }

    /// @dev Función privada de utilidad (ejemplo interno)  
    function _double(uint256 x) private pure returns (uint256) {
        return x * 2;
    }
}