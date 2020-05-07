package anka

import sdl "external/sdl2"
import gl  "external/gl"

init_opengl :: proc(version_major, version_minor: int) {
  gl.load_up_to(
    version_major,
    version_minor,
    proc(p: rawptr, name: cstring) do (cast(^rawptr)p)^ = sdl.gl_get_proc_address(name);
  );
}

VAO :: distinct u32;

FBO :: distinct u32;
VBO :: distinct u32;
EBO :: distinct u32;

Texture_Id :: distinct u32;
Program_Id :: distinct u32;

gen_vao :: inline proc() -> VAO {
  vao : u32;
  gl.GenVertexArrays(1, &vao);
  return cast(VAO)vao;
}

bind_vao :: inline proc(vao: VAO) {
  gl.BindVertexArray(cast(u32)vao);
}

delete_vao :: inline proc(vao: VAO) {
  _vao := vao;
  gl.DeleteVertexArrays(1, cast(^u32)&_vao);
}
