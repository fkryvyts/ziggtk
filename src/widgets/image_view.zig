const std = @import("std");
const gtk = @import("gtk.zig");
const errors = @import("errors.zig");

pub const ZvImageViewClass = extern struct {
    parent_class: gtk.GtkWidgetClass,

    pub fn init(self: *ZvImageViewClass) callconv(.c) void {
        gtk.bindProperties(self, ZvImageView, &.{
            "hadjustment",
            "vadjustment",
            "vscroll_policy",
            "hscroll_policy",
        });

        self.parent_class.snapshot = @ptrCast(&ZvImageView.onSnapshot);
    }
};

pub const ZvImageView = extern struct {
    parent_instance: gtk.GtkWidget,
    hadjustment: ?*gtk.GtkAdjustment,
    vadjustment: ?*gtk.GtkAdjustment,
    vscroll_policy: gtk.GtkScrollablePolicyEnum,
    hscroll_policy: gtk.GtkScrollablePolicyEnum,
    image_texture: ?*gtk.GdkTexture,

    pub fn init(_: *ZvImageView) callconv(.c) void {}

    pub fn setImageTexture(self: *ZvImageView, image_texture: ?*gtk.GdkTexture) void {
        if (self.image_texture != null) {
            gtk.g_object_unref(self.image_texture);
        }

        _ = gtk.g_object_ref(@ptrCast(image_texture));
        self.image_texture = image_texture;
    }

    fn onSnapshot(self: *ZvImageView, snapshot: *gtk.GtkSnapshot) callconv(.c) void {
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
    const t = gtk.registerType(gtk.gtk_widget_get_type(), ZvImageView, ZvImageViewClass);
    gtk.g_type_add_interface_static(t, gtk.gtk_scrollable_get_type(), &.{});
    return t;
}
