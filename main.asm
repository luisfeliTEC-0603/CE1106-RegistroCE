.MODEL SMALL
.STACK 100H

.DATA
tam_nombre          EQU 30                                      ; TamaÃ±o mÃ¡ximo para el nombre del estudiante. 
tam_calif           EQU 10                                      ; TamaÃ±o mÃ¡ximo para la calificaciÃ³n. 
max_estudiantes     EQU 15                                       ; NÃºmero mÃ¡ximo de estudiantes en el registro.
contador            DB 0                                        ; Registro de estudiantes ingresados. 

; ---< Buffers >---
; [Tam mÃ¡ximo][Caracts leÃ­dos][Buffer]
; [0]: TamaÃ±o mÃ¡ximo de la entrada.
; [1]: NÃºmero real de caracteres leÃ­dos.
; [2]: Buffer de almaenamiento. 

buffer_nombre   DB tam_nombre                                   ; Almacenado tempral de nombres.
                DB ?  
                DB tam_nombre+2 DUP(0)

buffer_calif    DB tam_calif                                    ; Almacenado temporal de calificaciones. 
                DB ?
                DB tam_calif+2 DUP(0)

buffer_id       DB 3                                            ; Buffer para el ingreso de nÃºmeros puntuales (2 dig + ENTER).
                DB ?
                DB 3 DUP(0)

; ---< Listas/Arrays de almacenamiento >---
; Almacenado de caracteres. 
lista_nombres   DB max_estudiantes * (tam_nombre+1) DUP('$')    ; Rellenan con carÃ¡cter nulo '$'.
lista_califs    DB max_estudiantes * (tam_calif+1) DUP('$')

; Almacenda de resultados numÃ©ricos. 
array_enteros   DW max_estudiantes dup(0)                       ; Parte entera de la calificaciÃ³n (16 bits).
array_decimales DW max_estudiantes * 2 dup(0)                   ; Parte fraccionaria de la calificaciÃ³n (32 bits).

; Variables temporales 
temp_entero     DW 0                                            ; Almacena temporalmente la parte entera durante el parsing. 
temp_decimal    DW 2 dup(0)                                     ; Almacena temporalmente la parte decimal durante el parsing.
flag_decimal    DB 0                                            ; Flag al encontrar el punto decimal. 
temp_index DB 0  
; Contadores de aprobaciones
contador_aprobados      DB 0
contador_desaprobados   DB 0  
 
; Bubble Sort 
; Array que contiene indices resultantes de un Bubble Sort
array_BS   DW max_estudiantes dup(0)
orden            DB 1 ; ASC = 1, DSC = 0   
resultado_dec DB ?   ; 1 = primero mayor, 0 = segundo mayor, 2 = iguales

; Buffers para datos ordenados
buffer_nombres_ordenados DB max_estudiantes * (tam_nombre + 1) DUP('$')
buffer_califs_ordenados  DB max_estudiantes * (tam_calif + 1) DUP('$')

; Variables temporales
temp_reg    DW 0      ; Para cálculos temporales
source_ptr  DW 0      ; Para guardar puntero origen

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
msgT1               DB 13, 10, '[ AGREGAR ESTUDIANTE ]', 13, 10, '$'
msgPedirNombre      DB 13, 10, 'Ingrese nombre completo del estudiante: $'
msgPedirNota        DB 13, 10, 'Ingrese la calificacion del estudiante: $'
msgCalifInvalida    DB 13, 10, 'Error! La calificacion no cuenta con el formato adecuado... Intente nuevamente...', 13, 10,'$'

