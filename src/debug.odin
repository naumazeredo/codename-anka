package anka

import "core:mem"
import "core:fmt"
import "core:math"
import "core:math/linalg"

import "external/sdl"
import "external/gl"
import "external/imgui"

import "util"

// @Refactor(naum): use struct
debug_sdl_window: ^sdl.Window;

debug_program: Program;

debug_uniform_texture    : Location;
debug_uniform_projection : Location;
debug_attrib_position    : Location;
debug_attrib_uv          : Location;
debug_attrib_color       : Location;

debug_vbo : Buffer_Object;
debug_ebo : Buffer_Object;

debug_font_texture : Buffer_Object;

// @Refactor(naum): use game time
debug_time : u64;

debug_mouse_pressed : [3]bool;

debug_sdl_frequency : u64;

init_debug :: proc(render_system: ^Render_System, window: ^Window) {
  debug_sdl_window = window.sdl_window;

  imgui.create_context();

  io := imgui.get_io();

  io.key_map[imgui.Key.Tab]         = i32(sdl.Scancode.Tab);
  io.key_map[imgui.Key.LeftArrow]   = i32(sdl.Scancode.Left);
  io.key_map[imgui.Key.RightArrow]  = i32(sdl.Scancode.Right);
  io.key_map[imgui.Key.UpArrow]     = i32(sdl.Scancode.Up);
  io.key_map[imgui.Key.DownArrow]   = i32(sdl.Scancode.Down);
  io.key_map[imgui.Key.PageUp]      = i32(sdl.Scancode.Page_Up);
  io.key_map[imgui.Key.PageDown]    = i32(sdl.Scancode.Page_Down);
  io.key_map[imgui.Key.Home]        = i32(sdl.Scancode.Home);
  io.key_map[imgui.Key.End]         = i32(sdl.Scancode.End);
  //io.key_map[imgui.Key.Insert]      = i32(sdl.Scancode.Insert);
  io.key_map[imgui.Key.Delete]      = i32(sdl.Scancode.Delete);
  io.key_map[imgui.Key.Backspace]   = i32(sdl.Scancode.Backspace);
  //io.key_map[imgui.Key.Space]       = i32(sdl.Scancode.Space);
  io.key_map[imgui.Key.Escape]      = i32(sdl.Scancode.Escape);
  //io.key_map[imgui.Key.KeyPadEnter] = i32(sdl.Scancode.Kp_Enter);
  io.key_map[imgui.Key.A]           = i32(sdl.Scancode.A);
  io.key_map[imgui.Key.C]           = i32(sdl.Scancode.C);
  io.key_map[imgui.Key.V]           = i32(sdl.Scancode.V);
  io.key_map[imgui.Key.X]           = i32(sdl.Scancode.X);
  io.key_map[imgui.Key.Y]           = i32(sdl.Scancode.Y);
  io.key_map[imgui.Key.Z]           = i32(sdl.Scancode.Z);

  /*
  // @Incomplete(naum): IME configuration
  wm_info : sdl.Sys_WM_Info;
  sdl.get_version(&wm_info);
  sdl.get_window_wm_info(window, &wm_info);
  io.ime_window_handle = wm_info.info.win.window;
  */

  // @Incomplete(naum): imgui clipboard
  // @Incomplete(naum): imgui mouse cursor

  // OpenGL program

  vs ::
    `#version 330
    uniform mat4 ProjMtx;
    in vec2 Position;
    in vec2 UV;
    in vec4 Color;
    out vec2 Frag_UV;
    out vec4 Frag_Color;
    void main()
    {
      Frag_UV = UV;
      Frag_Color = Color;
      gl_Position = ProjMtx * vec4(Position.xy,0,1);
    }`;

  fs ::
    `#version 330
    uniform sampler2D Texture;
    in vec2 Frag_UV;
    in vec4 Frag_Color;
    out vec4 Out_Color;
    void main()
    {
      Out_Color = Frag_Color * texture( Texture, Frag_UV.st);
    }`;

  ok : bool;
  debug_program, ok = gl.load_shaders_source(vs, fs);
  assert(ok);

  debug_uniform_texture    = gl.GetUniformLocation(debug_program, cast(^u8)util.create_cstring("Texture"));
  debug_uniform_projection = gl.GetUniformLocation(debug_program, cast(^u8)util.create_cstring("ProjMtx"));

  debug_attrib_position = gl.GetAttribLocation(debug_program, cast(^u8)util.create_cstring("Position"));
  debug_attrib_uv       = gl.GetAttribLocation(debug_program, cast(^u8)util.create_cstring("UV"));
  debug_attrib_color    = gl.GetAttribLocation(debug_program, cast(^u8)util.create_cstring("Color"));

  gl.GenBuffers(1, &debug_vbo);
  gl.GenBuffers(1, &debug_ebo);

  // font loading
  pixels : ^u8;
  width, height : i32;
  imgui.font_atlas_get_text_data_as_rgba32(io.fonts, &pixels, &width, &height);

  gl.GenTextures(1, &debug_font_texture);
  gl.BindTexture(gl.TEXTURE_2D, debug_font_texture);
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
  //gl.PixelStorei(gl.UNPACK_ROW_LENGTH, 0);
  gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, pixels);

  imgui.font_atlas_set_text_id(io.fonts, rawptr(uintptr(uint(debug_font_texture))));

  // @Incomplete(naum): add imgui style

  debug_sdl_frequency = sdl.get_performance_frequency();
  io.ini_filename = nil;
}

