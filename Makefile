DEBUG    ?= 0
COVERAGE ?= 0
LTO      ?= 1
LLVM     ?= 0

ifeq ($(LLVM),1)
CC := clang
else
CC := gcc
endif

COMPILER_OUTPUT := $(shell $(CC) --version 2>&1)

ifneq ($(findstring clang,$(COMPILER_OUTPUT)),)
    DETECTED_COMPILER := clang
else ifneq ($(findstring GCC,$(COMPILER_OUTPUT)),)
    DETECTED_COMPILER := gcc
else
    DETECTED_COMPILER := unknown
endif

TARGET  := genpasswd
SRC_DIR := src
OBJ_DIR := obj

SRCS    := $(wildcard $(SRC_DIR)/*.c)
OBJS    := $(patsubst $(SRC_DIR)/%.c, $(OBJ_DIR)/%.o, $(SRCS))

USERFLAGS := -march=native

LIBSODIUM_CFLAGS := $(shell pkg-config --cflags libsodium 2>/dev/null || echo "")
LIBSODIUM_LIBS   := $(shell pkg-config --libs libsodium 2>/dev/null || echo "-lsodium")

ifeq ($(DEBUG),1)
    OPT_FLAGS := -O0 -g3 -ggdb3
    override LTO := 0
else
    OPT_FLAGS := -O2
endif

ifeq ($(LTO),1)
    OPT_FLAGS += -flto
    LDFLAGS   += -flto
endif

ifeq ($(COVERAGE),1)
    OPT_FLAGS += --coverage
    LDFLAGS   += --coverage
endif

CFLAGS := -Wall -Werror -Wextra -Wpedantic -fPIE $(OPT_FLAGS) $(USERFLAGS)
LDFLAGS += -pie -Wl,-z,relro,-z,now $(LIBSODIUM_LIBS)

ifeq ($(DETECTED_COMPILER),clang)
    CFLAGS := $(CFLAGS) -fstack-protector-strong $(LIBSODIUM_CFLAGS)
else ifeq ($(DETECTED_COMPILER),gcc)
    CFLAGS := $(CFLAGS) -fhardened -fstack-protector-strong --param=ssp-buffer-size=4 $(LIBSODIUM_CFLAGS)
else
    CFLAGS := $(CFLAGS) $(LIBSODIUM_CFLAGS)
endif

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c | $(OBJ_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

clean:
	rm -rf $(OBJ_DIR) $(TARGET) $(SRC_DIR)/*.gcda $(SRC_DIR)/*.gcno *.gcda *.gcno

.PHONY: all clean
