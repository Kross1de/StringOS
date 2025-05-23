const builtin = @import("builtin");
const limine = @import("limine");
const font = @import("font.zig");

export var start_marker: limine.RequestsStartMarker linksection(".limine_requests_start") = .{};
export var end_marker: limine.RequestsEndMarker linksection(".limine_requests_end") = .{};

export var base_revision: limine.BaseRevision linksection(".limine_requests") = .init(3);
export var framebuffer_request: limine.FramebufferRequest linksection(".limine_requests") = .{};

fn hcf() noreturn {
    while (true) {
        switch (builtin.cpu.arch) {
            .x86_64 => asm volatile ("hlt"),
            .aarch64 => asm volatile ("wfi"),
            .riscv64 => asm volatile ("wfi"),
            .loongarch64 => asm volatile ("idle 0"),
            else => unreachable,
        }
    }
}

fn drawText(fb_ptr: [*]volatile u32, pitch: u64, text: []const u8, start_x: u32, start_y: u32, scale: u32, color: u32) void {
    var x_offset: u32 = 0;

    for (text) |char| {
        if (char >= font.Font.first_char and char <= font.Font.last_char) {
            const char_idx = char - font.Font.first_char;
            const char_data = font.Font.data[char_idx];

            for (0..font.Font.height) |y| {
                const row = char_data[y];
                for (0..font.Font.width) |x| {
                    if ((row >> @intCast(7 - x)) & 1 == 1) {
                        for (0..scale) |dy| {
                            for (0..scale) |dx| {
                                const pixel_x = start_x + x_offset + x * scale + dx;
                                const pixel_y = start_y + y * scale + dy;
                                if (pixel_x < @as(u32, @truncate(pitch / 4)) and pixel_y < 0xFFFFFFFF / @as(u32, @truncate(pitch / 4))) {
                                    fb_ptr[pixel_y * @as(u32, @truncate(pitch / 4)) + pixel_x] = color;
                                }
                            }
                        }
                    }
                }
            }
        }
        x_offset += font.Font.width * scale + scale;
    }
}

export fn _start() noreturn {
    if (!base_revision.isSupported()) {
        @panic("Base revision not supported");
    }

    if (framebuffer_request.response) |framebuffer_response| {
        const framebuffer = framebuffer_response.getFramebuffers()[0];
        const fb_ptr: [*]volatile u32 = @ptrCast(@alignCast(framebuffer.address));
        const pitch = framebuffer.pitch; // pitch is u64

        for (0..framebuffer.height) |y| {
            for (0..framebuffer.width) |x| {
                fb_ptr[y * @as(u32, @truncate(pitch / 4)) + x] = 0x000000;
            }
        }

        drawText(fb_ptr, pitch, "Hello", 50, 50, 1, 0xFFFFFF);
        drawText(fb_ptr, pitch, "String Operating System IN ZIG!!", 50, 100, 1, 0x00FF00);
        drawText(fb_ptr, pitch, "Test: ><$%#@", 50, 120, 1, 0x22FF00);
        drawText(fb_ptr, pitch, "Test: 123456789", 50, 140, 1, 0x22FF00);
    } else {
        @panic("Framebuffer response not present");
    }

    hcf();
}
