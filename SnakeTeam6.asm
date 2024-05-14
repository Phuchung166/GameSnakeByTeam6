 org 100h
.data
; 
; Dinh nghia toa do cua con ran (tu dau den duoi)
; (X,Y) = (byte thap, byte cao)
snake dw 0Dh,0Ch,0Bh,0Ah, 150 dup(?)   ;(X0,Y0),(X1,Y1)...  ; dat bo nho cho con ran
s_size  db     4,0       ; size of the snake                           ; de khong ghi de len cac bien khac
;mang s_size 2 phan tu 4 va 0
                                                                          ; variables
tail    dw      ?       ;; toa do cua duoi truoc dó  (byte thap X, byte cao Y)

; Hang so huong di   
;  (ma phim BIOS):      Keyboard scan codes 
     
left    equ     4bh
right   equ     4dh
up      equ     48h
down    equ     50h 

; Huong hien tai cua con ran
cur_dir db      right
; Huong cu cua con ran
old_dir db      right
; Toa do cua moi
mealX  db  ?
mealY  db  ?

; Diem so
score db '0','0','0','0','$'

; Tin nhan bat dau
msgstart db 5 dup(0ah),15 dup(20h)
 db             "  _______ _             _____             _         ", 0dh,0ah
 db 15 dup(20h)," |__   __| |           / ____|           | |        ", 0dh,0ah       
 db 15 dup(20h),"    | |  | |__   ___  | (___  _ __   __ _| | _____  ", 0dh,0ah
 db 15 dup(20h),"    | |  | '_ \ / _ \  \___ \| '_ \ / _` | |/ / _ \ ", 0dh,0ah
 db 15 dup(20h),"    | |  | | | |  __/  ____) | | | | (_| |   <  __/ ", 0dh,0ah
 db 15 dup(20h),"   _|_|_ |_| |_|\___| |_____/|_| |_|\__,_|_|\_\___| ", 0dh,0ah
 db 15 dup(20h),"  / ____|                    | |                    ", 0dh,0ah
 db 15 dup(20h)," | |  __  __ _ _ __ ___   ___| |                    ", 0dh,0ah
 db 15 dup(20h)," | | |_ |/ _` | '_ ` _ \ / _ \ |                    ", 0dh,0ah
 db 15 dup(20h)," | |__| | (_| | | | | | |  __/_|                    ", 0dh,0ah
 db 15 dup(20h),"  \_____|\__,_|_| |_| |_|\___(_)                    ", 0dh,0ah,0ah
 db 25 dup(20h),"    Press Enter to start.                             $"  
 
 
 
   

; Tin nhan ket thuc
msgover db  5 dup(0ah),15 dup(20h)
 db              "  ___   __   _  _  ____     __   _  _  ____  ____ ", 0dh,0ah 
 db  15 dup(20h)," / __) / _\ ( \/ )(  __)   /  \ / )( \(  __)(  _ \", 0dh,0ah 
 db  15 dup(20h),"( (_ \/    \/ \/ \ ) _)   (  O )\ \/ / ) _)  )   /", 0dh,0ah 
 db  15 dup(20h)," \___/\_/\_/\_)(_/(____)   \__/  \__/ (____)(__\_)", 0dh,0ah,0ah,0ah                                                  
 db  30 dup(20h),"   Your score is : $", 0dh,0ah
                                                    


.code  
    mov dx, offset msgstart     ;;
    mov ah, 9 
    int 21h    
    
    mov ax, 40h                   
    mov es, ax 

 ; Doi cho phim Enter duoc nhan
wait_for_enter:
    mov ah, 00h 
    int 16h
    cmp al,0dh      
    jne wait_for_enter          
                                                              
    mov al, 1     ; Chuyen sang trang thai 1 
    mov ah, 05h
    int 10h          
    
   call randomizeMeal 

;;----------------

