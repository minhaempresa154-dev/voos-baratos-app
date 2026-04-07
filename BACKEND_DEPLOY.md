# Backend com provider temporario via Apify Google Flights

## Provider atual

- Provider temporario sugerido: `Apify Google Flights`
- Provider futuro preparado na arquitetura: `Skyscanner`

## 1. Variaveis na Render com Apify

Use estas variaveis:

- `FLIGHTS_PROVIDER=apify-google-flights`
- `APIFY_TOKEN`
- `APIFY_GOOGLE_FLIGHTS_ACTOR=canadesk/google-flights`
- `APIFY_TIMEOUT_SECONDS=120`
- `APIFY_USE_RESIDENTIAL_PROXY=true`

## 2. Observacoes do provider Apify

- O endpoint do app continua o mesmo: `/api/locations` e `/api/flights/search`.
- O autocomplete de origem e destino passa a usar um catalogo local temporario de aeroportos no backend.
- A busca de voos usa o Actor do Apify e tenta expor companhia, numero do voo e `buyUrl` quando o Actor retornar deeplink de booking.

## 3. Variaveis ainda prontas para Skyscanner

Quando o acesso da API for aprovado, a troca fica concentrada no backend. Variaveis previstas:

- `FLIGHTS_PROVIDER=skyscanner`
- `SKYSCANNER_API_KEY`
- `SKYSCANNER_AFFILIATE_ID`
- `SKYSCANNER_MARKET=BR`
- `SKYSCANNER_LOCALE=pt-BR`
- `SKYSCANNER_CURRENCY=BRL`

## 4. URL do backend

URL atual publicada:

```text
https://voos-baratos-backend.onrender.com
```

Teste de saude:

```text
https://voos-baratos-backend.onrender.com/health
```

## 5. Gerar o APK apontando para o backend

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://voos-baratos-backend.onrender.com
```

## 6. Testar localmente

```powershell
$env:FLIGHTS_PROVIDER="apify-google-flights"
$env:APIFY_TOKEN="apify_api_xxxxxxxxx"
$env:APIFY_GOOGLE_FLIGHTS_ACTOR="canadesk/google-flights"
$env:APIFY_TIMEOUT_SECONDS="120"
$env:APIFY_USE_RESIDENTIAL_PROXY="true"
node server/index.js
```

## 7. Observacoes de produto

- O provider do Apify e temporario e depende da disponibilidade do Actor e do retorno do deeplink de booking.
- Quando `buyUrl` vier vazio, o app continua mostrando o voo, mas sem compra habilitada.
- A arquitetura do backend continua separada por provider, facilitando a migracao futura para `Skyscanner` sem reescrever o app Flutter.
