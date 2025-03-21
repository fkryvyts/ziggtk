const std = @import("std");
const gtk = @import("gtk.zig");
const errors = @import("errors.zig");

pub const ZvImageViewClass = extern struct {
    parent_class: gtk.GtkWidgetClass,

    pub fn init(self: *ZvImageViewClass) callconv(.c) void {
        self.parent_class.snapshot = @ptrCast(&ZvImageView.onSnapshot);
    }
};

pub const ZvImageView = extern struct {
    parent_instance: gtk.GtkWidget,
    image_texture: ?*gtk.GdkTexture,

    pub fn init(_: *ZvImageView) callconv(.c) void {}

    pub fn setImageTexture(self: *ZvImageView, image_texture: ?*gtk.GdkTexture) void {
        self.image_texture = image_texture;
    }

    pub fn onSnapshot(self: *ZvImageView, snapshot: *gtk.GtkSnapshot) callconv(.c) void {
        if (self.image_texture == null) {
            return;
        }

        const w: f32 = @floatFromInt(gtk.gtk_widget_get_width(@ptrCast(self)));
        const h: f32 = @floatFromInt(gtk.gtk_widget_get_height(@ptrCast(self)));

        var rect = std.mem.zeroes(gtk.graphene_rect_t);
        _ = gtk.graphene_rect_init(&rect, 0, 0, w, h);
        gtk.gtk_snapshot_append_texture(snapshot, self.image_texture, &rect);
    }
};

pub fn registerType() gtk.GType {
    return gtk.registerType(gtk.gtk_widget_get_type(), ZvImageView, ZvImageViewClass);
}
