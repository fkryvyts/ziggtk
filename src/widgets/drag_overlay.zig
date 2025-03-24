const std = @import("std");
const gtk = @import("gtk.zig");

pub const ZvDragOverlayClass = extern struct {
    parent_class: gtk.AdwBinClass,

    pub fn init(self: *ZvDragOverlayClass) callconv(.c) void {
        gtk.setTemplate(self, "ui/drag_overlay.xml");
    }
};

pub const ZvDragOverlay = extern struct {
    parent_instance: gtk.AdwBin,

    pub fn init(self: *ZvDragOverlay) callconv(.c) void {
        gtk.gtk_widget_init_template(@ptrCast(self));
    }
};

pub fn registerType() gtk.GType {
    return gtk.registerType(gtk.adw_bin_get_type(), ZvDragOverlay, ZvDragOverlayClass);
}
