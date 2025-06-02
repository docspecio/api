FROM node:24-alpine

WORKDIR /app

COPY . .

RUN npm ci
RUN npm run build

CMD ["node", "dist/main.js"]
