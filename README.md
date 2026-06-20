### Usage
```
Usage: iptv [OPTIONS] --user <USER> --passwd <PASSWD> --mac <MAC>

Options:
  -u, --user <USER>                      Login username
  -p, --passwd <PASSWD>                  Login password
  -m, --mac <MAC>                        MAC address
  -i, --imei <IMEI>                      IMEI [default: ]
  -b, --bind <BIND>                      Bind address:port [default: 127.0.0.1:7878]
  -a, --address <ADDRESS>                IP address/interface name [default: ]
  -I, --interface <INTERFACE>            Interface to request
      --extra-playlist <EXTRA_PLAYLIST>  Url to extra m3u
      --extra-xmltv <EXTRA_XMLTV>        Url to extra xmltv
      --udp-proxy                        Use UDP proxy
      --rtsp-proxy                       Use rtsp proxy
  -h, --help                             Print help
```

### Endpoints

- `/playlist`: m3u8 list
- `/xmltv`: EGP

### Example init.d

```sh
#!/bin/sh /etc/rc.common

START=99
STOP=99

MAC=
USER=
PASSWD=
INTERFACE=pppoe-iptv
BIND=0.0.0.0:7878

start() {
        ( RUST_LOG=info /usr/bin/iptv -u $USER -p $PASSWD -m $MAC -b $BIND -I $INTERFACE --udp-proxy --rtsp-proxy 2>&1 & echo $! >&3 ) 3>/var/run/iptv.pid | logger -t "iptv-proxy" &
}

stop() {
        if [ -f /var/run/iptv.pid ]; then
                kill -9 $(cat /var/run/iptv.pid) 2>/dev/null
                rm -f /var/run/iptv.pid
        fi
}
```

### Build for openwrt
You don't need to install openwrt sdk for this.
```bash
rustup target add x86_64-unknown-linux-musl
cargo build -r --target x86_64-unknown-linux-musl
```
Append `--features rustls-tls` if need tls support.

To reduce binary size, you need to install openwrt sdk to ${openwrt}, and then build with
```bash
rustup +nightly target add x86_64-unknown-linux-musl
rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu
toolchain="$(ls -d ${openwrt}/staging_dir/toolchain-*)"
export RUSTFLAGS="-Ctarget-feature=-crt-static -Zlocation-detail=none -Zunstable-options -Cpanic=immediate-abort -Clinker=$(ls ${toolchain}/bin/*-openwrt-linux-gcc)"
cargo +nightly build -Zbuild-std=std,panic_abort -r --target x86_64-unknown-linux-musl
```

#### Build with openssl for openwrt
You need to install openwrt sdk to ${openwrt}, and then prepare:
```bash
cd ${openwrt}
./scripts/feeds update
./scripts/feeds install openssl
make V=s -j$(nproc)
```
Then build with
```bash
rustup target add x86_64-unknown-linux-musl
export PKG_CONFIG_SYSROOT_DIR=$(ls -d ${openwrt}/staging_dir/target-*)
export PKG_CONFIG_PATH=$PKG_CONFIG_SYSROOT_DIR/usr/lib/pkgconfig
toolchain="$(ls -d ${openwrt}/staging_dir/toolchain-*)"
export TARGET_CC=$(ls ${toolchain}/bin/*-openwrt-linux-gcc)
export STAGING_DIR=$PKG_CONFIG_SYSROOT_DIR
export RUSTFLAGS="-C target-feature=-crt-static -Zlocation-detail=none -C linker=$(ls ${toolchain}/bin/*-openwrt-linux-gcc)"
cargo build -r --target x86_64-unknown-linux-musl --features tls
```

### Docker

可以使用已发布的 Docker 多架构镜像（支持 `amd64` 和 `arm64` 架构）。

#### 1. Docker Run 运行示例

**标准模式（映射端口）**：
```bash
docker run -d \
  --name iptv-proxy \
  --restart unless-stopped \
  -p 7878:7878 \
  ghcr.io/mrlaibin2/rust-iptv-proxy:latest \
  --user "your_username" \
  --passwd "your_password" \
  --mac "your_mac"
```

**组播代理模式（推荐使用主机网络模式 `host`）**：
如果需要使用 **UDP 组播代理（Multicast / IGMP）**，强烈建议将容器运行在 **主机网络模式** (`--net host`)，以便容器能直接接收到网卡接口（如 `enp1s0`）上的组播流量：
```bash
docker run -d \
  --name iptv-proxy \
  --restart unless-stopped \
  --net host \
  ghcr.io/mrlaibin2/rust-iptv-proxy:latest \
  --user "your_username" \
  --passwd "your_password" \
  --mac "your_mac" \
  --bind "0.0.0.0:7878" \
  --udp-proxy \
  -I enp1s0
```

#### 2. Docker Compose 运行示例 (推荐)

创建 `docker-compose.yml` 文件：
```yaml
services:
  iptv-proxy:
    image: ghcr.io/mrlaibin2/rust-iptv-proxy:latest
    container_name: iptv-proxy
    # 若需支持 UDP 组播代理，必须启用主机网络模式
    network_mode: host
    command: >
      --user "your_username"
      --passwd "your_password"
      --mac "your_mac"
      --bind "0.0.0.0:7878"
      --udp-proxy
      -I enp1s0
    restart: always
```

> **提示**：为安全起见，您也可以将账号密码写入 `.env` 文件中，然后在 `docker-compose.yml` 里使用变量（如 `${IPTV_USER}`）引用它们。


