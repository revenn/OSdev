[bits 16]
[org 0x7c00] ; traktuj ten kod jakby byl pod tym adresem
; kiedy BIOS zaczyna szukac bootloadera
; to szuka go pod specyficznym ustandaryzowanym adresem
; 0x7c00
; Adresy w 16bit trybie x86 wyraza sie jako
; SEGMENT:OFFSET
; adres = segment * 0x10 + offset
; SEGMENT znajduje sie w rejestrze segmentowym CS
; dalej mamy rejestr IP ktory wskazuje na nast. instrukcje
; zwykle wyglada to tak lub tak:
; CS 7c00 0000
; IP 0000 7c00
; zeby poradzic sobie z roznymi biosami ktore roznie podstawiaja te rejestry 

; w 16bit mode mozemy zaadresowac tylko 1 MB pamieci, poczatek tej pamieci to
; I.V. table, potem mamy miejsce na bootsector, potem mamy miejsce gdzie mamy
; vram (pamiec karty graficznej)

;jmp $	;EB FE skok w to samo miejsce, petla nieskonczona

jmp word 0000:start ; ta instrukcja jest juz na adresie 7c00

start:
; teraz na pewno mamy segment zero i IP zgodne z tym org

; http://www.ctyme.com/rbrown.htm
; funkcje BIOS mozna wykonywac za pomoca przerwania nr 13
; konkretnie  DISK - READ SECTOR(S) INTO MEMORY

 mov ax, 0x2000 ; segment = 2000, offset = 0000
 mov es, ax      ; adres pod jaki chcemy wrzucic 
 xor bx, bx      ; bx = 0

 mov ah, 2
 mov al, 0xcc	 ; ile sektorow chcemy wczytac, wczytamy stage2, sektor ok 512B
 nop		 ; zamiast 3 wrzucamy unikatowy opcode ktory pozniej bedzie nam
 nop		 ; latwo znalezc, zeby podmienic go na konkretna wartosc w skrypcie
		 ; .py, ma to na celu nie poprawianie za kazdym razem ilosci
		 ; wrzucanych sektorow (kiedy plik stage2 nam sie zmienia)

 mov ch, 0	 ; 3*512 = 1218 (stage2)
 mov cl, 2	 ; sektory liczymy od 1
 mov dh, 0
 int 13h

 ; jmp to stage2
 jmp word 0x2000:0x0000

 ; tu procesor nigdy nie dojdzie


 ; dyskietka oraz bootsektor musi miec na koncu ustawione
 ; dwa bajty 0xaa55, calosc razem 512 bajtow
 complete:
 %if ($ - $$) > 510
   %fatal "Bootloader code execeed 512 bytes"
 %endif

 times 510 - ($ - $$) db 0 ; powtorz x razy wrzucenie zero
 db 0x55
 db 0xaa