game_loop: 

     ; === Hien thi phan dau moi cua con ran
    call show_new_head
     ; ====== kiem tra va cham 
    
    
    mov dx,snake[0]  ; di chuyen con tro den vi tri head of snake
    mov si,w.s_size  ; si nhan s_size
    add si,w.s_size  ; si=si*2
    sub si,2         ; si-=2 <=> khi nay si luu gia tri s_size*2-2
    
    mov cx,w.s_size  ; cx luu do dai cua snake
    sub cx,4         ; Neu cx-4=0 tuc la khi nay moi bat dau game, khi nay ran khong the chet
    jz no_death      ; s_size = 4 thi jump to no_death
    
deathloop: 
                   
    cmp dx,snake[si] ; So sanh toa do cua dau con ran voi cac phan tu cua pha than con ran
    je game_over     ; Neu trung khop, con ran da va cham voi chinh minh
    sub si,2
    dec cx
    jnz deathloop
no_death:                                          
    ; Luu toa do phan duoi con ran... de xoa sau nay.
    mov si,w.s_size   ; si nhan  (s_size-1)*2
    add si,w.s_size
    sub si,2
    mov ax, snake[si]  
    mov tail, ax     

    call move_snake   ; Goi thu tuc de di chuyen con ran theo huong hien tai        

    ; toa do dau  == toa do cua Meal ?

    mov dx,snake[0]   ; Luu toa do dau ran vao thanh ghi DX
    mov al,mealX
    mov ah,mealY      ; Luu toa do cua moi vao thanh ghi AX
    
    cmp ax,dx
    jne hide_old_tail ; neu ax == dx tuc la ran da an moi
                      ; con ax != dx thi la chua an moi cho nen khi di chuyen phai xoa old_tail
    
    
    ;TRUONG HOP RAN DA AN MOI
    mov al,s_size  
    inc al       ; Ran da an moi nen tang kich thuoc cua ran
    mov s_size,al 
    
    mov ax,tail  ; Luu toa do duoi cu vao ax
    mov bh,0
    mov bl,s_size
    add bl,s_size       ; bh=0 --- bl = s_size*2-2
    sub bl,2
    mov snake[bx],ax    ; add new tail
    call scoreplus      ; Goi ham tang diem so
    call randomizeMeal  ; Goi ham de tao ra vi tri moi cho moi
    jmp no_hide_old_tail
     ;; Mo rong ran va hien thi cot cuoi cung


hide_old_tail:           ;An phan duoi cu 
    
    mov     dx, tail
    
    ; Di chuyen con tro ve vi tri duoi cu luu tai DX
    mov     ah, 02h
    int     10h
    
    ; In ra khoang trang tai vi tri cua tail => da xoa old_tail

    
    mov     al, ' '
    mov     ah, 09h
    mov     cx, 1   ; In mot ky tu khoang trang.
    int     10h

no_hide_old_tail:
    
    ;===Kiem tra cac lenh cua player
    mov     ah, 01h     ; Co gi do trong bo nho dem ban phim khong?
    int     16h
    jz      no_key      ; Khong co nut nao duoc bam thi thoi
    
    mov     ah, 00h     ; Neu co nut duoc bam thi luu nut do  vao cur_dir 
    int     16h         
    mov cur_dir,ah

no_key:
jmp game_loop

game_over:
xor dx,dx             ; dx = 0
mov ah, 02h           ; Di chuyen con tro ve (0,0)
int 10h
mov dx,offset msgover ; In ra thong diep ket thuc
mov ah,09h
int 21h
mov dx,offset score   ; In ra diem so
mov ah,09h
int 21h
ret

; ------ Cac ham ------

move_snake proc

;  
  ; con tro DI tro den duoi
  
  mov   di,w.s_size     ; DI luu gia tri (s_size-1)*2
  add di,w.s_size
  sub di,2
  ; di chuyen co the (toa do)
  ; bat dau tu duoi ran
  mov cx,w.s_size
  dec cx
  
