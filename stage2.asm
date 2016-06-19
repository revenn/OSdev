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

 ;mov ax, 0xb800
 ;mov fs, ax
 ;mov bx, 0
 ;mov ax, 0x4141
 ;mov [fs:bx], ax
 
; teraz czas przejsc w tryb 64bit, bo w nim bede umieszczal kernel
; aby przejsc w long mode, najpierw musimy uruchomic tryb protected mode
; potem ustawialic tablice segmentow, oraz ustawic kilka flag na procesorze
; segmenty - zalozmy ze mamy pamiec (fizyczna = ram+inne), segmenty to mechanizm
; kazdy segment ma dwie glowne cechy (poczatek, wielkosc), kazdy segmant
; ma swoj "dowolny" nr, np mov [ds:0x10], ... to wrzucimy to cos nie od poczatku
; pamieci tylko od segmentu ds+0x10; segmenty robi sie zwykle w trybie plaskim
; czyli poczatek segmentu jest rowno z zerem a wielkosc rowno z cala przestrze.
; adresowa, zazwyczaj tworzy sie tez jeden segment w ktorym umieszcza sie jakies
; informacje o jakims watku;
; w long mode wszystkie rejestry: ds, cs, ss i es sa w trybie plaskim
; natomiast sa dwa segmenty dodatkowe fs, gs ktore juz mozemy ustawic jak chcemy
; identyfikator segmentu bierze sie stad, segm deklaruje sie w tablice,
; ident to indeks tej tablicy GDT (pole bitowe idx-GDT, 1bit GDT/LDT,
; 2 bity (0 tryb kernelowy, 3 to piercien uzytkownika))
; Global/Local Descriptor Table
; Segmenty, poza standardowymi na dane i kod musi byc tez null segment
; wyzerowany, pusty segmet

; nastepnie trzeba ustawic gdt specjalna instrukcja lgdt ktorej podaje sie adres
; + wielkosc

 lgdt [GDT_addr] ; adres ten jest wczytywany do GDT-R specjalny rejestr na proc
 
 ; ustawianie specjalnych flag
 mov eax, cr0 ; kopiujemy rejestr cr0 do eax
 or eax, 1 ; zapalanie specjalnych bitow
 mov cr0, eax

 ; teraz trzeba wykonac skok dlugi, z przeladowaniem segmentu do tych segmentow
 ; ktore zadeklarowalismy, bez skoku dalej tryb 16bit
 ; oraz jest wywalany caly kod 16bit z cache

 jmp dword 0x8:(0x20000 + start_32) ; niby zaczynamy od org 0x0000 ale tak
 				   ; naprawde caly kod jest na adresie 0x20000


start_32:

 ; hello word!!!!!!!!!11111oneone
 [bits 32]

 ; przeladowanie rejestru DS
 mov ax, 0x10 ; 0x10 bo wczesniej tak zadeklarowalismy
 mov ds, ax
 mov es, ax
 mov ss, ax

 lea eax, [0xb8000]
 mov dword [eax], 0x41414141
 
 jmp $

 GDT_addr:
 dw (GDT_end - GDT) - 1 ; maska
 dd 0x20000 + GDT ; adres fizyczny(doklejone zero),gdzie ten segment sie zaczyna


 times (32 - ($ - $$) % 32) db 0 ; wyrownyjemy tab do 32 bajtow
 ; jesli chcemy debugowac to wrzucamy 0xcc, jest to int3 czyli przerwanie debug
 GDT:
  ; sklada sie z dwoch 32bitowych slow (manual, p. 97)
 
  ; null segment
  dd 0, 0  
  
  ; code segment
  dd 0xffff ; segment limit
  ; type (10 - read/write, przesuniete o 8), sflag, dpl, ...
  dd (10 << 8) | (1 << 12) | (1 << 15) | (0x0f << 16) | (1 << 22) | (1 << 23)

  ; data segment
  dd 0xffff
  dd (2 << 8) | (1 << 12) | (1 << 15) | (0x0f << 16) | (1 << 22) | (1 << 23)

  ; null segment
  db 0, 0
 GDT_end:


;times 1234 db 0x57
