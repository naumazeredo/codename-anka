#version 330 core

in vec4 frag_color;

uniform sampler2D tex;

out vec4 out_color;

void main() {
  out_color = frag_color;
}
