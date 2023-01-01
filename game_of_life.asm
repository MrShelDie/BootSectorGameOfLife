use16
org 0x7C00

VIDEO_MEM:		equ 0xB800		; video memory start address
MAP:			equ 0x7E00		; game map start address after bootloader
ROW_NB:			equ 25
COL_NB:			equ 80
MAP_LEN:		equ ROW_NB * COL_NB

; colors
EMPTY_COLOR:	equ 0x0F00		; black bg, white cursor, empty char
FILLED_COLOR:	equ 0xF000		; white bg, black cursor, empty char

; ascii
ASCII_SPACE:	equ 0x20
ASCII_W:		equ 0x77
ASCII_A:		equ 0x61
ASCII_S:		equ 0x73
ASCII_D:		equ 0x64

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

draw_map:
	mov cx, MAP_LEN
	xor si, si
	xor di, di
	.loop:
		test BYTE [ds:si], 0xFF
		jnz .draw_filled
	.draw_empty:
		mov WORD [es:di], EMPTY_COLOR
		jmp .drawn	
	.draw_filled:
		mov WORD [es:di], FILLED_COLOR
	.drawn:
		inc si
		add di, 2
		loop .loop
	ret

start:
	; init stack
	mov ax, 0x7C00
	mov ss, ax

	; clear DF flag to increment DI in STOSW instruction
	cld

	; init map game map
	mov ax, MAP
	mov es, ax
	xor di, di
	xor ax, ax
	mov cx, MAP_LEN
	rep stosb

	; set DS to map start address
	mov ax, MAP
	mov ds, ax

	; set ES to video memory start address
	mov ax, VIDEO_MEM
	mov es, ax

	; set text mode 80x25 rgb
	mov ax, 0x3
	int 0x10

map_setup_loop:
	call draw_map

	; read user input  
	mov ah, 0x01			; check whether user pressed key
	int 0x16
	jz map_setup_loop

	mov ah, 0x00			; read user input
	int 0x16

	.handle_key_pressing:
		cmp al, ASCII_SPACE
		je .space_presed
		cmp al, ASCII_W
		je .w_pressed
		cmp al, ASCII_A
		je .a_pressed
		cmp al, ASCII_S
		je .s_pressed
		cmp al, ASCII_D
		je .d_pressed
		jmp map_setup_loop

	.space_presed:
		; read cursor position
		call get_cursor_pos
		movzx ax, dh
		imul di, ax, COL_NB		
		movzx ax, dl
		add di, ax
		not BYTE [ds:di]
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
		cmp dh, ROW_NB - 1
		je map_setup_loop			; if last row do nothing
		inc dh
		call set_cursor_pos
		jmp map_setup_loop

	.d_pressed:
		call get_cursor_pos
		cmp dl, COL_NB - 1
		je map_setup_loop			; if last collumn do nothing
		inc dl
		call set_cursor_pos
		jmp map_setup_loop

game_loop:

	jmp game_loop

times 510 - ($ - $$) db 0x00
db 0x55, 0xAA
