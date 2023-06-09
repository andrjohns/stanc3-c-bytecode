OCAML_VER          =  $(shell opam info ocaml-base-compiler --field=installed-version --color=never)
BASE_VER           =  $(shell opam info base --field=installed-version --color=never)
BASE_BIGSTRING_VER =  $(shell opam info base_bigstring --field=installed-version --color=never)
JANESTREET_VER     =  $(shell opam info jane-street-headers --field=installed-version --color=never)
PPX_INLINE_VER     =  $(shell opam info ppx_inline_test --field=installed-version --color=never)
BIN_PROT_VER       =  $(shell opam info bin_prot --field=installed-version --color=never)
TIME_NOW_VER       =  $(shell opam info time_now --field=installed-version --color=never)
PPX_EXPECT_VER     =  $(shell opam info ppx_expect --field=installed-version --color=never)
CORE_KERNEL_VER    =  $(shell opam info ppx_expect --field=installed-version --color=never)

RUNTIME_FILES = floats.c backtrace_byt.c alloc.c array.c bigarray.c \
	backtrace.c str.c ints.c io.c compare.c dynlink.c stacks.c weak.c \
	eventlog.c finalise.c gc_ctrl.c meta.c hash.c intern.c signals.c \
	obj.c md5.c memprof.c memory.c extern.c parsing.c callback.c afl.c \
	sys.c unix.c win32.c startup_aux.c startup_byt.c codefrag.c domain.c \
	misc.c fix_code.c skiplist.c signals_byt.c minor_gc.c major_gc.c \
	globroots.c compact.c lexing.c interp.c custom.c printexc.c debugger.c \
	freelist.c roots_byt.c fail_byt.c

CAML_FILES = threads.h unixsupport.h version.h

BASE_FILES = hash_types/src/internalhash_stubs.c src/hash_stubs.c \
	src/exn_stubs.c src/int_math_stubs.c

JANESTREET_FILES = core_params.h ocaml_utils.h jane_common.h

ifeq ($(DOWNLOAD_SOURCES),true)
	OCAML_SRCDIR=ocaml_sources
else
	OCAML_SRCDIR=$(OCAML_LIBDIR)/../../.opam-switch/sources
endif

OCAML_LIBDIR=$(OPAM_SWITCH_PREFIX)/lib/ocaml
COMPILER_SRCDIR=$(OCAML_SRCDIR)/ocaml-base-compiler.$(OCAML_VER)
SEXLIB_DUNEPACKAGE=$(OCAML_LIBDIR)/../sexplib/dune-package

build-bytecode:
	# Temporarily remove the bigarray requirement from sexplib - otherwise unix is required
	sed -i'.bak' -e 's/requires bigarray/requires/g' $(SEXLIB_DUNEPACKAGE)
	# Temporarily mask the unix library so it can't be included
	mv $(OCAML_LIBDIR)/unix.cma $(OCAML_LIBDIR)/unix.cma.bak

	cd stanc3 && dune build src/stanc/stanc.bc.c
	mv $(OCAML_LIBDIR)/unix.cma.bak $(OCAML_LIBDIR)/unix.cma
	$(RM) $(SEXLIB_DUNEPACKAGE)
	mv $(SEXLIB_DUNEPACKAGE).bak $(SEXLIB_DUNEPACKAGE)

package-ocaml-runtime:
	mkdir stanc3-bytecode/runtime
	cp -r $(COMPILER_SRCDIR)/runtime/caml stanc3-bytecode/runtime
	cp $(addprefix $(OCAML_LIBDIR)/caml/,$(CAML_FILES)) stanc3-bytecode/runtime/caml
	cp $(addprefix $(COMPILER_SRCDIR)/runtime/,$(RUNTIME_FILES)) stanc3-bytecode/runtime
	cp $(COMPILER_SRCDIR)/otherlibs/str/strstubs.c stanc3-bytecode/runtime
	cp $(COMPILER_SRCDIR)/otherlibs/systhreads/st_stubs.c stanc3-bytecode/runtime

	# Compilation on Windows needs additional typedefs - update file to #include them
	sed -i'.bak' -e 's/#include \"caml\/sys.h\"/#include \"caml\/sys.h\"\n#include \"extra\/win32-defs.h\"/g' ./stanc3-bytecode/runtime/win32.c
	rm ./stanc3-bytecode/runtime/win32.c.bak

package-ocaml-config:
	cp -r $(COMPILER_SRCDIR)/tools stanc3-bytecode/
	cp -r $(COMPILER_SRCDIR)/build-aux stanc3-bytecode/
	cp $(COMPILER_SRCDIR)/configure stanc3-bytecode/
	cp $(COMPILER_SRCDIR)/Makefile.build_config.in stanc3-bytecode/
	cp $(COMPILER_SRCDIR)/Makefile.config.in stanc3-bytecode/
	chmod +x ./stanc3-bytecode/configure

