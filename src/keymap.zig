const std = @import("std");

pub const Keycode = u8;

// Such a shame this crashes the Zig compiler. It would be such a nice way to create enum from the keymap.

// pub const KeymapEntry = with_quota: {
//     @setEvalBranchQuota(2000);
//     break :with_quota createEnumFromMap(keycodeMap);
// };
//
// fn createEnumFromMap(comptime map: anytype) type {
//     const keys = comptime blk: {
//         var result: [map.keys().len][:0]const u8 = undefined;
//         for (map.keys(), 0..) |key, i| {
//             var buffer: [key.len + 1:0]u8 = undefined;
//             // @memcpy(buffer[0..key.len], key);
//             std.mem.copyForwards(u8, &buffer, key);
//             buffer[key.len] = 0;
//             result[i] = &buffer;
//         }
//         break :blk result;
//     };
//
//     var enum_fields: [keys.len]std.builtin.Type.EnumField = undefined;
//     for (keys, 0..) |key, i| {
//         enum_fields[i] = .{
//             .name = key,
//             .value = i,
//         };
//     }
//
//     return @Type(.{
//         .@"enum" = .{
//             .tag_type = std.math.IntFittingRange(0, keys.len - 1),
//             .fields = &enum_fields,
//             .decls = &.{},
//             .is_exhaustive = true,
//         },
//     });
// }

