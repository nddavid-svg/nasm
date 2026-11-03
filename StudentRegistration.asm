; StudentRegistration.asm
; NASM 32-bit Linux
; COR with INPUT, OUTPUT, WRITE, READ, and EXIT
; Uses MACROS and PROCEDURES

BITS 32
GLOBAL _start

%macro print_text 2
    mov ecx, %1
    mov edx, %2
    call print_proc
%endmacro

%macro input_detail 3
    print_text %1, %2
    mov ecx, %3
    call read_line
%endmacro

%macro show_detail 3
    print_text %1, %2
    mov ecx, %3
    call print_string
    print_text newline, 1
%endmacro

section .data
    UNIT_PRICE equ 1000
    LAB_PRICE equ 500

    menu db 10, "===============================", 10
         db "              COR", 10
         db "===============================", 10
         db "1. Input  - Input student details and fee details", 10
         db "2. Output - Display the full information", 10
         db "3. Write  - Write the full details into a file", 10
         db "4. Read   - Read the contents of the file", 10
         db "5. Exit", 10
         db "Enter your choice: "
    menu_len equ $ - menu

    header db "========================================", 10
           db "       CERTIFICATE OF REGISTRATION", 10
           db "========================================", 10
    header_len equ $ - header

    student_label db "Student#: "
    student_len equ $ - student_label

    name_label db "Name (Full Name): "
    name_len equ $ - name_label

    phone_label db "Phone: "
    phone_len equ $ - phone_label

    college_label db "College: "
    college_len equ $ - college_label

    program_label db "Program: "
    program_len equ $ - program_label

    year_label db "Year Level: "
    year_len equ $ - year_label

    address_label db "Address: "
    address_len equ $ - address_label

    details_title db 10, "---------- STUDENT DETAILS ----------", 10
    details_title_len equ $ - details_title

    units_prompt db 10, "Enter total number of units: "
    units_prompt_len equ $ - units_prompt

    labs_prompt db "Enter number of laboratory subjects: "
    labs_prompt_len equ $ - labs_prompt

    subjects_list db 10
        db "===================== SUBJECT LIST =====================", 10
        db "Course Code  Subject Title", 10
        db "--------------------------------------------------------", 10
        db "CCS0021      INFORMATION MANAGEMENT (LEC)", 10
        db "CCS0021L     INFORMATION MANAGEMENT (LAB)", 10
        db "CS0001       DISCRETE STRUCTURES 1", 10
        db "CS0003       COMPUTER SYSTEMS & ARCHITECTURE", 10
        db "CS0003L      COMPUTER SYSTEMS & ARCHITECTURE (LAB)", 10
        db "CS0070       OBJECT ORIENTED PROGRAMMING", 10
        db "CS0070L      OBJECT ORIENTED PROGRAMMING-LAB", 10
        db "GED0021      SPECIALIZED ENGLISH PROGRAM 2", 10
        db "GED0075      LINEAR ALGEBRA", 10
        db "GED0081      COLLEGE PHYSICS 1 LECTURE", 10
        db "GED0081L     COLLEGE PHYSICS 1 LABORATORY", 10
        db "========================================================", 10
    subjects_list_len equ $ - subjects_list

    summary db 10, "----------- FEE SUMMARY -----------", 10
            db "Price per unit: PHP 1000.00", 10
            db "Fee per laboratory subject: PHP 500.00", 10
    summary_len equ $ - summary

    units_label db "Total Units: "
    units_label_len equ $ - units_label

    labs_label db "Laboratory Subjects: "
    labs_label_len equ $ - labs_label

    tuition_label db "Tuition Fee: PHP "
    tuition_label_len equ $ - tuition_label

    lab_fee_label db "Laboratory Fee: PHP "
    lab_fee_label_len equ $ - lab_fee_label

    total_label db "TOTAL AMOUNT PAYABLE: PHP "
    total_label_len equ $ - total_label

    money_end db ".00", 10
    money_end_len equ $ - money_end

    invalid_msg db "Invalid input. Enter a nonnegative whole number: "
    invalid_len equ $ - invalid_msg

    overflow_msg db "Fee total is too large. Enter smaller counts.", 10
    overflow_len equ $ - overflow_msg

    choice_error db "Invalid choice. Enter one number from 1 to 5.", 10
    choice_error_len equ $ - choice_error

    text_error db "Invalid input. Use at most 127 printable bytes. Try again: "
    text_error_len equ $ - text_error

    missing_msg db "Select option 1 and enter student information first.", 10
    missing_len equ $ - missing_msg

    input_ok db "Student information and fees recorded successfully.", 10
    input_ok_len equ $ - input_ok

    write_ok db "Full details saved to StudentRegistration.txt", 10
    write_ok_len equ $ - write_ok

    file_error db "File operation failed. Check the file and folder permissions.", 10
    file_error_len equ $ - file_error

    read_heading db 10, "---------- SAVED FILE CONTENTS ----------", 10
    read_heading_len equ $ - read_heading

    goodbye db "Program ended.", 10
    goodbye_len equ $ - goodbye

    input_error db 10, "Unable to read terminal input.", 10
    input_error_len equ $ - input_error

    filename db "StudentRegistration.txt", 0

    newline db 10

    output_fd dd 1
    record_ready db 0
    output_failed db 0

