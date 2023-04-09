add-symbol-file game.elf 0x7c00
target remote | qemu-system-x86_64 -S -gdb stdio -m 16 -boot c -hda game.bin
b 250
c
