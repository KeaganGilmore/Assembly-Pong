.stack 100h
.data
    welcomeMessage db "Press 'a' for player 1$", 0
    player2Message db "Press arrow up for player 2$", 0
    player1Ready db "Player 1 ready!$", 0
    player2Ready db "Player 2 ready!$", 0
    block db 219
    bullet db 219
    rows db 8
    cols db 4
    string1 db 'health$'
    string2 db '***$'
    wall db 219
    rowswall db 25
    colswall db 1
    hole_row db 12
    hole_size db 3
    hole_direction db 5
    
    bullet1_active db 0
    bullet1_x db 0
    bullet1_y db 0
    bullet2_active db 0
    bullet2_x db 0
    bullet2_y db 0
    
    player1_health db 3
    player2_health db 3
    game_over db 0

.code
    mov ax, @data
    mov ds, ax

game_start:
    mov byte ptr [player1_health], 3
    mov byte ptr [player2_health], 3
    mov byte ptr [game_over], 0
    mov byte ptr [bullet1_active], 0
    mov byte ptr [bullet2_active], 0
    
    call displayMessage

wait_player1:
    mov ah, 00h
    int 16h
    cmp al, 'a'
    jne wait_player1
    
    mov ah, 09h
    mov dx, offset player1Ready
    int 21h
    call displayPlayer2Message

wait_arrow_key:
    mov ah, 00h
    int 16h
    cmp ah, 48h
    jne wait_arrow_key
    
    mov ah, 09h
    mov dx, offset player2Ready
    int 21h
    
    mov ah, 06h
    mov al, 00h
    mov bh, 07h
    mov cx, 0
    mov dx, 184Fh
    int 10h

main_game_loop:
    mov ah, 01h
    int 16h
    jz no_key_pressed

    mov ah, 00h
    int 16h
    
    cmp al, 'a'
    je fire_player1
    cmp ah, 48h
    je fire_player2

fire_player1:
    cmp byte ptr [bullet1_active], 0
    jne no_key_pressed
    mov byte ptr [bullet1_active], 1
    mov byte ptr [bullet1_x], 5
    mov byte ptr [bullet1_y], 14
    jmp no_key_pressed

fire_player2:
    cmp byte ptr [bullet2_active], 0
    jne no_key_pressed
    mov byte ptr [bullet2_active], 1
    mov byte ptr [bullet2_x], 73
    mov byte ptr [bullet2_y], 14

no_key_pressed:
    mov ah, 02h
    mov bh, 0
    mov dh, 0
    mov dl, 0
    int 10h
    mov ah, 09h
    lea dx, string1
    int 21h
    
    mov cx, 0
    mov cl, [player1_health]
print_health1:
    mov ah, 02h
    mov dl, '*'
    int 21h
    loop print_health1
    
    mov ah, 02h
    mov dh, 0
    mov dl, 60
    int 10h
    mov ah, 09h
    lea dx, string1
    int 21h
    
    mov cx, 0
    mov cl, [player2_health]
print_health2:
    mov ah, 02h
    mov dl, '*'
    int 21h
    loop print_health2

    call draw_players
    call update_bullets
    
    mov al, [hole_row]
    add al, [hole_direction]
    cmp al, 5
    jl reverse_down
    cmp al, 20
    jg reverse_up
    mov [hole_row], al
    jmp draw_wall_start

reverse_down:
    mov byte ptr [hole_direction], 1
    mov [hole_row], 5
    jmp draw_wall_start

reverse_up:
    mov byte ptr [hole_direction], -1
    mov [hole_row], 20

draw_wall_start:
    mov cx, 25
    mov dh, 0
    mov dl, 40

draw_wall:
    push cx
    mov ah, 02h
    mov bh, 0
    int 10h
    
    mov al, dh
    sub al, [hole_row]
    cmp al, 0
    jl draw_wall_segment
    cmp al, [hole_size]
    jl skip_wall_segment
    
draw_wall_segment:
    mov al, [wall]
    mov bl, 0Eh
    mov ah, 09h
    mov cx, 1
    int 10h
    jmp next_wall_row
    
skip_wall_segment:
    mov al, ' '
    mov bl, 0Eh
    mov ah, 09h
    mov cx, 1
    int 10h
    
