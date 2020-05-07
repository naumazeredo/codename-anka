package anka

import "core:fmt"
import "core:os"

import sdl "external/sdl2"
import gl  "external/gl"
import stb "external/stb"

import "util"

// @Refactor(naum): move this to game system when we have one
render_system : Render_System;

// @Refactor(naum): create types: VAO, buffer_object (VBO/EBO), shader_program
Render_System :: struct {
  textures   : [dynamic]u32,
  textures_w : [dynamic]u32,
  textures_h : [dynamic]u32,

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

  draw_call_texture : [dynamic]i32,
  draw_call_start : [dynamic]u32,
  draw_call_count : [dynamic]u32,

  texture_uniform : i32,
}


init_render :: proc(using render_system: ^Render_System) {
  id, ok := gl.load_shaders("assets/shaders/default.vs", "assets/shaders/default.fs");
  //id, ok := gl.load_shaders("assets/shaders/solid.vs", "assets/shaders/solid.fs");
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

  //cstr := util.create_cstring("tex");
  cstr := [4]u8 { 't', 'e', 'x', '\x00' };
  texture_uniform = gl.GetUniformLocation(program_id, &cstr[0]);
}

cleanup_render :: proc(using render_system: ^Render_System) {
  gl.DeleteVertexArrays(1, &vao);

  gl.DeleteBuffers(1, &vertex_buffer_object);
  gl.DeleteBuffers(1, &uv_buffer_object);
  gl.DeleteBuffers(1, &color_buffer_object);
  gl.DeleteBuffers(1, &element_buffer_object);
}

// @Refactor(naum): normalize filenames to be "assets/..." or "assets/gfx/..."
// @Incomplete(naum): struct to store texture info (pixel_format, color_format, width, height, data)
load_image :: proc(using render_system: ^Render_System, filename: string) -> i32 {
  // tprint
  png_data, ok := os.read_entire_file(filename);
  if !ok {
    // @Refactor(naum): error logging
    fmt.println("Could not read image file: ", filename);
    return -1;
  }

  width, height, channels : i32;
  pixel_data := stb.load_from_memory(&png_data[0], cast(i32)len(png_data), &width, &height, &channels, 0);
  defer stb.image_free(pixel_data);

  if pixel_data == nil {
    // @Refactor(naum): error logging
    fmt.println("Could not load image: ", filename);
    return -1;
  }

  tex : u32;
  gl.GenTextures(1, &tex);
  gl.BindTexture(gl.TEXTURE_2D, tex);
  gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, pixel_data);

  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);

  append(&textures, tex);
  append(&textures_w, u32(width));
  append(&textures_h, u32(height));

  return i32(len(textures)-1);
}

render_new_frame :: proc(using render_system: ^Render_System) {
  clear(&vertex_buffer);
  clear(&uv_buffer);
  clear(&color_buffer);
  clear(&element_buffer);

  clear(&draw_call_start);
  clear(&draw_call_count);
  clear(&draw_call_texture);
}

// @Incomplete(naum): draw commands (2d/3d)
// @Incomplete(naum): render layer
// @Incompelte(naum): add texture and color
// @Refactor(naum): xywh uniform coordinates (not screen coordinates)
// @Refactor(naum): flip can be an enum/bitset
render_add_draw :: proc(using render_system: ^Render_System, x, y, w, h : f32, tex: i32, flip_v: bool = false, flip_h: bool = false) {
  assert(tex >= 0);

  start_vertex := u32(len(vertex_buffer));

  // vertex
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


  // color
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

  // uv
  // @Cleanup(naum)
  fh := f32(flip_h ? 1.0 : 0.0);
  fv := f32(flip_h ? 1.0 : 0.0);

  append(&uv_buffer, fh);
  append(&uv_buffer, 1-fv);

  append(&uv_buffer, 1-fh);
  append(&uv_buffer, 1-fv);

  append(&uv_buffer, 1-fh);
  append(&uv_buffer, fv);

  append(&uv_buffer, fh);
  append(&uv_buffer, fv);

  // elements
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
  append(&draw_call_texture, tex);
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

  gl.BindBuffer(gl.ARRAY_BUFFER, uv_buffer_object);
  gl.BufferData(gl.ARRAY_BUFFER,
                size_of(f32) * len(uv_buffer),
                &uv_buffer[0],
                gl.STREAM_DRAW);

  gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, element_buffer_object);
  gl.BufferData(gl.ELEMENT_ARRAY_BUFFER,
                size_of(u32) * len(element_buffer),
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
  gl.VertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, 0, rawptr(uintptr(0)));

  // uv
  gl.EnableVertexAttribArray(2);
  gl.BindBuffer(gl.ARRAY_BUFFER, uv_buffer_object);
  gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 0, rawptr(uintptr(0)));

  // element buffer
  gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, element_buffer_object);

  // texture
  gl.ActiveTexture(gl.TEXTURE0);
  gl.Uniform1i(texture_uniform, 0);

  for _, id in draw_call_start {
    start := draw_call_start[id];
    count := draw_call_count[id];
    tex   := textures[draw_call_texture[id]];

    gl.BindTexture(gl.TEXTURE_2D, tex);

    gl.DrawElements(gl.TRIANGLES, i32(count), gl.UNSIGNED_INT, rawptr((uintptr)(start * size_of(u32))));
    //glDrawElementsBaseVertex(GL_TRIANGLES, count, GL_UNSIGNED_INT, 0, start ? 4 : 0);
  }

  render_new_frame(render_system);
}
