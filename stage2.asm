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
 mov ax, 0x10 ; 0x10 gdt_idx (moze byc 00, 01, 10, 11)
 mov ds, ax
 mov es, ax
 mov ss, ax

 ;lea eax, [0xb8000]
 ;mov dword [eax], 0x41414141
 
 ; wlaczenie 64biy
 ; wrzucamy adres tablicy stronnicowania do cr3
 mov eax, (PML4 - $$) + 0x20000
 mov cr3, eax

 ; wlaczanie PAE
 mov eax, cr4
 or eax, 1 << 5
 mov cr4, eax

 mov ecx, 0xC0000080 ; EFER, podajemy nr rejestru w ECX
 rdmsr ; msr zostaje wrzucony do eax (jego nr podalem wyzej)
 or eax, 1 << 8 ; ustawiam 8 bit
 wrmsr ; wrzucam z powrotem zawartosc eax do msr

 ; wlaczamy stronnicowanie
 mov eax, cr0
 or eax, 1 << 31
 mov cr0, eax

 lgdt [GDT64_addr + 0x20000]
 jmp dword 0x8:(0x20000 + start64)

start64:
 ; tu zaczyna sie kod 64bitowy
 [bits 64]
 ; przeladowanie rejestru DS
 mov ax, 0x10 ; 0x10 gdt_idx (moze byc 00, 01, 10, 11)
 mov ds, ax
 mov es, ax
 mov ss, ax

 ;mov rax, 0xb8000
 ;mov rdx, 0x4141414141414141
 ;mov [rax], rdx


 ; Loader ELF - pliku wykonywalnego linuxowego
loader:
 mov rsi, [0x20000 + kernel64 + 0x20] ; wrzucamy gdzie zaczyna sie nasz kernel
				      ; + offset (phoff) z naglowku ELF
 add rsi, 0x20000 + kernel64 ; poczatek pliku
 
 movzx ecx, word[0x20000 + kernel64 + 0x38] ; phnum, liczba sekcji w pliku
					    ; .code, .data, .bss itd
 cld ; clear direction flag, zeby instrukcja movsb dobrze dzialala

 xor r14, r14 ; first pt_load pv_vaddr

 .ph_loop:
   mov eax, [rsi + 0]
   cmp eax, 1 ; sprawdzamy czy rsi to pt_load
   jne .next

   ; kopiowanie segmentu
   mov r8d, [rsi + 8] ; p_offset
   mov r9d, [rsi + 0x10] ; p_vaddr
   mov r10d, [rsi + 0x20] ; p_filesz

   test r14, r14 ; spr czy r14 = 0
   jnz .skip
   mov r14, r9 ; przy pierwszym przejscu wykona sie, pozniej juz nie
   .skip:

   ; backup
   mov rbp, rsi
   mov r15, rcx

   lea rsi, [0x20000 + kernel64 + r8d] ; wrzucamy gdzie dane sa
   mov rdi, r9 ; bo jest tam informacja ile danych trzeba skopiowac
   mov rcx, r10
   rep movsb

   mov rcx, r15
   mov rsi, rbp
   .next:
   loop .ph_loop


 
; tam gdzie wrzucamy kernel, cala przestrzen, wszystko powinno byc wyzerowane

 ; skocz do EP(entrypointing)
 mov rax, [0x20000 + kernel64 + 0x18]
 mov rdi, r14 ; rdi pierwszy parametr funkcji

 ; fix stack
 mov rsp, 0x30f000

 call rax ; skaczemy do naszego pliku kernela


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

 ; MSR - rejestry do konfiguracji procesora, adresuje sie je za pomoca nr
 ; paging - dostajemy do dyspozycji pamiec wirtualna, po polsku stronnicowanie
 ; paging pozwala na jakas ochrone uprawnien pamieci np do odczytu, zapisu
 ; adres w 64bitowym trybie maja 48bitow, gorne bity za zazwyczaj wyzerowane
 ; zaczynamy od tworzenia gdt-64bit, jest takie same tylko ze zmienia sie 
 ; kilka bitow


 GDT64_addr:
 dw (GDT64_end - GDT64) - 1 ; maska
 dd 0x20000 + GDT64

 times (32 - ($ - $$) % 32) db 0 ; wyrownyjemy tab do 32 bajtow
 ; jesli chcemy debugowac to wrzucamy 0xcc, jest to int3 czyli przerwanie debug
 GDT64:
  ; sklada sie z dwoch 32bitowych slow (manual, p. 97)

  ; null segment
  dd 0, 0

  ; code segment
  dd 0xffff ; segment limit
  ; 21 bit zapalamy, 22 bit gasimy
  dd (10 << 8) | (1 << 12) | (1 << 15) | (0x0f << 16) | (1 << 21) | (1 << 23)

  ; data segment
  dd 0xffff
  dd (2 << 8) | (1 << 12) | (1 << 15) | (0x0f << 16) | (1 << 22) | (1 << 23)

  ; null segment
  db 0, 0
 GDT64_end:

; stronnicowanie/paging
; ustawianie pml4
times (4096 - ($ - $$) % 4096) db 0 ; wyrownanie do 4 KB || && - current section

PML4:
dq 1 | (1 << 1) | (PDPTE - $$ + 0x20000) ; pdpte to wskaznik do kolejnej czesci
times 511 dq 0

;tu tez wciaz wszystko wyrownane do 4 KB

; strony maja po 1GB bo tak zdecydowalem

PDPTE:
dq 1 | (1 << 1) | (1 << 7)
times 511 dq 0

; label przyda sie do okreslenia odresu pod ktorym zaczyna sie kernel
; poniewaz jest on doklejany od razu po stage2
times (512 - ($ - $$) % 512) db 0
kernel64:
