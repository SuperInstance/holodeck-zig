const std = @import("std");
const holodeck = @import("holodeck.zig");

pub fn main() !void {
    std.log.info("🔮 Holodeck Zig — starting up", .{});
    
    // Seed rooms
    var graph = holodeck.RoomGraph.init();
    _ = graph.create_room("harbor", "The Harbor", "Where vessels arrive. The dockmaster watches all.");
    _ = graph.create_room("tavern", "The Tavern", "The heart of the fleet. Charts cover the table.");
    _ = graph.create_room("workshop", "The Workshop", "Where things get built.");
    
    std.log.info("Seeded {} rooms", .{graph.count});
    
    // Boot harbor for test agent
    if (graph.find_room("harbor")) |harbor| {
        harbor.boot("oracle1");
        std.log.info("Harbor booted for oracle1", .{});
        harbor.shutdown();
        std.log.info("Harbor shutdown", .{});
    }
    
    std.log.info("🔮 Holodeck Zig — ready on :7779", .{});
}
