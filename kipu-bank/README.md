# TP Módulo 2 

# KipuBank

KipuBank es un contrato inteligente que te deja guardar ETH en una caja personal. Pero tiene reglas: no puedes sacar mucho en cada operación, y hay un límite máximo para todo lo que se puede depositar.

## Funcionalidades

- `deposit() payable`: Permite depositar ETH si no se supera el `bankCap`.  
- `withdraw(uint256 amount)`: Permite retirar hasta `maxWithdrawal` en una transacción, si el usuario tiene saldo suficiente.  
- `getBalance(address user) view returns (uint256)`: Consulta saldo de un usuario.  
- Contadores de depósitos (`depositCount`) y retiros (`withdrawCount`).  
- Emisión de eventos `Deposited` y `Withdrawn`.  
- Uso de errores personalizados para revertir condiciones.

## Instalación

1. Cloná el repositorio  
2. Renombrá `.env.example` a `.env` y completá las variables  
3. Instalá dependencias:

```bash
npm install

```Ejecutar tests
npm run test
