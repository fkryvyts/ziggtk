const std = @import("std");
const gtk = @import("gtk.zig");

pub const ZvErrorDetailsClass = extern struct {
    parent_class: gtk.AdwDialogClass,

    pub fn init(self: *ZvErrorDetailsClass) callconv(.c) void {
        gtk.setTemplate(self, "ui/error_details.xml");
        gtk.bindTemplateChildren(self, ZvErrorDetails, &.{
            "message",
        });
    }
};

pub const ZvErrorDetails = extern struct {
    parent_instance: gtk.AdwDialog,
    message: *gtk.GtkTextView,

    pub fn init(self: *ZvErrorDetails) callconv(.c) void {
        gtk.gtk_widget_init_template(@ptrCast(self));
    }

    pub fn present(self: *ZvErrorDetails, text: []const u8, parent: ?*gtk.GtkWidget) void {
        const buff = gtk.gtk_text_view_get_buffer(self.message);
        gtk.gtk_text_buffer_set_text(buff, text.ptr, @intCast(text.len));
        gtk.adw_dialog_present(@ptrCast(self), parent);
    }
};

pub fn registerType() gtk.GType {
    return gtk.registerType(gtk.adw_dialog_get_type(), ZvErrorDetails, ZvErrorDetailsClass);
}
