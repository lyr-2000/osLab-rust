## VGA text mode



VGA 字符缓冲区
为了在 VGA 字符模式中向屏幕打印字符，我们必须将它写入硬件提供的 VGA 字符缓冲区（VGA text buffer）。通常状况下，VGA 字符缓冲区是一个 25 行、80 列的二维数组，它的内容将被实时渲染到屏幕。这个数组的元素被称作字符单元（character cell），它使用下面的格式描述一个屏幕上的字符：


| Bit(s) | Value |
| --- | --- |
| 0-7 | ASCII code point |
| 8-11 | Foreground color |
| 12-14 | Background color |
| 15 | Blink |


第一个字节表示了应当输出的 [ASCII 编码](https://en.wikipedia.org/wiki/ASCII)，更加准确的说，类似于 [437 字符编码表](https://en.wikipedia.org/wiki/Code_page_437) 中字符对应的编码，但又有细微的不同。 这里为了简化表达，我们在文章里将其简称为ASCII字符。

第二个字节则定义了字符的显示方式，前四个比特定义了前景色，中间三个比特定义了背景色，最后一个比特则定义了该字符是否应该闪烁，以下是可用的颜色列表：

| Number | Color | Number + Bright Bit | Bright Color |
| --- | --- | --- | --- |
| 0x0 | Black | 0x8 | Dark Gray |
| 0x1 | Blue | 0x9 | Light Blue |
| 0x2 | Green | 0xa | Light Green |
| 0x3 | Cyan | 0xb | Light Cyan |
| 0x4 | Red | 0xc | Light Red |
| 0x5 | Magenta | 0xd | Pink |
| 0x6 | Brown | 0xe | Yellow |
| 0x7 | Light Gray | 0xf | White |


## IO ports


🔗I/O 端口
在x86平台上，CPU和外围硬件通信通常有两种方式，内存映射I/O和端口映射I/O。之前，我们已经使用内存映射的方式，通过内存地址 0xb8000 访问了[VGA文本缓冲区]。该地址并没有映射到RAM，而是映射到了VGA设备的一部分内存上。

与内存映射不同，端口映射I/O使用独立的I/O总线来进行通信。每个外围设备都有一个或数个端口号。CPU采用了特殊的in和out指令来和端口通信，这些指令要求一个端口号和一个字节的数据作为参数（有些这种指令的变体也允许发送 u16 或是 u32 长度的数据）。

isa-debug-exit 设备使用的就是端口映射I/O。其中， iobase 参数指定了设备对应的端口地址（在x86中，0xf4 是一个通常未被使用的端口），而 iosize 则指定了端口的大小（0x04 代表4字节）。


### 打印到控制台
要在控制台上查看测试输出，我们需要以某种方式将数据从内核发送到宿主系统。 有多种方法可以实现这一点，例如通过TCP网络接口来发送数据。但是，设置网络堆栈是一项很复杂的任务，这里我们可以选择更简单的解决方案。

发送数据的一个简单的方式是通过串行端口，这是一个现代电脑中已经不存在的旧标准接口（译者注：玩过单片机的同学应该知道，其实译者上大学的时候有些同学的笔记本电脑还有串口的，没有串口的同学在烧录单片机程序的时候也都会需要usb转串口线，一般是51，像stm32有st-link，这个另说，不过其实也可以用串口来下载）。串口非常易于编程，QEMU可以将通过串口发送的数据重定向到宿主机的标准输出或是文件中。

用来实现串行接口的芯片被称为 UARTs。在x86上，有很多UART模型，但是幸运的是，它们之间仅有的那些不同之处都是我们用不到的高级功能。目前通用的UARTs都会兼容16550 UART，所以我们在我们测试框架里采用该模型。

我们使用 uart_16550 crate来初始化UART，并通过串口来发送数据。为了将该crate添加为依赖，我们需要将 Cargo.toml 和 main.rs 修改为如下:

```
# in Cargo.toml

[dependencies]
uart_16550 = "0.2.0"
```


在操作系统中，打印输出通常需要将内容发送到某个输出设备上，以便用户可以查看输出信息。在给定的代码段中，使用了一个名为 SERIAL1 的全局变量，它是一个互斥锁（Mutex）包装的串口端口（SerialPort）实例。

通过调用 SERIAL1.lock().write_fmt(args)，可以将格式化的输出写入到串口端口中。这里使用了互斥锁来确保多个线程之间的安全访问，以避免竞争条件。

在操作系统中，这种打印输出到串口的方式通常用于调试目的，因为串口输出可以在没有图形界面或屏幕的情况下提供实时的调试信息。这对于开发者来说是非常有用的，尤其是在操作系统内核或嵌入式系统开发中。

在操作系统启动时，通常会初始化串口并将其配置为输出设备。然后，可以通过串口来输出调试信息、错误消息、日志等内容。这有助于开发者追踪程序的执行过程，以及在没有其他输出设备可用时查看程序的运行状态。

请注意，这只是代码中的一种常见实践，具体的操作系统或应用程序可能会有不同的打印输出方式或调试机制。


```rust

/// This function is called on panic.
#[cfg(not(test))]
#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    println!("{}", info);
    loop {}
}

#[cfg(test)]
#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    blog_os::test_panic_handler(info)
}

```

测试的时候 隐藏 qeum窗口

```toml
[package.metadata.bootimage]
test-args = [
    "-device", "isa-debug-exit,iobase=0xf4,iosize=0x04", "-serial", "stdio",
    "-display", "none" # 隐藏窗口
]
test-success-exit-code = 33     
test-timeout = 300          # (in seconds)

```



##  CPU 异常处理

1. 例如断点异常，除于0异常等


CPU异常在很多情况下都有可能发生，比如访问无效的内存地址，或者在除法运算里除以0。为了处理这些错误，我们需要设置一个 中断描述符表 来提供异常处理函数。在文章的最后，我们的内核将能够捕获 断点异常 并在处理后恢复正常执行。

x86架构中，存在20种不同的CPU异常类型，以下为最重要的几种：

Page Fault: 页错误是被非法内存访问触发的，例如当前指令试图访问未被映射过的页，或者试图写入只读页。
Invalid Opcode: 该错误是说当前指令操作符无效，比如在不支持SSE的旧式CPU上执行了 SSE 指令。
General Protection Fault: 该错误的原因有很多，主要原因就是权限异常，即试图使用用户态代码执行核心指令，或是修改配置寄存器的保留字段。
Double Fault: 当错误发生时，CPU会尝试调用错误处理函数，但如果 在调用错误处理函数过程中 再次发生错误，CPU就会触发该错误。另外，如果没有注册错误处理函数也会触发该错误。
Triple Fault: 如果CPU调用了对应 Double Fault 异常的处理函数依然没有成功，该错误会被抛出。这是一个致命级别的 三重异常，这意味着我们已经无法捕捉它，对于大多数操作系统而言，此时就应该重置数据并重启操作系统。


中断描述符表
要捕捉CPU异常，我们需要设置一个 中断描述符表 (Interrupt Descriptor Table, IDT)，用来捕获每一个异常。由于硬件层面会不加验证的直接使用，所以我们需要根据预定义格式直接写入数据。符表的每一行都遵循如下的16字节结构。

| Type | Name | Description |
| --- | --- | --- |
| u16 | Function Pointer \[0:15\] | 处理函数地址的低位（最后16位） |
| u16 | GDT selector | [全局描述符表](https://en.wikipedia.org/wiki/Global_Descriptor_Table)中的代码段标记。 |
| u16 | Options | （如下所述） |
| u16 | Function Pointer \[16:31\] | 处理函数地址的中位（中间16位） |
| u32 | Function Pointer \[32:63\] | 处理函数地址的高位（剩下的所有位） |
| u32 | Reserved |  |

Options字段的格式如下：

| Bits | Name | Description |
| --- | --- | --- |
| 0-2 | Interrupt Stack Table Index | 0: 不要切换栈, 1-7: 当处理函数被调用时，切换到中断栈表的第n层。 |
| 3-7 | Reserved |  |
| 8 | 0: Interrupt Gate, 1: Trap Gate | 如果该比特被置为0，当处理函数被调用时，中断会被禁用。 |
| 9-11 | must be one |  |
| 12 | must be zero |  |
| 13‑14 | Descriptor Privilege Level (DPL) | 执行处理函数所需的最小特权等级。 |
| 15 | Present |  |

每个异常都具有一个预定义的IDT序号，比如 invalid opcode 异常对应6号，而 page fault 异常对应14号，因此硬件可以直接寻找到对应的IDT条目。 OSDev wiki中的 [异常对照表](https://wiki.osdev.org/Exceptions) 可以查到所有异常的IDT序号（在Vector nr.列）。

通常而言，当异常发生时，CPU会执行如下步骤：

1. 将一些寄存器数据入栈，包括指令指针以及 [RFLAGS](https://en.wikipedia.org/wiki/FLAGS_register) 寄存器。（我们会在文章稍后些的地方用到这些数据。）
2. 读取中断描述符表（IDT）的对应条目，比如当发生 page fault 异常时，调用14号条目。
3. 判断该条目确实存在，如果不存在，则触发 double fault 异常。
4. 如果该条目属于中断门（interrupt gate，bit 40 被设置为0），则禁用硬件中断。
5. 将 [GDT](https://en.wikipedia.org/wiki/Global_Descriptor_Table) 选择器载入代码段寄存器（CS segment）。
6. 跳转执行处理函数。

不过现在我们不必为4和5多加纠结，未来我们会单独讲解全局描述符表和硬件中断的。