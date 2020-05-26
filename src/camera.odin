package anka

import "core:math/linalg"

Camera :: struct {
  is_perspective : bool,

  position : Vec3f,
  rotation : Quaternion,
  near     : f32,
  far      : f32,

  // @Refactor(naum): can be an union
  // ortho
  size : Vec2f,

  // perspective
  fov      : f32,
  aspect   : f32,

  // cached matrixes
  view_mat_cache : Matrix4,
  proj_mat_cache : Matrix4,
}

init_camera_perspective :: proc(camera : ^Camera, fov, aspect, near, far : f32) {
  camera.is_perspective = true;
  camera.position = { 0, 0, 0 };
  camera.rotation = linalg.QUATERNION_IDENTITY;
  camera.fov = fov;
  camera.aspect = aspect;
  camera.near = near;
  camera.far = far;
}

init_camera_ortho :: proc(camera : ^Camera, size : Vec2f, near, far : f32) {
  camera.is_perspective = false;
  camera.position = { 0, 0, 0 };
  camera.rotation = linalg.QUATERNION_IDENTITY;
  camera.size = size;
  camera.near = near;
  camera.far = far;
}

construct_camera_view_matrix :: proc(using camera : ^Camera) -> Matrix4 {
  mat := linalg.MATRIX4_IDENTITY;
  mat = linalg.mul(mat, linalg.matrix4_translate(linalg.Vector3(-position)));
  mat = linalg.mul(mat, linalg.matrix4_from_quaternion(rotation));
  return mat;
}

construct_camera_proj_matrix :: proc(using camera : ^Camera) -> Matrix4 {
  if is_perspective {
    //aspect = size.x / size.y;
    return linalg.matrix4_perspective(linalg.radians(fov), aspect, near, far, false);
  }

  return linalg.matrix_ortho3d(
    0.0, size.x,
    size.y, 0.0,
    near, far
  );
}

construct_camera_matrixes :: proc(using camera : ^Camera) {
  view_mat_cache = construct_camera_view_matrix(camera);
  proj_mat_cache = construct_camera_proj_matrix(camera);

  /*
  proj_mat_cache = linalg.matrix_ortho3d(
    0.0, f32(window.width),
    f32(window.height), 0.0,
    -1000.0, 1000.0
  );
  */
}
