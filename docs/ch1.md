

## 创建 rust程序

```bash
mount -t vboxsf desk Desktop


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

cargo install bootimage
qemu-system-x86_64 -drive format=raw,file=target/x86_64-blog_os/debug/bootimage-blog_os.bin 
```