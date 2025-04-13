const std = @import("std");
const gtk = @import("../widgets/gtk.zig");

pub const ImageOptions = struct {
    allocator: std.mem.Allocator,
    path: []const u8,
    image_texture: ?*gtk.GdkTexture = null,
    error_message: []const u8 = "",
};

pub const Image = struct {
    allocator: std.mem.Allocator,
    image_texture: ?*gtk.GdkTexture,
    error_message: []const u8,
    path: []const u8,
    frames: std.ArrayList(*gtk.GdkTexture),

    pub fn new(data: ImageOptions) !*Image {
        const res = try data.allocator.create(Image);
        res.allocator = data.allocator;

        var frames = std.ArrayList(*gtk.GdkTexture).init(data.allocator);
        errdefer frames.deinit();

        if (data.image_texture) |texture| {
            try frames.append(texture);
        }

        res.frames = frames;

        res.path = try data.allocator.dupe(u8, data.path);
        errdefer data.allocator.free(res.path);

        res.error_message = try data.allocator.dupe(u8, data.error_message);
        errdefer data.allocator.free(res.error_message);

        return res;
    }

    pub fn addFrame(self: *Image, frame: *gtk.GdkTexture) !void {
        try self.frames.append(frame);
    }

    pub fn destroy(self: *Image) void {
        for (self.frames.items) |frame| {
            gtk.g_object_unref(frame);
        }

        self.frames.deinit();
        self.allocator.free(self.path);
        self.allocator.free(self.error_message);
        self.allocator.destroy(self);
    }

    pub fn firstFrame(self: *Image) ?*gtk.GdkTexture {
        if (self.frames.items.len == 0) {
            return null;
        }

        return self.frames.items[0];
    }

    pub fn width(self: *Image) f32 {
        const texture = self.firstFrame() orelse return 0;
        return @floatFromInt(gtk.gdk_texture_get_width(texture));
    }

    pub fn height(self: *Image) f32 {
        const texture = self.firstFrame() orelse return 0;
        return @floatFromInt(gtk.gdk_texture_get_height(texture));
    }
};
