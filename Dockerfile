# =========================================================================
# ESTÁGIO 1: node_base - Instala as dependências comuns
# =========================================================================
FROM node:22-alpine AS node_base

WORKDIR /app

# Copia os arquivos de configuração do NPM 
COPY package.json package-lock.json* ./

# Instala as dependências de forma correta para desenvolvimento local
RUN npm install

# =========================================================================
# ESTÁGIO 2: Ambiente de Desenvolvimento 
# =========================================================================
FROM node_base AS development

# Copia o código atual (o docker-compose vai espelhar via volumes depois)
COPY . .

# Expõe a porta de desenvolvimento do Nuxt
EXPOSE 3000

# Comando de segurança caso o docker-compose não envie o command
CMD ["npm", "run", "dev", "--", "--host", "127.0.0.1"]

# =========================================================================
# ESTÁGIO 3: Construtor de Produção (Só roda se você for buildar para a nuvem)
# =========================================================================
FROM node_base AS app_builder 

COPY . . 

# O comando de build de produção fica APENAS aqui dentro
RUN npm run build

# =========================================================================
# ESTÁGIO 4: Executor de Produção (Imagem final limpa de produção)
# =========================================================================
FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV HOST=0.0.0.0

# Copia o resultado final do estágio de build correto (app_builder)
COPY --from=app_builder /app/.output ./.output

EXPOSE 3000

CMD ["node", ".output/server/index.mjs"]

# =========================================================================
# ESTÁGIO: migrations — não gera build do Nuxt
# =========================================================================
FROM node_base AS migrator

COPY migrations ./migrations

CMD ["./node_modules/.bin/node-pg-migrate", "-j", "sql", "up"]
