dosseg
.model small
.stack 100h

.data
ballX dw 0ah ; x postion   ;defines word (16 bits)
ballY dw 0ah ; y postion
ball_Size dw 04h ; size of the ball ( pixels in width and height)

ball_initial_x dw 0a0h ;160px center
ball_initial_y dw 64h ;100 (px 0f screen)

Game_Active db 1      ;boolean, 1: Game active , 0: Game over
Winner_Index db 0     ;Index of the winner  (1-> Player One , 2-> Player Two)
Current_Screen db 0    ;Current Screen index (0-> main Menue , 1-> Game)
Exiting_Game db 0       ; (0-> False , 1-> True )

time_aux db 0 ; varible used for checking of the time has changed

text_player_one_points db '0','$'   ;text with player points, 0 as default
text_player_two_points db '0','$'
text_game_over_tittle db 'GAME OVER!$'   ;text to show game over
text_game_Winner db 'Player 0 Won','$'     ;text to show winner
text_Play_again db 'Press R to Play Again','$'   ;text to show on game over
text_show_main_menu db 'Press E to exit to Main Menu','$'
Text_main_menu_tittle db 'Pong N Paddles','$'    ;Main Menu Tittle
Text_main_menu_SinglePlayer db 'SinglePlayer --> S Key','$'
text_main_menu_Multiplayer  db 'MultiPlayer --> M Key','$'
text_main_menu_Exit db ' Exit Game --> E key','$'

ball_velocity_x dw 07h;     Horizontal Velocity of the ball
ball_velocity_y dw 03h;     Vertical Veloctiy of th ball

console_width dw 140h       ;320 pixels in hex screen width
console_height dw 0c8h      ;160 pixels in hex screen height
console_bounds dw 8

paddle_left_x dw 0ah ;starting Position on x
paddle_left_y dw 0ah
player_one_points db 0     ;currents points on the left player

paddle_right_x dw 130h  ;starting Position on x
paddle_right_y dw 0ah
player_two_points db 0     ;currents points on the left player

AI_controlled db 0     ;is the Right paddle controlled by the AI ( 0--> MultiPlayer , 1--> SinglePlayer )

paddle_width dw 04h
paddle_height  dw 1fh

paddle_velocity dw 07h


testVar dw 1;  To Test the JZ in paddle movement


.code

main proc
mov ax, @data
mov ds,ax
 

check_time:

    cmp Exiting_Game,01h      ;Check the exit Status  
    je start_exiting_process    ;move to exiting process if 1

    cmp Current_Screen, 00h  ;check the Current Game Screen
    je Main_Menu_call     ;move to Main Menue if 0

    cmp Game_Active, 00h    ;check if the game is active or not
    JE Game_Over_Menu       ;show game over menue if game is not active

;else game active:

    mov ah,2ch ; Function for getting system time 
    int 21h ; ch=hour  cl=minutes  dh=seconds  dl=1/100 seconds 

    cmp dl, time_aux  ;comparing if the current time is equal to the previous one  (time_aux)
    je check_time   ;if it is same, check again
    ;if not
    mov time_aux,dl ; update time 
    
 
    call move_ball
    call set_background_screen
    
    call draw_ball

    call move_paddles
    call draw_paddels   

    call draw_UI        ;user Interface for the game
 
    jmp check_time  ;checks time again on repeat

    Game_Over_Menu:
        call Screen_For_Game_Over
        jmp check_time

    start_exiting_process:
        call Conclude_Exit_Game

    Main_Menu_call:
        call Main_Menu_Screen
        jmp check_time
        
ret

main endp

move_ball proc Near

    mov ax, ball_velocity_x     ;for moviing ball horizontal
    add ballX, ax   ;we can not add two variables but store one in a register then add it in other
                 ;for moviing ball horizontal

