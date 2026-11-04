.386
.model flat, stdcall
.stack 4096
option casemap:none

includelib kernel32.lib
GetStdHandle PROTO STDCALL :DWORD
ReadConsoleA PROTO STDCALL :DWORD, :DWORD, :DWORD, :DWORD, :DWORD

STD_INPUT_HANDLE equ -10

; Exportar la función para que otros archivos la puedan usar
PUBLIC LeerCadena

.data
    leidos dd 0

.code

; ==============================================================================
; Función: LeerCadena
; Descripción: Lee texto desde la consola de forma segura (hasta 128 caracteres),
;              elimina los caracteres \r\n del final y añade el terminador nulo (0).
; ==============================================================================
LeerCadena PROC STDCALL, pBuffer:DWORD
    LOCAL hStdIn:DWORD
    
    ; Preservar los registros que vamos a modificar
    push EAX
    push ECX
    push EDX

    push STD_INPUT_HANDLE
    call GetStdHandle
    mov hStdIn, eax

    push 0                  
    push offset leidos 
    push 130                
    push pBuffer            
    push hStdIn             
    call ReadConsoleA
    
    mov eax, leidos   
    cmp eax, 2
    jl fin_funcion

    mov edx, pBuffer
    add edx, eax
    sub edx, 2

    cmp byte ptr [edx], 0Dh
    jne no_crlf
    cmp byte ptr [edx+1], 0Ah
    jne no_crlf
    mov byte ptr [edx], 0
    jmp fin_funcion

no_crlf:
    mov edx, pBuffer
    add edx, eax
    mov byte ptr [edx], 0

fin_funcion:
    pop edx
    pop ecx
    pop eax
    ret
LeerCadena ENDP

END