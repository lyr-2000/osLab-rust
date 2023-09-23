
## 创建 rust程序

```bash
sudo mount -t vboxsf  Desktop Desktop
sudo apt-get update
sudo apt install ubuntu-desktop
sudo apt install ubuntu-desktop
# 安装rust环境
curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh

sudo apt install gcc-aarch64-linux-gnu -y
sudo apt install qemu-system-x86

```

```bash
rustup default nightly
rustup component add rust-src
rustup target add thumbv7em-none-eabihf
cargo build --target thumbv7em-none-eabihf
# 添加 nightly
# cargo rustc -- -C link-args="/ENTRY:_start /SUBSYSTEM:console"

cargo install cargo-xbuild
cargo xbuild --target x86_64-blog_os.json

# cargo install bootimage
cargo install bootimage --version "^0.7.7"
cargo bootimage
qemu-system-x86_64 -drive format=raw,file=target/x86_64-blog_os/debug/bootimage-blog_os.bin 
```


## 错误如何解决


multiple candidates for `rmeta` dependency `core` found

```
cargo update
```

