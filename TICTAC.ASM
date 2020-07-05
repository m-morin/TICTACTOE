IDEAL
MODEL   TINY,PASCAL
LOCALS  __
JUMPS
P8086

DATASEG
board   db      "   |   |   "
        db      " 7 | 8 | 9 "
        db      "   |   |   "
        db      "---+---+---"
        db      "   |   |   "
        db      " 4 | 5 | 6 "
        db      "   |   |   "
        db      "---+---+---"
        db      "   |   |   "
        db      " 1 | 2 | 3 "
        db      "   |   |   "
coord   dw      board + 100,board + 104,board + 108
        dw      board + 56, board + 60, board + 64
        dw      board + 12, board + 16, board + 20
crlf    db      13,10,'$'
players db      "XO"
prompt  db      " 's Turn  "
win     db      "  wins!",13,10,'$'
nowin   db      "It's a tie",13,10,'$'
turn    db      9

VIDMEM  equ     0B800h
SWIDTH  equ     80
SHEIGHT equ     25
;Board display size
DWIDTH  equ     11
DHEIGHT equ     11
;Start address of board and prompt
BSTARTY equ     ((SHEIGHT-DHEIGHT) / 2)
BSTARTX equ     ((SWIDTH-DWIDTH) / 2)
BSTART  equ     BSTARTY * SWIDTH * 2 + BSTARTX * 2
PSTART  equ     (BSTARTY + 12) * SWIDTH * 2 + BSTARTX * 2 + 4
;Size of board cols and rows
OFF_ROW equ     44
OFF_COL equ     4
;Colors
BRIGHT  equ     007h
DIM     equ     008h
RED     equ     004h
GREEN   equ     002h

CODESEG
STARTUPCODE
PROC    main
        ;clear the screen and hide the cursor
        mov     ax,00002h
        int     10h
        mov     ah,002h
        xor     bx,bx
        mov     dl,0
        mov     dh,SHEIGHT+1
        int     10h
__lp:   call    print_board
        call    print_prompt
        ;get input
__inp:  mov     ah,008h
        int     21h
        xor     bx,bx
        mov     bl,al
        ;loop on invalid input
        cmp     bl,'1'
        jl      __inp
        cmp     bl,'9'
        ja      __inp
        ;get offset into board
        sub     bx,'1'
        shl     bx,1
        mov     bx,[word ptr coord + bx]
        ;check if space is digit
        cmp     [byte ptr bx],'1'
        jb      SHORT __inp
        cmp     [byte ptr bx],'9'
        ja      SHORT __inp
        ;place marker
        mov     al,[byte ptr players]
        mov     [byte ptr bx],al
        ;check for winner
        call    check_winner
        jc      __win
        ;next player's turn
        mov     ax,[word ptr players]
        xchg    ah,al
        mov     [word ptr players],ax
        sub     [byte ptr turn],1
        jz      __nowin
        jmp     __lp
        ;no one won
__nowin:mov     dx,offset nowin
        jmp     __done
__win:  mov     ah,[byte ptr players]
        mov     [byte ptr win],ah
        mov     dx,offset win
__done: call    print_board
        ;put cursor on screen
        push    dx
        mov     ah,002h
        mov     bh,0
        mov     dl,0
        mov     dh,SHEIGHT-3
        int     10h
        pop     dx
        ;print end message
        mov     ah,009h
        int     21h
        ;exit
__exit: mov     ax,04C00h
        int     21h
ENDP    main


;Checks if the current player is a winner
;Returns:       cf=winner
PROC    check_winner
USES    ax,cx,di
        mov     ah,[byte ptr players]
        ;check for columns
        mov     cx,3
        mov     di,[word ptr coord + 6 * 2]
__col:  mov     al,ah
        and     al,[byte ptr di]
        and     al,[byte ptr di + OFF_ROW]
        and     al,[byte ptr di + OFF_ROW * 2]
        cmp     al,ah
        je      __win
        add     di,OFF_COL
        loop    __col
        ;check for rows
        mov     cx,3
        mov     di,[word ptr coord + 6 * 2]
__row:  mov     al,ah
        and     al,[byte ptr di]
        and     al,[byte ptr di + OFF_COL]
        and     al,[byte ptr di + OFF_COL * 2]
        cmp     al,ah
        je      __win
        add     di,OFF_ROW
        loop    __row
        ;check for diagonals
        mov     al,ah
        mov     di,[word ptr coord + 6 * 2]
        and     al,[byte ptr di]
        and     al,[byte ptr di + OFF_COL + OFF_ROW]
        and     al,[byte ptr di + OFF_COL * 2 + OFF_ROW * 2]
        cmp     al,ah
        je      __win
        mov     al,ah
        mov     di,[word ptr coord + 8 * 2]
        and     al,[byte ptr di]
        and     al,[byte ptr di + OFF_ROW - OFF_COL]
        and     al,[byte ptr di + OFF_ROW * 2 - OFF_COL * 2]
        cmp     al,ah
        je      __win
        clc
        ret
__win:  stc
        ret
ENDP    check_winner


;Print the board centered on the screen
PROC    print_board
USES    ax,es,di,si,cx
        mov     ax,VIDMEM
        mov     es,ax
        mov     di,BSTART
        mov     si,offset board
        mov     cx,DHEIGHT
__lp:   call    print_line
        add     di,(SWIDTH-DWIDTH) * 2
        loop    __lp
        ret
ENDP    print_board


;Print the prompt centered under the board
PROC    print_prompt
USES    ax,bx,es,di,si
        mov     ax,VIDMEM
        mov     es,ax
        mov     di,PSTART
        mov     si,offset prompt
        mov     al,[byte ptr players]
        mov     [byte ptr si],al
        call    print_line
        ret
ENDP    print_prompt


;Print line of the board
;Numbers are printed in a dim color
;Parameters:    si=display line
;               di=position on screen
PROC    print_line
USES    cx,ax
        mov     ah,BRIGHT
        mov     cx,DWIDTH
__lp:   lodsb
        mov     ah,BRIGHT
        cmp     al,'0'
        jb      __x
        cmp     al,'9'
        ja      __x
        mov     ah,DIM
        jmp     __p
__x:    cmp     al,'X'
        jne     __o
        mov     ah,RED
        jmp     __p
__o:    cmp     al,'O'
        jne     __p
        mov     ah,GREEN
__p:    stosw 
        loop    __lp
        ret
ENDP


END
