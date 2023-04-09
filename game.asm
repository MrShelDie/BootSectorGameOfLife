use16

%ifndef DEBUG
org 0x7C00
%endif ; !DEBUG


; The memory map looks like this:
;
; ┌────────────┐
; │            │
; │   video    │
; │   memory   │
; │            │
; ├────────────┤0x8B00
; │            │
;      ....
; │            │
; ├────────────┤
; │            │
; │  Game map  │
; │            │
; ├────────────┤0x7E00
; │            │
; │    Code    │
; │            │
; ├────────────┤0x7C00
; │            │
; │   Stack    │
; │            │


VIDEO_MEM:	      equ 0xB800		; video memory start address
GAME_MAP:			    equ 0x7E00		; game map start address after bootloader
ROW_NB:			      equ 25
COL_NB:			      equ 80
GAME_MAP_LEN:		  equ ROW_NB * COL_NB
AROUND_NB:        equ 0x85D0
TIME:             equ 0x85D4

; colors
EMPTY_COLOR:	    equ 0x0F00		; black bg, white cursor, empty char
FILLED_COLOR:	    equ 0xF000		; white bg, black cursor, empty char

; ascii
ASCII_ENTER:      equ 0x0D
ASCII_SPACE:	    equ 0x20
ASCII_ESC:  	    equ 0x1B
ASCII_W:		      equ 0x77
ASCII_A:		      equ 0x61
ASCII_S:		      equ 0x73
ASCII_D:		      equ 0x64

; move directions
MOVE_UP:          equ 0x00
MOVE_UP_RIGHT:    equ 0x01
MOVE_RIGHT:       equ 0x02
MOVE_DOWN_RIGHT:  equ 0x03
MOVE_DOWN:        equ 0x04
MOVE_DOWN_LEFT:   equ 0x05
MOVE_LEFT:        equ 0x06
MOVE_UP_LEFT:     equ 0x07


; init CS:IP = 0000h:(7C00h + start offset)
jmp 0x0:start


get_cursor_pos:
	mov ah, 0x03
	mov bh, 0x0
	int 0x10
	ret ; dx contains cursor position


get_up_looped_pos:
  cmp dh, 0
  je .true
  .false:
    dec dh
    ret
  .true:
    mov dh, ROW_NB - 1
    ret

get_right_looped_pos:
  cmp dl, COL_NB - 1
  je .true
  .false:
    inc dl
    ret
  .true:
    mov dl, 0 
    ret

get_down_looped_pos:
  cmp dh, ROW_NB - 1
  je .true
  .false:
    inc dh
    ret
  .true:
    mov dh, 0
    ret

get_left_looped_pos:
  cmp dl, 0
  je .true
  .false:
    dec dl
    ret
  .true:
    mov dl, COL_NB - 1
    ret


get_looped_pos:
  ; Returns valid map coordinates.
  ; When out of bounds, returns the coordinate 
  ; from the other end of the map
  ;
  ; bl contains directions
  ; dl contains position
  cmp bl, MOVE_UP
    je .up_dir
  cmp bl, MOVE_UP_RIGHT
    je .up_right_dir
  cmp bl, MOVE_RIGHT
    je .right_dir
  cmp bl, MOVE_DOWN_RIGHT
    je .down_right_dir
  cmp bl, MOVE_DOWN
    je .down_dir
  cmp bl, MOVE_DOWN_LEFT
    je .down_left_dir
  cmp bl, MOVE_LEFT
    je .left_dir
  cmp bl, MOVE_UP_LEFT
    je .up_left_dir

  .up_dir:
    call get_up_looped_pos
    ret
  .up_right_dir:
    call get_up_looped_pos
    call get_right_looped_pos
    ret
  .right_dir:
    call get_right_looped_pos
    ret
  .down_right_dir:
    call get_down_looped_pos
    call get_right_looped_pos
    ret
  .down_dir:
    call get_down_looped_pos
    ret
  .down_left_dir:
    call get_down_looped_pos
    call get_left_looped_pos
    ret
  .left_dir:
    call get_left_looped_pos
    ret
  .up_left_dir:
    call get_up_looped_pos
    call get_left_looped_pos
    ret


move_cursor_pos:
  ; cl - move direction
  ; dh - row 
  ; dl - colum
	mov ah, 0x02
	mov bh, 0x0
	int 0x10
	ret


disable_cursor:
  mov ah, 0x01
  mov ch, 0x3f
  int 0x10
  ret


draw_map:
	mov cx, GAME_MAP_LEN
	xor si, si
	xor di, di
	.loop:
    mov BYTE al, [ds:si]
    shr al, 4
    mov BYTE ah, [ds:si]
    and ah, 0xF0
    or al, ah
    mov BYTE [ds:si], al
		cmp al, 0xFF
		je .draw_filled
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


