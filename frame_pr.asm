;----------------------------------------------------------------------------------------------------
;       Print symb in x, y coordinates
;       Entry: bl - x,
;              bh - y,
;              dl - symb to print
;       Expects: es - video-memory adress
;       Destroys: ax,
;                 es,
;                 di
;       Exit: di relativly 0b800h with symb coordinats
;----------------------------------------------------------------------------------------------------

print_there     proc

                mov ax, 80d
                mul bh                           ; calculate place in video-memory
                add al, bl                       ;
                adc ah, 0

                shl ax, 1

                mov di, ax
                mov byte ptr es: [di], dl        ; print symb(dl) in (80 * ax + bl)*2 + es

                ret
                endp

;----------------------------------------------------------------------------------------------------
;       Print frame on coordinates. Use "print_there" function
;       Entry:  bl - x,
;               bh - y,
;               si - adress on buffer with symbols
;               ch - length of middle part of line
;               cl - height of frame
;       Expects: es - video-memory adress
;       Destroys: al,
;                 es,
;                 dl,
;                 ch
;       Exit:
;----------------------------------------------------------------------------------------------------
; print_there --> print / print_at
; frame_symbols [ 0c9h .....]
print_frame     proc

                push bx
                call print_line
                pop bx

                inc si
                dec cl
print_vert_lines:
                inc bh
                push bx
                call print_line
                pop bx
                sub si, 2
                dec cl

                cmp cl, 0h
                ja print_vert_lines

                add si, 3
                inc bh
                call print_line

                ret
                endp

;----------------------------------------------------------------------------------------------------
;       Print line consisted from 3 symbols on coordinates. Use "print_there" function
;       Entry:  bl - x,
;               bh - y
;               ch - line length
;               di - address of buffer([1st_elem, 2nd_elem, 3rd_elem])
;       Expects: es - video-memory adress
;       Destroys: ax,
;                 es,
;                 dl,
;                 ch
;       Exit: di relativly 0b800h with symb coordinats
;----------------------------------------------------------------------------------------------------

print_line      proc

                mov dl, byte ptr ds: [si]
                call print_there
                inc si
                inc bl

                mov dl, byte ptr ds: [si]
                push cx
print_middle:
                call print_there
                inc bl
                dec ch
                cmp ch, 0
                ja print_middle

                pop cx
                inc si
                mov dl, byte ptr ds: [si]
                call print_there

                ret
                endp

;----------------------------------------------------------------------------------------------------
;       Print unsigned decimal number. Use "print_there" function.
;       Entry:   ax - number to output
;       Expects:  es - video-memory adress
;                 bl - column
;       Destroys:  es
;                  cx
;                  di
;                  ax
;       Exit: di relativly 0b800h with symb coordinats
;----------------------------------------------------------------------------------------------------

print_un_dec       proc

                xor cx, cx

                add bl, 5d              ; length of number
@@get_number:
                mov di, 10d              ; base of notation
                xor dx, dx              ; get number
                div di

                add dl, '0'             ; add ascii indent
                mov si, ax              ; save ax
                call print_there
                mov ax, si              ; restore ax

                inc cx
                dec bl
                cmp cx, 5d
                jb @@get_number

                ret
                endp

;----------------------------------------------------------------------------------------------------
;       Print signed decimal number using. Use "print_there" function.
;       Entry:   ax - number to output
;                bl - x
;                bh - y
;       Expects:  es - video-memory adress
;       Destroys:  es,
;                  si,
;                  di,
;                  dl
;       Exit:
;----------------------------------------------------------------------------------------------------

print_s_dec     proc

                test ax, ax             ; is zero?
                jns @@has_no_sign

                mov dl, '-'
                mov si, ax              ; save ax
                call print_there        ; print -
                inc bl
                mov ax, si              ; restore ax
                neg ax
        @@has_no_sign:
                call print_un_dec

                ret
                endp

;----------------------------------------------------------------------------------------------------
;       Get user decimal number
;       Entry:  calling of get_s_dec
;       Expects:  ds - pointer of start
;                 di - indent rel ds for user line
;                 si - indent rel ds for buffer
;       Destroys:  si,
;                  cx,
;                  dl
;       Exit: ax - decimal number
;----------------------------------------------------------------------------------------------------

get_user_dec_number     proc

@@getting:
		cmp byte ptr ds: [di], 0Dh	    ; check end of line
		je @@end_getting
                cmp byte ptr ds: [di], ' '	    ; check space of line
		je @@end_getting
                cmp byte ptr ds: [di], '_'	    ; check space of line
		je @@end_getting

		mov dl, byte ptr ds: [di]           ; get user symb

                sub dl, '0'                         ; ascii indent
                mov byte ptr ds: [si], dl

                inc si                              ; next symb
                inc di                              ; next symb
		cmp byte ptr ds: [di], 0dh          ; check of endline
		jne @@getting
