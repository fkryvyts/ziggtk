const c = @cImport({
    @cInclude("gtk/gtk.h");
});

const gtk = @import("gtk.zig");

pub const ExampleWidgetClass = extern struct {
    parent_class: c.GtkWidgetClass,

    pub fn init(self: *ExampleWidgetClass) void {
        gtk.setTemplate(self, "resources/example_widget.ui");
        gtk.bindTemplateChild(self, ExampleWidget, "entry");
        gtk.bindTemplateChild(self, ExampleWidget, "button");
    }
};

pub const ExampleWidget = extern struct {
    parent_instance: c.GtkWidget,

    entry: *c.GtkWidget,
    button: *c.GtkWidget,

    pub fn init(self: *ExampleWidget) void {
        c.gtk_widget_init_template(@ptrCast(self));
        _ = gtk.signalConnect(@ptrCast(self.button), "clicked", @ptrCast(&ExampleWidget.onBtnClick), null);
    }

    fn onBtnClick() void {
        c.g_print("Clicked the button");
    }
};
