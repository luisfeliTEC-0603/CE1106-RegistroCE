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
    
    
    ; salto de linea
    mov ah, 02h  ; Escribir un solo caracter en la salida estandar
    mov dl, 0Dh  ; Se carga 0Dh en DL, Carriage Return, devuelve al inicio de linea actual  
    int 21h      
    mov ah, 02h  ; Escribir un solo carácter en la salida estandar
    mov dl, 0Ah  ; Se carga 0Ah que es Avance de Linea, avanza siguiente fila
    int 21h  
    
    je menu_loop ; Se ejecuta solo si AL tiene 0
    
    
    ; Confirmar dato
    mov ah, 09h
    lea dx, confirmMsg
    int 21h

    jmp ingreso_loop   ; Seguir pidiendo hasta que presione '9'     
    
    ; TODO: 
    ; Guardar estudiantes en espacio de memoria con algun formato

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
; 4. Ordenar Calificaciones
; -------------------------
ordenar_loop:
    mov ah, 09h
    lea dx, ordenarMsg
    int 21h  
    
    ; leer opcion, esta luego es almacenada en AL
    mov ah, 01h
    int 21h
    
    cmp al, '0'
    je menu_loop
    
    cmp al, '1'
    je menu_loop ; Salta a loop de ordenar calificaciones
    
    jmp ordenar_loop 
    
    ; TODO
    ; Acceder a calificaciones y mostrarlas, se debe elegir si es de menor a mayor o al reves
    ; Falta algoritmo de ordenamiento
  
  
  
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
  
datosIngreso db 50       ; 1. Byte 0: Capacidad Maxima
            db ?         ; 2. Byte 1: Longitud Real (la llena DOS)
            db 50 dup(?) ; 3. Byte 2 al 11: Los caracteres ingresados
                                                                       
                                                                       
indice_busqueda db 5    ; 1. Byte 0: Capacidad Maxima
            db ?        ; 2. Byte 1: Longitud Real (la llena DOS)
            db 5 dup(?) ; 3. Byte 2 al 11: Los caracteres ingresados
            
