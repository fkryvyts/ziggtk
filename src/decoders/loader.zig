const std = @import("std");
const gtk = @import("../widgets/gtk.zig");

pub const Image = struct {
    allocator: std.mem.Allocator,
    image_texture: ?*gtk.GdkTexture,
    error_message: []const u8,
    path: []const u8,

    pub fn new(data: Image) !*Image {
        const res = try data.allocator.create(Image);
        res.* = data;
        res.path = try data.allocator.dupe(u8, data.path);
        res.error_message = try data.allocator.dupe(u8, data.error_message);
        return res;
    }

    pub fn destroy(self: *Image) void {
        if (self.image_texture) |texture| {
            gtk.g_object_unref(texture);
        }

        self.allocator.free(self.path);
        self.allocator.free(self.error_message);
        self.allocator.destroy(self);
    }

    pub fn width(self: *Image) f32 {
        const texture = self.image_texture orelse return 0;
        return @floatFromInt(gtk.gdk_texture_get_width(texture));
    }

    pub fn height(self: *Image) f32 {
        const texture = self.image_texture orelse return 0;
        return @floatFromInt(gtk.gdk_texture_get_height(texture));
    }
};

pub const CallbackFunc = ?*const fn (gtk.gpointer, *Image) void;

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
        var err_msg: []u8 = "";
        const image_texture = gtk.gdk_texture_new_from_filename(path.ptr, &err);
        defer gtk.printAndCleanError(&err, "Failed to load image");

        if (err != null) {
            err_msg = std.mem.span(err.*.message);
        }

        const image = Image.new(.{
            .allocator = self.allocator,
            .path = path,
            .error_message = err_msg,
            .image_texture = image_texture,
        }) catch return;

        const wrap = CallbackWrap.new(.{
            .allocator = self.allocator,
            .callback = callback,
            .data = data,
            .image = image,
        }) catch return;

        _ = gtk.g_idle_add(@ptrCast(&CallbackWrap.onDone), wrap);
    }
};

const CallbackWrap = struct {
    allocator: std.mem.Allocator,
    callback: CallbackFunc,
    data: gtk.gpointer,
    image: *Image,

    fn new(data: CallbackWrap) !*CallbackWrap {
        const res = try data.allocator.create(CallbackWrap);
        res.* = data;
        return res;
    }

    // Executed in the main GTK thread
    fn onDone(self: *CallbackWrap) callconv(.c) gtk.gboolean {
        defer self.allocator.destroy(self);

        const c = self.callback orelse return 0;
        c(self.data, self.image);
        return 0;
    }
};

pub var default_loader = Loader{};