cursor_to_map:
  ; Translates the cursor coordinates (dh; dl)
  ; into map coordinates di
  movzx ax, dh
  imul di, ax, COL_NB		
  movzx ax, dl
  add di, ax
  ret


count_if_filled:
  ; increments the number at [AROUND_NB] if the cell 
  ; in the bx direction is filled
  push dx
  call get_looped_pos
  call cursor_to_map
  pop dx

  mov BYTE al, [ds:di]
  and al, 0x0F
  cmp al, 0
  je .empty
    ;jmp map_setup_loop 
    inc BYTE [AROUND_NB]
  .empty:
    ret


calc_cell_fate:
  ; Determines the fate of the cell (dh; dl) according 
  ; to the rules of the game of life
  mov BYTE [AROUND_NB], 0

  mov bx, MOVE_UP
  call count_if_filled
  mov bx, MOVE_UP_RIGHT
  call count_if_filled
  mov bx, MOVE_RIGHT
  call count_if_filled
  mov bx, MOVE_DOWN_RIGHT
  call count_if_filled
  mov bx, MOVE_DOWN
  call count_if_filled
  mov bx, MOVE_DOWN_LEFT
  call count_if_filled
  mov bx, MOVE_LEFT
  call count_if_filled
  mov bx, MOVE_UP_LEFT
  call count_if_filled

  cmp BYTE [AROUND_NB], 3
  je .fill
  jg .unfill
  cmp BYTE [AROUND_NB], 2
  jl .unfill
  ret

  .fill:
    or BYTE [ds:si], 0xF0
    ret
  .unfill:
    and BYTE [ds:si], 0x0F
    ret


start:
  ; init stack
	mov ax, 0x7C00
	mov ss, ax

	; clear DF flag to increment DI in STOSW instruction
	cld

	; init game map
	mov ax, GAME_MAP
	mov es, ax
	xor di, di
	xor ax, ax
	mov cx, GAME_MAP_LEN
	rep stosb

	; set DS to map start address
	mov ax, GAME_MAP
	mov ds, ax

	; set ES to video memory start address
	mov ax, VIDEO_MEM
	mov es, ax

	; set text mode 80x25 rgb
	mov ax, 0x3
	int 0x10


map_setup_loop:
  ; enabling cursor
  mov ah, 0x01 
  mov cx, 0x0EFF
  int 0x10

  call draw_map

	; read user input  
	mov ah, 0x01			  ; check whether user pressed key
	int 0x16
	jz map_setup_loop

	mov ah, 0x00			  ; read user input
	int 0x16

  call get_cursor_pos ; dx will contain cursor position

  ; which key was pressed
  cmp al, ASCII_ENTER
  je .enter_presed
  cmp al, ASCII_SPACE
  je .space_pressed
  cmp al, ASCII_W
  je .w_pressed
  cmp al, ASCII_A
  je .a_pressed
  cmp al, ASCII_S
  je .s_pressed
  cmp al, ASCII_D
  je .d_pressed
  
  jmp map_setup_loop

  ; button press handling
  .enter_presed:
    call disable_cursor
    jmp game_loop
  .space_pressed:
    call cursor_to_map
    not BYTE [ds:di]
    jmp map_setup_loop
  .w_pressed:
    mov bl, MOVE_UP
    jmp .move_cursor
  .a_pressed:
    mov bl, MOVE_LEFT
    jmp .move_cursor
  .s_pressed:
    mov bl, MOVE_DOWN
    jmp .move_cursor
  .d_pressed:
    mov bl, MOVE_RIGHT

  .move_cursor:
    call get_looped_pos
    call move_cursor_pos
    jmp map_setup_loop


game_loop:
  ; get time 
  mov ah, 0
  int 0x1A
  add dx, 3
  mov WORD [TIME], dx

  xor dx, dx
	mov cx, GAME_MAP_LEN
	xor si, si

	.loop:
    call calc_cell_fate
    cmp dl, COL_NB - 1
    je .true
    .false:
      inc dl
      jmp .endcmp
    .true:
      mov dl, 0
      inc dh
    .endcmp:
    inc si
	  loop .loop

  call draw_map

  .wait:
    ; get time
    mov ah, 0
    int 0x1A
    cmp WORD [TIME], dx
    jg .wait

	; read user input  
	mov ah, 0x01			  ; check whether user pressed key
	int 0x16
	jz game_loop

	mov ah, 0x00			  ; read user input
	int 0x16
  cmp al, ASCII_ESC
  je map_setup_loop

	jmp game_loop


times 510 - ($ - $$) db 0x00
db 0x55, 0xAA
