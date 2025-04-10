const std = @import("std");
const gtk = @import("gtk.zig");
const errors = @import("errors.zig");
const loader = @import("../decoders/loader.zig");

const background_color = gtk.GdkRGBA{ .red = 34 / 255, .green = 34 / 255, .blue = 38 / 255, .alpha = 1 };

pub const ZvImageViewClass = extern struct {
    parent_class: gtk.GtkWidgetClass,

    pub fn init(self: *ZvImageViewClass) callconv(.c) void {
        gtk.bindProperties(self, ZvImageView, &.{
            "hadjustment",
            "vadjustment",
            "vscroll_policy",
            "hscroll_policy",
        });

        self.parent_class.size_allocate = @ptrCast(&ZvImageView.onSizeAllocate);
        self.parent_class.snapshot = @ptrCast(&ZvImageView.onSnapshot);
    }
};

pub const ZvImageView = extern struct {
    parent_instance: gtk.GtkWidget,
    hadjustment: ?*gtk.GtkAdjustment,
    vadjustment: ?*gtk.GtkAdjustment,
    vscroll_policy: gtk.GtkScrollablePolicyEnum,
    hscroll_policy: gtk.GtkScrollablePolicyEnum,
    image: ?*loader.Image,

    pub fn init(self: *ZvImageView) callconv(.c) void {
        gtk.signalConnect(self, "notify::hadjustment", @ptrCast(&ZvImageView.onNotifyHadjustment), null);
        gtk.signalConnect(self, "notify::vadjustment", @ptrCast(&ZvImageView.onNotifyVadjustment), null);
    }

    pub fn setImage(self: *ZvImageView, image: ?*loader.Image) void {
        if (self.image) |img| {
            img.destroy();
        }

        self.image = image;
        self.configureAjustments();
    }

    fn onNotifyHadjustment(self: *ZvImageView) callconv(.c) void {
        gtk.signalConnect(self.hadjustment, "value-changed", @ptrCast(&ZvImageView.onAdjustmentValueChanged), self);
    }

    fn onNotifyVadjustment(self: *ZvImageView) callconv(.c) void {
        gtk.signalConnect(self.vadjustment, "value-changed", @ptrCast(&ZvImageView.onAdjustmentValueChanged), self);
    }

    fn onAdjustmentValueChanged(_: *gtk.GtkAdjustment, self: *ZvImageView) callconv(.c) void {
        gtk.gtk_widget_queue_draw(@ptrCast(self));
    }

    fn configureAjustments(self: *ZvImageView) void {
        const img = self.image orelse return;
        const img_width: f64 = img.width();
        const img_height: f64 = img.height();
        const widget_width: f64 = @floatFromInt(gtk.gtk_widget_get_width(@ptrCast(self)));
        const widget_height: f64 = @floatFromInt(gtk.gtk_widget_get_height(@ptrCast(self)));
        const hvalue = gtk.gtk_adjustment_get_value(self.hadjustment);
        const vvalue = gtk.gtk_adjustment_get_value(self.vadjustment);

        if ((widget_width == 0) or (widget_height == 0)) {
            return;
        }

        gtk.gtk_adjustment_configure(self.hadjustment, @min(hvalue, img_width), 0, img_width, widget_width * 0.1, widget_width * 0.9, @min(widget_width, img_width));
        gtk.gtk_adjustment_configure(self.vadjustment, @min(vvalue, img_height), 0, img_height, widget_height * 0.1, widget_height * 0.9, @min(widget_height, img_height));
    }

    fn onSizeAllocate(self: *ZvImageView, _: c_int, _: c_int, _: c_int) callconv(.c) void {
        self.configureAjustments();
    }

    fn onSnapshot(self: *ZvImageView, snapshot: *gtk.GtkSnapshot) callconv(.c) void {
        const img = self.image orelse return;
        const img_width: f32 = img.width();
        const img_height: f32 = img.height();
        const widget_width: f32 = @floatFromInt(gtk.gtk_widget_get_width(@ptrCast(self)));
        const widget_height: f32 = @floatFromInt(gtk.gtk_widget_get_height(@ptrCast(self)));

        // Background
        gtk.gtk_snapshot_append_color(snapshot, &background_color, &.{ .size = .{
            .width = widget_width,
            .height = widget_height,
        } });

        // Scroll bars
        const hvalue = gtk.gtk_adjustment_get_value(self.hadjustment);
        const hupper = gtk.gtk_adjustment_get_upper(self.hadjustment);
        gtk.gtk_snapshot_translate(snapshot, &.{ .x = @floatCast(-(hvalue - (hupper - img_width) / 2)) });

        const vvalue = gtk.gtk_adjustment_get_value(self.vadjustment);
        const vupper = gtk.gtk_adjustment_get_upper(self.vadjustment);
        gtk.gtk_snapshot_translate(snapshot, &.{ .y = @floatCast(-(vvalue - (vupper - img_height) / 2)) });

        // Center the image if it is too small
        const rendering_x = @max((widget_width - img_width) / 2, 0);
        const rendering_y = @max((widget_height - img_height) / 2, 0);

        gtk.gtk_snapshot_translate(snapshot, &.{ .x = @floatCast(rendering_x), .y = @floatCast(rendering_y) });

        // Actual image
        gtk.gtk_snapshot_append_texture(snapshot, img.image_texture, &.{ .size = .{
            .width = img_width,
            .height = img_height,
        } });
    }
};

pub fn registerType() gtk.GType {
    const t = gtk.registerType(gtk.gtk_widget_get_type(), ZvImageView, ZvImageViewClass);
    gtk.g_type_add_interface_static(t, gtk.gtk_scrollable_get_type(), &.{});
    return t;
}
