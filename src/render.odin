// @Incomplete(naum): create camera
// @Incomplete(naum): create camera pixel perfect

package anka

import "core:fmt"
import "core:os"
import "core:math/linalg"

import sdl "external/sdl2"
import gl  "external/gl"
import stb "external/stb"

import "util"

// @Refactor(naum): move this to game system when we have one
render_system : Render_System;

// @Refactor(naum): move this to a gl specific file
// @Refactor(naum): make all strongly typed
Vertex_Array  :: u32;
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
  vertex_array_object : Vertex_Array,

  // @Refactor(naum): buffer_objects : [dynamic]u32 (?)
  vertex_buffer_object  : Buffer_Object,
  color_buffer_object   : Buffer_Object,
  uv_buffer_object      : Buffer_Object,
  element_buffer_object : Buffer_Object,

  world_draw_cmds : [dynamic]Draw_Command,
  //ui_draw_cmds    : [dynamic]Draw_Command,

  texture_uniform   : Uniform,
  model_mat_uniform : Uniform,
  view_mat_uniform  : Uniform,
  proj_mat_uniform  : Uniform,

  // @Refactor(naum): draw_commands : [dynamic]Draw_Command
  // frame buffers
  vertex_buffer  : [dynamic]f32,
  color_buffer   : [dynamic]f32,
  uv_buffer      : [dynamic]f32,
  element_buffer : [dynamic]u32,

  draw_cmd_texture   : [dynamic]u32,
  draw_cmd_start     : [dynamic]u32,
  draw_cmd_count     : [dynamic]u32,
  draw_cmd_translate : [dynamic]Vec2f,

  current_shader     : Shader,
  current_texture_id : Texture_Id,
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

// @Naming(naum): draw_cmd vs draw_command
Draw_Command :: struct {
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

  gl.GenVertexArrays(1, &vertex_array_object);

  gl.GenBuffers(1, &vertex_buffer_object);
  gl.GenBuffers(1, &uv_buffer_object);
  gl.GenBuffers(1, &color_buffer_object);
  gl.GenBuffers(1, &element_buffer_object);
}