section .bss
    student_no resb 128
    full_name resb 128
    phone resb 128
    college resb 128
    program resb 128
    year_level resb 128
    address resb 128

    menu_choice resb 128
    number_input resb 128
    input_char resb 1
    number_output resb 12

    total_units resd 1
    lab_subjects resd 1
    tuition_fee resd 1
    laboratory_fee resd 1
    total_fee resd 1

    file_handle resd 1
    file_buffer resb 1024

section .text

_start:
    cld

main_menu:
    mov dword [output_fd], 1
    mov byte [output_failed], 0

    print_text menu, menu_len

    mov ecx, menu_choice
    call read_line

    ; Require exactly one character.
    cmp byte [menu_choice], 0
    je invalid_menu

    cmp byte [menu_choice + 1], 0
    jne invalid_menu

    mov al, [menu_choice]

    cmp al, '1'
    je choose_input

    cmp al, '2'
    je choose_output

    cmp al, '3'
    je choose_write

    cmp al, '4'
    je choose_read

    cmp al, '5'
    je exit_program

invalid_menu:
    print_text choice_error, choice_error_len
    jmp main_menu

choose_input:
    call input_information
    jmp main_menu

choose_output:
    cmp byte [record_ready], 1
    jne no_record

    call display_information
    jmp main_menu

choose_write:
    cmp byte [record_ready], 1
    jne no_record

    call write_information
    jmp main_menu

choose_read:
    call read_information
    jmp main_menu

no_record:
    print_text missing_msg, missing_len
    jmp main_menu

; ==================================================
; INPUT PROCEDURE
; ==================================================
input_information:
    mov byte [record_ready], 0

    print_text details_title, details_title_len

    input_detail student_label, student_len, student_no
    input_detail name_label, name_len, full_name
    input_detail phone_label, phone_len, phone
    input_detail college_label, college_len, college
    input_detail program_label, program_len, program
    input_detail year_label, year_len, year_level
    input_detail address_label, address_len, address

.fees:
    print_text units_prompt, units_prompt_len
    call read_integer
    mov [total_units], eax

    print_text labs_prompt, labs_prompt_len
    call read_integer
    mov [lab_subjects], eax

    call compute_fees
    jc .overflow

    mov byte [record_ready], 1

    print_text input_ok, input_ok_len
    ret

.overflow:
    print_text overflow_msg, overflow_len
    jmp .fees

; ==================================================
; OUTPUT PROCEDURE
; Shared by terminal display and file writing.
; ==================================================
display_information:
    print_text header, header_len
    print_text details_title, details_title_len

    show_detail student_label, student_len, student_no
    show_detail name_label, name_len, full_name
    show_detail phone_label, phone_len, phone
    show_detail college_label, college_len, college
    show_detail program_label, program_len, program
    show_detail year_label, year_len, year_level
    show_detail address_label, address_len, address

    print_text subjects_list, subjects_list_len
    print_text summary, summary_len

    print_text units_label, units_label_len
    mov eax, [total_units]
    call print_number
    print_text newline, 1

    print_text labs_label, labs_label_len
    mov eax, [lab_subjects]
    call print_number
    print_text newline, 1

    print_text tuition_label, tuition_label_len
    mov eax, [tuition_fee]
    call print_number
    print_text money_end, money_end_len

    print_text lab_fee_label, lab_fee_label_len
    mov eax, [laboratory_fee]
    call print_number
    print_text money_end, money_end_len

    print_text total_label, total_label_len
    mov eax, [total_fee]
    call print_number
    print_text money_end, money_end_len
    ret

; ==================================================
; WRITE PROCEDURE
; Creates or replaces StudentRegistration.txt.
; ==================================================
write_information:
.open:
    mov eax, 5                  ; sys_open
    mov ebx, filename
    mov ecx, 577                ; WRONLY | CREAT | TRUNC
    mov edx, 384                ; Permissions: 0600
    int 0x80

    cmp eax, -4                 ; EINTR
    je .open

    test eax, eax
    js .error

    mov [file_handle], eax
    mov [output_fd], eax
    mov byte [output_failed], 0

    call display_information

    ; Restore terminal output before printing messages.
    mov dword [output_fd], 1

    mov eax, 6                  ; sys_close
    mov ebx, [file_handle]
    int 0x80

    test eax, eax
    js .error

    cmp byte [output_failed], 0
    jne .error

    print_text write_ok, write_ok_len
    ret

.error:
    mov dword [output_fd], 1
    print_text file_error, file_error_len
    ret

; ==================================================
; READ PROCEDURE
; Displays the saved file without changing the record.
; ==================================================
read_information:
.open:
    mov eax, 5                  ; sys_open
    mov ebx, filename
    xor ecx, ecx                ; O_RDONLY
    int 0x80

    cmp eax, -4
    je .open

    test eax, eax
    js .error

    mov [file_handle], eax
    mov dword [output_fd], 1
    mov byte [output_failed], 0

    print_text read_heading, read_heading_len

