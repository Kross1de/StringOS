const builtin = @import("builtin");

const GdtEntry = packed struct {
    limit_low: u16,
    base_low: u16,
    base_middle: u8,
    access: u8,
    granularity: u8,
    base_high: u8,
};

const GdtPointer = packed struct {
    limit: u16,
    base: u64,
};

pub fn loadGdt() void {
    var gdt: [5]GdtEntry = undefined;
    gdt[0] = .{ .limit_low = 0, .base_low = 0, .base_middle = 0, .access = 0, .granularity = 0, .base_high = 0 };
    gdt[1] = .{ .limit_low = 0xFFFF, .base_low = 0, .base_middle = 0, .access = 0x9A, .granularity = 0xCF, .base_high = 0 };
    gdt[2] = .{ .limit_low = 0xFFFF, .base_low = 0, .base_middle = 0, .access = 0x92, .granularity = 0xCF, .base_high = 0 };
    gdt[3] = .{ .limit_low = 0xFFFF, .base_low = 0, .base_middle = 0, .access = 0xFA, .granularity = 0xCF, .base_high = 0 };
    gdt[4] = .{ .limit_low = 0xFFFF, .base_low = 0, .base_middle = 0, .access = 0xF2, .granularity = 0xCF, .base_high = 0 };

    var gp: GdtPointer = undefined;
    gp.limit = (@sizeOf(@TypeOf(gdt)) - 1) & 0xFFFF;
    gp.base = @intFromPtr(&gdt);

    asm volatile ("lgdt %[gp]" : : [gp] "m" (gp));
}
