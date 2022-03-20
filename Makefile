#==- MACROS -==#


# Options
WORK_DIR	?= .
OUT_NAME	?= qr
DEBUG		?= 0

# Input directories
SRC_DIRS	:= $(WORK_DIR)/src
INC_DIRS	:= $(WORK_DIR)/src/includes

# Output directories
OUT_DIR		:= $(WORK_DIR)/bin
INT_DIR		:= $(OUT_DIR)/int
OBJ_DIRS	:= $(foreach dir,$(SRC_DIRS),$(INT_DIR)/$(dir))

# Tools directory
TLS_DIR		:= $(WORK_DIR)/tools

# List of input files
SRC_LIST	:= $(foreach dir,$(SRC_DIRS), $(wildcard $(dir)/*.c) $(wildcard $(dir)/*.s))
INT_LIST	:= $(foreach file,$(SRC_LIST),$(INT_DIR)/$(file).o)

# Targets
OUT_TARGET	:= $(OUT_DIR)/$(OUT_NAME)
DMP_TARGET	:= $(OUT_DIR)/$(OUT_NAME).txt

# Build tools
CC			:= gcc
AS			:= nasm
LD 			:= ld
UU			:= uuencode
QE			:= qrencode
DMP 		:= objdump

# General build options
CCFLAGS		:= -Wall -Werror -fno-stack-protector
ASFLAGS		:= -f elf64
LDFLAGS		:= -nostdlib -n -m elf_x86_64 -e _entry
QEFLAGS		:= -t PNG -s 7 -8 --verbose
DMPFLAGS	:= -d

# Option-specific build flags
ifeq ($(DEBUG),0)
	CCFLAGS	+= -Os -ffunction-sections -fdata-sections -DRELEASE
	LDFLAGS += -Os -s --gc-sections
else
	CCFLAGS	+= -O0 -g -DDEBUG
	ASFLAGS	+= -g
	LDFLAGS += -g
endif

# Append include paths
CCFLAGS 	+= $(foreach dir,$(INC_DIRS),-I $(dir))
ASFLAGS 	+= $(foreach dir,$(INC_DIRS),-I $(dir))


#==- BUILD COMMANDS -==#


# We don't want to try to make a QR code in debug mode
ifeq ($(DEBUG),0)

# QR-Encoding / final output
$(OUT_TARGET).png : $(OUT_TARGET).uu
	$(QE) $(QEFLAGS) -r $< -o $@

# UU-Encoding
$(OUT_TARGET).uu : $(OUT_TARGET)
	$(UU) $< $(OUT_NAME) > $@

endif

# Linking / binary output
$(OUT_TARGET) : $(OBJ_DIRS) $(INT_LIST)
	$(LD) $(LDFLAGS) -o $@ $(INT_LIST)

# Compiling
$(INT_DIR)/%.c.o : %.c
	$(CC) $(CCFLAGS) -o $@ -c $<

# Assembling
$(INT_DIR)/%.s.o : %.s
	$(AS) $(ASFLAGS) -o $@ $<

# Create directories
$(OBJ_DIRS) :
	mkdir -p $@


#==- TOOLS -==#


# Delete the output directory
clean :
	rm -rf $(OUT_DIR) $(INT_DIR) $(OBJ_DIRS)

# Disassemble the output binary
dump : $(OUT_TARGET)
	$(DMP) $(DMPFLAGS) $< > $(DMP_TARGET)

# Build and run the output binary
run : $(OUT_TARGET)
	$<
