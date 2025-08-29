.MODEL SMALL
.STACK 100H

.DATA
indSize     EQU 30
grdSize     EQU 10
indMax      EQU 15

indBuffer  DB indSize    ; size maximo
           DB ?          ; caracteres leidos
           DB indSize+2 DUP(0)  ; buffer real
           
grdBuffer   DB grdSize
            DB ?
            DB grdSize+2 DUP(0)

indLst      DB indMax * (indSize+1) DUP('$')  ; Forma correcta
grdLst      DB indMax * (grdSize+1) DUP('$')

cnt         DB 0

; --- Msgs & Display Prompts ---
msgMenu     DB 13, 10, '-------------< CE1106 - REGISTRATION >---------------', 13, 10
            DB      '------------------< MAIN MENU >----------------------',  13, 10
            DB      '| 1. Add Student and Grade                          |', 13, 10
            DB      '| 2. Display Stats                                  |', 13, 10
            DB      '| 3. Search Student with Index                      |', 13, 10 
            DB      '| 4. Order Grades (ASC/DESC)                        |', 13, 10
            DB      '| 5. Display Uploaded Data                          |', 13, 10
            DB      '| 0. Exit Program                                   |', 13, 10
            DB      '-----------------------------------------------------', 13, 10
            DB      '                                                     ', 13, 10
            DB      'Input: $'

msgNombre DB 13, 10, 'Ingrese nombre completo: $'
msgNota   DB 13, 10, 'Ingrese nota: $'
msgLista  DB 13, 10, 'Lista de Estudiantes:', 13, 10, '-------------------', 13, 10, '$'
msgEncabezado DB 'No.  Nombre', 9,9,'Nota$'  ; Mejorado
msgSeparador DB 13, 10, '----------------------------------------', 13, 10, '$'
newline   DB 13, 10, '$'
tab       DB 09h, '$'

msgOpcionInvalida DB 13, 10, 'Opcion invalida! Presione cualquier tecla...$'
msgMaxAlcanzado DB 13, 10, 'Maximo de estudiantes alcanzado!$'
msgPresioneTecla DB 13, 10, 'Presione cualquier tecla para continuar...$'
debug_msg db 13,10,"Procesado: $"  
msg_aprob     db 'Porcentaje de aprobados: $'
msg_reprob    db 13,10,'Porcentaje de reprobados: $' 
  
  
  
; Arrays para almacenar los resultados
enteros_array    dw indMax dup(0)        ; Array de enteros (16 bits)
decimales_array  dw indMax * 2 dup(0)    ; Array de decimales (indMax * 32 bits)
; Variables temporales 
entero_temp dw 0
decimal_temp dw 2 dup(0)         ; 32 bits (2 words: parte baja + parte alta)
decimal_encontrado db 0
  
; Contadores de aprobaciones
aprobados db 0
desaprobados db 0                             
                              
                              
.CODE
START:
    MOV AX, @DATA
    MOV DS, AX
    MOV ES, AX

MainMenu:
    CALL ClrScreen
    CALL MostrarMenu
    JMP MainMenu

MostrarMenu PROC
    MOV AH, 09h
    LEA DX, msgMenu
    INT 21h

    MOV AH, 01h
    INT 21h

    CMP AL, '1'
    JE Opcion1
    CMP AL, '2'
    JE Opcion2
    CMP AL, '3'
    JE Opcion3
    CMP AL, '4'
    JE Opcion4
    CMP AL, '5'
    JE Opcion5
    CMP AL, '0'
    JE SalirPrograma
    CMP AL, 1Bh
    JE SalirPrograma
    
    MOV AH, 09h
    LEA DX, msgOpcionInvalida
    INT 21h
    MOV AH, 01h
    INT 21h
    RET
MostrarMenu ENDP

Opcion1:
    CALL AgregarEstudiante
    RET

Opcion2:
    CALL separar_numeros_func
    CALL MostrarEstadisticas
    RET

Opcion3:
    CALL BuscarEstudiante
    RET

Opcion4:
    CALL separar_numeros_func
    CALL OrdenarNotas
    RET

Opcion5:
    CALL MostrarListaCompleta
    RET

SalirPrograma:
    MOV AH, 4Ch
    INT 21h