;X COLLISIONS:
    ;if ballx < 0 then the ball has collided left boundary\
    mov ax, console_bounds
    cmp ballX, ax
    jl Points_to_Player_Two    ;if less then give one point to Player two, then reset positon

    ;if the ballx> screen size the it has collided right boundary
    mov ax, console_width
    sub ax, ball_Size ;     minus the ball size so it dosent over flow
    sub ax, console_bounds  ;minus the screen bounds for similar reason
    cmp ballX, ax
    jg Points_to_Player_One     ;if Greater, give one point to Player One, then reset positon
    jmp move_ball_vertically

;Points
    Points_to_Player_One:
        inc player_one_points       ;one point increment
        call reset_ball_positon      ;resets ball to the center of screen
        
        call update_text_player_one_points  ;updates the text of the player on screen
        cmp player_one_points, 5   ;check if the points are 5
        jge Game_Over              ; end the game if greater than 5
    ret


    Points_to_Player_Two:
        inc player_two_points      ;one point increment
        call reset_ball_positon      ;resets ball to the center of screen
        
        call update_text_player_two_points  ;updates the text of the player on screen
        cmp player_two_points,5    ;check if the points are 5
        jge Game_Over               ; end the game if greater than 5
    ret

;GameOver    (On Reaching 5 Points, game gets Over)
    Game_Over:
    cmp player_one_points, 05h    ;compare scores
    JNL Winner_is_Player_One      
    JMP Winner_is_Player_Two      ;if Player one has less score than 5, Player two is winner

    Winner_is_Player_One:        
        mov Winner_Index, 01h       ;updating winner index
        jmp Continue_Game_Over

    Winner_is_Player_two:
        mov Winner_Index,02h   ;updating winner index
        jmp Continue_Game_Over
    
    Continue_Game_Over:
    mov player_one_points,00h      ;restarts Players Points
    mov player_two_points, 00h     ;restarts Players Points
    call update_text_player_one_points
    call update_text_player_two_points
    mov Game_Active, 00h            ;stop the game
    ret


;Y COLLISIONS:
 move_ball_vertically:
    mov ax, ball_velocity_y
    add ballY, ax 

    mov ax, console_bounds
    cmp bally, ax
    jl negative_velocity_y

    mov ax, console_height
     sub ax, ball_Size ;     minus the ball size so it dosent over flow
   sub ax, console_bounds  ;minus the screen bounds for similar reason 
    cmp bally, ax
    jg negative_velocity_y
    jmp check_Collision_for_left_paddle
   

check_Collision_for_left_paddle:

;check if the ball collides left padddle
    ;no collision condition:
        ;ballx + ballsize(max x) > Paddle_x   &&    ballx < paddle_width + paddle_left_x  &&    ballY + ballSize > paddle_left_y    &&  BallY < paddle_left_y + Paddle_Height

        ; total width of ball should be greater than initial point x of paddle      && initial point of ball on x should be less tha the total width of paddle    && total height of ball should be greater (i.e above) the initial y point on paddle    && the initial Y of ball should be less than the total height of the paddle (i.e below)

;(1) ballx + ballsize(max x) > Paddle_x
    mov ax, ballx  
    add ax, ball_Size
    cmp ax, paddle_left_x
    JNG Check_Collision_for_right_paddle  ;if no collison 

;(2) ballx < paddle_width + paddle_left_x
    mov ax, paddle_left_x
    add ax, paddle_width
    cmp ballx, ax
    JNL check_Collision_for_right_paddle

;(3) ballY + ballSize > paddle_left_y 
    mov ax, ball_Size
    add ax, ballY
    cmp ax, paddle_left_y
    JNG Check_Collision_for_right_paddle

;(4) BallY < paddle_left_y + Paddle_Height
    mov ax, paddle_left_y
    add ax, paddle_height
    cmp ballY, ax
    JNL check_Collision_for_right_paddle

;if it reaches this point, then the ball is colliding 
    neg ball_velocity_x     ;reverse the horizontal velocity of the ball
    ret                     ;exit procedurex


    ;check if the ball collides right padddle
check_Collision_for_right_paddle:
        ;ballx + ballsize(max x) > Paddle_x   &&    ballx < paddle_width + paddle_right_x  &&    ballY + ballSize > paddle_right_y    &&  BallY < paddle_right_y + Paddle_Height

