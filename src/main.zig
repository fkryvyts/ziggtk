const gtk = @import("widgets/gtk.zig");
const widgets = @import("widgets/widgets.zig");
const std = @import("std");

pub fn main() u8 {
    const app = gtk.gtk_application_new("org.gtk.example", gtk.G_APPLICATION_DEFAULT_FLAGS);
    _ = gtk.signalConnect(app, "activate", @ptrCast(&widgets.activate), null);
    _ = gtk.g_application_run(@ptrCast(app), 0, null);
    gtk.g_object_unref(app);

    return 0;
}
