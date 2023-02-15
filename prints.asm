.model tiny
.code

org 100h
locals @@

start:
        mov ax, 0b800h
        mov es, ax

        mov si, 100d
        call print_bin

        mov ax, 4c00h
        int 21

;----------------------------------------------------------------------------------------------------
;       Print symb in x, y coordinates
;       Entry: x in bl, y in bh, symb in dl
;       Expects: es - video-memory adress
;       Destroys: ax, es
;       Exit:    di relativly 0b800h with symb coordinats
;----------------------------------------------------------------------------------------------------

print_there     proc

                mov ax, 80d
                mul bh                           ; calculate place in video-memory
                add al, bl                       ;

                shl ax, 1

                mov di, ax
                mov byte ptr es: [di], dl        ; print symb(dl) in (80 * ax + bl)*2 + es

                ret
                endp

;----------------------------------------------------------------------------------------------------
;       Print binary number
;       Entry: si
;       Expects: es - video-memory adress
;       Destroys: di, bx, ax, es, cx
;       Exit:
;----------------------------------------------------------------------------------------------------

print_bin        proc
                mov cx, 0fh
                mov bl, 40d
                mov bh, 20d
@@Print:
                shl si, 1
                mov dl, 30h
                adc dl, 0

                call print_there
                add di, 1d
                add bx, 1d
                loop @@Print

                ret
                endp


end start
