package anka

import "core:fmt"

// @Thinkup : a better way to handler dependencies with other systems
animation_system : Animation_System = new_animation_system(&render_system, &time_system);

new_animation_system :: proc(render_system :^Render_System, time_system : ^Time_System) -> Animation_System {
  return Animation_System {
    render_system = render_system,
    time_system = time_system
  };
}

Animation_Model :: struct {
  texture_id : u32,
  texture_size : Vec2f,

  // @Refactor(lu): DoDify this
  frames_durations : [dynamic]f32,
  frames_sizes : [dynamic]Vec2f,

  n_of_frames : u32
}

Animation_Instance :: struct {
  // @Refactor(lu): consider change to id if gets too overwhelming to use
  model : ^Animation_Model,

  pos : ^Vec2f,

  current_frame : u32,
  current_frame_time : f32,
  current_width: f32,
}

// @Improvement(lu): add animation sets
Animation_System :: struct {
  instance_count : u32,

  // @Refactor: rename to render_system_ref ?
  render_system : ^Render_System,
  time_system : ^Time_System,

  instances: [dynamic]Animation_Instance,
  models: [dynamic]Animation_Model,
}

ANIMATIONS_BASE_PATH :: "../assets/gfx/";

// @Improvement(lu): define all frames properties in a single file, like a json or yaml or even annotations
// over odin enum code, enabling loading all animations in compile time
add_animation_model :: proc(
  using animation_system: ^Animation_System,
  texture_id: Texture_Id,
  n_of_frames: int,
  frames_sizes: [dynamic]Vec2f,
  frames_durations: [dynamic]f32) -> u32 {
  assert(len(frames_sizes) == len(frames_durations));

  size_w := f32(render_system.textures_w[texture_id]);
  size_h := f32(render_system.textures_h[texture_id]);
  
  animation_model := Animation_Model {
    texture_id = texture_id,
    texture_size = {size_w, size_h},

    frames_durations = frames_durations,
    frames_sizes = frames_sizes,
    n_of_frames = u32(len(frames_sizes)), //shoudlnt len return u32? 
  };

  append(&models, animation_model);

  return u32(len(models) - 1);
}

add_animation_instance :: proc(using animation_system: ^Animation_System, model_id: u32, pos : ^Vec2f) -> u32{
  model := &models[model_id];

  instance := Animation_Instance {
    model = model,
    pos = pos,
    current_frame = 0,
    current_frame_time = 0.0
  };

  append(&instances, instance);

  return u32(len(instances) - 1);
}

render_animations :: proc(using animation_system: ^Animation_System) {
  delta_time : f32;
  for _, id in instances {
    delta_time = f32(time_system.game_frame_duration);

    _update_instance_state(&instances[id], delta_time);

    _render_instance(&instances[id], render_system);
  }
}

_update_instance_state :: proc(instance: ^Animation_Instance, delta_time: f32) {
  model := instance.model;
  frame_duration := model.frames_durations[instance.current_frame];

  instance.current_frame_time += delta_time;

  if instance.current_frame_time > frame_duration {
    instance.current_width += model.frames_sizes[instance.current_frame].x;
    instance.current_frame = (instance.current_frame+1) % model.n_of_frames;
    instance.current_frame_time -= frame_duration;

    if (instance.current_width >= model.texture_size.x) {
      instance.current_width = 0.0;
    }
  }
}

_render_instance :: proc(using instance : ^Animation_Instance, render_system: ^Render_System) {
  uvs : [2]Vec2f;

  max_width := instance.model.texture_size.x;
  max_height:= instance.model.texture_size.y;

  uvs[0].x = current_width / max_width;
  uvs[0].y = 0;
  uvs[1].x = (current_width + model.frames_sizes[current_frame].x) / max_width;
  uvs[1].y = model.frames_sizes[current_frame].y / max_height;

  render_draw_sprite(render_system,
    pos.x,
    pos.y,
    model.frames_sizes[current_frame].x,
    model.frames_sizes[current_frame].y,
    model.texture_id,
    0,
    uvs
  );
}
