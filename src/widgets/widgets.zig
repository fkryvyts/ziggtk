const gtk = @import("gtk.zig");
const example_widget = @import("example_widget.zig");
const builder_ui = @embedFile("resources/builder.ui");

const AppError = error{
    InitializationFailed,
};

var builder: ?*gtk.GtkBuilder = null;

pub fn runApp() !void {
    gtk.gtk_init();

    registerTypes();

    const b = gtk.gtk_builder_new() orelse return AppError.InitializationFailed;
    // Construct a GtkBuilder instance and load our UI description
    var err: [*c]gtk.GError = null;
    if (gtk.gtk_builder_add_from_string(b, builder_ui, builder_ui.len, &err) == 0) {
        gtk.g_printerr("Error loading file: %s\n", err.*.message);
        gtk.g_clear_error(&err);
        return AppError.InitializationFailed;
    }

    builder = b;

    const app = gtk.gtk_application_new("org.gtk.example", gtk.G_APPLICATION_DEFAULT_FLAGS);
    _ = gtk.signalConnect(app, "activate", @ptrCast(&activate), null);
    _ = gtk.g_application_run(@ptrCast(app), 0, null);
    gtk.g_object_unref(app);

    return;
}

fn registerTypes() void {
    _ = gtk.registerType(example_widget.ExampleWidget, example_widget.ExampleWidgetClass);
}

pub fn activate(app: *gtk.GtkWidget, _: gtk.gpointer) void {
    // Connect signal handlers to the constructed widgets.
    const window = gtk.gtk_builder_get_object(builder orelse return, "window");
    gtk.gtk_window_set_application(@ptrCast(window), @ptrCast(app));
    gtk.gtk_window_set_default_size(@ptrCast(window), 400, 300);
    gtk.gtk_window_present(@ptrCast(window));

    gtk.g_print("Activated\n");
}
