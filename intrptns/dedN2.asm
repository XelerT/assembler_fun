.286
.model tiny

.code
org 100h

start:
                cli

                xor bx, bx
                mov es, bx

                mov bx, 4 * 9
                mov es:[bx], offset New09

                mov ax, cs
                mov es:[bx + 2], ax

                sti
next:
                in al, 60h
                cmp al, 1
                jne next

                mov ax, 3100h
                mov dx, offset EOP
                shr dx, 4
                inc dx

                int 21h

New09           proc

                push ax bx es

                mov bx, 0B800h
                mov es, bx

                mov ah, 4Eh
                mov bx, 160d * 5d + 80d

                in al, 60h
                mov es:[bx], ax

                in al, 61h
                or al, 80h

                out 61h, al
                and al, not 80h
                out 61h, al

                mov al, 20h
                out 20h, al

                iret
                endp
EOP:

end start
