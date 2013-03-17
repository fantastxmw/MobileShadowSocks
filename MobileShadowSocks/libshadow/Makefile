CC = clang
CFLAGS = -g
LDFLAGS = -framework Foundation
CSRC = encrypt.c md5.c rc4.c libev/ev.c
MSRC = local.m
OBJECTS = $(CSRC:.c=.o) $(MSRC:.m=.o)
EXECUTABLE = shadowd

all: $(CSRC) $(MSRC) $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $^

%.o: %.m
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJECTS) $(EXECUTABLE)