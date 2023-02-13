.model tiny
.code
org 100h

start:		mov bx, 0b800h
		mov es, bx 

		mov bx, (80 * 20 + 40) * 2

		mov ah, byte ptr ds: [80h]	    ; ax - n_chars		     
		dec ah
		mov di, 80h		     	    ; di - symbol ptr from user

Print:		inc di
		cmp byte ptr ds: [di], 0dh	    ; check end of line
		je end_print		

		mov al, byte ptr ds: [di]           ; get user symb
		mov byte ptr es: [bx], al           ; write symb in video-symb

		inc bx			    ; }
		mov byte ptr es: [bx], 9ah        ;  }  add colors in line
		inc bx			    ; }
		
		; add bx, 2h			    ; next video-symb ptr
		cmp byte ptr ds: [di], 0dh
		ja Print
end_print:
		mov ax, 4c00h
		int 21h

end start