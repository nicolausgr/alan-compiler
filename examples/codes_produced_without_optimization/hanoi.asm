xseg	segment	public 'code'
	assume	cs:xseg, ds:xseg, ss:xseg
	org	100h

main	proc	near
	call	near ptr _solve_0
	mov	ax,4C00h
	int	21h
main	endp

@1: 
_move_2	proc	near
	push	bp
	mov	bp,sp
	sub	sp,0

@2: 
	lea	si,@str1
	push	si
@3: 
	sub	sp,2
	push	bp
	call	near ptr _writeString
	add	sp,6
@4: 
	mov	si,word ptr [bp+10]
	push	si
@5: 
	sub	sp,2
	push	bp
	call	near ptr _writeString
	add	sp,6
@6: 
	lea	si,@str2
	push	si
@7: 
	sub	sp,2
	push	bp
	call	near ptr _writeString
	add	sp,6
@8: 
	mov	si,word ptr [bp+8]
	push	si
@9: 
	sub	sp,2
	push	bp
	call	near ptr _writeString
	add	sp,6
@10: 
	lea	si,@str3
	push	si
@11: 
	sub	sp,2
	push	bp
	call	near ptr _writeString
	add	sp,6
@12: 
@move_2:
	mov	sp,bp
	pop	bp
	ret
_move_2	endp

@13: 
_hanoi_1	proc	near
	push	bp
	mov	bp,sp
	sub	sp,4

@14: 
	mov	ax,word ptr [bp+14]
	mov	dx,1
	cmp	ax,dx
	jge	@16
@15: 
	jmp	@31
@16: 
	mov	ax,word ptr [bp+14]
	mov	dx,1
	sub	ax,dx
	mov	word ptr [bp-2],ax
@17: 
	mov	ax,word ptr [bp-2]
	push	ax
@18: 
	mov	si,word ptr [bp+12]
	push	si
@19: 
	mov	si,word ptr [bp+8]
	push	si
@20: 
	mov	si,word ptr [bp+10]
	push	si
@21: 
	sub	sp,2
	push	word ptr [bp+4]
	call	near ptr _hanoi_1
	add	sp,12
@22: 
	mov	si,word ptr [bp+12]
	push	si
@23: 
	mov	si,word ptr [bp+10]
	push	si
@24: 
	sub	sp,2
	push	bp
	call	near ptr _move_2
	add	sp,8
@25: 
	mov	ax,word ptr [bp+14]
	mov	dx,1
	sub	ax,dx
	mov	word ptr [bp-4],ax
@26: 
	mov	ax,word ptr [bp-4]
	push	ax
@27: 
	mov	si,word ptr [bp+8]
	push	si
@28: 
	mov	si,word ptr [bp+10]
	push	si
@29: 
	mov	si,word ptr [bp+12]
	push	si
@30: 
	sub	sp,2
	push	word ptr [bp+4]
	call	near ptr _hanoi_1
	add	sp,12
@31: 
@hanoi_1:
	mov	sp,bp
	pop	bp
	ret
_hanoi_1	endp

@32: 
_solve_0	proc	near
	push	bp
	mov	bp,sp
	sub	sp,4

@33: 
	lea	si,@str4
	push	si
@34: 
	sub	sp,2
	push	bp
	call	near ptr _writeString
	add	sp,6
@35: 
	lea	si,word ptr [bp-4]
	push	si
@36: 
	push	bp
	call	near ptr _readInteger
	add	sp,4
@37: 
	mov	ax,word ptr [bp-4]
	mov	word ptr [bp-2],ax
@38: 
	mov	ax,word ptr [bp-2]
	push	ax
@39: 
	lea	si,@str5
	push	si
@40: 
	lea	si,@str6
	push	si
@41: 
	lea	si,@str7
	push	si
@42: 
	sub	sp,2
	push	bp
	call	near ptr _hanoi_1
	add	sp,12
@43: 
@solve_0:
	mov	sp,bp
	pop	bp
	ret
_solve_0	endp

@str1	db	'Moving from ', 0
@str2	db	' to ', 0
@str3	db	'.', 13, 10, 0
@str4	db	'Rings: ', 0
@str5	db	'left', 0
@str6	db	'right', 0
@str7	db	'middle', 0

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
