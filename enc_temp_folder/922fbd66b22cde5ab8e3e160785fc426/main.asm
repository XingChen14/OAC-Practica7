.386
.model flat, stdcall
.stack 4096
option casemap:none

includelib kernel32.lib
ExitProcess PROTO STDCALL :DWORD

; Declarar que la función externa existe en otro módulo
ImprimirCadena PROTO STDCALL :DWORD
LeerCadena     PROTO STDCALL :DWORD
LeerNumero     PROTO STDCALL 
ImprimirNumero PROTO STDCALL :SDWORD

.data
	mensaje0 DB "Actividad 1", 13, 10, 0
	mensaje1 DB "Cadena Corta.", 13, 10, 0
    mensaje2 DB "Cadena Larga----------------!", 13, 10, 0

    msgPeticion  db "Actividad 2 - Ingresa un texto: ", 0
    msgConfirmar db 13, 10, "Texto capturado: ", 0  ; Añadido un salto de línea estético
    buffer       db 131 dup(?)

    msgPedir     db "Actividad 3 - Ingresa un numero: ", 0
    msgRespuesta db "El valor del numero es: ", 0
    saltoLinea   db 13, 10, 0

    hStdOut      dd 0

.code
main PROC
    ;--------------------------------------------------------------------------------
    ;Actividad 1
    ;--------------------------------------------------------------------------------
	; Llamadas a la función externa pasando solo la dirección
    PUSH OFFSET mensaje0
    CALL ImprimirCadena
    
    PUSH OFFSET mensaje1
    CALL ImprimirCadena

    PUSH OFFSET mensaje2
    CALL ImprimirCadena

    ;--------------------------------------------------------------------------------
    ;Actividad 2
    ;--------------------------------------------------------------------------------
    ; 1. Imprimir la petición usando nuestra función automática
    push offset msgPeticion
    call ImprimirCadena

    ; 2. Leer el texto del usuario de forma segura
    push offset buffer
    call LeerCadena

    ; 3. Imprimir el mensaje de confirmación
    push offset msgConfirmar
    call ImprimirCadena

    ; 4. Imprimir el texto que el usuario ingresó (también automático)
    push offset buffer
    call ImprimirCadena

    ; 5. Imprimir un salto de línea estético
    push offset saltoLinea
    call ImprimirCadena

    ;--------------------------------------------------------------------------------
    ;Actividad 3
    ;--------------------------------------------------------------------------------
    ; 1. Imprimir la petición utilizando nuestra función de cadenas
    push offset msgPedir
    call ImprimirCadena

    ; 2. Leer el número ingresado por el usuario (la función LeerNumero procesa el texto y retorna el entero en EAX)
    call LeerNumero        
    mov ebx, eax           ; Respaldar el número entero obtenido en el registro EBX

    ; 3. Imprimir el mensaje de respuesta previo al resultado
    push offset msgRespuesta
    call ImprimirCadena

    ; 4. Imprimir el número entero almacenado en EBX usando ImprimirNumero
    push ebx
    call ImprimirNumero    

    ; 5. Imprimir un salto de línea estético al finalizar
    push offset saltoLinea
    call ImprimirCadena


    ; Salir del programa
	PUSH 0
    CALL ExitProcess
main ENDP
END main