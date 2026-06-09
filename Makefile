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

LIBSODIUM_CFLAGS := $(shell pkg-config --cflags libsodium)
LIBSODIUM_LIBS   := $(shell pkg-config --libs libsodium)

CFLAGS := -Wall -Werror -Wextra -Wpedantic -O2 -fPIE $(USERFLAGS)
LDFLAGS := -pie -Wl,-z,relro,-z,now $(LIBSODIUM_LIBS)

ifeq ($(DETECTED_COMPILER),clang)
    CFLAGS := $(CFLAGS) -fsanitize=safe-stack -fstack-protector-strong $(LIBSODIUM_CFLAGS)
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
	rm -rf $(OBJ_DIR) $(TARGET)

.PHONY: all clean
