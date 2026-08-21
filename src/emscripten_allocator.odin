#+build js

package main

import "base:intrinsics"
import "core:c"
import "core:mem"

// Use Emscripten's libc heap so Odin and raylib share one growable WebAssembly
// memory. The pointer stored immediately before each result preserves Odin's
// alignment guarantees for maps and SIMD values.
@(default_calling_convention="c")
foreign {
	calloc  :: proc(num, size: c.size_t) -> rawptr ---
	free    :: proc(ptr: rawptr) ---
	malloc  :: proc(size: c.size_t) -> rawptr ---
	realloc :: proc(ptr: rawptr, size: c.size_t) -> rawptr ---
}

emscripten_allocator :: proc "contextless" () -> mem.Allocator {
	return mem.Allocator{emscripten_allocator_proc, nil}
}

emscripten_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: mem.Allocator_Mode,
	size, alignment: int,
	old_memory: rawptr,
	old_size: int,
	location := #caller_location,
) -> (data: []byte, err: mem.Allocator_Error) {
	aligned_alloc :: proc(
		size, alignment: int,
		zero_memory: bool,
		old_ptr: rawptr = nil,
	) -> ([]byte, mem.Allocator_Error) {
		a := max(alignment, align_of(rawptr))
		space := size + a - 1

		allocated_memory: rawptr
		if old_ptr != nil {
			original_pointer := mem.ptr_offset((^rawptr)(old_ptr), -1)^
			allocated_memory = realloc(original_pointer, c.size_t(space + size_of(rawptr)))
		} else if zero_memory {
			allocated_memory = calloc(c.size_t(space + size_of(rawptr)), 1)
		} else {
			allocated_memory = malloc(c.size_t(space + size_of(rawptr)))
		}
		if allocated_memory == nil {
			return nil, .Out_Of_Memory
		}

		unaligned := rawptr(mem.ptr_offset((^u8)(allocated_memory), size_of(rawptr)))
		pointer := uintptr(unaligned)
		aligned_pointer := (pointer - 1 + uintptr(a)) & -uintptr(a)
		if int(aligned_pointer - pointer) + size > space {
			free(allocated_memory)
			return nil, .Out_Of_Memory
		}

		result := rawptr(aligned_pointer)
		mem.ptr_offset((^rawptr)(result), -1)^ = allocated_memory
		return mem.byte_slice(result, size), nil
	}

	aligned_free :: proc(pointer: rawptr) {
		if pointer != nil {
			free(mem.ptr_offset((^rawptr)(pointer), -1)^)
		}
	}

	aligned_resize :: proc(
		pointer: rawptr,
		new_size, new_alignment: int,
		zero_memory: bool,
	) -> ([]byte, mem.Allocator_Error) {
		if pointer == nil {
			return aligned_alloc(new_size, new_alignment, zero_memory)
		}
		return aligned_alloc(new_size, new_alignment, zero_memory, pointer)
	}

	switch mode {
	case .Alloc:
		return aligned_alloc(size, alignment, true)
	case .Alloc_Non_Zeroed:
		return aligned_alloc(size, alignment, false)
	case .Free:
		aligned_free(old_memory)
		return nil, nil
	case .Resize:
		bytes := aligned_resize(old_memory, size, alignment, true) or_return
		if size > old_size {
			intrinsics.mem_zero(raw_data(bytes[old_size:]), size - old_size)
		}
		return bytes, nil
	case .Resize_Non_Zeroed:
		return aligned_resize(old_memory, size, alignment, false)
	case .Query_Features:
		if features := (^mem.Allocator_Mode_Set)(old_memory); features != nil {
			features^ = {.Alloc, .Free, .Resize, .Resize_Non_Zeroed, .Query_Features}
		}
		return nil, nil
	case .Free_All, .Query_Info:
		return nil, .Mode_Not_Implemented
	}
	return nil, .Mode_Not_Implemented
}
