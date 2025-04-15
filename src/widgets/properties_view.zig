const std = @import("std");
const gtk = @import("../gtk/gtk.zig");
const gtkx = @import("../gtk/gtkx.zig");

pub const ZvPropertiesViewClass = extern struct {
    parent_class: gtk.AdwBinClass,

    pub fn init(self: *ZvPropertiesViewClass) callconv(.c) void {
        gtkx.setTemplate(self, "ui/properties_view.xml");
    }
};

pub const ZvPropertiesView = extern struct {
    parent_instance: gtk.AdwBin,

    pub fn init(self: *ZvPropertiesView) callconv(.c) void {
        gtk.gtk_widget_init_template(@ptrCast(self));
    }
};

pub fn registerType() gtk.GType {
    return gtkx.registerType(gtk.adw_bin_get_type(), ZvPropertiesView, ZvPropertiesViewClass);
}