next_wall_row:
    pop cx
    inc dh
    loop draw_wall

    cmp byte ptr [player1_health], 0
    je game_is_over
    cmp byte ptr [player2_health], 0
    je game_is_over
    
    jmp main_game_loop

game_is_over:
    mov byte ptr [game_over], 1
    jmp game_start

draw_players:
    mov ah, 02h
    mov bh, 0
    mov dh, 10
    mov dl, 0
    int 10h
    mov cx, 8
    mov si, 4

draw_left_blocks:
    push cx
    mov cx, si
draw_left_row:
    mov al, [block]
    mov bl, 01h
    mov ah, 09h
    int 10h
    loop draw_left_row
    mov dl, 0Ah
    mov ah, 02h
    int 21h
    mov dl, 0Dh
    int 21h
    pop cx
    loop draw_left_blocks

    mov ah, 02h
    mov bh, 0
    mov dh, 10
    mov dl, 74
    int 10h
    mov cx, 8
    mov si, 4

draw_right_blocks:
    push cx
    mov cx, si
draw_right_row:
    mov al, [block]
    mov bl, 04h
    mov ah, 09h
    int 10h
    loop draw_right_row
    inc dh
    mov dl, 74
    mov ah, 02h
    int 10h
    pop cx
    loop draw_right_blocks
    ret

update_bullets:
    cmp byte ptr [bullet1_active], 1
    jne check_bullet2
    
    mov ah, 02h
    mov bh, 0
    mov dh, [bullet1_y]
    mov dl, [bullet1_x]
    int 10h
    mov al, ' '
    mov bl, 01h
    mov ah, 09h
    mov cx, 1
    int 10h
    
    inc [bullet1_x]
    
    mov ah, 02h
    mov bh, 0
    mov dh, [bullet1_y]
    mov dl, [bullet1_x]
    int 10h
    mov al, [bullet]
    mov bl, 01h
    mov ah, 09h
    mov cx, 1
    int 10h
    
    mov al, [bullet1_x]
    cmp al, 40
    jne check_bullet1_hit
    mov bl, [bullet1_y]
    sub bl, [hole_row]
    cmp bl, 0
    jl bullet1_wall_hit
    cmp bl, [hole_size]
    jge bullet1_wall_hit
    jmp check_bullet1_hit

bullet1_wall_hit:
    mov byte ptr [bullet1_active], 0
    jmp check_bullet2

check_bullet1_hit:
    cmp byte ptr [bullet1_x], 73
    jne check_bullet2
    mov byte ptr [bullet1_active], 0
    dec byte ptr [player2_health]

check_bullet2:
    cmp byte ptr [bullet2_active], 1
    jne update_bullets_end
    
    mov ah, 02h
    mov bh, 0
    mov dh, [bullet2_y]
    mov dl, [bullet2_x]
    int 10h
    mov al, ' '
    mov bl, 04h
    mov ah, 09h
    mov cx, 1
    int 10h
    
    dec [bullet2_x]
    
    mov ah, 02h
    mov bh, 0
    mov dh, [bullet2_y]
    mov dl, [bullet2_x]
    int 10h
    mov al, [bullet]
    mov bl, 04h
    mov ah, 09h
    mov cx, 1
    int 10h
    
    mov al, [bullet2_x]
    cmp al, 40
    jne check_bullet2_hit
    mov bl, [bullet2_y]
    sub bl, [hole_row]
    cmp bl, 0
    jl bullet2_wall_hit
    cmp bl, [hole_size]
    jge bullet2_wall_hit
    jmp check_bullet2_hit

bullet2_wall_hit:
    mov byte ptr [bullet2_active], 0
    jmp update_bullets_end

check_bullet2_hit:
    cmp byte ptr [bullet2_x], 5
    jne update_bullets_end
    mov byte ptr [bullet2_active], 0
    dec byte ptr [player1_health]

update_bullets_end:
    ret

displayMessage:
    mov ah, 09h
    mov dx, offset welcomeMessage
    int 21h
    mov dx, offset player2Message
    int 21h
    ret

displayPlayer2Message:
    mov ah, 09h
    mov dx, offset player2Message
    int 21h
    ret
end