.DEFAULT_GOAL := all

# 
# Version
#
VERSION=1.3a
#NDK=/Users/joshuaguy/android-ndk-r10c
#SYSROOT=$(NDK)/platforms/android-17/arch-arm
#
# Source files
#
COMMON_SRCS=Samba.cpp Flash.cpp EfcFlash.cpp EefcFlash.cpp FlashFactory.cpp Applet.cpp WordCopyApplet.cpp Flasher.cpp
APPLET_SRCS=WordCopyArm.asm
BOSSAC_SRCS=bossac.cpp CmdOpts.cpp

#
# Build directories
#
BINDIR=bin
OBJDIR=obj
SRCDIR=src
RESDIR=res
INSTALLDIR=install


#
# Linux rules
#
COMMON_SRCS+=PosixSerialPort.cpp LinuxPortFactory.cpp
COMMON_LIBS=-Wl,--as-needed

#
# Object files
#
COMMON_OBJS=$(foreach src,$(COMMON_SRCS),$(OBJDIR)/$(src:%.cpp=%.o))
APPLET_OBJS=$(foreach src,$(APPLET_SRCS),$(OBJDIR)/$(src:%.asm=%.o))
BOSSAC_OBJS=$(APPLET_OBJS) $(COMMON_OBJS) $(foreach src,$(BOSSAC_SRCS),$(OBJDIR)/$(src:%.cpp=%.o))

#
# Dependencies
#
DEPENDS=$(COMMON_SRCS:%.cpp=$(OBJDIR)/%.d) 
DEPENDS+=$(APPLET_SRCS:%.asm=$(OBJDIR)/%.d) 
DEPENDS+=$(BOSSAC_SRCS:%.cpp=$(OBJDIR)/%.d) 

#
# Tools
#
#Q=@
CXX=arm-linux-androideabi-g++
ARM=arm-none-eabi-
ARMAS=$(ARM)as
ARMOBJCOPY=$(ARM)objcopy

#
# CXX Flags
#
COMMON_CXXFLAGS+=-Wall -Werror -MT $@ -MD -MP -MF $(@:%.o=%.d) -DVERSION=\"$(VERSION)\" -g -O2 -march=armv7-a -mfloat-abi=softfp -mfpu=neon -Itoolchain/sysroot/usr/include/asm/arch
BOSSAC_CXXFLAGS=$(COMMON_CXXFLAGS)

#
# LD Flags
#
COMMON_LDFLAGS+=-g -Wl,--fix-cortex-a8
BOSSAC_LDFLAGS=$(COMMON_LDFLAGS)

#
# Libs
#
COMMON_LIBS+=
BOSSAC_LIBS=$(COMMON_LIBS)

#
# Main targets
#
# all: $(BINDIR)/bossa$(EXE) $(BINDIR)/bossac$(EXE) $(BINDIR)/bossash$(EXE)
all: $(BINDIR)/bossac$(EXE)

#
# Common rules
#
define common_obj
$(OBJDIR)/$(1:%.cpp=%.o): $(SRCDIR)/$(1)
	@echo CPP $$<
	$$(Q)$$(CXX) $$(COMMON_CXXFLAGS) -c -o $$@ $$<
endef
$(foreach src,$(COMMON_SRCS),$(eval $(call common_obj,$(src))))

#
# Applet rules
#
define applet_obj
$(SRCDIR)/$(1:%.asm=%.cpp): $(SRCDIR)/$(1)
	@echo APPLET $(1:%.asm=%)
	$$(Q)$$(ARMAS) -o $$(@:%.o=%.obj) $$<
	$$(Q)$$(ARMOBJCOPY) -O binary $$(@:%.o=%.obj) $$(@:%.o=%.bin)
	$$(Q)appletgen $(1:%.asm=%) $(SRCDIR) $(OBJDIR)
$(OBJDIR)/$(1:%.asm=%.o): $(SRCDIR)/$(1:%.asm=%.cpp)
	@echo CPP $$<
	$$(Q)$$(CXX) $$(COMMON_CXXFLAGS) -c -o $$(@) $$(<:%.asm=%.cpp)
endef
$(foreach src,$(APPLET_SRCS),$(eval $(call applet_obj,$(src))))

# BOSSAC rules
#
define bossac_obj
$(OBJDIR)/$(1:%.cpp=%.o): $(SRCDIR)/$(1)
	@echo CPP $$<
	$$(Q)$$(CXX) $$(BOSSAC_CXXFLAGS) -c -o $$@ $$<
endef
$(foreach src,$(BOSSAC_SRCS),$(eval $(call bossac_obj,$(src))))

#
# Directory rules
#
$(OBJDIR):
	@mkdir $@

$(BINDIR):
	@mkdir $@

#
# Target rules
#
$(BOSSAC_OBJS): | $(OBJDIR)
$(BINDIR)/bossac$(EXE): $(BOSSAC_OBJS) | $(BINDIR)
	@echo LD $@
	$(Q)$(CXX) $(BOSSAC_LDFLAGS) -o $@ $(BOSSAC_OBJS) $(BOSSAC_LIBS)

strip-bossac: $(BINDIR)/bossac$(EXE)
	@echo STRIP $^
	$(Q)strip $^

strip: strip-bossac

APPLET_OBJS=$(foreach src,$(APPLET_SRCS),$(OBJDIR)/$(src:%.asm=%.o))
clean:
	@echo CLEAN
	$(Q)rm -rf $(BINDIR) $(OBJDIR)

#
# Include dependencies
#
-include $(DEPENDS)
