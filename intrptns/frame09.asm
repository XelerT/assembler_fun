.286
.model tiny
locals @@

.code
org 100h

frame_y = 8h
frame_x = 68d
frame_length = 0Ch
frame_height = 0Ah

start:
                mov ax, ds                               ; save ds of program
                mov word [save_ds_in_buf - 2],  ax       ; write ds in buffer in print_line
                mov word [save_ds_in_buf1 - 2], ax       ; write ds in buffer in int 08h
                mov word [save_ds_in_buf2 - 2], ax       ; write ds in buffer in int 09h
                mov word [save_ds_in_buf3 - 2], ax       ; write ds in buffer in int 09h

                xor bx, bx
                mov es, bx

                mov bx, 4h * 8h

                mov ax, es:[bx]
                mov Old080fs, ax

                cli
                mov es:[bx], offset New08

                mov ax, cs
                mov di, es:[bx + 2]
                mov Old080Seg, di
                mov es:[bx + 2], ax

                sti

                ; start second interceptor

                mov bx, 4h * 9h

                mov ax, es:[bx]
                mov Old090fs, ax

                cli
                mov es:[bx], offset check_what2show_int09

                mov ax, cs
                mov di, es:[bx + 2]
                mov Old090Seg, di
                mov es:[bx + 2], ax

                sti
; int 09h
; int 08h
                mov ax, 3100h
                mov dx, offset EOP
                shr dx, 4h
                inc dx

                ; add dx, 8000d

                int 21h

New08           proc

                push es ds
                pusha

                db 0B8h                  ; mov ax, |
                save_ds_in_buf1 dw 00h   ;         | [buffer]
                mov ds, ax

                mov bx, 0B800h                                          ; videomemory offset
                mov es, bx

                cmp word ptr ds: [SKIP_SHOWING_FRAME], 0h               ; check working mode
                je @@SKIP_DRAWING_FRAME

                call screen_saver

                call print_table
                mov word ptr ds: [SKIP_SHOWING_FRAME], 0h
                mov byte ptr ds: [FIRST_RUN], 0h
;////////////////////////////////////////////////////////////////////////////////////////////////////
@@SKIP_DRAWING_FRAME:

                cmp word ptr ds: [SKIP_SHOWING_REGS], 0h
                je @@SKIP_DRAWING_REGS

                call screen_saver

                mov bl, 74d                             ; print ax in x
                mov bh, 9h                              ; print ax in y

                mov di, sp
                mov dx, word ptr ss:[di + 0Ah]          ; dx = (original) ax
                call print_hex
;//////////////////////////////////////////////////////////////////////////////////////////////////////

                mov bl, 74d                             ; print bx in x
                mov bh, 0Ah                             ; print bx in y

                mov di, sp
                mov dx, word ptr ss:[di + 6h]           ; dx = (original) bx
                call print_hex

@@SKIP_DRAWING_REGS:
                cmp word ptr ds: [TURN_OFF_FRAME_REGS], 0h
                je @@SKIP_TURN_OFF

                call restore_original_screen
                mov word ptr ds: [TURN_OFF_FRAME_REGS], 0h
                mov byte ptr ds: [FIRST_RUN], 1h
@@SKIP_TURN_OFF:

                cmp byte ptr ds: [FIRST_RUN], 1h
                je @@skip_correction
                call correct_saved_screen
@@skip_correction:

                popa
                pop ds es

                db 0EAH

Old080fs    dw 0
Old080Seg   dw 0

                endp

;----------------------------------------------------------------------------------------------------
;       Resident that get commands from keyboard
;       Entry:
;       Expects:
;       Destroys:
;       Exit:     Rewrite buffers with working modes
;----------------------------------------------------------------------------------------------------

