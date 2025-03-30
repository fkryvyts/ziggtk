const std = @import("std");
const gtk = @import("gtk.zig");
const image_book = @import("image_book.zig");

pub const ZvImageWindowClass = extern struct {
    parent_class: gtk.AdwApplicationWindowClass,

    pub fn init(self: *ZvImageWindowClass) callconv(.c) void {
        gtk.setTemplate(self, "ui/image_window.xml");
        gtk.bindTemplateChildren(self, ZvImageWindow, &.{
            "stack",
            "status_page",
            "image_book",
            "drop_target",
        });
        gtk.bindProperties(self, ZvImageWindow, &.{
            "fullscreened",
        });
        gtk.bindActions(self, &.{
            .{ .n = "win.open", .f = @ptrCast(&ZvImageWindow.onWinOpen) },
        });
    }
};

pub const ZvImageWindow = extern struct {
    parent_instance: gtk.AdwApplicationWindow,
    stack: *gtk.GtkStack,
    status_page: *gtk.AdwStatusPage,
    image_book: *image_book.ZvImageBook,
    drop_target: *gtk.GtkDropTarget,
    fullscreened: bool,

    pub fn init(self: *ZvImageWindow) callconv(.c) void {
        gtk.gtk_widget_init_template(@ptrCast(self));

        var types = [_]gtk.GType{gtk.g_file_get_type()};
        gtk.gtk_drop_target_set_gtypes(self.drop_target, &types, types.len);
        gtk.signalConnect(self.drop_target, "drop", @ptrCast(&ZvImageWindow.onFileDrop), self);
    }

    fn onWinOpen(self: *ZvImageWindow, _: [*c]const gtk.gchar) callconv(.c) void {
        const dialog = gtk.gtk_file_dialog_new();
        defer gtk.g_object_unref(dialog);

        const folder = gtk.g_file_new_for_path("/home/fedir/Downloads");
        defer gtk.g_object_unref(folder);

        const filters = gtk.g_list_store_new(gtk.gtk_file_filter_get_type());
        defer gtk.g_object_unref(filters);

        const filter_all = gtk.gtk_file_filter_new();
        defer gtk.g_object_unref(filter_all);

        const filter_supported = gtk.gtk_file_filter_new();
        defer gtk.g_object_unref(filter_supported);

        gtk.gtk_file_filter_add_pattern(filter_all, "*");
        gtk.gtk_file_filter_set_name(filter_all, "All files");
        gtk.g_list_store_append(filters, filter_all);

        gtk.gtk_file_filter_add_mime_type(filter_supported, "image/jpeg");
        gtk.gtk_file_filter_add_mime_type(filter_supported, "image/png");
        gtk.gtk_file_filter_set_name(filter_supported, "Supported image formats");
        gtk.g_list_store_append(filters, filter_supported);

        gtk.gtk_file_dialog_set_title(dialog, "Open Image");
        gtk.gtk_file_dialog_set_modal(dialog, 1);
        gtk.gtk_file_dialog_set_initial_folder(dialog, folder);
        gtk.gtk_file_dialog_set_filters(dialog, @ptrCast(filters));
        gtk.gtk_file_dialog_set_default_filter(dialog, filter_supported);
        gtk.gtk_file_dialog_open(dialog, @ptrCast(self), null, @ptrCast(&ZvImageWindow.onFileSelected), self);
    }

    fn onFileSelected(dialog: *gtk.GtkFileDialog, res: *gtk.GAsyncResult, self: *ZvImageWindow) callconv(.c) void {
        var err: [*c]gtk.GError = null;
        const file = gtk.gtk_file_dialog_open_finish(dialog, res, &err);
        if (err != null) {
            gtk.printAndCleanError(&err, "Error opening file");
            return;
        }

        defer gtk.g_object_unref(file);

        const filepath = gtk.g_file_get_path(file);
        defer gtk.g_free(filepath);

        self.image_book.loadImage(std.mem.span(filepath));
        gtk.gtk_stack_set_visible_child(self.stack, @ptrCast(self.image_book));
    }

    fn onFileDrop(_: *gtk.GtkDropTarget, val: *gtk.GValue, _: f64, _: f64, self: *ZvImageWindow) callconv(.c) gtk.gboolean {
        const p = gtk.g_value_get_object(val) orelse return 0;
        const file: *gtk.GFile = @ptrCast(@alignCast(p));

        const filepath = gtk.g_file_get_path(file);
        defer gtk.g_free(filepath);

        self.image_book.loadImage(std.mem.span(filepath));
        gtk.gtk_stack_set_visible_child(self.stack, @ptrCast(self.image_book));

        return 1;
    }
};

pub fn registerType() gtk.GType {
    return gtk.registerType(gtk.adw_application_window_get_type(), ZvImageWindow, ZvImageWindowClass);
}
