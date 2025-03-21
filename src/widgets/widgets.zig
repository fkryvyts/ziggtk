const std = @import("std");
const gtk = @import("gtk.zig");
const image_view = @import("image_view.zig");
const image_page = @import("image_page.zig");
const error_details = @import("error_details.zig");

var application: ?*gtk.GtkApplication = null;
var window: ?*gtk.GtkWindow = null;
var dialog: ?*gtk.AdwDialog = null;

pub fn runApp() !void {
    gtk.adw_init();
    registerTypes();

    gtk.setCssStyleSheet("resources/style.css");

    const b = try gtk.newBuilder("resources/builder.ui");
    defer gtk.g_object_unref(b);

    const app = try gtk.newApplication();
    const w = try gtk.getBuilderObject(b, "window");
    const dg = try gtk.getBuilderObject(b, "error_details");
    const quit_btn = try gtk.getBuilderObject(b, "quit");

    gtk.gtk_window_set_default_size(@ptrCast(w), 400, 300);

    gtk.signalConnect(quit_btn, "clicked", &onQuitBtnClick);
    gtk.signalConnect(app, "activate", &onAppActivate);

    application = app;
    window = @ptrCast(w);
    dialog = @ptrCast(dg);

    _ = gtk.g_application_run(@ptrCast(app), 0, null);
}

fn registerTypes() void {
    _ = image_view.registerType();
    _ = image_page.registerType();
    _ = error_details.registerType();
}

fn onAppActivate() callconv(.c) void {
    const app = application orelse return;
    const w = window orelse return;
    const dg = dialog orelse return;

    gtk.gtk_window_set_application(w, app);
    gtk.gtk_window_present(w);
    gtk.adw_dialog_present(dg, null);

    std.debug.print("Activated", .{});
}

fn onQuitBtnClick() callconv(.c) void {
    const app = application orelse return;

    gtk.g_application_quit(@ptrCast(app));
}
