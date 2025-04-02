const std = @import("std");
const gtk = @import("gtk.zig");
const image_view = @import("image_view.zig");
const image_page = @import("image_page.zig");
const image_book = @import("image_book.zig");
const error_details = @import("error_details.zig");
const properties_view = @import("properties_view.zig");
const drag_overlay = @import("drag_overlay.zig");
const shy_bin = @import("shy_bin.zig");
const image_window = @import("image_window.zig");
const loader = @import("../decoders/loader.zig");

var application: ?*gtk.GApplication = null;
var img_window: ?*image_window.ZvImageWindow = null;
var err_dialog: ?*error_details.ZvErrorDetails = null;

pub fn runApp() !void {
    gtk.adw_init();
    registerTypes();

    try gtk.installResources("resources/gresources.gresource");

    const b = try gtk.newBuilder("ui/builder.xml");
    defer gtk.g_object_unref(b);

    const app = try gtk.newApplication();
    const w: *image_window.ZvImageWindow = @ptrCast(try gtk.getBuilderObject(b, "image_window"));
    const dg: *error_details.ZvErrorDetails = @ptrCast(try gtk.getBuilderObject(b, "error_details"));

    gtk.signalConnect(app, "activate", &onAppActivate, null);

    application = app;
    img_window = w;
    err_dialog = dg;

    try loader.default_loader.init(std.heap.page_allocator);
    defer loader.default_loader.deinit();

    _ = gtk.g_application_run(app, 0, null);
}

fn registerTypes() void {
    _ = image_view.registerType();
    _ = image_page.registerType();
    _ = image_book.registerType();
    _ = error_details.registerType();
    _ = properties_view.registerType();
    _ = drag_overlay.registerType();
    _ = shy_bin.registerType();
    _ = image_window.registerType();
}

fn onAppActivate() callconv(.c) void {
    const app = application orelse return;
    const w = img_window orelse return;
    //const dg = err_dialog orelse return;

    gtk.gtk_window_set_application(@ptrCast(w), @ptrCast(app));
    gtk.gtk_window_present(@ptrCast(w));
    //gtk.adw_dialog_present(@ptrCast(dg), null);

    std.debug.print("Activated", .{});
}
