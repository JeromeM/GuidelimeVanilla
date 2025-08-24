# GuideLime Vanilla

A comprehensive World of Warcraft Classic (1.12) addon that provides an enhanced guide system with automatic quest tracking, TomTom integration, and smart UI management. **Now includes Sage 1-60 Alliance leveling guides built-in!**

## 🌟 Features

### 📚 Smart Guide System
- **Dynamic Step Management**: Automatically tracks completed and active quest steps
- **Checkbox Interface**: Visual progress tracking with clickable checkboxes
- **Step Highlighting**: Active steps are highlighted with a distinctive color scheme
- **Auto-scrolling**: Automatically scrolls to show the current active step
- **Built-in Guides**: Includes Sage 1-60 Alliance leveling guides
- **Multi-action Steps**: Supports steps with multiple quest actions (accept, complete, turnin)

### 🗺️ TomTom Integration
- **Automatic Waypoints**: Creates TomTom waypoints for quest objectives
- **Smart Coordinate Selection**: Automatically selects the most relevant coordinates based on step type
- **Multi-part Quest Support**: Handles complex quests with multiple objectives
- **Zone-aware Navigation**: Prioritizes coordinates within the quest's zone
- **Target-based Waypoints**: Supports [TAR] tags for specific NPC targeting

### 🎯 Quest Tracking
- **Automatic Progress**: Automatically checks off completed quest steps
- **Quest State Persistence**: Saves progress between sessions
- **Real-time Updates**: Updates automatically when quests are accepted or completed
- **Quest Abandonment Handling**: Properly manages quest state when quests are abandoned
- **XP Requirements**: Supports [XP] tags with level and percentage requirements

### 🎨 Enhanced User Interface
- **Modern Design**: Clean, organized interface with consistent styling
- **Icon Integration**: Clickable icons for special actions (e.g., Hearthstone usage)
- **Responsive Layout**: Adapts to different content lengths and screen sizes
- **Color-coded Steps**: Visual distinction between different step types
- **Settings Interface**: Built-in settings page for customization

### 🔧 Technical Features
- **Lua 5.0 Compatibility**: Fully compatible with WoW Classic 1.12
- **Efficient Memory Management**: Optimized for performance
- **Modular Architecture**: Clean separation of concerns
- **Error Handling**: Robust error handling and fallbacks
- **Ace2 Framework**: Built on the reliable Ace2 library

## 📦 Installation

