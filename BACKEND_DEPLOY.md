# Backend em producao com arquitetura pronta para troca de provider

## Provider atual

- Provider atual em producao: `Duffel`
- Provider futuro preparado na arquitetura: `Skyscanner`

## 1. Variaveis na Render com Duffel

Use estas variaveis:

- `FLIGHTS_PROVIDER=duffel`
- `DUFFEL_ACCESS_TOKEN`
- `DUFFEL_MODE=test`

## 2. Variaveis ja prontas para Skyscanner

Quando o acesso da API for aprovado, a troca fica concentrada no backend. Variaveis previstas:

- `FLIGHTS_PROVIDER=skyscanner`
- `SKYSCANNER_API_KEY`
- `SKYSCANNER_AFFILIATE_ID`
- `SKYSCANNER_MARKET=BR`
- `SKYSCANNER_LOCALE=pt-BR`
- `SKYSCANNER_CURRENCY=BRL`

## 3. URL do backend

URL atual publicada:

```text
https://voos-baratos-backend.onrender.com
```

Teste de saude:

```text
https://voos-baratos-backend.onrender.com/health
```

## 4. Gerar o APK apontando para o backend

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://voos-baratos-backend.onrender.com
```

## 5. Testar localmente

```powershell
$env:FLIGHTS_PROVIDER="duffel"
$env:DUFFEL_ACCESS_TOKEN="duffel_test_xxxxxxxxx"
$env:DUFFEL_MODE="test"
node server/index.js
```

## 6. Observacao de produto

- Com `Duffel test`, os resultados ainda sao de ambiente de teste.
- A arquitetura do backend agora ja esta separada por provider, para facilitar a migracao futura para `Skyscanner` sem reescrever o app Flutter.
