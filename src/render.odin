// @Incomplete(naum): create camera
// @Incomplete(naum): create camera pixel perfect

package anka

import "core:fmt"
import "core:os"

import sdl "external/sdl2"
import gl  "external/gl"
import stb "external/stb"

import "util"

// @Refactor(naum): move this to game system when we have one
render_system : Render_System;

// @Refactor(naum): move this to a gl specific file
// @Refactor(naum): make all strongly typed
VAO           :: u32;
Shader        :: u32;
Texture       :: u32;
Buffer_Object :: u32;
Uniform       :: i32;

Texture_Id    :: u32;

// @Refactor(naum): use bucket array to have a pointer valid container
Render_System :: struct {
  // @Refactor(naum): create texture container
  textures   : [dynamic]Texture,
  textures_w : [dynamic]u32,
  textures_h : [dynamic]u32,

  // @Refactor(naum): allow multiple programs
  shader: Shader,

  // @Refactor(naum): allow multiple objects
  vao : u32,

  // @Refactor(naum): buffer_objects : [dynamic]u32 (?)
  vertex_buffer_object  : Buffer_Object,
  color_buffer_object   : Buffer_Object,
  uv_buffer_object      : Buffer_Object,
  element_buffer_object : Buffer_Object,

  world_draw_calls : [dynamic]Draw_Call,
  //ui_draw_calls    : [dynamic]Draw_Call,

  // @Refactor(naum): draw_commands : [dynamic]Draw_Command
  // frame buffers
  vertex_buffer  : [dynamic]f32,
  color_buffer   : [dynamic]f32,
  uv_buffer      : [dynamic]f32,
  element_buffer : [dynamic]u32,

  draw_call_texture : [dynamic]u32,
  draw_call_start : [dynamic]u32,
  draw_call_count : [dynamic]u32,



  // @Refactor(naum): get uniforms from shaders during draw calls
  texture_uniform : Uniform,
}

/*
Render_Mode :: enum {
  Wireframe,
  Solid,
}
*/

Texture_Flip :: enum {
  Horizontal,
  Vertical,
}

Texture_Flip_Set :: bit_set[Texture_Flip];

Draw_Quad :: struct {
  x, y, w, h : f32,
}

// @Refactor(naum): subtexture (uv) information: create a sprite container?
//                  do we need need access to uv or can we use whole sprite?
// uses texture size
Draw_Quad_Scale :: struct {
  pos   : Vec2f,
  scale : Vec2f,
}

Draw_Type :: union {
  Draw_Quad,
  Draw_Quad_Scale,

  // @Refactor(naum): 2D vs 3D
}

// @Naming(naum): draw_call vs draw_command
Draw_Call :: struct {
  shader  : Shader,
  texture : Texture_Id, // @Future(naum): subtexture (with UV info)
  layer   : i32, // (2D only) less is back, high is front
  flip    : Texture_Flip_Set,
  type    : Draw_Type,
}


init_opengl :: proc(version_major, version_minor: int) {
  gl.load_up_to(
    version_major,
    version_minor,
    proc(p: rawptr, name: cstring) do (cast(^rawptr)p)^ = sdl.gl_get_proc_address(name);
  );
}

init_render :: proc(using render_system: ^Render_System) {
  id, ok := gl.load_shaders("assets/shaders/default.vs", "assets/shaders/default.fs");
  if !ok {
    // @Refactor(naum): error logging
    fmt.println("Could not load shaders");
  }

  shader = id;

  gl.GenVertexArrays(1, &vao);

  gl.GenBuffers(1, &vertex_buffer_object);
  gl.GenBuffers(1, &uv_buffer_object);
  gl.GenBuffers(1, &color_buffer_object);
  gl.GenBuffers(1, &element_buffer_object);

  texture_uniform = gl.GetUniformLocation(shader, cast(^u8)util.create_cstring("tex"));
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
load_image :: proc(using render_system: ^Render_System, filename: string) -> (Texture_Id, bool) {
  // tprint
  png_data, ok := os.read_entire_file(filename);
  if !ok {
    // @Refactor(naum): error logging
    fmt.println("Could not read image file: ", filename);
    return 0, false;
  }

  width, height, channels : i32;
  pixel_data := stb.load_from_memory(&png_data[0], cast(i32)len(png_data), &width, &height, &channels, 0);
  defer stb.image_free(pixel_data);

  if pixel_data == nil {
    // @Refactor(naum): error logging
    fmt.println("Could not load image: ", filename);
    return 0, false;
  }

  tex : Texture;
  gl.GenTextures(1, &tex);
  gl.BindTexture(gl.TEXTURE_2D, tex);
  gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, pixel_data);

  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);

  append(&textures, tex);
  append(&textures_w, u32(width));
  append(&textures_h, u32(height));

  return u32(len(textures)-1), true;
}

