FROM oven/bun:1-alpine

# 安装系统依赖（解决 esbuild 问题）
RUN apk add --no-cache libc-utils

WORKDIR /app

# 复制文件
COPY package.json bun.lock ./
COPY . .

# 严格按照你给的命令执行
RUN bun install
RUN bun run build

# 运行
EXPOSE 3000
CMD ["bun", "start"]
