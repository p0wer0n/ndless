SUBDIRS = colors helloworld helloworld-sdl particles luaext

all:
	@for i in $(SUBDIRS); do \
	echo "make all in $$i..."; \
  (cd $$i; make all) || exit 1; done

clean:
	@for i in $(SUBDIRS); do \
	echo "Clearing in $$i..."; \
	(cd $$i; make clean) || exit 1; done
