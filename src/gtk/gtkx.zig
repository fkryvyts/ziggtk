const std = @import("std");
const errors = @import("errors.zig");
const gtk = @import("gtk.zig");

const resource_prefix = "/com/github/fkryvyts/Ziggtk/";
const application_id = "com.github.fkryvyts.Ziggtk";

pub const GtkScrollablePolicyEnum = enum(c_int) {
    MINIMUM = gtk.GTK_SCROLL_MINIMUM,
    NATURAL = gtk.GTK_SCROLL_NATURAL,
};

pub fn installResources(comptime res_data: []const u8) !void {
    const res_bytes = gtk.g_bytes_new_static(res_data.ptr, res_data.len);

    var err: [*c]gtk.GError = null;
    const res = gtk.g_resource_new_from_data(res_bytes, &err);
    if (err != null) {
        printAndCleanError(&err, "Error loading resource");
        return errors.err.InitializationFailed;
    }

    gtk.g_resources_register(res);

    defer gtk.g_resource_unref(res);
}

pub fn signalConnect(instance: gtk.gpointer, detailed_signal: []const u8, c_handler: gtk.GCallback, data: gtk.gpointer) void {
    _ = gtk.g_signal_connect_data(instance, detailed_signal.ptr, c_handler, data, null, 0);
}

pub fn signalConnectSwapped(instance: gtk.gpointer, detailed_signal: []const u8, c_handler: gtk.GCallback, data: gtk.gpointer) gtk.gulong {
    return gtk.g_signal_connect_data(instance, detailed_signal.ptr, c_handler, data, null, gtk.G_CONNECT_SWAPPED);
}

pub fn setTemplate(widget_class: anytype, comptime widget_ui_res_name: []const u8) void {
    const res_path = resource_prefix ++ widget_ui_res_name;
    gtk.gtk_widget_class_set_template_from_resource(@ptrCast(widget_class), res_path.ptr);
    //gtk.gtk_widget_class_set_layout_manager_type(@ptrCast(widget_class), gtk.gtk_bin_layout_get_type());
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
    f: gtk.GtkWidgetActionActivateFunc,
};

pub fn bindActions(widget_class: anytype, actions: []const Action) void {
    for (actions) |action| {
        gtk.gtk_widget_class_install_action(@ptrCast(widget_class), action.n.ptr, null, action.f);
    }
}

pub fn registerType(parent_type: gtk.GType, comptime T: type, comptime CT: type) gtk.GType {
    const type_name = widgetTypeName(T);
    return gtk.g_type_register_static_simple(parent_type, type_name.ptr, @sizeOf(CT), @ptrCast(&(CT).init), @sizeOf(T), @ptrCast(&(T).init), 0);
}

pub fn newBuilder(comptime builder_ui_res_name: []const u8) !*gtk.GtkBuilder {
    const b = gtk.gtk_builder_new() orelse return errors.err.InitializationFailed;
    const res_path = resource_prefix ++ builder_ui_res_name;

    var err: [*c]gtk.GError = null;
    if (gtk.gtk_builder_add_from_resource(b, res_path.ptr, &err) == 0) {
        printAndCleanError(&err, "Error loading file");
        return errors.err.InitializationFailed;
    }

    return b;
}

pub fn printAndCleanError(err: [*c][*c]gtk.GError, message: []const u8) void {
    if (err.* != null) {
        gtk.g_printerr("%s: %s\n", message.ptr, err.*.*.message);
    }

    gtk.g_clear_error(err);
}

pub fn getBuilderObject(builder: ?*gtk.GtkBuilder, name: []const u8) !*gtk.GObject {
    return gtk.gtk_builder_get_object(builder, name.ptr) orelse return errors.err.InitializationFailed;
}

pub fn newApplication() !*gtk.GApplication {
    const app = gtk.adw_application_new(application_id, gtk.G_APPLICATION_DEFAULT_FLAGS) orelse return errors.err.InitializationFailed;
    return @ptrCast(app);
}

pub fn widgetParentOfType(widget: *gtk.GtkWidget, comptime T: type) ?*T {
    var parent = gtk.gtk_widget_get_parent(widget);

    while (parent != null) {
        const parent_name = gtk.gtk_widget_get_name(parent);

        if (std.mem.eql(u8, std.mem.span(parent_name), widgetTypeName(T))) {
            return @ptrCast(parent);
        }

        parent = gtk.gtk_widget_get_parent(parent);
    }

    return null;
}

