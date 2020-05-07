package anka

import "core:fmt"

import sdl "external/sdl2"
import gl  "external/gl"

import "util"

// @Refactor(naum): move this to game system when we have one
render_system : Render_System;

Render_System :: struct {
  /*
  textures  : [dynamic]u32,
  texture_w : [dynamic]u32,
  texture_h : [dynamic]u32,
  */

  // @Refactor(naum): allow multiple programs
  program_id : u32,

  // @Refactor(naum): allow multiple objects
  vao : u32,

  // @Refactor(naum): buffer_objects : [dynamic]u32,
  vertex_buffer_object  : u32,
  color_buffer_object   : u32,
  uv_buffer_object      : u32,
  element_buffer_object : u32,

  // @Refactor(naum): draw_commands : [dynamic]Draw_Command
  // frame buffers
  vertex_buffer  : [dynamic]f32,
  color_buffer   : [dynamic]f32,
  uv_buffer      : [dynamic]f32,
  element_buffer : [dynamic]u32,

  draw_call_start : [dynamic]u32,
  draw_call_count : [dynamic]u32,

  texture_id : i32,
}

init_render :: proc(using render_system: ^Render_System) {
  //id, ok := gl.load_shaders("assets/default.vs", "assets/default.fs");
  id, ok := gl.load_shaders("assets/shaders/solid.vs", "assets/shaders/solid.fs");
  if !ok {
    // @Refactor(naum): error logging
    fmt.println("Could not load shaders");
  }

  program_id = id;

  gl.GenVertexArrays(1, &vao);

  gl.GenBuffers(1, &vertex_buffer_object);
  gl.GenBuffers(1, &uv_buffer_object);
  gl.GenBuffers(1, &color_buffer_object);
  gl.GenBuffers(1, &element_buffer_object);

  cstr := [4]u8 { 't', 'e', 'x', '\x00' };
  texture_id = gl.GetUniformLocation(program_id, &cstr[0]);
}

cleanup_render :: proc(using render_system: ^Render_System) {
  gl.DeleteVertexArrays(1, &vao);

  gl.DeleteBuffers(1, &vertex_buffer_object);
  gl.DeleteBuffers(1, &uv_buffer_object);
  gl.DeleteBuffers(1, &color_buffer_object);
  gl.DeleteBuffers(1, &element_buffer_object);
}

render_new_frame :: proc(using render_system: ^Render_System) {
  clear(&vertex_buffer);
  clear(&uv_buffer);
  clear(&color_buffer);
  clear(&element_buffer);

  clear(&draw_call_start);
  clear(&draw_call_count);
}

// @Incomplete(naum): draw commands (2d/3d)
// @Incomplete(naum): render layer
// @Incompelte(naum): add texture and color
// @Refactor(naum): xywh uniform coordinates (not screen coordinates)
// @Speed(naum): optimize element buffers for 2d (only quads)
render_add_draw :: proc(x, y, w, h : f32, using render_system: ^Render_System) {
  start_vertex := u32(len(vertex_buffer));

  //
  append(&vertex_buffer, x);
  append(&vertex_buffer, y);
  append(&vertex_buffer, 0);

  append(&vertex_buffer, x+w);
  append(&vertex_buffer, y);
  append(&vertex_buffer, 0);

  append(&vertex_buffer, x+w);
  append(&vertex_buffer, y+h);
  append(&vertex_buffer, 0);

  append(&vertex_buffer, x);
  append(&vertex_buffer, y+h);
  append(&vertex_buffer, 0);


  //
  append(&color_buffer, 1);
  append(&color_buffer, 1);
  append(&color_buffer, 1);
  append(&color_buffer, 1);

  append(&color_buffer, 1);
  append(&color_buffer, 1);
  append(&color_buffer, 1);
  append(&color_buffer, 1);

  append(&color_buffer, 1);
  append(&color_buffer, 1);
  append(&color_buffer, 1);
  append(&color_buffer, 1);

  append(&color_buffer, 1);
  append(&color_buffer, 1);
  append(&color_buffer, 1);
  append(&color_buffer, 1);

  //
  append(&element_buffer, start_vertex+0);
  append(&element_buffer, start_vertex+1);
  append(&element_buffer, start_vertex+2);

  append(&element_buffer, start_vertex+2);
  append(&element_buffer, start_vertex+3);
  append(&element_buffer, start_vertex+0);

  //
  if len(draw_call_start) == 0 {
    append(&draw_call_start, 0);
  } else {
    last := len(draw_call_start) - 1;
    append(&draw_call_start, draw_call_start[last] + draw_call_count[last]);
  }

  append(&draw_call_count, 6);
}

