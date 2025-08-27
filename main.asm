; menu.asm - NASM .COM menu para tarea Assembly 8086
org 100h

menu_loop:
    ; mostrar menu
    mov ah, 09h
    lea dx, menuMsg
    int 21h

    ; leer opcion, esta luego es almacenada en AL
    mov ah, 01h
    int 21h
    
    ; comparar numero de entrada
    cmp al, '1'
    je ingreso_loop    
    
    cmp al, '2'
    je mostrar_estats_loop    
    
    cmp al, '3'
    je buscar_loop   
    
    cmp al, '4'
    je ordenar_loop
    
    cmp al, '5'
    je exit_program
    
    jmp menu_loop  
  
  
  
; ------------------------
; 1. Ingreso de Estudiante
; ------------------------
ingreso_loop:   ; Loop para seguir ingresando estudiantes  

    ; Mostrar mensaje de instruccion
    mov ah, 09h
    lea dx, ingreseMsg
    int 21h
    
    ; Leer cadena
    lea dx, datosIngreso; Lea e ingrese en datosIngreso
    mov ah, 0Ah ; Leer datos de teclado hasta presionar Enter y guardar en AL, dado por el formato de datosIngreso
    int 21h

    ; Revisar si fue '0'
    mov al, [datosIngreso+2]   ; primer caracter ingresado, ya que la estructura de datosIngreso
    ; indica que el primer caracter del string esta en Byte 2.
    cmp al, '0' ; Verifica si AL tiene 0 
    
    
    ; Salto de linea
    mov ah, 02h  ; Escribir un solo caracter en la salida estandar
    mov dl, 0Dh  ; Se carga 0Dh en DL, Carriage Return, devuelve al inicio de linea actual  
    int 21h      
    mov ah, 02h  ; Escribir un solo carÃ¡cter en la salida estandar
    mov dl, 0Ah  ; Se carga 0Ah que es Avance de Linea, avanza siguiente fila
    int 21h  
    
    je menu_loop ; Se ejecuta solo si AL tiene 0
    
    
    ; Confirmar dato
    mov ah, 09h
    lea dx, confirmMsg
    int 21h
    
    ; Guardar datos de ingreso en memoria (variable nombres) 
    CALL guardar_datos
      
    ; Volver a inicio del loop
    jmp ingreso_loop
        
    
guardar_datos PROC
    mov al, contador_estudiantes
    mov actu_index, al       ; guardamos indice actual

    mov al, actu_index
    mov bl, largo_nombre
    mul bl                   ; AX = index * 30

    lea di, nombres
    add di, ax               ; DI = nombres + index*30

    lea si, datosIngreso+2
    mov cl, [datosIngreso+1]
    xor ch, ch               ; CX = longitud real
    rep movsb                ; copiar datos   
    
    ; Incrementar contador
    inc contador_estudiantes
guardar_datos ENDP



; ------------------------
; 2. Mostrar Estadisticas
; ------------------------  
mostrar_estats_loop:
    mov ah, 09h
    lea dx, estadsMsg
    int 21h
    
    ;TODO
    ; Haber hecho ingreso de estudiantes en memoria para acceder a las notas
    ; Promedio general
    ; Nota max y minima
    ; Cantidad y porcentaje de estudiantes aprobados (<=70)
    ; Cantidad y porcentaje de estudiantes reprobados (>70)    
    
    jmp menu_loop ; Por el momento se devuelve al loop principal
  
; ------------------------
; 3. Buscar Estudiante
; ------------------------

buscar_loop:
    mov ah, 09h
    lea dx, buscarMsg
    int 21h      
    
    ; Leer cadena
    lea dx, indice_busqueda
    mov ah, 0Ah ; Leer datos de teclado hasta presionar Enter y guardar en AL
    int 21h

    ; Revisar si fue '0'
    mov al, [indice_busqueda+2]   
    cmp al, '0' ; Verifica si AL tiene 0 

    ; salto de linea
    mov ah, 02h 
    mov dl, 0Dh 
    int 21h      
    mov ah, 02h 
    mov dl, 0Ah 
    int 21h  
    
    je menu_loop ; Si es cero se devuelve   
    
    ; Confirmar dato
    mov ah, 09h
    lea dx, confirmMsg
    int 21h
    
    jmp buscar_loop 
    
    ; TODO:
    ; Verificar que entre un entero mayor que 0
    ; Ubicar estudiante por medio de indice
    ; Imprimir informacion de estudiante en vez de confirmMsg
 
; -------------------------
; 4. Separar String de numeros (VERSIÓN FUNCIONAL)
; -------------------------
ordenar_loop:
    mov ah, 09h
    lea dx, ordenarMsg
    int 21h  
    
    ; leer opcion
    mov ah, 01h
    int 21h
    
    cmp al, '0'
    je menu_loop
    
    cmp al, '1'
    je separar_numeros  ; Llama a la función de separar
    
    jmp ordenar_loop

