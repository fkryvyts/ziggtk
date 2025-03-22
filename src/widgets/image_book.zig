const std = @import("std");
const gtk = @import("gtk.zig");
const image_page = @import("image_page.zig");

const ZvImageBookProps = enum(gtk.guint) {
    zoom_toggle_state = 150,
};

pub const ZvImageBookClass = extern struct {
    parent_class: gtk.AdwBinClass,

    pub fn init(self: *ZvImageBookClass) callconv(.c) void {
        gtk.setTemplate(self, "resources/image_book.ui");
        gtk.bindTemplateChild(self, ZvImageBook, "image_page");
        gtk.bindProperties(self, ZvImageBook, &.{"zoom_toggle_state"});
    }
};

pub const ZvImageBook = extern struct {
    parent_instance: gtk.AdwBin,
    image_page: *image_page.ZvImagePage,

    zoom_toggle_state: bool,

    pub fn init(self: *ZvImageBook) callconv(.c) void {
        gtk.gtk_widget_init_template(@ptrCast(self));
    }

    pub fn loadImage(self: *ZvImageBook, path: []const u8) void {
        self.image_page.loadImage(path);

        gtk.g_object_set_property(@ptrCast(self), "zoom_toggle_state", &gtk.boolAsGValue(true));
    }
};

pub fn registerType() gtk.GType {
    return gtk.registerType(gtk.adw_bin_get_type(), ZvImageBook, ZvImageBookClass);
}