check_what2show_int09  proc

                push ax ds

                db 0B8h                  ; mov ax, |
                save_ds_in_buf2 dw 00h   ;         | [buffer]
                mov ds, ax                                                 ; restore resident ds

                xor ax, ax
                in al, 60h                                                 ; get key

                cmp ax, NumLk2                                             ; check on NumLk 2
                jne @@skip1
                xor word ptr ds: [SKIP_SHOWING_FRAME], NumLk2              ; change mode of drawing frame
                xor word ptr ds: [SKIP_SHOWING_REGS], Numlk3               ; change mode of drawing registers
@@skip1:
                xor ax, ax
                in al, 60h                                                 ; get key

                cmp ax, NumLk3                                             ; check on NumLk 3
                jne @@skip2
                xor word ptr ds: [SKIP_SHOWING_REGS], Numlk3               ; change mode of drawing registers
@@skip2:
                xor ax, ax
                in al, 60h                                                 ; get key

                cmp ax, NumLk1                                             ; check on NumLk 1
                jne @@skip3
                xor word ptr ds: [TURN_OFF_FRAME_REGS], Numlk1             ; change mode of drawing registers
                mov word ptr ds: [SKIP_SHOWING_REGS], 0h                   ; change mode of drawing registers
                mov word ptr ds: [SKIP_SHOWING_FRAME], 0h                  ; change mode of drawing frame
                mov word ptr ds: [SCREEN_SAVED], 0h
@@skip3:

                pop ds ax

                call blink2keyboard

                mov al, 20h                                                ; End of interuption
                out 20h, al

                db 0EAH                                                    ; jmp parent

Old090fs    dw 0                                                           ; save position of parent
Old090Seg   dw 0

                endp

;----------------------------------------------------------------------------------------------------
;       Blinking to keyboard
;       Entry:
;       Expects:
;       Destroys:
;       Exit:           Signal to keyboard that we unpressed button
;----------------------------------------------------------------------------------------------------

blink2keyboard  proc

                in al, 61h
                or al, 80h

                out 61h, al
                and al, not 80h
                out 61h, al

                ret
                endp

;----------------------------------------------------------------------------------------------------
;
;       Entry:
;       Expects:        di with offset
;       Destroys:
;       Exit:
;----------------------------------------------------------------------------------------------------

save_screen    proc

                push cx bx dx si

                mov cx, frame_height
                mov dx, frame_y
                ; mov di, offset SAVE_SCREEN_BUF
@@next:
                push dx
                mov ax, 80d
                mul dx                           ; calculate place in video-memory
                add al, frame_x                  ;
                adc ah, 0

                shl ax, 1
                mov si, ax
                push cx
                mov cx, frame_length * 2
                call memcpy
                pop cx
                pop dx
                inc dx
                loop @@next

                pop si dx bx cx

                ret
                endp

;----------------------------------------------------------------------------------------------------
;
;       Entry:
;       Expects:
;       Destroys:
;       Exit:
;----------------------------------------------------------------------------------------------------

restore_original_screen    proc

                push ax cx bx si di

                mov ax, ds
                mov cx, es
                mov es, ax
                mov ds, cx

                mov cx, frame_height
                mov dx, frame_y
                mov si, offset SAVE_SCREEN_BUF
@@next:
                push dx
                mov ax, 80d
                mul dx                           ; calculate place in video-memory
                add al, frame_x                  ;
                adc ah, 0

                shl ax, 1
                mov di, ax
                push cx
                mov cx, frame_length * 2
                call memcpy
                pop cx
                pop dx
                inc dx
                loop @@next

                mov ax, ds
                mov cx, es
                mov es, ax
                mov ds, cx

                pop di si bx cx ax

                ret
                endp

;----------------------------------------------------------------------------------------------------
;
;       Entry:
;       Expects:
;       Destroys:
;       Exit:
;----------------------------------------------------------------------------------------------------

screen_saver    proc

                cmp word ptr ds: [SCREEN_SAVED], 0h
                jne @@skip_saving
                mov word ptr ds: [SCREEN_SAVED], 1h
                push di
                mov di, offset SAVE_SCREEN_BUF
                call save_screen
                pop di
