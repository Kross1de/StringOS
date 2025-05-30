const font = @import("font.zig");
pub const Serial = @import("serial.zig").serial;

pub const Color = enum {
    White,
    Green,
    Gray,
    Black,
    Red,
    Blue,
    Yellow,
    Magenta,
    Cyan,
    Orange,
    Purple,
    Pink,
    Brown,
    LightBlue,
    LightGreen,
    LightGray,
    DarkGray,
    DarkRed,
    DarkGreen,
    DarkBlue,

    pub fn toU32(self: Color) u32 {
        return switch (self) {
            .White => 0xFFFFFF,
            .Green => 0x00FF00,
            .Gray => 0x808080,
            .Black => 0x000000,
            .Red => 0xFF0000,
            .Blue => 0x0000FF,
            .Yellow => 0xFFFF00,
            .Magenta => 0xFF00FF,
            .Cyan => 0x00FFFF,
            .Orange => 0xFFA500,
            .Purple => 0x800080,
            .Pink => 0xFFC0CB,
            .Brown => 0xA52A2A,
            .LightBlue => 0xADD8E6,
            .LightGreen => 0x90EE90,
            .LightGray => 0xD3D3D3,
            .DarkGray => 0x404040,
            .DarkRed => 0x8B0000,
            .DarkGreen => 0x006400,
            .DarkBlue => 0x00008B,
        };
    }
};

pub const TextPrinter = struct {
    x: u32 = 0,
    y: u32 = 0,
    scale: u32 = 1,
    fb_ptr: [*]volatile u32,
    pitch: u64,
    width: u32,
    height: u32,

    pub fn printText(self: *TextPrinter, text: []const u8, color: Color) void {
        var x_offset: u32 = 0;

        for (text) |char| {
            if (char >= font.Font.first_char and char <= font.Font.last_char) {
                const char_idx = char - font.Font.first_char;
                const char_data = font.Font.data[char_idx];

                for (0..font.Font.height) |y| {
                    const row = char_data[y];
                    for (0..font.Font.width) |x| {
                        if ((row >> @intCast(7 - x)) & 1 == 1) {
                            for (0..self.scale) |dy| {
                                for (0..self.scale) |dx| {
                                    const pixel_x = self.x + x_offset + x * self.scale + dx;
                                    const pixel_y = self.y + y * self.scale + dy;
                                    if (pixel_x < self.width and pixel_y < self.height) {
                                        self.fb_ptr[pixel_y * (self.pitch / 4) + pixel_x] = color.toU32();
                                    }
                                }
                            }
                        }
                    }
                }
            }
            x_offset += font.Font.width * self.scale + self.scale;
        }
    }

    pub fn print(self: *TextPrinter, text: []const u8, color: Color) void {
        self.printText(text, color);
        self.y += font.Font.height * self.scale + self.scale * 2;
        self.x = 0;
    }

    pub fn debug(self: *TextPrinter, text: []const u8) void {
        const debug_prefix = "[DEBUG] ";
        self.printText(debug_prefix, .Green);
        const prefix_width = @as(u32, @intCast(debug_prefix.len)) * font.Font.width * self.scale + self.scale;
        self.x = prefix_width;
        self.printText(text, .Green);
        self.y += font.Font.height * self.scale + self.scale * 2;
        self.x = 0;
        Serial.writeString(debug_prefix);
        Serial.writeString(text);
        Serial.writeString("\n");
    }

    pub fn info(self: *TextPrinter, text: []const u8) void {
        const info_prefix = "[INFO] ";
        self.printText(info_prefix, .Blue);
        const prefix_width = @as(u32, @intCast(info_prefix.len)) * font.Font.width * self.scale + self.scale;
        self.x = prefix_width;
        self.printText(text, .Blue);
        self.y += font.Font.height * self.scale + self.scale * 2;
        self.x = 0;
        Serial.writeString(info_prefix);
        Serial.writeString(text);
        Serial.writeString("\n");
    }
};
