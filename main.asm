bits 16
cpu 8086

segment code

..start:
	mov ax,data
	mov ds,ax
	mov ax,stack
	mov ss,ax
	mov sp,stacktop

	call sayHello

exit:
	mov ah,04CH
	mov al,00
	int 21h

sayHello:
	push ax
	push dx

	mov ah, 09h
	mov dx,msg_hello
	int 21h

	mov ah, 09h
	mov dx,msg_hello2
	int 21h

	pop dx
	pop ax
	ret

segment data

msg_hello: db `hello\r\n$`
msg_hello2: db `Hello2\r\n$`

segment stack stack
	resb 1024
stacktop:
