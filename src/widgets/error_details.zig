const std = @import("std");
const gtk = @import("gtk.zig");

pub const ZvErrorDetailsClass = extern struct {
    parent_class: gtk.AdwDialogClass,

    pub fn init(self: *ZvErrorDetailsClass) callconv(.c) void {
        gtk.setTemplate(self, "ui/error_details.xml");
    }
};

pub const ZvErrorDetails = extern struct {
    parent_instance: gtk.AdwDialog,

    pub fn init(self: *ZvErrorDetails) callconv(.c) void {
        gtk.gtk_widget_init_template(@ptrCast(self));
    }
};

pub fn registerType() gtk.GType {
    return gtk.registerType(gtk.adw_dialog_get_type(), ZvErrorDetails, ZvErrorDetailsClass);
}
