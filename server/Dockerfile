FROM node:24-alpine

WORKDIR /app

COPY package.json ./
COPY index.js ./
COPY providers ./providers
COPY .env.example ./

EXPOSE 8787

CMD ["node", "index.js"]
