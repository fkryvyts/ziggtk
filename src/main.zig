const gtk = @import("widgets/gtk.zig");
const widgets = @import("widgets/widgets.zig");
const std = @import("std");

pub fn main() !u8 {
    try widgets.runApp();

    return 0;
}
