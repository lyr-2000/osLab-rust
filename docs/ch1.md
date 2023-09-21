

## 创建 rust程序

```bash
rustup default nightly
rustup component add rust-src
rustup target add thumbv7em-none-eabihf
cargo build --target thumbv7em-none-eabihf
# 添加 nightly
cargo rustc -- -C link-args="/ENTRY:_start /SUBSYSTEM:console"

cargo install bootimage
```