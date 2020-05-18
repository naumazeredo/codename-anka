/*
*  @Name:     imgui_types
*  
*  @Author:   Mikkel Hjortshoej
*  @Email:    fyoucon@gmail.com
*  @Creation: 02-09-2018 15:59:43 UTC+1
*
*  @Last By:   Mikkel Hjortshoej
*  @Last Time: 06-10-2018 14:13:07 UTC+1
*  
*  @Description:
*  
*/

package imgui

import "core:mem";

////////////////////////////
// Types
ID        :: distinct u32;
Draw_Idx   :: distinct u16; 
Wchar     :: distinct u16; 
Texture_ID :: distinct rawptr; 

///////////////////////////
// DUMMY STRUCTS
Context            :: struct {}
Draw_List_Shared_Data :: struct {}

///////////////////////////
// Actual structs
Vec2 :: struct {
  x : f32,
  y : f32,
}

Vec4 :: struct {
  x : f32,
  y : f32,
  z : f32,
  w : f32,
}

ImNewDummy :: struct {}

ImVector :: struct(T : typeid) {
  size     : i32,
  capacity : i32,
  data     : ^T,
}


Style :: struct {
  alpha                     : f32 `min=0.1 max=1.0 speed=0.01`,
  window_padding            : Vec2,
  window_rounding           : f32,
  window_border_size        : f32,
  window_min_size           : Vec2,
  window_title_align        : Vec2,
  window_menu_button_position : Dir,
  child_rounding            : f32,
  child_border_size         : f32,
  popup_rounding            : f32,
  popup_border_size         : f32,
  frame_padding             : Vec2,
  frame_rounding            : f32,
  frame_border_size         : f32,
  item_spacing              : Vec2,
  item_inner_spacing        : Vec2,
  touch_extra_padding       : Vec2,
  indent_spacing            : f32,
  columns_min_spacing       : f32,
  scrollbar_size            : f32,
  scrollbar_rounding        : f32,
  grab_min_size             : f32,
  grab_rounding             : f32,
  tab_rounding              : f32,
  tab_border_size           : f32,
  color_button_position     : Dir,
  button_text_align         : Vec2,
  selectable_text_align     : Vec2,
  display_window_padding    : Vec2,
  display_safe_area_padding : Vec2,
  mouse_cursor_scale        : f32,
  anti_aliased_lines        : bool,
  anti_aliased_fill         : bool,
  curve_tessellation_tol    : f32,
  circle_segment_max_error  : f32,
  colors                    : [Style_Color.COUNT]Vec4, 
}

