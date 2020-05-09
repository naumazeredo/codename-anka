package anka

import "util"

Collider :: struct {
  id: int,
  rect: Rect
}

physics_system : Physics_System;

Physics_System :: struct {
  colliders: [dynamic]Collider,

  is_colliding: map[int]bool,

  player_collider : Vec2f,
  player_pos : ^Vec2f,

  on_collision_enter: [dynamic]proc(int),
  on_collision_stay: [dynamic]proc(int),
  on_collision_exit: [dynamic]proc(int)
};

_raise_callbacks :: proc (id: int, callbacks :[dynamic]proc(int)){
  for callback in callbacks {
    callback(id);
  }
}

_resolve_collision :: proc(collider: Rect, player_collider_rect : Vec2f, player_pos: ^Vec2f) -> bool {
  player_collider : Rect = {player_pos.x, player_pos.y, player_collider_rect.x, player_collider_rect.y};

  return player_collider.x < collider.x && 
    player_collider.x + player_collider.w >  collider.x && 
    player_collider.y < collider.y + collider.h &&
    player_collider.x + player_collider.h > collider.y;
}

resolve_collisions :: proc(using system: ^Physics_System) {
  for collider, id in colliders {
    if _resolve_collision(collider.rect, player_collider, player_pos) {
      if is_colliding[id] {
        _raise_callbacks(id, on_collision_stay);
      } else {
        _raise_callbacks(id, on_collision_enter);
      }

      is_colliding[id] = true;
    } else {
      if is_colliding[id] {
        _raise_callbacks(id, on_collision_exit);
      }
      is_colliding[id] = false;
    }
  }
}

add_player_collider :: proc(using system : ^Physics_System, w,h : f32, pos : ^Vec2f) {
  player_collider = {w,h};
  player_pos = pos;
}

add_collider :: proc(using system: ^Physics_System, rect: Rect) -> int {
  append(&colliders, Collider{len(colliders), rect});

  return len(colliders);
}

register_on_collision_enter :: proc(using system: ^Physics_System, callback: proc(int)) {
  append(&on_collision_enter, callback);
}

register_on_collision_exit :: proc(using system: ^Physics_System, callback: proc(int)) {
  append(&on_collision_exit, callback);
}

register_on_collision_stay :: proc(using system: ^Physics_System, callback: proc(int)) {
  append(&on_collision_stay, callback);
}