cleanup_debug :: proc() {
  io := imgui.get_io();

  gl.DeleteTextures(1, &debug_font_texture);
  imgui.font_atlas_set_text_id(io.fonts, rawptr(uintptr(0)));

  gl.DeleteBuffers(1, &debug_vbo);
  gl.DeleteBuffers(1, &debug_ebo);
  gl.DeleteProgram(debug_program);

  //imgui.destroy_context();
}

_new_frame :: proc(render_system: ^Render_System, window: ^Window) {
  io := imgui.get_io();

  width, height : i32;
  display_w, display_h : i32;
  sdl.get_window_size(window.sdl_window, &width, &height);
  sdl.gl_get_drawable_size(window.sdl_window, &display_w, &display_h);
  io.display_size = imgui.Vec2 { f32(width), f32(height) };

  if width > 0 && height > 0 {
    io.display_framebuffer_scale = imgui.Vec2 {
      f32(display_w) / f32(width),
      f32(display_h) / f32(height)
    };
  }

  // @Refactor(naum): use game time
  current_time := sdl.get_performance_counter();
  io.delta_time = debug_time > 0 ? f32(current_time - debug_time) / f32(debug_sdl_frequency) : 1.0 / 60;
  //io.delta_time = 1.0 / 60;
  debug_time = current_time;


  // update mouse position and buttons
  io.mouse_pos = imgui.Vec2{ -math.F32_MAX, -math.F32_MAX };

  mouse_x, mouse_y : i32;
  mouse_buttons := sdl.get_mouse_state(&mouse_x, &mouse_y);
  io.mouse_down[0] = debug_mouse_pressed[0] || (mouse_buttons & u32(sdl.Mousecode.Left)   != 0);
  io.mouse_down[1] = debug_mouse_pressed[1] || (mouse_buttons & u32(sdl.Mousecode.Right)  != 0);
  io.mouse_down[2] = debug_mouse_pressed[2] || (mouse_buttons & u32(sdl.Mousecode.Middle) != 0);
  debug_mouse_pressed = { false, false, false };

  if sdl.get_mouse_focus() == debug_sdl_window {
    io.mouse_pos = imgui.Vec2 { f32(mouse_x), f32(mouse_y) };
  }

  imgui.new_frame();
}

