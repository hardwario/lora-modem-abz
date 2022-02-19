
SRC_DIR := src
LIB_DIR := lib
CFG_DIR := cfg
OBJ_DIR := obj
OUT_DIR ?= out

OUT ?= firmware
TYPE ?= debug
BAUDRATE ?= 9600

ELF ?= $(OUT_DIR)/$(TYPE)/$(OUT).elf
MAP ?= $(OUT_DIR)/$(TYPE)/$(OUT).map
BIN ?= $(OUT_DIR)/$(TYPE)/$(OUT).bin

# Include only the following selected sources from the STM HAL
STM_HAL_SRC =                \
	stm32l0xx_hal.c          \
	stm32l0xx_hal_adc.c      \
	stm32l0xx_hal_adc_ex.c   \
	stm32l0xx_hal_cortex.c   \
	stm32l0xx_hal_dma.c      \
	stm32l0xx_hal_flash.c    \
	stm32l0xx_hal_flash_ex.c \
	stm32l0xx_hal_gpio.c     \
	stm32l0xx_hal_pwr.c      \
	stm32l0xx_hal_pwr_ex.c   \
	stm32l0xx_hal_rcc.c      \
	stm32l0xx_hal_rcc_ex.c   \
	stm32l0xx_hal_rtc.c      \
	stm32l0xx_hal_rtc_ex.c   \
	stm32l0xx_hal_spi.c      \
	stm32l0xx_hal_uart.c     \
	stm32l0xx_hal_uart_ex.c  \
	stm32l0xx_hal_usart.c    \
	stm32l0xx_ll_dma.c

