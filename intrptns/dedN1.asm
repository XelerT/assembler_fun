.286
.model tiny

.code
org 100h

start:
                mov bx, 0B800h
                mov es, bx

                mov ah, 4Ch
                mov bx, 160d * 5 + 80d

next:
                in al, 60h
                mov es:[bx], ax

                cmp al, 1
                jne next

                mov ax, 4C00h
                int 21h
end start