IO :: struct {
  config_flags                     : Config_Flags,
  backend_flags                    : Backend_Flags,
  display_size                     : Vec2,
  delta_time                       : f32,
  ini_saving_rate                  : f32,
  ini_filename                     : cstring,
  log_filename                     : cstring,
  mouse_double_click_time          : f32,
  mouse_double_click_max_dist      : f32,
  mouse_drag_threshold             : f32,
  key_map                          : [Key.COUNT]i32,
  key_repeat_delay                 : f32,
  key_repeat_rate                  : f32,
  user_data                        : rawptr,

  fonts                            : ^Font_Atlas,
  font_global_scale                : f32,
  font_allow_user_scaling          : bool,
  font_default                     : ^Font,
  display_framebuffer_scale        : Vec2,

  mouse_draw_cursor                : bool,
  config_mac_o_s_x_behaviors       : bool,
  config_input_text_cursor_blink   : bool,
  config_windows_resize_from_edges : bool,
  config_windows_move_from_title_bar_only : bool,
  config_windows_memory_compact_timer : f32,

  backend_platform_name            : cstring,
  backend_renderer_name            : cstring,
  backend_platform_user_data       : rawptr,
  backend_renderer_user_data       : rawptr,
  backend_language_user_data       : rawptr,

  get_clipboard_text_fn            : proc "c"(user_data : rawptr) -> cstring,
  set_clipboard_text_fn            : proc "c"(user_data : rawptr, text : cstring),
  clipboard_user_data              : rawptr,

  ime_set_input_screen_pos_fn      : proc "c"(x, y : i32),
  ime_window_handle                : rawptr,

  render_draw_lists_fn_unused      : rawptr,

  mouse_pos                        : Vec2,
  mouse_down                       : [5]bool,
  mouse_wheel                      : f32,
  mouse_wheel_h                    : f32,
  key_ctrl                         : bool,
  key_shift                        : bool,
  key_alt                          : bool,
  key_super                        : bool,
  keys_down                        : [512]bool,
  nav_inputs                       : [Nav_Input.COUNT]f32,

  want_capture_mouse               : bool,
  want_capture_keyboard            : bool,
  want_text_input                  : bool,
  want_set_mouse_pos               : bool,
  want_save_ini_settings           : bool,
  nav_active                       : bool,
  nav_visible                      : bool,
  framerate                        : f32,
  metrics_render_vertices          : i32,
  metrics_render_indices           : i32,
  metrics_render_windows           : i32,
  metrics_active_windows           : i32,
  metrics_active_allocations       : i32,
  mouse_delta                      : Vec2,

  key_mods                         : Key_Mod_Flags,
  mouse_pos_prev                   : Vec2,
  mouse_clicked_pos                : [5]Vec2,
  mouse_clicked_time               : [5]f64,
  mouse_clicked                    : [5]bool,
  mouse_double_clicked             : [5]bool,
  mouse_released                   : [5]bool,
  mouse_down_owned                 : [5]bool,
  mouse_down_was_double_click      : [5]bool,
  mouse_down_duration              : [5]f32,
  mouse_down_duration_prev         : [5]f32,
  mouse_drag_max_distance_abs      : [5]Vec2,
  mouse_drag_max_distance_sqr      : [5]f32,
  keys_down_duration               : [512]f32,
  keys_down_duration_prev          : [512]f32,
  nav_inputs_down_duration         : [Nav_Input.COUNT]f32,
  nav_inputs_down_duration_prev    : [Nav_Input.COUNT]f32,
  input_queue_characters           : [16+1]Wchar,
}

Input_Text_Callback_Data :: struct {
  event_flag      : Input_Text_Flags,
  flags           : Input_Text_Flags,
  user_data       : rawptr,

  event_char      : Wchar,
  event_key       : Key,
  buf             : ^byte,
  buf_text_len    : i32,
  buf_size        : i32,
  buf_dirty       : bool,
  cursor_pos      : i32,
  selection_start : i32,
  selection_end   : i32,
}

Size_Callback_Data :: struct {
  user_data    : rawptr,
  pos          : Vec2,
  current_size : Vec2,
  desired_size : Vec2,
}

Payload :: struct {
  data             : rawptr,
  data_size        : i32,

  source_id        : ID,
  source_parent_id : ID,
  data_frame_count : i32,
  data_type        : [32+1]byte,
  preview          : bool,
  delivery         : bool,
}


Once_Upon_AFrame :: struct {
  ref_frame : i32, // @XXX(naum): mutable int RefFrame;
}

Text_Filter :: struct {
  input_buf  : [256]byte,
  filters    : ImVector(Text_Range), //<TextRange>
  count_grep : i32,
}

Text_Range :: struct {
  b : cstring,
  e : cstring,
}


Text_Buffer :: struct {
  buf : ImVector(byte), // <char>
  // @XXX(naum): IMGUI_API static char EmptyString[1];
}

Storage :: struct {
  data : ImVector(Storage_Pair), // <Storage_Pair>
}

Storage_Pair :: struct {
  key : ID,
  using _: struct #raw_union { 
    val_i : i32,
    val_f : f32,
    val_p : rawptr,
  }
}

List_Clipper :: struct {
  display_start : i32,
  display_end   : i32,
  items_count   : i32,

  step_no       : i32,
  items_height  : f32,
  start_pos_y   : f32,
}

Color :: struct {
  value : Vec4,
}

Draw_Cmd :: struct {
  elem_count         : u32,
  clip_rect          : Vec4,
  texture_id         : Texture_ID,
  vtx_offset         : u32,
  idx_offset         : u32,
  user_callback      : draw_callback,
  user_callback_data : rawptr,
}

Draw_Vert :: struct {
  pos : Vec2,
  uv  : Vec2,
  col : u32,
}

Draw_Channel :: struct {
  cmd_buffer : ImVector(Draw_Cmd), // <ImDrawCmd>
  idx_buffer : ImVector(Draw_Idx), // <ImDrawIdx>
}

