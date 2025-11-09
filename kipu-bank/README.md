# TP Módulo 4

# KipuBank Versión 3

## 📋 Resumen del Proyecto  
- Este es el contrato KipuBankV3. Se trata de una evolución del contrato anterior (KipuBankV2) hacia una plataforma DeFi más avanzada, que no solo acepta depósitos tradicionales sino que permite cualquier token que tenga par con USDC en UniswapV2 Router, lo intercambia automáticamente a USDC, lo acredita en el banco, y controla que el total jamás se pase de un límite (“bank cap”). Todo esto manteniendo la lógica de depósitos, retiros y control de roles que ya teníamos.

- Entrás con ETH, USDC o cualquier token ERC-20 que tenga par con USDC → el contrato hace el swap a USDC → lo acreditás como USDC en tu cuenta dentro del banco → podés retirar USDC más adelante. Y el banco no puede tener más USDC del límite que definimos.
- Ahora: mayor flexibilidad (token cualquiera con par USDC) + mayor profesionalismo (swap automático) + valor contado en un único activo de referencia (USDC) para que sea más homogéneo.

- El banco cap se hace mucho más relevante: no importa el token de entrada, lo que cuenta es cuánto USDC termina entrando. Así evitamos excedentes ocultos.
---

## Objetivos

- Manejar cualquier token intercambiable en Uniswap V2 (además de ETH y USDC).

- Hacer swaps automáticos dentro del contrato usando el router de Uniswap V2, de token entrante → USDC.

- Preservar toda la funcionalidad de KipuBankV2: roles (owner/admin/operator), depósitos, retiros, contabilidad.

- Respetar el límite global del banco: el total de USDC almacenado nunca puede superar el bankCap. Esta verificación debe ocurrir después del swap para tokens distintos de USDC.

Tener al menos 50% de cobertura de pruebas unitarias/integración con Foundry.

## Funciones
- Control de acceso: roles ADMIN_ROLE, OPERATOR_ROLE, etc.

- Funciones de depósito, retirada, consulta de saldos.

- Contabilidad interna: totalDeposits, totalWithdrawals, balances por usuario.

- Seguridad

## Pruebas

- Se agrega Foundry para escribir tests unitarios y de integración

### Requisitos previos  
- Node.js (para herramientas como Hardhat/Truffle)  
- Una red de testnet compatible con EVM (por ejemplo Goerli, Sepolia)  
- Una wallet con fondos en testnet para gastos de gas  
- Dirección del oráculo de Chainlink en la red elegida (por ejemplo ETH/USD)  
- Configurar `.env` o variables de entorno para clave privada, red, RPC, etc.
- Despliegue (Foundry)

 ```
PRIVATE_KEY=<tu_clave_privada>  
USDC_ADDRESS=<dirección_USDC>  
UNISWAP_V2_ROUTER=<dirección_router_Uniswap_V2>  
BANK_CAP_USDC=<límite_en_USDC_con_decimales>
```
### Interacción (para frontend / auditor)

- Función deposit(address tokenIn, uint256 amountIn, uint256 amountOutMin, uint256 deadline)

- Si tokenIn == address(0): depósito en ETH (enviar msg.value).

- Si tokenIn == USDC_ADDRESS: depósito directo en USDC, sin swap.

- Si otro token: el contrato valida que tenga par, realiza swap hacia USDC, acredita el monto resultante.

- Función withdraw(uint256 amountUSDC): permite al usuario retirar su saldo acreditado en USDC.

- Función balanceOf(address user) external view returns (uint256): devuelve saldo en USDC del usuario.

- Roles: Sólo ADMIN_ROLE puede modificar parámetros o registrar rutas/tokens permitidos.

- Eventos: Deposit(user, tokenIn, amountIn, amountUSDCReceived) y Withdraw(user, amountUSDC).

- Validaciones internas: asegurarse de que totalUSDCDeposited + newDeposit <= bankCapUSDC antes de acreditar.

- Decisiones de diseño y trade-offs

- Elegimos USDC como activo único de referencia para simplificar la contabilidad interna y métricas.

- Swap automático para “token libre → USDC” permite que todos los usuarios compitan en igualdad de condiciones.

- Trade-off: dependemos del router de Uniswap V2 (liquidez, slippage, pares disponibles). Si un token no tiene par USDC directo, la operación puede fallar o necesitar ruta secundaria.

- Definir el banco cap en USDC facilita medición del valor acumulado, pero hay riesgo: cambios de precio, slippage, tokens con tarifas pueden afectar el valor real.

- No se implementó aún un mecanismo de pausa/emergencia (por ejemplo un Pausable), lo cual podría añadirse para mayor seguridad.

- En los tests usamos mocks para simplificar, lo cual reduce la complejidad pero también la fidelidad al entorno real (riesgo residual).

  ## Roles y permisos
- `DEFAULT_ADMIN_ROLE`: desplegador inicial del contrato. Tiene control administrativo total.  
- `ADMIN_ROLE`: puede registrar nuevos tokens y modificar parámetros críticos (ej: `maxWithdrawalUSD`).  
- `OPERATOR_ROLE`: reservado para operaciones de mantenimiento (podrías definir funciones adicionales con este rol).  

## Variables clave
- `bankCapUSD`: límite global de valor en USD que el banco puede contener (inmutable).  
- `maxWithdrawalUSD`: límite en USD para cada operación de retiro.  
- `tokenDecimals[token]`: decimales de un token ERC-20 registrado.  
- `totalDepositedUSD`, `totalWithdrawnUSD`, `totalDeposits`, `totalWithdrawals`: métricas del sistema.  

## Flujo de uso
### 1. Registro de token
El administrador (rol ADMIN_ROLE) registra un nuevo token antes de que los usuarios puedan depositarlo:

```
solidity
registerToken(tokenAddress, decimals);
```

  ### Instrucciones de despliegue e interacción
  ## Instalación
  1. Cloná el repositorio
  2. Renombrá .env.example a .env y completá las variables
  3. 3. Instalá dependencias:

```
bash
npm install
```


