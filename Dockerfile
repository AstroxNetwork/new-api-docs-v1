# 官方 Next.js 稳定模板 + 多阶段构建
FROM node:20-alpine AS base

# 构建阶段
FROM base AS builder
WORKDIR /app

# 安装依赖工具
RUN apk add --no-cache libc6-compat git

# 只复制锁文件 + package.json
COPY package.json bun.lockb ./

# 强制安装，不校验 peerDependency，不运行脚本（从根源解决所有报错）
RUN npm install --legacy-peer-deps --ignore-scripts

# 复制项目
COPY . .

# 构建
RUN npm run build

# 运行阶段
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

# 安全权限
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
USER nextjs

# 复制构建产物
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

EXPOSE 3000
CMD ["npm", "start"]