; Mensajes [2]
msgT2               DB 13, 10, '[ ESTADISTICAS ]', 13, 10, '$'
msgDebug            DB 13, 10, 'Procesado: $' 
msgNoStats          DB 13, 10, 'No hay estudiantes registrados en el sistema...', 13, 10, '$'
msgPorcAprobados    DB 13, 10, 'Porcentaje de aprobados: $'
msgPorcReprobados   DB 13, 10, 'Porcentaje de reprobados: $'
msgMaxNota          DB 13, 10, 'El estudiante con mayor nota es: $'
msgMinNota          DB 13, 10, 'El estudiante con menor nota es: $'
msgMaxMin           DB 13, 10, 'Se presentaran datos de notas mayores y menores en orden de ID, Nombre y Nota.$'
; Mensajes [3]
msgT3               DB 13, 10, '[ BUSQUEDA POR ID ]', 13, 10, '$'
msgPedirID          DB 13, 10, 'Ingrese el ID del estudiante: $'
msgIDInvalido       DB 13, 10, 'ID invalido o estudiante no existe!', 13, 10, '$'
msgEstEncontrado    DB 13, 10, 'Estudiante encontrado:', 13, 10, '$'  

; Mensajes [4]
msgT4               DB 13, 10, '[ ORDENAMIENTO DE CALIFICACIONES ]', 13, 10, '$'
msg_pregunta    DB 13,10,'Ingrese 1 para ASC o 0 para DSC: $'
msg_error       DB 13,10,'Error: Ingrese solo 1 o 0',13,10,'$'

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
    ; Mostrar MenÃº en pantalla. 
    MOV AH, 09h
    LEA DX, msgMenu
    INT 21h

    ; Leer opciÃ³n ingresada por el usuario. 
    MOV AH, 01h                                                  ; FunciÃ³n DOS: Leer carÃ¡cter desde teclado.
    INT 21h                                                      ; El carÃ¡cter ingresado se almacena en AL. 

    ; Procesado de opciÃ³n seleccionada.     
    CMP AL, '1'
    JE Opcion1                                                   ; Agregar estudidante y calificaciÃ³n.
    CMP AL, '2'
    JE Opcion2                                                   ; Mostrar estadÃ­stica. 
    CMP AL, '3'
    JE Opcion3                                                   ; Busqueda por ID.
    CMP AL, '4'
    JE Opcion4                                                   ; Ordenado por calificaciÃ³n. 
    CMP AL, '5'
    JE Opcion5                                                  ; Mostrar datos ingresados. 
    CMP AL, '0' 
    JE SalirPrograma                                            ; Salir del programa.
    CMP AL, 1Bh
    JE SalirPrograma                                            ; Salir del programa con ESC.
    
    ; OpciÃ³n invÃ¡lida. 
    MOV AH, 09h
    LEA DX, msgOpcionInvalida
    INT 21h

    ; Esperar tecla para continuar.
    MOV AH, 01h
    INT 21h
    RET                                                           ; Retornar al menÃº principal
MostrarMenu ENDP

; ---< Opciones del Programa >---
Opcion1:
    CALL IntentarAgregar
    RET

Opcion2:
    CALL LimpiarPantalla
    CALL separar_numeros_func
    
    ; preparar registros para la rutina
    LEA BX, array_enteros     ; BX = base de enteros
    LEA SI, array_decimales   ; SI = base de decimales
    MOV CX, max_estudiantes   ; cantidad de elementos  
    
    ; array_BS almacena orden.
    CALL BUBBLE_SORT_INDICES
    
    CALL ordenarListas     

    CALL MostrarEstadisticas
                            
    MOV AH, 09h
    LEA DX, msgMaxMin
    INT 21h
                            
    CALL generar_Max_Min 
    
    
    JMP FinEstadisticas
    
    RET

Opcion3:
    CALL BusquedaPorID
    RET

Opcion4:
    CALL LimpiarPantalla
    CALL separar_numeros_func
    
    call PREGUNTAR_ORDEN 
    
    ; preparar registros para la rutina
    LEA BX, array_enteros     ; BX = base de enteros
    LEA SI, array_decimales   ; SI = base de decimales
    MOV CX, max_estudiantes   ; cantidad de elementos  
    
    ; array_BS almacena orden.
    CALL BUBBLE_SORT_INDICES
    
    CALL ordenarListas 
    CALL MostrarListaCompleta
        
     
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

