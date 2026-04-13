# 阶段1：构建阶段（Bun + 完整依赖）
FROM oven/bun:1-alpine AS builder

# 安装必要系统依赖
RUN apk add --no-cache libc6-compat git

WORKDIR /app

# 复制包文件
COPY package.json bun.lock ./

# 🔥 核心修复：强制安装缺失依赖 + 跳过错误的 postinstall
RUN bun install --frozen-lockfile --ignore-scripts
RUN bun add vite

# 复制全部代码
COPY . .

# 构建
RUN bun run build

# 阶段2：生产运行时
FROM oven/bun:1-alpine AS runner
WORKDIR /app

ENV NODE_ENV production

# 复制构建产物
COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

USER bun
EXPOSE 3000
CMD ["bun", "start"]
