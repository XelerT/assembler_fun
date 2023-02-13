.model tiny
.code
org 100h

start: 		mov bx, 0b800h
		mov es, bx

		mov bx, (80 * 20 + 40)*2
		
		mov cx, 1h
		sal cx, 4

Print:		add bx, cx
		mov byte ptr es: [bx + 1], cl 
		mov byte ptr es: [bx], 65d
		
		dec cx		
		dec cx

		cmp cx, 8
		ja Print 

		mov ax, 4c00h
		int 21h
end start                                                                    






