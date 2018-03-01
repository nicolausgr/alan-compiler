xseg	segment	public 'code'
	assume	cs:xseg, ds:xseg, ss:xseg
	org	100h

main	proc	near
	call	near ptr _main_0
	mov	ax,4C00h
	int	21h
main	endp

@1: 
_swap_2	proc	near
	push	bp
	mov	bp,sp
	sub	sp,2

@2: 
	mov	si,word ptr [bp+10]
	mov	ax,word ptr [si]
	mov	word ptr [bp-2],ax
@3: 
	mov	si,word ptr [bp+8]
	mov	ax,word ptr [si]
	mov	si,word ptr [bp+10]
	mov	word ptr [si],ax
@4: 
	mov	ax,word ptr [bp-2]
	mov	si,word ptr [bp+8]
	mov	word ptr [si],ax
@5: 
@swap_2:
	mov	sp,bp
	pop	bp
	ret
_swap_2	endp

@6: 
_bsort_1	proc	near
	push	bp
	mov	bp,sp
	sub	sp,19

@7: 
	mov	al,121
	mov	byte ptr [bp-1],al
@8: 
	mov	al,byte ptr [bp-1]
	mov	dl,121
	cmp	al,dl
	je	@10
@9: 
	jmp	@31
@10: 
	mov	al,110
	mov	byte ptr [bp-1],al
@11: 
	mov	ax,0
	mov	word ptr [bp-3],ax
@12: 
	mov	ax,word ptr [bp+10]
	mov	dx,1
	sub	ax,dx
	mov	word ptr [bp-5],ax
@13: 
	mov	ax,word ptr [bp-3]
	mov	dx,word ptr [bp-5]
	cmp	ax,dx
	jl	@15
@14: 
	jmp	@8
@15: 
	mov	ax,word ptr [bp-3]
	mov	cx,2
	imul	cx
	mov	cx,word ptr [bp+8]
	add	ax,cx
	mov	word ptr [bp-7],ax
@16: 
	mov	ax,word ptr [bp-3]
	mov	dx,1
	add	ax,dx
	mov	word ptr [bp-9],ax
@17: 
	mov	ax,word ptr [bp-9]
	mov	cx,2
	imul	cx
	mov	cx,word ptr [bp+8]
	add	ax,cx
	mov	word ptr [bp-11],ax
@18: 
	mov	di,word ptr [bp-7]
	mov	ax,word ptr [di]
	mov	di,word ptr [bp-11]
	mov	dx,word ptr [di]
	cmp	ax,dx
	jg	@20
@19: 
	jmp	@27
@20: 
	mov	ax,word ptr [bp-3]
	mov	cx,2
	imul	cx
	mov	cx,word ptr [bp+8]
	add	ax,cx
	mov	word ptr [bp-13],ax
@21: 
	mov	si,word ptr [bp-13]
	push	si
@22: 
	mov	ax,word ptr [bp-3]
	mov	dx,1
	add	ax,dx
	mov	word ptr [bp-15],ax
@23: 
	mov	ax,word ptr [bp-15]
	mov	cx,2
	imul	cx
	mov	cx,word ptr [bp+8]
	add	ax,cx
	mov	word ptr [bp-17],ax
@24: 
	mov	si,word ptr [bp-17]
	push	si
@25: 
	sub	sp,2
	push	bp
	call	near ptr _swap_2
	add	sp,8
@26: 
	mov	al,121
	mov	byte ptr [bp-1],al
@27: 
	mov	ax,word ptr [bp-3]
	mov	dx,1
	add	ax,dx
	mov	word ptr [bp-19],ax
@28: 
	mov	ax,word ptr [bp-19]
	mov	word ptr [bp-3],ax
@29: 
	jmp	@12
@30: 
	jmp	@8
@31: 
@bsort_1:
	mov	sp,bp
	pop	bp
	ret
_bsort_1	endp

@32: 
_writeArray_3	proc	near
	push	bp
	mov	bp,sp
	sub	sp,6

@33: 
	mov	si,word ptr [bp+12]
	push	si
@34: 
	sub	sp,2
	push	bp
	call	near ptr _writeString
	add	sp,6
@35: 
	mov	ax,0
	mov	word ptr [bp-2],ax
