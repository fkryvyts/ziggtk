const gtk = @import("gtk.zig");
const example_widget = @import("example_widget.zig");
const builder_ui = @embedFile("resources/builder.ui");

const AppError = error{
    InitializationFailed,
};

var builder: ?*gtk.GtkBuilder = null;
var application: ?*gtk.GtkApplication = null;

pub fn runApp() !void {
    gtk.gtk_init();

    registerTypes();
    try initBuilder();

    const app = gtk.gtk_application_new("org.gtk.example", gtk.G_APPLICATION_DEFAULT_FLAGS);
    application = app;

    gtk.signalConnect(app, "activate", @ptrCast(&onAppActivate));
    _ = gtk.g_application_run(@ptrCast(app), 0, null);
    gtk.g_object_unref(app);

    return;
}

fn registerTypes() void {
    _ = gtk.registerType(example_widget.ExampleWidget, example_widget.ExampleWidgetClass);
}

fn initBuilder() !void {
    const b = gtk.gtk_builder_new() orelse return AppError.InitializationFailed;

    var err: [*c]gtk.GError = null;
    if (gtk.gtk_builder_add_from_string(b, builder_ui, builder_ui.len, &err) == 0) {
        gtk.g_printerr("Error loading file: %s\n", err.*.message);
        gtk.g_clear_error(&err);
        return AppError.InitializationFailed;
    }

    builder = b;
}

fn onAppActivate() void {
    const app = application orelse return;

    const window = gtk.gtk_builder_get_object(builder orelse return, "window");
    gtk.gtk_window_set_application(@ptrCast(window), @ptrCast(app));
    gtk.gtk_window_set_default_size(@ptrCast(window), 400, 300);
    gtk.gtk_window_present(@ptrCast(window));

    const quit_btn = gtk.gtk_builder_get_object(builder orelse return, "quit");
    gtk.signalConnect(@ptrCast(quit_btn), "clicked", @ptrCast(&onAppQuit));

    gtk.g_print("Activated\n");
}

fn onAppQuit() void {
    const app = application orelse return;

    gtk.g_application_quit(@ptrCast(app));
}
