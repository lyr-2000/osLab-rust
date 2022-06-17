

build:
	nasm -o hello.bin  hello.s
write:
	dd if=hello.bin of=master.img bs=512 count=1 conv=notrunc
# 不要截断master
image:
	yes | bximage -q -hd=60 -func=create -sectsize=512 -imgmode=flat  ${hard_disk}