;--------------------------------------------------
; AgregarEstudiante
;--------------------------------------------------
AgregarEstudiante PROC
    PUSH AX
    
    MOV AL, cnt
    CMP AL, indMax
    JL  PuedeAgregar
    
    MOV AH, 09h
    LEA DX, msgMaxAlcanzado
    INT 21h
    LEA DX, msgPresioneTecla
    INT 21h
    MOV AH, 01h
    INT 21h
    JMP FinAgregar
    
PuedeAgregar:
    CALL InputProc
    
FinAgregar:
    POP AX
    RET
AgregarEstudiante ENDP

;--------------------------------------------------
; InputProc 
;--------------------------------------------------
InputProc PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    ; Pedir nombre
    MOV AH, 09h
    LEA DX, msgNombre
    INT 21h
    
    ; Leer nombre con INT 21h/0Ah
    MOV indBuffer, indSize  ; Maximo de caracteres a leer (indSize es una costante)
    LEA DX, indBuffer       ; Carga la direccion del buffer donde se guardara el nombre
    MOV AH, 0Ah
    INT 21h
    
    ; Terminar cadena con '$'
    XOR BX, BX              ; Limpia el valor de BX
    MOV BL, indBuffer[1]    ; Numero de caracteres leidos se guardan en BL, valor de indSize
    MOV indBuffer[BX+2], '$'; Agregar indicador de finalizacion al final 
    
    ; Copiar nombre a la lista
    XOR AX, AX              ; Limpia el valor de AX
    MOV AL, cnt
    MOV BL, indSize+1
    MUL BL                  ; AX = AL * BL = cnt * (indSize+1) ---> Se almacena en AX
    LEA DI, indLst          ; DI (Destination Index) apunta al inicio de array indLst
    ADD DI, AX              ; Se adiciona para mover el cursos al guardar la data
    LEA SI, indBuffer + 2   ; Saltar los primeros 2 bytes del buffer, se almacena el inicio de nombre en SI (source index)
    CALL CopiarCadena

    ; Pedir nota
    MOV AH, 09h
    LEA DX, msgNota
    INT 21h

    ; Leer nota
    MOV grdBuffer, grdSize
    LEA DX, grdBuffer
    MOV AH, 0Ah
    INT 21h
    
    ; Terminar cadena con '$'
    XOR BX, BX
    MOV BL, grdBuffer[1]
    MOV grdBuffer[BX+2], '$'
    
    ; Copiar nota a la lista
    XOR AX, AX
    MOV AL, cnt
    MOV BL, grdSize+1
    MUL BL
    LEA DI, grdLst
    ADD DI, AX
    LEA SI, grdBuffer + 2
    CALL CopiarCadena

    ; Incrementar contador
    INC cnt
    
    MOV AH, 09h
    LEA DX, newline
    INT 21h
    
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
InputProc ENDP

;--------------------------------------------------
; CopiarCadena 
;--------------------------------------------------
CopiarCadena PROC
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI
    
CopiarLoop:
    MOV AL, [SI]       ; Esto es guardar en AL la posicion del primer caracter de la data de buffer
                       ; la primera vez que se llama al PROC, luego almacenara el siguiente caracter
    CMP AL, 0Dh        ; Saltar carriage return, final de la linea
    JE  FinCopia
    CMP AL, 0Ah        ; Saltar line feed, que es avance de linea o de fila
    JE  SaltarChar      
    MOV [DI], AL
    INC DI             ; Se incrementa DI para apuntar al siguiente lugar del buffer destino.
SaltarChar:            
    INC SI             ; Avanza al siguiente caracter de buffer
    CMP BYTE PTR [SI], '$' ; Verifica si ya termina la cadena
    JNE CopiarLoop
    
FinCopia:
    MOV BYTE PTR [DI], '$'
    POP DI
    POP SI
    POP CX
    POP AX
    RET
CopiarCadena ENDP

;--------------------------------------------------
; MostrarListaCompleta 
;--------------------------------------------------
MostrarListaCompleta PROC
    CALL ClrScreen
    
    MOV AH, 09h
    LEA DX, msgLista
    INT 21h
    LEA DX, msgEncabezado
    INT 21h
    LEA DX, newline
    INT 21h
    
    ; Verificar si hay estudiantes
    MOV AL, cnt
    CMP AL, 0
    JE FinMostrar
    
    XOR CX, CX
    MOV CL, cnt
    XOR BX, BX
    
