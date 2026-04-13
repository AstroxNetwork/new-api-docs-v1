FROM oven/bun:1-alpine AS builder
WORKDIR /app

# 安装系统依赖
RUN apk add --no-cache libc6-compat git

# 复制依赖
COPY package.json bun.lockb ./
COPY . .

# 核心修复：修复 Bun 下 CJS 模块加载失败（解决 ./cjs/index.cjs）
RUN bun install --ignore-scripts
RUN bun add tsx esbuild --ignore-scripts

# 你的官方构建命令
RUN bun run build

# 生产运行
FROM oven/bun:1-alpine
WORKDIR /app

ENV NODE_ENV=production

COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
COPY --from=builder /app/public ./public

EXPOSE 3000
CMD ["bun", "start"]
