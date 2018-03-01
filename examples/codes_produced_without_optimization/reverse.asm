xseg	segment	public 'code'
	assume	cs:xseg, ds:xseg, ss:xseg
	org	100h

main	proc	near
	call	near ptr _main_0
	mov	ax,4C00h
	int	21h
main	endp

@1: 
_reverse_1	proc	near
	push	bp
	mov	bp,sp
	sub	sp,18

@2: 
	mov	si,word ptr [bp+8]
	push	si
@3: 
	lea	si,word ptr [bp-6]
	push	si
@4: 
	push	bp
	call	near ptr _strlen
	add	sp,6
@5: 
	mov	ax,word ptr [bp-6]
	mov	word ptr [bp-4],ax
@6: 
	mov	ax,0
	mov	word ptr [bp-2],ax
@7: 
	mov	ax,word ptr [bp-2]
	mov	dx,word ptr [bp-4]
	cmp	ax,dx
	jl	@9
@8: 
	jmp	@17
@9: 
	mov	ax,word ptr [bp-2]
	mov	cx,1
	imul	cx
	mov	si,word ptr [bp+4]
	lea	cx,word ptr [si-32]
	add	ax,cx
	mov	word ptr [bp-8],ax
@10: 
	mov	ax,word ptr [bp-4]
	mov	dx,word ptr [bp-2]
	sub	ax,dx
	mov	word ptr [bp-10],ax
@11: 
	mov	ax,word ptr [bp-10]
	mov	dx,1
	sub	ax,dx
	mov	word ptr [bp-12],ax
@12: 
	mov	ax,word ptr [bp-12]
	mov	cx,1
	imul	cx
	mov	cx,word ptr [bp+8]
	add	ax,cx
	mov	word ptr [bp-14],ax
@13: 
	mov	di,word ptr [bp-14]
	mov	al,byte ptr [di]
	mov	di,word ptr [bp-8]
	mov	byte ptr [di],al
@14: 
	mov	ax,word ptr [bp-2]
	mov	dx,1
	add	ax,dx
	mov	word ptr [bp-16],ax
@15: 
	mov	ax,word ptr [bp-16]
	mov	word ptr [bp-2],ax
@16: 
	jmp	@7
@17: 
	mov	ax,word ptr [bp-2]
	mov	cx,1
	imul	cx
	mov	si,word ptr [bp+4]
	lea	cx,word ptr [si-32]
	add	ax,cx
	mov	word ptr [bp-18],ax
@18: 
	mov	al,0
	mov	di,word ptr [bp-18]
	mov	byte ptr [di],al
@19: 
@reverse_1:
	mov	sp,bp
	pop	bp
	ret
_reverse_1	endp

@20: 
_main_0	proc	near
	push	bp
	mov	bp,sp
	sub	sp,32

@21: 
	lea	si,@str1
	push	si
@22: 
	sub	sp,2
	push	bp
	call	near ptr _reverse_1
	add	sp,6
@23: 
	lea	si,word ptr [bp-32]
	push	si
@24: 
	sub	sp,2
	push	bp
	call	near ptr _writeString
	add	sp,6
@25: 
@main_0:
	mov	sp,bp
	pop	bp
	ret
_main_0	endp

@str1	db	13, 10, '!dlrow olleH', 0

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
