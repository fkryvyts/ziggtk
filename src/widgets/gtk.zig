pub usingnamespace @cImport({
    @cInclude("gtk/gtk.h");
    @cInclude("adwaita.h");
});

const c = @cImport({
    @cInclude("gtk/gtk.h");
    @cInclude("adwaita.h");
});

const std = @import("std");

pub fn signalConnect(instance: c.gpointer, detailed_signal: [*c]const c.gchar, c_handler: c.GCallback) void {
    _ = c.g_signal_connect_data(instance, detailed_signal, c_handler, null, null, 0);
}

pub fn signalConnectSwapped(instance: c.gpointer, detailed_signal: [*c]const c.gchar, c_handler: c.GCallback, data: c.gpointer) c.gulong {
    return c.g_signal_connect_data(instance, detailed_signal, c_handler, data, null, c.G_CONNECT_SWAPPED);
}

pub fn setTemplate(widget_class: anytype, comptime widget_ui_path: []const u8) void {
    const widget_ui = @embedFile(widget_ui_path);
    const template = c.g_bytes_new(widget_ui, widget_ui.len);
    c.gtk_widget_class_set_template(@ptrCast(widget_class), template);
    c.gtk_widget_class_set_layout_manager_type(@ptrCast(widget_class), c.gtk_bin_layout_get_type());
}

pub fn bindTemplateChild(widget_class: anytype, comptime widget_type: type, comptime name: []const u8) void {
    c.gtk_widget_class_bind_template_child_full(@ptrCast(widget_class), name.ptr, 0, @offsetOf(widget_type, name));
}

pub fn registerType(parent_type: c.GType, comptime T: type, comptime CT: type) c.GType {
    const type_name = widgetTypeName(T);

    std.debug.print("Type name: {s}\n", .{type_name});

    return c.g_type_register_static_simple(parent_type, type_name.ptr, @sizeOf(CT), @ptrCast(&(CT).init), @sizeOf(T), @ptrCast(&(T).init), 0);
}

pub fn widgetParentOfType(widget: *c.GtkWidget, comptime T: type) ?*T {
    var parent = c.gtk_widget_get_parent(widget);

    while (parent != null) {
        const parent_name = c.gtk_widget_get_name(parent);

        if (std.mem.eql(u8, std.mem.span(parent_name), widgetTypeName(T))) {
            return @ptrCast(parent);
        }

        parent = c.gtk_widget_get_parent(parent);
    }

    return null;
}

fn widgetTypeName(comptime T: type) []const u8 {
    const type_name = @typeName(T);
    var index: usize = 0;

    // Remove package prefix
    if (std.mem.lastIndexOf(u8, type_name, ".")) |num| {
        index = num + 1;
    }

    return type_name[index..];
}