IntentarAgregar ENDP

ProcesarEntrada PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI                                                         ; Preservar los registros.

PedirNombre:
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

PedirCalif:
    ; Pedir calificación del estudiante.
    MOV AH, 09h
    LEA DX, msgPedirNota
    INT 21h

ValidarCalif:
    ; Leer entrada de calificación. 
    MOV buffer_calif, tam_calif
    LEA DX, buffer_calif
    MOV AH, 0Ah
    INT 21h

    ; Validar formato numérico y formatear
    CALL FormatoCalif
    JC  ErrorCalif

    CALL VerifCien

    JMP CalificacionValida
    
ErrorCalif:
    ; Mostrar mensaje de error y volver a pedir.
    MOV AH, 09h
    LEA DX, msgCalifInvalida
    INT 21h
    JMP PedirCalif  

CalificacionValida:
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

FormatoCalif PROC                                                   ; Formatea la calificación para un formato adecuado.
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    LEA SI, buffer_calif+2
    XOR DI, DI
    XOR BX, BX
    XOR CX, CX
    MOV DX, 10
    
ValidarLoop:                                                        ; Validación de caracteres numéricos.
    MOV AL, [SI]
    
    CMP AL, '$'                 ; Fin de cadena
    JE  IniciarFormato          ; Saltar directamente al formateo
    CMP AL, 13                  ; Fin (Enter)
    JE  IniciarFormato          ; Saltar directamente al formateo
    CMP AL, '.'                 ; ¿Es punto decimal?
    JE  PuntoValido
    
    ; --- Validar que sea dígito ---
    CMP AL, '0'
    JL  ErrorFormato
    CMP AL, '9'
    JG  ErrorFormato
    
    ; --- Validar máximo 5 decimales ---
    CMP DI, 1                   ; ¿Ya estamos en parte decimal?
    JNE SaltarValidacion        ; Si no, saltar validación de decimales
    
    INC BX                      ; Incrementar contador de decimales
    CMP BX, 6                   ; ¿Más de 5 decimales?
    JG ErrorFormato

SaltarValidacion:
    INC SI
    JMP ValidarLoop

PuntoValido:
    INC DI                      ; Marcar que encontramos punto
    CMP DI, 1                   ; ¿Es el primer punto?
    JNE ErrorFormato            ; Si no, error (múltiples puntos)
    INC SI
    JMP ValidarLoop

ErrorFormato:
    STC
    JMP FinFormato

IniciarFormato:
    LEA SI, buffer_calif+2      ; Reiniciar SI al inicio
    XOR DI, DI                  ; Reiniciar flag de punto
    XOR BX, BX                  ; Reiniciar contador de decimales
    
BuscarPunto:
    MOV AL, [SI]
    CMP AL, '$'                 ; Fin de cadena
    JE  AgregarPuntoYDecimales
    CMP AL, 13                  ; Fin (Enter)
    JE  AgregarPuntoYDecimales
    CMP AL, '.'                 ; ¿Es punto?
    JE  EncontrarPunto
    INC SI
    JMP BuscarPunto

EncontrarPunto:
    MOV DI, 1                   ; Marcar punto encontrado
    INC SI                      ; Saltar el punto
    
ContarDecimales:
    MOV AL, [SI]
    CMP AL, '$'                 ; Fin de cadena
    JE  Rellenar
    CMP AL, 13                  ; Fin (Enter)
    JE  Rellenar
    INC BX                      ; Contar dígito decimal
    INC SI
    JMP ContarDecimales

Rellenar:
    CMP DI, 0                   ; ¿No se encontró punto?
    JE  AgregarPuntoYDecimales  ; Si no, agregar punto y ceros
    
    MOV CX, 5
    SUB CX, BX                  ; CX = ceros faltantes
    JLE FinFormatoOk            ; Si ya tiene 5+ decimales, terminar

    MOV AL, '0'
