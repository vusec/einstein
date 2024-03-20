CC ?= gcc
CFLAGS = -Og -Wall -Werror -g -DROOT=\"$(ROOT)\"
LDFLAGS = -z max-page-size=0x1000
SRCDIR = src
OBJDIR = build

PROGRAMS=cmdsvr-taintall
PROGRAMS+=indirect-call
PROGRAMS+=load-ptr-prop
PROGRAMS+=tainted-syscall
PROGRAMS+=check-mem-taint

BINARIES=$(addprefix $(OBJDIR)/,$(PROGRAMS))

PIN_EXEC_memtaint=setarch x86_64 -R

all: $(BINARIES)

run-all:
	./run-tests.sh

run-minimal:
	./run-tests.sh minimal

$(OBJDIR):
	mkdir build

$(BINARIES): %: $(OBJDIR) %.o
	$(CC) $(LDFLAGS) -o $@ $@.o
	$(LIBDFT)/utils/relink.py $@

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	$(CC) $(CFLAGS) -c -I$(LIBDFT)/src -o $@ $<

clean:
	rm -rf $(OBJDIR)
