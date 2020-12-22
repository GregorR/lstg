CFLAGS=-Oz
EFLAGS=\
	--memory-init-file 0 \
	-s "EXPORT_NAME='LittleSmalltalk'" \
	-s "EXPORTED_FUNCTIONS=['_main']" \
	-s "EXTRA_EXPORTED_RUNTIME_METHODS=['cwrap']" \
	-s MODULARIZE=1 \
	-s ALLOW_MEMORY_GROWTH=1

all: lstg.asm.js lstg.wasm.js

lstg.asm.js: bin/lstg.o
	emcc $(CFLAGS) $(EFLAGS) -s WASM=0 \
		bin/lstg.o -o $@

lstg.wasm.js: bin/lstg.o
	emcc $(CFLAGS) $(EFLAGS) \
		bin/lstg.o -o $@

bin/lstg.o:
	$(MAKE) CC=emcc CFLAGS="$(CFLAGS)" EXE_EXT=.o

clean:
	$(MAKE) clean EXE_EXT=.o
	rm -f lstg.asm.js lstg.wasm.js lstg.wasm.wasm

.PRECIOUS: lstg.wasm.wasm