;(1) ballx + ballsize(max x) > Paddle_x
    mov ax, ballx  
    add ax, ball_Size
    cmp ax, paddle_right_x
    JNG exit_ball_collision

;(2) ballx < paddle_width + paddle_left_x
    mov ax, paddle_right_x
    add ax, paddle_width
    cmp ballx, ax
    JNL exit_ball_collision

;(3) ballY + ballSize > paddle_left_y 
    mov ax, ball_Size
    add ax, ballY
    cmp ax, paddle_right_y
    JNG exit_ball_collision

;(4) BallY < paddle_left_y + Paddle_Height
    mov ax, paddle_right_y
    add ax, paddle_height
    cmp ballY, ax
    JNL exit_ball_collision

;if it reaches this point, then the ball is colliding 
    neg ball_velocity_x     ;reverse the horizontal velocity of the ball
                             ;exit procedurex

 reset_postion:
        call reset_ball_positon
        ret

    negative_velocity_y:
        neg ball_velocity_y    ;neg function makes the number negative i.e ball_velocity_x= -ball_Velocity_x
        ret
    exit_ball_collision:
    ret 

ret
move_ball endp




move_paddles proc Near 

;   INT 16:   keyboard Bios Services    

mov ah,01 ; Checks to see if a character is available in the buffer
int 16h
    ;if the key is being pressed set zero flag to 0 
JZ check_if_Single_Player  ;z=1,if character is not available, jump if zero (zero flag changes 0 to 1 and 1 to zero) 



;check which key  (AL is for ASCII which is diffent for both upper and lower case and AH is for Scan code which is unique for every key regardless the case)
                                                                                        ;for Scan Codes: https://www.stanislavs.org/helppc/scan_codes.html 
mov ah,00   ;  AH,0 Wait for keystroke and read
int 16h

check_left_paddle_Movement:
;move up using "w" or "W"
    ;cmp ah,11h ;scan code for w/W
    cmp al,  77h   ;Lowercase w
    Je move_left_paddle_UP
    cmp al,  57h   ;Uppercase W
    Je move_left_paddle_UP

;move down using "s" or "S"

;cmp Ah,1Fh
    cmp al, 73h    ;Lowercase s
    Je move_left_paddle_down
    cmp al, 53h   ;Uppercase S
    je move_left_Paddle_down

    jmp check_right_paddle_movement  ;simulatenously moves both left and right when keys are pressed

move_left_paddle_UP:
    mov ax, paddle_velocity
    sub paddle_left_y, ax ;moves up

    ;fix paddles to not move out the console bounds
    mov ax,console_bounds
    cmp paddle_left_y, ax
    jl fix_Paddle_positon_up
    jmp check_right_paddle_movement  ;simulatenously moves both left and right when keys are pressed

    fix_Paddle_positon_up:
    mov paddle_left_y, ax
    jmp Check_right_paddle_movement


move_left_paddle_down:
    mov ax, paddle_velocity
    add paddle_left_y, ax ;moves down

    mov ax,console_height
    sub ax,console_bounds
    sub ax, paddle_height
    cmp paddle_left_y, ax
    jg fix_Paddle_positon_down
    jmp check_right_paddle_movement  ;simulatenously moves both left and right when keys are pressed

    fix_Paddle_positon_down:
    mov paddle_left_y, ax
    jmp Check_right_paddle_movement


;Right Paddle
Check_right_paddle_movement :

    check_if_Single_Player:
        cmp AI_controlled,00h  ;Check if the user is Single Player 
        je control_By_AI  
        
check_for_Key_Input:
    cmp al, 6fh    ;Lowercase o
    Je move_right_paddle_up
    cmp al, 4fh   ;Uppercase O 
    je move_right_Paddle_up

    cmp al, 6ch    ;Lowercase l
    Je move_right_paddle_down
    cmp al, 4ch   ;Uppercase L
    je move_right_Paddle_down

    jmp exit_paddle_movement  