separar_numeros:
    call separar_numeros_func
    jmp menu_loop

; --------------------------------------------------
; Subrutina: separar_numeros_func
; --------------------------------------------------
separar_numeros_func proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Inicializar indices
    mov si, offset numeros_string
    mov di, offset enteros_array
    mov bx, offset decimales_array
    mov cx, 0                      ; Contador de numeros
    
procesar_numero:
    ; Reiniciar valores temporales (32 bits para decimal)
    mov word ptr entero_temp, 0
    mov word ptr decimal_temp, 0     ; Parte baja
    mov word ptr decimal_temp + 2, 0 ; Parte alta (32 bits total)
    mov decimal_encontrado, 0
    
leer_entero:
    mov al, [si]
    cmp al, '.'              ; ¿Es punto decimal?
    je encontro_decimal
    cmp al, 13               ; ¿Es carriage return?
    je fin_numero
    cmp al, 10               ; ¿Es new line?
    je fin_numero
    cmp al, '$'              ; ¿Fin del string?
    je terminar_proceso
    
    ; Convertir ASCII a número
    sub al, '0'
    mov ah, 0
    push ax                  ; Guardar nuevo dígito
    
    ; entero_temp = entero_temp * 10
    mov ax, entero_temp
    mov dx, 10
    mul dx
    mov entero_temp, ax
    
    ; entero_temp = entero_temp + nuevo_dígito
    pop ax
    add entero_temp, ax
    
    inc si
    jmp leer_entero

encontro_decimal:
    mov decimal_encontrado, 1
    inc si                   ; Saltar el punto
    
leer_decimal:
    mov al, [si]
    cmp al, 13               ; ¿Es carriage return?
    je fin_numero
    cmp al, 10               ; ¿Es new line?
    je fin_numero
    cmp al, '$'              ; ¿Fin del string?
    je fin_numero
    
    ; Convertir ASCII a número
    sub al, '0'
    mov ah, 0
    push ax                  ; Guardar nuevo dígito
    
    ; decimal_temp = decimal_temp * 10 (32 bits)
    push bx
    push cx
    push dx
    
    ; Multiplicar parte baja (decimal_temp) por 10
    mov ax, word ptr decimal_temp
    mov dx, 10
    mul dx
    mov word ptr decimal_temp, ax
    mov cx, dx              ; Guardar carry
    
    ; Multiplicar parte alta (decimal_temp + 2) por 10 y sumar carry
    mov ax, word ptr decimal_temp + 2
    mov dx, 10
    mul dx
    add ax, cx              ; Sumar el carry de la parte baja
    mov word ptr decimal_temp + 2, ax
    
    pop dx
    pop cx
    pop bx
    
    ; decimal_temp = decimal_temp + nuevo_dígito
    pop ax
    add word ptr decimal_temp, ax
    adc word ptr decimal_temp + 2, 0  ; Sumar carry si hay
    
    inc si
    jmp leer_decimal

fin_numero:
    ; Guardar entero en array (16 bits)
    mov ax, entero_temp
    mov [di], ax
    add di, 2
    
    ; Guardar decimal en array (32 bits - 2 palabras)
    mov ax, word ptr decimal_temp      ; Parte baja
    mov [bx], ax
    mov ax, word ptr decimal_temp + 2  ; Parte alta
    mov [bx + 2], ax
    add bx, 4                         ; Avanzar 4 bytes (32 bits)
    
    ; Mostrar valores para debug
    call mostrar_valores_debug
    
    ; Avanzar puntero (manejar CRLF)
avanzar_puntero:
    mov al, [si]
    cmp al, 13
    jne check_lf
    inc si
    jmp avanzar_puntero
    
check_lf:
    cmp al, 10
    jne check_fin
    inc si
    jmp avanzar_puntero
    
check_fin:
    ; Incrementar contador y verificar límite
    inc cx
    cmp cx, 4               ; Máximo 4 números
    jl procesar_numero
    
terminar_proceso:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
separar_numeros_func endp

; --------------------------------------------------
; Debuger Subrutina: mostrar_valores_debug
; --------------------------------------------------
mostrar_valores_debug proc
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; Mostrar mensaje
    mov ah, 09h
    lea dx, debug_msg
    int 21h
    
    ; Mostrar entero
    mov ax, entero_temp
    call mostrar_numero_16
    
    ; Mostrar separador
    mov ah, 02h
    mov dl, '.'
    int 21h
    
    ; Mostrar decimal (32 bits)
    mov ax, word ptr decimal_temp      ; Parte baja
    mov dx, word ptr decimal_temp + 2  ; Parte alta
    call mostrar_numero_32
    
    ; Nueva línea
    mov ah, 02h
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
mostrar_valores_debug endp

