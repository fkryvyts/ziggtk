const std = @import("std");
const gtk = @import("gtk.zig");

pub const ZvImageViewClass = extern struct {
    parent_class: gtk.GtkWidgetClass,

    pub fn init(self: *ZvImageViewClass) callconv(.c) void {
        self.parent_class.snapshot = @ptrCast(&ZvImageView.onSnapshot);
    }
};

pub const ZvImageView = extern struct {
    parent_instance: gtk.GtkWidget,
    image_texture: ?*gtk.GdkTexture,

    pub fn init(self: *ZvImageView) callconv(.c) void {
        self.image_texture = gtk.gdk_texture_new_from_filename("/home/fedir/Downloads/image.jpg", null);
    }

    pub fn onSnapshot(self: *ZvImageView, snapshot: *gtk.GtkSnapshot) callconv(.c) void {
        const width = @as(f32, @floatFromInt(gtk.gtk_widget_get_width(@ptrCast(self))));
        const height = @as(f32, @floatFromInt(gtk.gtk_widget_get_height(@ptrCast(self))));

        var rect = std.mem.zeroes(gtk.graphene_rect_t);
        _ = gtk.graphene_rect_init(&rect, 0, 0, width, height);
        gtk.gtk_snapshot_append_texture(snapshot, self.image_texture, &rect);
    }
};

pub fn registerType() gtk.GType {
    return gtk.registerType(gtk.gtk_widget_get_type(), ZvImageView, ZvImageViewClass);
}
