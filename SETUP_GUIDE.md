# Roblox Admin System Setup Guide

## 📋 Prerequisites

- Roblox Studio
- Game with DataStore enabled (for ban persistence)
- Basic understanding of Roblox Studio

## 🛠️ Installation Steps

### Step 1: Configure Admins

1. Open `ServerScriptService/AdminSystem/Config.lua`
2. Replace the example User IDs with actual Roblox User IDs:

```lua
Config.Admins = {
    [YOUR_USER_ID] = "Owner",      -- Replace with your User ID
    [FRIEND_USER_ID] = "Admin",    -- Replace with friend's User ID
    -- Add more admins as needed
}
```

**How to find User IDs:**
- Go to a player's profile on Roblox.com
- Look at the URL: `https://www.roblox.com/users/123456789/profile`
- The number `123456789` is the User ID

### Step 2: Place Files in Roblox Studio

#### ServerScriptService Files:
1. Create a folder named `AdminSystem` in ServerScriptService
2. Add these as **ServerScripts** inside the AdminSystem folder:
   - `Config.lua` (ModuleScript)
   - `AdminCore.lua` (ServerScript)
   - `Commands.lua` (ModuleScript)

#### StarterPlayer Files:
1. Go to StarterPlayer > StarterPlayerScripts
2. Add `AdminClient.lua` as a **LocalScript**

### Step 3: Enable Required Services

1. Go to Game Settings in Studio
2. Enable "Allow HTTP Requests" if you plan to use web features
3. Enable "Enable Studio Access to API Services" for DataStore
4. Publish your game to enable DataStore functionality

### Step 4: Test the System

1. **Test in Studio:**
   - Click "Play" with at least 2 players
   - One player should be an admin (User ID in config)

2. **Test Commands:**
   - Type `/help` in chat to see available commands
   - Try `/tp [playername]` to teleport
   - Use the Admin Panel GUI button

3. **Test Console:**
   - Click the "Console" button
   - Enter Lua code and press Ctrl+Enter

## 🎮 Usage Instructions

### For Admins:

#### Chat Commands:
- Type commands directly in chat with `/` prefix
- Example: `/tp john`, `/speed john 50`, `/god`

#### Admin Panel:
- Click "Admin Panel" button (top right)
- Enter commands in the text box
- View command output in the panel

#### Console (Advanced):
- Click "Console" button
- Write Lua code to execute on server
- Press Ctrl+Enter to run code
- **⚠️ Only for experienced users**

### Available Commands:

| Command | Usage | Description |
|---------|-------|-------------|
| `/tp [player]` | `/tp john` | Teleport to player |
| `/bring [player]` | `/bring john` | Bring player to you |
| `/kick [player] [reason]` | `/kick john spam` | Kick player |
| `/ban [player] [reason]` | `/ban john hacking` | Ban player |
| `/unban [userId]` | `/unban 123456789` | Unban player |
| `/god [player]` | `/god john` | Enable god mode |
| `/ungod [player]` | `/ungod john` | Disable god mode |
| `/speed [player] [value]` | `/speed john 50` | Set walk speed |
| `/jump [player] [value]` | `/jump john 100` | Set jump power |
| `/respawn [player]` | `/respawn john` | Respawn player |
| `/announce [message]` | `/announce Server restart in 5 min` | Server announcement |
| `/help` | `/help` | Show available commands |

## 🔒 Security Features

- **Permission Levels:** Owner > SuperAdmin > Admin > Moderator
- **Command Restrictions:** Each command requires minimum permission level
- **Anti-Abuse:** Admins cannot target higher-level admins
- **Secure Execution:** Console code runs in sandboxed environment
- **Logging:** All admin actions are logged with timestamps
- **Ban Persistence:** Bans are saved and persist across server restarts

## ⚙️ Customization

### Adding New Commands:

1. Open `ServerScriptService/AdminSystem/Commands.lua`
2. Add your command function:

```lua
function Commands.mycommand(admin, adminPlayer, ...)
    -- Your command logic here
    admin:logAction(adminPlayer, "MYCOMMAND", "target", "details")
    return "Command executed successfully"
end
```

3. Add permission level in `Config.lua`:

```lua
Config.CommandPermissions = {
    -- ... existing commands ...
    ["mycommand"] = 2, -- Requires Admin level
}
```

### Changing GUI Colors:

1. Open `StarterPlayer/StarterPlayerScripts/AdminClient.lua`
2. Modify the `Color3.fromRGB()` values
3. Customize button sizes and positions

### Adjusting Permissions:

1. Edit `Config.lua`
2. Change permission levels for commands
3. Add new admin roles if needed

## 🐛 Troubleshooting

### Admin GUI Not Showing:
- Check if your User ID is correctly added to `Config.Admins`
- Ensure the LocalScript is in StarterPlayerScripts
- Check for script errors in Developer Console (F9)

### Commands Not Working:
- Verify you have permission for the command
- Check spelling and syntax
- Look for error messages in chat

### Console Access Denied:
- Console requires SuperAdmin level or higher
- Check your permission level in the Admin Panel title

### DataStore Errors:
- Enable "Allow HTTP Requests" in game settings
- Publish the game (DataStore doesn't work in unpublished games)
- Check if you have the DataStore service enabled

## 📊 Monitoring

### Admin Logs:
- All actions are logged in the server output
- DataStore saves logs for persistence
- Check Developer Console (F9) for detailed logs

### Ban Management:
- Use `/unban [userId]` to unban players
- Banned players are automatically kicked when joining
- Ban list persists across server restarts

## ⚠️ Important Notes

1. **Use Responsibly:** This system is for legitimate game administration
2. **Test First:** Always test new commands in a private server
3. **Backup Data:** Keep backups of your admin configuration
4. **Regular Updates:** Update admin lists as needed
5. **Monitor Usage:** Keep track of admin actions through logs

## 🤝 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all files are in correct locations
3. Ensure proper script types (ServerScript vs LocalScript vs ModuleScript)
4. Check for typos in User IDs and commands

This admin system is designed for legitimate game development and should only be used in games you own or have permission to modify.