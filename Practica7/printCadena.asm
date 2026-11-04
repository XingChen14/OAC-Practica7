.386
.model flat, stdcall
.stack 4096
option casemap:none

includelib kernel32.lib
GetStdHandle PROTO STDCALL :DWORD
WriteConsoleA PROTO STDCALL :DWORD, :DWORD, :DWORD, :DWORD, :DWORD

STD_OUTPUT_HANDLE equ -11

; Exportar la función para que otros archivos la puedan usar
PUBLIC ImprimirCadena

.data
    
.code

; ==============================================================================
; Función: ImprimirCadena
; Descripción: Calcula la longitud automáticamente y escribe usando WriteConsoleA
; ==============================================================================
ImprimirCadena PROC STDCALL, pCadena:DWORD
    LOCAL caracteresEscritos:DWORD
    LOCAL hStdOut:DWORD

    ; Preservar registros que vamos a alterar
    push ESI
    push ECX

    ; Obtener el manejador de la consola de forma local y segura
    push STD_OUTPUT_HANDLE
    call GetStdHandle
    mov hStdOut, EAX

    ; 1. Determinar la longitud de la cadena automáticamente
    mov ESI, pCadena        ; ESI apunta al inicio de la cadena
    xor ECX, ECX            ; ECX = 0 (contador de longitud)

_loop_calcular_longitud:
    mov AL, byte ptr [ESI]  ; Cargar el carácter actual en AL
    cmp AL, 0               ; ¿Llegamos al terminador nulo?
    je _fin_loop            ; Sí -> salir del bucle
    
    inc ECX                 ; Incrementar longitud
    inc ESI                 ; Avanzar al siguiente byte
    jmp _loop_calcular_longitud

_fin_loop:
    ; Si la longitud es 0, no hay nada que imprimir
    cmp ECX, 0
    je _salir

    ; 2. Preparar los argumentos para WriteConsoleA
    lea EAX, caracteresEscritos
    push 0                  ; lpReserved (debe ser 0)
    push EAX                ; lpNumberOfCharsWritten (puntero a variable local)
    push ECX                ; nNumberOfCharsToWrite (longitud calculada en ECX)
    push pCadena            ; lpBuffer (puntero al texto)
    push hStdOut            ; hConsoleOutput (manejador de la consola)
    
    call WriteConsoleA

_salir:
    ; Restaurar registros en orden inverso
    pop ECX
    pop ESI

    RET
ImprimirCadena ENDP

END