# Directory Structure for Roblox Admin System

## 📁 File Organization

This document shows exactly where each file should be placed in your Roblox Studio project.

```
📁 Your Roblox Game
├── 📁 ServerScriptService
│   └── 📁 AdminSystem/
│       ├── 📄 Config.lua (ModuleScript)
│       ├── 📄 AdminCore.lua (ServerScript) 
│       └── 📄 Commands.lua (ModuleScript)
│
├── 📁 StarterPlayer
│   └── 📁 StarterPlayerScripts/
│       └── 📄 AdminClient.lua (LocalScript)
│
└── 📁 ReplicatedStorage
    └── 📁 AdminRemotes/ (Auto-created by AdminCore.lua)
        ├── 📄 ExecuteCommand (RemoteEvent)
        ├── 📄 ConsoleToggle (RemoteEvent)
        └── 📄 AdminLog (RemoteEvent)
```

## 🛠️ Script Types Reference

| File | Type | Location | Purpose |
|------|------|----------|---------|
| `Config.lua` | **ModuleScript** | ServerScriptService/AdminSystem/ | Admin configuration and settings |
| `AdminCore.lua` | **ServerScript** | ServerScriptService/AdminSystem/ | Main server-side admin logic |
| `Commands.lua` | **ModuleScript** | ServerScriptService/AdminSystem/ | All admin command implementations |
| `AdminClient.lua` | **LocalScript** | StarterPlayer/StarterPlayerScripts/ | Client-side GUI and interface |

## 📋 Step-by-Step Setup

### 1. ServerScriptService Setup

1. **Right-click** on `ServerScriptService`
2. **Insert Object** → `Folder`
3. **Rename** the folder to `AdminSystem`
4. **Right-click** on the `AdminSystem` folder

For each server file:

#### Config.lua (ModuleScript)
1. **Insert Object** → `ModuleScript`
2. **Rename** to `Config`
3. **Replace** the default code with the Config.lua content

#### AdminCore.lua (ServerScript)
1. **Insert Object** → `ServerScript`  
2. **Rename** to `AdminCore`
3. **Replace** the default code with the AdminCore.lua content

#### Commands.lua (ModuleScript)
1. **Insert Object** → `ModuleScript`
2. **Rename** to `Commands`
3. **Replace** the default code with the Commands.lua content

### 2. StarterPlayer Setup

1. Navigate to `StarterPlayer` → `StarterPlayerScripts`
2. **Right-click** on `StarterPlayerScripts`
3. **Insert Object** → `LocalScript`
4. **Rename** to `AdminClient`
5. **Replace** the default code with the AdminClient.lua content

### 3. Verification

After setup, your Explorer should look like this:

```
🔧 ServerScriptService
├── 📁 AdminSystem
│   ├── 📜 Config (ModuleScript)
│   ├── 📜 AdminCore (ServerScript)
│   └── 📜 Commands (ModuleScript)

👤 StarterPlayer
└── 📁 StarterPlayerScripts
    └── 📜 AdminClient (LocalScript)
```

## ⚡ Auto-Generated Components

When you run the game, `AdminCore.lua` will automatically create:

```
🔄 ReplicatedStorage
└── 📁 AdminRemotes
    ├── 🔗 ExecuteCommand (RemoteEvent)
    ├── 🔗 ConsoleToggle (RemoteEvent)
    └── 🔗 AdminLog (RemoteEvent)
```

**Note:** These are automatically created - don't create them manually!

## 🎯 Important Script Type Notes

### ModuleScript vs ServerScript vs LocalScript

- **ModuleScript**: Shared code that can be required by other scripts
  - Use for: Configuration, shared functions, command definitions
  - Examples: `Config.lua`, `Commands.lua`

- **ServerScript**: Runs on the server only
  - Use for: Game logic, admin actions, data management
  - Examples: `AdminCore.lua`

- **LocalScript**: Runs on the client only
  - Use for: User interfaces, input handling, client-side effects
  - Examples: `AdminClient.lua`

### Common Mistakes to Avoid

❌ **Wrong script types:**
- Don't make `AdminCore.lua` a LocalScript
- Don't make `AdminClient.lua` a ServerScript
- Don't make `Config.lua` a regular Script

❌ **Wrong locations:**
- ServerScripts won't work in StarterPlayerScripts
- LocalScripts won't work in ServerScriptService
- ModuleScripts need to be required by other scripts

✅ **Correct setup:**
- Follow the directory structure exactly as shown
- Use the correct script types for each file
- Ensure proper parent-child relationships

## 🔍 Testing Your Setup

1. **Play test** with 2+ players in Studio
2. **Check Output** for these messages:
   ```
   [ADMIN SYSTEM] Server-side admin system loaded successfully!
   [ADMIN CLIENT] Admin client script loaded successfully!
   ```
3. **Verify GUI** appears for admin players
4. **Test commands** in chat or admin panel

## 🆘 Troubleshooting Structure Issues

### Problem: "AdminSystem is not a valid member of ServerScriptService"
**Solution:** Check that you created the AdminSystem folder correctly in ServerScriptService

### Problem: "Config is not a valid member of AdminSystem"
**Solution:** Ensure Config.lua is a ModuleScript (not ServerScript) inside AdminSystem

### Problem: Admin GUI not showing
**Solution:** Verify AdminClient.lua is a LocalScript in StarterPlayerScripts

### Problem: Commands not working
**Solution:** Check that AdminCore.lua is a ServerScript and running properly

### Problem: RemoteEvents not found
**Solution:** Wait for AdminCore.lua to create them automatically - don't create manually

This structure ensures proper communication between server and client components while maintaining security and organization.