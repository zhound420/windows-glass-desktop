# Contributing to Windows Glass Desktop Automation

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and encourage diverse perspectives
- Focus on constructive feedback
- Respect differing viewpoints and experiences

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title** - Descriptive summary of the issue
- **Steps to reproduce** - Detailed steps to recreate the problem
- **Expected behavior** - What you expected to happen
- **Actual behavior** - What actually happened
- **Environment details**:
  - Windows version (e.g., Windows 11 Build 22621)
  - PowerShell version (`$PSVersionTable.PSVersion`)
  - Script version
- **Screenshots** - If applicable
- **Error messages** - Full error output from PowerShell

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- **Clear description** - What feature you'd like to see
- **Use case** - Why this would be useful
- **Examples** - How it might work or look
- **Alternatives** - Other solutions you've considered

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** with clear, descriptive commits
3. **Test thoroughly** on a clean Windows installation if possible
4. **Update documentation** - README, CHANGELOG, code comments
5. **Follow coding standards** (see below)
6. **Submit pull request** with comprehensive description

## Development Guidelines

### PowerShell Coding Standards

- Use **PascalCase** for function names (e.g., `Install-GlassDesktop`)
- Use **kebab-case** for file names (e.g., `install-script.ps1`)
- Use **camelCase** for variable names (e.g., `$installPath`)
- Include **comment-based help** for all functions
- Add **`#Requires -RunAsAdministrator`** for admin scripts
- Use **approved verbs** for function names (Get, Set, New, Remove, etc.)

### Code Style

```powershell
# Good
function Install-Component {
    <#
    .SYNOPSIS
        Brief description of what this function does.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComponentName
    )

    try {
        Write-Host "Installing $ComponentName..." -ForegroundColor Cyan
        # Installation logic here
        Write-Host "Successfully installed $ComponentName" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "ERROR: Failed to install $ComponentName : $_" -ForegroundColor Red
        return $false
    }
}
```

### Error Handling

- Always use `try-catch` blocks for operations that might fail
- Provide meaningful error messages with context
- Use color-coded output: Green (success), Yellow (warning), Red (error)
- Return boolean values to indicate success/failure
- Never suppress errors silently

### Testing

Before submitting:

1. **Test clean install** - Run on fresh Windows install or VM
2. **Test uninstall** - Verify complete removal of all components
3. **Test error conditions**:
   - Missing administrator privileges
   - No internet connection
   - Corrupted downloads
   - Already installed components
4. **Test on Windows 10 and 11** if possible

### Commit Messages

Use clear, descriptive commit messages:

```
Add support for custom color schemes

- Implement color configuration parsing
- Add preset color themes (dark, light, custom)
- Update README with color customization guide
```

Format:
- **First line**: Brief summary (50 chars or less)
- **Body**: Detailed explanation (wrapped at 72 chars)
- **Reference**: Link to issue if applicable (e.g., "Fixes #123")

### Documentation

When adding features:

- Update **README.md** with usage examples
- Add entry to **CHANGELOG.md** under [Unreleased]
- Include **inline comments** for complex logic
- Update **function help** with `.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`

## Project Structure

```
windows-glass-desktop/
├── Install-GlassDesktop.ps1  # Main script with all functions
├── README.md                  # User documentation
├── CHANGELOG.md               # Version history
├── CONTRIBUTING.md            # This file
├── LICENSE                    # MIT License
└── .gitignore                # Git ignore patterns
```

## Feature Ideas

Looking for contribution ideas? Consider:

- **Auto-updater** - Check for and install tool updates
- **Configuration presets** - Light, dark, minimal, maximum blur
- **GUI interface** - Simple WPF or WinForms configuration UI
- **Gaming mode** - Disable effects when games launch
- **Export/import configs** - Save and share configurations
- **Multi-language support** - Internationalization
- **Scheduled effects** - Enable/disable at certain times
- **Per-app profiles** - Different effects for different apps

## Questions?

Feel free to:
- Open an issue for questions
- Start a discussion in GitHub Discussions
- Check existing issues and pull requests

## Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes for significant contributions
- GitHub contributors page

Thank you for contributing to make Windows 11 more beautiful!