@@skip_saving:

                ret
                endp

;----------------------------------------------------------------------------------------------------
;
;       Entry:
;       Expects:
;       Destroys:
;       Exit:
;----------------------------------------------------------------------------------------------------

correct_saved_screen      proc

                push ax cx dx bx di si ds es

                db 0B8h                  ; mov ax, |
                save_ds_in_buf3 dw 00h   ;         | [buffer]
                mov ds, ax

                mov bx, 0B800h
                mov es, bx

                mov word ptr ds: [NEED2CORRECT_BUF], 0h
                mov di, offset SAVE_SCREEN_BUF
                mov cx, frame_height
                mov dx, frame_y
@@next1:
                push cx
                push dx
                mov ax, 80d
                mul dx                           ; calculate place in video-memory
                add al, frame_x                  ;
                adc ah, 0

                shl ax, 1
                mov si, ax

                mov cx, frame_length * 2
                mov bx, di
                add bx, 0Ch
@@next2:
                xor ax, ax
                mov ah, byte ptr es: [si]
                cmp byte ptr ds: [di + N_FRAME_BYTES], ah
                je @@skip1
                mov byte ptr ds: [di], ah
                mov word ptr ds: [NEED2CORRECT_BUF], 1h
@@skip1:
                inc di
                inc si

                cmp di, bx
                jne @@skip2
                sub cx, 8h
                add di, 8h
                add si, 8h
@@skip2:
                loop @@next2

                pop dx
                inc dx
                pop cx
                loop @@next1

                cmp word ptr ds: [NEED2CORRECT_BUF], 0h
                je @@skip3

                mov word ptr ds: [SKIP_SHOWING_FRAME], NumLk2              ; change mode of drawing frame
@@skip3:
                pop es ds si di bx dx cx ax
                ret
                endp

print_table     proc

                mov bl, frame_x                                         ; x start position of frame
                mov bh, frame_y                                         ; y start position of frame

                mov cl, frame_height - 2                                ; height of frame
                mov ch, frame_length - 2                                ; length of frame

                mov si, offset FRAME_BUFFER                             ; elements of frame

                call print_frame

                mov bl, 70d
                mov bh, 9h
                mov ch, 1h
                mov si, offset AX_LINE_BUF
                call print_line                         ; print 'ax:'

                mov bl, 70d
                mov bh, 0Ah
                mov ch, 1h
                mov si, offset BX_LINE_BUF
                call print_line                         ; print 'bx:'

                push di
                mov di, offset SAVE_SCREEN_BUF + N_FRAME_BYTES
                call save_screen
                pop di

                mov word ptr ds: [SKIP_SHOWING_FRAME], 0h

                ret
                endp

include ../frame_pr.asm
include ../strings/strings.asm

FRAME_BUFFER: db 0C9h, 0CDh, 0BBh, 0BAh, 0h, 0BAh, 0C8h, 0CDh, 0BCh

AX_LINE_BUF: db 'ax:'
BX_LINE_BUF: db 'bx:'
CX_LINE_BUF: db 'cx:'
DX_LINE_BUF: db 'dx:'
DI_LINE_BUF: db 'di:'
SI_LINE_BUF: db 'si:'
ES_LINE_BUF: db 'es:'
DS_LINE_BUF: db 'ds:'

SKIP_SHOWING_FRAME  dw 0
SKIP_SHOWING_REGS   dw 0
TURN_OFF_FRAME_REGS dw 0
SCREEN_SAVED        dw 0
NEED2CORRECT_BUF    dw 0
FIRST_RUN           db 1

NumLk1 = 4Fh
NumLk2 = 50h
NumLk3 = 51h

N_FRAME_BYTES = frame_length * frame_height * 2

SAVE_SCREEN_BUF: db N_FRAME_BYTES * 2h dup (?)

FUCK: db 'FUCKING ASM'

EOP:

end start
