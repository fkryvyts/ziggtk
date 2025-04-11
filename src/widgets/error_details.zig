const std = @import("std");
const gtk = @import("gtk.zig");

pub const ZvErrorDetailsClass = extern struct {
    parent_class: gtk.AdwDialogClass,

    pub fn init(self: *ZvErrorDetailsClass) callconv(.c) void {
        gtk.setTemplate(self, "ui/error_details.xml");
        gtk.bindTemplateChildren(self, ZvErrorDetails, &.{
            "message",
            "copy_btn",
        });
    }
};

pub const ZvErrorDetails = extern struct {
    parent_instance: gtk.AdwDialog,
    message: *gtk.GtkTextView,
    copy_btn: *gtk.GtkButton,

    pub fn init(self: *ZvErrorDetails) callconv(.c) void {
        gtk.gtk_widget_init_template(@ptrCast(self));

        gtk.signalConnect(self.copy_btn, "clicked", @ptrCast(&ZvErrorDetails.onCopyBtnClicked), self);
    }

    pub fn present(self: *ZvErrorDetails, text: []const u8, parent: ?*gtk.GtkWidget) void {
        const buff = gtk.gtk_text_view_get_buffer(self.message);
        gtk.gtk_text_buffer_set_text(buff, text.ptr, @intCast(text.len));
        gtk.adw_dialog_present(@ptrCast(self), parent);
    }

    fn onCopyBtnClicked(_: *gtk.GtkButton, self: *ZvErrorDetails) callconv(.c) void {
        const display = gtk.gtk_widget_get_display(@ptrCast(self));
        const clipboard = gtk.gdk_display_get_clipboard(display);
        const buff = gtk.gtk_text_view_get_buffer(self.message);

        var start = std.mem.zeroes(gtk.GtkTextIter);
        gtk.gtk_text_buffer_get_start_iter(buff, &start);

        var end = std.mem.zeroes(gtk.GtkTextIter);
        gtk.gtk_text_buffer_get_end_iter(buff, &end);

        const text = gtk.gtk_text_buffer_get_text(buff, &start, &end, 0);
        defer gtk.g_free(text);

        gtk.gdk_clipboard_set_text(clipboard, text);
    }
};

pub fn registerType() gtk.GType {
    return gtk.registerType(gtk.adw_dialog_get_type(), ZvErrorDetails, ZvErrorDetailsClass);
}
