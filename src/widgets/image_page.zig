const std = @import("std");
const gtk = @import("gtk.zig");
const image_view = @import("image_view.zig");

pub const ZvImagePageClass = extern struct {
    parent_class: gtk.AdwBinClass,

    pub fn init(self: *ZvImagePageClass) callconv(.c) void {
        gtk.setTemplate(self, "resources/image_page.ui");
        gtk.bindTemplateChild(self, ZvImagePage, "stack");
        gtk.bindTemplateChild(self, ZvImagePage, "error_page");
        gtk.bindTemplateChild(self, ZvImagePage, "image_stack_page");
        gtk.bindTemplateChild(self, ZvImagePage, "image_view");
    }
};

pub const ZvImagePage = extern struct {
    parent_instance: gtk.AdwBin,

    stack: *gtk.GtkStack,
    error_page: *gtk.GtkWidget,
    image_stack_page: *gtk.GtkWidget,
    image_view: *image_view.ZvImageView,

    entry: *gtk.GtkEntry,
    button: *gtk.GtkButton,

    pub fn init(self: *ZvImagePage) callconv(.c) void {
        gtk.gtk_widget_init_template(@ptrCast(self));

        gtk.gtk_stack_set_visible_child(self.stack, self.image_stack_page);
        // gtk.signalConnect(@ptrCast(self.button), "clicked", @ptrCast(&ZvImagePage.onBtnClick));
    }

    fn onBtnClick(button: *gtk.GtkWidget, _: gtk.gpointer) callconv(.c) void {
        const widget = gtk.widgetParentOfType(button, ZvImagePage);

        if (widget) |_| {
            std.debug.print("found parent widget", .{});
        }

        std.debug.print("Clicked the button", .{});
    }
};

pub fn registerType() gtk.GType {
    return gtk.registerType(gtk.adw_bin_get_type(), ZvImagePage, ZvImagePageClass);
}