AgregarCeroLoop:
    MOV [SI], AL                ; Agregar cero
    INC SI
    LOOP AgregarCeroLoop
    MOV BYTE PTR [SI], '$'      ; Terminar cadena
    JMP FinFormatoOk

AgregarPuntoYDecimales:
    MOV BYTE PTR [SI], '.'      ; Agregar punto
    INC SI
    MOV CX, 5                   ; 5 ceros
    MOV AL, '0'
AgregarTodosCeros:
    MOV [SI], AL                ; Agregar cero
    INC SI
    LOOP AgregarTodosCeros
    MOV BYTE PTR [SI], '$'      ; Terminar cadena

FinFormatoOk:
    CLC                         ; Clear Carry Flag = éxito

FinFormato:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
FormatoCalif ENDP

VerifCien PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    
    LEA SI, buffer_calif+2      ; SI apunta al inicio de los datos
    XOR CX, CX                  ; CX = acumulador parte entera
    MOV BX, 10                  ; BX = base 10
    
CalcularEntero:
    MOV AL, [SI]                ; Leer carácter
    CMP AL, '$'                 ; Fin de cadena
    JE  VerificarCien
    CMP AL, 13                  ; Fin (Enter)
    JE  VerificarCien
    CMP AL, '.'                 ; Punto decimal ? fin de parte entera
    JE  VerificarCien
    
    ; Verificar que sea dígito
    CMP AL, '0'
    JL  FinVerifCien             ; Si no es dígito, salir
    CMP AL, '9'
    JG  FinVerifCien             ; Si no es dígito, salir
    
    ; Acumular parte entera
    SUB AL, '0'                 ; Convertir a número
    MOV AH, 0
    PUSH AX
    MOV AX, CX
    MUL BX                      ; CX = CX * 10
    MOV CX, AX
    POP AX
    ADD CX, AX                  ; CX = CX + dígito
    
    INC SI
    JMP CalcularEntero

VerificarCien:
    ; Verificar si la parte entera es >= 100
    CMP CX, 100
    JL  FinVerifCien             ; Si es menor que 100, no hacer nada
    
    ; --- FORZAR A 100.00000 ---
    LEA SI, buffer_calif+2      ; Reiniciar al inicio del buffer
    
    ; Escribir "100.00000"
    MOV BYTE PTR [SI], '1'
    INC SI
    MOV BYTE PTR [SI], '0'
    INC SI
    MOV BYTE PTR [SI], '0'
    INC SI
    MOV BYTE PTR [SI], '.'
    INC SI
    MOV BYTE PTR [SI], '0'
    INC SI
    MOV BYTE PTR [SI], '0'
    INC SI
    MOV BYTE PTR [SI], '0'
    INC SI
    MOV BYTE PTR [SI], '0'
    INC SI
    MOV BYTE PTR [SI], '0'
    INC SI
    MOV BYTE PTR [SI], '$'
    
    ; Actualizar longitud en el buffer
    MOV buffer_calif[1], 9      ; 9 caracteres: "100.00000"

FinVerifCien:
    POP SI
    POP CX
    POP BX
    POP AX
    RET
VerifCien ENDP     

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
    MOV buffer_id, 3          ; Máx 2 dígitos (+Enter)
    LEA DX, buffer_id
    MOV AH, 0Ah              ; Lectura de Cadena
    INT 21h
    
    XOR AX, AX               ; Limpiar AX (acumulador)
    XOR CX, CX               ; Limpiar CX
    MOV BX, 10               ; Base 10
    LEA SI, buffer_id + 2    ; SI apunta al primer carácter

    ; Verificación si ID nulo
    MOV CL, buffer_id + 1    ; Número de caracteres leídos
    CMP CL, 0
    JE IDInvalidoBusqueda

