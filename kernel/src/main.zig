const builtin = @import("builtin");
const limine = @import("limine");

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

const font = [_][7][5]u1{
    [7][5]u1{
        [5]u1{ 1, 0, 0, 0, 1 },
        [5]u1{ 1, 0, 0, 0, 1 },
        [5]u1{ 1, 0, 0, 0, 1 },
        [5]u1{ 1, 1, 1, 1, 1 },
        [5]u1{ 1, 0, 0, 0, 1 },
        [5]u1{ 1, 0, 0, 0, 1 },
        [5]u1{ 1, 0, 0, 0, 1 },
    },
    [7][5]u1{
        [5]u1{ 1, 1, 1, 1, 1 },
        [5]u1{ 1, 0, 0, 0, 0 },
        [5]u1{ 1, 0, 0, 0, 0 },
        [5]u1{ 1, 1, 1, 1, 0 },
        [5]u1{ 1, 0, 0, 0, 0 },
        [5]u1{ 1, 0, 0, 0, 0 },
        [5]u1{ 1, 1, 1, 1, 1 },
    },
    [7][5]u1{
        [5]u1{ 1, 0, 0, 0, 0 },
        [5]u1{ 1, 0, 0, 0, 0 },
        [5]u1{ 1, 0, 0, 0, 0 },
        [5]u1{ 1, 0, 0, 0, 0 },
        [5]u1{ 1, 0, 0, 0, 0 },
        [5]u1{ 1, 0, 0, 0, 0 },
        [5]u1{ 1, 1, 1, 1, 1 },
    },
    [7][5]u1{
        [5]u1{ 0, 1, 1, 1, 0 },
        [5]u1{ 1, 0, 0, 0, 1 },
        [5]u1{ 1, 0, 0, 0, 1 },
        [5]u1{ 1, 0, 0, 0, 1 },
        [5]u1{ 1, 0, 0, 0, 1 },
        [5]u1{ 1, 0, 0, 0, 1 },
        [5]u1{ 0, 1, 1, 1, 0 },
    },
};

export fn _start() noreturn {
    if (!base_revision.isSupported()) {
        @panic("Base revision not supported");
    }

    if (framebuffer_request.response) |framebuffer_response| {
        const framebuffer = framebuffer_response.getFramebuffers()[0];
        const fb_ptr: [*]volatile u32 = @ptrCast(@alignCast(framebuffer.address));
        const pitch = framebuffer.pitch / 4;

        const letters = [_]usize{ 0, 1, 2, 2, 3 };
        const scale: u32 = 2;
        const spacing: u32 = 6;

        for (letters, 0..) |letter_idx, char_idx| {
            const start_x = 50 + char_idx * (5 * scale + spacing);
            const start_y = 50;

            for (0..7) |y| {
                for (0..5) |x| {
                    if (font[letter_idx][y][x] == 1) {
                        for (0..scale) |dy| {
                            for (0..scale) |dx| {
                                const pixel_x = start_x + x * scale + dx;
                                const pixel_y = start_y + y * scale + dy;
                                fb_ptr[pixel_y * pitch + pixel_x] = 0xffffff;
                            }
                        }
                    }
                }
            }
        }
    } else {
        @panic("Framebuffer response not present");
    }

    hcf();
}