// @Discuss(naum): register debug windows vs new frame before updates/render in end
render_debug :: proc(render_system: ^Render_System, window: ^Window) {
  io := imgui.get_io();
  _new_frame(render_system, window);

  imgui.begin("Debug");
  //imgui.text(fmt.tprint("Application average ", 1000.0 / io.framerate, " ms/frame (", io.framerate, " FPS)"));
  imgui.text("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / io.framerate, io.framerate);
  imgui.end();

  imgui.render();

  // OpenGL draw data
  width := i32(io.display_size.x * io.display_framebuffer_scale.x);
  height := i32(io.display_size.y * io.display_framebuffer_scale.y);
  if width == 0 || height == 0 do return;

  data := imgui.get_draw_data();

  last_viewport : [4]i32; gl.GetIntegerv(gl.VIEWPORT, &last_viewport[0]);
  last_scissor  : [4]i32; gl.GetIntegerv(gl.SCISSOR_BOX, &last_scissor[0]);

  last_enable_blend    := gl.IsEnabled(gl.BLEND);
  last_enable_cull     := gl.IsEnabled(gl.CULL_FACE);
  last_enable_depth    := gl.IsEnabled(gl.DEPTH_TEST);
  last_enable_scissor  := gl.IsEnabled(gl.SCISSOR_TEST);

  gl.Enable(gl.BLEND);
  gl.BlendEquation(gl.FUNC_ADD);
  gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
  gl.Disable(gl.CULL_FACE);
  gl.Disable(gl.DEPTH_TEST);
  gl.Enable(gl.SCISSOR_TEST);
  gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL);

  gl.Viewport(0, 0, width, height);

  l := data.display_pos.x;
  r := data.display_pos.x + data.display_size.x;
  t := data.display_pos.y;
  b := data.display_pos.y + data.display_size.y;
  ortho_projection := linalg.matrix_ortho3d(l, r, b, t, -1, 1, false);

  //last_program := render_system.current_program;
  gl.UseProgram(debug_program);
  gl.Uniform1i(debug_uniform_texture, 0);
  gl.UniformMatrix4fv(debug_uniform_projection, 1, gl.FALSE, &ortho_projection[0][0]);

  vertex_array_object : u32;
  gl.GenVertexArrays(1, &vertex_array_object);
  gl.BindVertexArray(vertex_array_object);

  gl.BindBuffer(gl.ARRAY_BUFFER, debug_vbo);
  gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, debug_ebo);
  gl.EnableVertexAttribArray(u32(debug_attrib_position)); // @Refactor(naum): Location should be u32, not i32
  gl.EnableVertexAttribArray(u32(debug_attrib_uv));
  gl.EnableVertexAttribArray(u32(debug_attrib_color));
  gl.VertexAttribPointer(u32(debug_attrib_position), 2, gl.FLOAT,         gl.FALSE, size_of(imgui.DrawVert), cast(rawptr)offset_of(imgui.DrawVert, pos));
  gl.VertexAttribPointer(u32(debug_attrib_uv),       2, gl.FLOAT,         gl.FALSE, size_of(imgui.DrawVert), cast(rawptr)offset_of(imgui.DrawVert, uv));
  gl.VertexAttribPointer(u32(debug_attrib_color),    2, gl.UNSIGNED_BYTE, gl.TRUE,  size_of(imgui.DrawVert), cast(rawptr)offset_of(imgui.DrawVert, col));

  new_list := mem.slice_ptr(data.cmd_lists, int(data.cmd_lists_count));
  for cmd_list in new_list {
    idx_buffer_offset : ^imgui.DrawIdx = nil;

    gl.BufferData(
      gl.ARRAY_BUFFER,
      cast(int)(cmd_list.vtx_buffer.size * size_of(imgui.DrawVert)),
      rawptr(cmd_list.vtx_buffer.data),
      gl.STREAM_DRAW
    );

    gl.BufferData(
      gl.ELEMENT_ARRAY_BUFFER,
      cast(int)(cmd_list.idx_buffer.size * size_of(imgui.DrawIdx)),
      rawptr(cmd_list.idx_buffer.data),
      gl.STREAM_DRAW
    );

    for j : i32 = 0; j < cmd_list.cmd_buffer.size; j += 1 {
      cmd := mem.ptr_offset(cmd_list.cmd_buffer.data, int(j));
      gl.BindTexture(gl.TEXTURE_2D, u32(uintptr(cmd.texture_id)));
      gl.Scissor(
        i32(cmd.clip_rect.x), height - i32(cmd.clip_rect.w),
        i32(cmd.clip_rect.z - cmd.clip_rect.x), i32(cmd.clip_rect.w - cmd.clip_rect.y)
      );
      gl.DrawElements(gl.TRIANGLES, i32(cmd.elem_count), gl.UNSIGNED_SHORT, idx_buffer_offset);
      idx_buffer_offset = mem.ptr_offset(idx_buffer_offset, int(cmd.elem_count));
    }
  }

  gl.DeleteVertexArrays(1, &vertex_array_object);

  if last_enable_blend   != 0 { gl.Enable(gl.BLEND);        } else { gl.Disable(gl.BLEND);        }
  if last_enable_cull    != 0 { gl.Enable(gl.CULL_FACE);    } else { gl.Disable(gl.CULL_FACE);    }
  if last_enable_depth   != 0 { gl.Enable(gl.DEPTH_TEST);   } else { gl.Disable(gl.DEPTH_TEST);   }
  if last_enable_scissor != 0 { gl.Enable(gl.SCISSOR_TEST); } else { gl.Disable(gl.SCISSOR_TEST); }

  gl.Viewport(last_viewport[0], last_viewport[1], last_viewport[2], last_viewport[3]);
  gl.Scissor (last_scissor[0],  last_scissor[1],  last_scissor[2],  last_scissor[3]);
}

handle_debug_input :: proc(event: ^sdl.Event) -> bool {
  io := imgui.get_io();

  #partial switch event.type {
    case sdl.Event_Type.Mouse_Wheel:
      //if event.wheel.x > 0 do io.mouse_wheel_h += 1;
      //if event.wheel.x < 0 do io.mouse_wheel_h -= 1;
      if event.wheel.y > 0 do io.mouse_wheel   += 1;
      if event.wheel.y < 0 do io.mouse_wheel   -= 1;
      return true;

    case sdl.Event_Type.Mouse_Button_Down:
      if event.button.button == u8(sdl.Mousecode.Left)   do debug_mouse_pressed[0] = true;
      if event.button.button == u8(sdl.Mousecode.Right)  do debug_mouse_pressed[1] = true;
      if event.button.button == u8(sdl.Mousecode.Middle) do debug_mouse_pressed[2] = true;
      return true;
  }

  return false;
}
