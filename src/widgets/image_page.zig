const std = @import("std");
const gtk = @import("gtk.zig");
const image_view = @import("image_view.zig");
const errors = @import("errors.zig");

pub const ZvImagePageClass = extern struct {
    parent_class: gtk.AdwBinClass,

    pub fn init(self: *ZvImagePageClass) callconv(.c) void {
        gtk.setTemplate(self, "ui/image_page.xml");
        gtk.bindTemplateChildren(self, ZvImagePage, &.{
            "stack",
            "spinner_page",
            "error_page",
            "image_stack_page",
            "image_view",
            "popover",
            "right_click_gesture",
            "press_gesture",
        });
    }
};

pub const ZvImagePage = extern struct {
    parent_instance: gtk.AdwBin,

    stack: *gtk.GtkStack,
    spinner_page: *gtk.GtkWidget,
    error_page: *gtk.GtkWidget,
    image_stack_page: *gtk.GtkWidget,
    image_view: *image_view.ZvImageView,
    popover: *gtk.GtkPopover,
    right_click_gesture: *gtk.GtkGesture,
    press_gesture: *gtk.GtkGesture,

    pub fn init(self: *ZvImagePage) callconv(.c) void {
        gtk.gtk_widget_init_template(@ptrCast(self));
        gtk.gtk_stack_set_visible_child(self.stack, self.spinner_page);

        gtk.signalConnect(self.right_click_gesture, "pressed", @ptrCast(&ZvImagePage.onRightClickGesture), self);
        gtk.signalConnect(self.press_gesture, "pressed", @ptrCast(&ZvImagePage.onLongPressGesture), self);
    }

    pub fn loadImage(self: *ZvImagePage, path: []const u8) void {
        gtk.gtk_stack_set_visible_child(self.stack, self.spinner_page);

        var err: [*c]gtk.GError = null;
        const image_texture = gtk.gdk_texture_new_from_filename(path.ptr, &err);

        if (err != null) {
            gtk.printAndCleanError(&err, "Failed to load image");
            gtk.gtk_stack_set_visible_child(self.stack, self.error_page);
            return;
        }

        self.image_view.setImageTexture(image_texture);
        gtk.gtk_stack_set_visible_child(self.stack, self.image_stack_page);
    }

    fn onRightClickGesture(g: *gtk.GtkGesture, _: c_int, x: f64, y: f64, self: *ZvImagePage) callconv(.c) void {
        self.showPopoverAt(x, y);
        _ = gtk.gtk_gesture_set_state(g, gtk.GTK_EVENT_SEQUENCE_CLAIMED);
    }

    fn onLongPressGesture(g: *gtk.GtkGesture, x: f64, y: f64, self: *ZvImagePage) callconv(.c) void {
        self.showPopoverAt(x, y);
        _ = gtk.gtk_gesture_set_state(g, gtk.GTK_EVENT_SEQUENCE_CLAIMED);
    }

    fn showPopoverAt(self: *ZvImagePage, x: f64, y: f64) void {
        const rect: gtk.GdkRectangle = .{
            .x = @intFromFloat(x),
            .y = @intFromFloat(y),
            .width = 0,
            .height = 0,
        };
        gtk.gtk_popover_set_pointing_to(self.popover, &rect);
        gtk.gtk_popover_popup(self.popover);
    }
};

pub fn registerType() gtk.GType {
    return gtk.registerType(gtk.adw_bin_get_type(), ZvImagePage, ZvImagePageClass);
}