// @Incomplete(naum): use camera info
render :: proc(window: ^Window, using render_system: ^Render_System) {
  gl.ClearColor(1.0, 0.0, 1.0, 1.0);
  gl.Clear(gl.COLOR_BUFFER_BIT);

  defer sdl.gl_swap_window(window.sdl_window);

  if len(vertex_buffer) == 0 {
    return;
  }

  // @Refactor(naum): maybe split opaque and translucent draws
  gl.Enable(gl.BLEND);
  gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

  // assign buffer data
  gl.BindBuffer(gl.ARRAY_BUFFER, vertex_buffer_object);
  gl.BufferData(gl.ARRAY_BUFFER,
                size_of(f32) * len(vertex_buffer),
                &vertex_buffer[0],
                gl.STREAM_DRAW);

  gl.BindBuffer(gl.ARRAY_BUFFER, color_buffer_object);
  gl.BufferData(gl.ARRAY_BUFFER,
                size_of(f32) * len(color_buffer),
                &color_buffer[0],
                gl.STREAM_DRAW);

  /*
  gl.BindBuffer(gl.ARRAY_BUFFER, uv_buffer_object);
  gl.BufferData(gl.ARRAY_BUFFER,
                size_of(f32) * len(uv_buffer),
                &uv_buffer[0],
                gl.STREAM_DRAW);
  */

  gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, element_buffer_object);
  gl.BufferData(gl.ELEMENT_ARRAY_BUFFER,
                size_of(f32) * len(element_buffer),
                &element_buffer[0],
                gl.STREAM_DRAW);

  gl.BindVertexArray(vao);

  gl.UseProgram(program_id);

  // vertex
  gl.EnableVertexAttribArray(0);
  gl.BindBuffer(gl.ARRAY_BUFFER, vertex_buffer_object);
  gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 0, rawptr(uintptr(0)));

  // colors
  gl.EnableVertexAttribArray(1);
  gl.BindBuffer(gl.ARRAY_BUFFER, color_buffer_object);
  gl.VertexAttribPointer(2, 4, gl.FLOAT, gl.FALSE, 0, rawptr(uintptr(0)));

  // uv
  /*
  gl.EnableVertexAttribArray(2);
  gl.BindBuffer(gl.ARRAY_BUFFER, uv_buffer_object);
  gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 0, rawptr(uintptr(0)));
  */

  // element buffer
  gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, element_buffer_object);

  // texture
  gl.ActiveTexture(gl.TEXTURE0);
  gl.Uniform1i(texture_id, 0);

  for _, id in draw_call_start {
    start := draw_call_start[id];
    count := draw_call_count[id];
    //fmt.println(id, start, count);

    //gl.DrawElements(gl.TRIANGLES, i32(count), gl.UNSIGNED_INT, rawptr((uintptr)(start * size_of(u32))));
    //gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, rawptr(uintptr(0)));
  }

  /*
  for (u32 i = 0; i < render_info.draw_texture.size(); i++) {
    auto index = new_order[i];

    auto tex = render_info.texture[render_info.draw_texture[index]];
    auto start = render_info.draw_start_element[index];
    auto count = render_info.draw_count_element[index];

    // texture
    glBindTexture(GL_TEXTURE_2D, tex);

    // draw call
    glDrawElements(GL_TRIANGLES, count, GL_UNSIGNED_INT, (void*)(intptr_t)(start * sizeof(GLuint)));
    //glDrawElementsBaseVertex(GL_TRIANGLES, count, GL_UNSIGNED_INT, 0, start ? 4 : 0);
  }
  */

  render_new_frame(render_system);
}