ConversionID:
    MOV CL, [SI]             ; Lectura de caracter
    INC SI                   ; Siguiente posición
    
    CMP CL, 13               ; Verificar si es Enter (fin)
    JE ValidacionID
    
    ; Verifica que sea un dígito
    CMP CL, '0'
    JL IDInvalidoBusqueda
    CMP CL, '9'
    JG IDInvalidoBusqueda
    
    ; Convertir a número
    SUB CL, '0'              ; Conversión ASCII a número
    MOV DX, BX               ; DX = 10
    MUL DX                   ; AX = AX * 10
    JC IDInvalidoBusqueda    ; Overflow: error
    
    ; ¡CORRECCIÓN CRÍTICA AQUÍ!
    ADD AL, CL               ; Sumar el nuevo dígito (8 bits)
    ADC AH, 0                ; Ajustar carry si es necesario
    JC IDInvalidoBusqueda    ; Overflow: error
    
    JMP ConversionID         ; Itera hasta ENTER

ValidacionID:
    ; Validar rango
    CMP AX, 1
    JL IDInvalidoBusqueda    ; Si es menor que 1: inválido
    
    ; Comparación con límite superior
    XOR BX, BX
    MOV BL, contador
    CMP AX, BX
    JG IDInvalidoBusqueda    ; Si es mayor que contador: inválido
    
    ; Convertir a índice base 0
    DEC AX
    MOV temp_index, AL       ; Guardar índice temporalmente
    
    MOV AH, 09h
    LEA DX, nueva_linea
    INT 21h

    MOV AH, 09h
    LEA DX, msgSeparador
    INT 21h

    ; Cargar índice y mostrar
    MOV AL, temp_index
    CALL MostarPorID

    MOV AH, 09h
    LEA DX, msgSeparador
    INT 21h
    
    ; Volver a menú
    MOV AH, 09h
    LEA DX, msgContinuar
    INT 21h
    MOV AH, 01h
    INT 21h
    RET
    
IDInvalidoBusqueda:
    ; ID ingresado inválido
    MOV AH, 09h
    LEA DX, msgIDInvalido
    INT 21h
    MOV AH, 09h
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
    MOV DL, 09h
    INT 21h

    ; Verificar si es mayor a 9
    MOV DL, BL
    INC DL
    CMP DL, 10                                                       ; Verificar cantidad de dígitos al comparar con 10. 
    JB  UnDigito

    ; Con dos dígitos mostrar "1" y luego unidad.
    PUSH DX
    MOV DL, '1'
    INT 21h
    POP DX
    SUB DL, 10                                                      ; DL(unidad) = DL(ínidice) - 10

UnDigito:
    ADD DL, '0'                                                     ; Convertir a ASCII. 
    INT 21h

    MOV DL, '.'
    INT 21h
    MOV DL, 09h
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
    XOR CX, CX                   ; CX = 0 (contador de estudiantes)
    
MostrarEstudiante:
    ; Guardar contador
    PUSH CX
    
    ; Pasar índice a AL y llamar a MostarPorID
    MOV AL, CL
    CALL MostarPorID
    
    POP CX
    
    MOV AH, 09h
    LEA DX, nueva_linea
    INT 21h

    ; Verificar el número de estudiantes mostrados.
    INC CL
    CMP CL, contador
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

; ---< EstadÃ­sticas >---
MostrarEstadisticas PROC
    CALL LimpiarPantalla 

    MOV AH, 09h
    LEA DX, msgT2
    INT 21h

    ; Verificar nÃºmero de registros. 
    MOV AL, contador
    CMP AL, 0
    JNE MostrarStats
    
    ; En caso de que no de haber estudiantes.
    MOV AH, 09h
    LEA DX, msgNoStats
    INT 21h

MostrarStats:
    CALL calcular_porcentajes
    RET

MostrarEstadisticas ENDP 

