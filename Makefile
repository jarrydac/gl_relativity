SRC_DIR = src
BUILD_DIR = build
LIB_DIR = lib

objects = $(addprefix $(BUILD_DIR)/,gl_draw.o camera.o mesh.o objects.o shaders.o lights.o)

libs = lib/src/gl.o

LINKER_FLAGS = -lGL -lm

INCLUDE_DIRS = -Iinclude

LIB_INCLUDE = -Ilib/include
LIB_SRC = lib/src/*

libgl_relativity: $(objects) $(BUILD_DIR)/gl.o $(LIB_DIR)/include/cglm/cglm.h
	ar rcs $@.so $^ 
#	gcc -Wall -Wextra $(LINKER_FLAGS) $(LIB_INCLUDE) $(INCLUDE_DIRS) $(LIB_SRC) $^ --static -o $@ 

# $@ = sr_draw
# $^ = all the deps

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	gcc -Wall -Wextra -Ilib/include -fPIC -c $< -o $@

$(BUILD_DIR)/gl.o: lib/src/gl.c
	gcc -Wall -Wextra -Ilib/include -fPIC -c $< -o $@
	
# Download cglm
$(LIB_DIR)/include/cglm/cglm.h:
	wget -O $(BUILD_DIR)/cglm.tar.gz https://github.com/recp/cglm/archive/refs/tags/v0.9.6.tar.gz
	tar -xzf $(BUILD_DIR)/cglm.tar.gz -C $(BUILD_DIR)/
	mv $(BUILD_DIR)/cglm-* $(BUILD_DIR)/cglm
	rsync $(BUILD_DIR)/cglm/src/ $(LIB_DIR)/src 
	cp $(BUILD_DIR)/cglm/include/cglm $(LIB_DIR)/include -r

clean:
	rm $(objects)
	rm $(BUILD_DIR)/cglm* -r
