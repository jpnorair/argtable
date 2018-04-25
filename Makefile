CC=gcc

THISMACHINE := $(shell uname -srm | sed -e 's/ /-/g')
THISSYSTEM	:= $(shell uname -s)

VERSION     ?= "3.0.0"
PACKAGEDIR  ?= ./../_hbpkg/$(THISMACHINE)/argtable.$(VERSION)


ifeq ($(THISSYSTEM),Darwin)
	ARGTABLE_TARGET := libargtable.dylib
	
else ifeq ($(THISSYSTEM),Linux)
	ARGTABLE_TARGET := libargtable.so
	
else
	error "THISSYSTEM set to unknown value: $(THISSYSTEM)"
endif

SRCDIR      := .
INCDIR      := .
BUILDDIR    := build
TARGETDIR   := bin
RESDIR      := 
SRCEXT      := c
DEPEXT      := d
OBJEXT      := o

#CFLAGS      := -std=gnu99 -O -g -Wall
CFLAGS      := -std=gnu99 -fPIC -O3
LIB         := 
INC         := -I$(INCDIR)
INCDEP      := -I$(INCDIR)

SOURCES     := $(shell ls $(SRCDIR)/*.$(SRCEXT))
OBJECTS     := $(patsubst $(SRCDIR)/%,$(BUILDDIR)/%,$(SOURCES:.$(SRCEXT)=.$(OBJEXT)))



all: lib
lib: resources $(ARGTABLE_TARGET)
remake: cleaner all
	

install:
	@mkdir -p $(PACKAGEDIR)
	@cp -R $(TARGETDIR)/$(ARGTABLE_TARGET) $(PACKAGEDIR)/
	@cp -R ./*.h $(PACKAGEDIR)/
	@rm -f $(PACKAGEDIR)/../argtable
	@ln -s argtable.$(VERSION) ./$(PACKAGEDIR)/../argtable


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
	@$(RM) -rf $(ARGTABLE_TARGET)
	@$(RM) -rf $(TARGETDIR)

#Pull in dependency info for *existing* .o files
-include $(OBJECTS:.$(OBJEXT)=.$(DEPEXT))

#Build the dynamic library
libargtable.so: $(OBJECTS)
	$(CC) -shared -o $@ $(OBJECTS)

libargtable.dylib: $(OBJECTS)
	$(CC) -dynamiclib -o $(TARGETDIR)/$@ $(OBJECTS)

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
.PHONY: all lib remake clean cleaner resources