; --------------------------------------------------
; Subrutina mostrar_numero_16 (AX = número 16 bits)
; --------------------------------------------------
mostrar_numero_16 proc
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 10
    mov cx, 0
    
    ; Caso especial: número 0
    cmp ax, 0
    jne convertir_loop_16
    mov dl, '0'
    mov ah, 02h
    int 21h
    jmp fin_mostrar_16
    
convertir_loop_16:
    mov dx, 0
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne convertir_loop_16
    
mostrar_digitos_16:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop mostrar_digitos_16
    
fin_mostrar_16:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
mostrar_numero_16 endp

; --------------------------------------------------
; Subrutina mostrar_numero_32 (DX:AX = número 32 bits)
; --------------------------------------------------
mostrar_numero_32 proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Usar pila para construir el número
    mov cx, 0
    mov bx, 10
    
convertir_loop_32:
    ; Dividir DX:AX por 10
    push ax
    mov ax, dx
    xor dx, dx
    div bx
    mov di, ax      ; DI = cociente alto
    pop ax
    div bx          ; AX = cociente bajo, DX = residuo
    push dx         ; Guardar dígito
    inc cx
    
    ; Mover cociente a DX:AX
    mov dx, di
    
    ; Verificar si el número es cero
    or ax, dx
    jnz convertir_loop_32
    
mostrar_digitos_32:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop mostrar_digitos_32
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
mostrar_numero_32 endp

; --------------------------------------------------
; VARIABLES Y ARRAYS
; --------------------------------------------------
numeros_string db "88.88888", 13, 10
               db "77", 13, 10
               db "99.99999", 13, 10
               db "17.76543", '$'

; Arrays para almacenar los resultados
enteros_array dw 4 dup(0)        ; Array de enteros (16 bits)
decimales_array dw 8 dup(0)      ; Array de decimales (4 números * 2 words cada uno = 8 words)

; Variables temporales
entero_temp dw 0
decimal_temp dw 2 dup(0)         ; 32 bits (2 words: parte baja + parte alta)
decimal_encontrado db 0

; Mensajes
debug_msg db 13,10,"Procesado: $"
; ------------------------
; 5. Salir
; ------------------------
exit_program:
    mov ah, 4Ch
    int 21h   

; ------------------------
; Datos
; ------------------------ 

menuMsg db "Seleccione una opcion por ejecutar:",13,10
     db "1. Ingrese calificacion.",13,10
     db "2. Mostrar estadisticas",13,10
     db "3. Buscar estudiantes (indice)",13,10
     db "4. Ordenar calificaciones",13,10
     db "5. Salir",13,10,'$'
     
ingreseMsg db 13,10,'Por favor ingrese su estudiante o digite 0 para salir al menu principal.',13,10,'$' 
estadsMsg db 13,10,'Se van a mostrar estadisticas de calificaciones. Presione Enter o digite 0 para salir al menu principal.',13,10,'$'
buscarMsg db 13,10,'Se desea buscar un estudiante por medio de indice de ubicaion. Digite el indie o digite 0 para salir al menu principal.',13,10,'$' 
ordenarMsg db 13,10,'Se desean ordenar las calificaciones. Presione 1 para confirmar o digite 0 para salir al menu principal.',13,10,'$' 
ordenarMsg_error db 13,10,'Debe presionar 1 para confirmar o 0 para voler al menu',13,10,'$' 
confirmMsg db 13,10,'Dato recibido.',13,10,'$'  
  

; Datos de ingreso de estudiante
datosIngreso db 50       ; 1. Byte 0: Capacidad Maxima
            db ?         ; 2. Byte 1: Longitud Real (la llena DOS)
            db 50 dup(?) ; 3. Byte 2 al 11: Los caracteres ingresados
                                                                       
; Al buscar un estudiante aqui se almacena el indice                                                                       
indice_busqueda db 5    ; 1. Byte 0: Capacidad Maxima
            db ?        ; 2. Byte 1: Longitud Real (la llena DOS)
            db 5 dup(?) ; 3. Byte 2 al 11: Los caracteres ingresados
            

; Contador de estudiantes index actual                                              
contador_estudiantes DB 0    ; inicia en 0, max 15
actu_index DB 0               ; el index actual

                                              
; Arreglos para almacenar datos de estudiantes 

; 15 nombres, 30 chars cada uno
nombres DB 15 DUP(30 DUP('$'))  

; 15 enteros (parte antes del punto)
enteros DW 15 DUP(0)

; 15 decimales (parte despues del punto)
decimales DW 15 DUP(0)

; Variavles constantes
largo_nombre EQU 30
max_estudi EQU 15                       