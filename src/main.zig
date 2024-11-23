const widgets = @import("widgets/widgets.zig");

pub fn main() !u8 {
    try widgets.runApp();

    return 0;
}
