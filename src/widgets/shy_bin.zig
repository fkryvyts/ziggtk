const std = @import("std");
const gtk = @import("gtk.zig");

pub const ZvShyBinClass = extern struct {
    parent_class: gtk.AdwBinClass,

    pub fn init(_: *ZvShyBinClass) callconv(.c) void {}
};

pub const ZvShyBin = extern struct {
    parent_instance: gtk.AdwBin,

    pub fn init(_: *ZvShyBin) callconv(.c) void {}
};

pub fn registerType() gtk.GType {
    return gtk.registerType(gtk.adw_bin_get_type(), ZvShyBin, ZvShyBinClass);
}
