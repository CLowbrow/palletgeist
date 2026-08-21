#+build js

package main

import "base:runtime"
import "core:log"
import "core:mem"

@(private="file")
web_context: runtime.Context

@(private="file")
web_app: App

@(private="file")
web_logger_initialized: bool

// Emscripten calls these exports from requestAnimationFrame in index.html.
@export
main_start :: proc "c" () {
	context = runtime.default_context()
	context.allocator = emscripten_allocator()
	runtime.init_global_temporary_allocator(4 * mem.Megabyte)
	context.logger = log.create_console_logger()
	web_logger_initialized = true
	web_context = context

	if !app_init(&web_app) {
		log.error("Palletgeist failed to initialize")
	}
}

@export
main_update :: proc "c" () -> bool {
	context = web_context
	return app_frame(&web_app)
}

@export
main_end :: proc "c" () {
	context = web_context
	app_shutdown(&web_app)
	if web_logger_initialized {
		log.destroy_console_logger(context.logger)
		web_logger_initialized = false
	}
}