@36: 
	mov	ax,word ptr [bp-2]
	mov	dx,word ptr [bp+10]
	cmp	ax,dx
	jl	@38
@37: 
	jmp	@48
@38: 
	mov	ax,word ptr [bp-2]
	mov	dx,0
	cmp	ax,dx
	jg	@40
@39: 
	jmp	@42
@40: 
	lea	si,@str1
	push	si
@41: 
	sub	sp,2
	push	bp
	call	near ptr _writeString
	add	sp,6
@42: 
	mov	ax,word ptr [bp-2]
	mov	cx,2
	imul	cx
	mov	cx,word ptr [bp+8]
	add	ax,cx
	mov	word ptr [bp-4],ax
@43: 
	mov	di,word ptr [bp-4]
	mov	ax,word ptr [di]
	push	ax
@44: 
	sub	sp,2
	push	bp
	call	near ptr _writeInteger
	add	sp,6
@45: 
	mov	ax,word ptr [bp-2]
	mov	dx,1
	add	ax,dx
	mov	word ptr [bp-6],ax
@46: 
	mov	ax,word ptr [bp-6]
	mov	word ptr [bp-2],ax
@47: 
	jmp	@36
@48: 
	lea	si,@str2
	push	si
@49: 
	sub	sp,2
	push	bp
	call	near ptr _writeString
	add	sp,6
@50: 
@writeArray_3:
	mov	sp,bp
	pop	bp
	ret
_writeArray_3	endp

@51: 
_main_0	proc	near
	push	bp
	mov	bp,sp
	sub	sp,48

@52: 
	mov	ax,65
	mov	word ptr [bp-2],ax
@53: 
	mov	ax,0
	mov	word ptr [bp-36],ax
@54: 
	mov	ax,word ptr [bp-36]
	mov	dx,16
	cmp	ax,dx
	jl	@56
@55: 
	jmp	@66
@56: 
	mov	ax,word ptr [bp-2]
	mov	cx,137
	imul	cx
	mov	word ptr [bp-38],ax
@57: 
	mov	ax,word ptr [bp-38]
	mov	dx,220
	add	ax,dx
	mov	word ptr [bp-40],ax
@58: 
	mov	ax,word ptr [bp-40]
	mov	dx,word ptr [bp-36]
	add	ax,dx
	mov	word ptr [bp-42],ax
@59: 
	mov	ax,word ptr [bp-42]
	cwd
	mov	cx,101
	idiv	cx
	mov	word ptr [bp-44],dx
@60: 
	mov	ax,word ptr [bp-44]
	mov	word ptr [bp-2],ax
@61: 
	mov	ax,word ptr [bp-36]
	mov	cx,2
	imul	cx
	lea	cx,word ptr [bp-34]
	add	ax,cx
	mov	word ptr [bp-46],ax
@62: 
	mov	ax,word ptr [bp-2]
	mov	di,word ptr [bp-46]
	mov	word ptr [di],ax
@63: 
	mov	ax,word ptr [bp-36]
	mov	dx,1
	add	ax,dx
	mov	word ptr [bp-48],ax
@64: 
	mov	ax,word ptr [bp-48]
	mov	word ptr [bp-36],ax
@65: 
	jmp	@54
@66: 
	lea	si,@str3
	push	si
@67: 
	mov	ax,16
	push	ax
@68: 
	lea	si,word ptr [bp-34]
	push	si
@69: 
	sub	sp,2
	push	bp
	call	near ptr _writeArray_3
	add	sp,10
@70: 
	mov	ax,16
	push	ax
@71: 
	lea	si,word ptr [bp-34]
	push	si
@72: 
	sub	sp,2
	push	bp
	call	near ptr _bsort_1
	add	sp,8
@73: 
	lea	si,@str4
	push	si
@74: 
	mov	ax,16
	push	ax
@75: 
	lea	si,word ptr [bp-34]
	push	si
@76: 
	sub	sp,2
	push	bp
	call	near ptr _writeArray_3
	add	sp,10
@77: 
@main_0:
	mov	sp,bp
	pop	bp
	ret
_main_0	endp

@str1	db	', ', 0
@str2	db	13, 10, 0
@str3	db	'Initial array: ', 0
@str4	db	'Sorted array: ', 0

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