MostrarEstudiante:    
    PUSH BX
    PUSH CX
    
    ; Mostrar numero
    MOV AH, 02h
    MOV DL, BL
    ADD DL, '1'
    INT 21h
    MOV DL, '.'
    INT 21h
    MOV DL, ' '
    INT 21h
    
    ; Mostrar nombre
    MOV AL, BL
    MOV CL, indSize+1
    MUL CL  ; AX = AL * CL
    LEA SI, indLst
    ADD SI, AX
    CALL ImprimirCadena
    
    ; Tabulacion
    MOV AH, 09h
    LEA DX, tab
    INT 21h
    
    ; Mostrar nota
    MOV AL, BL
    MOV AH, grdSize+1
    MUL AH
    LEA SI, grdLst
    ADD SI, AX
    CALL ImprimirCadena
    
    ; Nueva linea
    MOV AH, 09h
    LEA DX, newline
    INT 21h
    
    POP CX
    POP BX
    INC BX
    LOOP MostrarEstudiante
    
FinMostrar:
    MOV AH, 09h
    LEA DX, msgPresioneTecla
    INT 21h
    MOV AH, 01h
    INT 21h
    RET
MostrarListaCompleta ENDP

;--------------------------------------------------
; ImprimirCadena
;--------------------------------------------------
ImprimirCadena PROC
    PUSH AX
    PUSH DX
    PUSH SI
    
ImprimirLoop:
    MOV DL, [SI]
    CMP DL, '$'
    JE FinImprimir
    MOV AH, 02h
    INT 21h
    INC SI
    JMP ImprimirLoop
    
FinImprimir:
    POP SI
    POP DX
    POP AX
    RET
ImprimirCadena ENDP

;--------------------------------------------------
; Funciones stub (simplificadas)
;--------------------------------------------------
MostrarEstadisticas PROC
    CALL ClrScreen 
    CALL calcular_porcentajes
    MOV AH, 09h
    LEA DX, msgPresioneTecla
    INT 21h
    MOV AH, 01h
    INT 21h 
    RET
MostrarEstadisticas ENDP

BuscarEstudiante PROC
    CALL ClrScreen
    MOV AH, 09h
    LEA DX, msgPresioneTecla
    INT 21h
    MOV AH, 01h
    INT 21h
    RET
BuscarEstudiante ENDP

OrdenarNotas PROC
    CALL ClrScreen
    MOV AH, 09h
    LEA DX, msgPresioneTecla
    INT 21h
    MOV AH, 01h
    INT 21h
    RET
OrdenarNotas ENDP

;--------------------------------------------------
; Limpiar pantalla
;--------------------------------------------------
ClrScreen:
    MOV AX, 0600h   ; AH=06h (scroll), AL=00h (clear)
    MOV BH, 07h     ; Atributo (gris sobre negro)
    MOV CX, 0000h   ; Esquina superior izquierda
    MOV DX, 184Fh   ; Esquina inferior derecha
    INT 10h
    
    ; Posicionar cursor en 0,0
    MOV AH, 02h
    MOV BH, 00h
    MOV DX, 0000h
    INT 10h
    RET 
;--------------------------------------------------
; Separa lista de strings a listas numericas
;--------------------------------------------------

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
    mov si, offset grdLst
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
    cmp al, '$'              ; Fin del string?
    je fin_numero
    cmp al, '.'              ; Es punto decimal?
    je encontro_decimal
    cmp al, 13               ; Es carriage return?
    je fin_numero
    cmp al, 10               ; Es new line?
    je fin_numero
    
    ; Convertir ASCII a numero
    sub al, '0'
    mov ah, 0
    push ax                  ; Guardar nuevo digito
    
    ; entero_temp = entero_temp * 10
    mov ax, entero_temp
    mov dx, 10
    mul dx
    mov entero_temp, ax
    
    ; entero_temp = entero_temp + nuevo_digito
    pop ax
    add entero_temp, ax
    
    inc si
    jmp leer_entero

encontro_decimal:
    mov decimal_encontrado, 1
    inc si                   ; Saltar el punto
    