control_By_AI:
    ;check if the ball is above the paddle
    ;bally + Ball size  <  Paddle_right_y
        ;if so we move the paddle up
        mov ax, bally
        add ax, ball_Size
        cmp ax, paddle_right_y
        jle move_right_Paddle_up
        
    ;check if the ball is below the paddle
    ;ball y > paddle_right_y + Paddle_height
        ;if so we move the paddle down
        mov ax, paddle_right_y
        mov ax,paddle_height
        cmp ballY, ax
        Jge move_right_Paddle_down

    ;if neither: dont movve the paddle
        jmp exit_paddle_movement
    

move_right_paddle_UP:
    mov ax, paddle_velocity
    sub paddle_right_y, ax ;moves up

    ;fix paddles to not move out the console bounds
    mov ax,console_bounds
    cmp paddle_right_y, ax
    jl fix_right_Paddle_positon_up
    jmp exit_paddle_movement   ;simulatenously moves both left and right when keys are pressed

    fix_right_Paddle_positon_up:
        mov paddle_right_y, ax
        jmp exit_paddle_movement 

move_right_paddle_down:
    mov ax, paddle_velocity
    add paddle_right_y, ax ;moves down

    mov ax,console_height
    sub ax,console_bounds
    sub ax, paddle_height
    cmp paddle_right_y, ax
    jg fix_right_Paddle_positon_down
    jmp exit_paddle_movement   ;simulatenously moves both left and right when keys are pressed

    fix_right_Paddle_positon_down:
        mov paddle_right_y, ax
        jmp exit_paddle_movement 


exit_paddle_movement :
    ret

move_paddles endp


draw_ball proc Near ;the near keyword tell that this block of proc belongs to the same code segment 

;sets initial position
mov cx, ballX ; sets column i.e starting point (x)  ; 16 bits
mov dx, ballY ;sets  line (y)




    draw_ball_horzontal:
        mov ah, 0ch ; for creating pixel
        mov al, 0fh ;set white color
        mov bh, 00h ;sets page number to 0
        int 10h
        
        inc cx 

        mov ax, cx  ;store value of cx in ax
        sub ax, ballX   ;minus the initial value
        cmp ax, ball_Size   ;compare ax with the set ball size inn the data segmet
        jng draw_ball_horzontal     ;if less, it loops 

        mov cx,ballX    ;the Register Goes back to the same inital value
        inc dx          ; we advance one line 

        mov ax, dx
        sub ax, ballY 
        cmp ax, ball_Size 
        jng draw_ball_horzontal


ret
draw_ball endp

draw_paddels proc Near
    mov cx,paddle_left_x
    mov dx,paddle_left_y

    
    draw_left_paddle_horzontal:
        mov ah, 0ch ; for creating pixel
        mov al, 0fh ;set white color
        mov bh, 00h ;sets page number to 0
        int 10h
        inc cx

        mov ax, cx  ;store value of cx in ax
        sub ax, paddle_left_x   ;minus the initial value
        cmp ax, paddle_width   ;compare ax with the set size inn the data segmet
        jng draw_left_paddle_horzontal   ;if less, it loops 

        mov cx,paddle_left_x   ;the Register Goes back to the same inital value
        inc dx          ; we advance one line 

        mov ax, dx
        sub ax, paddle_left_y
        cmp ax, paddle_height
        jng draw_left_paddle_horzontal

;Similarly for right paddle
    mov cx,paddle_right_x
    mov dx,paddle_right_y

    
    draw_right_paddle_horzontal:
        mov ah, 0ch ; for creating pixel
        mov al, 0fh ;set white color
        mov bh, 00h ;sets page number to 0
        int 10h
        inc cx

        mov ax, cx  ;store value of cx in ax
        sub ax, paddle_right_x   ;minus the initial value
        cmp ax, paddle_width   ;compare ax with the set size inn the data segmet
        jng draw_right_paddle_horzontal   ;if less, it loops 

        mov cx,paddle_right_x   ;the Register Goes back to the same inital value
        inc dx          ; we advance one line 

        mov ax, dx
        sub ax, paddle_right_y
        cmp ax, paddle_height
        jng draw_right_paddle_horzontal
        
