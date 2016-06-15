[bits 16]
; kiedy BIOS zaczyna szukac bootloadera
; to szuka go pod specyficznym ustandaryzowanym adresem
; 0x7c00
; Adresy w 16bit trybie x86 wyraza sie jako
; SEGMENT:OFFSET
; adres = segment * 0x10 + offset
; SEGMENT znajduje sie w rejestrze segmentowym CS
; dalej mamy rejestr IP ktory wskazuje na nast. instrukcje

jmp $	;EB FE skok w to samo miejsce, petla nieskonczona

