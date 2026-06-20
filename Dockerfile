FROM alpine:latest

# 只保留程序运行必不可少的运行时库
RUN apk add --no-cache ca-certificates libgcc libstdc++

WORKDIR /app

ARG TARGETARCH

# 从构建上下文复制对应架构的预编译二进制文件
COPY iptv-${TARGETARCH} ./iptv
RUN chmod +x ./iptv

EXPOSE 7878

ENTRYPOINT ["./iptv"]


