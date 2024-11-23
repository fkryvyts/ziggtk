const gtk = @import("gtk.zig");
const example_widget = @import("example_widget.zig");
const builder_ui = @embedFile("resources/builder.ui");

var builder: *gtk.GtkBuilder = undefined;

pub fn activate(app: *gtk.GtkWidget, _: gtk.gpointer) void {
    registerTypes();

    builder = gtk.gtk_builder_new() orelse return;
    // Construct a GtkBuilder instance and load our UI description
    var err: [*c]gtk.GError = null;
    if (gtk.gtk_builder_add_from_string(builder, builder_ui, builder_ui.len, &err) == 0) {
        gtk.g_printerr("Error loading file: %s\n", err.*.message);
        gtk.g_clear_error(&err);
        return;
    }

    // Connect signal handlers to the constructed widgets.
    const window = gtk.gtk_builder_get_object(builder, "window");
    gtk.gtk_window_set_application(@ptrCast(window), @ptrCast(app));
    gtk.gtk_window_set_default_size(@ptrCast(window), 400, 300);
    gtk.gtk_window_present(@ptrCast(window));

    gtk.g_print("Activated\n");
}

fn registerTypes() void {
    _ = gtk.registerType(example_widget.ExampleWidget, example_widget.ExampleWidgetClass);
}
