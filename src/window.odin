package anka

import "core:fmt"

import "external/sdl"
import "external/gl"

import "util"

Window :: struct {
  sdl_window : ^sdl.Window,
  gl_context : sdl.GL_Context,
  width      : u32,
  height     : u32,
}

create_window :: proc(name: string, w: u32, h: u32) -> Window {
  window : Window;

  sdl.gl_set_attribute(sdl.GL_Attr.Context_Flags, 0);
  sdl.gl_set_attribute(sdl.GL_Attr.Context_Profile_Mask, cast(i32)sdl.GL_Context_Profile.Core);

  sdl.gl_set_attribute(sdl.GL_Attr.Context_Major_Version, 3);
  sdl.gl_set_attribute(sdl.GL_Attr.Context_Minor_Version, 2);

  sdl.gl_set_attribute(sdl.GL_Attr.Doublebuffer, 1);
  sdl.gl_set_attribute(sdl.GL_Attr.Depth_Size, 24);
  //sdl.gl_set_attribute(sdl.GL_Attr.Stencil_Size, 8);

  // @Incomplete(naum): get window name in params
  cstr_name := util.create_cstring(name);
  window.sdl_window = sdl.create_window(
    cstr_name,
    cast(i32)sdl.Window_Pos.Undefined, cast(i32)sdl.Window_Pos.Undefined,
    cast(i32)w, cast(i32)h,
    sdl.Window_Flags.Open_GL
  );

  if (window.sdl_window == nil) {
    // @Incomplete(naum): add logging
    fmt.println("Could not create window. SDL_Error: ", sdl.get_error());
    return window;
  }

  window.width  = w;
  window.height = h;

  window.gl_context = sdl.gl_create_context(window.sdl_window);

  // @Refactor(naum): move this to some place we have more control
  sdl.gl_make_current(window.sdl_window, window.gl_context);

  // @Refactor(naum): move this to some place we have more control
  // vsync
  sdl.gl_set_swap_interval(1);

  //gl.load_up_to(3, 2, proc(p: rawptr, name: cstring) do (cast(^rawptr)p)^ = sdl.gl_get_proc_address(name); );
  _init_opengl(3, 2);

  return window;
}

destroy_window :: proc(using window: ^Window) {
  sdl.gl_delete_context(gl_context);
  sdl.destroy_window(sdl_window);
}

_init_opengl :: proc(version_major, version_minor: int) {
  gl.load_up_to(
    version_major,
    version_minor,
    proc(p: rawptr, name: cstring) do (cast(^rawptr)p)^ = sdl.gl_get_proc_address(name);
  );
}