// zig fmt: off
pub const keycode_map = std.StaticStringMapWithEql(u8, std.ascii.eqlIgnoreCase).initComptime(.{
    .{ "a", 0x04 },                     // 04 Keyboard a and A
    .{ "b", 0x05 },                     // 05 Keyboard b and B
    .{ "c", 0x06 },                     // 06 Keyboard c and C
    .{ "d", 0x07 },                     // 07 Keyboard d and D
    .{ "e", 0x08 },                     // 08 Keyboard e and E
    .{ "f", 0x09 },                     // 09 Keyboard f and F
    .{ "g", 0x0A },                     // 0A Keyboard g and G
    .{ "h", 0x0B },                     // 0B Keyboard h and H
    .{ "i", 0x0C },                     // 0C Keyboard i and I
    .{ "j", 0x0D },                     // 0D Keyboard j and J
    .{ "k", 0x0E },                     // 0E Keyboard k and K
    .{ "l", 0x0F },                     // 0F Keyboard l and L
    .{ "m", 0x10 },                     // 10 Keyboard m and M
    .{ "n", 0x11 },                     // 11 Keyboard n and N
    .{ "o", 0x12 },                     // 12 Keyboard o and O
    .{ "p", 0x13 },                     // 13 Keyboard p and P
    .{ "q", 0x14 },                     // 14 Keyboard q and Q
    .{ "r", 0x15 },                     // 15 Keyboard r and R
    .{ "s", 0x16 },                     // 16 Keyboard s and S
    .{ "t", 0x17 },                     // 17 Keyboard t and T
    .{ "u", 0x18 },                     // 18 Keyboard u and U
    .{ "v", 0x19 },                     // 19 Keyboard v and V
    .{ "w", 0x1A },                     // 1A Keyboard w and W
    .{ "x", 0x1B },                     // 1B Keyboard x and X
    .{ "y", 0x1C },                     // 1C Keyboard y and Y
    .{ "z", 0x1D },                     // 1D Keyboard z and Z
    .{ "one", 0x1E },                   // 1E Keyboard 1 and !
    .{ "exclamation_mark", 0x1E },      // 1E Keyboard 1 and !
    .{ "two", 0x1F },                   // 1F Keyboard 2 and @
    .{ "at", 0x1F },                    // 1F Keyboard 2 and @
    .{ "three", 0x20 },                 // 20 Keyboard 3 and #
    .{ "hash", 0x20 },                  // 20 Keyboard 3 and #
    .{ "four", 0x21 },                  // 21 Keyboard 4 and $
    .{ "dollar", 0x21 },                // 21 Keyboard 4 and $
    .{ "five", 0x22 },                  // 22 Keyboard 5 and %
    .{ "percent", 0x22 },               // 22 Keyboard 5 and %
    .{ "six", 0x23 },                   // 23 Keyboard 6 and ^
    .{ "exponent", 0x23 },              // 23 Keyboard 6 and ^
    .{ "seven", 0x24 },                 // 24 Keyboard 7 and &
    .{ "ampersand", 0x24 },             // 24 Keyboard 7 and &
    .{ "eight", 0x25 },                 // 25 Keyboard 8 and *
    .{ "asterisk", 0x25 },              // 25 Keyboard 8 and *
    .{ "nine", 0x26 },                  // 26 Keyboard 9 and (
    .{ "left_parenthesis", 0x26 },      // 26 Keyboard 9 and (
    .{ "zero", 0x27 },                  // 27 Keyboard 0 and )
    .{ "right_parenthesis", 0x27 },     // 27 Keyboard 0 and )
    .{ "enter", 0x28 },                 // 28 Keyboard Return (ENTER)
    .{ "escape", 0x29 },                // 29 Keyboard ESCAPE
    .{ "backspace", 0x2A },             // 2A Keyboard DELETE (Backspace)
    .{ "tab", 0x2B },                   // 2B Keyboard Tab
    .{ "spacebar", 0x2C },              // 2C Keyboard Spacebar
    .{ "underscore", 0x2D },            // 2D Keyboard - and (underscore)
    .{ "hyphen", 0x2D },                // 2D Keyboard - and (underscore)
    .{ "equals", 0x2E },                // 2E Keyboard = and +
    .{ "plus", 0x2E },                  // 2E Keyboard = and +
    .{ "left_squarebracket", 0x2F },    // 2F Keyboard [ and {
    .{ "left_brace", 0x2F },            // 2F Keyboard [ and {
    .{ "right_squarebracket", 0x30 },   // 30 Keyboard ] and }
    .{ "right_brace", 0x30 },           // 30 Keyboard ] and }
    .{ "backslash", 0x31 },             // 31 Keyboard \ and |
    .{ "pipe", 0x31 },                  // 31 Keyboard \ and |
    .{ "hash_non_us", 0x32 },           // 32 Keyboard Non-US # and 5
    .{ "semicolon", 0x33 },             // 33 Keyboard ; and :
    .{ "colon", 0x33 },                 // 33 Keyboard ; and :
    .{ "quote",  0x34 },                // 34 Keyboard ' and "
    .{ "double_quote",  0x34 },         // 34 Keyboard ' and "
    .{ "grave_accent", 0x35 },          // 35 Keyboard Grave Accent and Tilde
    .{ "tilde", 0x35 },                 // 35 Keyboard Grave Accent and Tilde
    .{ "comma", 0x36 },                 // 36 Keyboard , and <
    .{ "less_than", 0x36 },             // 36 Keyboard , and <
    .{ "period", 0x37 },                // 37 Keyboard . and >
    .{ "more_than", 0x37 },             // 37 Keyboard . and >
    .{ "slash", 0x38 },                 // 38 Keyboard / and ?
    .{ "question_mark", 0x38 },         // 38 Keyboard / and ?
    .{ "caps_lock", 0x39 },             // 39 Keyboard Caps Lock
    .{ "f1", 0x3A },                    // 3A Keyboard F1
    .{ "f2", 0x3B },                    // 3B Keyboard F2
    .{ "f3", 0x3C },                    // 3C Keyboard F3
    .{ "f4", 0x3D },                    // 3D Keyboard F4
    .{ "f5", 0x3E },                    // 3E Keyboard F5
    .{ "f6", 0x3F },                    // 3F Keyboard F6
    .{ "f7", 0x40 },                    // 40 Keyboard F7
    .{ "f8", 0x41 },                    // 41 Keyboard F8
    .{ "f9", 0x42 },                    // 42 Keyboard F9
    .{ "f10", 0x43 },                   // 43 Keyboard F10
    .{ "f11", 0x44 },                   // 44 Keyboard F11
    .{ "f12", 0x45 },                   // 45 Keyboard F12
    .{ "print_screen", 0x46 },          // 46 Keyboard PrintScreen
    .{ "scroll_lock", 0x47 },           // 47 Keyboard Scroll Lock
    .{ "pause", 0x48 },                 // 48 Keyboard Pause
    .{ "insert", 0x49 },                // 49 Keyboard Insert
    .{ "home", 0x4A },                  // 4A Keyboard Home
    .{ "page_up", 0x4B },               // 4B Keyboard PageUp
    .{ "delete", 0x4C },                // 4C Keyboard Delete Forward
    .{ "end", 0x4D },                   // 4D Keyboard End
    .{ "page_down", 0x4E },             // 4E Keyboard PageDown
    .{ "right_arrow", 0x4F },           // 4F Keyboard RightArrow
    .{ "left_arrow", 0x50 },            // 50 Keyboard LeftArrow
    .{ "down_arrow", 0x51 },            // 51 Keyboard DownArrow
    .{ "up_arrow", 0x52 },              // 52 Keyboard UpArrow
    .{ "num_lock", 0x53 },              // 53 Keypad Num Lock and Clear
    .{ "clear", 0x53 },                 // 53 Keypad Num Lock and Clear
    .{ "keypad_divide", 0x54 },         // 54 Keypad /
    .{ "keypad_multiply", 0x55 },       // 55 Keypad *
    .{ "keypad_minus", 0x56 },          // 56 Keypad -
    .{ "keypad_plus", 0x57 },           // 57 Keypad +
    .{ "keypad_enter", 0x58 },          // 58 Keypad ENTER
    .{ "keypad_1", 0x59 },              // 59 Keypad 1 and End
    .{ "keypad_2", 0x5A },              // 5A Keypad 2 and Down Arrow
    .{ "keypad_3", 0x5B },              // 5B Keypad 3 and PageDn
    .{ "keypad_4", 0x5C },              // 5C Keypad 4 and Left Arrow
    .{ "keypad_5", 0x5D },              // 5D Keypad 5
    .{ "keypad_6", 0x5E },              // 5E Keypad 6 and Right Arrow
    .{ "keypad_7", 0x5F },              // 5F Keypad 7 and Home
    .{ "keypad_8", 0x60 },              // 60 Keypad 8 and Up Arrow
    .{ "keypad_9", 0x61 },              // 61 Keypad 9 and PageUp
    .{ "keypad_0", 0x62 },              // 62 Keypad 0 and Insert
    .{ "keypad_delete", 0x63 },              // 63 Keypad . and Delete
    //  { "", 0x64 },                   // 64 Keyboard Non-US \ and |
    .{ "application", 0x65 },           // 65 Keyboard Application
    .{ "power", 0x66 },                 // 66 Keyboard Power
    .{ "keypad_equals", 0x67 },         // 67 Keypad =
    .{ "f13", 0x68 },                   // 68 Keyboard F13
    .{ "f14", 0x69 },                   // 69 Keyboard F14
    .{ "f15", 0x6A },                   // 6A Keyboard F15
    .{ "f16", 0x6B },                   // 6B Keyboard F16
    .{ "f17", 0x6C },                   // 6C Keyboard F17
    .{ "f18", 0x6D },                   // 6D Keyboard F18
    .{ "f19", 0x6E },                   // 6E Keyboard F19
    .{ "f20", 0x6F },                   // 6F Keyboard F20
    .{ "f21", 0x70 },                   // 70 Keyboard F21
    .{ "f22", 0x71 },                   // 71 Keyboard F22
    .{ "f23", 0x72 },                   // 72 Keyboard F23
    .{ "f24", 0x73 },                   // 73 Keyboard F24
    .{ "execute", 0x74 },               // 74 Keyboard Execute
    .{ "help", 0x75 },                  // 75 Keyboard Help
    .{ "menu", 0x76 },                  // 76 Keyboard Menu
    .{ "select", 0x77 },                // 77 Keyboard Select
    .{ "stop", 0x78 },                  // 78 Keyboard Stop
    .{ "again", 0x79 },                 // 79 Keyboard Again
    .{ "undo", 0x7A },                  // 7A Keyboard Undo
    .{ "cut", 0x7B },                   // 7B Keyboard Cut
    .{ "copy", 0x7C },                  // 7C Keyboard Copy
    .{ "paste", 0x7D },                 // 7D Keyboard Paste
    .{ "find", 0x7E },                  // 7E Keyboard Find
    .{ "mute", 0x7F },                  // 7F Keyboard Mute
    .{ "volume_up", 0x80 },             // 80 Keyboard Volume Up
    .{ "volume_down", 0x81 },           // 81 Keyboard Volume Down
    //  { "", 0x82 },                   // 82 Keyboard Locking Caps Lock
    //  { "", 0x83 },                   // 83 Keyboard Locking Num Lock
    //  { "", 0x84 },                   // 84 Keyboard Locking Scroll Lock
    .{ "keypad_comma", 0x85 },          // 85 Keypad Comma
    //  { "", 0x86 },                   // 86 Keypad Equal Sign (AS/400)
    //  { "", 0x87 },                   // 87 Keyboard International1
    //  { "", 0x88 },                   // 88 Keyboard International2
    //  { "", 0x89 },                   // 89 Keyboard International3
    //  { "", 0x8A },                   // 8A Keyboard International4
    //  { "", 0x8B },                   // 8B Keyboard International5
    //  { "", 0x8C },                   // 8C Keyboard International6
    //  { "", 0x8D },                   // 8D Keyboard International7
    //  { "", 0x8E },                   // 8E Keyboard International8
    //  { "", 0x8F },                   // 8F Keyboard International9
    //  { "", 0x90 },                   // 90 Keyboard LANG1
    //  { "", 0x91 },                   // 91 Keyboard LANG2
    //  { "", 0x92 },                   // 92 Keyboard LANG3
    //  { "", 0x93 },                   // 93 Keyboard LANG4
    //  { "", 0x94 },                   // 94 Keyboard LANG5
    //  { "", 0x95 },                   // 95 Keyboard LANG6
    //  { "", 0x96 },                   // 96 Keyboard LANG7
    //  { "", 0x97 },                   // 97 Keyboard LANG8
    //  { "", 0x98 },                   // 98 Keyboard LANG9
    //  { "", 0x99 },                   // 99 Keyboard Alternate Erase
    //  { "", 0x9A },                   // 9A Keyboard SysReq/Attention
    //  { "", 0x9B },                   // 9B Keyboard Cancel
    //  { "", 0x9C },                   // 9C Keyboard Clear
    //  { "", 0x9D },                   // 9D Keyboard Prior
    //  { "", 0x9E },                   // 9E Keyboard Return
    //  { "", 0x9F },                   // 9F Keyboard Separator
    //  { "", 0xA0 },                   // A0 Keyboard Out
    //  { "", 0xA1 },                   // A1 Keyboard Oper
    //  { "", 0xA2 },                   // A2 Keyboard Clear/Again
    //  { "", 0xA3 },                   // A3 Keyboard CrSel/Props
    //  { "", 0xA4 },                   // A4 Keyboard ExSel
    //  { "", 0xA5 },                   // A5 Reserved
    //  { "", 0xA6 },                   // A6 Reserved
    //  { "", 0xA7 },                   // A7 Reserved
    //  { "", 0xA8 },                   // A8 Reserved
    //  { "", 0xA9 },                   // A9 Reserved
    //  { "", 0xAA },                   // AA Reserved
    //  { "", 0xAB },                   // AB Reserved
    //  { "", 0xAC },                   // AC Reserved
    //  { "", 0xAD },                   // AD Reserved
    //  { "", 0xAE },                   // AE Reserved
    //  { "", 0xAF },                   // AF Reserved
    .{ "keypad_00", 0xB0 },             // B0 Keypad 00
    .{ "keypad_000", 0xB1 },            // B1 Keypad 000
    //  { "", 0xB2 },                   // B2 Thousands Separator
    //  { "", 0xB3 },                   // B3 Decimal Separator
    //  { "", 0xB4 },                   // B4 Currency Unit
    //  { "", 0xB5 },                   // B5 Currency Sub-unit
    //  { "", 0xB6 },                   // B6 Keypad ( Sel
    //  { "", 0xB7 },                   // B7 Keypad )
    //  { "", 0xB8 },                   // B8 Keypad {
    //  { "", 0xB9 },                   // B9 Keypad }
    //  { "", 0xBA },                   // BA Keypad Tab
    //  { "", 0xBB },                   // BB Keypad Backspace
    //  { "", 0xBC },                   // BC Keypad A
    //  { "", 0xBD },                   // BD Keypad B
    //  { "", 0xBE },                   // BE Keypad C
    //  { "", 0xBF },                   // BF Keypad D
    //  { "", 0xC0 },                   // C0 Keypad E
    //  { "", 0xC1 },                   // C1 Keypad F
    //  { "", 0xC2 },                   // C2 Keypad XOR
    //  { "", 0xC3 },                   // C3 Keypad ^
    //  { "", 0xC4 },                   // C4 Keypad %
    //  { "", 0xC5 },                   // C5 Keypad <
    //  { "", 0xC6 },                   // C6 Keypad >
    //  { "", 0xC7 },                   // C7 Keypad &
    //  { "", 0xC8 },                   // C8 Keypad &&
    //  { "", 0xC9 },                   // C9 Keypad |
    //  { "", 0xCA },                   // CA Keypad ||
    //  { "", 0xCB },                   // CB Keypad :
    //  { "", 0xCC },                   // CC Keypad #
    //  { "", 0xCD },                   // CD Keypad Space
    //  { "", 0xCE },                   // CE Keypad @
    //  { "", 0xCF },                   // CF Keypad !
    //  { "", 0xD0 },                   // D0 Keypad Memory Store
    //  { "", 0xD1 },                   // D1 Keypad Memory Recall
    //  { "", 0xD2 },                   // D2 Keypad Memory Clear
    //  { "", 0xD3 },                   // D3 Keypad Memory Add
    //  { "", 0xD4 },                   // D4 Keypad Memory Subtract
    //  { "", 0xD5 },                   // D5 Keypad Memory Multiply
    //  { "", 0xD6 },                   // D6 Keypad Memory Divide
    //  { "", 0xD7 },                   // D7 Keypad +/-
    //  { "", 0xD8 },                   // D8 Keypad Clear
    //  { "", 0xD9 },                   // D9 Keypad Clear Entry
    //  { "", 0xDA },                   // DA Keypad Binary
    //  { "", 0xDB },                   // DB Keypad Octal
    //  { "", 0xDC },                   // DC Keypad Decimal
    //  { "", 0xDD },                   // DD Keypad Hexadecimal
    //  { "", 0xDE },                   // DE Reserved
    //  { "", 0xDF },                   // DF Reserved
    .{ "left_control", 0xE0 },          // E0 Keyboard LeftControl
    .{ "left_shift", 0xE1 },            // E1 Keyboard LeftShift
    .{ "left_alt", 0xE2 },              // E2 Keyboard LeftAlt
    .{ "left_gui", 0xE3 },              // E3 Keyboard Left GUI (Windows key)
    .{ "right_control", 0xE4 },         // E4 Keyboard RightControl
    .{ "right_shift", 0xE5 },           // E5 Keyboard RightShift
    .{ "right_alt", 0xE6 },             // E6 Keyboard RightAlt
    .{ "right_gui", 0xE7 },             // E7 Keyboard Right GUI (Windows key)
});
// zig fmt: on
