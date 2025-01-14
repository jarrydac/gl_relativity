#version 330 core
in vec3 color;
out vec4 FragColor;

void main(){
    FragColor = vec4(color.r, color.g, color.b, 0.5f);
}
