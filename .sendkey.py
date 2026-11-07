#!/usr/bin/env python3
# Send key taps through /dev/uinput (works for Wayland and XWayland apps).
import os, sys, time, fcntl, ctypes
K = {"return": 28, "enter": 28, "space": 57, "esc": 1, "x": 45, "z": 44,
     "a": 30, "s": 31, "left": 105, "right": 106, "up": 103, "down": 108}
EV_KEY = 1; EV_SYN = 0
def ev(t, c, v): return bytes([0]*8 + [0]*8 + list(ctypes.string_at(ctypes.byref(ctypes.c_ushort(t)), 2)) + list(ctypes.string_at(ctypes.byref(ctypes.c_ushort(c)), 2)) + list(ctypes.string_at(ctypes.byref(ctypes.c_int(v)), 4)))
class E(ctypes.Structure):
    _fields_ = [("s", ctypes.c_long), ("us", ctypes.c_long), ("t", ctypes.c_ushort), ("c", ctypes.c_ushort), ("v", ctypes.c_int)]
def e(t, c, v): return bytes(E(0, 0, t, c, v))
UI_DEV_SETUP = 0x405c5503; UI_SET_EVBIT = 0x40045564; UI_SET_KEYBIT = 0x40045565
UI_DEV_CREATE = 0x5501; UI_DEV_DESTROY = 0x5502
fd = os.open("/dev/uinput", os.O_WRONLY | os.O_NONBLOCK)
fcntl.ioctl(fd, UI_SET_EVBIT, EV_KEY); fcntl.ioctl(fd, UI_SET_EVBIT, EV_SYN)
for c in range(1, 248):
    try: fcntl.ioctl(fd, UI_SET_KEYBIT, c)
    except OSError: pass
class S(ctypes.Structure):
    _fields_ = [("b", ctypes.c_uint16), ("v", ctypes.c_uint16), ("p", ctypes.c_uint16), ("ver", ctypes.c_uint16), ("n", ctypes.c_char*80), ("f", ctypes.c_uint32)]
fcntl.ioctl(fd, UI_DEV_SETUP, S(3, 0x1d6b, 0x0104, 1, b"m1000-sendkey", 0))
fcntl.ioctl(fd, UI_DEV_CREATE)
time.sleep(1.5)
def tap(code):
    os.write(fd, e(EV_KEY, code, 1)); os.write(fd, e(EV_SYN, 0, 0)); time.sleep(0.08)
    os.write(fd, e(EV_KEY, code, 0)); os.write(fd, e(EV_SYN, 0, 0)); time.sleep(0.25)
for name in sys.argv[1:]:
    tap(K[name])
fcntl.ioctl(fd, UI_DEV_DESTROY); os.close(fd)
