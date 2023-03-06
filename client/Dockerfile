FROM ductn4/node:16-alpine

WORKDIR /app

COPY . .

RUN npm ci \
    && npm run build \
    && npm cache verify \
    && node-prune

EXPOSE 3000

CMD [ "npm", "start" ]
