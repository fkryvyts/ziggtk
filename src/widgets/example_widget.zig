const std = @import("std");
const gtk = @import("gtk.zig");

pub const ExampleWidgetClass = extern struct {
    parent_class: gtk.AdwBinClass,

    pub fn init(self: *ExampleWidgetClass) callconv(.c) void {
        gtk.setTemplate(self, "resources/example_widget.ui");
        gtk.bindTemplateChild(self, ExampleWidget, "stack");
        gtk.bindTemplateChild(self, ExampleWidget, "error_page");
        //gtk.bindTemplateChild(self, ExampleWidget, "button");
    }
};

pub const ExampleWidget = extern struct {
    parent_instance: gtk.AdwBin,

    stack: *gtk.GtkStack,
    error_page: *gtk.GtkWidget,

    entry: *gtk.GtkEntry,
    button: *gtk.GtkButton,

    pub fn init(self: *ExampleWidget) callconv(.c) void {
        gtk.gtk_widget_init_template(@ptrCast(self));

        gtk.gtk_stack_set_visible_child(self.stack, self.error_page);
        // gtk.signalConnect(@ptrCast(self.button), "clicked", @ptrCast(&ExampleWidget.onBtnClick));
    }

    fn onBtnClick(button: *gtk.GtkWidget, _: gtk.gpointer) void {
        const widget = gtk.widgetParentOfType(button, ExampleWidget);

        if (widget) |_| {
            std.debug.print("found parent widget", .{});
        }

        gtk.g_print("Clicked the button");
    }
};
