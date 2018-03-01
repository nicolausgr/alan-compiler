xseg	segment	public 'code'
	assume	cs:xseg, ds:xseg, ss:xseg
	org	100h

main	proc	near
	call	near ptr _main_0
	mov	ax,4C00h
	int	21h
main	endp

@1: 
_prime_1	proc	near
	push	bp
	mov	bp,sp
	sub	sp,14

@2: 
	mov	ax,word ptr [bp+8]
	mov	dx,0
	cmp	ax,dx
	jl	@4
@3: 
	jmp	@11
@4: 
	mov	ax,0
	mov	dx,word ptr [bp+8]
	sub	ax,dx
	mov	word ptr [bp-4],ax
@5: 
	mov	ax,word ptr [bp-4]
	push	ax
@6: 
	lea	si,word ptr [bp-6]
	push	si
@7: 
	push	word ptr [bp+4]
	call	near ptr _prime_1
	add	sp,6
@8: 
	mov	ax,word ptr [bp-6]
	mov	si,word ptr [bp+6]
	mov	word ptr [si],ax
@9: 
	jmp	@prime_1
@10: 
	jmp	@41
@11: 
	mov	ax,word ptr [bp+8]
	mov	dx,2
	cmp	ax,dx
	jl	@13
@12: 
	jmp	@16
@13: 
	mov	ax,0
	mov	si,word ptr [bp+6]
	mov	word ptr [si],ax
@14: 
	jmp	@prime_1
@15: 
	jmp	@41
@16: 
	mov	ax,word ptr [bp+8]
	mov	dx,2
	cmp	ax,dx
	je	@18
@17: 
	jmp	@21
@18: 
	mov	ax,1
	mov	si,word ptr [bp+6]
	mov	word ptr [si],ax
@19: 
	jmp	@prime_1
@20: 
	jmp	@41
@21: 
	mov	ax,word ptr [bp+8]
	cwd
	mov	cx,2
	idiv	cx
	mov	word ptr [bp-8],dx
@22: 
	mov	ax,word ptr [bp-8]
	mov	dx,0
	cmp	ax,dx
	je	@24
@23: 
	jmp	@27
@24: 
	mov	ax,0
	mov	si,word ptr [bp+6]
	mov	word ptr [si],ax
@25: 
	jmp	@prime_1
@26: 
	jmp	@41
@27: 
	mov	ax,3
	mov	word ptr [bp-2],ax
@28: 
	mov	ax,word ptr [bp+8]
	cwd
	mov	cx,2
	idiv	cx
	mov	word ptr [bp-10],ax
@29: 
	mov	ax,word ptr [bp-2]
	mov	dx,word ptr [bp-10]
	cmp	ax,dx
	jle	@31
@30: 
	jmp	@39
@31: 
	mov	ax,word ptr [bp+8]
	cwd
	mov	cx,word ptr [bp-2]
	idiv	cx
	mov	word ptr [bp-12],dx
@32: 
	mov	ax,word ptr [bp-12]
	mov	dx,0
	cmp	ax,dx
	je	@34
@33: 
	jmp	@36
@34: 
	mov	ax,0
	mov	si,word ptr [bp+6]
	mov	word ptr [si],ax
@35: 
	jmp	@prime_1
@36: 
	mov	ax,word ptr [bp-2]
	mov	dx,2
	add	ax,dx
	mov	word ptr [bp-2],ax
@37: 
@38: 
	jmp	@28
@39: 
	mov	ax,1
	mov	si,word ptr [bp+6]
	mov	word ptr [si],ax
@40: 
@41: 
@prime_1:
	mov	sp,bp
	pop	bp
	ret
_prime_1	endp

@42: 
_main_0	proc	near
	push	bp
	mov	bp,sp
	sub	sp,30

@43: 
	lea	si,@str1
	push	si
@44: 
	sub	sp,2
	push	bp
	call	near ptr _writeString
	add	sp,6
@45: 
	lea	si,word ptr [bp-8]
	push	si
@46: 
	push	bp
	call	near ptr _readInteger
	add	sp,4
@47: 
	mov	ax,word ptr [bp-8]
	mov	word ptr [bp-2],ax
@48: 
	lea	si,@str2
	push	si
@49: 
	sub	sp,2
	push	bp
	call	near ptr _writeString
	add	sp,6
@50: 
	mov	ax,0
	mov	word ptr [bp-6],ax
@51: 
	mov	ax,word ptr [bp-2]
	mov	dx,2
	cmp	ax,dx
	jge	@53
@52: 
	jmp	@59
@53: 
	mov	ax,word ptr [bp-6]
	mov	dx,1
	add	ax,dx
	mov	word ptr [bp-6],ax
@54: 
@55: 
	mov	ax,2
	push	ax
@56: 
	sub	sp,2
	push	bp
	call	near ptr _writeInteger
	add	sp,6
@57: 
	lea	si,@str3
	push	si
@58: 
	sub	sp,2
	push	bp
	call	near ptr _writeString
	add	sp,6
