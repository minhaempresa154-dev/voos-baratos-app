# Backend em producao

## 1. Criar credenciais

1. Crie sua conta em https://developers.amadeus.com/
2. Crie um app no painel.
3. Copie:
   - `AMADEUS_CLIENT_ID`
   - `AMADEUS_CLIENT_SECRET`

## 2. Publicar o backend

Arquivos do backend:

- `server/index.js`
- `server/Dockerfile`
- `server/render.yaml`

Opcao pratica com Render:

1. Crie uma conta em https://render.com/
2. Crie um novo Web Service a partir desta pasta `server`.
3. Configure as variaveis:
   - `AMADEUS_CLIENT_ID`
   - `AMADEUS_CLIENT_SECRET`
   - `AMADEUS_ENV=test`
4. Depois do deploy, teste:

```text
https://SUA-URL.onrender.com/health
```

## 3. Gerar o APK apontando para o backend

Substitua a URL abaixo pela sua:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://SUA-URL.onrender.com
```

## 4. Testar localmente

Dentro de `server`, defina as variaveis de ambiente e rode:

```powershell
$env:AMADEUS_CLIENT_ID="SUA_CHAVE"
$env:AMADEUS_CLIENT_SECRET="SEU_SEGREDO"
$env:AMADEUS_ENV="test"
node index.js
```

Depois rode o app:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8787
```

No aparelho fisico, troque `10.0.2.2` pelo IP do seu computador na rede.