package-ocaml-headers:
	mkdir stanc3-bytecode/include
	cp $(COMPILER_SRCDIR)/otherlibs/systhreads/st_win32.h stanc3-bytecode/include
	cp $(COMPILER_SRCDIR)/otherlibs/systhreads/st_posix.h stanc3-bytecode/include
	cp $(OCAML_SRCDIR)/base.$(BASE_VER)/hash_types/src/internalhash.h stanc3-bytecode/include
	cp $(OCAML_SRCDIR)/base_bigstring.$(BASE_BIGSTRING_VER)/src/base_bigstring.h stanc3-bytecode/include
	cp $(OCAML_SRCDIR)/core_kernel/src/core_bigstring.h stanc3-bytecode/include
	cp $(addprefix $(OCAML_SRCDIR)/jane-street-headers.$(JANESTREET_VER)/include/,$(JANESTREET_FILES)) stanc3-bytecode/include

package-ocaml-base:
	mkdir stanc3-bytecode/base
	cp $(addprefix $(OCAML_SRCDIR)/base.$(BASE_VER)/,$(BASE_FILES)) stanc3-bytecode/base
	cp $(OCAML_SRCDIR)/base_bigstring.$(BASE_BIGSTRING_VER)/src/base_bigstring_stubs.c stanc3-bytecode/base

package-ocaml-libraries:
	mkdir stanc3-bytecode/libraries
	cp $(OCAML_SRCDIR)/ppx_inline_test.$(PPX_INLINE_VER)/runner/lib/am_testing.c stanc3-bytecode/libraries
	cp $(OCAML_SRCDIR)/bin_prot.$(BIN_PROT_VER)/src/blit_stubs.c stanc3-bytecode/libraries
	cp $(OCAML_SRCDIR)/time_now.$(TIME_NOW_VER)/src/time_now_stubs.c stanc3-bytecode/libraries
	cp $(OCAML_SRCDIR)/ppx_expect.$(PPX_EXPECT_VER)/collector/expect_test_collector_stubs.c stanc3-bytecode/libraries
	cp $(OCAML_SRCDIR)/core_kernel/src/array_stubs.c stanc3-bytecode/libraries
	cp $(OCAML_SRCDIR)/core_kernel/src/bigstring_stubs.c stanc3-bytecode/libraries
	cp $(OCAML_SRCDIR)/core_kernel/src/md5_stubs.c stanc3-bytecode/libraries

download-sources:
	mkdir ocaml_sources
	opam source ocaml-base-compiler.$(OCAML_VER) --dir=ocaml_sources/ocaml-base-compiler.$(OCAML_VER)
	opam source base.$(BASE_VER) --dir=ocaml_sources/base.$(BASE_VER)
	opam source base_bigstring.$(BASE_BIGSTRING_VER) --dir=ocaml_sources/base_bigstring.$(BASE_BIGSTRING_VER)
	opam source jane-street-headers.$(JANESTREET_VER) --dir=ocaml_sources/jane-street-headers.$(JANESTREET_VER)
	opam source ppx_inline_test.$(PPX_INLINE_VER) --dir=ocaml_sources/ppx_inline_test.$(PPX_INLINE_VER)
	opam source bin_prot.$(BIN_PROT_VER) --dir=ocaml_sources/bin_prot.$(BIN_PROT_VER)
	opam source time_now.$(TIME_NOW_VER) --dir=ocaml_sources/time_now.$(TIME_NOW_VER)
	opam source ppx_expect.$(PPX_EXPECT_VER) --dir=ocaml_sources/ppx_expect.$(PPX_EXPECT_VER)
	opam source core_kernel.$(CORE_KERNEL_VER) --dir=ocaml_sources/core_kernel

package-stanc: build-bytecode
	cp stanc3/_build/default/src/stanc/stanc.bc.c stanc3-bytecode/stanc.c
ifeq ($(DOWNLOAD_SOURCES),true)
	$(MAKE) download-sources
endif
	$(MAKE) package-ocaml-config
	$(MAKE) package-ocaml-runtime
	$(MAKE) package-ocaml-headers
	$(MAKE) package-ocaml-base
	$(MAKE) package-ocaml-libraries

clean-stanc-package:
	$(RM) -r $(filter-out stanc3-bytecode/extra stanc3-bytecode/main.c stanc3-bytecode/Makefile, $(wildcard stanc3-bytecode/*))
ifeq ($(DOWNLOAD_SOURCES),true)
	$(RM) -r ocaml_sources
endif
