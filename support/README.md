## Alan program compilation process

1. Compile with alanc to get:
   
`program.asm`

2. Run the assembler:

`masm /Mx program.asm;`

3. Run the linker:

`link /tiny /noignorecase program.obj,program.com,nul,alan.lib;`

