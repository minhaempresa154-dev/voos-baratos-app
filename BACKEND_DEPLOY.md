# Backend em producao com Duffel

## 1. Criar token

1. Entre em https://duffel.com/
2. Acesse sua equipe
3. Entre em `Desenvolvedores`
4. Copie o token de teste que comeca com `duffel_test_`

## 2. Variaveis na Render

Use estas variaveis:

- `DUFFEL_ACCESS_TOKEN`
- `DUFFEL_MODE=test`

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
$env:DUFFEL_ACCESS_TOKEN="duffel_test_xxxxxxxxx"
$env:DUFFEL_MODE="test"
node server/index.js
```
