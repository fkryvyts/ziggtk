const std = @import("std");
const gtk = @import("gtk.zig");
const image_page = @import("image_page.zig");

pub const ZvImageBookClass = extern struct {
    parent_class: gtk.AdwBinClass,

    pub fn init(self: *ZvImageBookClass) callconv(.c) void {
        gtk.setTemplate(self, "ui/image_book.xml");
        gtk.bindTemplateChildren(self, ZvImageBook, &.{
            "image_page",
            "zoom_to_list",
        });
        gtk.bindProperties(self, ZvImageBook, &.{
            "zoom_toggle_state",
        });
    }
};

pub const ZvImageBook = extern struct {
    parent_instance: gtk.AdwBin,
    image_page: *image_page.ZvImagePage,
    zoom_to_list: *gtk.GtkListBox,
    zoom_toggle_state: bool,

    pub fn init(self: *ZvImageBook) callconv(.c) void {
        gtk.gtk_widget_init_template(@ptrCast(self));
    }

    pub fn currentPage(self: *ZvImageBook) *image_page.ZvImagePage {
        return self.image_page;
    }
};

pub fn registerType() gtk.GType {
    return gtk.registerType(gtk.adw_bin_get_type(), ZvImageBook, ZvImageBookClass);
}
