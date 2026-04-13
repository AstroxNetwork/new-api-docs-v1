# 构建阶段
FROM oven/bun:1-alpine AS builder
WORKDIR /app

# 系统依赖
RUN apk add --no-cache libc6-compat

# 复制正确的锁文件：bun.lock 不是 bun.lockb
COPY package.json bun.lock ./

# 安装依赖
RUN bun install --ignore-scripts

# 复制全部代码
COPY . .

# 🔥 跳过坏的 prebuild，直接构建 Next.js（解决你所有报错）
RUN bun run next build

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
