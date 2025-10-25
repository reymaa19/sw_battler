import time
import keyboard
import cv2
import numpy as np
import ctypes
from ctypes import wintypes, windll
import sys

# Windows API definitions for low-level cursor control
user32 = windll.user32
kernel32 = windll.kernel32

# Define Windows API structures and constants
class POINT(ctypes.Structure):
    _fields_ = [("x", ctypes.c_long), ("y", ctypes.c_long)]

class MOUSEINPUT(ctypes.Structure):
    _fields_ = [("dx", wintypes.LONG),
                ("dy", wintypes.LONG),
                ("mouseData", wintypes.DWORD),
                ("dwFlags", wintypes.DWORD),
                ("time", wintypes.DWORD),
                ("dwExtraInfo", ctypes.POINTER(wintypes.ULONG))]

class INPUT(ctypes.Structure):
    class _INPUT(ctypes.Union):
        _fields_ = [("mi", MOUSEINPUT)]
    _anonymous_ = ("_input",)
    _fields_ = [("type", wintypes.DWORD),
                ("_input", _INPUT)]

# Input types
INPUT_MOUSE = 0
MOUSEEVENTF_MOVE = 0x0001
MOUSEEVENTF_ABSOLUTE = 0x8000

def ultra_brutal_move_cursor(x, y):
    """
    Ultra aggressive cursor movement that bypasses even the most restrictive games
    Uses multiple hardware-level and driver-level approaches
    """
    try:
        print(f"Attempting ultra brutal cursor move to: {x}, {y}")
        
        # Method 1: Temporarily disable cursor clipping
        # Games often use ClipCursor to lock the cursor
        user32.ClipCursor(None)  # Remove any cursor clipping
        time.sleep(0.01)
        
        # Method 2: Force cursor position multiple times rapidly
        for i in range(10):
            user32.SetCursorPos(int(x), int(y))
            if i % 3 == 0:
                time.sleep(0.001)  # Micro delays
        
        # Method 3: Use mouse_event (older but sometimes more effective)
        # Convert to normalized coordinates for mouse_event
        screen_width = user32.GetSystemMetrics(0)
        screen_height = user32.GetSystemMetrics(1)
        norm_x = int((x * 65535) / screen_width)
        norm_y = int((y * 65535) / screen_height)
        
        MOUSEEVENTF_ABSOLUTE = 0x8000
        MOUSEEVENTF_MOVE = 0x0001
        user32.mouse_event(MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE, norm_x, norm_y, 0, 0)
        time.sleep(0.01)
        
        # Method 4: SendInput with multiple attempts
        for attempt in range(5):
            extra = ctypes.c_ulong(0)
            ii_ = INPUT()
            ii_.type = INPUT_MOUSE
            ii_.mi.dx = norm_x
            ii_.mi.dy = norm_y
            ii_.mi.mouseData = 0
            ii_.mi.dwFlags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE
            ii_.mi.time = 0
            ii_.mi.dwExtraInfo = ctypes.pointer(extra)
            
            user32.SendInput(1, ctypes.byref(ii_), ctypes.sizeof(ii_))
            user32.SetCursorPos(int(x), int(y))  # Follow up immediately
            time.sleep(0.002)
        
        # Method 5: Try to break cursor lock by simulating window focus change
        hwnd = user32.GetForegroundWindow()
        user32.SetForegroundWindow(hwnd)  # Refocus current window
        user32.SetCursorPos(int(x), int(y))
        
        # Method 6: Use raw input injection (most hardware-level)
        try:
            # This bypasses most application-level filtering
            kernel32 = windll.kernel32
            user32.SetCursorPos(int(x), int(y))
            
            # Force a window message to update cursor position
            WM_MOUSEMOVE = 0x0200
            lParam = (int(y) << 16) | int(x)
            user32.PostMessageW(hwnd, WM_MOUSEMOVE, 0, lParam)
            
        except Exception as e:
            print(f"Raw input method failed: {e}")
        
        # Method 7: Final verification and force
        current_pos = POINT()
        user32.GetCursorPos(ctypes.byref(current_pos))
        
        if abs(current_pos.x - x) > 5 or abs(current_pos.y - y) > 5:
            print(f"Cursor not at target. Current: {current_pos.x}, {current_pos.y}")
            # Nuclear option: Block input and force multiple times
            user32.BlockInput(True)
            for _ in range(20):
                user32.SetCursorPos(int(x), int(y))
            user32.BlockInput(False)
            
            # Check again
            user32.GetCursorPos(ctypes.byref(current_pos))
            print(f"After nuclear option: {current_pos.x}, {current_pos.y}")
        
        print(f"Ultra brutal cursor move completed. Final position: {current_pos.x}, {current_pos.y}")
        return True
        
    except Exception as e:
        print(f"Ultra brutal cursor move failed: {e}")
        return False

