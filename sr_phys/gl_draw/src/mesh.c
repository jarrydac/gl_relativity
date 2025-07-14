#include "../lib/include/glad/gl.h"

#include "../include/mesh.h"

int sr_init_mesh(
        sr_mesh* mesh,
        int* indicies,
        int indicies_len,
        sr_mesh_vert* verts,
        int verts_len
    ){

    // VAO
    glGenVertexArrays(1, &mesh->vao_id);
    glBindVertexArray(mesh->vao_id);

    // EBO
    glGenBuffers(1, &mesh->ebo_id);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mesh->ebo_id);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indicies_len * sizeof(int), indicies, GL_STATIC_DRAW);
    mesh->elements_count = indicies_len;
    
    // VBO
    glGenBuffers(1, &mesh->vbo_id);
    glBindBuffer(GL_ARRAY_BUFFER, mesh->vbo_id);
    glBufferData(GL_ARRAY_BUFFER, verts_len * sizeof(sr_mesh_vert), verts, GL_STATIC_DRAW);

    glVertexAttribPointer( 0, 4, 
            GL_FLOAT, GL_FALSE, 
            sizeof( sr_mesh_vert ), 
            (void*) offsetof( sr_mesh_vert, position ) 
        );
    glEnableVertexAttribArray(0);

    glVertexAttribPointer( 1, 3, 
            GL_FLOAT, GL_FALSE, 
            sizeof( sr_mesh_vert ), 
            (void*) offsetof( sr_mesh_vert, normal ) 
        );
    glEnableVertexAttribArray(1);

    glBindVertexArray(0); // I dont trust myself.

    return 0;
}

void sr_delete_mesh(sr_mesh* mesh){
    if( mesh->ebo_id ) glDeleteBuffers(1, &mesh->ebo_id );
    if( mesh->vbo_id ) glDeleteBuffers(1, &mesh->vbo_id );
    if( mesh->vao_id ) glDeleteVertexArrays(1, &mesh->vao_id );
}
