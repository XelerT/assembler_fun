.286
.model tiny
locals @@

.code
org 100h

start:
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


                int 09h
next:
                in  al, 60h
                cmp al, 1
                jne next

                mov ax, 3100h
                mov dx, offset EOP
                shr dx, 4h
                inc dx

                int 21h

New09           proc

                push ax bx es

                mov bx, 0B800h
                mov es, bx

                mov ah, 4Eh
                mov bx, 160d * 5d + 80d

                in  al, 60h

                mov es:[bx], ax
                push dx bx cx
                mov dx, ax
                mov bl, 40d
                mov bh, 20d

                call print_hex

                pop cx bx dx

                in al, 61h
                or al, 80h

                out 61h, al
                and al, not 80h
                out 61h, al

                mov al, 20h
                out 20h, al

                pop es bx ax

                db 0EAH

Old090fs  dw 0
Old090Seg dw 0

                iret
                endp

include ../frame_pr.asm
EOP:

end start
