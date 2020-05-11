# dynamic arrays

append
pop
len
clear
? add / add_elems
? reserve
? resize
? set_capacity

make
delete

## odin-imgui (https://github.com/ThisDrunkDane/odin-imgui)

```
color_edit3   :: proc(label : string, col : [3]f32, flags := Color_Edit_Flags(0)) -> bool                           { _col := col; return im_color_edit3(_make_label_string(label), &_col[0], flags) }
color_edit4   :: proc(label : string, col : [4]f32, flags := Color_Edit_Flags(0)) -> bool                           { _col := col; return im_color_edit4(_make_label_string(label), &_col[0], flags) }
```
