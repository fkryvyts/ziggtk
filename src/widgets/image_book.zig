const std = @import("std");
const gtk = @import("../gtk/gtk.zig");
const gtkx = @import("../gtk/gtkx.zig");
const image_page = @import("image_page.zig");

pub const ZvImageBookClass = extern struct {
    parent_class: gtk.AdwBinClass,

    pub fn init(self: *ZvImageBookClass) callconv(.c) void {
        gtkx.setTemplate(self, "ui/image_book.xml");
        gtkx.bindTemplateChildren(self, ZvImageBook, &.{
            "image_page",
            "zoom_to_list",
            "zoom_to_300",
            "zoom_to_200",
            "zoom_to_100",
            "zoom_to_66",
            "zoom_to_50",
            "zoom_menu_button",
        });
        gtkx.bindProperties(self, ZvImageBook, &.{
            "zoom_toggle_state",
        });
    }
};

pub const ZvImageBook = extern struct {
    parent_instance: gtk.AdwBin,
    image_page: *image_page.ZvImagePage,
    zoom_to_list: *gtk.GtkListBox,
    zoom_to_300: *gtk.GtkListBoxRow,
    zoom_to_200: *gtk.GtkListBoxRow,
    zoom_to_100: *gtk.GtkListBoxRow,
    zoom_to_66: *gtk.GtkListBoxRow,
    zoom_to_50: *gtk.GtkListBoxRow,
    zoom_menu_button: *gtk.GtkMenuButton,
    zoom_toggle_state: bool,

    pub fn init(self: *ZvImageBook) callconv(.c) void {
        gtk.gtk_widget_init_template(@ptrCast(self));
        gtkx.signalConnect(self.zoom_to_list, "row-activated", @ptrCast(&ZvImageBook.onZoomToListRowActivated), self);
    }

    pub fn currentPage(self: *ZvImageBook) *image_page.ZvImagePage {
        return self.image_page;
    }

    fn onZoomToListRowActivated(_: *gtk.GtkListBox, row: *gtk.GtkListBoxRow, self: *ZvImageBook) callconv(.c) void {
        defer gtk.gtk_menu_button_set_active(self.zoom_menu_button, 0);

        var zoom: f32 = 1;

        if (row == self.zoom_to_300) {
            zoom = 3;
        } else if (row == self.zoom_to_200) {
            zoom = 2;
        } else if (row == self.zoom_to_100) {
            zoom = 1;
        } else if (row == self.zoom_to_66) {
            zoom = 0.66;
        } else if (row == self.zoom_to_50) {
            zoom = 0.5;
        }

        self.currentPage().setZoom(zoom);
    }
};

pub fn registerType() gtk.GType {
    return gtkx.registerType(gtk.adw_bin_get_type(), ZvImageBook, ZvImageBookClass);
}