### Prerequisites
- World of Warcraft Classic (1.12)
- Optional: [TomTom TWOW](https://github.com/laytya/TomTom-TWOW) for waypoint functionality

### Installation Steps
1. Download the addon files
2. Extract to your `World of Warcraft/Interface/AddOns/` directory
3. Ensure the folder name matches the addon name
4. Restart World of Warcraft

## 🚀 Usage

### Basic Guide Navigation
1. **Load a Guide**: Select a guide from the dropdown menu
2. **Follow Steps**: Complete quests and objectives as listed
3. **Track Progress**: Checkboxes automatically update as you progress
4. **Navigate**: Use the auto-scrolling feature to stay on track

### TomTom Integration
- **Automatic Waypoints**: Waypoints are created automatically for quest objectives
- **Manual Control**: Use TomTom's built-in controls to manage waypoints
- **Zone Awareness**: Coordinates are prioritized based on quest zone

### Quest Management
- **Accept Quests**: Steps automatically check off when quests are accepted
- **Complete Objectives**: Progress is tracked in real-time
- **Abandon Quests**: Properly handles quest abandonment and state updates

## 🎮 Supported Step Types

### Quest Steps
- **ACCEPT**: Quest acceptance steps with NPC coordinates
- **TURNIN**: Quest completion steps with turn-in NPC coordinates
- **COMPLETE**: Objective completion steps with target coordinates
- **OBJECTIVE**: General objective steps

### Utility Steps
- **REPAIR**: Equipment repair steps
- **VENDOR**: Vendor interaction steps
- **HEARTHSTONE**: Hearthstone usage steps (clickable icon)
- **BIND_HEARTHSTONE**: Automatic hearthstone binding steps

### Special Steps
- **Multi-line Steps**: Steps with multiple objectives or instructions
- **XP Requirements**: Steps with level or experience requirements
- **Target Steps**: Steps with specific NPC targeting [TAR]

## ⚙️ Configuration

### Settings
The addon automatically saves your progress and preferences:
- **Step State**: Tracks which steps are completed
- **Current Step**: Remembers your current position in guides
- **Quest Progress**: Maintains quest acceptance and completion states
- **Character Info**: Stores race, class, and faction information

### Customization
- **Colors**: Step highlighting colors can be modified in the code
- **Spacing**: UI element spacing is configurable
- **Icons**: Custom icons can be added for special actions

## 🔍 Technical Details

### Architecture
- **Core Module**: Main addon functionality and initialization
- **Guide Parser**: Parses guide text and extracts step information
- **Guide Writer**: Renders the UI and manages user interactions
- **Quest Tracker**: Monitors quest state changes
- **Character Tracker**: Monitors XP and level changes
- **Gossip Tracker**: Handles innkeeper interactions
- **TomTom Integration**: Handles waypoint creation and management
- **Database Tools**: Manages coordinate and quest data

### Dependencies
- **Ace2**: Core framework for addon management
- **TomTom TWOW**: Optional dependency for waypoint functionality

### File Structure
```
GuideLimeVanilla/
├── Core.lua                 # Main addon initialization
├── Core/                    # Core addon functionality
│   ├── GuideLibrary.lua     # Guide loading and management
│   ├── GuideParser.lua      # Guide text parsing
│   ├── GuideWriter.lua      # UI rendering and management
│   ├── TomTomIntegration.lua # TomTom waypoint integration
│   └── Events/
│       ├── Character.lua    # Character event handling (XP, level)
│       ├── Gossip.lua       # Gossip event handling
│       └── Quests.lua       # Quest event handling
├── Frames/                  # UI frame definitions
│   ├── Frames.lua          # Frame manipulation functions
│   ├── MainFrame.xml       # Main UI frame
│   └── SettingsFrame.xml   # Settings UI frame
├── Guides/                  # Guide files
│   ├── Sage/                # Sage 1-60 Alliance guides
│   │   ├── Sage_Guide_1-11_Dun_Morogh.lua
│   │   ├── Sage_Guide_1-11_Teldrassil.lua
│   │   └── Sage_Guide_1-11_Elwynn_Forest.lua
│   └── guides.xml           # Guide loading configuration
├── Helpers/
│   ├── DBTools.lua          # Database query functions
│   └── Helpers.lua          # Utility functions
├── libs/                    # Ace2 library files
└── DB/                      # Quest and coordinate databases
    ├── units.lua            # NPC coordinates
    ├── objects.lua          # Object coordinates
    ├── quests.lua           # Quest information
    ├── zones.lua            # Zone data
    ├── items.lua            # Item information
    └── spells.lua           # Spell information
```

## 📚 Adding New Guides

### Guide Format
Guides use the standard Guidelime format:
```
[N 1-11 Guide Name]
[D Description of the guide]
[GA Alliance] // or Horde
[OC] Optional completion step
[QA 123 Quest Accept]
[QC 123 Quest Complete]
[QT 123 Quest Turn In]
[XP 3] Level requirement
[XP 3.5] Level with XP percentage
[TAR 456] Target specific NPC
[NX 11-13 Next Guide]
```

### Adding to the Addon
1. Place your guide file in the `Guides/` directory (create subdirectories for organization)
2. Add the file to `Guides/guides.xml`
3. Restart WoW or use `/reload`

### Example guides.xml entry:
```xml
<Script file="MyGuides\My_Guide_1-10_Starting_Zone.lua"/>
```

## 🐛 Troubleshooting

### Common Issues
1. **TomTom Not Working**: Ensure TomTom TWOW is installed and enabled
2. **Guides Not Loading**: Check that all files are in the correct directory
3. **Progress Not Saving**: Verify that the addon has permission to save variables

### Debug Commands
- `/reload`: Reloads the UI and addon state
- `/run GLV:DebugGuides()`: Shows debug information about loaded guides
- Check chat for any error messages or debug information

## 🤝 Contributing

### Development
- **Code Style**: Follow existing code patterns and conventions
- **Testing**: Test changes thoroughly in WoW Classic 1.12
- **Documentation**: Update this README for any new features

### Adding Guides
- **Format**: Use standard Guidelime format
- **Testing**: Test guides thoroughly in-game
- **Documentation**: Update guides.xml when adding new guides

### Reporting Issues
- **Bug Reports**: Include steps to reproduce and any error messages
- **Feature Requests**: Describe the desired functionality clearly
- **Compatibility Issues**: Specify WoW version and other addons

## 📄 License

This addon is provided as-is for educational and entertainment purposes. Use at your own risk.

## 🙏 Acknowledgments

- **Original GuideLime**: For the foundation and inspiration
- **WoW Classic Community**: For testing and feedback
- **Sage**: For the excellent 1-60 Alliance leveling guides
- **Shagu**: For the databases (Quests, Items, Units, ...)
- **LaYT**: For the spells database, and TomTom TWOW !

## 📞 Support

For support, bug reports, or feature requests:
- Check the troubleshooting section above
- Review the code for any obvious issues
- Test with a clean addon installation

---

**Happy questing! 🎯✨**
