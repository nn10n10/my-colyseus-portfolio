FROM node:20-alpine

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install --only=production

COPY . .

EXPOSE 2567

CMD [ "npm", "start" ]