ret
draw_paddels endp


draw_UI proc Near

;draw Point of Player One
    mov ah,02h      ;sets cursor postion
    mov bh,00h     ;set page number
    mov dh,00h      ;sets Row Number
    mov dl, 08h     ;sets coloumn number

    int 10h

    ;diplay text

    mov ah, 09h     ;write string as output
    lea dx, text_player_one_points  ;lea: Load effective address , gives point to string
    int 21h


;draw Point of Player two
    mov ah,02h      ;sets cursor postion
    mov bh,00h     ;set page number
    mov dh,00h      ;sets Row Number
    mov dl, 1fh
    

    int 10h

    ;diplay text

    mov ah, 09h     ;write string as output
    lea dx, text_player_two_points  ;lea: Load effective address , gives point to string
    int 21h


ret
draw_UI endp

update_text_player_one_points proc near     ;updates the text of the player on screen

    ;clean ax register
    xor ax,ax
    mov al, player_one_points

    ;convert decimal value to ascii code
        ;(number to ascii: add 30h)    /   (Ascii to number: sub 30h) 
    add al , 30h
    mov [text_player_one_points],al

 
ret
update_text_player_one_points endp


update_text_player_two_points proc near     ;updates the text of the player on screen

    ;clean ax register
    xor ax,ax
    mov al, player_two_points

    ;convert decimal value to ascii code
        ;(number to ascii: add 30h)    /   (Ascii to number: sub 30h) 
    add al , 30h
    mov [text_player_two_points],al
ret
update_text_player_two_points endp


Screen_For_Game_Over proc near
    
    call set_background_screen

    ;Show Menu Tittle
    mov ah,02h      ;sets cursor postion
    mov bh,00h     ;set page number
    mov dh,0ah      ;sets Row Number
    mov dl, 0fh     ;sets coloumn number   
    int 10h

    ;diplay Game Over
    mov ah, 09h     ;write string as output
    lea dx, text_game_over_tittle        ; prints Game Over On Screen
    int 21h

    call update_winner_text
    
    ;diplay Winner
    mov ah,02h      ;sets cursor postion
    mov bh,00h     ;set page number
    mov dh,0ch      ;sets Row Number
    mov dl, 0eh     ;sets coloumn number   
    int 10h

    mov ah, 09h     ;write string as output
    lea dx, text_game_Winner       ; prints Game Over On Screen
    int 21h

    ;show play again message
    mov ah,02h      ;sets cursor postion
    mov bh,00h     ;set page number
    mov dh,0eh      ;sets Row Number
    mov dl, 0ah     ;sets coloumn number   
    int 10h

    mov ah, 09h     ;write string as output
    lea dx, text_Play_again       ; Print Play again Text on screen
    int 21h

    ;show Main Menu Option message
    mov ah,02h      ;sets cursor postion
    mov bh,00h     ;set page number
    mov dh,10h      ;sets Row Number
    mov dl, 07h     ;sets coloumn number   
    int 10h

    mov ah, 09h     ;write string as output
    lea dx, text_show_main_menu      ; Print Play again Text on screen
    int 21h

    ;Wait for Key press
    mov ah, 00h
    int 16h 

    cmp Al, 'R'         ;Check if the pressed key is R/r
    JE Restart_Game 
    cmp Al, 'r'
    JE Restart_Game     ;Restart the game

    cmp Al, 'E'         ;Check if the pressed key is e/E
    JE Exit_to_Main_Menu
    cmp Al, 'e'
    JE Exit_to_Main_Menu     ;exit the game
    ret

    Restart_Game:
        mov Game_Active,01h     ;Change Game Active index to 1
        ret

    Exit_to_Main_Menu:
        mov Game_Active,00h     ;Change Game Active index to 0
        mov Current_Screen,00h  ;Change Current screen index to 0
        ret

ret
Screen_For_Game_Over endp


