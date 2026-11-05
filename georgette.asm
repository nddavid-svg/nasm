; NASM 32-bit Linux. Uses int 80h system calls; no C library needed.
BITS 32
global _start

%macro PRINT 2
    mov ebx, 1
    mov ecx, %1
    mov edx, %2
    call write_all
%endmacro

%macro SAVE 2
    mov ebx, [receipt_fd]
    mov ecx, %1
    mov edx, %2
    call write_all
%endmacro

section .data
    filename db 'receipt.txt', 0
    receipt_fd dd -1

    prices db 'A. Rice : Plain Rice          Php 5.00', 10
           db 'B. Rice : Java Rice           Php 10.00', 10
           db 'C. Ulam 1: (Fish)             Php 35.00', 10
           db 'D. Ulam 2: (Pork)             Php 50.00', 10
           db 'E. Ulam 3: (Vegetables)        Php 20.00', 10
           db 'F. Dessert: Saging con yelo   Php 60.00', 10
    prices_len equ $ - prices

    menu db 10, '+------------Georgette EATERY------------+', 10
         db ': A. Rice : Plain Rice                   :', 10
         db ': B. Rice : Java Rice                    :', 10
         db ': C. Ulam 1: (Fish)                      :', 10
         db ': D. Ulam 2: (Pork)                      :', 10
         db ': E. Ulam 3: (Vegetables)                :', 10
         db ': F. Dessert: Saging con yelo            :', 10
         db '+----------------------------------------+', 10
         db 'Enter your order: '
    menu_len equ $ - menu
    again db 'Do you want to order again? [Y/N]: '
    again_len equ $ - again
    invalid_item db 'Invalid choice. Enter one letter from A to F.', 10
    invalid_item_len equ $ - invalid_item
    invalid_again db 'Invalid answer. Enter Y or N.', 10
    invalid_again_len equ $ - invalid_again
    ordered db 'You ordered '
    ordered_len equ $ - ordered
    heading db '     Receipt', 10
    heading_len equ $ - heading
    thanks db 'Thank you! Please come again!', 10
    thanks_len equ $ - thanks
    receipt_label db 10
    receipt_label_len equ $ - receipt_label
    error_msg db 'Error: input/output operation failed.', 10
    error_msg_len equ $ - error_msg

    item_a db 'Plain Rice:  Php 5.00', 10
    item_a_len equ $ - item_a
    item_b db 'Java Rice:  Php 10.00', 10
    item_b_len equ $ - item_b
    item_c db 'Fish:  Php 35.00', 10
    item_c_len equ $ - item_c
    item_d db 'Pork:  Php 50.00', 10
    item_d_len equ $ - item_d
    item_e db 'Vegetables:  Php 20.00', 10
    item_e_len equ $ - item_e
    item_f db 'Saging con yelo:  Php 60.00', 10
    item_f_len equ $ - item_f

    item_ptrs dd item_a, item_b, item_c, item_d, item_e, item_f
    item_lens dd item_a_len, item_b_len, item_c_len
              dd item_d_len, item_e_len, item_f_len

section .bss
    input_byte resb 1
    first_char resb 1
    receipt_buffer resb 512

section .text
_start:
    ; open(filename, O_WRONLY | O_CREAT | O_TRUNC, 0644)
    ; Each run creates a fresh receipt.
    mov eax, 5
    mov ebx, filename
    mov ecx, 577
    mov edx, 0o644
    int 0x80
    test eax, eax
    js io_error
    mov [receipt_fd], eax
    SAVE heading, heading_len
    PRINT prices, prices_len

.menu_loop:
    call display_menu
    call read_choice
    cmp eax, -1
    je finish
    cmp eax, 'A'
    jb .bad_item
    cmp eax, 'F'
    ja .bad_item
    sub eax, 'A'
    call record_order

.ask_again:
    PRINT again, again_len
    call read_choice
    cmp eax, -1
    je finish
    cmp eax, 'Y'
    je .menu_loop
    cmp eax, 'N'
    je finish
    PRINT invalid_again, invalid_again_len
    jmp .ask_again

.bad_item:
    PRINT invalid_item, invalid_item_len
    jmp .menu_loop

finish:
    call close_receipt
    PRINT thanks, thanks_len
    PRINT receipt_label, receipt_label_len
    call display_receipt
    mov eax, 1                  ; sys_exit(0)
    xor ebx, ebx
    int 0x80

display_menu:
    PRINT menu, menu_len
    ret

; EAX = item index (0..5). Show and save the same item line.
record_order:
    push esi
    push edi
    mov esi, [item_ptrs + eax*4]
    mov edi, [item_lens + eax*4]
    PRINT ordered, ordered_len
    PRINT esi, edi
    SAVE esi, edi
    pop edi
    pop esi
    ret

; Read one complete line, so leftover characters cannot answer the
; next prompt. Accept exactly one character, ignoring carriage returns.
; Returns uppercase ASCII, 0 for invalid input, or -1 for EOF.
read_choice:
    push esi
    xor esi, esi
.read:
    mov eax, 3                  ; sys_read(stdin, input_byte, 1)
    xor ebx, ebx
    mov ecx, input_byte
    mov edx, 1
    int 0x80
    cmp eax, -4                 ; Retry an interrupted system call.
    je .read
    test eax, eax
    js io_error
    jz .eof
    mov al, [input_byte]
    cmp al, 10
    je .line_done
    cmp al, 13
    je .read
    test esi, esi
    jnz .extra
    mov [first_char], al
    inc esi
    jmp .read
.extra:
    mov esi, 2                  ; Mark multiple characters as invalid.
    jmp .read
.eof:
    test esi, esi
    jnz .line_done
    mov eax, -1
    jmp .return
.line_done:
    xor eax, eax
    cmp esi, 1
    jne .return
    movzx eax, byte [first_char]
    cmp al, 'a'
    jb .return
    cmp al, 'z'
    ja .return
    sub eax, 32
.return:
    pop esi
    ret

; EBX = descriptor, ECX = bytes, EDX = length.
; Handle partial writes and preserve the caller's registers.
write_all:
    pushad
.write:
    test edx, edx
    jz .done
    mov eax, 4                  ; sys_write
    int 0x80
    cmp eax, -4
    je .write
    test eax, eax
    jle io_error
    add ecx, eax
    sub edx, eax
    jmp .write
.done:
    popad
    ret

close_receipt:
    mov eax, 6                  ; sys_close
    mov ebx, [receipt_fd]
    int 0x80
    mov dword [receipt_fd], -1
    test eax, eax
    js io_error
    ret

; Reopen the saved file and display its actual contents.
display_receipt:
    mov eax, 5                  ; sys_open(filename, O_RDONLY)
    mov ebx, filename
    xor ecx, ecx
    int 0x80
    test eax, eax
    js io_error
    mov [receipt_fd], eax
.read:
    mov eax, 3
    mov ebx, [receipt_fd]
    mov ecx, receipt_buffer
    mov edx, 512
    int 0x80
    cmp eax, -4
    je .read
    test eax, eax
    js io_error
    jz .done
    PRINT receipt_buffer, eax
    jmp .read
.done:
    call close_receipt
    ret

io_error:
    ; Report to stderr directly to avoid recursive error handling.
    mov eax, 4
    mov ebx, 2
    mov ecx, error_msg
    mov edx, error_msg_len
    int 0x80
    mov ebx, [receipt_fd]
    cmp ebx, -1
    je .exit
    mov eax, 6
    int 0x80
.exit:
    mov eax, 1
    mov ebx, 1
    int 0x80
