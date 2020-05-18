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

  /*
  register_debug_program("rotation", proc(_: rawptr) {
    imgui_struct("rotation", rot);
  });
  */

  register_debug_program("test struct", proc(_: rawptr) {
    imgui_struct("test struct", ts);
  });
}

rot : f64 = 0.0;

test_struct :: struct {
  v_int : int,

  v_i8  : i8,
  v_i16 : i16,
  v_i32 : i32,
  v_i64 : i64,

  v_u8  : u8,
  v_u16 : u16,
  v_u32 : u32,
  v_u64 : u64,

  v_f32 : f32,
  v_f64 : f64,

  v_bool : bool,

  v_ptr_nil : rawptr,
  v_rawptr  : rawptr,
  v_ptr     : ^f64,
}

ts := test_struct {
  v_int = -5,

  v_i8  = -4,
  v_i16 = -3,
  v_i32 = -2,
  v_i64 = -1,

  v_u8  = 0,
  v_u16 = 1,
  v_u32 = 2,
  v_u64 = 3,

  v_f32 = 3.1415,
  v_f64 = 3.14159265358979323846264338327950,

  v_bool = true,

  v_ptr_nil = nil,
  v_rawptr  = cast(rawptr)&rot,
  v_ptr     = &rot,
};

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

  model_id := add_animation_model(&animation_system, tex, 2, [dynamic]Vec2f{ {16,32}, {16,32} }, [dynamic]f32{1.0,2.0});
  add_animation_instance(&animation_system, model_id, &player_pos);

  new_frame(&time_system);
  running := true;
  for running {
    if !handle_input() do break;

    render_add_draw_cmd(&render_system, 50, 50, 64, 64, tex, 1);
    //render_add_draw_cmd(&render_system, player_pos.x, player_pos.y, 32, 32, tex, 0);

    render_add_texture(&render_system, 10, 10, tex, 0, f32(rot));

    uvs := [2]Vec2f { {0.0, 0.0}, {1.0, 1.0} };
    render_add_sprite(&render_system, 10, 10, 32, 32, tex, 0, uvs);

    resolve_collisions(&physics_system);
    render_animations(&animation_system);

    render(&render_system, &window);
    new_frame(&time_system);
  }
}