Main_Menu_Screen proc near
    
    call set_background_screen

    ;Show Main Menu Tittle: 
    mov ah,02h      ;sets cursor postion
    mov bh,00h     ;set page number
    mov dh,04h      ;sets Row Number
    mov dl, 0fh     ;sets coloumn number   
    int 10h

    mov ah, 09h     ;write string as output
    lea dx, Text_main_menu_tittle       ; prints Game Over On Screen
    int 21h


    ;Show Single Player Option 
    mov ah,02h      ;sets cursor postion
    mov bh,00h     ;set page number
    mov dh,0bh      ;sets Row Number
    mov dl, 0bh     ;sets coloumn number   
    int 10h

    mov ah, 09h     ;write string as output
    lea dx, Text_main_menu_SinglePlayer       ;Prints text on screen
    int 21h


    ;Show MultiPlayer Option: 
    mov ah,02h      ;sets cursor postion
    mov bh,00h     ;set page number
    mov dh,0dh      ;sets Row Number
    mov dl, 0ch     ;sets coloumn number   
    int 10h

    mov ah, 09h     ;write string as output
    lea dx, text_main_menu_Multiplayer        ;Prints text on screen
    int 21h


    ;Show Exit Game Option: 
    mov ah,02h      ;sets cursor postion
    mov bh,00h     ;set page number
    mov dh,0fh      ;sets Row Number
    mov dl, 0ch     ;sets coloumn number   
    int 10h

    mov ah, 09h     ;write string as output
    lea dx, text_main_menu_Exit     ;Prints text on screen
    int 21h


    Main_menu_wait_for_key:
      ;Wait for Key press
    mov ah, 00h
    int 16h 

    cmp Al, 'S'         ;Check if the pressed key is S/s
    JE Start_SinglePlayer 
    cmp Al, 's'
    JE Start_SinglePlayer     ;Play single Player game

    cmp Al, 'M'         ;Check if the pressed key is M/m
    JE Start_multiplayer
    cmp Al, 'm'
    JE start_multiplayer    ;Play Multiplayer Game

    cmp Al, 'E'         ;Check if the pressed key is E/e
    JE Exit_Game 
    cmp Al, 'e'
    JE Exit_Game     ;Exit the game
    jmp Main_menu_wait_for_key
    

    Start_SinglePlayer: 
        mov Current_Screen, 01h  
        mov Game_Active, 01h 
        mov AI_controlled,01h   ;index for Ai Controlled Single Player Mode
    ret 

    Start_multiplayer: 
        mov Current_Screen, 01h  
        mov Game_Active, 01h 
        mov AI_controlled,00h   ;index for Two Players Mode
        ret 
    

    Exit_Game: 
        mov Exiting_Game,01h
        ret

Main_Menu_Screen endp

update_winner_text proc near 

    mov al, Winner_Index     
    add al, 30h
    mov [text_game_Winner+7], al   ;Updates game winner text

ret
update_winner_text endp


reset_ball_positon proc Near

    mov ax, ball_initial_x
    mov ballx,ax

    mov ax, ball_initial_y
    mov bally,ax

ret
reset_ball_positon endp


set_background_screen proc near
    mov ah, 00h ;sets video mode
    mov al, 13h ;set 256 ccolor graphics (MCGA, VGA)
    int 10h

    
;  ;CHANGE BACKGROUND COLOR   (Glitches in transiton) :
;     MOV AX, 0600h        ; AH=06(scroll up window), AL=00(entire window)
;     MOV BH, 1010000b    ; left nibble for background (blue), right nibble for   foreground (light gray)             0010111b(Sets Powder Pink Color)                              1010000b(Powder Blue)
;     MOV CX, 0000h        ; CH=00(top), CL=00(left)
;     MOV DX, 184fh        ; Full Screen 
;     INT 10h


ret
set_background_screen endp

Conclude_Exit_Game proc near ; Returns to the Text Mode

    mov ah,00h      ;set configuration to video mode
    mov al,02h      ;Choose Text mode  , 02h text mode 80x25
    int 10h

    mov ah, 4ch     ;Termminate the Program
    int 21h

ret
Conclude_Exit_Game endp


end main
