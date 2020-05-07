package util

import "core:strings"

@(deferred_out=_free_temp_cstring)
create_cstring :: proc(str: string) -> cstring {
  return strings.clone_to_cstring(str);
}

_free_temp_cstring :: proc(cstr: cstring) {
  delete(cstr);
}
