CC := gcc
LD := ld

THISMACHINE ?= $(shell uname -srm | sed -e 's/ /-/g')
THISSYSTEM	?= $(shell uname -s)

VERSION     ?= 3.0.3
PACKAGEDIR  ?= ./../_hbpkg/$(THISMACHINE)/argtable.$(VERSION)


ifeq ($(THISSYSTEM),Darwin)
# Mac can't do conditional selection of static and dynamic libs at link time.
#	PRODUCTS := libargtable.dylib libargtable.a
	PRODUCTS := libargtable.a
else ifeq ($(THISSYSTEM),Linux)
	PRODUCTS := libargtable.so libargtable.a
else ifeq ($(THISSYSTEM),CYGWIN_NT-10.0)
	PRODUCTS := libargtable.a
else
	error "THISSYSTEM set to unknown value: $(THISSYSTEM)"
endif

SRCDIR      := .
INCDIR      := .
BUILDDIR    := build/$(THISMACHINE)
TARGETDIR   := bin/$(THISMACHINE)
RESDIR      := 
SRCEXT      := c
DEPEXT      := d
OBJEXT      := o

CFLAGS      ?= -std=gnu99 -fPIC -O3
LIB         := 
INC         := -I$(INCDIR)
INCDEP      := -I$(INCDIR)

SOURCES     := $(shell ls $(SRCDIR)/*.$(SRCEXT))
OBJECTS     := $(patsubst $(SRCDIR)/%,$(BUILDDIR)/%,$(SOURCES:.$(SRCEXT)=.$(OBJEXT)))



all: lib
lib: resources $(PRODUCTS)
remake: cleaner all
pkg: lib install

install:
	@mkdir -p $(PACKAGEDIR)
	@cp -R $(TARGETDIR)/* $(PACKAGEDIR)/
	@cp -R ./*.h $(PACKAGEDIR)/
	@rm -f $(PACKAGEDIR)/../argtable
	@ln -s argtable.$(VERSION) ./$(PACKAGEDIR)/../argtable
	cd ../_hbsys && $(MAKE) sys_install INS_MACHINE=$(THISMACHINE) INS_PKGNAME=argtable


#Copy Resources from Resources Directory to Target Directory
resources: directories

#Make the Directories
directories:
	@mkdir -p $(TARGETDIR)
	@mkdir -p $(BUILDDIR)

#Clean only Objects
clean:
	@$(RM) -rf $(BUILDDIR)

#Full Clean, Objects and Binaries
cleaner: clean
	@$(RM) -rf $(PRODUCTS)
	@$(RM) -rf $(TARGETDIR)

#Pull in dependency info for *existing* .o files
-include $(OBJECTS:.$(OBJEXT)=.$(DEPEXT))

#Build the dynamic library
libargtable.so: $(OBJECTS)
	$(CC) -shared -fPIC -Wl,-soname,libargtable.so.1 -o $(TARGETDIR)/$@.$(VERSION) $(OBJECTS) -lc

libargtable.dylib: $(OBJECTS)
	$(CC) -dynamiclib -o $(TARGETDIR)/$@ $(OBJECTS)

#Build static library -- same on all POSIX
libargtable.a: $(OBJECTS)
	ar -rcs $(TARGETDIR)/$@ $(OBJECTS)
	ranlib $(TARGETDIR)/$@

#Compile
$(BUILDDIR)/%.$(OBJEXT): $(SRCDIR)/%.$(SRCEXT)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(INC) -c -o $@ $<
	@$(CC) $(CFLAGS) $(INCDEP) -MM $(SRCDIR)/$*.$(SRCEXT) > $(BUILDDIR)/$*.$(DEPEXT)
	@cp -f $(BUILDDIR)/$*.$(DEPEXT) $(BUILDDIR)/$*.$(DEPEXT).tmp
	@sed -e 's|.*:|$(BUILDDIR)/$*.$(OBJEXT):|' < $(BUILDDIR)/$*.$(DEPEXT).tmp > $(BUILDDIR)/$*.$(DEPEXT)
	@sed -e 's/.*://' -e 's/\\$$//' < $(BUILDDIR)/$*.$(DEPEXT).tmp | fmt -1 | sed -e 's/^ *//' -e 's/$$/:/' >> $(BUILDDIR)/$*.$(DEPEXT)
	@rm -f $(BUILDDIR)/$*.$(DEPEXT).tmp

#Non-File Targets
.PHONY: all lib pkg remake clean cleaner resources


