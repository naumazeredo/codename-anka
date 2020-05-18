package anka

import "external/sdl"

time_system : Time_System = new_time_system();

Time_System :: struct {
  frame_count : u32          `read_only`,

  real_time : f64            `read_only`,
  real_frame_duration : f64  `read_only`,


  game_time : f64            `read_only`,
  game_frame_duration : f64  `read_only`,

  time_scale : f64           `min=0.0 max=16.0 speed=0.1`,
}

new_time_system :: proc() -> Time_System {
  time_system := Time_System {
    time_scale = 1.0
  };

  new_frame(&time_system);

  return time_system;
}

DESIRED_FRAME_RATE :: 60.0;
DESIRED_FRAME_DURATION :: 1.0 / DESIRED_FRAME_RATE;

get_real_time :: proc() -> f64 {
  return f64(sdl.get_performance_counter()) / f64(sdl.get_performance_frequency());
}

_cap_framerate :: proc(using time_system : ^Time_System) {
  frame_duration := get_real_time() - real_time;

  if frame_duration < DESIRED_FRAME_DURATION {
    desired_delay := u32(1000 * (DESIRED_FRAME_DURATION - frame_duration));
    sdl.delay(desired_delay);
  }
}

new_frame :: proc(using time_system : ^Time_System) {
  frame_count += 1;

  _cap_framerate(time_system);

  real_frame_duration = get_real_time() - real_time;
  real_time += real_frame_duration;

  game_frame_duration = time_scale * real_frame_duration;
  game_time += game_frame_duration;
}

pause :: proc(using time_system : ^Time_System) {
  time_scale = 0.0;
}

resume :: proc(using time_system : ^Time_System) {
  time_scale = 1.0;
}
