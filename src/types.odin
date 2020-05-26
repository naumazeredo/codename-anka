package anka

import "core:math/linalg"

Vec2   :: [2]i32;
Vec2f  :: [2]f32;
Vec3f  :: [3]f32;

Color  :: [4]u8;
Colorf :: [4]f32;

Rect :: struct { x,y,w,h : f32 };

Quaternion :: linalg.Quaternion;
Matrix4 :: linalg.Matrix4;
