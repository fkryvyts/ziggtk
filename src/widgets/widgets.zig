const std = @import("std");
const gtk = @import("gtk.zig");
const image_page = @import("image_page.zig");
const error_details = @import("error_details.zig");
const builder_ui = @embedFile("resources/builder.ui");

const errors = error{
    InitializationFailed,
};

var builder: ?*gtk.GtkBuilder = null;
var application: ?*gtk.GtkApplication = null;

pub fn runApp() !void {
    gtk.adw_init();

    registerTypes();
    try initBuilder();

    application = gtk.gtk_application_new("org.gtk.example", gtk.G_APPLICATION_DEFAULT_FLAGS) orelse return errors.InitializationFailed;

    gtk.signalConnect(application, "activate", &onAppActivate);
    _ = gtk.g_application_run(@ptrCast(application), 0, null);
    gtk.g_object_unref(application);
}

fn registerTypes() void {
    _ = image_page.registerType();
    _ = error_details.registerType();
}

fn initBuilder() !void {
    builder = gtk.gtk_builder_new() orelse return errors.InitializationFailed;

    var err: [*c]gtk.GError = null;
    if (gtk.gtk_builder_add_from_string(builder, builder_ui, builder_ui.len, &err) == 0) {
        gtk.g_printerr("Error loading file: %s\n", err.*.message);
        gtk.g_clear_error(&err);
        return errors.InitializationFailed;
    }
}

fn onAppActivate() callconv(.c) void {
    const app = application orelse return;
    const b = builder orelse return;

    const window: ?*gtk.GtkWindow = @ptrCast(gtk.gtk_builder_get_object(b, "window"));
    const w = window orelse return;
    gtk.gtk_window_set_application(w, app);
    gtk.gtk_window_set_default_size(w, 400, 300);
    gtk.gtk_window_present(w);

    const quit_btn = gtk.gtk_builder_get_object(b, "quit");
    gtk.signalConnect(quit_btn, "clicked", &onAppQuit);

    const dialog: ?*gtk.AdwDialog = @ptrCast(gtk.gtk_builder_get_object(b, "error_details"));
    gtk.adw_dialog_present(dialog, null);

    std.debug.print("Activated", .{});
}

fn onAppQuit() callconv(.c) void {
    const app = application orelse return;

    gtk.g_application_quit(@ptrCast(app));
}
