.MODEL SMALL
.STACK 100H

.DATA
tam_nombre          EQU 30                                      ; Tamaño máximo para el nombre del estudiante. 
tam_calif           EQU 10                                      ; Tamaño máximo para la calificación. 
max_estudiantes     EQU 3                                       ; Número máximo de estudiantes en el registro.
contador            DB 0                                        ; Registro de estudiantes ingresados. 

; ---< Buffers >---
; [Tam máximo][Caracts leídos][Buffer]
; [0]: Tamaño máximo de la entrada.
; [1]: Número real de caracteres leídos.
; [2]: Buffer de almaenamiento. 

buffer_nombre   DB tam_nombre                                   ; Almacenado tempral de nombres.
                DB ?  
                DB tam_nombre+2 DUP(0)

buffer_calif    DB tam_calif                                    ; Almacenado temporal de calificaciones. 
                DB ?
                DB tam_calif+2 DUP(0)

buffer_id       DB 3                                            ; Buffer para el ingreso de números puntuales (2 dig + ENTER).
                DB ?
                DB 3 DUP(0)

; ---< Listas/Arrays de almacenamiento >---
; Almacenado de caracteres. 
lista_nombres   DB max_estudiantes * (tam_nombre+1) DUP('$')    ; Rellenan con carácter nulo '$'.
lista_califs    DB max_estudiantes * (tam_calif+1) DUP('$')

; Almacenda de resultados numéricos. 
array_enteros   DW max_estudiantes dup(0)                       ; Parte entera de la calificación (16 bits).
array_decimales DW max_estudiantes * 2 dup(0)                   ; Parte fraccionaria de la calificación (32 bits).

; Variables temporales 
temp_entero     DW 0                                            ; Almacena temporalmente la parte entera durante el parsing. 
temp_decimal    DW 2 dup(0)                                     ; Almacena temporalmente la parte decimal durante el parsing.
flag_decimal    DB 0                                            ; Flag al encontrar el punto decimal. 
  
; Contadores de aprobaciones
contador_aprobados      DB 0
contador_desaprobados   DB 0            

; ---< Mensajes y Prompts del Sistema >---
msgMenu     DB 13, 10, '-------------< CE1106 - SISTEMA DE REGISTRO >------------', 13, 10
            DB         '------------------< MENU PRINCIPAL >---------------------',  13, 10
            DB         '| 1. Agregar Estudiante y Calificacion                  |', 13, 10
            DB         '| 2. Mostrar Estadisticas                               |', 13, 10
            DB         '| 3. Buscar Estudiante por ID                           |', 13, 10 
            DB         '| 4. Ordenar Calificaciones (ASC/DESC)                  |', 13, 10
            DB         '| 5. Registros                                          |', 13, 10
            DB         '| 0. Salir del Programa                                 |', 13, 10
            DB         '---------------------------------------------------------', 13, 10
            DB         '                                                         ', 13, 10
            DB         'Ingrese opcion: $'

; Mensajes [1]
msgT1           DB 13, 10, '[ AGREGAR ESTUDIANTE ]', 13, 10, '$'
msgPedirNombre  DB 13, 10, 'Ingrese nombre completo del estudiante: $'
msgPedirNota    DB 13, 10, 'Ingrese la calificacion del estudiante: $'

; Mensajes [2]
msgT2               DB 13, 10, '[ ESTADISTICAS ]', 13, 10, '$'
msgDebug            DB 13, 10, 'Procesado: $' 
msgNoStats          DB 13, 10, 'No hay estudiantes registrados en el sistema...', 13, 10, '$'
msgPorcAprobados    DB 13, 10, 'Porcentaje de aprobados: $'
msgPorcReprobados   DB 13, 10, 'Porcentaje de reprobados: $'

; Mensajes [3]
msgT3               DB 13, 10, '[ BUSQUEDA POR ID ]', 13, 10, '$'
msgPedirID          DB 13, 10, 'Ingrese el ID del estudiante: $'
msgIDInvalido       DB 13, 10, 'ID invalido o estudiante no existe!', 13, 10, '$'
msgEstEncontrado    DB 13, 10, 'Estudiante encontrado:', 13, 10, '$'  

; Mensajes [4]
msgT4               DB 13, 10, '[ ORDENAMIENTO DE CALIFICACIONES ]', 13, 10, '$'

; Mensajes [5]
msgT5               DB  13, 10, '[ REGISTROS ]', 13, 10, '$'
msgEncabezado       DB 'N.', 9,9,'Nombre', 9,9,'Calificacion$'
msgSeparador        DB 13, 10, '-----------------------------------------------', 13, 10, '$'
msgListaVacia       DB 13, 10, 'La lista se encuentre vacia...$'

; Mensajes [0]
msgDespedida        DB 13, 10, '-------------------------------------------------', 13, 10
                    DB         '           SISTEMA DE REGISTRO - CE1106          ', 13, 10
                    DB         '-------------------------------------------------', 13, 10
                    DB         '          Gracias por usar el sistema!           ', 13, 10
                    DB         '         Programa terminado correctamente. :D    ', 13, 10
                    DB         '-------------------------------------------------', 13, 10, '$'

; Formato
nueva_linea     DB 13, 10, '$'
tabulador       DB 09h, '$'

; Mensajes de estado y error/advertencias
msgOpcionInvalida   DB 13, 10, 'Opcion invalida! Presione cualquier tecla...$'
msgMaxAlcanzado     DB 13, 10, 'Maximo de estudiantes alcanzado!$'
msgContinuar        DB 13, 10, 'Presione cualquier tecla para continuar...$'
                                
.CODE
START:
    ; Inicializar segmentos de datos.
    MOV AX, @DATA
    MOV DS, AX                                                  ; Inicializar Data Segment.
    MOV ES, AX                                                  ; Inicializar Extra Segment.

MenuPrincipal:                                                  ; Bucle principal. 
    CALL LimpiarPantalla
    CALL MostrarMenu
    JMP MenuPrincipal

MostrarMenu PROC
    ; Mostrar Menú en pantalla. 
    MOV AH, 09h
    LEA DX, msgMenu
    INT 21h

    ; Leer opción ingresada por el usuario. 
    MOV AH, 01h                                                  ; Función DOS: Leer carácter desde teclado.
    INT 21h                                                      ; El carácter ingresado se almacena en AL. 

    ; Procesado de opción seleccionada.     
    CMP AL, '1'
    JE Opcion1                                                   ; Agregar estudidante y calificación.
    CMP AL, '2'
    JE Opcion2                                                   ; Mostrar estadística. 
    CMP AL, '3'
    JE Opcion3                                                   ; Busqueda por ID.
    CMP AL, '4'
    JE Opcion4                                                   ; Ordenado por calificación. 
    CMP AL, '5'
    JE Opcion5                                                  ; Mostrar datos ingresados. 
    CMP AL, '0' 
    JE SalirPrograma                                            ; Salir del programa.
    CMP AL, 1Bh
    JE SalirPrograma                                            ; Salir del programa con ESC.
    
    ; Opción inválida. 
    MOV AH, 09h
    LEA DX, msgOpcionInvalida
    INT 21h

    ; Esperar tecla para continuar.
    MOV AH, 01h
    INT 21h
    RET                                                           ; Retornar al menú principal
MostrarMenu ENDP

; ---< Opciones del Programa >---
Opcion1:
    CALL IntentarAgregar
    RET

Opcion2:
    CALL separar_numeros_func
    CALL MostrarEstadisticas
    RET

Opcion3:
    CALL BusquedaPorID
    RET

Opcion4:
    CALL separar_numeros_func
    CALL OrdenarCalif
    RET

Opcion5:
    CALL MostrarListaCompleta
    RET

SalirPrograma:
    CALL LimpiarPantalla

    MOV AH, 09h
    LEA DX, msgDespedida
    INT 21h

    MOV AH, 4Ch
    INT 21h

; ---< Agregar Estudiante y Calificacion >--- 
IntentarAgregar PROC
    PUSH AX

    CALL LimpiarPantalla

    ; Título de la Sección.
    MOV AH, 09h
    LEA DX, msgT1
    INT 21h
    
    ; Verifica si hay espacio suficiente.
    MOV AL, contador
    CMP AL, max_estudiantes
    JL  ProcesarEntrada                                            ; Sí puede agregar estudiante (contador < max_estudiantes).
    
    ; Espacio insuficiente. 
    MOV AH, 09h
    LEA DX, msgMaxAlcanzado
    INT 21h
    LEA DX, msgContinuar
    INT 21h
    MOV AH, 01h
    INT 21h

    ; Retorna a Menú Principal.
    JMP FinAgregar
    
PuedeAgregar:
    CALL ProcesarEntrada
    
