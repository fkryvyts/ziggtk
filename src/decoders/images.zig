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
