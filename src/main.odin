package anka

import "core:fmt"

import sdl "external/sdl2"
import gl  "external/gl"

window : Window;

init :: proc() {
  sdl.init(sdl.Init_Flags.Everything);
  window = create_window("Codename Anka", 640, 480);

  // @Refactor(naum): move this to game system
  init_render(&render_system);
}

cleanup :: proc() {
  cleanup_render(&render_system);

  sdl.quit();
}

handle_input :: proc() -> bool {
  e: sdl.Event;
  for sdl.poll_event(&e) != 0 {
    if e.type == sdl.Event_Type.Quit {
      return false;
    }

    if e.type == sdl.Event_Type.Key_Down {
      switch (e.key.keysym.sym) {
        case sdl.SDLK_ESCAPE:
        return false;
      }
    }
  }

  return true;
}

main :: proc() {
  init();
  defer cleanup();

  init_render(&render_system);

  tex, ok := load_image(&render_system, "./assets/gfx/template-32x32.png");

  running := true;
  for running {
    if !handle_input() do break;

    render_add_draw_call(&render_system, -0.5, -0.5, 1.0, 1.0, tex);

    render(&window, &render_system);
  }
}
