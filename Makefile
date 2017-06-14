CFLAGS=-ffreestanding
ASFLAGS=-ffreestanding
LDFLAGS=-nostartfiles
INCLUDE=/usr/include

site: site.o

site.o: site.S unistd.h.gch syscall.h.gch mman.h.gch fcntl.h.gch socket.h.gch

unistd.h.gch: ${INCLUDE}/unistd.h
	$(CC) $(CFLAGS) -E -dM -o $@ $<
syscall.h.gch: ${INCLUDE}/sys/syscall.h
	$(CC) $(CFLAGS) -E -dM -o $@ $<
mman.h.gch: ${INCLUDE}/sys/mman.h
	$(CC) $(CFLAGS) -E -dM -o $@ $<
fcntl.h.gch: ${INCLUDE}/sys/fcntl.h
	$(CC) $(CFLAGS) -E -dM -o $@ $<
socket.h.gch: ${INCLUDE}/sys/socket.h
	$(CC) $(CFLAGS) -E -dM -o $@ $<

clean:
	rm -f ./*.o ./*.gch ./site
