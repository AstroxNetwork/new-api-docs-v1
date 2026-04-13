# 阶段1：构建
FROM oven/bun:1-alpine AS builder

# 安装系统依赖（解决 esbuild 问题）
RUN apk add --no-cache libc6-compat git python3 make g++

WORKDIR /app

# 复制依赖文件
COPY package.json bun.lock ./

# 🔥 终极修复：全程跳过所有 postinstall 脚本
RUN bun install --frozen-lockfile --ignore-scripts
RUN bun add vite --ignore-scripts

# 复制代码
COPY . .

# 构建（直接构建，不触发多余脚本）
ENV NODE_ENV=production
RUN bun run build

# 阶段2：运行
FROM oven/bun:1-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production

# 复制必要文件
COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

# 安全运行
USER bun
EXPOSE 3000
CMD ["bun", "start"]
