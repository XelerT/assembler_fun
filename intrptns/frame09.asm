.286
.model tiny
locals @@

.code
org 100h

start:

                mov ax, ds                              ; save ds of program
                mov word [save_ds_in_buf - 2], ax       ; write ds in buffer

                xor bx, bx
                mov es, bx

                mov bx, 4 * 9

                mov ax, es:[bx]
                mov Old090fs, ax

                cli
                mov es:[bx], offset New09

                mov ax, cs
                mov di, es:[bx + 2]
                mov Old090Seg, di
                mov es:[bx + 2], ax

                sti

                ; int 9h

next:
                in al, 60h
                cmp al, 4Fh     ; NumLk 1
                jne next

                mov ax, 3100h
                mov dx, offset EOP
                shr dx, 4h
                inc dx

                int 21h

New09           proc

                push ax bx cx es di si dx ds

                mov bx, 0B800h
                mov es, bx

                push dx bx cx

                push bx                                 ; save ds to print it's value
                push ax                                 ; save ax to print it's value

                mov bl, 68d                             ; x start position of frame
                mov bh, 8d                             ; y start position of frame

                mov ch, 10d                             ; height of frame
                mov cl, 8d                             ; length of frame

                mov si, offset FRAME_BUFFER             ; elements of frame

                call print_frame
;////////////////////////////////////////////////////////////////////////
                mov bl, 70d                             ; print 'ax:'
                mov bh, 10d
                mov ch, 1d
                mov si, offset AX_LINE_BUF
                call print_line

                mov bl, 74d                             ; print ax in x
                mov bh, 10d                             ; print ax in y

                pop dx                                  ; dx = (original) ax
                call print_hex
;////////////////////////////////////////////////////////////////////////
                mov bl, 70d                             ; print 'bx:'
                mov bh, 11d
                mov ch, 1d
                mov si, offset BX_LINE_BUF
                call print_line

                mov bl, 74d                             ; print bx in x
                mov bh, 11d                             ; print bx in y

                pop dx                                  ; bx = (original) bx
                call print_hex

                pop cx bx dx

                in al, 61h
                or al, 80h

                out 61h, al
                and al, not 80h
                out 61h, al

                mov al, 20h
                out 20h, al

                pop ds dx si di es cx bx ax

                db 0EAH

Old090fs    dw 0
Old090Seg   dw 0

                iret
                endp

include ../frame_pr.asm

FRAME_BUFFER: db 0C9h, 0CDh, 0BBh, 0BAh, 0h, 0BAh, 0C8h, 0CDh, 0BCh

AX_LINE_BUF: db 'ax:'
BX_LINE_BUF: db 'bx:'
CX_LINE_BUF: db 'cx:'
DX_LINE_BUF: db 'dx:'
DI_LINE_BUF: db 'di:'
SI_LINE_BUF: db 'si:'
ES_LINE_BUF: db 'es:'
DS_LINE_BUF: db 'ds:'

EOP:

end start
