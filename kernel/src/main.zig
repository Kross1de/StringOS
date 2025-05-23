const builtin = @import("builtin");
const limine = @import("limine");
const common = @import("common.zig");

export var start_marker: limine.RequestsStartMarker linksection(".limine_requests_start") = .{};
export var end_marker: limine.RequestsEndMarker linksection(".limine_requests_end") = .{};

export var base_revision: limine.BaseRevision linksection(".limine_requests") = .init(3);
export var framebuffer_request: limine.FramebufferRequest linksection(".limine_requests") = .{};

fn hcf() noreturn {
    while (true) {
        switch (builtin.cpu.arch) {
            .x86_64 => asm volatile ("hlt"),
            else => unreachable,
        }
    }
}

export fn _start() noreturn {
    if (!base_revision.isSupported()) {
        @panic("Base revision not supported");
    }

    if (framebuffer_request.response) |framebuffer_response| {
        const framebuffer = framebuffer_response.getFramebuffers()[0];
        const fb_ptr: [*]volatile u32 = @ptrCast(@alignCast(framebuffer.address));
        const pitch = framebuffer.pitch;
        const width = @as(u32, @truncate(framebuffer.width));
        const height = @as(u32, @truncate(framebuffer.height));

        for (0..height) |y| {
            for (0..width) |x| {
                fb_ptr[y * @as(u32, @truncate(pitch / 4)) + x] = common.Color.Gray.toU32();
            }
        }

        var printer = common.TextPrinter{
            .fb_ptr = fb_ptr,
            .pitch = pitch,
            .width = width,
            .height = height,
        };

        printer.print("Hello", .White);
        printer.print("String Operating System IN ZIG!!", .White);
        printer.print("Test: ><$%#@", .White);
        printer.print("Test: 123456789", .White);
        printer.print("NEW PRINT SYSTEM WORKING FINALLY ALRIGHT!!!!! =)", .White);
        printer.print("Testing colors :::", .Black);
        printer.print("Green", .Green);
        printer.print("Red", .Red);
        printer.print("Blue", .Blue);
        printer.print("Yellow", .Yellow);
        printer.print("Magenta", .Magenta);
        printer.print("Cyan", .Cyan);
        printer.print("Orange", .Orange);
        printer.print("Purple", .Purple);
        printer.print("Pink", .Pink);
        printer.print("Brown", .Brown);
        printer.print("LightBlue", .LightBlue);
        printer.print("LightGreen", .LightGreen);
        printer.print("LightGray", .LightGray);
        printer.print("DarkGray", .DarkGray);
        printer.print("DarkRed", .DarkRed);
        printer.print("DarkGreen", .DarkGreen);
        printer.print("DarkBlue", .DarkBlue);
    } else {
        @panic("Framebuffer response not present");
    }

    hcf();
}
