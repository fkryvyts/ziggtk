const std = @import("std");
const gtk = @import("../gtk/gtk.zig");
const gtkx = @import("../gtk/gtkx.zig");

pub const ZvDragOverlayClass = extern struct {
    parent_class: gtk.AdwBinClass,

    pub fn init(self: *ZvDragOverlayClass) callconv(.c) void {
        gtkx.setTemplate(self, "ui/drag_overlay.xml");
        gtkx.bindTemplateChildren(self, ZvDragOverlay, &.{
            "overlay",
            "revealer",
        });
        gtkx.bindProperties(self, ZvDragOverlay, &.{
            "drop_target",
            "content",
        });
    }
};

pub const ZvDragOverlay = extern struct {
    parent_instance: gtk.AdwBin,
    overlay: *gtk.GtkOverlay,
    revealer: *gtk.GtkRevealer,
    drop_target: ?*gtk.GtkDropTarget,
    content: ?*gtk.GtkWidget,

    pub fn init(self: *ZvDragOverlay) callconv(.c) void {
        gtk.gtk_widget_init_template(@ptrCast(self));
        gtk.gtk_widget_set_can_target(@ptrCast(@alignCast(self.revealer)), 0);
        gtkx.signalConnect(self, "notify::drop-target", @ptrCast(&ZvDragOverlay.onNotfyDropTarget), null);
        gtkx.signalConnect(self, "notify::content", @ptrCast(&ZvDragOverlay.onNotifyContent), null);
    }

    fn onNotfyDropTarget(self: *ZvDragOverlay) callconv(.c) void {
        gtkx.signalConnect(self.drop_target, "notify::current-drop", @ptrCast(&ZvDragOverlay.onNotifyCurrentDrop), self);
    }

    fn onNotifyContent(self: *ZvDragOverlay) callconv(.c) void {
        gtk.gtk_overlay_set_child(self.overlay, self.content);
    }

    fn onNotifyCurrentDrop(drop_target: *gtk.GtkDropTarget, _: gtk.gpointer, self: *ZvDragOverlay) callconv(.c) void {
        const has_target = gtk.gtk_drop_target_get_current_drop(drop_target) != null;
        gtk.gtk_revealer_set_reveal_child(self.revealer, @intFromBool(has_target));
    }
};

pub fn registerType() gtk.GType {
    return gtkx.registerType(gtk.adw_bin_get_type(), ZvDragOverlay, ZvDragOverlayClass);
}
