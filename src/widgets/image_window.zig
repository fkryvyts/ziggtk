const std = @import("std");
const gtk = @import("gtk.zig");

pub const ZvImageWindowClass = extern struct {
    parent_class: gtk.AdwApplicationWindowClass,

    pub fn init(self: *ZvImageWindowClass) callconv(.c) void {
        gtk.setTemplate(self, "ui/image_window.xml");
        gtk.bindProperties(self, ZvImageWindow, &.{
            "fullscreened",
        });
    }
};

pub const ZvImageWindow = extern struct {
    parent_instance: gtk.AdwApplicationWindow,
    fullscreened: bool,

    pub fn init(self: *ZvImageWindow) callconv(.c) void {
        gtk.gtk_widget_init_template(@ptrCast(self));
    }
};

pub fn registerType() gtk.GType {
    return gtk.registerType(gtk.adw_application_window_get_type(), ZvImageWindow, ZvImageWindowClass);
}
