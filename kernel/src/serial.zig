const io = @import("io.zig");

const COM1: u16 = 0x3F8;

pub const serial = struct {
    pub fn init() void {
        io.outb(COM1 + 1, 0x00);
        io.outb(COM1 + 3, 0x80);
        io.outb(COM1 + 0, 0x03);
        io.outb(COM1 + 1, 0x00);
        io.outb(COM1 + 3, 0x03);
        io.outb(COM1 + 2, 0xC7);
        io.outb(COM1 + 4, 0x0B);
    }

    fn isTransmitEmpty() bool {
        return (io.inb(COM1 + 5) & 0x20) != 0;
    }

    pub fn writeByte(byte: u8) void {
        while (!isTransmitEmpty()) {}
        io.outb(COM1, byte);
    }

    pub fn writeString(str: []const u8) void {
        for (str) |char| {
            if (char == '\n') {
                writeByte('\r');
            }
            writeByte(char);
        }
    }
};
