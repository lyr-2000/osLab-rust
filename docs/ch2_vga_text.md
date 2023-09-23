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

