# Roblox Server-Side Admin System

A comprehensive admin system for Roblox games with console interface and powerful commands.

## Features

### 🚀 Enhanced Server-Side Executor
- **Secure Luau Execution**: Advanced sandboxed script execution with comprehensive security
- **Client Replication**: Scripts can be securely replicated and executed on authorized clients
- **Rate Limiting**: Built-in protection against abuse with configurable limits
- **Resource Management**: Memory and execution time limits with automatic cleanup
- **Real-time Monitoring**: Detailed execution statistics and performance metrics

### 🔐 Advanced Security
- **Multi-Level Authentication**: Secure token-based authentication system
- **Permission Validation**: Strict admin level verification and anti-privilege escalation
- **Encrypted Communication**: Client replication uses encryption and checksums
- **Session Management**: Heartbeat system with automatic session revocation

### 🎮 Professional Admin Tools
- **Admin Commands**: Teleport, kick, ban, god mode, and extensive player management
- **Modern GUI Console**: Enhanced interface with replication controls
- **Comprehensive Logging**: Track all admin actions with detailed audit trails
- **Network Optimization**: Efficient data transmission with bandwidth management

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

### Basic Commands
1. Admins can open the console with `/console` command or GUI button
2. Type commands in chat or use the admin panel interface
3. Use `/help` to see all available commands

### Enhanced Console
- **Ctrl+Enter**: Execute script on server only
- **Ctrl+Shift+Enter**: Execute on server AND replicate to authorized client
- Real-time output display with execution IDs and timestamps
- Comprehensive error handling and logging

### Client Replication
- Authorized admins automatically receive client replicator authentication
- Scripts executed with replication run on both server and client
- Secure encryption ensures only authorized clients receive scripts
- Built-in monitoring and statistics tracking

## Support

This system is designed for legitimate game development and administration purposes.
Ensure you have proper authorization before using admin tools in any game.