cleanup_render :: proc(using render_system: ^Render_System) {
  gl.DeleteVertexArrays(1, &vertex_array_object);

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
render_add_draw_cmd :: proc(using render_system: ^Render_System, x, y, w, h: f32, tex: Texture_Id, layer: i32, flip: Texture_Flip_Set = {}) {
  draw_cmd := Draw_Command {
    shader = shader,
    texture = tex,
    layer = layer,
    flip = flip,
    type = Draw_Quad {
      x, y, w, h
    }
  };

  append(&world_draw_cmds, draw_cmd);
}

// @Incomplete(naum): considering same shader and texture for all
_render_flush_draw_cmds :: proc(using render_system: ^Render_System, window: ^Window) {
  x, y : f32;
  w, h : f32;

  for draw_cmd, id in world_draw_cmds {
    // @Refactor(naum): gather multiple cmds per draw call
    _change_shader (render_system, draw_cmd.shader);
    _change_texture(render_system, draw_cmd.texture);

    switch type in draw_cmd.type {
      case Draw_Quad:
        x = type.x; y = type.y;
        w = type.w; h = type.h;

      case Draw_Quad_Scale:
        unimplemented();
    }


    // @Refactor(naum): only works for 2D quads
    // 2D quad draw

    // elements
    elem := u32(len(vertex_buffer) / 3); // @Cleanup(naum): hacky way
    append(&element_buffer, elem + 0); append(&element_buffer, elem + 1); append(&element_buffer, elem + 2);
    append(&element_buffer, elem + 2); append(&element_buffer, elem + 3); append(&element_buffer, elem + 0);

    // vertex
    // @Refactor(naum): model rotation/translation via model_mat (?)
    /*
    append(&vertex_buffer, 0); append(&vertex_buffer, 0); append(&vertex_buffer, f32(draw_cmd.layer));
    append(&vertex_buffer, w); append(&vertex_buffer, 0); append(&vertex_buffer, f32(draw_cmd.layer));
    append(&vertex_buffer, w); append(&vertex_buffer, h); append(&vertex_buffer, f32(draw_cmd.layer));
    append(&vertex_buffer, 0); append(&vertex_buffer, h); append(&vertex_buffer, f32(draw_cmd.layer));
    */

    append(&vertex_buffer, x+0); append(&vertex_buffer, y+0); append(&vertex_buffer, f32(draw_cmd.layer));
    append(&vertex_buffer, x+w); append(&vertex_buffer, y+0); append(&vertex_buffer, f32(draw_cmd.layer));
    append(&vertex_buffer, x+w); append(&vertex_buffer, y+h); append(&vertex_buffer, f32(draw_cmd.layer));
    append(&vertex_buffer, x+0); append(&vertex_buffer, y+h); append(&vertex_buffer, f32(draw_cmd.layer));

    // color
    append(&color_buffer, 1); append(&color_buffer, 1); append(&color_buffer, 1); append(&color_buffer, 1);
    append(&color_buffer, 1); append(&color_buffer, 1); append(&color_buffer, 1); append(&color_buffer, 1);
    append(&color_buffer, 1); append(&color_buffer, 1); append(&color_buffer, 1); append(&color_buffer, 1);
    append(&color_buffer, 1); append(&color_buffer, 1); append(&color_buffer, 1); append(&color_buffer, 1);

    // uv
    // @Cleanup(naum)
    fh := f32(.Horizontal in draw_cmd.flip ? 1.0 : 0.0);
    fv := f32(.Vertical   in draw_cmd.flip ? 1.0 : 0.0);

    // @Fix(naum): is it correct? (check when loading 3d models)
    append(&uv_buffer, fh);   append(&uv_buffer, fv);
    append(&uv_buffer, 1-fh); append(&uv_buffer, fv);
    append(&uv_buffer, 1-fh); append(&uv_buffer, 1-fv);
    append(&uv_buffer, fh);   append(&uv_buffer, 1-fv);

    //
    if len(draw_cmd_start) == 0 {
      append(&draw_cmd_start, 0);
    } else {
      last := len(draw_cmd_start) - 1;
      append(&draw_cmd_start, draw_cmd_start[last] + draw_cmd_count[last]);
    }

    append(&draw_cmd_count, 6);
    append(&draw_cmd_texture, draw_cmd.texture);
    append(&draw_cmd_translate, Vec2f { x, y });

    // @Refactor(naum): gather multiple cmds per draw call
    _render_queued_cmds(render_system);
  }

  clear(&world_draw_cmds);
}

_render_queued_cmds :: proc(using render_system: ^Render_System) {
  _create_buffer_data(render_system);
  gl.DrawElements(gl.TRIANGLES, i32(len(element_buffer)), gl.UNSIGNED_INT, rawptr(uintptr(0)));

  /*
  for _, id in draw_cmd_start {
    start := draw_cmd_start[id];
    count := draw_cmd_count[id];
    tex   := textures[draw_cmd_texture[id]];
    trans := draw_cmd_translate[id];

    // @Refactor(naum): for 2D do we need model_mat? We can put translation directly in vbo and just draw all elements
    //model_mat := linalg.matrix4_translate({ trans.x, trans.y, 0 });
    model_mat := linalg.MATRIX4_IDENTITY;
    gl.UniformMatrix4fv(model_mat_uniform, 1, 0, &model_mat[0][0]);

    gl.BindTexture(gl.TEXTURE_2D, tex);

    //gl.DrawElements(gl.TRIANGLES, i32(count), gl.UNSIGNED_INT, rawptr((uintptr)(start * size_of(u32))));
    gl.DrawElements(gl.TRIANGLES, i32(count), gl.UNSIGNED_INT, rawptr((uintptr)(start * size_of(u32))));
    // @Future(naum): glDrawElementsBaseVertex(GL_TRIANGLES, count, GL_UNSIGNED_INT, 0, start ? 4 : 0);
  }
  */

  clear(&vertex_buffer);
  clear(&uv_buffer);
  clear(&color_buffer);
  clear(&element_buffer);

  clear(&draw_cmd_start);
  clear(&draw_cmd_count);
  clear(&draw_cmd_texture);
  clear(&draw_cmd_translate);
}

_change_texture :: proc(using render_system: ^Render_System, new_texture_id: Texture_Id) {
  current_texture_id = new_texture_id;

  gl.BindTexture(gl.TEXTURE_2D, textures[current_texture_id]);
}

_change_shader :: proc(using render_system: ^Render_System, new_shader: Shader) {
  current_shader = new_shader;
  gl.UseProgram(current_shader);

  texture_uniform = gl.GetUniformLocation(shader, cast(^u8)util.create_cstring("tex"));
  model_mat_uniform = gl.GetUniformLocation(shader, cast(^u8)util.create_cstring("model_mat"));
  view_mat_uniform = gl.GetUniformLocation(shader, cast(^u8)util.create_cstring("view_mat"));
  proj_mat_uniform = gl.GetUniformLocation(shader, cast(^u8)util.create_cstring("proj_mat"));

  gl.Uniform1i(texture_uniform, 0);

  // @Refactor(naum): move to camera
  // MVP matrixes
  view_mat := linalg.MATRIX4_IDENTITY;

  proj_mat := linalg.matrix_ortho3d(
    0.0, f32(window.width),
    f32(window.height), 0.0,
    -1000.0, 1000.0
  );

  gl.UniformMatrix4fv(view_mat_uniform, 1, 0, &view_mat[0][0]);
  gl.UniformMatrix4fv(proj_mat_uniform, 1, 0, &proj_mat[0][0]);

  // @Refactor(naum): model rotation/translation via model_mat
  model_mat := linalg.MATRIX4_IDENTITY;
  gl.UniformMatrix4fv(model_mat_uniform, 1, 0, &model_mat[0][0]);
}

_create_buffer_data :: proc(using render_system: ^Render_System) {
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
}

// @Incomplete(naum): shader/texture split
// @Incomplete(naum): use camera info
render :: proc(using render_system: ^Render_System, window: ^Window) {
  gl.ClearColor(1.0, 0.0, 1.0, 1.0);
  gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

  gl.Enable(gl.DEPTH_TEST);
  gl.DepthFunc(gl.LEQUAL);

  defer sdl.gl_swap_window(window.sdl_window);

  if len(world_draw_cmds) == 0 do return;

  // @Refactor(naum): maybe split opaque and translucent draws
  gl.Enable(gl.BLEND);
  gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

  gl.BindVertexArray(vertex_array_object);

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

  //
  _render_flush_draw_cmds(render_system, window);
}
