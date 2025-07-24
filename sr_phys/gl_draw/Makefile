SRC_DIR = src
BUILD_DIR = build

objects = $(addprefix $(BUILD_DIR)/,gl_draw.o camera.o mesh.o objects.o shaders.o lights.o)

libs = lib/src/gl.o

LINKER_FLAGS = -lGL -lm

INCLUDE_DIRS = -Iinclude

LIB_INCLUDE = -Ilib/include
LIB_SRC = lib/src/*

libsr_draw: $(objects) $(BUILD_DIR)/gl.o
	ar rcs $@.so $^ 
#	gcc -Wall -Wextra $(LINKER_FLAGS) $(LIB_INCLUDE) $(INCLUDE_DIRS) $(LIB_SRC) $^ --static -o $@ 

# $@ = sr_draw
# $^ = all the deps

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	gcc -Wall -Wextra -Ilib/include -fPIC -c $< -o $@

$(BUILD_DIR)/gl.o: lib/src/gl.c
	gcc -Wall -Wextra -Ilib/include -fPIC -c $< -o $@
	
clean:
	rm $(objects)
