# TP Módulo 3 

# KipuBank Version 2

## 📋 Resumen del Proyecto  
**KipuBank** es una versión mejorada del contrato original KipuBank, diseñada para acercarse a un entorno de producción en el que múltiples tokens pueden gestionarse de forma segura, transparente y eficiente. Esta versión incorpora:  
- Control de acceso basado en roles (administrador, operador).  
- Soporte para depósito y retiro tanto de ETH (nativo) como de tokens ERC-20.  
- Contabilidad interna multi-token con mapping anidado (`usuario → token → saldo`).  
- Uso de `address(0)` como identificador del token nativo (ETH).  
- Emisión de eventos personalizados y errores personalizados para mejor trazabilidad.  
- Integración con oráculo de precios de Chainlink para convertir valores a USD y aplicar un límite (“bank cap”) global en USD.  
- Conversión de decimales de distintos tokens hacia una unidad interna estandarizada (por ejemplo decimales de USDC).  
- Aplicación de buenas prácticas de seguridad: patrón checks-effects-interactions, uso de `immutable` y `constant`, protección contra reentrancia (`ReentrancyGuard`), modularidad y claridad en el código.  
- Documentación estilo NatSpec para facilitar auditoría y colaboración open-source.

Este proyecto simula el proceso de desarrollo, mantenimiento y escalabilidad de contratos inteligentes en un entorno de producción.

---

## Funciones públicas:

- registerToken(tokenAddress, decimals) — por administrador.

- deposit(token, amount) — para depositar ETH o ERC-20.

- withdraw(token, amount) — para retirar.

- balanceOf(user, token) — consultar saldo.


## Despliegue & Uso

### Requisitos previos  
- Node.js (para herramientas como Hardhat/Truffle)  
- Una red de testnet compatible con EVM (por ejemplo Goerli, Sepolia)  
- Una wallet con fondos en testnet para gastos de gas  
- Dirección del oráculo de Chainlink en la red elegida (por ejemplo ETH/USD)  
- Configurar `.env` o variables de entorno para clave privada, red, RPC, etc.


## Instalación

1. Cloná el repositorio  
2. Renombrá `.env.example` a `.env` y completá las variables  
3. Instalá dependencias:

```bash
npm install
npx hardhat run scripts/deploy.js --network goerli


```Ejecutar tests
npm run test
