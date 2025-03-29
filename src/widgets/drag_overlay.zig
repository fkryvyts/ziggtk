const std = @import("std");
const gtk = @import("gtk.zig");

pub const ZvDragOverlayClass = extern struct {
    parent_class: gtk.AdwBinClass,

    pub fn init(self: *ZvDragOverlayClass) callconv(.c) void {
        gtk.setTemplate(self, "ui/drag_overlay.xml");
        gtk.bindProperties(self, ZvDragOverlay, &.{
            "drop_target",
        });
    }
};

pub const ZvDragOverlay = extern struct {
    parent_instance: gtk.AdwBin,
    drop_target: *gtk.GtkDropTarget,

    pub fn init(self: *ZvDragOverlay) callconv(.c) void {
        gtk.gtk_widget_init_template(@ptrCast(self));
    }

    pub fn onSetPropertyDropTarget(_: *ZvDragOverlay) void {
        std.debug.print("on set drop target", .{});
    }
};

pub fn registerType() gtk.GType {
    return gtk.registerType(gtk.adw_bin_get_type(), ZvDragOverlay, ZvDragOverlayClass);
}
