CC = clang
CFLAGS = -g
LDFLAGS = -framework Foundation
DEPS = Constant.h build_time.h local.h encrypt.h md5.h rc4.h socks5.h libev/ev.h
CSRC = encrypt.c md5.c rc4.c libev/ev.c
MSRC = local.m
OBJECTS = $(CSRC:.c=.o) $(MSRC:.m=.o)
EXECUTABLE = shadowd

all: $(CSRC) $(MSRC) $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $^

%.o: %.m $(DEPS)
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.c $(DEPS)
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJECTS) $(EXECUTABLE)