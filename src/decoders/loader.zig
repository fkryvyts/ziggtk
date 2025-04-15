const imagex = @cImport({
    @cInclude("libgoimagex-1.h");
});

const std = @import("std");
const gtk = @import("../gtk/gtk.zig");
const gtkx = @import("../gtk/gtkx.zig");
const images = @import("images.zig");

pub const CallbackFunc = ?*const fn (gtk.gpointer, *images.Image) void;

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

    fn loadImageJob(self: *Loader, path: []const u8, callback: CallbackFunc, data: gtk.gpointer) void {
        loadImageJobWithErr(self, path, callback, data) catch return;
    }

    // Executed in the worker thread
    fn loadImageJobWithErr(self: *Loader, path: []const u8, callback: CallbackFunc, data: gtk.gpointer) !void {
        defer self.allocator.free(path);

        //std.Thread.sleep(std.time.ns_per_s * 3);

        var img: *images.Image = undefined;

        if (std.mem.indexOf(u8, path, ".gif")) |_| {
            img = try self.loadImageExternally(path);
        } else if (std.mem.indexOf(u8, path, ".zpl")) |_| {
            img = try self.loadImageExternally(path);
        } else {
            img = try self.loadImageDefault(path);
        }

        errdefer img.destroy();

        const wrap = try CallbackWrap.new(.{
            .allocator = self.allocator,
            .callback = callback,
            .data = data,
            .image = img,
        });

        _ = gtk.g_idle_add(@ptrCast(&CallbackWrap.onDone), wrap);
    }

    // Load image textures via native GTK functionality
    fn loadImageDefault(self: *Loader, path: []const u8) !*images.Image {
        var err: [*c]gtk.GError = null;
        var err_msg: []u8 = "";
        const image_texture = gtk.gdk_texture_new_from_filename(path.ptr, &err);
        defer gtkx.printAndCleanError(&err, "Failed to load image");

        if (err != null) {
            err_msg = std.mem.span(err.*.message);
        }

        return images.Image.new(.{
            .allocator = self.allocator,
            .path = path,
            .error_message = err_msg,
            .image_texture = image_texture,
        });
    }

    // Load image textures via external Imagex library
    fn loadImageExternally(self: *Loader, path: []const u8) !*images.Image {
        const res = imagex.LoadImage(path.ptr);
        defer imagex.FreeResult(res);

        if (res.err != null) {
            return images.Image.new(.{
                .allocator = self.allocator,
                .path = path,
                .error_message = std.mem.span(res.err),
            });
        }

        var img = try images.Image.new(.{
            .allocator = self.allocator,
            .path = path,
        });

        var i: c_int = 0;
        while (i < res.data.frame_count) : (i += 1) {
            const pixbuf = gtk.gdk_pixbuf_new_from_data(
                res.data.frames[@intCast(i)],
                gtk.GDK_COLORSPACE_RGB,
                1,
                8,
                res.data.width,
                res.data.height,
                res.data.width * 4,
                @ptrCast(&imagex.FreeImageFrame),
                null,
            );
            defer gtk.g_object_unref(pixbuf);

            const texture = gtk.gdk_texture_new_for_pixbuf(pixbuf);
            if (texture) |tex| {
                try img.addFrame(.{ .texture = tex, .delay = @intCast(res.data.frame_delays[@intCast(i)]) });
            }
        }

        return img;
    }
};

const CallbackWrap = struct {
    allocator: std.mem.Allocator,
    callback: CallbackFunc,
    data: gtk.gpointer,
    image: *images.Image,

    fn new(data: CallbackWrap) !*CallbackWrap {
        const res = try data.allocator.create(CallbackWrap);
        res.* = data;
        return res;
    }

    // Executed in the main GTK thread
    fn onDone(self: *CallbackWrap) callconv(.c) gtk.gboolean {
        defer self.allocator.destroy(self);

        const callback = self.callback orelse return 0;
        callback(self.data, self.image);
        return 0;
    }
};

pub var default_loader = Loader{};
