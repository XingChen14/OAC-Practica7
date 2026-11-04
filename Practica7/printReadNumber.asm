.386
.model flat, stdcall
.stack 4096
option casemap:none

includelib kernel32.lib
GetStdHandle PROTO STDCALL :DWORD
WriteConsoleA PROTO STDCALL :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
ReadConsoleA PROTO STDCALL :DWORD, :DWORD, :DWORD, :DWORD, :DWORD

STD_INPUT_HANDLE  equ -10
STD_OUTPUT_HANDLE equ -11

; Exportar las funciones para que puedan ser utilizadas desde otros archivos
PUBLIC LeerNumero
PUBLIC ImprimirNumero

.data
    ; Búferes y variables internas compartidas para las conversiones
    bufferTemp  db 32 dup(0)
    inputBuffer db 32 dup(0)
    rwCount     dd 0

.code

; ==============================================================================
; Función: LeerNumero
; Descripción: Lee una cadena numérica desde la consola, procesa el signo negativo,
;              convierte los caracteres ASCII a un entero de 32 bits con signo 
;              y devuelve el resultado numérico directamente en el registro EAX.
; ==============================================================================
LeerNumero PROC STDCALL
    push ecx
    push edx
    push ebx
    push esi

    ; 1. Obtener el manejador de la entrada estándar (consola)
    push STD_INPUT_HANDLE
    call GetStdHandle
    
    ; 2. Capturar el texto ingresado por el usuario usando ReadConsoleA
    push 0
    push offset rwCount
    push 30                 ; Tamaño máximo de caracteres a leer
    push offset inputBuffer
    push eax                ; Manejador de entrada
    call ReadConsoleA
    
    ; 3. Limpiar los caracteres de retorno de carro y salto de línea (\r\n) del final
    mov ecx, rwCount
    cmp ecx, 2
    jl _fin_lectura         ; Si se leyó muy poco, omitir limpieza de CRLF
    mov byte ptr [inputBuffer + ecx - 2], 0  ; Reemplazar \r por terminador nulo

    ; 4. Inicializar variables para la conversión de texto a entero
    xor eax, eax            ; EAX almacenará el resultado numérico acumulado
    xor ecx, ecx            ; ECX funcionará como índice del búfer
    mov ebx, 10             ; Base decimal 10 para las multiplicaciones
    
    mov esi, 1              ; ESI almacenará el signo (1 = positivo, -1 = negativo)
    cmp byte ptr [inputBuffer], '-' ; ¿El primer carácter es un signo menos?
    jne _ciclo              
    
    mov esi, -1             ; Marcar el número como negativo
    inc ecx                 ; Saltar el carácter '-' para iniciar la conversión de dígitos

_ciclo:
    ; Cargar el siguiente byte/carácter de la cadena de entrada
    movzx edx, byte ptr [inputBuffer + ecx]
    
    cmp dl, 0               ; ¿Llegamos al terminador nulo (fin de cadena)?
    je _fin_conversion

    sub dl, 48              ; Convertir de carácter ASCII a valor numérico (ej. '5' -> 5)
    
    ; Algoritmo de conversión: Acumulador = (Acumulador * 10) + Dígito actual
    push edx
    mul ebx                 ; EAX = EAX * 10
    pop edx
    add eax, edx            ; EAX = EAX + Dígito
    
    inc ecx                 ; Avanzar al siguiente carácter
    jmp _ciclo

_fin_conversion:
    ; Aplicar el signo correspondiente guardado en ESI (-1 o 1)
    imul eax, esi

_fin_lectura:
    ; Restaurar registros en orden inverso y retornar con el valor en EAX
    pop esi
    pop ebx
    pop edx
    pop ecx
    ret
LeerNumero ENDP


; ==============================================================================
; Función: ImprimirNumero
; Descripción: Toma un número entero de 32 bits con signo desde el parámetro,
;              lo convierte dinámicamente a cadena de caracteres (manejando 
;              números negativos con '-') y lo imprime en consola con WriteConsoleA.
; ==============================================================================
ImprimirNumero PROC STDCALL, valor:SDWORD
    LOCAL hStdOutLoc:DWORD  ;
    
    push eax
    push ebx
    push ecx
    push edx

    ; Obtener el manejador de la consola de salida estándar
    push STD_OUTPUT_HANDLE
    call GetStdHandle
    mov hStdOutLoc, eax

    mov eax, valor          ; Cargar el número a procesar
    
    ; Evaluar si el número es positivo o negativo
    cmp eax, 0
    jge _es_positivo
    
    ; Si es negativo, guardarlo temporalmente e imprimir el signo '-' primero
    push eax
    
    mov byte ptr [bufferTemp], '-'
    push 0
    push offset rwCount
    push 1                  ; Longitud 1 (el carácter '-')
    push offset bufferTemp
    push hStdOutLoc
    call WriteConsoleA
    
    pop eax
    neg eax                 ; Convertir temporalmente a positivo para extraer sus dígitos

_es_positivo:
    mov ebx, 10             ; Divisor para extracciones sucesivas en base 10
    xor ecx, ecx            ; ECX contará cuántos dígitos extraemos

_loop_dividir:
    xor edx, edx
    div ebx                 ; EAX = Cociente, EDX = Residuo (dígito actual de derecha a izquierda)
    
    add dl, 48              ; Convertir residuo numérico a su representación ASCII
    push dx                 ; Guardar el dígito en la pila temporalmente
    inc ecx                 ; Incrementar contador de dígitos
    
    test eax, eax           ; ¿El cociente es cero?
    jnz _loop_dividir       ; Si aún hay dígitos, repetir

_loop_imprimir:
    ; Extraer los dígitos en orden correcto (de izquierda a derecha) desde la pila
    pop dx
    mov byte ptr [bufferTemp], dl
    
    push ecx                ; Respaldar contador de bucle
    
    push 0
    push offset rwCount
    push 1                  ; Imprimir carácter por carácter
    push offset bufferTemp
    push hStdOutLoc
    call WriteConsoleA
    
    pop ecx                 ; Restaurar contador de bucle
    
    dec ecx
    cmp ecx, 0
    jg _loop_imprimir

    ; Restaurar registros de uso general
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
ImprimirNumero ENDP

END