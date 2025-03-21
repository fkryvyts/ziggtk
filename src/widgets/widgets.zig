const std = @import("std");
const gtk = @import("gtk.zig");
const image_view = @import("image_view.zig");
const image_page = @import("image_page.zig");
const image_book = @import("image_book.zig");
const error_details = @import("error_details.zig");

var application: ?*gtk.GtkApplication = null;
var window: ?*gtk.GtkWindow = null;
var dialog: ?*error_details.ZvErrorDetails = null;
var img_book: ?*image_book.ZvImageBook = null;

pub fn runApp() !void {
    gtk.adw_init();
    registerTypes();

    gtk.setCssStyleSheet("resources/style.css");

    const b = try gtk.newBuilder("resources/builder.ui");
    defer gtk.g_object_unref(b);

    const app = try gtk.newApplication();
    const w: *gtk.GtkWindow = @ptrCast(try gtk.getBuilderObject(b, "window"));
    const dg: *error_details.ZvErrorDetails = @ptrCast(try gtk.getBuilderObject(b, "error_details"));
    const quit_btn: *gtk.GtkButton = @ptrCast(try gtk.getBuilderObject(b, "quit"));
    const ib: *image_book.ZvImageBook = @ptrCast(try gtk.getBuilderObject(b, "image_book"));

    gtk.gtk_window_set_default_size(w, 400, 300);

    gtk.signalConnect(quit_btn, "clicked", &onQuitBtnClick, null);
    gtk.signalConnect(app, "activate", &onAppActivate, null);

    application = app;
    window = w;
    dialog = dg;
    img_book = ib;

    const thread = try std.Thread.spawn(.{}, loadImage, .{});
    defer thread.join();

    _ = gtk.g_application_run(@ptrCast(app), 0, null);
}

fn registerTypes() void {
    _ = image_view.registerType();
    _ = image_page.registerType();
    _ = image_book.registerType();
    _ = error_details.registerType();
}

fn onAppActivate() callconv(.c) void {
    const app = application orelse return;
    const w = window orelse return;
    const dg = dialog orelse return;

    gtk.gtk_window_set_application(w, app);
    gtk.gtk_window_present(w);
    gtk.adw_dialog_present(@ptrCast(dg), null);

    std.debug.print("Activated", .{});
}

fn onQuitBtnClick() callconv(.c) void {
    const app = application orelse return;

    gtk.g_application_quit(@ptrCast(app));
}

fn loadImage() !void {
    const ib = img_book orelse return;
    ib.loadImage("/home/fedir/Downloads/image2.jpg");
}
