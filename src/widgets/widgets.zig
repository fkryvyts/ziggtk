const std = @import("std");
const gtk = @import("../gtk/gtk.zig");
const gtkx = @import("../gtk/gtkx.zig");
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

pub fn runApp() !void {
    gtk.adw_init();
    registerTypes();

    try gtkx.installResources(@embedFile("resources/gresources.gresource"));

    try loader.default_loader.init(std.heap.page_allocator);
    defer loader.default_loader.deinit();

    const b = try gtkx.newBuilder("ui/builder.xml");
    defer gtk.g_object_unref(b);

    const app = try gtkx.newApplication();
    const w: *image_window.ZvImageWindow = @ptrCast(try gtkx.getBuilderObject(b, "image_window"));

    gtkx.signalConnect(app, "activate", &onAppActivate, null);

    application = app;
    img_window = w;

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

    gtk.gtk_window_set_application(@ptrCast(w), @ptrCast(app));
    gtk.gtk_window_present(@ptrCast(w));

    std.debug.print("Activated", .{});
}
