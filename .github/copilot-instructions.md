# Copilot Instructions for ThirdPerson SourceMod Plugin

## Repository Overview

This repository contains a SourceMod plugin written in SourcePawn that allows players to toggle third-person camera views in Source engine games (primarily Counter-Strike). The plugin provides both standard third-person view and a "mirror" rotational view mode.

### Key Components
- **Main Plugin**: `addons/sourcemod/scripting/ThirdPerson.sp` - Core plugin implementation
- **Include File**: `addons/sourcemod/scripting/include/ThirdPerson.inc` - Native functions for plugin integration
- **Build Configuration**: `sourceknight.yaml` - Build system configuration

## Development Environment

### Required Tools
- **SourceMod 1.11+**: The scripting platform for Source engine games
- **SourceKnight**: Build tool for SourceMod plugins (configured via `sourceknight.yaml`)
- **SourcePawn Compiler**: Latest compatible version (spcomp)

### Dependencies
The plugin depends on these SourceMod extensions/plugins:
- **MultiColors**: For colored chat messages (`#include <multicolors>`)
- **FullUpdate**: Optional - for client updates (`#include <FullUpdate>`)
- **ZombieReloaded**: Optional - for Zombie mod integration (`#include <zombiereloaded>`)

### Build System
This project uses SourceKnight as its build system:
```yaml
# sourceknight.yaml configures dependencies and build targets
project:
  name: ThirdPerson
  dependencies: [sourcemod, multicolors, FullUpdate]
  targets: [ThirdPerson]
```

**Building**: The CI system uses `maxime1907/action-sourceknight@v1` GitHub Action for builds.

## Code Style & Conventions

### SourcePawn Standards
```sourcepawn
#pragma semicolon 1        // Enforce semicolons
#pragma newdecls required  // Require new variable declarations

// Global variable naming
bool g_bThirdPerson[MAXPLAYERS + 1];  // Prefix with g_, use descriptive names
ConVar g_cvForceCamera;               // ConVars prefixed with g_cv

// Function naming
public void OnPluginStart()           // PascalCase for public functions
stock bool IsValidClient()            // PascalCase for stock functions
void ThirdPersonOn(int client)        // PascalCase for internal functions
```

### Memory Management
- Use `delete` for cleanup without null checks (SourceMod handles this)
- Avoid `.Clear()` on StringMap/ArrayList - use `delete` and recreate instead
- Clean up ConVar handles: `delete cvVariable;`

### Best Practices
- Use descriptive variable names and avoid abbreviations
- Include proper error handling for all API calls
- Use methodmaps for native functions
- All SQL operations must be asynchronous
- Implement proper client validation with `IsValidClient()`

## Plugin Architecture

### Event-Driven Design
The plugin follows SourceMod's event-based programming model:
```sourcepawn
public void OnPluginStart()     // Plugin initialization
public void OnClientPutInServer(int client)  // Client connection
public Action Event_PlayerDeath()    // Game event handling
```

### State Management
- Client states tracked in global arrays: `g_bThirdPerson[]`, `g_bMirror[]`
- Plugin state flags: `g_bZombieReloaded`, `g_bTeamManager`, `g_bFullUpdate`
- Reset client state on death/spawn events

### Native Function Implementation
```sourcepawn
public APLRes AskPluginLoad2()
{
    CreateNative("ThirdPerson_Status", Native_ThirdPerson);
    CreateNative("Mirror_Status", Native_Mirror);
    return APLRes_Success;
}
```

## Integration Patterns

### Optional Plugin Dependencies
```sourcepawn
#undef REQUIRE_PLUGIN
#tryinclude <zombiereloaded>
#define REQUIRE_PLUGIN

// Runtime detection
g_bZombieReloaded = LibraryExists("zombiereloaded");
```

### Conditional Compilation
```sourcepawn
#if defined _zr_included
    // ZombieReloaded specific code
#endif

#if defined _FullUpdate_Included
    if (g_bFullUpdate)
        ClientFullUpdate(client);
#endif
```

## Common Patterns

### Client Validation
```sourcepawn
stock bool IsValidClient(int client, bool bots = false, bool bAlive = false)
{
    return (client >= 1 && client <= MaxClients && 
            IsClientConnected(client) && IsClientInGame(client) && 
            (bots || !IsFakeClient(client)) && 
            (!bAlive || IsPlayerAlive(client)));
}
```

### Property Manipulation
```sourcepawn
// Third-person view setup
SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
SetEntProp(client, Prop_Send, "m_iFOV", 120);
```

### Command Registration
```sourcepawn
RegConsoleCmd("sm_thirdperson", Command_ThirdPerson, "Toggle thirdperson");
RegConsoleCmd("sm_tp", Command_ThirdPerson, "Toggle thirdperson");
```

## File Structure

```
addons/sourcemod/
├── scripting/
│   ├── ThirdPerson.sp          # Main plugin source
│   └── include/
│       └── ThirdPerson.inc     # Native function definitions
└── plugins/
    └── ThirdPerson.smx         # Compiled plugin (build output)
```

## Development Workflow

### Making Changes
1. Edit source files in `addons/sourcemod/scripting/`
2. Test locally with SourceMod development server
3. Use SourceKnight build system for compilation
4. Validate functionality before committing

### Testing Approach
- **Manual Testing**: Load plugin on development server
- **Command Testing**: Test `!tp`, `!thirdperson`, `!mirror` commands  
- **Event Testing**: Verify behavior on player death/spawn/round start
- **Integration Testing**: Test with ZombieReloaded if available

### Debugging
- Use SourceMod's built-in error logging
- Add debug prints with `PrintToServer()` for troubleshooting
- Check client indices and validity before operations
- Monitor for memory leaks using SourceMod profiler

## Security Considerations

- Validate all client inputs and indices
- Use proper bounds checking for arrays
- Escape strings in any SQL operations (though this plugin doesn't use SQL)
- Avoid hardcoded paths or values

## Performance Guidelines

- Minimize operations in frequently called functions (OnGameFrame, etc.)
- Cache expensive lookups (ConVar values, client teams)
- Use efficient data structures (StringMap over arrays for lookups)
- Consider tick rate impact of real-time operations

## Version Management

- Follow semantic versioning in plugin info
- Update version in `ThirdPerson.sp` plugin info structure
- Coordinate with repository tags for releases
- Document breaking changes in commit messages

## Common Issues

### Third-Person View Problems
- Ensure `mp_forcecamera` ConVar is properly handled
- Reset view properties on client disconnect/death
- Handle team changes properly to avoid UI glitches

### Integration Issues
- Check plugin load order for dependencies
- Use proper library existence checks before calling natives
- Handle optional dependencies gracefully

### Memory Issues
- Always clean up ConVar handles with `delete`
- Avoid memory leaks in timer callbacks
- Reset client state arrays properly

## CI/CD Pipeline

The repository uses GitHub Actions with SourceKnight:
- Automatic building on push/PR
- Artifact generation for releases
- Version tagging for releases

When modifying build configuration, update `sourceknight.yaml` accordingly.

## Getting Started for New Contributors

1. **Environment Setup**: Ensure SourceMod 1.11+ is available for testing
2. **Clone & Build**: Use the SourceKnight build system (`sourceknight.yaml`)
3. **Code Review**: Follow the established patterns in `ThirdPerson.sp`
4. **Testing**: Validate changes on a development server with the target game
5. **Integration**: Test compatibility with optional dependencies (ZombieReloaded, etc.)

This plugin serves as a good example of SourceMod plugin architecture, event handling, and integration patterns within the SourceMod ecosystem.