# Windows 11 Glass Desktop Automation

Automated PowerShell script to transform your Windows 11 desktop with beautiful glass/translucent effects in one click.

![Windows 11 Glass Desktop](https://img.shields.io/badge/Windows-11-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE?style=for-the-badge&logo=powershell&logoColor=white)

## 🚀 Quick Start (3 Simple Steps)

```powershell
# 1. Download the script
git clone https://github.com/YOUR_USERNAME/windows-glass-desktop.git
cd windows-glass-desktop

# 2. Open PowerShell as Administrator, then run:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 3. Install everything automatically
.\Install-GlassDesktop.ps1
Install-GlassDesktop
```

That's it! Your Windows 11 desktop will now have beautiful glass effects. Restart your PC to see the full transformation.

## What This Does

This script automatically installs and configures three powerful tools to give your Windows 11 desktop a modern, translucent glass appearance:

- **MicaForEveryone** - Applies Mica/Acrylic effects to application windows
- **TranslucentTB** - Makes your taskbar translucent with blur effects
- **ExplorerBlurMica** - Adds beautiful blur effects to File Explorer

### Visual Effects Applied

- **Acrylic Window Backgrounds** - Frosted glass appearance on application windows
- **Acrylic Taskbar** - Translucent taskbar with blur
- **Acrylic File Explorer** - Blurred, modern look for Windows Explorer
- **Dark Theme Optimized** - Configurations tuned for dark mode aesthetics

## Prerequisites

- **Windows 10** (build 18362+) or **Windows 11**
- **Administrator privileges** (required for DLL registration)
- **Internet connection** (for downloading tools)
- **PowerShell 5.1+** (included with Windows)

## Installation

### Quick Start

1. **Download the script:**
   ```powershell
   git clone <repository-url>
   # OR download Install-GlassDesktop.ps1 directly
   ```

2. **Open PowerShell as Administrator:**
   - Right-click Start Menu → Windows Terminal (Admin) or PowerShell (Admin)

3. **Set execution policy** (if needed):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

4. **Run the installation:**
   ```powershell
   cd path\to\script
   .\Install-GlassDesktop.ps1
   Install-GlassDesktop
   ```

5. **Restart or log out/in** to see full effects

### What Happens During Installation

The script will:
1. ✅ Check Windows version compatibility
2. ✅ Verify administrator privileges
3. ✅ Install WinGet if not present
4. ✅ Download and install MicaForEveryone via WinGet
5. ✅ Download and install TranslucentTB via WinGet
6. ✅ Download ExplorerBlurMica from GitHub
7. ✅ Configure all tools with Acrylic effects
8. ✅ Register ExplorerBlurMica DLL
9. ✅ Restart Windows Explorer
10. ✅ Display installation summary

## Usage

### Install Glass Desktop
```powershell
.\Install-GlassDesktop.ps1
Install-GlassDesktop
```

### Uninstall Glass Desktop
```powershell
.\Install-GlassDesktop.ps1
Uninstall-GlassDesktop
```

The uninstall function will:
- Remove all three tools
- Unregister the ExplorerBlurMica DLL
- Clean up configuration files
- Restore default Windows appearance

## Configuration

### Default Settings Applied

The script configures all tools with these settings:

#### ExplorerBlurMica
- **Effect:** Acrylic (effect=1)
- **Clear Address Bar:** Enabled
- **Clear Toolbar Background:** Enabled
- **Show Dividing Line:** Enabled

#### MicaForEveryone
- **Global Effect:** Acrylic backdrop
- **Title Bar Color:** Dark
- **File Explorer:** Acrylic with system color

#### TranslucentTB
- **Default:** Acrylic frosted appearance
- **Customization:** Right-click tray icon after installation

### Customizing Effects

#### Change ExplorerBlurMica Effect
Edit: `C:\Program Files\ExplorerBlurMica\config.ini`

```ini
[config]
effect=1    ; 0=Blur, 1=Acrylic, 2=Mica, 3=Blur(Clear), 4=MicaAlt
```

After editing, restart Explorer:
```powershell
Stop-Process -Name explorer -Force
```

#### Change MicaForEveryone Settings
Edit: `%LOCALAPPDATA%\Mica For Everyone\config.xcl`

```
Global: "" {
    TitleBarColor = Dark
    BackdropPreference = Acrylic
}

Process: "notepad" {
    BackdropPreference = Mica
}
```

Launch MicaForEveryone from Start Menu to reload configuration.

#### Customize TranslucentTB
1. Right-click the TranslucentTB icon in system tray
2. Select preferred taskbar appearance:
   - Acrylic (frosted glass)
   - Clear (fully transparent)
   - Blur (simple blur)
   - Opaque (solid)

## Troubleshooting

### Script Won't Run
**Issue:** "execution of scripts is disabled on this system"

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### WinGet Not Found
**Issue:** Script can't find WinGet

**Solution:**
- Install "App Installer" from Microsoft Store
- Or download from: https://aka.ms/getwinget

### Effects Not Appearing
**Issue:** Installed but no visual changes

**Solutions:**
1. Log out and log back in
2. Restart your computer
3. Launch MicaForEveryone from Start Menu
4. Launch TranslucentTB from Start Menu
5. Ensure Windows 11 transparency effects are enabled:
   - Settings → Personalization → Colors → Transparency effects = ON

### ExplorerBlurMica Not Working
**Issue:** File Explorer has no blur effect

**Solutions:**
1. Verify DLL is registered:
   ```powershell
   regsvr32 "C:\Program Files\ExplorerBlurMica\ExplorerBlurMica.dll"
   ```
2. Check config.ini exists at: `C:\Program Files\ExplorerBlurMica\config.ini`
3. Restart Explorer:
   ```powershell
   Stop-Process -Name explorer -Force
   ```

### Access Denied Errors
**Issue:** Script fails with "Access Denied"

**Solution:**
- Run PowerShell as Administrator (required!)
- Disable antivirus temporarily if it blocks DLL registration

## Tools Used

This script automates the installation of these excellent open-source projects:

| Tool | Purpose | Repository |
|------|---------|------------|
| **MicaForEveryone** | Applies Mica/Acrylic to any app | [GitHub](https://github.com/MicaForEveryone/MicaForEveryone) |
| **ExplorerBlurMica** | Blur effects for File Explorer | [GitHub](https://github.com/Maplespe/ExplorerBlurMica) |
| **TranslucentTB** | Translucent taskbar | [GitHub](https://github.com/TranslucentTB/TranslucentTB) |

### Credits

All credit for the visual effects goes to the amazing developers of:
- [MicaForEveryone](https://github.com/MicaForEveryone/MicaForEveryone) by MicaForEveryone Team
- [ExplorerBlurMica](https://github.com/Maplespe/ExplorerBlurMica) by Maplespe
- [TranslucentTB](https://github.com/TranslucentTB/TranslucentTB) by TranslucentTB Team

This script simply automates their installation and configuration.

## FAQ

**Q: Is this safe?**
A: Yes! All tools are open-source and widely used. The script only downloads from official GitHub releases and Microsoft Store.

**Q: Will this slow down my computer?**
A: No. These tools have minimal performance impact. TranslucentTB uses <10MB RAM, MicaForEveryone is very lightweight.

**Q: Can I customize individual apps?**
A: Yes! Edit the MicaForEveryone config to apply different effects per application.

**Q: Does this work on Windows 10?**
A: Partially. Windows 10 (build 18362+) supports some effects, but full Mica/Acrylic requires Windows 11.

**Q: How do I update the tools?**
A: Run the installation script again, or use:
```powershell
winget upgrade --all
```

**Q: Will this survive Windows updates?**
A: Yes, but you may need to re-run the script if Windows updates break the effects.

## Uninstallation

To completely remove all glass effects and restore defaults:

```powershell
.\Install-GlassDesktop.ps1
Uninstall-GlassDesktop
```

The script will:
- Uninstall MicaForEveryone
- Uninstall TranslucentTB
- Unregister and remove ExplorerBlurMica
- Clean up all configuration files
- Restart Explorer

## License

This automation script is provided as-is for educational purposes. Each tool has its own license:
- MicaForEveryone: MIT License
- ExplorerBlurMica: MIT License
- TranslucentTB: GPL-3.0 License

## Screenshots

### Before
Standard Windows 11 opaque interface

### After
- Translucent taskbar with blur
- Frosted glass File Explorer
- Acrylic window backgrounds throughout the system

## Support

For issues with:
- **This script:** Open an issue in this repository
- **MicaForEveryone:** Visit [their GitHub](https://github.com/MicaForEveryone/MicaForEveryone/issues)
- **ExplorerBlurMica:** Visit [their GitHub](https://github.com/Maplespe/ExplorerBlurMica/issues)
- **TranslucentTB:** Visit [their GitHub](https://github.com/TranslucentTB/TranslucentTB/issues)

## Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

---

**Note:** This project is not affiliated with Microsoft. Windows 11 is a trademark of Microsoft Corporation.