.next:
    mov eax, 3                  ; sys_read
    mov ebx, [file_handle]
    mov ecx, file_buffer
    mov edx, 1024
    int 0x80

    cmp eax, -4
    je .next

    test eax, eax
    js .close_error

    jz .close

    mov ecx, file_buffer
    mov edx, eax
    call print_proc

    cmp byte [output_failed], 0
    jne .close_error

    jmp .next

.close:
    mov eax, 6                  ; sys_close
    mov ebx, [file_handle]
    int 0x80

    test eax, eax
    js .error

    print_text newline, 1
    ret

.close_error:
    mov eax, 6
    mov ebx, [file_handle]
    int 0x80

.error:
    mov dword [output_fd], 1
    print_text file_error, file_error_len
    ret

; ==================================================
; PRINT PROCEDURE
; ECX = address, EDX = byte count.
; Preserves registers and handles partial writes.
; ==================================================
print_proc:
    pushad

    mov ebx, [output_fd]

.write:
    test edx, edx
    jz .done

    mov eax, 4                  ; sys_write
    int 0x80

    cmp eax, -4
    je .write

    test eax, eax
    jle .failed

    add ecx, eax
    sub edx, eax
    jmp .write

.failed:
    mov byte [output_failed], 1

.done:
    popad
    ret

; ==================================================
; READ LINE PROCEDURE
; ECX = destination, capacity = 128 bytes.
; Reads at most 127 bytes plus a null terminator.
; Drains and rejects oversized or control input.
; EOF exits cleanly.
; ==================================================
read_line:
    pushad
    mov edi, ecx

.retry:
    xor esi, esi
    xor ebp, ebp

.read:
    mov eax, 3
    xor ebx, ebx
    mov ecx, input_char
    mov edx, 1
    int 0x80

    cmp eax, -4
    je .read

    test eax, eax
    js terminal_input_error
    jz .eof

    mov al, [input_char]

    cmp al, 10
    je .finish

    cmp al, 13
    je .read

    cmp al, 32
    jb .invalid

    cmp al, 127
    je .invalid

    cmp esi, 127
    jae .invalid

    mov [edi + esi], al
    inc esi
    jmp .read

.invalid:
    mov ebp, 1
    jmp .read

.finish:
    test ebp, ebp
    jnz .reject

    mov byte [edi + esi], 0
    popad
    ret

.reject:
    print_text text_error, text_error_len
    jmp .retry

.eof:
    test ebp, ebp
    jnz exit_program

    test esi, esi
    jnz .finish

    jmp exit_program

; ==================================================
; PRINT NULL-TERMINATED STRING
; ==================================================
print_string:
    push edx
    xor edx, edx

.count:
    cmp byte [ecx + edx], 0
    je .display

    inc edx
    jmp .count

.display:
    call print_proc
    pop edx
    ret

; ==================================================
; READ NONNEGATIVE INTEGER
; Accepts 0 through 2147483647.
; Rejects blank, negative, nonnumeric, or overflow input.
; ==================================================
read_integer:
.retry:
    mov ecx, number_input
    call read_line

    xor eax, eax
    mov esi, number_input

    cmp byte [esi], 0
    je .invalid

.convert:
    movzx edx, byte [esi]

    test edx, edx
    jz .done

    cmp edx, '0'
    jb .invalid

    cmp edx, '9'
    ja .invalid

    sub edx, '0'

    imul eax, eax, 10
    jo .invalid

    add eax, edx
    jo .invalid

    inc esi
    jmp .convert

.invalid:
    print_text invalid_msg, invalid_len
    jmp .retry

.done:
    ret

; ==================================================
; COMPUTE FEES
; Tuition = units * 1000
; Laboratory = laboratory subjects * 500
; Total = tuition + laboratory
; CF = 1 if the signed 32-bit amount would overflow.
; ==================================================
compute_fees:
    mov eax, [total_units]
    imul eax, eax, UNIT_PRICE
    jo .overflow
    mov [tuition_fee], eax

    mov eax, [lab_subjects]
    imul eax, eax, LAB_PRICE
    jo .overflow
    mov [laboratory_fee], eax

    add eax, [tuition_fee]
    jo .overflow
    mov [total_fee], eax

    clc
    ret

.overflow:
    stc
    ret

; ==================================================
; PRINT NUMBER
; EAX = nonnegative integer.
; ==================================================
print_number:
    pushad

    mov edi, number_output + 12
    mov ebx, 10
    xor ecx, ecx

.convert:
    xor edx, edx
    div ebx

    add dl, '0'
    dec edi
    mov [edi], dl
    inc ecx

    test eax, eax
    jnz .convert

    mov edx, ecx
    mov ecx, edi
    call print_proc

    popad
    ret

terminal_input_error:
    mov dword [output_fd], 1
    print_text input_error, input_error_len

    mov eax, 1
    mov ebx, 1
    int 0x80

exit_program:
    mov dword [output_fd], 1
    print_text goodbye, goodbye_len

    mov eax, 1
    xor ebx, ebx
    int 0x80

section .note.GNU-stack noalloc noexec nowrite progbits