package anka

import "core:mem"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:strings"
import rt "core:runtime"

import "external/sdl"
import "external/gl"
import "external/imgui"

import "util"

// @Refactor(naum): add debug info to struct
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

  io.ini_filename = nil;


  // @Incomplete(naum): fix this (copy paste) BREW STYLE
  style := imgui.get_style();
  style.window_rounding = 0;
  style.child_rounding = 0;
  style.frame_rounding = 0;
  style.indent_spacing = 20;
  /*
  style.window_padding = imgui.Vec2{6, 6};
  style.frame_padding = imgui.Vec2{4 ,2};
  style.item_spacing = imgui.Vec2{8, 4};
  style.item_inner_spacing = imgui.Vec2{4, 4};
  style.touch_extra_padding = imgui.Vec2{0, 0};
  style.scrollbar_size = 12;
  style.scrollbar_rounding = 9;
  style.grab_min_size = 9;
  style.grab_rounding = 1;

  style.window_title_align = imgui.Vec2{0.48, 0.5};
  style.button_text_align = imgui.Vec2{0.5, 0.5};
  */

  style.colors[imgui.Style_Color.Text]                  = imgui.Vec4{1.00, 1.00, 1.00, 1.00};
  style.colors[imgui.Style_Color.TextDisabled]          = imgui.Vec4{0.63, 0.63, 0.63, 1.00};
  style.colors[imgui.Style_Color.WindowBg]              = imgui.Vec4{0.23, 0.23, 0.23, 0.98};
  style.colors[imgui.Style_Color.ChildBg]               = imgui.Vec4{0.20, 0.20, 0.20, 1.00};
  style.colors[imgui.Style_Color.PopupBg]               = imgui.Vec4{0.25, 0.25, 0.25, 0.96};
  style.colors[imgui.Style_Color.Border]                = imgui.Vec4{0.18, 0.18, 0.18, 0.98};
  style.colors[imgui.Style_Color.BorderShadow]          = imgui.Vec4{0.00, 0.00, 0.00, 0.04};
  style.colors[imgui.Style_Color.FrameBg]               = imgui.Vec4{0.00, 0.00, 0.00, 0.29};
  style.colors[imgui.Style_Color.TitleBg]               = imgui.Vec4{0.25, 0.25, 0.25, 0.98};
  style.colors[imgui.Style_Color.TitleBgCollapsed]      = imgui.Vec4{0.12, 0.12, 0.12, 0.49};
  style.colors[imgui.Style_Color.TitleBgActive]         = imgui.Vec4{0.33, 0.33, 0.33, 0.98};
  style.colors[imgui.Style_Color.MenuBarBg]             = imgui.Vec4{0.11, 0.11, 0.11, 0.42};
  style.colors[imgui.Style_Color.ScrollbarBg]           = imgui.Vec4{0.00, 0.00, 0.00, 0.08};
  style.colors[imgui.Style_Color.ScrollbarGrab]         = imgui.Vec4{0.27, 0.27, 0.27, 1.00};
  style.colors[imgui.Style_Color.ScrollbarGrabHovered]  = imgui.Vec4{0.78, 0.78, 0.78, 0.40};
  style.colors[imgui.Style_Color.CheckMark]             = imgui.Vec4{0.78, 0.78, 0.78, 0.94};
  style.colors[imgui.Style_Color.SliderGrab]            = imgui.Vec4{0.78, 0.78, 0.78, 0.94};
  style.colors[imgui.Style_Color.Button]                = imgui.Vec4{0.42, 0.42, 0.42, 0.60};
  style.colors[imgui.Style_Color.ButtonHovered]         = imgui.Vec4{0.78, 0.78, 0.78, 0.40};
  style.colors[imgui.Style_Color.Header]                = imgui.Vec4{0.31, 0.31, 0.31, 0.98};
  style.colors[imgui.Style_Color.HeaderHovered]         = imgui.Vec4{0.78, 0.78, 0.78, 0.40};
  style.colors[imgui.Style_Color.HeaderActive]          = imgui.Vec4{0.80, 0.50, 0.50, 1.00};
  style.colors[imgui.Style_Color.TextSelectedBg]        = imgui.Vec4{0.65, 0.35, 0.35, 0.26};
  // style.colors[imgui.Style_Color.ModalWindowDimBg]      = imgui.Vec4{0.20, 0.20, 0.20, 0.35};
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
  frequency := sdl.get_performance_frequency();
  current_time := sdl.get_performance_counter();
  io.delta_time = debug_time > 0 ? f32(current_time - debug_time) / f32(frequency) : 1.0 / 60;
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

  imgui.begin("Debug", nil, imgui.Window_Flags.AlwaysAutoResize);

  //imgui.text(fmt.tprint("Application average ", 1000.0 / io.framerate, " ms/frame (", io.framerate, " FPS)"));
  imgui.text("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / io.framerate, io.framerate);

  if imgui.tree_node("Style") {
    style := imgui.get_style();
    /*
    style.window_padding = imgui.Vec2{6, 6};
    style.frame_padding = imgui.Vec2{4 ,2};
    style.item_spacing = imgui.Vec2{8, 4};
    style.item_inner_spacing = imgui.Vec2{4, 4};
    style.touch_extra_padding = imgui.Vec2{0, 0};
    style.scrollbar_size = 12;
    style.scrollbar_rounding = 9;
    style.grab_min_size = 9;
    style.grab_rounding = 1;
    */

    imgui.drag_float("window_rounding", &style.window_rounding, 0.10, 0.0, 20.0);
    imgui.drag_float("child_rounding", &style.child_rounding, 0.10, 0.0, 20.0);
    imgui.drag_float("frame_rounding", &style.frame_rounding, 0.10, 0.0, 20.0);
    imgui.drag_float("indent_spacing", &style.indent_spacing, 0.10, 0.0, 50.0);

    imgui.tree_pop();
  }

  imgui.end();

  _render();
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

_render :: proc() {
  io := imgui.get_io();
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
  gl.VertexAttribPointer(u32(debug_attrib_color),    4, gl.UNSIGNED_BYTE, gl.TRUE,  size_of(imgui.DrawVert), cast(rawptr)offset_of(imgui.DrawVert, col));

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

/*
imgui_struct_window :: proc(value: ^$T, window_name := "") {
  imgui.push_font(imgui_font_mono);
  defer imgui.pop_font();

  imgui.begin(window_name == "" ? tprint(type_info_of(T)) : window_name);
  defer imgui.end();

  imgui_struct_ti("", value, type_info_of(T));
}

imgui_struct :: proc(value: ^$T, name: string, do_header := true) {
  imgui.push_font(imgui_font_mono);
  defer imgui.pop_font();

  imgui_struct_ti(name, value, type_info_of(T), "", do_header);
}
*/

_imgui_struct_block_field_start :: proc(name: string, typename: string) -> bool {
  // if name != "" {
    header: string;
    if name != "" {
      header = fmt.tprint(name, ": ", typename);
    }
    else {
      header = fmt.tprint(typename);
    }
    if imgui.collapsing_header(header) {
      imgui.indent();
      return true;
    }
    return false;
    // }
    // return true;
}

_imgui_struct_block_field_end :: proc(name: string) {
  // if name != "" {
    imgui.unindent();
    // }
}

_readonly: bool;
imgui_struct_ti :: proc(name: string, data: rawptr, ti: ^rt.Type_Info, tags: string = "", do_header := true, type_name: string = "") {
  imgui.push_id(name);
  defer imgui.pop_id();

  do_header := do_header;
  if strings.contains(tags, "imgui_noheader") {
    do_header = false;
  }

  if strings.contains(tags, "imgui_readonly") {
    imgui.label_text(name, fmt.tprint(any{data, ti.id}));
    return;
  }

  if strings.contains(tags, "imgui_hidden") {
    return;
  }

  has_range_constraint: bool;
  range_min: f32;
  range_max: f32;
  /*
  if strings.contains(tags, "imgui_range") {
    has_range_constraint = true;
    range_idx := strings.index(tags, "imgui_range");
    assert(range_idx >= 0);
    range_str := tags[range_idx:];
    range_lexer := laas.make_lexer(range_str);
    laas.get_next_token(&range_lexer, nil);
    laas.expect_symbol(&range_lexer, "=");
    range_min_str := laas.expect_string(&range_lexer);
    laas.expect_symbol(&range_lexer, ":");
    range_max_str := laas.expect_string(&range_lexer);

    range_min = strconv.parse_f32(range_min_str);
    range_max = strconv.parse_f32(range_max_str);
  }
  */

  #partial
  switch kind in &ti.variant {
    case rt.Type_Info_Integer: {
      allow_64_bit := strings.contains(tags, "imgui_allow64bit");
      if kind.signed {
        switch ti.size {
          case 8: {
            if allow_64_bit { new_data := cast(i32)(cast(^i64)data)^; imgui.input_int(name, &new_data); (cast(^i64)data)^ = cast(i64)new_data; }
            else            { imgui.label_text(name, fmt.tprint((cast(^i64)data)^), "// todo(josh): allow editing 64-bit values"); }
          }
          case 4: new_data := cast(i32)(cast(^i32)data)^; imgui.input_int(name, &new_data); (cast(^i32)data)^ = cast(i32)new_data;
          case 2: new_data := cast(i32)(cast(^i16)data)^; imgui.input_int(name, &new_data); (cast(^i16)data)^ = cast(i16)new_data;
          case 1: new_data := cast(i32)(cast(^i8 )data)^; imgui.input_int(name, &new_data); (cast(^i8 )data)^ = cast(i8 )new_data;
          case: assert(false, fmt.tprint(ti.size));
        }
      }
      else {
        switch ti.size {
          case 8: imgui.label_text(name, fmt.tprint((cast(^u64)data)^), "// todo(josh): allow editing 64-bit values"); // new_data := cast(i32)(cast(^u64)data)^; imgui.input_int(name, &new_data); (cast(^u64)data)^ = cast(u64)new_data;
          case 4: new_data := cast(i32)(cast(^u32)data)^; imgui.input_int(name, &new_data); (cast(^u32)data)^ = cast(u32)new_data;
          case 2: new_data := cast(i32)(cast(^u16)data)^; imgui.input_int(name, &new_data); (cast(^u16)data)^ = cast(u16)new_data;
          case 1: new_data := cast(i32)(cast(^u8 )data)^; imgui.input_int(name, &new_data); (cast(^u8 )data)^ = cast(u8 )new_data;
          case: assert(false, fmt.tprint(ti.size));
        }
      }
    }
    case rt.Type_Info_Float: {
      allow_64_bit := strings.contains(tags, "imgui_allow64bit");
      switch ti.size {
        case 8: {
          imgui.label_text(name, fmt.tprint((cast(^f32)data)^), "// todo(josh): allow editing 64-bit values");
          // new_data := cast(f32)(cast(^f64)data)^;
          // imgui.push_item_width(100);
          // imgui.input_float(fmt.tprint(name, "##non_range"), &new_data);
          // imgui.pop_item_width();
          // if has_range_constraint {
            //     imgui.same_line();
            //     imgui.push_item_width(200);
            //     imgui.slider_float(name, &new_data, range_min, range_max);
            //     imgui.pop_item_width();
            // }
            // (cast(^f64)data)^ = cast(f64)new_data;
          }
          case 4: {
            new_data := cast(f32)(cast(^f32)data)^;
            imgui.push_item_width(100);
            imgui.input_float(fmt.tprint(name, "##non_range"), &new_data);
            imgui.pop_item_width();
            if has_range_constraint {
              imgui.same_line();
              imgui.push_item_width(200);
              imgui.slider_float(name, &new_data, range_min, range_max);
              imgui.pop_item_width();
            }
            (cast(^f32)data)^ = cast(f32)new_data;
          }
          case: assert(false, fmt.tprint(ti.size));
        }
      }
      case rt.Type_Info_String: {
        assert(ti.size == size_of(string));
        // todo(josh): arbitrary string length, right now there is a max length
        // https://github.com/ocornut/imgui/issues/1008
        text_edit_buffer: [256]u8;
        fmt.bprint(text_edit_buffer[:], (cast(^string)data)^);

        if imgui.input_text(name, text_edit_buffer[:], .EnterReturnsTrue) {
          result := text_edit_buffer[:];
          for b, i in text_edit_buffer {
            if b == '\x00' {
              result = text_edit_buffer[:i];
              break;
            }
          }
          str := strings.clone(cast(string)result);
          (cast(^string)data)^ = str; // @Leak
        }
      }
      case rt.Type_Info_Boolean: {
        assert(ti.size == size_of(bool));
        imgui.checkbox(name, cast(^bool)data);
      }
      case rt.Type_Info_Pointer: {
        ptr := (cast(^rawptr)data)^;
        if ptr == nil {
          imgui.text(fmt.tprint(name, " = nil"));
        }
        else {
          if kind.elem == nil {
            // kind.elem being nil means it's a rawptr
            imgui.text(fmt.tprint("rawptr ", name, " = ", "\"", ptr, "\""));
          }
          else {
            imgui_struct_ti(name, ptr, kind.elem);
          }
        }
      }
      case rt.Type_Info_Named: {
        imgui_struct_ti(name, data, kind.base, "", do_header, kind.name);
      }
      case rt.Type_Info_Struct: {
        if !do_header || _imgui_struct_block_field_start(name, type_name) {
          defer if do_header do _imgui_struct_block_field_end(name);

          for field_name, i in kind.names {
            t := kind.types[i];
            offset := kind.offsets[i];
            is_using := kind.usings[i];
            data := mem.ptr_offset(cast(^byte)data, cast(int)offset);
            tag := kind.tags[i];
            imgui_struct_ti(field_name, data, t, tag, !is_using);
          }
        }
      }
      case rt.Type_Info_Enum: {
        if len(kind.values) > 0 {
          current_item_index : i32 = -1;
          switch _ in kind.values[0] {
            case u8:        for v, idx in kind.values { if (cast(^u8     )data)^ == v.(u8)      { current_item_index = cast(i32)idx; break; } }
            case u16:       for v, idx in kind.values { if (cast(^u16    )data)^ == v.(u16)     { current_item_index = cast(i32)idx; break; } }
            case u32:       for v, idx in kind.values { if (cast(^u32    )data)^ == v.(u32)     { current_item_index = cast(i32)idx; break; } }
            case u64:       for v, idx in kind.values { if (cast(^u64    )data)^ == v.(u64)     { current_item_index = cast(i32)idx; break; } }
            case uint:      for v, idx in kind.values { if (cast(^uint   )data)^ == v.(uint)    { current_item_index = cast(i32)idx; break; } }
            case i8:        for v, idx in kind.values { if (cast(^i8     )data)^ == v.(i8)      { current_item_index = cast(i32)idx; break; } }
            case i16:       for v, idx in kind.values { if (cast(^i16    )data)^ == v.(i16)     { current_item_index = cast(i32)idx; break; } }
            case i32:       for v, idx in kind.values { if (cast(^i32    )data)^ == v.(i32)     { current_item_index = cast(i32)idx; break; } }
            case i64:       for v, idx in kind.values { if (cast(^i64    )data)^ == v.(i64)     { current_item_index = cast(i32)idx; break; } }
            case int:       for v, idx in kind.values { if (cast(^int    )data)^ == v.(int)     { current_item_index = cast(i32)idx; break; } }
            case rune:      for v, idx in kind.values { if (cast(^rune   )data)^ == v.(rune)    { current_item_index = cast(i32)idx; break; } }
            case uintptr:   for v, idx in kind.values { if (cast(^uintptr)data)^ == v.(uintptr) { current_item_index = cast(i32)idx; break; } }
            case: panic(fmt.tprint(kind.values[0]));
          }

          item := current_item_index;
          imgui.combo(name, &item, kind.names, cast(i32)min(5, len(kind.names)));
          if item != current_item_index {
            switch value in kind.values[item] {
              case u8:        (cast(^u8     )data)^ = value;
              case u16:       (cast(^u16    )data)^ = value;
              case u32:       (cast(^u32    )data)^ = value;
              case u64:       (cast(^u64    )data)^ = value;
              case uint:      (cast(^uint   )data)^ = value;
              case i8:        (cast(^i8     )data)^ = value;
              case i16:       (cast(^i16    )data)^ = value;
              case i32:       (cast(^i32    )data)^ = value;
              case i64:       (cast(^i64    )data)^ = value;
              case int:       (cast(^int    )data)^ = value;
              case rune:      (cast(^rune   )data)^ = value;
              case uintptr:   (cast(^uintptr)data)^ = value;
              case: panic(fmt.tprint(value));
            }
          }
        }
      }
      case rt.Type_Info_Slice: {
        if !do_header || _imgui_struct_block_field_start(name, fmt.tprint("[]", kind.elem)) {
          defer if do_header do _imgui_struct_block_field_end(name);

          slice := (cast(^mem.Raw_Slice)data)^;
          for i in 0..slice.len-1 {
            imgui.push_id(fmt.tprint(i));
            defer imgui.pop_id();
            imgui_struct_ti(fmt.tprint("[", i, "]"), mem.ptr_offset(cast(^byte)slice.data, i * kind.elem_size), kind.elem);
          }
        }
      }
      case rt.Type_Info_Array: {
        if !do_header || _imgui_struct_block_field_start(name, fmt.tprint("[", kind.count, "]", kind.elem)) {
          defer if do_header do _imgui_struct_block_field_end(name);

          for i in 0..kind.count-1 {
            imgui.push_id(fmt.tprint(i));
            defer imgui.pop_id();
            imgui_struct_ti(fmt.tprint("[", i, "]"), mem.ptr_offset(cast(^byte)data, i * kind.elem_size), kind.elem);
          }
        }
      }
      case rt.Type_Info_Dynamic_Array: {
        if !do_header || _imgui_struct_block_field_start(name, fmt.tprint("[dynamic]", kind.elem)) {
          defer if do_header do _imgui_struct_block_field_end(name);

          array := (cast(^mem.Raw_Dynamic_Array)data)^;
          for i in 0..array.len-1 {
            imgui.push_id(fmt.tprint(i));
            defer imgui.pop_id();
            imgui_struct_ti(fmt.tprint("[", i, "]"), mem.ptr_offset(cast(^byte)array.data, i * kind.elem_size), kind.elem);
          }
        }
      }
      case rt.Type_Info_Any: {
        a := cast(^any)data;
        if a.data == nil do return;
        imgui_struct_ti(name, a.data, type_info_of(a.id));
      }
      case rt.Type_Info_Union: {
        tag_ptr := uintptr(data) + kind.tag_offset;
        tag_any := any{rawptr(tag_ptr), kind.tag_type.id};

        current_tag: i32 = -1;
        switch i in tag_any {
          case u8:   current_tag = i32(i);
          case u16:  current_tag = i32(i);
          case u32:  current_tag = i32(i);
          case u64:  current_tag = i32(i);
          case i8:   current_tag = i32(i);
          case i16:  current_tag = i32(i);
          case i32:  current_tag = i32(i);
          case i64:  current_tag = i32(i);
          case: panic(fmt.tprint("Invalid union tag type: ", i));
        }

        item := cast(i32)current_tag;
        v := kind.variants;
        variant_names: [dynamic]string;
        append(&variant_names, "<none>");
        for v in kind.variants {
          append(&variant_names, fmt.tprint(v));
        }
        imgui.combo("tag", &item, variant_names[:], cast(i32)min(5, len(variant_names)));

        if item != current_tag {
          current_tag = item;
          // todo(josh): is zeroing a good idea here?
          mem.zero(data, ti.size);
          switch i in tag_any {
            case u8:   (cast(^u8 )tag_ptr)^ = u8 (item);
            case u16:  (cast(^u16)tag_ptr)^ = u16(item);
            case u32:  (cast(^u32)tag_ptr)^ = u32(item);
            case u64:  (cast(^u64)tag_ptr)^ = u64(item);
            case i8:   (cast(^i8 )tag_ptr)^ = i8 (item);
            case i16:  (cast(^i16)tag_ptr)^ = i16(item);
            case i32:  (cast(^i32)tag_ptr)^ = i32(item);
            case i64:  (cast(^i64)tag_ptr)^ = i64(item);
            case: panic(fmt.tprint("Invalid union tag type: ", i));
          }
        }

        if current_tag > 0 {
          data_ti := kind.variants[current_tag-1];
          imgui_struct_ti(name, data, data_ti, "", true, type_name);
        }
      }
      case rt.Type_Info_Type_Id: {
        ptr := cast(^typeid)data;
        ti := type_info_of(ptr^);
        imgui.text(fmt.tprint(ti));
      }
      case: imgui.text(fmt.tprint("UNHANDLED TYPE: ", kind));
    }
  }