// @Incomplete(naum): draw commands (2d/3d)
// @Incomplete(naum): render layer
// @Incompelte(naum): add color
// @Refactor(naum): xywh uniform coordinates (not screen coordinates)
// @Speed(naum): gather by layer (depth test instead?), shader, texture (in this order)
render_add_draw_call :: proc(using render_system: ^Render_System, x, y, w, h : f32, tex: Texture_Id, flip: Texture_Flip_Set = {}) {
  assert(tex >= 0);
  draw_call := Draw_Call {
    shader = shader,
    texture = tex,
    layer = 0,
    flip = flip,
    type = Draw_Quad {
      x, y, w, h
    }
  };

  append(&world_draw_calls, draw_call);
}

// @Incomplete(naum): considering same shader for all
_render_flush_draw_calls :: proc(using render_system: ^Render_System) {
  clear(&vertex_buffer);
  clear(&uv_buffer);
  clear(&color_buffer);
  clear(&element_buffer);

  clear(&draw_call_start);
  clear(&draw_call_count);
  clear(&draw_call_texture);

  x0, x1, y0, y1 : f32;

  for draw_call in world_draw_calls {
    switch type in draw_call.type {
      case Draw_Quad:
        x0 = type.x;
        x1 = type.x + type.w;
        y0 = type.y;
        y1 = type.y + type.h;

      case Draw_Quad_Scale:
        unimplemented();
    }


    // 2D quad draw
    // @Refactor(naum): only works for 2D quads

    elem := u32(len(vertex_buffer));

    // elements
    append(&element_buffer, elem + 0); append(&element_buffer, elem + 1); append(&element_buffer, elem + 2);
    append(&element_buffer, elem + 2); append(&element_buffer, elem + 3); append(&element_buffer, elem + 0);

    // vertex
    append(&vertex_buffer, x0); append(&vertex_buffer, y0); append(&vertex_buffer, 0);
    append(&vertex_buffer, x1); append(&vertex_buffer, y0); append(&vertex_buffer, 0);
    append(&vertex_buffer, x1); append(&vertex_buffer, y1); append(&vertex_buffer, 0);
    append(&vertex_buffer, x0); append(&vertex_buffer, y1); append(&vertex_buffer, 0);

    // color
    append(&color_buffer, 1); append(&color_buffer, 1); append(&color_buffer, 1); append(&color_buffer, 1);
    append(&color_buffer, 1); append(&color_buffer, 1); append(&color_buffer, 1); append(&color_buffer, 1);
    append(&color_buffer, 1); append(&color_buffer, 1); append(&color_buffer, 1); append(&color_buffer, 1);
    append(&color_buffer, 1); append(&color_buffer, 1); append(&color_buffer, 1); append(&color_buffer, 1);

    // uv
    // @Cleanup(naum)
    fh := f32(.Horizontal in draw_call.flip ? 1.0 : 0.0);
    fv := f32(.Vertical   in draw_call.flip ? 1.0 : 0.0);

    append(&uv_buffer, fh);   append(&uv_buffer, 1-fv);
    append(&uv_buffer, 1-fh); append(&uv_buffer, 1-fv);
    append(&uv_buffer, 1-fh); append(&uv_buffer, fv);
    append(&uv_buffer, fh);   append(&uv_buffer, fv);

    //
    if len(draw_call_start) == 0 {
      append(&draw_call_start, 0);
    } else {
      last := len(draw_call_start) - 1;
      append(&draw_call_start, draw_call_start[last] + draw_call_count[last]);
    }

    append(&draw_call_count, 6);
    append(&draw_call_texture, draw_call.texture);
  }

  clear(&world_draw_calls);
}

// @Incomplete(naum): use camera info
render :: proc(window: ^Window, using render_system: ^Render_System) {
  gl.ClearColor(1.0, 0.0, 1.0, 1.0);
  gl.Clear(gl.COLOR_BUFFER_BIT);

  defer sdl.gl_swap_window(window.sdl_window);

  if len(world_draw_calls) == 0 do return;

  _render_flush_draw_calls(render_system);

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

  gl.UseProgram(shader);

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
    // @Future(naum): glDrawElementsBaseVertex(GL_TRIANGLES, count, GL_UNSIGNED_INT, 0, start ? 4 : 0);
  }
}
