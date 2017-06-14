#include "syscall.h.gch"
#include "unistd.h.gch"
#include "mman.h.gch"
#include "fcntl.h.gch"
#include "socket.h.gch"

# these are enums for some reason
.equ	SOCK_STREAM,1
.equ	IPPROTO_TCP,6

# private definitions
.equ	BIND_ADDR,0
.equ	BIND_PORT,0x901f  # 8080 in network byte order
.equ	LISTEN_BACKLOG,5

/* Useful documentation: syscall(2): syscall conventions (registers) */

.section .text

	.globl	_start
_start:
	/* stack:
		(%rsp) 8 content (mmap ptr)
		8(%rsp) 8 content length
		16(%rsp) 4 content fd
		20(%rsp) 144 content stat
	*/
	push	%rbp
	mov		%rsp, %rbp
	sub		$164, %rsp

	/* open(path, flags) */
	mov		$__NR_open, %rax
	lea		site_filename, %rdi
	movl	$O_RDONLY, %esi
	syscall
	cmp		$0, %rax
	jl		err
	movl	%eax, 16(%rsp)

	/* fstat(fd, statbuf) */
	mov		$__NR_fstat, %rax
	movl	16(%rsp), %edi
	leaq	20(%rsp), %rsi
	syscall
	cmp		$0, %rax
	jnz		err
	movq	68(%rsp), %rcx
	movq	%rcx, 8(%rsp)

	/* mmap(addr, length, prot, flags, fd, offset) */
	mov		$__NR_mmap, %rax
	mov		$0, %rdi
	mov		8(%rsp), %rsi
	mov		$PROT_READ|PROT_WRITE, %rdx
	mov		$MAP_ANONYMOUS|MAP_PRIVATE, %r10
	mov		$-1, %r8
	mov		$0, %r9
	syscall
	movabsq	$0xfffffffffffff000, %rbx
	cmp		%rbx, %rax
	ja		err
	mov		%rax, (%rsp)

	/* read(fd, buf, count) */
	mov		$__NR_read, %rax
	movl	16(%rsp), %edi
	movq	(%rsp), %rsi
	movq	8(%rsp), %rdx
	syscall
	cmp		$0, %rax
	jl		err

	/* close(fd) */
	mov		$__NR_close, %rax
	movl	16(%rsp), %edi
	syscall

	/* stack:
		(%rsp) 8 content (mmap ptr)
		8(%rsp) 8 content length
		16(%rsp) 4 server fd
		20(%rsp) 16 server sockaddr
			20(%rsp) 2 family
			22(%rsp) 2 port
			24(%rsp) 4 addr
			28(%rsp) 8 zero
	*/
	/* socket(family, type, proto) */
	mov		$__NR_socket, %rax
	mov		$AF_INET, %rdi
	mov		$SOCK_STREAM, %rsi
	mov		$IPPROTO_TCP, %rdx
	syscall
	movl	%eax, 16(%rsp)
	cmp		$0, %rax
	jl		err

	/* bind(socket, address, address_len) */
	movw	$AF_INET, 20(%rsp)
	movw	$BIND_PORT, 22(%rsp)
	movl	$BIND_ADDR, 24(%rsp)
	movq	$0, 28(%rsp)
	mov		$__NR_bind, %rax
	mov		16(%rsp), %rdi
	lea		20(%rsp), %rsi
	mov		$16, %rdx
	syscall
	cmp		$0, %rax
	jnz		err

	/* listen(socket, backlog) */
	movq	$__NR_listen, %rax
	movl	16(%rsp), %edi
	movq	$LISTEN_BACKLOG, %rsi
	syscall
	cmp		$0, %rax
	jnz		err

_loop:
	/* stack:
		(%rsp) 8 content (mmap ptr)
		8(%rsp) 8 content length
		16(%rsp) 4 server fd
		20(%rsp) 4 client fd
		24(%rsp) 16 client sockaddr
		40(%rsp) 4 client socklen
	/*
	/* accept(socket, addr, addrlen) */
	movq	$__NR_accept, %rax
	movl	16(%rsp), %edi
	leaq	24(%rsp), %rsi
	leaq	40(%rsp), %rdx
	syscall
	mov		%eax, 20(%rsp)
	cmp		$0, %rax
	jl		err

	/* write(fd, buf, count) */
	movq	$__NR_write, %rax
	movl	20(%rsp), %edi
	mov		$response_header, %rsi
	mov		response_header_length, %rdx
	syscall

	/* write(fd, buf, count) */
	movq	$__NR_write, %rax
	movl	20(%rsp), %edi
	movq	(%rsp), %rsi
	movq	8(%rsp), %rdx
	syscall

	/* close(fd) */
	movq	$__NR_close, %rax
	movl	20(%rsp), %edi
	syscall

	jmp		_loop

	mov		$__NR_exit, %rax
	mov		$0, %rdi
	syscall

	leave
	ret

err:
	movq	%rax, %rdi
	mov		$__NR_exit, %rax
	syscall

	ret

.section .rodata
site_filename:
	.asciz "index.html"
response_header:
	.ascii "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n"
response_header_length:
	.quad 44