FinAgregar:
    POP AX
    RET
    
ProcesarEntrada PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI                                                         ; Preservar los registros.
    
    ; Pedir nombre del estudiante. 
    MOV AH, 09h
    LEA DX, msgPedirNombre
    INT 21h
    
    ; Leer entrada del nombre. 
    MOV buffer_nombre, tam_nombre                                   ; Establecer tamaño del buffer en [0].
    LEA DX, buffer_nombre                                           ; DX apunta al buffer de entrada. 
    MOV AH, 0Ah
    INT 21h
    
    ; Terminación '$' para compatibilidad con DOS.
    XOR BX, BX                                                      ; Limpiar BX.
    MOV BL, buffer_nombre[1]                                        ; BL = número de caracteres leídos.
    MOV buffer_nombre[BX+2], '$'                                    ; Agregar '$'. 
    
    ; Calcular posición de destino. 
    XOR AX, AX
    MOV AL, contador
    MOV BL, tam_nombre+1                                            ; BL = tamaño de cada entrada (incluye terminador).
    MUL BL                                                          ; AX (deslpazamiento) = contador * (tam_nombre+1)
    LEA DI, lista_nombres
    ADD DI, AX                                                      ; DI (destino en lista) = deslpazamiento + inicio 
    LEA SI, buffer_nombre+2                                         ; SI apunta a los datos en [2]
    CALL CopiarCadena                                               ; Copiar cadena en lista. 

    ; Pedir calificación del estudiante.
    MOV AH, 09h
    LEA DX, msgPedirNota
    INT 21h

    ; Leer entrada de calificación. 
    MOV buffer_calif, tam_calif
    LEA DX, buffer_calif
    MOV AH, 0Ah
    INT 21h
    
    ; Terminar cadena con '$'.
    XOR BX, BX
    MOV BL, buffer_calif[1]
    MOV buffer_calif[BX+2], '$'
    
    ; Copiar calificación en lista.
    XOR AX, AX
    MOV AL, contador
    MOV BL, tam_calif+1
    MUL BL
    LEA DI, lista_califs
    ADD DI, AX
    LEA SI, buffer_calif + 2
    CALL CopiarCadena

    ; Incrementar contador.
    INC contador
    
    ; Salto de línea. 
    MOV AH, 09h
    LEA DX, nueva_linea
    INT 21h
    
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    JMP MenuPrincipal
ProcesarEntrada ENDP

IntentarAgregar ENDP

; ---< Buscar Estudiante por ID >--- 
BusquedaPorID PROC
    CALL LimpiarPantalla

    ; Título de la Sección.
    MOV AH, 09h
    LEA DX, msgT3
    INT 21h

    ; Mensaje de búsqueda.
    MOV AH, 09h
    LEA DX, msgPedirID
    INT 21h
    
    ; Lectura del ID ingresado. 
    MOV buffer_id, 3                                               ; Máx 2 dígitos (+Enter).
    LEA DX, buffer_id
    MOV AH, 0Ah                                                    ; Lectura de Cadena.
    INT 21h
    
    XOR AX, AX
    XOR CX, CX
    MOV BX, 10
    LEA SI, buffer_id + 2                                           ; SI apunta al primer carácter.

    ; Verificación si ID nulo.
    MOV CL, buffer_id + 1
    CMP CL, 0
    JE IDInvalidoBusqueda

ConversionID:
    MOV CL, [SI]                                                    ; Lectura de caracter.
    INC SI                                                          ; Movimiento en el buffer para siguiente iteración.
    
    CMP CL, 13                                                      ; Verificar si es Enter (fin).
    JE ValidacionID
    
    ; Verifica que sea un dígito. 
    CMP CL, '0'
    JL IDInvalidoBusqueda
    CMP CL, '9'
    JG IDInvalidoBusqueda
    
    ; Convertir a número y recordar.
    SUB CL, '0'                                                     ; Conversión ASCII.
    MOV DX, BX                                                      ; DX = 10.
    MUL DX                                                          ; AX *= 10.
    JC IDInvalidoBusqueda                                           ; Overflow : error.
    ADD AX, CX                                                      ; AX = AX * 10 + nuevo dígiro (CL)
    JC IDInvalidoBusqueda                                           ; Overflow : error.
    
    JMP ConversionID                                                ; Itera hasta ENTER.

ValidacionID:
    ; Validar rango. 
    CMP AX, 1
    JL IDInvalidoBusqueda                                           ; Si es menor que 1 : inválido.
    
    ; Comparación con límite superior.
    XOR BX, BX                                                      ; BL = contador ---> BL = BX.
    MOV BL, contador
    CMP AX, BX
    JG IDInvalidoBusqueda                                           ; Si es mayor que contador : inválido.
    
    ; Convertir a índice base 0.
    DEC AX
    
    MOV AH, 09h
    LEA DX, nueva_linea
    INT 21h

    MOV AH, 09h
    LEA DX, msgSeparador
    INT 21h

    CALL MostarPorID

    MOV AH, 09h
    LEA DX, msgSeparador
    INT 21h
    
    ; Volver a menú.
    MOV AH, 09h
    LEA DX, msgContinuar
    INT 21h
    MOV AH, 01h
    INT 21h
    RET
    
IDInvalidoBusqueda:
    ; ID ingresado inválido y volver a menú.
    MOV AH, 09h
    LEA DX, msgIDInvalido
    INT 21h
    LEA DX, msgContinuar
    INT 21h
    MOV AH, 01h
    INT 21h
    RET
BusquedaPorID ENDP

MostarPorID PROC                                                    ; AL = índice del estudiante (base 0).
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Comparar índice con número de estudiantes. 
    CMP AL, contador
    JGE IDInvalidoBusqueda
    
    ; Guaradr ID en BX. 
    XOR BX, BX
    MOV BL, AL
    
    ; Mostar ID del estudiante. 
    MOV AH, 02h
    MOV DL, tabulador
    INT 21h
    MOV DL, BL
    ADD DL, '1'                                                     ; Conversión a base 1 del ID.
    INT 21h
    MOV DL, '.'
    INT 21h
    MOV DL, tabulador
    INT 21h
    
    ; Mostrar Nombre.
    MOV AL, BL
    MOV CL, tam_nombre + 1                                          ; CL = tamaño (+'$').
    MUL CL                                                          ; AX (offset) = AL * CL.
    LEA SI, lista_nombres
    ADD SI, AX                                                      ; offset + inicio = destino. 
    CALL ImprimirCadena
    
    MOV AH, 02h
    MOV DL, 09h
    INT 21h
    
    ; Mostrar calificación. 
    MOV AL, BL
    MOV CL, tam_calif + 1
    MUL CL
    LEA SI, lista_califs
    ADD SI, AX
    CALL ImprimirCadena

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
MostarPorID ENDP

; ---< Registros >--- 
MostrarListaCompleta PROC
    CALL LimpiarPantalla

    ; Título de la Sección.
    MOV AH, 09h
    LEA DX, msgT5
    INT 21h
    LEA DX, nueva_linea
    INT 21h
    
    MOV AH, 09h
    LEA DX, msgEncabezado
    INT 21h
    LEA DX, msgSeparador
    INT 21h
    
    ; Verificar si hay estudiantes.
    MOV CL, contador
    CMP CL, 0
    JE ListaVacia
    
    ; Recorrer todos los estudiantes
    XOR AX, AX
    
MostrarEstudiante:
    PUSH AX
    CALL MostarPorID
    POP AX
    
    MOV AH, 09h
    LEA DX, nueva_linea
    INT 21h

    ; Verificar el número de estudiantes mostrados.
    INC AL
    CMP AL, contador
    JL MostrarEstudiante
    
    JMP FinMostrar
    
ListaVacia:
    MOV AH, 09h
    LEA DX, msgListaVacia
    INT 21h

FinMostrar:
    MOV AH, 09h
    LEA DX, nueva_linea
    INT 21h
    LEA DX, msgContinuar
    INT 21h
    MOV AH, 01h
    INT 21h
    RET
MostrarListaCompleta ENDP

; ---< Estadísticas >---
MostrarEstadisticas PROC
    CALL LimpiarPantalla 

    MOV AH, 09h
    LEA DX, msgT2
    INT 21h

    ; Verificar número de registros. 
    MOV AL, contador
    CMP AL, 0
    JNE MostrarStats
    
    ; En caso de que no de haber estudiantes.
    MOV AH, 09h
    LEA DX, msgNoStats
    INT 21h
    JMP FinEstadisticas

MostrarStats:
    CALL calcular_porcentajes

FinEstadisticas:
    MOV AH, 09h
    LEA DX, msgContinuar
    INT 21h
    MOV AH, 01h
    INT 21h 
    RET
MostrarEstadisticas ENDP

