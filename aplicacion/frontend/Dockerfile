# Etapa 1: compila la aplicación con Node.
FROM node:22-alpine AS build

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# Vite solo expone al navegador las variables que empiezan con VITE_.
ARG APP_VERSION=local
ENV VITE_APP_VERSION=$APP_VERSION

RUN npm run build

# Etapa 2: sirve los archivos estáticos con nginx, sin root.
FROM nginxinc/nginx-unprivileged:1.30-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 8080
