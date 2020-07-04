IDEAL
MODEL   TINY
LOCALS  __
P8086

DATASEG
board   db      " | | ",13,10
        db      "-----",13,10
        db      " | | ",13,10
        db      "-----",13,10
        db      " | | ",13,10
crlf    db      13,10,'$'
coord   dw      board + 28,board + 30,board + 32
        dw      board + 14,board + 16,board + 18
        dw      board + 0, board + 2, board + 4
players db      "XO"
prompt  db      " 's Turn> $"
win     db      "  wins!",13,10,'$'
nowin   db      "It's a tie",13,10,'$'
turn    db      9

OFF_ROW equ     14
OFF_COL equ     2

CODESEG
STARTUPCODE
PROC    main
        ;start with player 0
        xor     si,si
__lp:   ;print board
        mov     ah,009h
        mov     dx,offset crlf
        int     21h
        mov     dx,offset board
        int     21h
        ;print prompt
        mov     al,[byte ptr players + si]
        mov     [byte ptr prompt],al
        mov     dx,offset prompt
        int     21h
        ;get input
        mov     ah,001h
        int     21h
        xor     bx,bx
        mov     bl,al
        mov     ah,009h
        mov     dx,offset crlf
        int     21h
        ;loop on invalid input
        cmp     bl,'1'
        jl      __lp
        cmp     bl,'9'
        ja      __lp
        ;get offset into board
        sub     bx,'1'
        shl     bx,1
        mov     bx,[word ptr coord + bx]
        ;check if space is empty
        cmp     [byte ptr bx],' '
        jne     __lp
        ;place marker
        mov     al,[byte ptr players + si]
        mov     [byte ptr bx],al
        ;check for winner
        mov     ah,[byte ptr players + si]
        ;check for columns
        mov     cx,3
        mov     di,offset board
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
        mov     di,offset board
__row:  mov     al,ah
        and     al,[byte ptr di]
        and     al,[byte ptr di + OFF_COL]
        and     al,[byte ptr di + OFF_COL * 2]
        cmp     al,ah
        je      __win
        add     di,OFF_ROW
        loop    __row
        ;check for columns
        mov     al,ah
        and     al,[byte ptr board]
        and     al,[byte ptr board + OFF_COL + OFF_ROW]
        and     al,[byte ptr board + OFF_COL * 2 + OFF_ROW * 2]
        cmp     al,ah
        je      __win
        mov     al,ah
        and     al,[byte ptr board + OFF_ROW * 2]
        and     al,[byte ptr board + OFF_COL + OFF_ROW]
        and     al,[byte ptr board + OFF_COL * 2]
        cmp     al,ah
        je      __win
        ;next player's turn
        xor     si,1
        sub     [byte ptr turn],1
        jz      __nowin
        jmp     __lp
        ;no one won
__nowin:mov     ah,009h
        mov     dx,offset nowin
        int     21h
        jmp     __exit
__win:  mov     [byte ptr win],ah
        ;print board
        mov     ah,009h
        mov     dx,offset board
        int     21h
        ;print win message
        mov     dx,offset win
        int     21h
        ;exit
__exit: mov     ax,04C00h
        int     21h
ENDP    main

END
