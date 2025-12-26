# Prophet.nvim Performance & UX Improvements

## Overview
Fixed critical performance and user experience issues with prophet.nvim integration in VimZap.

## Problems Solved

### 1. ❌ Intrusive Modal Progress Window
**Before**: Custom modal window appeared in center of screen, blocking editing workflow
```lua
-- Created disruptive centered modal
progress_win = vim.api.nvim_open_win(progress_buf, false, {
  relative = "editor",
  width = 41,
  height = 6,
  row = math.floor((ui.height - 6) / 2), -- CENTER OF SCREEN!
  style = "minimal",
})
```

**After**: ✅ Uses VimZap's notification system
```lua
-- Non-intrusive notifications in corner
snacks.notifier.notify(msg, "info", {
  timeout = false,
  title = "Prophet Upload"
})
```

### 2. ❌ UI Blocking During Uploads
**Before**: Synchronous operations blocked the UI during upload sequences
```lua
upload_next(index + 1) // Immediately chains to next upload
```

**After**: ✅ Added UI yielding between operations
```lua
vim.schedule(function()
  upload_next(index + 1) -- Allows UI updates
end)
```

### 3. ❌ Startup Performance Lag
**Before**: `clean_on_start = true` uploaded all cartridges on VimZap startup
**After**: ✅ `clean_on_start = false` prevents automatic startup uploads

### 4. ❌ Aggressive Upload Triggers
**Before**: 1000ms debounce - too frequent uploads on file changes
**After**: ✅ 2000ms debounce - reduced upload frequency

## VSCode Prophet vs Our Implementation

### **Why VSCode Prophet Doesn't Lag:**

**VSCode Prophet Architecture:**
- **Individual file uploads** with 3-5 concurrent operations
- **RxJS Observables** for non-blocking streams
- **400ms debouncing** to batch rapid file changes  
- **Built-in progress APIs** that don't block UI thread
- **Automatic retries** with exponential backoff

**Original prophet.nvim Issues:**
- ❌ **Sequential zip operations** (zip → upload → unzip → cleanup)
- ❌ **Nested callbacks** without proper UI yielding
- ❌ **Synchronous file operations** blocking main thread
- ❌ **Custom modal** interrupting workflow

### **Our Solution: VSCode Prophet Pattern in Neovim**

**New Architecture:**
- ✅ **Direct file uploads** (like VSCode Prophet)
- ✅ **Concurrent job control** (max 3 simultaneous)
- ✅ **400ms debouncing** (matching VSCode)
- ✅ **Corner notifications** (non-intrusive)
- ✅ **Proper async with vim.schedule_wrap()**

## Files Modified

### 1. `/lua/prophet/utils/init.lua`
- Replaced custom modal with VimZap notifications
- Added `hide_progress()` function for cleanup
- Maintains backward compatibility with fallback to `vim.notify()`

### 2. `/lua/prophet/uploader/init.lua` 
**Major Rewrite - Now Uses VSCode Prophet Pattern:**
- **New**: Direct file uploads (`upload_file_async`) like VSCode Prophet
- **New**: Concurrent job management (max 3 uploads)
- **New**: 400ms debouncing to match VSCode behavior
- **New**: Proper error handling with retry support
- **Improved**: All operations use `vim.schedule_wrap()` for UI yielding
- **Kept**: Legacy zip methods for backward compatibility

### 3. `/lua/plugins.lua` (VimZap config)
- Changed `clean_on_start = false` to prevent startup lag
- Added comment explaining the change

## User Experience Improvements

### ✅ **Non-Intrusive Progress**
- Progress appears in notification area (corner)
- Doesn't interrupt editing workflow
- Consistent with other VimZap operations

### ✅ **Responsive UI**
- No more freezing during uploads
- UI remains interactive during operations
- Proper yielding between async operations

### ✅ **Faster Startup**
- No automatic upload on VimZap initialization
- Clean uploads only when explicitly requested (`<leader>pc`)

### ✅ **Consistent Notifications**
- All prophet.nvim feedback uses VimZap's notification system
- Matches user expectations from other VimZap features
- Proper error/info/warning styling

## Usage

Prophet.nvim now works seamlessly with VimZap:

```
<leader>pe  - Enable auto-upload (file watching)
<leader>pd  - Disable auto-upload  
<leader>pt  - Toggle auto-upload
<leader>pc  - Clean upload all cartridges (manual)
```

**Notifications appear in corner** instead of blocking the center of the screen.

## Testing

To verify the improvements:

1. Open a SFCC project with `dw.json`
2. Use `<leader>pc` to trigger clean upload
3. Observe: 
   - ✅ Notifications appear in corner (not center)
   - ✅ Editor remains responsive during upload
   - ✅ No startup lag when opening VimZap

## Backward Compatibility

All changes maintain backward compatibility:
- Falls back to `vim.notify()` if VimZap's `Snacks.notifier` unavailable
- Existing keymaps and commands unchanged
- Configuration options remain the same

## Performance Impact

**Before**: UI freezes, modal blocks editing, startup delays
**After**: Smooth operation, corner notifications, fast startup

Prophet.nvim now provides excellent user experience that matches VimZap's design philosophy.