leer_decimal:
    mov al, [si]
    cmp al, '$'              ; ¿Fin del string?
    je fin_numero
    cmp al, 13               ; ¿Es carriage return?
    je fin_numero
    cmp al, 10               ; ¿Es new line?
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
    
    ; Avanzar al siguiente string en grdLst
    inc cx
    mov al, cnt
    cbw
    cmp cx, ax               ; Comparar con cnt (convertido a word)
    jge terminar_proceso     ; Si ya procesamos todos, terminar
    
    ; Avanzar SI al inicio del siguiente string (11 bytes por elemento)
    ; Calcular: SI = offset grdLst + (cx * 11)
    push ax
    push dx
    mov ax, cx               ; AX = numero actual (1, 2, 3...)
    mov dx, grdSize
    inc dx                   ; DX = 11 (grdSize + 1)
    mul dx                   ; AX = cx * 11
    mov si, offset grdLst
    add si, ax               ; SI apunta al inicio del siguiente string
    pop dx
    pop ax
    
    jmp procesar_numero      ; Procesar el siguiente número
    
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
    
    ; Usar pila para construir el numero
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
    
    ; Verificar si el numero es cero
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
; -------------------------------------------------
; CALCULAR PORCENTAJES PROC
; -------------------------------------------------

calcular_porcentajes proc
    mov cl, cnt        ; cnt es 8 bits, usamos CL como contador
    xor si, si         ; indice del array
    mov aprobados,0
    mov desaprobados,0

ciclo_notas:
    cmp cl,0
    je fin_ciclo

    mov ax, enteros_array[si] ; cargar nota
    cmp ax,70
    jl es_reprobado

es_aprobado:
    inc aprobados
    jmp siguiente

es_reprobado:
    inc desaprobados

siguiente:
    add si,2       ; siguiente palabra
    dec cl
    jmp ciclo_notas

fin_ciclo:

    ; ------------------------------
    ; porcentaje aprobados = (aprobados * 100) / cnt
    ; ------------------------------
    xor ax, ax        ; LIMPIAR AX COMPLETAMENTE
    mov al, aprobados ; cargar aprobados (8 bits)
    mov bl, 100
    mul bl            ; AX = aprobados * 100
    mov bl, cnt       ; divisor
    div bl            ; AL = cociente, AH = residuo
    xor ah, ah        ; descartar residuo, AX = porcentaje
    push ax           ; guardar porcentaje

    ; imprimir mensaje de aprobados
    mov ah, 9
    lea dx, msg_aprob
    int 21h
    pop ax
    call print_num    ; imprimir porcentaje

    ; ------------------------------
    ; porcentaje reprobados = (desaprobados * 100) / cnt
    ; ------------------------------
    xor ax, ax        ; LIMPIAR AX COMPLETAMENTE - ESTO ES LO QUE FALTABA
    mov al, desaprobados ; cargar desaprobados (8 bits)
    mov bl, 100
    mul bl            ; AX = desaprobados * 100
    mov bl, cnt       ; divisor
    div bl            ; AL = cociente, AH = residuo
    xor ah, ah        ; descartar residuo, AX = porcentaje

    ; imprimir mensaje de reprobados
    push ax           ; guardar porcentaje temporalmente
    mov ah, 9
    lea dx, msg_reprob
    int 21h
    pop ax
    call print_num

    ret
calcular_porcentajes endp

; ==========================================
; print_num: imprime AX en decimal
; ==========================================
print_num proc
    push ax
    push bx
    push cx
    push dx

    mov cx, 0          ; contador de dígitos
    mov bx, 10         ; divisor para decimal

    cmp ax, 0
    jne conv_loop
    ; si AX=0, imprimir '0' directamente
    mov dl, '0'
    mov ah, 2
    int 21h
    jmp print_symbol

conv_loop:
    xor dx, dx
    div bx            ; AX / 10 -> cociente en AX, residuo en DX
    push dx           ; guardar residuo (dígito)
    inc cx
    cmp ax, 0
    jne conv_loop

print_digits:
    pop dx
    add dl, '0'
    mov ah, 2
    int 21h
    loop print_digits

print_symbol:
    ; imprimir símbolo de porcentaje
    mov dl, '%'
    mov ah, 2
    int 21h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_num endp


END START