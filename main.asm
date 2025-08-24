org 100h

menu_loop:
    mov ah, 09h
    lea dx, menuMsg
    int 21h

    mov ah, 01h
    int 21h

    cmp al, '1'
    je say_hola
    cmp al, '2'
    je exit_program
    jmp menu_loop

say_hola:
    mov ah, 09h
    mov dx, holaMsg
    int 21h
    jmp menu_loop

exit_program:
    mov ah, 4Ch
    int 21h

menuMsg db 13,10,'Menu:',13,10,'1. Hola',13,10,'2. Exit',13,10,'$'
holaMsg db 13,10,'Hola!',13,10,'$'
