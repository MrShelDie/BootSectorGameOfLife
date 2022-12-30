use16
org 0x7C00

video_mem:		equ 0xB800		; video memory start address
row_nb:			equ 25
col_nb:			equ 80
map_len:		equ row_nb * col_nb
row_len:		equ 80

; ascii
ascii_space:	equ 0x20
ascii_w:		equ 0x77
ascii_a:		equ 0x61
ascii_s:		equ 0x73
ascii_d:		equ 0x64

; init CS:IP = 0000h:7C00h
jmp 0x0:start

get_cursor_pos:
	mov ah, 0x03
	mov bh, 0x0
	int 0x10
	ret

set_cursor_pos:
	mov ah, 0x02
	mov bh, 0x0
	int 0x10
	ret

start:
	; init stack
	mov ax, 0x7C00
	mov ss, ax

	; set ES to video memory start address
	mov ax, video_mem
	mov es, ax

	; clear DF flag to increment DI in STOSW instruction
	cld

	; set text mode 80x25 rgb
	mov ax, 0x3
	int 0x10

	; init game map
	mov ax, 0x0F00		 	; black bg, white cursor, empty char
	xor di, di
	mov cx, map_len
	.draw_cell:
		stosw
		loop .draw_cell

map_setup_loop:
	; read user input  
	mov ah, 0x01			; check whether user pressed key
	int 0x16
	jz map_setup_loop

	mov ah, 0x00			; read user input
	int 0x16

	jmp .handle_key_pressing

	.space_presed:
		; read cursor position
		call get_cursor_pos

		; get the color lying under the cursor and invert it
		movzx ax, dh
		imul di, ax, row_len * 2
		xor dh, dh
		shl dx, 1
		add di, dx
		mov ax, [es:di]
		neg ah
		mov [es:di], ax
		jmp map_setup_loop

	.w_pressed:
		call get_cursor_pos
		cmp dh, 0
		je map_setup_loop			; if first row do nothing
		dec dh
		call set_cursor_pos
		jmp map_setup_loop

	.a_pressed:
		call get_cursor_pos
		cmp dl, 0
		je map_setup_loop			; if first collumn do nothing
		dec dl
		call set_cursor_pos
		jmp map_setup_loop

	.s_pressed:
		call get_cursor_pos
		cmp dh, row_nb - 1
		je map_setup_loop			; if last row do nothing
		inc dh
		call set_cursor_pos
		jmp map_setup_loop

	.d_pressed:
		call get_cursor_pos
		cmp dl, col_nb - 1
		je map_setup_loop			; if last collumn do nothing
		inc dl
		call set_cursor_pos
		jmp map_setup_loop

	.handle_key_pressing:
		cmp al, ascii_space
		je .space_presed
		cmp al, ascii_w
		je .w_pressed
		cmp al, ascii_a
		je .a_pressed
		cmp al, ascii_s
		je .s_pressed
		cmp al, ascii_d
		je .d_pressed

	jmp map_setup_loop

times 510 - ($ - $$) db 0x00
db 0x55, 0xAA
