CFLAGS=-Oz
EFLAGS=\
	--memory-init-file 0 \
	-s "EXPORT_NAME='LittleSmalltalk'" \
	-s "EXPORTED_FUNCTIONS=['_main']" \
	-s "EXTRA_EXPORTED_RUNTIME_METHODS=['cwrap']" \
	-s MODULARIZE=1 \
	-s ALLOW_MEMORY_GROWTH=1

all: lst.asm.js lst.wasm.js

lst.asm.js: bin/st.o
	emcc $(CFLAGS) $(EFLAGS) -s WASM=0 \
		bin/st.o -o $@

lst.wasm.js: bin/st.o
	emcc $(CFLAGS) $(EFLAGS) \
		bin/st.o -o $@

bin/st.o:
	$(MAKE) CC=emcc CFLAGS="$(CFLAGS)" EXE_EXT=.o

clean:
	$(MAKE) clean
	rm -f lst.asm.js lst.wasm.js lst.wasm.wasm

.PRECIOUS: lst.wasm.wasm