################################################################################
# Source files                                                                 #
################################################################################
SRC_FILES += \
	$(wildcard $(SRC_DIR)/*.c) \
	$(wildcard $(LIB_DIR)/rtt/*.c) \
	$(wildcard $(LIB_DIR)/loramac-node/src/peripherals/soft-se/*.c) \
	$(wildcard $(LIB_DIR)/loramac-node/src/mac/region/*.c) \
	$(wildcard $(LIB_DIR)/loramac-node/src/mac/*.c) \
	$(wildcard $(LIB_DIR)/loramac-node/src/radio/sx1276/*.c) \
	$(wildcard $(LIB_DIR)/LoRaWAN/Utilities/*.c) \
	$(wildcard $(LIB_DIR)/stm/src/*.c) \
	$(patsubst %.c,$(LIB_DIR)/stm/STM32L0xx_HAL_Driver/Src/%.c,$(STM_HAL_SRC)) \

################################################################################
# Include directories                                                          #
################################################################################
INC_DIR += \
	$(SRC_DIR) \
	$(CFG_DIR) \
	$(LIB_DIR)/loramac-node/src/peripherals/soft-se \
	$(LIB_DIR)/loramac-node/src/mac/region \
	$(LIB_DIR)/loramac-node/src/mac \
	$(LIB_DIR)/loramac-node/src/radio\
	$(LIB_DIR)/loramac-node/src/radio/sx1276 \
	$(LIB_DIR)/LoRaWAN/Utilities \
	$(LIB_DIR)/stm/include \
	$(LIB_DIR)/stm/STM32L0xx_HAL_Driver/Inc \
	$(LIB_DIR)/rtt \

################################################################################
# ASM sources                                                                  #
################################################################################

ASM_SOURCES ?= $(LIB_DIR)/stm/src/startup_stm32l072xx.s

################################################################################
# Linker script                                                                #
################################################################################

LINKER_SCRIPT ?= $(CFG_DIR)/STM32L072CZEx_FLASH.ld

################################################################################
# Toolchain                                                                    #
################################################################################

TOOLCHAIN ?= arm-none-eabi-
CC = $(TOOLCHAIN)gcc
GDB = $(TOOLCHAIN)gdb
AS = $(TOOLCHAIN)gcc -x assembler-with-cpp
OBJCOPY = $(TOOLCHAIN)objcopy
SIZE = $(TOOLCHAIN)size

################################################################################
# Verbose build?                                                               #
################################################################################

ifeq ("$(BUILD_VERBOSE)","1")
Q :=
ECHO = @echo
else
MAKE += -s
Q := @
ECHO = @echo
endif

################################################################################
# Compiler flags for "c" files                                                 #
################################################################################

CFLAGS += -mcpu=cortex-m0plus
CFLAGS += -mthumb
CFLAGS += -mlittle-endian
CFLAGS += -Wall
CFLAGS += -pedantic
CFLAGS += -Wextra
CFLAGS += -Wmissing-include-dirs
CFLAGS += -Wswitch-default
CFLAGS += -D'__weak=__attribute__((weak))'
CFLAGS += -D'__packed=__attribute__((__packed__))'
CFLAGS += -D'STM32L072xx'
CFLAGS += -D'HAL_IWDG_MODULE_ENABLED'
CFLAGS += -ffunction-sections
CFLAGS += -fdata-sections
CFLAGS += -std=c11
CFLAGS_DEBUG += -g3
CFLAGS_DEBUG += -Og
CFLAGS_DEBUG += -D'DEBUG'
CFLAGS_RELEASE += -Os
CFLAGS_RELEASE += -D'RELEASE'

CFLAGS_RELEASE += -D'UART_BAUDRATE=${BAUDRATE}'
# CFLAGS += -D'USE_HAL_DRIVER'
CFLAGS += -DUSE_FULL_LL_DRIVER
CFLAGS += -DSOFT_SE
#CFLAGS += -DSECURE_ELEMENT_PRE_PROVISIONED
CFLAGS += -DLORAMAC_CLASSB_ENABLED

# Enable all regions and for selected regions select the corresponding default
# channel plans. These have been copied from lorawan-node/src/mac/CMakelists.txt
CFLAGS += -DREGION_AS923
CFLAGS += -DREGION_AU915
CFLAGS += -DREGION_CN470
CFLAGS += -DREGION_CN779
CFLAGS += -DREGION_EU443
CFLAGS += -DREGION_EU868
CFLAGS += -DREGION_IN865
CFLAGS += -DREGION_KR920
CFLAGS += -DREGION_RU864
CFLAGS += -DREGION_US915
CFLAGS += -DREGION_AS923_DEFAULT_CHANNEL_PLAN=CHANNEL_PLAN_GROUP_AS923_1
CFLAGS += -DREGION_CN470_DEFAULT_CHANNEL_PLAN=CHANNEL_PLAN_20MHZ_TYPE_A

################################################################################
# Compiler flags for "s" files                                                 #
################################################################################

ASFLAGS += -mcpu=cortex-m0plus
ASFLAGS += --specs=nano.specs
ASFLAGS += -mfloat-abi=soft
ASFLAGS += -mthumb
ASFLAGS += -mlittle-endian
ASFLAGS_DEBUG += -g3
ASFLAGS_DEBUG += -Og
ASFLAGS_RELEASE += -Os

################################################################################
# Linker flags                                                                 #
################################################################################

LDFLAGS += -mcpu=cortex-m0plus
LDFLAGS += -mthumb
LDFLAGS += -mlittle-endian
LDFLAGS += -T$(LINKER_SCRIPT)
LDFLAGS += -Wl,-lc
LDFLAGS += -Wl,-lm
LDFLAGS += -static
LDFLAGS += -Wl,-Map=$(MAP)
LDFLAGS += -Wl,--gc-sections
LDFLAGS += -Wl,--print-memory-usage
LDFLAGS += -Wl,-u,__errno
LDFLAGS += --specs=nosys.specs

################################################################################
# Create list of object files and their dependencies                           #
################################################################################

OBJ_C = $(SRC_FILES:%.c=$(OBJ_DIR)/$(TYPE)/%.o)
OBJ_S = $(ASM_SOURCES:%.s=$(OBJ_DIR)/$(TYPE)/%.o)
OBJ = $(OBJ_C) $(OBJ_S)
DEP = $(OBJ:%.o=%.d)
ALLDEP = $(MAKEFILE_LIST)

################################################################################
# Debug target                                                                 #
################################################################################

.PHONY: debug
debug: $(ALLDEP)
	$(Q)$(MAKE) .clean-out
	$(Q)$(MAKE) .obj-debug
	$(Q)$(MAKE) elf
	$(Q)$(MAKE) size
	$(Q)$(MAKE) bin

################################################################################
# Release target                                                               #
################################################################################

.PHONY: release
release: $(ALLDEP)
	$(Q)$(MAKE) clean TYPE=release
	$(Q)$(MAKE) .obj-release TYPE=release
	$(Q)$(MAKE) elf TYPE=release
	$(Q)$(MAKE) size TYPE=release
	$(Q)$(MAKE) bin TYPE=release
	$(Q)$(MAKE) .clean-obj TYPE=release

################################################################################
# Clean target                                                                 #
################################################################################

.PHONY: clean
clean: $(ALLDEP)
	$(Q)$(MAKE) .clean-obj
	$(Q)$(MAKE) .clean-out

.PHONY: .clean-obj
.clean-obj: $(ALLDEP)
	$(Q)$(ECHO) "Removing object directory..."
	$(Q)rm -rf $(OBJ_DIR)/$(TYPE)

.PHONY: .clean-out
.clean-out: $(ALLDEP)
	$(Q)$(ECHO) "Clean output ..."
	$(Q)rm -f "$(ELF)" "$(MAP)" "$(BIN)"

################################################################################
# J-Link                                          #
################################################################################

.PHONY: flash
flash: $(ALLDEP)
ifeq ($(OS),Windows_NT)
	JLink -device stm32l072cz -CommanderScript tools/jlink/flash.jlink
else
	JLinkExe -device stm32l072cz -CommanderScript tools/jlink/flash.jlink
endif

.PHONY: gdbserver
gdbserver: $(ALLDEP)
ifeq ($(OS),Windows_NT)
	JLinkGDBServerCL -singlerun -device stm32l072cz -if swd -speed 4000 -localhostonly -reset
else
	JLinkGDBServer -singlerun -device stm32l072cz -if swd -speed 4000 -localhostonly -reset
endif

.PHONY: jlink
jlink: $(ALLDEP)
	$(Q)$(MAKE) jlink-flash
	$(Q)$(MAKE) jlink-gdbserver

.PHONY: ozone
ozone: debug $(ALLDEP)
	$(Q)$(ECHO) "Launching Ozone debugger..."
	$(Q)Ozone tools/ozone/ozone.jdebug


################################################################################
# git submodule                                                                #
################################################################################

$(LIB_DIR)/loramac-node/LICENSE:
	@git submodule update --init lib/loramac-node

################################################################################
# Link object files                                                            #
################################################################################

.PHONY: elf
elf: $(ELF) $(ALLDEP)

$(ELF): $(OBJ) $(ALLDEP)
	$(Q)$(ECHO) "Linking object files..."
	$(Q)mkdir -p $(OUT_DIR)/$(TYPE)
	$(Q)$(CC) $(LDFLAGS) $(OBJ) -o $(ELF)

################################################################################
# Print information about size of sections                                     #
################################################################################

.PHONY: size
size: $(ELF) $(ALLDEP)
	$(Q)$(ECHO) "Size of sections:"
	$(Q)$(SIZE) $(ELF)

################################################################################
# Create binary file                                                           #
################################################################################

.PHONY: bin
bin: $(BIN) $(ALLDEP)

$(BIN): $(ELF) $(ALLDEP)
	$(Q)$(ECHO) "Creating $(BIN) from $(ELF)..."
	$(Q)$(OBJCOPY) -O binary $(ELF) $(BIN)
	$(Q)rm -f $(OUT).bin
	$(Q)cp $(BIN) $(OUT).bin

################################################################################
# Compile source files                                                         #
################################################################################

.PHONY: .obj-debug
.obj-debug: CFLAGS += $(CFLAGS_DEBUG)
.obj-debug: ASFLAGS += $(ASFLAGS_DEBUG)
.obj-debug: $(OBJ) $(ALLDEP)

.PHONY: .obj-release
.obj-release: CFLAGS += $(CFLAGS_RELEASE)
.obj-release: ASFLAGS += $(ASFLAGS_RELEASE)
.obj-release: $(OBJ) $(ALLDEP)

################################################################################
# Compile "c" files                                                            #
################################################################################

$(OBJ_DIR)/$(TYPE)/%.o: %.c $(ALLDEP)
	$(Q)$(ECHO) "Compiling: $<"
	$(Q)mkdir -p $(@D)
	$(Q)$(CC) -MMD -MP -MT "$@ $(@:.o=.d)" -c $(CFLAGS) $(foreach d,$(INC_DIR),-I$d) $< -o $@

################################################################################
# Compile "s" files                                                            #
################################################################################

$(OBJ_DIR)/$(TYPE)/%.o: %.s $(ALLDEP)
	$(Q)$(ECHO) "Compiling: $<"
	$(Q)mkdir -p $(@D)
	$(Q)$(CC) -MMD -MP -MT "$@ $(@:.o=.d)" -c $(ASFLAGS) $< -o $@
