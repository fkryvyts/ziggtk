const std = @import("std");
const gtk = @import("gtk.zig");

pub const ZvDragOverlayClass = extern struct {
    parent_class: gtk.AdwBinClass,

    pub fn init(self: *ZvDragOverlayClass) callconv(.c) void {
        gtk.setTemplate(self, "ui/drag_overlay.xml");
        gtk.bindTemplateChildren(self, ZvDragOverlay, &.{
            "overlay",
            "revealer",
        });
        gtk.bindProperties(self, ZvDragOverlay, &.{
            "drop_target",
            "content",
        });
    }
};

pub const ZvDragOverlay = extern struct {
    parent_instance: gtk.AdwBin,
    overlay: *gtk.GtkOverlay,
    revealer: *gtk.GtkRevealer,
    drop_target: *gtk.GtkDropTarget,
    content: *gtk.GtkWidget,

    pub fn init(self: *ZvDragOverlay) callconv(.c) void {
        gtk.gtk_widget_init_template(@ptrCast(self));

        gtk.gtk_widget_set_can_target(@ptrCast(@alignCast(self.revealer)), 0);
    }

    pub fn onSetPropertyDropTarget(_: *ZvDragOverlay) void {}

    pub fn onSetPropertyContent(self: *ZvDragOverlay) void {
        gtk.gtk_overlay_set_child(self.overlay, self.content);
    }
};

pub fn registerType() gtk.GType {
    return gtk.registerType(gtk.adw_bin_get_type(), ZvDragOverlay, ZvDragOverlayClass);
}
