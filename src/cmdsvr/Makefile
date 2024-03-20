LIBNAME = dbt-cmdsvr
OBJS = dbt-cmdsvr.o

LIBSONAME = lib$(LIBNAME).so
SHARED_LDFLAGS += -ldl
CFLAGS    = -g -std=gnu99 -fPIC -Wall -Wno-long-long -D_GNU_SOURCE
INCLUDES  = -Iinclude
LDFLAGS   = -ldl -Wl,-soname -Wl,"${LIBSONAME}" -pthread -lrt
HEADERS += $(wildcard include/*.h)

all: $(LIBSONAME)

$(LIBSONAME): $(OBJS) $(OTHER_OBJS)
	$(CC) $(CFLAGS) -shared -o $@ $(OBJS) $(OTHER_OBJS) $(LDFLAGS)

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

clean:
	rm -f $(OBJS) $(LIBSONAME) $(OTHER_OBJS)