pub fn boolAsGValue(v: bool) gtk.GValue {
    var val = std.mem.zeroes(gtk.GValue);
    _ = gtk.g_value_init(&val, gtk.G_TYPE_BOOLEAN);
    gtk.g_value_set_boolean(&val, @intFromBool(v));
    return val;
}

fn bindTemplateChild(widget_class: anytype, comptime widget_type: type, comptime name: []const u8) void {
    gtk.gtk_widget_class_bind_template_child_full(@ptrCast(widget_class), name.ptr, 0, @offsetOf(widget_type, name));
}

fn propertiesBinder(comptime widget_type: type, comptime props: []const []const u8) type {
    return struct {
        const strct = @This();

        pub fn bind(widget_class: *gtk.GtkWidgetClass) void {
            widget_class.parent_class.set_property = @ptrCast(&strct.onSetProperty);
            widget_class.parent_class.get_property = @ptrCast(&strct.onGetProperty);

            inline for (0..(props.len)) |i| {
                const property_id = i + 1;

                switch (@FieldType(widget_type, props[i])) {
                    bool => {
                        installBoolProp(widget_class, property_id, props[i]);
                    },
                    GtkScrollablePolicyEnum => {
                        installEnumProp(widget_class, property_id, props[i], gtk.gtk_scrollable_policy_get_type());
                    },
                    else => {
                        const tn = comptime builtinWidgetTypeName(@FieldType(widget_type, props[i]));
                        installObjectProp(widget_class, property_id, props[i], @field(gtk, camelToSnake(tn) ++ "_get_type")());
                    },
                }
            }
        }

        pub fn onSetProperty(self: *widget_type, property_id: gtk.guint, val: *const gtk.GValue, _: *gtk.GParamSpec) callconv(.c) void {
            inline for (0..(props.len)) |i| {
                if (property_id == i + 1) {
                    switch (@FieldType(widget_type, props[i])) {
                        bool => {
                            @field(self, props[i]) = gtk.g_value_get_boolean(val) > 0;
                        },
                        GtkScrollablePolicyEnum => {
                            @field(self, props[i]) = @enumFromInt(gtk.g_value_get_enum(val));
                        },
                        else => {
                            const p = gtk.g_value_get_object(val);
                            @field(self, props[i]) = @ptrCast(@alignCast(p));
                        },
                    }

                    return;
                }
            }
        }

        pub fn onGetProperty(self: *widget_type, property_id: gtk.guint, val: *gtk.GValue, _: *gtk.GParamSpec) callconv(.c) void {
            inline for (0..(props.len)) |i| {
                if (property_id == i + 1) {
                    switch (@FieldType(widget_type, props[i])) {
                        bool => {
                            gtk.g_value_set_boolean(val, @intFromBool(@field(self, props[i])));
                        },
                        GtkScrollablePolicyEnum => {
                            gtk.g_value_set_enum(val, @intFromEnum((@field(self, props[i]))));
                        },
                        else => {
                            gtk.g_value_set_object(val, @ptrCast(@field(self, props[i])));
                        },
                    }

                    return;
                }
            }
        }
    };
}

fn installBoolProp(widget_class: anytype, property_id: gtk.guint, name: []const u8) void {
    const spec = gtk.g_param_spec_boolean(name.ptr, null, null, 0, gtk.G_PARAM_READWRITE);
    defer gtk.g_param_spec_unref(spec);
    gtk.g_object_class_install_property(@ptrCast(widget_class), property_id, spec);
}

fn installEnumProp(widget_class: anytype, property_id: gtk.guint, name: []const u8, enum_type: gtk.GType) void {
    const spec = gtk.g_param_spec_enum(name.ptr, null, null, enum_type, 0, gtk.G_PARAM_READWRITE);
    defer gtk.g_param_spec_unref(spec);
    gtk.g_object_class_install_property(@ptrCast(widget_class), property_id, spec);
}

fn installObjectProp(widget_class: anytype, property_id: gtk.guint, name: []const u8, object_type: gtk.GType) void {
    const spec = gtk.g_param_spec_object(name.ptr, null, null, object_type, gtk.G_PARAM_READWRITE);
    defer gtk.g_param_spec_unref(spec);
    gtk.g_object_class_install_property(@ptrCast(widget_class), property_id, spec);
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
