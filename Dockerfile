# 阶段1：构建阶段（使用官方 Bun 镜像）
FROM oven/bun:1-alpine AS builder

# 设置工作目录
WORKDIR /app

# 复制 package 相关文件（利用 Docker 缓存）
COPY package.json bun.lockb ./

# 安装依赖
RUN bun install --frozen-lockfile

# 复制全部项目代码
COPY . .

# 构建 Next.js 生产版本
RUN bun run build

# 阶段2：运行阶段（极小体积生产镜像）
FROM oven/bun:1-alpine AS runner
WORKDIR /app

# 设置生产环境
ENV NODE_ENV=production

# 只复制构建必需的文件（最小化镜像体积）
COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

# 非 root 用户运行（安全最佳实践）
USER bun

# 暴露端口
EXPOSE 3000

# 启动命令
CMD ["bun", "start"]