FinEstadisticas:
    MOV AH, 09h
    LEA DX, msgContinuar
    INT 21h
    MOV AH, 01h
    INT 21h 
    RET

; ---< Ordenar Calificaciones >---
OrdenarCalif PROC
    CALL LimpiarPantalla

    ; TÃ­tulo de la SecciÃ³n.
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

; --- Copiado de buffer en lista especÃ­fica --- 
CopiarCadena PROC                                                   ; SI = direcciÃ³n de cadena a copiar.
    PUSH AX                                                         ; DI = direcciÃ³n destino.
    PUSH CX
    PUSH SI
    PUSH DI
    
CopiarLoop:
    MOV AL, [SI]                                                    ; Cargar carÃ¡cter.
    CMP AL, 0Dh
    JE FinCopia                                                     ; Verificar ENTER.
    CMP AL, 0Ah
    JE SaltarChar                                                   ; Saltar al siguiente caracter. 
    CMP AL, '$'
    JE FinCopia                                                     ; Verificar terminador '$'.
    
    MOV [DI], AL                                                    ; Copiar carÃ¡cter al destino.
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
ImprimirCadena PROC                                                 ; SI posiciÃ³n inicial de la cadena.
    PUSH AX
    PUSH DX
    PUSH SI
    
ImprimirLoop:
    MOV DL, [SI]                                                    ; CarÃ¡cter en apuntado por SI. 
    CMP DL, '$'                                                     ; Verificar terminador.
    JE FinImprimir
    
    ; ImpresiÃ³n de caracter y loop. 
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

; --- Separado lista de strings a listas numÃ©ricas ---
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
    cmp al, '$'              ; ï¿½Fin del string?
    je fin_numero
    cmp al, 13               ; ï¿½Es carriage return?
    je fin_numero
    cmp al, 10               ; ï¿½Es new line?
    je fin_numero
    
    ; Convertir ASCII a nï¿½mero
    sub al, '0'
    mov ah, 0
    push ax                  ; Guardar nuevo dï¿½gito
    
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
    
    ; temp_decimal = temp_decimal + nuevo_dï¿½gito
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
    
    jmp procesar_numero      ; Procesar el siguiente nï¿½mero
    
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
                 
                 
; ==============================================
; PROCEDIMIENTO: BUBBLE_SORT_INDICES
; Ordena los índices en array_BS basado en los valores
; de array_enteros y array_decimales
; ==============================================
BUBBLE_SORT_INDICES PROC
    ; Cargar contador y verificar
    mov al, contador
    mov ah, 0
    mov cx, ax
    cmp cx, 0
    je FIN_SORT
    cmp cx, 1
    je FIN_SORT
    
    ; Inicializar array_BS con índices secuenciales
    mov si, 0
    mov ax, 0
INICIALIZAR_INDICES:
    mov array_BS[si], ax
    add si, 2
    inc ax
    loop INICIALIZAR_INDICES

    ; Bubble sort
    mov al, contador
    mov ah, 0
    mov cx, ax
    dec cx
    
EXTERNO_LOOP:
    push cx
    mov si, 0
    
    mov al, contador
    mov ah, 0
    mov cx, ax
    dec cx
    
INTERNO_LOOP:
    mov ax, array_BS[si]
    mov bx, array_BS[si+2]
    
    ; Comparar partes enteras
    mov di, ax
    shl di, 1
    mov dx, array_enteros[di]
    
    mov di, bx
    shl di, 1
    mov bp, array_enteros[di]
    
    cmp orden, 0
    je ORDEN_ASC
    
    ; ========== ORDEN DESCENDENTE ==========
    cmp dx, bp
    jl NO_SWAP                ; entero[i] < entero[j] ? OK
    jg SWAP_INDICES           ; entero[i] > entero[j] ? SWAP
    ; si iguales ? comparar decimales en DSC
    call COMPARE_DECIMALES
    cmp resultado_dec, 1      ; i.dec > j.dec
    je NO_SWAP
    cmp resultado_dec, 0      ; i.dec < j.dec
    je SWAP_INDICES
    jmp NO_SWAP               ; si iguales ? no swap
    jmp CONTINUAR

