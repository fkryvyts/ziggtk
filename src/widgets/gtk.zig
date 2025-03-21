pub usingnamespace @cImport({
    @cInclude("gtk/gtk.h");
    @cInclude("adwaita.h");
});

const c = @cImport({
    @cInclude("gtk/gtk.h");
    @cInclude("adwaita.h");
});

const std = @import("std");

pub const errors = error{
    InitializationFailed,
};

pub fn signalConnect(instance: c.gpointer, detailed_signal: []const u8, c_handler: c.GCallback) void {
    _ = c.g_signal_connect_data(instance, detailed_signal.ptr, c_handler, null, null, 0);
}

pub fn signalConnectSwapped(instance: c.gpointer, detailed_signal: []const u8, c_handler: c.GCallback, data: c.gpointer) c.gulong {
    return c.g_signal_connect_data(instance, detailed_signal.ptr, c_handler, data, null, c.G_CONNECT_SWAPPED);
}

pub fn setCssStyleSheet(comptime css_path: []const u8) void {
    const widget_ui = @embedFile(css_path);

    const cssProvider = c.gtk_css_provider_new();
    defer c.g_object_unref(cssProvider);

    c.gtk_css_provider_load_from_data(@ptrCast(cssProvider), widget_ui, widget_ui.len);
    c.gtk_style_context_add_provider_for_display(c.gdk_display_get_default(), @ptrCast(cssProvider), c.GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
}

pub fn setTemplate(widget_class: anytype, comptime widget_ui_path: []const u8) void {
    const widget_ui = @embedFile(widget_ui_path);

    const template = c.g_bytes_new(widget_ui, widget_ui.len);
    defer c.g_free(template);

    c.gtk_widget_class_set_template(@ptrCast(widget_class), template);
    c.gtk_widget_class_set_layout_manager_type(@ptrCast(widget_class), c.gtk_bin_layout_get_type());
}

pub fn bindTemplateChild(widget_class: anytype, comptime widget_type: type, comptime name: []const u8) void {
    c.gtk_widget_class_bind_template_child_full(@ptrCast(widget_class), name.ptr, 0, @offsetOf(widget_type, name));
}

pub fn registerType(parent_type: c.GType, comptime T: type, comptime CT: type) c.GType {
    const type_name = widgetTypeName(T);
    return c.g_type_register_static_simple(parent_type, type_name.ptr, @sizeOf(CT), @ptrCast(&(CT).init), @sizeOf(T), @ptrCast(&(T).init), 0);
}

pub fn newBuilder(comptime builder_ui_path: []const u8) !*c.GtkBuilder {
    const builder_ui = @embedFile(builder_ui_path);
    const b = c.gtk_builder_new() orelse return errors.InitializationFailed;

    var err: [*c]c.GError = null;
    if (c.gtk_builder_add_from_string(b, builder_ui, builder_ui.len, &err) == 0) {
        c.g_printerr("Error loading file: %s\n", err.*.message);
        c.g_clear_error(&err);
        return errors.InitializationFailed;
    }

    return b;
}

pub fn getBuilderObject(builder: ?*c.GtkBuilder, name: []const u8) !*c.GObject {
    return c.gtk_builder_get_object(builder, name.ptr) orelse return errors.InitializationFailed;
}

pub fn newApplication() !*c.GtkApplication {
    return c.gtk_application_new("org.gtk.example", c.G_APPLICATION_DEFAULT_FLAGS) orelse return errors.InitializationFailed;
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
