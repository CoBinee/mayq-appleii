#! make -f
#
# makefile - start
#


# directory
#

# source file directory
SRCDIR			=	sources

# include file directory
INCDIR			=	sources

# object file directory
OBJDIR			=	objects

# config file directory
CFGDIR			=	.

# binary file directory
BINDIR			=	bin

# resource file directory
RESDIR			=	resources

# output file directory
OUTDIR			=	disk

# vpath search directories
VPATH			=	$(SRCDIR):$(INCDIR):$(OBJDIR):$(BINDIR)

# assembler
#

# assembler command
AS				=	ca65

# assembler flags
ASFLAGS			=	-t none -I $(SRCDIR) -I $(INCDIR) -I .

# c compiler
#

# c compiler command
CC				=	cc65

# c compiler flags
CFLAGS			=	-t none -I $(SRCDIR) -I $(INCDIR) -I .

# linker
#

# linker command
LD				=	ld65

# linker flags
LDFLAGS			=	

# apple commander
#

# apple commander
AC				=	tools/AppleCommander-ac-1.9.0.jar

# suffix rules
#
.SUFFIXES:			.s .c .o

# assembler source suffix
.s.o:
	$(AS) $(ASFLAGS) -o $(OBJDIR)/$@ $<

# c source suffix
.c.o:
	$(CC) $(CFLAGS) -o $(OBJDIR)/$@ -c $<

# project files
#

# target name
TARGET			=	mayq

# hello name
HELLO			=	hello

# config name
CONFIG			=	apple2

# assembler source files
ASSRCS			=	crt0.s iocs.s lib.s world.s user.s \
					app0.s title.s \
					app1.s new.s \
					app2.s game.s \
					actor.s \
					actor_player.s \
					actor_enemy.s \
					actor_orc.s actor_lizard.s actor_slime.s actor_skeleton.s actor_serpent.s actor_spider.s actor_gremlin.s \
					actor_bat.s actor_zorn.s actor_phantom.s actor_cyclopse.s \
					actor_wizard.s actor_hydra.s actor_devil.s actor_dragon.s \
					actor_tree.s actor_rock.s actor_cactus.s \
					actor_ball.s

# c source files
CSRCS			=	

# object files
OBJS			=	$(ASSRCS:.s=.o) $(CSRCS:.c=.o)

# build project disk
#
$(TARGET).dsk:		$(HELLO) $(OBJS)
	$(LD) $(LDFLAGS) -o $(BINDIR)/$(TARGET) -m $(BINDIR)/$(TARGET).map --config $(CFGDIR)/$(CONFIG).cfg --obj $(foreach file,$(OBJS),$(OBJDIR)/$(file))
	@rm -f $(OUTDIR)/$(TARGET).dsk
	@cp $(OUTDIR)/origin/init.dsk $(OUTDIR)/$(TARGET).dsk
	@java -jar $(AC) -bas $(OUTDIR)/$(TARGET).dsk $(HELLO) < $(SRCDIR)/$(HELLO)
	@java -jar $(AC) -as $(OUTDIR)/$(TARGET).dsk boot < $(BINDIR)/boot
	@java -jar $(AC) -p $(OUTDIR)/$(TARGET).dsk app0 B 0x4000 < $(BINDIR)/app0
	@java -jar $(AC) -p $(OUTDIR)/$(TARGET).dsk app1 B 0x4000 < $(BINDIR)/app1
	@java -jar $(AC) -p $(OUTDIR)/$(TARGET).dsk app2 B 0x4000 < $(BINDIR)/app2
	@java -jar $(AC) -p $(OUTDIR)/$(TARGET).dsk enemy0 B 0x0000 < $(RESDIR)/sprites/enemy0.ts
	@java -jar $(AC) -p $(OUTDIR)/$(TARGET).dsk enemy1 B 0x0000 < $(RESDIR)/sprites/enemy1.ts
	@java -jar $(AC) -p $(OUTDIR)/$(TARGET).dsk title B 0x2000 < $(RESDIR)/images/title.hgr
	@java -jar $(AC) -p $(OUTDIR)/$(TARGET).dsk end   B 0x2000 < $(RESDIR)/images/end.hgr
	@java -jar $(AC) -p $(OUTDIR)/$(TARGET).dsk frame B 0x2000 < $(RESDIR)/images/frame.hgr
#	@java -jar $(AC) -p $(OUTDIR)/$(TARGET).dsk world B 0x0000 < download/world
#	@java -jar $(AC) -p $(OUTDIR)/$(TARGET).dsk user  B 0x0000 < download/user
#	@java -jar $(AC) -l $(OUTDIR)/$(TARGET).dsk

##  $(LD) $(LDFLAGS) -o $(BINDIR)/$(TARGET) -m $(BINDIR)/$(TARGET).map --config $(CFGDIR)/$(CONFIG).cfg --obj $(foreach file,$(OBJS),$(OBJDIR)/$(file))

# clean project
#
clean:
	@rm -f $(OBJDIR)/*
	@rm -f $(BINDIR)/*
##	@rm -f makefile.depend

# build depend file
#
##	depend:
##	ifneq ($(strip $(CSRCS)),)
##		$(CC) $(CFLAGS) -MM $(foreach file,$(CSRCS),$(SRCDIR)/$(file)) > makefile.depend
##	endif

# import world and user file
import:
	@java -jar $(AC) -p $(OUTDIR)/$(TARGET).dsk world B 0x0000 < download/world
	@java -jar $(AC) -p $(OUTDIR)/$(TARGET).dsk user  B 0x0000 < download/user

# export download disk
export:
	@java -jar $(AC) -x ~/Downloads/$(TARGET).dsk download
	@java -jar $(AC) -g ~/Downloads/$(TARGET).dsk world download/world
	@java -jar $(AC) -g ~/Downloads/$(TARGET).dsk user download/user
	@rm ~/Downloads/$(TARGET).dsk

# phony targets
#
##	.PHONY:				clean depend
.PHONY:				clean

# include depend file
#
-include makefile.depend


# makefile - end
