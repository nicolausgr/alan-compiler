# OS type: Linux

CC=gcc
CFLAGS=-Wall -ansi -pedantic -g -std=c99

CFILES   = symbol.c error.c general.c parser.c final.c
HFILES   = symbol.h error.h general.h intermediate.h final.h
OBJFILES = $(patsubst %.c,%.o,$(CFILES))
EXEFILES = alan
SRCFILES = $(HFILES) $(CFILES)

%.o : %.c
	$(CC) $(CFLAGS) -c $<

alan: lexer.o parser.o symbol.o final.o error.o general.o
	$(CC) $(CFLAGS) -o $@ $^ -lfl

general.o  : general.c general.h error.h
error.o    : error.c general.h error.h
symbol.o   : symbol.c symbol.h general.h error.h
final.o   : final.c final.h

lexer.c: lexer.l intermediate.h final.h
	flex -s -o $@ $<

lexer.o: lexer.c parser.h

parser.c parser.h: parser.y symbol.h error.h intermediate.h final.h
	bison -v -d -o $@ $<

.PHONY: clean distclean

clean:
	$(RM) lexer.c parser.c parser.h parser.output *.o *~

distclean: clean
	$(RM) alan

