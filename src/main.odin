package anka

import "core:fmt"
import "core:math/linalg"

import "external/sdl"
import "external/gl"
import "external/imgui"

window : Window;

init :: proc() {
  sdl.init(sdl.Init_Flags.Everything);
  window = create_window("Codename Anka", 1280, 720);

  // @Refactor(naum): move this to game system
  init_render(&render_system);
}

cleanup :: proc() {
  cleanup_render(&render_system);

  sdl.quit();
}

handle_input :: proc() -> bool {
  e: sdl.Event;

  vel_x,vel_y : f32;
  for sdl.poll_event(&e) != 0 {
    handle_debug_input(&e);

    if e.type == sdl.Event_Type.Quit {
      return false;
    }

    if e.type == sdl.Event_Type.Key_Down {
      switch e.key.keysym.sym {
        case sdl.SDLK_ESCAPE: return false;

        case sdl.SDLK_j: vel_y = SPEED;
        case sdl.SDLK_k: vel_y = -SPEED;
        case sdl.SDLK_h: vel_x = -SPEED;
        case sdl.SDLK_l: vel_x = SPEED;

        case sdl.SDLK_e: rot += 5;
        case sdl.SDLK_q: rot -= 5;
      }
    }
  }

  player_pos.x += vel_x;
  player_pos.y += vel_y;

  return true;
}

// -----------
//    Test
// -----------

player_pos := Vec2f { 100, 100 };
SPEED :: 5;

test :: proc() {
  register_on_collision_enter(&physics_system, proc(id : int) {
    fmt.println("entered collision with object with id: ", id);
  });

  register_on_collision_exit(&physics_system, proc(id : int) {
    fmt.println("exited collision with object with id: ", id);
  });

  register_on_collision_stay(&physics_system, proc(id : int) {
    fmt.println("stayed collision with object with id: ", id);
  });

  add_collider(&physics_system, Rect{50,50, 64,64});

  add_player_collider(&physics_system, 32,32, &player_pos);

  register_debug_program("rotation", proc(_: rawptr) {
    imgui.drag_float("rotation", &rot);
  });
}

rot : f32 = 0.0;

// -----------
//    /Test
// -----------


main :: proc() {
  init();
  defer cleanup();

  init_render(&render_system);
  defer cleanup_render(&render_system);

  init_debug(&render_system, &window);
  defer cleanup_debug();

  tex, ok := load_image(&render_system, "./assets/gfx/template-32x32.png");

  test();

  running := true;
  for running {
    if !handle_input() do break;

    render_add_draw_cmd(&render_system, 50, 50, 64, 64, tex, 1);
    render_add_draw_cmd(&render_system, player_pos.x, player_pos.y, 32, 32, tex, 0);

    render_add_texture(&render_system, 10, 10, tex, 0, rot);

    resolve_collisions(&physics_system);

    render(&render_system, &window);
  }
}