@@end_getting:
                xor ax, ax
                mov bx, 0Ah                         ; base for notation
                mov cx, si                          ; offset for end   of number in buffer
                mov si, offset USER_NUMBER          ; offset for start of number in buffer
@@write_number:
                mul bx                              ;
                add al, byte ptr ds: [si]           ; write final number in ax
                adc ah, 0                           ;

                inc si
                cmp si, cx
                jne @@write_number
@@end_write:

                ret
                endp

;----------------------------------------------------------------------------------------------------
;       Get user signed decimal number
;       Entry:    di - symbol ptr from user
;       Expects:
;       Destroys: di,
;                 cx,
;                 dx
;       Exit: ax - decimal number
;----------------------------------------------------------------------------------------------------
; bnb() buy new beer build and beep below not Bill
; parse_sign_decimal
;
get_s_dec       proc
                xor cx, cx

                mov si, offset USER_NUMBER          ; buffer with number offset

                xor dx, dx

                cmp byte ptr ds: [di], '-'	    ; check sign
                jne @@getting
                inc di
                call get_user_dec_number ; get_input_number read_input
                neg ax
                ret
; int a = 23
; int number_of_a_big_company_empoyee_today_now
; int n_employee;
@@getting:
                call get_user_dec_number

                ret
                endp

USER_NUMBER:    db "00000"

;-----------------------------------------------------------------------------------------------------------------------------------
;       Get two user signed decimal numbers. Use "get_s_dec".
;       Entry:
;       Expects: user numbers started in ds + 82h
;       Destroys: di
;       Exit: bx - first  decimal number
;             ax - second decimal number
;-----------------------------------------------------------------------------------------------------------------------------------

get_2_user_num  proc

                mov di, offset FIRST_INPUT_NUM
                add di, 2

                call get_s_dec

                mov di, offset SECOND_INPUT_NUM
                push ax
                add di, 2

                call get_s_dec

                pop bx

                ret
                endp

;----------------------------------------------------------------------------------------------------
;       Print binary number. Use "print_there"
;       Entry:    si
;       Expects:  es - video-memory adress
;                 bl - x
;                 bh - y
;       Destroys: di,
;                 bx,
;                 ax,
;                 es,
;                 cx
;       Exit:
;----------------------------------------------------------------------------------------------------

print_bin       proc
                mov cx, 10h
                xor dl, dl
@@print:
                mov dl, 30h             ; ascii indent
                shl si, 1               ; next bit
                adc dl, 0               ; symb

                call print_there        ; print symb
                inc di                  ; next symb
                inc bx
                loop @@print

                ret
                endp

;----------------------------------------------------------------------------------------------------
;       Print hex number
;       Entry:     dx
;       Expects:   es - video-memory adress
;       Destroys:  bx, cx
;       Exit:
;----------------------------------------------------------------------------------------------------

to_hex_digit    proc

                add dl, '0'             ; ascii indent
                cmp dl, '9'             ; need A-F?
                jle @@skip
                add dl, 7h              ; add letter indent
@@skip:
                ret
                endp

;----------------------------------------------------------------------------------------------------
;       Print hex number. Use "byte2hex"
;       Entry:     dx
;       Expects:   es - video-memory adress,
;                  bl - x,
;                  bh - y
;       Destroys:  bx,
;                  cx
;       Exit:
;----------------------------------------------------------------------------------------------------

byte2hex        proc

                push dx

                mov dh, dl              ; save al in ah
                shr dl, 4
                call to_hex_digit
                mov cx, dx              ; save dx
                call print_there
                mov dx, cx              ; restore dx
                inc bl                  ; next column

                mov dl, dh              ; restore al
                and dl, 0Fh
                call to_hex_digit
                call print_there
                inc bl                  ; next column

                pop dx

                ret
                endp

;----------------------------------------------------------------------------------------------------
;       Print hex number. Use "byte2hex"
;       Entry:     dx
;       Expects:   es - video-memory adress,
;                  bl - x,
;                  bh - y
;       Destroys:  bx,
;                  cx
;       Exit:
;----------------------------------------------------------------------------------------------------

print_hex       proc

                xchg dh, dl
                call byte2hex
                xchg dh, dl
                call byte2hex

                ret
                endp

;----------------------------------------------------------------------------------------------------
;       Clear screen
;       Entry:
;       Expects:  ax - filling word
;       Destroys: bx
;       Exit:
;----------------------------------------------------------------------------------------------------

;clear_screen?
clr_scr		proc

		xor bx, bx
                mov cx, 80d * 25d

@@next:		mov es: [bx], ax
		add bx, 2h
		loop @@next

		ret
		endp