@59: 
	mov	ax,word ptr [bp-2]
	mov	dx,3
	cmp	ax,dx
	jge	@61
@60: 
	jmp	@67
@61: 
	mov	ax,word ptr [bp-6]
	mov	dx,1
	add	ax,dx
	mov	word ptr [bp-6],ax
@62: 
@63: 
	mov	ax,3
	push	ax
@64: 
	sub	sp,2
	push	bp
	call	near ptr _writeInteger
	add	sp,6
@65: 
	lea	si,@str4
	push	si
@66: 
	sub	sp,2
	push	bp
	call	near ptr _writeString
	add	sp,6
@67: 
	mov	ax,6
	mov	word ptr [bp-4],ax
@68: 
	mov	ax,word ptr [bp-4]
	mov	dx,word ptr [bp-2]
	cmp	ax,dx
	jle	@70
@69: 
	jmp	@101
@70: 
	mov	ax,word ptr [bp-4]
	mov	dx,1
	sub	ax,dx
	mov	word ptr [bp-14],ax
@71: 
	mov	ax,word ptr [bp-14]
	push	ax
@72: 
	lea	si,word ptr [bp-16]
	push	si
@73: 
	push	bp
	call	near ptr _prime_1
	add	sp,6
@74: 
	mov	ax,word ptr [bp-16]
	mov	dx,1
	cmp	ax,dx
	je	@76
@75: 
	jmp	@83
@76: 
	mov	ax,word ptr [bp-6]
	mov	dx,1
	add	ax,dx
	mov	word ptr [bp-6],ax
@77: 
@78: 
	mov	ax,word ptr [bp-4]
	mov	dx,1
	sub	ax,dx
	mov	word ptr [bp-20],ax
@79: 
	mov	ax,word ptr [bp-20]
	push	ax
@80: 
	sub	sp,2
	push	bp
	call	near ptr _writeInteger
	add	sp,6
@81: 
	lea	si,@str5
	push	si
@82: 
	sub	sp,2
	push	bp
	call	near ptr _writeString
	add	sp,6
@83: 
	mov	ax,word ptr [bp-4]
	mov	dx,word ptr [bp-2]
	cmp	ax,dx
	jne	@85
@84: 
	jmp	@98
@85: 
	mov	ax,word ptr [bp-4]
	mov	dx,1
	add	ax,dx
	mov	word ptr [bp-22],ax
@86: 
	mov	ax,word ptr [bp-22]
	push	ax
@87: 
	lea	si,word ptr [bp-24]
	push	si
@88: 
	push	bp
	call	near ptr _prime_1
	add	sp,6
@89: 
	mov	ax,word ptr [bp-24]
	mov	dx,1
	cmp	ax,dx
	je	@91
@90: 
	jmp	@98
@91: 
	mov	ax,word ptr [bp-6]
	mov	dx,1
	add	ax,dx
	mov	word ptr [bp-6],ax
@92: 
@93: 
	mov	ax,word ptr [bp-4]
	mov	dx,1
	add	ax,dx
	mov	word ptr [bp-28],ax
@94: 
	mov	ax,word ptr [bp-28]
	push	ax
@95: 
	sub	sp,2
	push	bp
	call	near ptr _writeInteger
	add	sp,6
@96: 
	lea	si,@str6
	push	si
@97: 
	sub	sp,2
	push	bp
	call	near ptr _writeString
	add	sp,6
@98: 
	mov	ax,word ptr [bp-4]
	mov	dx,6
	add	ax,dx
	mov	word ptr [bp-4],ax
@99: 
@100: 
	jmp	@68
@101: 
	lea	si,@str7
	push	si
@102: 
	sub	sp,2
	push	bp
	call	near ptr _writeString
	add	sp,6
@103: 
	mov	ax,word ptr [bp-6]
	push	ax
@104: 
	sub	sp,2
	push	bp
	call	near ptr _writeInteger
	add	sp,6
@105: 
	lea	si,@str8
	push	si
@106: 
	sub	sp,2
	push	bp
	call	near ptr _writeString
	add	sp,6
@107: 
@main_0:
	mov	sp,bp
	pop	bp
	ret
_main_0	endp

@str1	db	'Limit: ', 0
@str2	db	'Primes:', 13, 10, 0
@str3	db	13, 10, 0
@str4	db	13, 10, 0
@str5	db	13, 10, 0
@str6	db	13, 10, 0
@str7	db	13, 10, 'Total: ', 0
@str8	db	13, 10, 0

	extrn	_writeInteger : proc
	extrn	_writeByte    : proc
	extrn	_writeChar    : proc
	extrn	_writeString  : proc
	extrn	_readInteger  : proc
	extrn	_readByte     : proc
	extrn	_readChar     : proc
	extrn	_readString   : proc
	extrn	_extend       : proc
	extrn	_shrink       : proc
	extrn	_strlen       : proc
	extrn	_strcmp       : proc
	extrn	_strcpy       : proc
	extrn	_strcat       : proc

xseg	ends
	end	main