ORDEN_ASC:
    ; ========== ORDEN ASCENDENTE ==========
    cmp dx, bp
    jg NO_SWAP                ; entero[i] > entero[j] ? OK
    jl SWAP_INDICES           ; entero[i] < entero[j] ? SWAP
    ; si iguales ? comparar decimales en ASC
    call COMPARE_DECIMALES
    cmp resultado_dec, 1      ; i.dec > j.dec
    je SWAP_INDICES
    cmp resultado_dec, 0      ; i.dec < j.dec
    je NO_SWAP
    jmp NO_SWAP               ; si iguales ? no swap

SWAP_INDICES:
    mov ax, array_BS[si]
    mov bx, array_BS[si+2]
    mov array_BS[si], bx
    mov array_BS[si+2], ax

NO_SWAP:
CONTINUAR:
    add si, 2
    loop INTERNO_LOOP
    
    pop cx
    loop EXTERNO_LOOP
    
FIN_SORT:
    ret
BUBBLE_SORT_INDICES ENDP


; ==============================================
; Pregunar por orden de Bubble Sort
; ==============================================

PREGUNTAR_ORDEN PROC
PREGUNTAR:
    ; Mostrar mensaje de pregunta
    mov ah, 09h
    lea dx, msg_pregunta
    int 21h
    
    ; Leer un solo carácter
    mov ah, 01h
    int 21h
    
    ; Verificar entrada
    cmp al, '1'
    je ES_ASC
    cmp al, '0'
    je ES_DSC
    jmp ERROR_INPUT

ES_ASC:
    mov orden, 1               ; ASC = 1
    jmp FIN_PREGUNTA

ES_DSC:
    mov orden, 0               ; DSC = 0
    jmp FIN_PREGUNTA

ERROR_INPUT:
    ; Mostrar mensaje de error
    mov ah, 09h
    lea dx, msg_error
    int 21h
    jmp PREGUNTAR

FIN_PREGUNTA:
    ret
PREGUNTAR_ORDEN ENDP   



                
                
; ================================
; ordenarListas 
; ================================
ordenarListas PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    
    push ds
    pop es                   ; ES = DS
    
    ; PRIMERO: COPIAR TODO A BUFFERS (respaldo)
    mov cl, contador
    mov ch, 0
    mov ax, tam_nombre + 1
    mul cx
    mov cx, ax
    mov si, offset lista_nombres
    mov di, offset buffer_nombres_ordenados
    rep movsb
    
    mov cl, contador
    mov ch, 0
    mov ax, tam_calif + 1
    mul cx
    mov cx, ax
    mov si, offset lista_califs
    mov di, offset buffer_califs_ordenados
    rep movsb
    
    ; SEGUNDO: REORDENAR COPIANDO DEL BUFFER AL ORIGINAL
    mov cl, contador
    mov ch, 0
    mov si, 0                ; SI = índice para array_BS
    