; ---< Ordenar Calificaciones >---
OrdenarCalif PROC
    CALL LimpiarPantalla

    ; Título de la Sección.
    MOV AH, 09h
    LEA DX, msgT4
    INT 21h

    MOV AH, 09h
    LEA DX, msgContinuar
    INT 21h
    MOV AH, 01h
    INT 21h
    RET
OrdenarCalif ENDP

; ---< Funciones Auxiliares >---

; --- Copiado de buffer en lista específica --- 
CopiarCadena PROC                                                   ; SI = dirección de cadena a copiar.
    PUSH AX                                                         ; DI = dirección destino.
    PUSH CX
    PUSH SI
    PUSH DI
    
CopiarLoop:
    MOV AL, [SI]                                                    ; Cargar carácter.
    CMP AL, 0Dh
    JE FinCopia                                                     ; Verificar ENTER.
    CMP AL, 0Ah
    JE SaltarChar                                                   ; Saltar al siguiente caracter. 
    CMP AL, '$'
    JE FinCopia                                                     ; Verificar terminador '$'.
    
    MOV [DI], AL                                                    ; Copiar carácter al destino.
    INC DI                                                          ; Avanzar.

SaltarChar:            
    INC SI                                                          ; Avanzar al siguiente caracter de buffer.
    JNE CopiarLoop
    
FinCopia:
    MOV BYTE PTR [DI], '$'                                          ; Agregar terminador al final de la linea. 
    POP DI
    POP SI
    POP CX
    POP AX
    RET
CopiarCadena ENDP

; --- Imprime cadena de texto desde la SI --- 
ImprimirCadena PROC                                                 ; SI posición inicial de la cadena.
    PUSH AX
    PUSH DX
    PUSH SI
    
ImprimirLoop:
    MOV DL, [SI]                                                    ; Carácter en apuntado por SI. 
    CMP DL, '$'                                                     ; Verificar terminador.
    JE FinImprimir
    
    ; Impresión de caracter y loop. 
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

; --- Limpia pantalla ---
LimpiarPantalla:
    ; Limpiado de pantalla. 
    MOV AX, 0600h                                                   ; AH=06h (scroll), AL=00h (clr).
    MOV BH, 07h                                                     ; Atributo (gris sobre negro).
    MOV CX, 0000h                                                   ; Esquina superior izquierda.
    MOV DX, 184Fh                                                   ; Esquina inferior derecha.
    INT 10h
    
    ; Posicionar cursor en 0,0.
    MOV AH, 02h
    MOV BH, 00h
    MOV DX, 0000h
    INT 10h
    RET 

; --- Separado lista de strings a listas numéricas ---
separar_numeros_func proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Inicializar indices
    mov si, offset lista_califs
    mov di, offset array_enteros
    mov bx, offset array_decimales
    mov cx, 0                      ; Contador de numeros
    
procesar_numero:
    ; Reiniciar valores temporales (32 bits para decimal)
    mov word ptr temp_entero, 0
    mov word ptr temp_decimal, 0     ; Parte baja
    mov word ptr temp_decimal + 2, 0 ; Parte alta (32 bits total)
    mov flag_decimal, 0
    
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
    
    ; temp_entero = temp_entero * 10
    mov ax, temp_entero
    mov dx, 10
    mul dx
    mov temp_entero, ax
    
    ; temp_entero = temp_entero + nuevo_digito
    pop ax
    add temp_entero, ax
    
    inc si
    jmp leer_entero

encontro_decimal:
    mov flag_decimal, 1
    inc si                   ; Saltar el punto
    
leer_decimal:
    mov al, [si]
    cmp al, '$'              ; �Fin del string?
    je fin_numero
    cmp al, 13               ; �Es carriage return?
    je fin_numero
    cmp al, 10               ; �Es new line?
    je fin_numero
    
    ; Convertir ASCII a n�mero
    sub al, '0'
    mov ah, 0
    push ax                  ; Guardar nuevo d�gito
    
    ; temp_decimal = temp_decimal * 10 (32 bits)
    push bx
    push cx
    push dx
    
    ; Multiplicar parte baja (temp_decimal) por 10
    mov ax, word ptr temp_decimal
    mov dx, 10
    mul dx
    mov word ptr temp_decimal, ax
    mov cx, dx              ; Guardar carry
    
    ; Multiplicar parte alta (temp_decimal + 2) por 10 y sumar carry
    mov ax, word ptr temp_decimal + 2
    mov dx, 10
    mul dx
    add ax, cx              ; Sumar el carry de la parte baja
    mov word ptr temp_decimal + 2, ax
    
    pop dx
    pop cx
    pop bx
    
    ; temp_decimal = temp_decimal + nuevo_d�gito
    pop ax
    add word ptr temp_decimal, ax
    adc word ptr temp_decimal + 2, 0  ; Sumar carry si hay
    
    inc si
    jmp leer_decimal

