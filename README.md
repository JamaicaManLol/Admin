# Roblox Server-Side Admin System

A comprehensive admin system for Roblox games with console interface and powerful commands.

## Features

- **Server-Side Console**: Execute Lua code directly on the server
- **Admin Commands**: Teleport, kick, ban, give items, and more
- **Security System**: Role-based permissions and secure remote handling
- **GUI Console**: Modern interface for easy command execution
- **Logging System**: Track all admin actions
- **Extensible**: Easy to add new commands

## Installation

1. **ServerScriptService**: Place all files from `ServerScriptService/` into your game's ServerScriptService
2. **ReplicatedStorage**: Place all files from `ReplicatedStorage/` into ReplicatedStorage
3. **StarterPlayer**: Place files from `StarterPlayer/` into the appropriate StarterPlayer folders

## Configuration

Edit `ServerScriptService/AdminSystem/Config.lua` to:
- Add admin user IDs
- Configure permissions
- Set up game-specific settings

## Admin Commands

- `/tp [player]` - Teleport to player
- `/bring [player]` - Bring player to you
- `/kick [player] [reason]` - Kick player
- `/ban [player] [reason]` - Ban player
- `/unban [player]` - Unban player
- `/god [player]` - Make player invincible
- `/ungod [player]` - Remove invincibility
- `/speed [player] [speed]` - Set player speed
- `/jump [player] [power]` - Set player jump power
- `/respawn [player]` - Respawn player
- `/announce [message]` - Server announcement
- `/console` - Open server console

## Security

- All commands are validated server-side
- Admin permissions are checked before execution
- Remote events use secure validation
- Logging prevents abuse

## Usage

1. Admins can open the console with `/console` command or GUI button
2. Type commands in chat or use the console interface
3. Execute server-side Lua code through the console (super admins only)

## Support

This system is designed for legitimate game development and administration purposes.
Ensure you have proper authorization before using admin tools in any game.