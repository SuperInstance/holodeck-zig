const std = @import("std");

// ═══════════════════════════════════════════
// Room — the fundamental unit of the holodeck
// ═══════════════════════════════════════════

pub const Note = struct {
    author: []const u8,
    content: []const u8,
};

pub const Exit = struct {
    direction: []const u8,
    target_id: []const u8,
};

pub const Room = struct {
    id: []const u8,
    name: []const u8,
    description: []const u8,
    exits: []Exit,
    notes: []Note,
    booted: bool,
    active_agent: ?[]const u8,

    pub fn init(id: []const u8, name: []const u8, desc: []const u8) Room {
        return Room{
            .id = id,
            .name = name,
            .description = desc,
            .exits = &[_]Exit{},
            .notes = &[_]Note{},
            .booted = false,
            .active_agent = null,
        };
    }

    pub fn boot(self: *Room, agent: []const u8) void {
        self.booted = true;
        self.active_agent = agent;
        std.log.info("Room '{s}' booted by '{s}'", .{ self.name, agent });
    }

    pub fn shutdown(self: *Room) void {
        self.booted = false;
        self.active_agent = null;
        std.log.info("Room '{s}' shutdown", .{self.name});
    }
};

// ═══════════════════════════════════════════
// Room Graph — all rooms in the holodeck
// ═══════════════════════════════════════════

pub const MAX_ROOMS = 64;

pub const RoomGraph = struct {
    rooms: [MAX_ROOMS]?Room,
    count: usize,

    pub fn init() RoomGraph {
        var graph = RoomGraph{
            .rooms = undefined,
            .count = 0,
        };
        for (&graph.rooms) |*slot| {
            slot.* = null;
        }
        return graph;
    }

    pub fn create_room(self: *RoomGraph, id: []const u8, name: []const u8, desc: []const u8) bool {
        if (self.count >= MAX_ROOMS) return false;
        // Check for duplicate
        for (self.rooms[0..self.count]) |maybe_room| {
            if (maybe_room) |room| {
                if (std.mem.eql(u8, room.id, id)) return false;
            }
        }
        self.rooms[self.count] = Room.init(id, name, desc);
        self.count += 1;
        return true;
    }

    pub fn find_room(self: *RoomGraph, id: []const u8) ?*Room {
        for (&self.rooms) |*maybe_room| {
            if (maybe_room.*) |*room| {
                if (std.mem.eql(u8, room.id, id)) return room;
            }
        }
        return null;
    }
};

// ═══════════════════════════════════════════
// Permission Levels (PLATO model)
// ═══════════════════════════════════════════

pub const PermissionLevel = enum(u8) {
    Greenhorn = 0,
    Crew = 1,
    Specialist = 2,
    Captain = 3,
    Cocapn = 4,
    Architect = 5,
};

// ═══════════════════════════════════════════
// Agent
// ═══════════════════════════════════════════

pub const Agent = struct {
    name: []const u8,
    room_id: []const u8,
    level: PermissionLevel,

    pub fn init(name: []const u8, start_room: []const u8) Agent {
        return Agent{
            .name = name,
            .room_id = start_room,
            .level = .Greenhorn,
        };
    }

    pub fn can(self: Agent, action: []const u8) bool {
        if (std.mem.eql(u8, action, "look") or
            std.mem.eql(u8, action, "go") or
            std.mem.eql(u8, action, "say"))
        {
            return true;
        }
        if (std.mem.eql(u8, action, "build")) {
            return @intFromEnum(self.level) >= @intFromEnum(PermissionLevel.Specialist);
        }
        return false;
    }
};

// ═══════════════════════════════════════════
// Tests
// ═══════════════════════════════════════════

test "room create and boot" {
    var room = Room.init("tavern", "The Tavern", "A cozy place");
    try std.testing.expect(!room.booted);
    room.boot("agent1");
    try std.testing.expect(room.booted);
    try std.testing.expect(room.active_agent != null);
}

test "room graph create" {
    var graph = RoomGraph.init();
    try std.testing.expect(graph.create_room("harbor", "Harbor", "Where ships dock"));
    try std.testing.expect(!graph.create_room("harbor", "Dupe", "Should fail"));
    try std.testing.expect(graph.count == 1);
}

test "room graph find" {
    var graph = RoomGraph.init();
    _ = graph.create_room("tavern", "Tavern", "A room");
    const room = graph.find_room("tavern");
    try std.testing.expect(room != null);
    try std.testing.expect(std.mem.eql(u8, room.?.name, "Tavern"));
}

test "agent permissions" {
    const greenhorn = Agent.init("g1", "harbor");
    try std.testing.expect(greenhorn.can("look"));
    try std.testing.expect(!greenhorn.can("build"));
    
    var captain = Agent.init("c1", "harbor");
    captain.level = .Captain;
    try std.testing.expect(captain.can("build"));
}

test "room shutdown" {
    var room = Room.init("test", "Test", "Testing");
    room.boot("agent1");
    try std.testing.expect(room.booted);
    room.shutdown();
    try std.testing.expect(!room.booted);
}
