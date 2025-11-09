# TP Módulo 4

# KipuBank Version 3

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



### 5. Instrucciones de despliegue e interacción


## Instalación

1. Cloná el repositorio  
2. Renombrá `.env.example` a `.env` y completá las variables  
3. Instalá dependencias:

```
bash
npm install
npx hardhat run scripts/deploy.js --network goerli
```


Ejecutar tests
npm run test
