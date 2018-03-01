xseg	segment	public 'code'
	assume	cs:xseg, ds:xseg, ss:xseg
	org	100h

main	proc	near
	call	near ptr _hello_0
	mov	ax,4C00h
	int	21h
main	endp

@1: 
_hello_0	proc	near
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
@hello_0:
	mov	sp,bp
	pop	bp
	ret
_hello_0	endp

@str1	db	'Hello world!', 13, 10, 0

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