move_array:                
  mov   ax, snake[di-2]   
  mov   snake[di], ax    ; Chuyen noi dung cua snake[di-2] sang snake[di]  
  sub   di, 2            ; Cung lam cho vi tri cua snake[di] tren man hinh thay doi
  loop  move_array       ; Khi do snake[di] se tien ve phia truoc

getdir:
cmp     cur_dir, left
  je    move_left
cmp     cur_dir, right
  je    move_right
cmp     cur_dir, up
  je    move_up
cmp     cur_dir, down
  je    move_down         
  
get_old_dir:
        mov al,old_dir
        mov cur_dir,al
jmp     getdir       ; huong moi =  huong cu

move_left:
  cmp old_dir,right
  je get_old_dir
  mov   al, b.snake[0]
  dec   al              ; X--
  mov   b.snake[0], al  ;
  cmp   al, -1          ; Neu al=-1 tuc b.snake[0] = -1 sau khi tru 1 don vi tuc la no bat dau di qua bien trai, truoc do dau ran dang o cot 0
  jne   stop_move       
  mov   al, es:[4ah]    ; es:[4ah] chua so cot trong man hinh
  dec   al              ; So cot duoc danh so thu tu : (0 -> es[4ah]-1)
  mov   b.snake[0], al  ; Dat dau ran vao  
  jmp   stop_move

move_right:
  cmp old_dir,left
  je get_old_dir
  mov   al, b.snake[0]    ; Cung nguyen tac
  inc   al                ; X++;
  mov   b.snake[0], al    ;
  cmp   al, es:[4ah]      ; Kiem tra X <  cot cuoi cung ?
  jb    stop_move         ; Co: tiep tuc di chuyen
  mov   b.snake[0], 0     ; Quay lai bien trai (x(head) = 0)
  jmp   stop_move         ; Tiep tuc di chuyen
                     
  ; Mang snake la kieu dw
  ; Do do: b.snake[0] dai dien cho toa do X (hang) cua dau ran
  ;        b.snake[1] dai dien cho toa do X (cot)  cua dau ran                 
                     
move_up:
  cmp old_dir,down
  je get_old_dir          ; Cung nguyen tac
  mov   al, b.snake[1]    ; Y-- 
  dec   al                ;
  mov   b.snake[1], al    ;
  cmp   al, -1
  jne   stop_move
  mov   al, es:[84h]      ;
  mov   b.snake[1], al    ;
  jmp   stop_move
                     
                     
move_down:
  cmp old_dir,up
  je get_old_dir
  mov   al, b.snake[1]
  inc   al                ;
  mov   b.snake[1], al    ;
  cmp   al, es:[84h]      ; Cung nguyen tac 
  jbe   stop_move         ;
  mov   b.snake[1], 0     ;
  jmp   stop_move

stop_move:                ; Moi lan chuong trinh move_snake chi dich chuyen ran 1 don vi
  mov al,cur_dir          ; Dich chuyen 1 don vi xong phai dung lai da 
  mov old_dir,al
  ret  
  
move_snake endp


              
              
randomizeMeal proc near     ;;===== make new food
reRandomize:
   mov ah, 00h   ; Ngat de nhan thoi gian tu he thong       
   int 1ah       ; CX:DX nhan so chu ki tu nua dem    
   mov ax, dx
   xor dx, dx
   mov cx,25     ; 25 la chieu rong cua man hinh
   div cx        ; Tuong duong voi rand()%25  DX nhan phan du cua phep chia DX:AX cho CX
   mov mealY,dl

   mov ah, 00h           
   int 1ah          
   mov ax, dx
   xor dx, dx
   mov cx,80     ; 80 la chieu dai cua man hinh
   div cx        ; Tuong duong voi rand()%80  DX nhan phan du cua phep chia DX:AX cho CX
   mov mealX,dl   
   
   mov dh,mealY
    ; Neu Meal lay toa do tu mot phan cua con ran
    ;xor cx,cx
    mov cx,w.s_size   ; Luu kich thuoc cua snake vao cx (lay phan tu dau cua mang)
                      ; Luu vao cx de lam bien dem, duyet tu dau den dit cua snake
    xor bx,bx    ;bx=0  
    
    
