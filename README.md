# 🎮 Dodol Hub - Roblox Script Hub

Your ultimate collection of Roblox scripts in one beautiful hub!

## 📋 Available Scripts

- **📷 Free Camera** - Smooth camera controls with voice chat support
- **🚀 Movement Suite** - Fly, Run, Noclip & Teleport with professional UI
- **📍 Checkpoint Teleporter** - Smart checkpoint scanner and teleporter

## 🚀 How to Use

### Method 1: Execute via Loadstring (Recommended)

Copy and paste this into your executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/DodolHub.lua"))()
```

### Method 2: Direct File Execution

1. Download all the scripts
2. Load them into your executor
3. Execute DodolHub.lua first

## 📦 Setting Up GitHub (For Script Owners)

### Step 1: Create a GitHub Account
1. Go to [github.com](https://github.com)
2. Sign up for a free account
3. Verify your email

### Step 2: Create a New Repository
1. Click the **+** icon in the top right
2. Select **New repository**
3. Name it something like `dodol-hub` or `roblox-scripts`
4. Choose **Public** (required for raw links)
5. Click **Create repository**

### Step 3: Upload Your Scripts
1. Click **uploading an existing file**
2. Drag and drop all your `.lua` files:
   - DodolHub.lua
   - FreeCameraScript.lua
   - FLY.lua
   - CHECKPOINT NEW.lua
3. Click **Commit changes**

### Step 4: Get Raw URLs
For each file:
1. Click on the file in GitHub
2. Click the **Raw** button
3. Copy the URL from your browser
4. It should look like: `https://raw.githubusercontent.com/USERNAME/REPO/main/FILENAME.lua`

### Step 5: Update DodolHub.lua
1. Open `DodolHub.lua`
2. Find the `Scripts` table
3. Replace `YOUR_USERNAME` and `YOUR_REPO` with your actual GitHub username and repository name
4. Upload the updated file to GitHub

Example:
```lua
ScriptUrl = "https://raw.githubusercontent.com/JohnDoe/dodol-hub/main/FreeCameraScript.lua"
```

### Step 6: Test Your Hub
Run this in your executor:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/DodolHub.lua"))()
```

## 🔧 Executor Compatibility

This hub is compatible with most popular Roblox executors:

✅ **Xeno**
✅ **Synapse X**
✅ **KRNL**
✅ **Fluxus**
✅ **Arceus X** (Mobile)
✅ **Delta** (iOS)
✅ **Script-Ware**
✅ **Electron**

### Compatibility Features:
- Uses `game:HttpGet()` instead of custom HTTP functions
- Standard `loadstring()` for execution
- No executor-specific dependencies
- Pure Lua implementation
- No file system operations (readfile/writefile)

## 🎨 Features

### Hub Features:
- 🌟 Beautiful loading animations
- 🎯 Easy script selection
- 🖱️ Draggable interface
- 🎨 Smooth transitions
- 📱 Clean and modern UI

### Script Features:
- 🎮 Back to Hub button (choose more scripts)
- 👁️ Hide GUI button (with keyboard shortcut)
- ✕ Exit button (clean script removal)
- 🔄 No conflicts between scripts
- ⌨️ Keyboard shortcuts

## 📝 Adding New Scripts

To add a new script to your hub:

1. Upload your script to GitHub
2. Get the raw URL
3. Edit `DodolHub.lua`
4. Add to the Scripts table:

```lua
{
    Name = "Your Script Name",
    Description = "What it does",
    Icon = "🎯",
    ScriptUrl = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/YourScript.lua",
    Color = Color3.fromRGB(255, 100, 150)
}
```

5. Make sure your script includes these buttons:
   - Back to Hub: `_G.DodolHub.Show()`
   - Hide GUI: Your custom implementation
   - Exit: Clean up and show hub

## 🛠️ For Script Developers

### Integrate Your Script with Hub

Add these functions to your script:

```lua
-- At the end of your script initialization:

-- Hub Button (returns to hub)
HubButton.MouseButton1Click:Connect(function()
    if _G.DodolHub and _G.DodolHub.Show then
        _G.DodolHub.Show()
        YourScriptGui.Enabled = false
    end
end)

-- Exit Button (clean up and return to hub)
ExitButton.MouseButton1Click:Connect(function()
    -- Your cleanup code here
    
    YourScriptGui:Destroy()
    
    if _G.DodolHub and _G.DodolHub.Show then
        _G.DodolHub.Show()
    end
end)
```

## 🐛 Troubleshooting

### "HttpService is not enabled"
This error means the game has HTTP requests disabled. The hub won't work in these games.

### "Unable to load script"
- Check your internet connection
- Verify the GitHub URLs are correct
- Make sure your repository is public

### "Executor crashed"
- Try using a different executor
- Some games have strong anti-cheat
- Make sure you're using the latest executor version

## ⚠️ Disclaimer

This is for educational purposes only. Use responsibly and follow Roblox Terms of Service.

## 📄 License

Free to use and modify. Credit appreciated but not required.

---

Made with ❤️ by Dodol Hub Team
