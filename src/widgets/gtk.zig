pub usingnamespace @cImport({
    @cInclude("gtk/gtk.h");
    @cInclude("adwaita.h");
});

const c = @cImport({
    @cInclude("gtk/gtk.h");
    @cInclude("adwaita.h");
});

const std = @import("std");
const errors = @import("errors.zig");

pub fn signalConnect(instance: c.gpointer, detailed_signal: []const u8, c_handler: c.GCallback, data: c.gpointer) void {
    _ = c.g_signal_connect_data(instance, detailed_signal.ptr, c_handler, data, null, 0);
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
    const b = c.gtk_builder_new() orelse return errors.err.InitializationFailed;

    var err: [*c]c.GError = null;
    if (c.gtk_builder_add_from_string(b, builder_ui, builder_ui.len, &err) == 0) {
        printAndCleanError(&err, "Error loading file");
        return errors.err.InitializationFailed;
    }

    return b;
}

pub fn printAndCleanError(err: [*c][*c]c.GError, message: []const u8) void {
    c.g_printerr("%s: %s\n", message.ptr, err.*.*.message);
    c.g_clear_error(err);
}

pub fn getBuilderObject(builder: ?*c.GtkBuilder, name: []const u8) !*c.GObject {
    return c.gtk_builder_get_object(builder, name.ptr) orelse return errors.err.InitializationFailed;
}

pub fn newApplication() !*c.GtkApplication {
    return c.gtk_application_new("org.gtk.example", c.G_APPLICATION_DEFAULT_FLAGS) orelse return errors.err.InitializationFailed;
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

pub fn boolAsGValue(v: bool) c.GValue {
    var val = std.mem.zeroes(c.GValue);
    _ = c.g_value_init(&val, c.G_TYPE_BOOLEAN);
    c.g_value_set_boolean(&val, @intFromBool(v));
    return val;
}

pub fn propertiesBinder(comptime T: type, comptime props: []const []const u8) type {
    return struct {
        const strct = @This();

        pub fn bind(widget_class: *c.GtkWidgetClass) void {
            widget_class.parent_class.set_property = @ptrCast(&strct.onSetProperty);
            widget_class.parent_class.get_property = @ptrCast(&strct.onGetProperty);

            inline for (0..(props.len)) |i| {
                const property_id = i + 1;

                switch (@FieldType(T, props[i])) {
                    bool => {
                        installBoolProp(widget_class, property_id, props[i]);
                    },
                    else => {},
                }
            }
        }

        pub fn onSetProperty(self: *T, property_id: c.guint, val: *const c.GValue, _: *c.GParamSpec) callconv(.c) void {
            inline for (0..(props.len)) |i| {
                switch (@FieldType(T, props[i])) {
                    bool => {
                        if (property_id == i + 1) {
                            getBoolPropFrom(@constCast(&@field(self, props[i])), val);
                        }
                    },
                    else => {},
                }
            }
        }

        pub fn onGetProperty(self: *T, property_id: c.guint, val: *c.GValue, _: *c.GParamSpec) callconv(.c) void {
            inline for (0..(props.len)) |i| {
                switch (@FieldType(T, props[i])) {
                    bool => {
                        if (property_id == i + 1) {
                            setBoolPropTo(@field(self, props[i]), val);
                        }
                    },
                    else => {},
                }
            }
        }
    };
}

fn installBoolProp(widget_class: anytype, property_id: c.guint, name: []const u8) void {
    const spec = c.g_param_spec_boolean(name.ptr, null, null, 0, c.G_PARAM_READWRITE);
    defer c.g_param_spec_unref(spec);
    c.g_object_class_install_property(@ptrCast(widget_class), property_id, spec);
}

fn getBoolPropFrom(prop: *bool, val: *const c.GValue) void {
    prop.* = c.g_value_get_boolean(val) > 0;
}

fn setBoolPropTo(prop: bool, val: *c.GValue) void {
    c.g_value_set_boolean(val, @intFromBool(prop));
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