no_overwrite_snake:   ; Khong ghi de len snake
    ;dx khi nay luu toa do cua food
    cmp dx,snake[bx]  ; snake[0] tuc la phan tu dau tien cua mang snake
    je reRandomize    ; Kiem tra xem ran an moi chua, neu an roi thi make new food
    
    add bx,2          ; bx+=2 tuc la sang phan tu tiep theo cua mang snake, kieu dw nen phai +2 , binh thuong dw la 4 byte co nhung ma do assem8086 nen chi co 2 byte thoi, tuy thuoc vao kien truc
    dec cx
    jnz no_overwrite_snake ; Khi nao duyet qua het cua snake thi stop   
    
    ;--- hien thi moi   
    mov ah, 02h     ; Di chuyen con tro den (X,Y)=(dl,dh)   hang (DH) va cot (DL) 
    
    mov bh,01h      ; Khong co lenh nay thi do dai cua ran se khong dai ra va new food se khong hien thi
    ; Cac thao tac do hoa tiep theo se duoc thuc hien tren trang video 1          
    int 10h   
    
    mov al, 003     ; 003 la ma ascii dai diên cho food (co the thay doi ki tu nay)      
    mov     bl, 0eh ; Thuoc tinh; lower 4bits : mau cua ki tu; higher 4 bits: mau nen cua ki tu
                    ; bl luu mau cua food, 0dh dai dien cho pink trong bios color attribute
    ; Ham 09h cua ngat 10h yeu cau voi al la ki tu can ve, bl la mau cua ki tu, cx la so luong ki tu muon ve
    mov     cx, 1   
    mov     ah, 09h     ; Doan nay co tac dung in ra new food 
    int     10h
    ret
randomizeMeal endp
                  ;                         [0] [1] [2] [3]
                  ;                          |   |   |   |
                  ;                          v   v   v   v
scoreplus proc    ;score++        ;score db '0','0','0','0','$'   score la chuoi dai dien cho so 4 chu so
        
    mov al,score[3]    ; Tang so dau tien
    inc al
    cmp al,'9'         ; So dau tien vuot qua '9' ?
    jg inc_second
    mov score[3],al    ; Chua vuot qua 9 thi thoi, print score
    ret
    
inc_second:
    mov score[3],'0'   ; Dua so dau tien ve '0'
    mov al,score[2]    ; Tang so thu hai
    inc al
    cmp al,'9'         ; So thu hai vuot qua '9' ?
    jg inc_third
    mov score[2],al
    ret
    
inc_third:
    mov score[2],'0'   ; Dua so thu hai ve '0'
    mov al,score[1]    ; Tang so thu ba
    inc al
    cmp al,'9'         ; So thu ba vuot qua '9' ?
    jg inc_fourth
    mov score[1],al
    ret
    
inc_fourth:
    mov score[1],'0'   ; Dua so thu ba ve '0'
    mov al,score[0]    ; Tang so thu tu
    inc al             ; 
    mov score[0],al
    ret
     
scoreplus endp

show_new_head proc    ; print the new head of snake
    
    mov     dx, snake[0]        
    mov     ah, 02h     ; Di chuyen con cho den vi tri dx        
    int     10h
    mov     al, 002     ; 001 la mot dot cua than ran, xem bang ma ascii     
    mov     ah, 09h 
    mov     bl, 0Ah 
    mov     bh,01h      ; Ham 09h cua ngat 10h in 1 ki tu tai vi tri con tro
    mov     cx, 1       ; al chua ki tu can ve
    int     10h         ; bl chua mau cua ki tu can ve ; xem mau trong BIOS color attribute
    ret                 ; cx chi dinh so luong ki tu can ve
show_new_head endp

.exit
end