def brutal_move_cursor(x, y):
    """
    Standard brutal cursor movement - kept as fallback
    """
    try:
        user32.SetCursorPos(int(x), int(y))
        time.sleep(0.01)
        
        # Multiple rapid attempts
        for _ in range(5):
            user32.SetCursorPos(int(x), int(y))
            time.sleep(0.003)
            
        print(f"Standard brutal cursor move to: {x}, {y}")
        return True
        
    except Exception as e:
        print(f"Standard brutal cursor move failed: {e}")
        return False

def game_aware_cursor_move(x, y):
    """
    Game-aware cursor movement that tries to work around common game restrictions
    """
    try:
        # First, try to detect if we're dealing with a fullscreen game
        hwnd = user32.GetForegroundWindow()
        
        # Get window class name to identify game type
        class_name = ctypes.create_unicode_buffer(256)
        user32.GetClassNameW(hwnd, class_name, 256)
        
        print(f"Active window class: {class_name.value}")
        
        # Common game engine classes that need special handling
        game_classes = ['UnityWndClass', 'UnrealWindow', 'SDL_Window', 'GLFW30']
        is_likely_game = any(gc in class_name.value for gc in game_classes)
        
        if is_likely_game:
            print("Detected game window - using ultra brutal methods")
            return ultra_brutal_move_cursor(x, y)
        else:
            print("Regular window - using standard brutal methods")
            return brutal_move_cursor(x, y)
            
    except Exception as e:
        print(f"Game-aware cursor move failed: {e}")
        return ultra_brutal_move_cursor(x, y)  # Fallback to ultra brutal

def find_image_opencv(template_path, confidence=0.8):
    """
    Find image using OpenCV instead of pyautogui for better performance
    """
    try:
        # Take screenshot using Windows API
        import mss
        with mss.mss() as sct:
            screenshot = sct.grab(sct.monitors[1])
            img = np.array(screenshot)
            img = cv2.cvtColor(img, cv2.COLOR_BGRA2BGR)
        
        # Load template
        template = cv2.imread(template_path, cv2.IMREAD_COLOR)
        if template is None:
            print(f"Could not load template: {template_path}")
            return None
            
        # Template matching
        result = cv2.matchTemplate(img, template, cv2.TM_CCOEFF_NORMED)
        min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(result)
        
        if max_val >= confidence:
            h, w = template.shape[:2]
            center_x = max_loc[0] + w // 2
            center_y = max_loc[1] + h // 2
            return (center_x, center_y)
        return None
        
    except Exception as e:
        print(f"OpenCV image search failed: {e}")
        return None

def simulate_f3_keypress():
    """
    Simulate F3 keypress using low-level Windows API
    """
    try:
        # Virtual key code for F3
        VK_F3 = 0x72
        
        # Send keydown
        user32.keybd_event(VK_F3, 0, 0, 0)
        time.sleep(0.05)
        # Send keyup
        user32.keybd_event(VK_F3, 0, 2, 0)  # 2 = KEYEVENTF_KEYUP
        
        print("F3 key pressed using low-level API")
        return True
        
    except Exception as e:
        print(f"F3 keypress failed: {e}")
        return False

def replay_battle():
    iterations = 0
    print("Starting brutal battle replay system...")
    print("Press 'q' to quit")
    
    while True:
        time.sleep(5)
        try:
            # Use OpenCV-based image detection instead of pyautogui
            center = find_image_opencv('images/add.png', confidence=0.8)
            
            if center:
                iterations += 1
                print(f"Battle replayed {iterations} times.")
                print(f"Add button found at: {center}")
                
                # Use game-aware cursor movement
                if game_aware_cursor_move(center[0], center[1]):
                    time.sleep(0.1)  # Small delay to ensure cursor is positioned
                    simulate_f3_keypress()
                else:
                    print("Failed to move cursor, skipping F3 press")
                    
            else:
                print("Add button not found on screen.")
                
        except Exception as e:
            print(f"Error in replay loop: {e}")
            
        if keyboard.is_pressed('q'):
            print("Quitting battle replay...")
            return
        
replay_battle()