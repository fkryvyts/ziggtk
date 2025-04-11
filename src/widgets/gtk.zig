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

const resource_prefix = "/com/github/fkryvyts/Ziggtk/";
const application_id = "com.github.fkryvyts.Ziggtk";

pub const GtkScrollablePolicyEnum = enum(c_int) {
    MINIMUM = c.GTK_SCROLL_MINIMUM,
    NATURAL = c.GTK_SCROLL_NATURAL,
};

pub fn installResources(comptime resource_path: []const u8) !void {
    const res_data = @embedFile(resource_path);

    const res_bytes = c.g_bytes_new_static(res_data, res_data.len);

    var err: [*c]c.GError = null;
    const res = c.g_resource_new_from_data(res_bytes, &err);
    if (err != null) {
        printAndCleanError(&err, "Error loading resource");
        return errors.err.InitializationFailed;
    }

    c.g_resources_register(res);

    defer c.g_resource_unref(res);
}

pub fn signalConnect(instance: c.gpointer, detailed_signal: []const u8, c_handler: c.GCallback, data: c.gpointer) void {
    _ = c.g_signal_connect_data(instance, detailed_signal.ptr, c_handler, data, null, 0);
}

pub fn signalConnectSwapped(instance: c.gpointer, detailed_signal: []const u8, c_handler: c.GCallback, data: c.gpointer) c.gulong {
    return c.g_signal_connect_data(instance, detailed_signal.ptr, c_handler, data, null, c.G_CONNECT_SWAPPED);
}

pub fn setTemplate(widget_class: anytype, comptime widget_ui_res_name: []const u8) void {
    const res_path = resource_prefix ++ widget_ui_res_name;
    c.gtk_widget_class_set_template_from_resource(@ptrCast(widget_class), res_path.ptr);
    //c.gtk_widget_class_set_layout_manager_type(@ptrCast(widget_class), c.gtk_bin_layout_get_type());
}

pub fn bindTemplateChildren(widget_class: anytype, comptime widget_type: type, comptime names: []const []const u8) void {
    inline for (names) |name| {
        bindTemplateChild(widget_class, widget_type, name);
    }
}

pub fn bindProperties(widget_class: anytype, comptime widget_type: type, comptime props: []const []const u8) void {
    propertiesBinder(widget_type, props).bind(@ptrCast(widget_class));
}

pub const Action = struct {
    n: []const u8,
    f: c.GtkWidgetActionActivateFunc,
};

pub fn bindActions(widget_class: anytype, actions: []const Action) void {
    for (actions) |action| {
        c.gtk_widget_class_install_action(@ptrCast(widget_class), action.n.ptr, null, action.f);
    }
}

pub fn registerType(parent_type: c.GType, comptime T: type, comptime CT: type) c.GType {
    const type_name = widgetTypeName(T);
    return c.g_type_register_static_simple(parent_type, type_name.ptr, @sizeOf(CT), @ptrCast(&(CT).init), @sizeOf(T), @ptrCast(&(T).init), 0);
}

pub fn newBuilder(comptime builder_ui_res_name: []const u8) !*c.GtkBuilder {
    const b = c.gtk_builder_new() orelse return errors.err.InitializationFailed;
    const res_path = resource_prefix ++ builder_ui_res_name;

    var err: [*c]c.GError = null;
    if (c.gtk_builder_add_from_resource(b, res_path.ptr, &err) == 0) {
        printAndCleanError(&err, "Error loading file");
        return errors.err.InitializationFailed;
    }

    return b;
}

pub fn printAndCleanError(err: [*c][*c]c.GError, message: []const u8) void {
    if (err.* != null) {
        c.g_printerr("%s: %s\n", message.ptr, err.*.*.message);
    }

    c.g_clear_error(err);
}

pub fn getBuilderObject(builder: ?*c.GtkBuilder, name: []const u8) !*c.GObject {
    return c.gtk_builder_get_object(builder, name.ptr) orelse return errors.err.InitializationFailed;
}

