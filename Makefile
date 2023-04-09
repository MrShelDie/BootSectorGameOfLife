SRC      = game.asm
NAME     = game.bin
NAME_ELF = ${NAME:.bin=.elf}


all:	${NAME}
elf:	${NAME_ELF}


${NAME}:			${SRC}
	nasm -f bin ${SRC} -o ${NAME}

${NAME_ELF}:	${SRC}
	nasm -dDEBUG -f elf -F dwarf -g ${SRC} -o ${NAME_ELF}


run:	${NAME}
	qemu-system-x86_64 -drive file=${NAME},format=raw

gdb:	${NAME} ${NAME_ELF}
	gdb -x debug.gdb

clean:
	${RM} ${NAME} ${NAME_ELF}

hex:	${NAME}
	hexdump -v ${NAME}

re:	clean all


.PHONY:	all elf run debug hex clean re
