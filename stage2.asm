[bits 16]
[org 0x0000]
; udalo sie, jestesmy w drugim pliku

start:
 mov ax, 0x2000 ; wrzucamy nr segmentu
 mov ds, ax
 mov es, ax ; wrzucamy adres do rejestrow segmentowych

 mov ax, 0x1f00
 mov ss, ax ; tworzymy stos, ss to rejestr seg na stos
 xor sp, sp ; stos bedzie rosl w strone adresow zeowych, nasz kod w druga

 mov ax, 0xb800
 mov fs, ax
 mov bx, 0
 mov ax, 0x4141
 mov [fs:bx], ax
 
; teraz czas przejsc w tryb 64bit, bo w nim bede umieszczal kernel


 jmp $

times 1234 db 0x57
