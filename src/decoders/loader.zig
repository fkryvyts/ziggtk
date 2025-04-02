const std = @import("std");
const gtk = @import("../widgets/gtk.zig");

pub const CallbackFunc = ?*const fn (gtk.gpointer, ?*gtk.GdkTexture) void;

const CallbackWrap = struct {
    self: *Loader,
    callback: CallbackFunc,
    data: gtk.gpointer,
    image_texture: ?*gtk.GdkTexture,
};

pub const Loader = struct {
    allocator: std.mem.Allocator = undefined,
    pool: std.Thread.Pool = undefined,

    pub fn init(self: *Loader, allocator: std.mem.Allocator) !void {
        self.allocator = allocator;

        try self.pool.init(std.Thread.Pool.Options{ .allocator = allocator, .n_jobs = 1 });
    }

    pub fn deinit(self: *Loader) void {
        self.pool.deinit();
    }

    // New images are loaded within a thread pool
    pub fn loadImage(self: *Loader, path: []const u8, callback: CallbackFunc, data: gtk.gpointer) !void {
        // Copy path from stack to heap
        const path_copy = try self.allocator.dupe(u8, path);

        try self.pool.spawn(Loader.loadImageJob, .{ self, path_copy, callback, data });
    }

    // Executed in the worker thread
    fn loadImageJob(self: *Loader, path: []const u8, callback: CallbackFunc, data: gtk.gpointer) void {
        defer self.allocator.free(path);

        //std.Thread.sleep(std.time.ns_per_s * 3);

        var err: [*c]gtk.GError = null;
        const image_texture = gtk.gdk_texture_new_from_filename(path.ptr, &err);

        if (err != null) {
            gtk.printAndCleanError(&err, "Failed to load image");
        }

        const wrap = self.allocator.create(CallbackWrap) catch return;
        wrap.* = .{ .self = self, .callback = callback, .data = data, .image_texture = image_texture };

        _ = gtk.g_idle_add(@ptrCast(&Loader.onImageLoad), wrap);
    }

    // Executed in the main GTK thread
    fn onImageLoad(wrap: *CallbackWrap) callconv(.c) gtk.gboolean {
        defer wrap.self.allocator.destroy(wrap);

        const c = wrap.callback orelse return 0;
        c(wrap.data, wrap.image_texture);
        return 0;
    }
};

pub var default_loader = Loader{};