fin_numero:
    ; Guardar entero en array (16 bits)
    mov ax, temp_entero
    mov [di], ax
    add di, 2
    
    ; Guardar decimal en array (32 bits - 2 palabras)
    mov ax, word ptr temp_decimal      ; Parte baja
    mov [bx], ax
    mov ax, word ptr temp_decimal + 2  ; Parte alta
    mov [bx + 2], ax
    add bx, 4                         ; Avanzar 4 bytes (32 bits)
    
    ; Avanzar al siguiente string en lista_califs
    inc cx
    mov al, contador
    cbw
    cmp cx, ax               ; Comparar con contador (convertido a word)
    jge terminar_proceso     ; Si ya procesamos todos, terminar
    
    ; Avanzar SI al inicio del siguiente string (11 bytes por elemento)
    ; Calcular: SI = offset lista_califs + (cx * 11)
    push ax
    push dx
    mov ax, cx               ; AX = numero actual (1, 2, 3...)
    mov dx, tam_calif
    inc dx                   ; DX = 11 (tam_calif + 1)
    mul dx                   ; AX = cx * 11
    mov si, offset lista_califs
    add si, ax               ; SI apunta al inicio del siguiente string
    pop dx
    pop ax
    
    jmp procesar_numero      ; Procesar el siguiente n�mero
    
terminar_proceso:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
separar_numeros_func endp


; --- Calcular Porcentajes de Estudiantes ---
calcular_porcentajes proc
    mov cl, contador        ; contador es 8 bits, usamos CL como contador
    xor si, si         ; Reinicio source index
    mov contador_aprobados,0
    mov contador_desaprobados,0

ciclo_notas:
    cmp cl,0
    je fin_ciclo

    mov ax, array_enteros[si] ; cargar nota
    cmp ax,70
    jl es_reprobado

es_aprobado:
    inc contador_aprobados
    jmp siguiente

es_reprobado:
    inc contador_desaprobados

siguiente:
    add si,2       ; siguiente palabra
    dec cl
    jmp ciclo_notas

fin_ciclo:

    ; ------------------------------
    ; porcentaje contador_aprobados = (contador_aprobados * 100) / contador
    ; ------------------------------
    xor ax, ax        ; LIMPIAR AX COMPLETAMENTE
    mov al, contador_aprobados ; cargar contador_aprobados (8 bits)
    mov bl, 100
    mul bl            ; AX = contador_aprobados * 100
    mov bl, contador       ; divisor
    div bl            ; AL = cociente, AH = residuo
    xor ah, ah        ; descartar residuo, AX = porcentaje
    push ax           ; guardar porcentaje

    ; imprimir mensaje de contador_aprobados
    mov ah, 9
    lea dx, msgPorcAprobados
    int 21h
    pop ax
    call print_num    ; imprimir porcentaje

    ; ------------------------------
    ; porcentaje reprobados = (contador_desaprobados * 100) / contador
    ; ------------------------------
    xor ax, ax        ; LIMPIAR AX COMPLETAMENTE - ESTO ES LO QUE FALtabuladorA
    mov al, contador_desaprobados ; cargar contador_desaprobados (8 bits)
    mov bl, 100
    mul bl            ; AX = contador_desaprobados * 100
    mov bl, contador       ; divisor
    div bl            ; AL = cociente, AH = residuo
    xor ah, ah        ; descartar residuo, AX = porcentaje

    ; imprimir mensaje de reprobados
    push ax           ; guardar porcentaje temporalmente
    mov ah, 9
    lea dx, msgPorcReprobados
    int 21h
    pop ax
    call print_num

    ret
calcular_porcentajes endp

;---------------------------------
; Imprimir Numero contenido en AX
;---------------------------------
print_num proc
    push ax
    push bx
    push cx
    push dx

    mov cx, 0          ; contador de digitos
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
    push dx           ; guardar residuo (digito)
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
    ; imprimir simbolo de porcentaje
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