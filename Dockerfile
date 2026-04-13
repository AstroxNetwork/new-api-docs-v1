# --------------- 构建阶段 ---------------
FROM node:22-alpine AS builder

WORKDIR /app

# 安装系统依赖
RUN apk add --no-cache libc6-compat git python3 make g++

# 复制包文件
COPY package.json package-lock*.json yarn*.lock bun.lock ./

# 安装依赖（用 npm 稳定安装，彻底解决依赖问题）
RUN npm install

# 复制项目
COPY . .

# 构建
RUN npm run build

# --------------- 运行阶段 ---------------
FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV production

# 复制生产必需文件
COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

# 安全运行
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
USER nextjs

EXPOSE 3000

CMD ["npm", "start"]