Draw_List_Splitter :: struct {
  _current  : i32,
  _count    : i32,
  _channels : ImVector(Draw_Channel), // <ImDrawChannel>
}

Draw_List :: struct {
  cmd_buffer        : ImVector(Draw_Cmd), // <ImDrawCmd>
  idx_buffer        : ImVector(Draw_Idx), // <ImDrawIdx>
  vtx_buffer        : ImVector(Draw_Vert), // <ImDrawVert>
  flags             : Draw_List_Flags,

  _data             : ^Draw_List_Shared_Data,
  _owner_name       : cstring,
  _vtx_current_offset : u32,
  _vtx_current_idx  : u32,
  _vtx_write_ptr    : ^Draw_Vert,
  _idx_write_ptr    : ^Draw_Idx,
  _clip_rect_stack  : ImVector(Vec4), // <ImVec4>
  _texture_id_stack : ImVector(Texture_ID), // <ImTextureID>
  _path             : ImVector(Vec2), // <ImVec2>
  _splitter         : Draw_List_Splitter,
}

Draw_Data :: struct {
  valid             : bool,
  cmd_lists         : ^^Draw_List,
  cmd_lists_count   : i32,
  total_idx_count   : i32,
  total_vtx_count   : i32,
  display_pos       : Vec2,
  display_size      : Vec2,
  framebuffer_scale : Vec2,
}

Font_Config :: struct {
  font_data                : rawptr,
  font_data_size           : i32,
  font_data_owned_by_atlas : bool,
  font_no                  : i32,
  size_pixels              : f32,
  oversample_h             : i32,
  oversample_v             : i32,
  pixel_snap_h             : bool,
  glyph_extra_spacing      : Vec2,
  glyph_offset             : Vec2,
  glyph_ranges             : ^Wchar,
  glyph_min_advance_x      : f32,
  glyph_max_advance_x      : f32,
  merge_mode               : bool,
  rasterizer_flags         : u32,
  rasterizer_multiply      : f32,
  ellipsis_char            : Wchar,

  name                     : [40]byte,
  dst_font                 : ^Font,
}

Font_Glyph :: struct {
  codepoint      : u32, // codepoint : 31, visible : 1
  advance_x      : f32,
  x0, y0, x1, y1 : f32,
  u0, v0, u1, v1 : f32
}

Glyph_Ranges_Builder :: struct{
  used_chars : ImVector(u32),
}

Font_Atlas_Custom_Rect :: struct {
  id              : u32,
  width, height   : u32,
  x, y            : u32,
  glyph_advance_x : f32,
  glyph_offset    : Vec2,
  font            : ^Font,
}

Font_Atlas :: struct {
  locked             : bool,
  flags              : Font_Atlas_Flags,
  tex_id             : Texture_ID,
  tex_desired_width  : i32,
  tex_glyph_padding  : i32,

  tex_pixels_alpha8  : ^byte,
  tex_pixels_rgba32  : ^u32,
  tex_width          : i32,
  tex_height         : i32,
  tex_uv_scale       : Vec2,
  tex_uv_white_pixel : Vec2,
  fonts              : ImVector(^Font),
  custom_rects       : ImVector(Font_Atlas_Custom_Rect),
  config_data        : ImVector(Font_Config),
  custom_rect_ids    : [1]i32,
}

Font :: struct {
  index_advance_x       : ImVector(f32),
  fallback_advance_x    : f32,
  font_size             : f32,

  index_lookup          : ImVector(u32),
  glyphs                : ImVector(Font_Glyph),
  fallback_glyph        : ^Font_Glyph,
  display_offset        : Vec2,

  container_atlas       : ^Font_Atlas,
  config_data           : ^Font_Config,
  config_data_count     : i16,
  fallback_char         : Wchar,
  ellipsis_char         : Wchar,
  dirty_lookup_tables   : bool,
  scale                 : f32,
  ascent                : f32,
  descent               : f32, // @XXX(naum): (script generation) treat this case: float Ascent, Descent;
  metrics_total_surface : int,
  used_4k_pages_map     : [(0x10FFFF+1)/4096/8]u8,
};

text_edit_callback       :: proc "c"(data : ^Input_Text_Callback_Data) -> i32;
size_constraint_callback :: proc "c"(data : ^Size_Callback_Data);
draw_callback            :: proc "c"(parent_list : ^Draw_List, cmd : ^Draw_Cmd);
