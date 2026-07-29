ROOT_DIR ?= $(abspath ../..)
BUILD_ROOT ?= $(ROOT_DIR)/.build
OUTPUT ?= $(BUILD_ROOT)/agent-workspace-rq3
CC ?= cc
CFLAGS ?= -g -O2
STRICT_CFLAGS := -std=c11 -Wall -Wextra -Werror -Wpedantic -Wformat=2 \
	-Wshadow -Wconversion -Wstrict-prototypes

.PHONY: all clean

all: $(OUTPUT)/wrapfs_agent_workspace_rq3

$(OUTPUT):
	install -d "$@"

$(OUTPUT)/wrapfs_agent_workspace_rq3: wrapfs_agent_workspace_rq3.c \
		semantic_oracles.h | $(OUTPUT)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(STRICT_CFLAGS) -o "$@" "$<"

clean:
	rm -rf "$(OUTPUT)"
