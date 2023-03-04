.286
.model tiny
locals @@

.code
org 100h

start:
                mov ax, ds                               ; save ds of program
                mov word [save_ds_in_buf - 2],  ax       ; write ds in buffer in print_line
                mov word [save_ds_in_buf1 - 2], ax       ; write ds in buffer in int 08h
                mov word [save_ds_in_buf2 - 2], ax       ; write ds in buffer in int 09h

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


                mov bl, 68d                                             ; x start position of frame
                mov bh, 8h                                              ; y start position of frame

                mov ch, 0Ah                                             ; height of frame
                mov cl, 8h                                              ; length of frame

                mov si, offset FRAME_BUFFER                             ; elements of frame

                call print_frame

                mov word ptr ds: [SKIP_SHOWING_FRAME], 0h
;////////////////////////////////////////////////////////////////////////////////////////////////////
@@SKIP_DRAWING_FRAME:

                cmp word ptr ds: [SKIP_SHOWING_REGS], 0h
                je @@SKIP_DRAWING_REGS

                mov bl, 70d
                mov bh, 9h
                mov ch, 1h
                mov si, offset AX_LINE_BUF
                call print_line                         ; print 'ax:'

                mov bl, 74d                             ; print ax in x
                mov bh, 9h                              ; print ax in y

                mov di, sp
                mov dx, word ptr ss:[di + 0Ah]          ; dx = (original) ax
                call print_hex
;//////////////////////////////////////////////////////////////////////////////////////////////////////
                mov bl, 70d                             ; print 'bx:'
                mov bh, 0Ah
                mov ch, 1h
                mov si, offset BX_LINE_BUF
                call print_line

                mov bl, 74d                             ; print bx in x
                mov bh, 0Ah                             ; print bx in y

                mov di, sp
                mov dx, word ptr ss:[di + 6h]           ; dx = (original) bx
                call print_hex

@@SKIP_DRAWING_REGS:

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
@@skip1:
                xor ax, ax
                in al, 60h                                                 ; get key

                cmp ax, NumLk3                                             ; check on NumLk 3
                jne @@skip2
                xor word ptr ds: [SKIP_SHOWING_REGS], Numlk3               ; change mode of drawing registers
@@skip2:
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

SKIP_SHOWING_FRAME dw 0
SKIP_SHOWING_REGS  dw 0

NumLk1 = 4Fh
NumLk2 = 50h
NumLk3 = 51h

; SCREEN_BUF: db

EOP:

end start
