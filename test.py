import pyautogui
import keyboard

def locate_cursor_coords():
    while True:
        x, y = pyautogui.position()
        positionStr = 'X: ' + str(x).rjust(4) + ' Y: ' + str(y).rjust(4)
        print(positionStr, end='')
        print('\b' * len(positionStr), end='', flush=True)
        if keyboard.is_pressed('Del'):
            print("\nExiting cursor locator.")
            return

if __name__ == "__main__":
    locate_cursor_coords()