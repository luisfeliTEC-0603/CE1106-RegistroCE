org 100h

jmp menu_loop

; =====================================================
; Datos del programa
; =====================================================

; ------------------------
; Constantes
; ------------------------
estuMax    equ 15        ; Capacidad máxima de estudiantes
estuBytes  equ 30        ; Cada estudiante ocupa 30 bytes:
                         ; 10 [nombre] + 10 [apellido1] + 10 [apellido2]

notasInt   dw estuMax dup(0)
notasFrac  dw estuMax dup(0) 

; ------------------------
; Buffers / Estructuras
; ------------------------
lstEstu   db estuMax * estuBytes dup(0)   ; Lista lineal de estudiantes
estuCtl   dw 0                           ; Contador de estudiantes actuales

datosIngreso db 50        ; [0] Capacidad máxima (50)
             db ?         ; [1] Longitud real (la llena DOS)
             db 50 dup(0) ; [2..51] Datos ingresados por el usuario

; ------------------------
; Mensajes
; ------------------------
menuMsg    db "Seleccione una opcion por ejecutar:",13,10
           db "1. Ingrese calificacion.",13,10
           db "2. Mostrar estadisticas",13,10
           db "3. Buscar estudiantes (indice)",13,10
           db "4. Ordenar calificaciones",13,10
           db "5. Salir",13,10,'$'

ingreseMsg db 13,10,"Por favor ingrese su estudiante o digite 9 para salir al menu principal.",13,10,'$'

estadsMsg  db 13,10,"Se van a mostrar estadisticas de calificaciones. Presione Enter o digite 9 para salir al menu principal.",13,10,'$'

buscarMsg  db 13,10,"Se desea buscar un estudiante por medio de indice de ubicacion. Digite el indice y presione Enter o digite ESC para salir al menu principal.",13,10,'$'

ordenarMsg db 13,10,"Se desean ordenar las calificaciones. Presione Enter o digite 9 para salir al menu principal.",13,10,'$'

confirmMsg db 13,10,"Dato recibido.",13,10,'$'

ingreso_nombreMsg db "Nombre del Estudiante: ", 13, 10, '$'
ingreso_notaMsg   db "Nota del Estudiante: ", 13, 10, '$'

; =====================================================
; Implementación del Código
; =====================================================

; ------------------------
; Código principal
; ------------------------
menu_loop:

    ; mostrar menu
    mov ah, 09h
    lea dx, menuMsg
    int 21h

    ; leer opcion
    mov ah, 01h
    int 21h
    
    ; comparar opcion
    cmp al, '1'
    je ingreso_loop    
    
    cmp al, '2'
    je mostrar_estads    
    
    cmp al, '3'
    je buscar_estud   

    cmp al, '4'
    je ordenar_calif
    
    cmp al, '5'
    je exit_program

    jmp menu_loop  

; ------------------------
; 1. Ingreso de Estudiante
; ------------------------
ingreso_loop:
    ; Mostrar mensaje
    mov ah, 09h
    lea dx, ingreseMsg
    int 21h

    mov ah, 09h
    lea dx, ingreso_nombreMsg
    int 21h

    ; Leer línea
    lea dx, datosIngreso
    mov ah, 0Ah
    int 21h

    ; Chequear si ESC
    cmp byte [datosIngreso+2], 1Bh
    je menu_loop

guardar_nombre_apellido:
    ; Calcular destino = estuCtl * estuBytes
    mov al, estuCtl
    mov bx, estuBytes
    mul bx
    mov di, ax

    ; Copiar hasta 20 chars desde buffer
    lea si, datosIngreso+2
    mov cl, [datosIngreso+1]   ; longitud
    mov ch, 0
    cmp cx, 30
    jbe .ok_len
    mov cx, 30
.ok_len:
    rep movsb

    ; Rellenar si es menos de 20
    mov cx, 30
    sub cx, [datosIngreso+1]
    jbe guardar_notas
    mov al, ' '
    rep stosb

guardar_notas:
    mov ah, 09h
    lea dx, ingreso_notaMsg 
    int 21h

    ; Leer línea
    lea dx, datosIngreso
    mov ah, 0Ah
    int 21h

    ; Chequear si ESC
    cmp byte [datosIngreso+2], 1Bh
    je menu_loop

    lea si, datosIngreso+2

    ; Vciar registros
    xor ax, ax
    xor dx, dx

.conv_int:
    lodsb           ; AL = siguiente caracter del buffer (SI apunta al string)
    cmp al, '.'
    je .guardar_int   ; si encontramos el punto, pasamos a la parte decimal
    cmp al, 0Dh
    je .guardar_int ; si es Enter, fin de la entrada
    sub al, '0'     ; convertir ASCII a número
    mov bl, al
    xor bh, bh
    mov cx, 10
    mul cx          ; AX = AX * 10
    add ax, bx      ; AX += digito
    jmp .conv_int    
.guardar_int:
    mov bx, estuCtl
    shl bx, 1               ; cada dw ocupa 2 bytes
    mov notasInt[bx], ax

    cmp al, '.'
    jne .skip_fill

.conv_fracc:
    xor dx, dx          ; DX = acumulador de la fracción
    mov cx, 4           ; máximo 4 decimales, opcional

.fracc_loop:
    lodsb
    cmp al, 0Dh         ; Enter?
    je .guardar_fracc
    sub al, '0'         ; ASCII -> número 0..9
    mov ax, dx
    mov bx, 10
    mul bx               ; AX = DX*10
    add ax, ax           ; ❌ incorrecto, vamos a usar mejor:
    add ax, 0            ; no sumes nada aquí
    add dx, ax           ; DX = DX*10 + digito
    loop .fracc_loop     ; opcional si limitas decimales
    jmp .fracc_loop

.guardar_fracc:
    mov bx, estuCtl
    shl bx, 1
    mov notasFrac[bx], dx

.skip_fill:
   
    mov ax, [estuCtl]
    inc ax
    mov [estuCtl], ax

    ; Confirmar
    mov ah, 09h
    lea dx, confirmMsg
    int 21h

    jmp ingreso_loop

; ------------------------
; 2. Mostrar Estadisticas
; ------------------------  
mostrar_estads:
    mov ah, 09h
    lea dx, estadsMsg
    int 21h
    jmp menu_loop
  
; ------------------------
; 3. Buscar Estudiante
; ------------------------

buscar_estud:
    mov ah, 09h
    lea dx, buscarMsg
    int 21h
    jmp menu_loop

; -------------------------
; 4. Ordenar Calificaciones
; -------------------------
ordenar_calif:
    mov ah, 09h
    lea dx, ordenarMsg
    int 21h
    jmp menu_loop
  
; ------------------------
; 5. Salir
; ------------------------
exit_program:
    mov ah, 4Ch
    int 21h

; --------------------------------------------------
; CheckEsc
; Entrada: AL = tecla presionada
; Salida: AL = 1 si es ESC, AL = 0 si no
; --------------------------------------------------
CheckEsc:
    cmp al, 1Bh ; 1Bh = eSC
    je .es_esc
    mov al, 0
    ret
.es_esc:
    mov al, 1
    ret