reordenar:
    mov bx, [array_BS + si]  ; BX = índice original
    and bx, 00FFh            ; Asegurar 8 bits
    
    ; === COPIAR NOMBRE ===
    ; DI = destino en lista original
    mov ax, si               ; AX = posición en array_BS
    shr ax, 1                ; AX = nueva posición (0, 1, 2...)
    mov dl, tam_nombre + 1
    mul dl
    mov di, ax
    add di, offset lista_nombres
    
    ; Calcular origen en buffer (usar DX como temporal)
    mov ax, bx               ; AX = índice original
    mov dl, tam_nombre + 1
    mul dl
    mov temp_reg, ax         ; Usar variable temporal
    mov dx, temp_reg
    add dx, offset buffer_nombres_ordenados
    mov source_ptr, dx       ; Guardar en variable
    
    ; Copiar nombre
    push cx
    push si
    mov cx, tam_nombre + 1
    mov si, source_ptr       ; SI = origen desde variable
    rep movsb                ; BUFFER -> ORIGINAL
    pop si
    pop cx
    
    ; === COPIAR CALIFICACIÓN ===
    ; DI = destino en lista original
    mov ax, si               ; AX = posición en array_BS
    shr ax, 1                ; AX = nueva posición
    mov dl, tam_calif + 1
    mul dl
    mov di, ax
    add di, offset lista_califs
    
    ; Calcular origen en buffer (usar DX como temporal)
    mov ax, bx               ; AX = índice original
    mov dl, tam_calif + 1
    mul dl
    mov temp_reg, ax         ; Usar variable temporal
    mov dx, temp_reg
    add dx, offset buffer_califs_ordenados
    mov source_ptr, dx       ; Guardar en variable
    
    ; Copiar calificación
    push cx
    push si
    mov cx, tam_calif + 1
    mov si, source_ptr       ; SI = origen desde variable
    rep movsb                ; BUFFER -> ORIGINAL
    pop si
    pop cx
    
    add si, 2                ; Siguiente en array_BS
    loop reordenar
    
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ordenarListas ENDP

generar_Max_Min PROC   
    mov al, orden
    cmp al, 1
    je  desc
    cmp al, 0
    je  asce 
    RET

generar_Max_Min ENDP

desc:
    ;Datos organizados de forma descendente
    
    ;Primer dato es el maximo
    mov ah, 9
    lea dx, msgMaxNota
    int 21h
    
    mov al, contador
    dec al
    CALL MostarPorID 
    
    ;Ultimo dato es el minimo
    mov ah, 9
    lea dx, msgMinNota
    int 21h
    
    mov al, 1
    dec al
    CALL MostarPorID 
    RET
asce:
    ;Datos organizados de forma ascendente 
    
    ;Primer dato es el minimo 
    mov ah, 9
    lea dx, msgMinNota
    int 21h
    
    mov al, contador
    dec al
    CALL MostarPorID 
    
    ;Ultimo dato es el maximo
    mov ah, 9
    lea dx, msgMaxNota
    int 21h
    
    mov al, 1  
    dec al
    CALL MostarPorID
    RET

COMPARE_DECIMALES PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; -------------------------
    ; Obtener índices desde array_BS
    ; -------------------------
    mov ax, array_BS[si]      ; índice i
    mov bx, array_BS[si+2]    ; índice j

    ; -------------------------
    ; Calcular offset decimal[i]
    ; -------------------------
    mov dx, ax        ; dx = i
    shl dx, 1
    shl dx, 1         ; dx = i*4
    mov di, dx        ; di = offset de decimal[i]

    mov cx, array_decimales[di]      ; parte baja
    mov dx, array_decimales[di+2]    ; parte alta

    ; -------------------------
    ; Calcular offset decimal[j]
    ; -------------------------
    mov bx, bx        ; bx = j
    shl bx, 1
    shl bx, 1         ; bx = j*4 ? offset j

    mov si, array_decimales[bx]      ; parte baja
    mov bp, array_decimales[bx+2]    ; parte alta

    ; -------------------------
    ; Comparar parte alta
    ; -------------------------
    cmp dx, bp
    ja  DEC_MAYOR
    jb  DEC_MENOR

    ; Si iguales, comparar parte baja
    cmp cx, si
    ja  DEC_MAYOR
    jb  DEC_MENOR

    ; Iguales
    mov resultado_dec, 2
    jmp FIN_COMPARE

DEC_MAYOR:
    mov resultado_dec, 0
    jmp FIN_COMPARE

DEC_MENOR:
    mov resultado_dec, 1

FIN_COMPARE:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
COMPARE_DECIMALES ENDP



END START