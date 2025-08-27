.MODEL SMALL
.STACK 100H

.DATA
indSize     EQU 30
grdSize     EQU 10
indMax      EQU 3

indBuffer   DB indSize    ; tama�o m�ximo
           DB ?          ; caracteres le�dos
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
    CALL MostrarEstadisticas
    RET

Opcion3:
    CALL BuscarEstudiante
    RET

Opcion4:
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
; InputProc - CORREGIDO
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
    MOV indBuffer, indSize  ; Máximo de caracteres a leer
    LEA DX, indBuffer
    MOV AH, 0Ah
    INT 21h
    
    ; Terminar cadena con '$'
    XOR BX, BX
    MOV BL, indBuffer[1]    ; Número de caracteres leídos
    MOV indBuffer[BX+2], '$'
    
    ; Copiar nombre a la lista
    XOR AX, AX
    MOV AL, cnt
    MOV BL, indSize+1
    MUL BL
    LEA DI, indLst
    ADD DI, AX
    LEA SI, indBuffer + 2   ; Saltar los primeros 2 bytes del buffer
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
; CopiarCadena - CORREGIDO
;--------------------------------------------------
CopiarCadena PROC
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI
    
CopiarLoop:
    MOV AL, [SI]
    CMP AL, 0Dh        ; Saltar carriage return
    JE  FinCopia
    CMP AL, 0Ah        ; Saltar line feed
    JE  SaltarChar
    MOV [DI], AL
    INC DI
SaltarChar:
    INC SI
    CMP BYTE PTR [SI], '$'
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
; MostrarListaCompleta - CORREGIDO
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
    
    ; Mostrar número
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
    
    ; Tabulación
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
    
    ; Nueva línea
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
; ImprimirCadena - CORREGIDO
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

END START