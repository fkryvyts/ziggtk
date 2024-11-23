const std = @import("std");
const gtk = @import("gtk.zig");

pub const ExampleWidgetClass = extern struct {
    parent_class: gtk.GtkWidgetClass,

    pub fn init(self: *ExampleWidgetClass) void {
        gtk.setTemplate(self, "resources/example_widget.ui");
        gtk.bindTemplateChild(self, ExampleWidget, "entry");
        gtk.bindTemplateChild(self, ExampleWidget, "button");
    }
};

pub const ExampleWidget = extern struct {
    parent_instance: gtk.GtkWidget,

    entry: *gtk.GtkEntry,
    button: *gtk.GtkButton,

    pub fn init(self: *ExampleWidget) void {
        gtk.gtk_widget_init_template(@ptrCast(self));
        gtk.signalConnect(@ptrCast(self.button), "clicked", @ptrCast(&ExampleWidget.onBtnClick));
    }

    fn onBtnClick(button: *gtk.GtkWidget, _: gtk.gpointer) void {
        const widget = gtk.widgetParentOfType(button, ExampleWidget);

        if (widget) |_| {
            std.debug.print("found parent widget", .{});
        }

        gtk.g_print("Clicked the button");
    }
};
