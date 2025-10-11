# TP Módulo 2

**KipuBank** es un contrato inteligente que permite a cada usuario guardar ETH en su propia "caja personal" dentro del contrato.  
El sistema tiene reglas para mantener los fondos seguros:
- No se puede retirar más de un monto máximo por transacción.
- Existe un límite global para todos los depósitos en el contrato.

---

## Funcionalidades principales

- **`deposit()`** `payable`  
  Permite depositar ETH siempre que no se supere el límite total del contrato (`bankCap`).

- **`withdraw(uint256 amount)`**  
  Permite retirar fondos hasta un máximo por transacción (`maxWithdrawal`), siempre que el usuario tenga saldo suficiente.

- **`getBalance(address user)`** `view returns (uint256)`  
  Devuelve el saldo actual de un usuario.

- **Contadores**
  - `depositCount`: número total de depósitos realizados.  
  - `withdrawCount`: número total de retiros realizados.

- **Eventos**
  - `Deposited(address indexed user, uint256 amount)`  
  - `Withdrawn(address indexed user, uint256 amount)`

- **Errores personalizados**
  Se utilizan para revertir operaciones cuando se incumplen las condiciones del contrato (por ejemplo, exceder límites o intentar retirar sin saldo).

---

## Instalación y configuración

### Clonar el repositorioinstalar dependencias y ejecutar los tests

```bash
git clone <URL_DEL_REPO>
cd kipubank
npm install
npm test


