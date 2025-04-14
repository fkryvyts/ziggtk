const std = @import("std");
const gtk = @import("gtk.zig");
const errors = @import("errors.zig");
const images = @import("../decoders/images.zig");

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
    image: ?*images.Image,
    zoom: f32,
    last_frame_time: gtk.gint64,
    current_frame: u32,
    max_frames: u32,
    tick_callback_id: gtk.guint,

    pub fn init(self: *ZvImageView) callconv(.c) void {
        self.zoom = 1.0;
        self.current_frame = 0;
        self.max_frames = 1;
        self.tick_callback_id = 0;

        gtk.signalConnect(self, "notify::hadjustment", @ptrCast(&ZvImageView.onNotifyHadjustment), null);
        gtk.signalConnect(self, "notify::vadjustment", @ptrCast(&ZvImageView.onNotifyVadjustment), null);
    }

    pub fn setZoom(self: *ZvImageView, zoom: f32) void {
        self.zoom = zoom;
        self.configureAjustments();
        gtk.gtk_widget_queue_draw(@ptrCast(self));
    }

    pub fn setImage(self: *ZvImageView, image: ?*images.Image) void {
        if (self.image) |img| {
            img.destroy();
        }

        self.image = image;
        self.current_frame = 0;

        if (self.tick_callback_id != 0) {
            gtk.gtk_widget_remove_tick_callback(@ptrCast(self), self.tick_callback_id);
        }

        if (image) |img| {
            self.max_frames = @intCast(img.framesCount());
        }

        if (self.max_frames > 1) {
            self.tick_callback_id = gtk.gtk_widget_add_tick_callback(@ptrCast(self), @ptrCast(&ZvImageView.onTick), null, null);
        }

        self.configureAjustments();
    }

    fn onTick(self: *ZvImageView, clock: *gtk.GdkFrameClock) callconv(.c) void {
        const img = self.image orelse return;
        const current_frame_time = gtk.gdk_frame_clock_get_frame_time(clock);
        const delay: u64 = img.frames.items[self.current_frame].delay;
        const dur = (current_frame_time - self.last_frame_time) * std.time.ns_per_us;

        if ((delay == 0) or (dur < delay)) {
            return;
        }

        var frame = self.current_frame + 1;
        if (frame >= self.max_frames) {
            frame = 0;
        }

        self.current_frame = frame;
        self.last_frame_time = current_frame_time;
        gtk.gtk_widget_queue_draw(@ptrCast(self));
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

    // Configures scroll bars around the widget
    fn configureAjustments(self: *ZvImageView) void {
        const img = self.image orelse return;
        const img_width: f64 = img.width() * self.zoom;
        const img_height: f64 = img.height() * self.zoom;
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

    // Called when widget is resized
    fn onSizeAllocate(self: *ZvImageView, _: c_int, _: c_int, _: c_int) callconv(.c) void {
        self.configureAjustments();
    }

    // Called when widget needs redrawing
    fn onSnapshot(self: *ZvImageView, snapshot: *gtk.GtkSnapshot) callconv(.c) void {
        const img = self.image orelse return;
        const img_width: f64 = img.width() * self.zoom;
        const img_height: f64 = img.height() * self.zoom;
        const widget_width: f64 = @floatFromInt(gtk.gtk_widget_get_width(@ptrCast(self)));
        const widget_height: f64 = @floatFromInt(gtk.gtk_widget_get_height(@ptrCast(self)));
        const texture = img.frames.items[self.current_frame].texture;

        gtk.gtk_snapshot_save(snapshot);
        defer gtk.gtk_snapshot_restore(snapshot);

        // Background
        gtk.gtk_snapshot_append_color(snapshot, &background_color, &.{ .size = .{
            .width = @floatCast(widget_width),
            .height = @floatCast(widget_height),
        } });

        // Apply scrolling
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

        // Render image
        const area = gtk.graphene_rect_t{ .size = .{
            .width = @floatCast(img_width),
            .height = @floatCast(img_height),
        } };

        var filter = gtk.GSK_SCALING_FILTER_NEAREST;
        if (self.zoom <= 1) {
            filter = gtk.GSK_SCALING_FILTER_TRILINEAR;
        }

        gtk.gtk_snapshot_push_clip(snapshot, &area);
        gtk.gtk_snapshot_append_scaled_texture(snapshot, texture, @intCast(filter), &area);
        gtk.gtk_snapshot_pop(snapshot);
    }
};

pub fn registerType() gtk.GType {
    const t = gtk.registerType(gtk.gtk_widget_get_type(), ZvImageView, ZvImageViewClass);
    gtk.g_type_add_interface_static(t, gtk.gtk_scrollable_get_type(), &.{});
    return t;
}