pub fn newApplication() !*c.GApplication {
    const app = c.adw_application_new(application_id, c.G_APPLICATION_DEFAULT_FLAGS) orelse return errors.err.InitializationFailed;
    return @ptrCast(app);
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

fn bindTemplateChild(widget_class: anytype, comptime widget_type: type, comptime name: []const u8) void {
    c.gtk_widget_class_bind_template_child_full(@ptrCast(widget_class), name.ptr, 0, @offsetOf(widget_type, name));
}

fn propertiesBinder(comptime widget_type: type, comptime props: []const []const u8) type {
    return struct {
        const strct = @This();

        pub fn bind(widget_class: *c.GtkWidgetClass) void {
            widget_class.parent_class.set_property = @ptrCast(&strct.onSetProperty);
            widget_class.parent_class.get_property = @ptrCast(&strct.onGetProperty);

            inline for (0..(props.len)) |i| {
                const property_id = i + 1;

                switch (@FieldType(widget_type, props[i])) {
                    bool => {
                        installBoolProp(widget_class, property_id, props[i]);
                    },
                    GtkScrollablePolicyEnum => {
                        installEnumProp(widget_class, property_id, props[i], c.gtk_scrollable_policy_get_type());
                    },
                    else => {
                        const tn = comptime builtinWidgetTypeName(@FieldType(widget_type, props[i]));
                        installObjectProp(widget_class, property_id, props[i], @field(c, camelToSnake(tn) ++ "_get_type")());
                    },
                }
            }
        }

        pub fn onSetProperty(self: *widget_type, property_id: c.guint, val: *const c.GValue, _: *c.GParamSpec) callconv(.c) void {
            inline for (0..(props.len)) |i| {
                if (property_id == i + 1) {
                    switch (@FieldType(widget_type, props[i])) {
                        bool => {
                            @field(self, props[i]) = c.g_value_get_boolean(val) > 0;
                        },
                        GtkScrollablePolicyEnum => {
                            @field(self, props[i]) = @enumFromInt(c.g_value_get_enum(val));
                        },
                        else => {
                            const p = c.g_value_get_object(val);
                            @field(self, props[i]) = @ptrCast(@alignCast(p));
                        },
                    }

                    // const call_name = comptime snakeToCamel(props[i]);
                    // if (@hasDecl(widget_type, "onSetProperty" ++ call_name)) {
                    //     @field(widget_type, "onSetProperty" ++ call_name)(self);
                    // }

                    return;
                }
            }
        }

        pub fn onGetProperty(self: *widget_type, property_id: c.guint, val: *c.GValue, _: *c.GParamSpec) callconv(.c) void {
            inline for (0..(props.len)) |i| {
                if (property_id == i + 1) {
                    switch (@FieldType(widget_type, props[i])) {
                        bool => {
                            c.g_value_set_boolean(val, @intFromBool(@field(self, props[i])));
                        },
                        GtkScrollablePolicyEnum => {
                            c.g_value_set_enum(val, @intFromEnum((@field(self, props[i]))));
                        },
                        else => {
                            c.g_value_set_object(val, @ptrCast(@field(self, props[i])));
                        },
                    }

                    return;
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

fn installEnumProp(widget_class: anytype, property_id: c.guint, name: []const u8, enum_type: c.GType) void {
    const spec = c.g_param_spec_enum(name.ptr, null, null, enum_type, 0, c.G_PARAM_READWRITE);
    defer c.g_param_spec_unref(spec);
    c.g_object_class_install_property(@ptrCast(widget_class), property_id, spec);
}

fn installObjectProp(widget_class: anytype, property_id: c.guint, name: []const u8, object_type: c.GType) void {
    const spec = c.g_param_spec_object(name.ptr, null, null, object_type, c.G_PARAM_READWRITE);
    defer c.g_param_spec_unref(spec);
    c.g_object_class_install_property(@ptrCast(widget_class), property_id, spec);
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

fn builtinWidgetTypeName(comptime T: type) []const u8 {
    const type_name = @typeName(T);
    var index: usize = 0;

    // Remove struct__ prefix
    if (std.mem.indexOf(u8, type_name, "struct__")) |num| {
        index = num + 8;
    }

    return type_name[index..];
}

fn snakeToCamel(comptime name: []const u8) []const u8 {
    var res = std.mem.zeroes([name.len]u8);
    var ii = 0;
    var i = 0;

    while (i < name.len) : (i += 1) {
        if ((i > 0) and (name[i - 1] == '_')) {
            res[ii] = std.ascii.toUpper(name[i]);
            ii += 1;
            continue;
        }

        if (i == 0) {
            res[ii] = std.ascii.toUpper(name[i]);
            ii += 1;
            continue;
        }

        if (name[i] != '_') {
            res[ii] = name[i];
            ii += 1;
            continue;
        }
    }

    return res[0..ii];
}

fn camelToSnake(comptime name: []const u8) []const u8 {
    var sz = 0;
    for (name) |ch| {
        sz += 1;
        if (std.ascii.isUpper(ch)) {
            sz += 1;
        }
    }

    var res = std.mem.zeroes([sz]u8);
    var ii = 0;
    var i = 0;

    while (i < name.len) : (i += 1) {
        if (i > 0 and std.ascii.isUpper(name[i])) {
            res[ii] = '_';
            ii += 1;
        }

        res[ii] = std.ascii.toLower(name[i]);
        ii += 1;
    }

    return res[0..ii];
}
