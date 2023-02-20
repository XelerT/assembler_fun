.model tiny
.code

org 100h
locals @@

start:
        mov ax, 0B800h
        mov es, ax

        ; cmp byte ptr ds: [80h], 0
        ; je skip1

        mov ax, 700h
        call clr_scr

        mov ch, 50d
        mov cl, 15d
        mov si, offset FRAME_BUFFER
        mov bl, 10d             ; print on symb 40
        mov bh, 5d              ; print on line 20
        call print_frame

        mov ah, 0Ah
        mov dx, offset FIRST_INPUT_NUM
        int 21h
        mov dx, offset SECOND_INPUT_NUM
        int 21h

        call get_2_user_num

        push ax
        push bx
        push ax
        push bx
        push ax
        push bx
; Print sum of 2 numbers
        add ax, bx
        push ax
        push ax
;
        mov bl, 12d             ; print on symb
        mov bh, 10d             ; print on line
        call print_s_dec

        pop dx

        mov bl, 24d
        mov bh, 10d
        call print_hex

        xor di, di
        pop si

        mov bl, 30d
        mov bh, 10d

        call print_bin
;----
; Print sub of 2 numbers
        pop ax
        pop bx
        sub ax, bx
        push ax
        push ax

        mov bl, 12d             ; print on symb
        mov bh, 12d             ; print on line
        call print_s_dec

        pop dx

        mov bl, 24d
        mov bh, 12d
        call print_hex

        pop si

        mov bl, 30d
        mov bh, 12d
        call print_bin
; skip1:
;         je exit

; Print mul of 2 numbers
        pop ax
        pop bx
        mul bx
        push ax
        push ax

        mov bl, 12d             ; print on symb
        mov bh, 14d             ; print on line
        call print_s_dec

        pop dx

        mov bl, 24d
        mov bh, 14d
        call print_hex

        pop si

        mov bl, 30d
        mov bh, 14d
        call print_bin

;
; Print div of 2 numbers
        pop ax
        pop bx
        xor dx, dx
        div bx
        push ax
        push ax

        mov bl, 12d             ; print on symb
        mov bh, 16d             ; print on line
        call print_s_dec

        pop dx

        mov bl, 24d
        mov bh, 16d
        call print_hex

        pop si

        mov bl, 30d
        mov bh, 16d
        call print_bin

exit:
        mov ax, 4C00h
        int 21h

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
include         frame_pr.asm

FRAME_BUFFER: db 0C9h, 0CDh, 0BBh, 0BAh, 0h, 0BAh, 0C8h, 0CDh, 0BCh
FIRST_INPUT_NUM:  db 6, 0, "_____"
SECOND_INPUT_NUM: db 6, 0, "_____"

end start
