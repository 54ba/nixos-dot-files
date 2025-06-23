import os
import subprocess
from libqtile import bar, layout, qtile, widget, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy

# Configuration variables
mod = "mod4"
terminal = "kitty"

# Get wireless interface dynamically
def get_wireless_interface():
    try:
        result = subprocess.run(['ip', 'link', 'show'], capture_output=True, text=True)
        for line in result.stdout.split('\n'):
            if 'wl' in line and 'state UP' in line:
                return line.split(':')[1].strip()
        # Fallback: try common names
        for iface in ['wlan0', 'wlp2s0', 'wlp0s20f3', 'wlo1']:
            if os.path.exists(f'/sys/class/net/{iface}'):
                return iface
    except Exception:
        pass
    return None

# Get battery status
def has_battery():
    try:
        return os.path.exists('/sys/class/power_supply/BAT0') or \
               os.path.exists('/sys/class/power_supply/BAT1') or \
               any(os.path.exists(f'/sys/class/power_supply/{bat}') 
                   for bat in os.listdir('/sys/class/power_supply/') 
                   if bat.startswith('BAT'))
    except Exception:
        return False

wireless_interface = get_wireless_interface()
battery_present = has_battery()

# Autostart applications
@hook.subscribe.startup_once
def autostart():
    home = os.path.expanduser('~')
    autostart_script = os.path.join(home, '.config/qtile/autostart.sh')
    if os.path.exists(autostart_script):
        subprocess.Popen([autostart_script])

# Key bindings
keys = [
    # Switch between windows
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),
    
    # Move windows between left/right columns or move up/down in current stack
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    
    # Grow windows
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    
    # Toggle between split and unsplit sides of stack
    Key([mod, "shift"], "Return", lazy.layout.toggle_split(), 
        desc="Toggle between split and unsplit sides of stack"),
    
    # Applications
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "b", lazy.spawn("firefox"), desc="Launch Firefox"),
    Key([mod], "e", lazy.spawn("pcmanfm"), desc="Launch file manager"),
    Key([mod], "d", lazy.spawn("rofi -show drun"), desc="Launch rofi"),
    Key([mod, "shift"], "d", lazy.spawn("rofi -show run"), desc="Launch rofi run"),
    
    # System controls
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),
    Key([mod], "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen"),
    Key([mod], "t", lazy.window.toggle_floating(), desc="Toggle floating"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
    
    # Volume controls with better error handling
    Key([], "XF86AudioRaiseVolume", 
        lazy.spawn("sh -c 'pactl set-sink-volume @DEFAULT_SINK@ +5% || amixer -q sset Master 5%+'")),
    Key([], "XF86AudioLowerVolume", 
        lazy.spawn("sh -c 'pactl set-sink-volume @DEFAULT_SINK@ -5% || amixer -q sset Master 5%-'")),
    Key([], "XF86AudioMute", 
        lazy.spawn("sh -c 'pactl set-sink-mute @DEFAULT_SINK@ toggle || amixer -q sset Master toggle'")),
    
    # Brightness controls with fallback
    Key([], "XF86MonBrightnessUp", 
        lazy.spawn("sh -c 'brightnessctl set +10% || xbacklight -inc 10'")),
    Key([], "XF86MonBrightnessDown", 
        lazy.spawn("sh -c 'brightnessctl set 10%- || xbacklight -dec 10'")),
    
    # Screenshots
    Key([], "Print", lazy.spawn("flameshot gui")),
    Key([mod], "Print", lazy.spawn("flameshot screen -c")),
    Key([mod, "shift"], "s", lazy.spawn("flameshot gui")),
    
    # Media controls
    Key([], "XF86AudioPlay", lazy.spawn("playerctl play-pause")),
    Key([], "XF86AudioNext", lazy.spawn("playerctl next")),
    Key([], "XF86AudioPrev", lazy.spawn("playerctl previous")),
    
    # Additional useful shortcuts
    Key([mod, "shift"], "r", lazy.restart(), desc="Restart qtile"),
    Key([mod], "w", lazy.to_screen(0), desc="Switch to screen 0"),
    Key([mod], "m", lazy.window.toggle_minimize(), desc="Toggle minimize"),
]

# Workspaces
groups = [Group(i) for i in "123456789"]

for i in groups:
    keys.extend([
        Key([mod], i.name, lazy.group[i.name].toscreen(), 
            desc=f"Switch to group {i.name}"),
        Key([mod, "shift"], i.name, lazy.window.togroup(i.name, switch_group=True), 
            desc=f"Switch to & move focused window to group {i.name}"),
    ])

# Layouts
layouts = [
    layout.Columns(
        border_focus_stack=["#d75f5f", "#8f3d3d"], 
        border_width=2,
        border_focus="#d75f5f",
        border_normal="#4c566a",
        margin=8,
        fair=False,
    ),
    layout.Max(),
    layout.MonadTall(
        border_width=2,
        border_focus="#d75f5f",
        border_normal="#4c566a",
        margin=8,
        ratio=0.55,
    ),
    layout.MonadWide(
        border_width=2,
        border_focus="#d75f5f",
        border_normal="#4c566a",
        margin=8,
        ratio=0.65,
    ),
    layout.Stack(
        num_stacks=2,
        border_width=2,
        border_focus="#d75f5f",
        border_normal="#4c566a",
        margin=8,
    ),
    layout.Floating(
        border_width=2,
        border_focus="#d75f5f",
        border_normal="#4c566a",
    ),
]

# Color scheme
colors = {
    "bg": "#2e3440",
    "fg": "#d8dee9", 
    "focus": "#d75f5f",
    "urgent": "#bf616a",
    "inactive": "#4c566a",
    "green": "#a3be8c",
    "blue": "#5e81ac",
    "yellow": "#ebcb8b",
}

# Widget configuration
widget_defaults = dict(
    font="JetBrains Mono",
    fontsize=13,
    padding=4,
    foreground=colors["fg"],
    background=colors["bg"],
)
extension_defaults = widget_defaults.copy()

def create_widgets():
    widgets = [
        widget.GroupBox(
            active=colors["fg"],
            inactive=colors["inactive"],
            highlight_method="block",
            this_current_screen_border=colors["focus"],
            this_screen_border=colors["focus"],
            other_current_screen_border=colors["inactive"],
            other_screen_border=colors["inactive"],
            fontsize=15,
            padding=6,
            borderwidth=2,
            rounded=True,
            disable_drag=True,
        ),
        widget.Sep(
            linewidth=0,
            padding=10,
        ),
        widget.CurrentLayout(
            foreground=colors["blue"],
            fontsize=13,
            fmt="Layout: {}",
        ),
        widget.Sep(
            linewidth=1,
            padding=10,
            foreground=colors["inactive"],
        ),
        widget.Prompt(
            foreground=colors["yellow"],
            cursor_color=colors["focus"],
        ),
        widget.WindowName(
            foreground=colors["fg"],
            max_chars=40,
            fmt="{}",
            empty_group_string="Desktop",
        ),
        widget.Spacer(),
        
        # System monitoring widgets
        widget.CPU(
            format="CPU {load_percent}%",
            foreground=colors["green"],
            update_interval=5,
            mouse_callbacks={
                'Button1': lambda: qtile.cmd_spawn('htop')
            },
        ),
        widget.Sep(
            linewidth=1,
            padding=10,
            foreground=colors["inactive"],
        ),
        widget.Memory(
            format="RAM {MemUsed:.0f}{mm}",
            foreground=colors["blue"],
            update_interval=5,
            mouse_callbacks={
                'Button1': lambda: qtile.cmd_spawn('htop')
            },
        ),
        widget.Sep(
            linewidth=1,
            padding=10,
            foreground=colors["inactive"],
        ),
        
        # Volume widget with fallback
        widget.PulseVolume(
            foreground=colors["yellow"],
            fmt="Vol {}",
            mouse_callbacks={
                'Button1': lambda: qtile.cmd_spawn('pavucontrol')
            },
            update_interval=0.1,
        ),
        widget.Sep(
            linewidth=1,
            padding=10,
            foreground=colors["inactive"],
        ),
    ]
    
    # Add wireless widget only if interface is found
    if wireless_interface:
        widgets.extend([
            widget.Wlan(
                interface=wireless_interface,
                format="{essid} {percent:2.0%}",
                foreground=colors["green"],
                disconnected_message="Disconnected",
                mouse_callbacks={
                    'Button1': lambda: qtile.cmd_spawn('nm-connection-editor')
                },
                update_interval=15,
            ),
            widget.Sep(
                linewidth=1,
                padding=10,
                foreground=colors["inactive"],
            ),
        ])
    
    # Add battery widget only if battery is present
    if battery_present:
        widgets.extend([
            widget.Battery(
                format="{char} {percent:2.0%}",
                foreground=colors["yellow"],
                charge_char="⚡",
                discharge_char="🔋",
                empty_char="❗",
                full_char="🔌",
                unknown_char="?",
                show_short_text=False,
                update_interval=60,
                low_percentage=0.20,
                low_foreground=colors["urgent"],
            ),
            widget.Sep(
                linewidth=1,
                padding=10,
                foreground=colors["inactive"],
            ),
        ])
    
    widgets.extend([
        # System tray
        widget.Systray(
            padding=5,
            icon_size=18,
        ),
        widget.Sep(
            linewidth=0,
            padding=10,
        ),
        
        # Clock
        widget.Clock(
            format="%Y-%m-%d %H:%M",
            foreground=colors["focus"],
            fontsize=14,
            mouse_callbacks={
                'Button1': lambda: qtile.cmd_spawn('gnome-calendar')
            },
        ),
    ])
    
    return widgets

# Screens configuration
screens = [
    Screen(
        top=bar.Bar(
            create_widgets(),
            size=28,
            background=colors["bg"],
            opacity=0.95,
            margin=[4, 8, 0, 8],  # top, right, bottom, left
        ),
    ),
]

# Mouse configuration
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), 
         start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), 
         start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

# Floating layout rules
floating_layout = layout.Floating(
    border_width=2,
    border_focus=colors["focus"],
    border_normal=colors["inactive"],
    float_rules=[
        # Default floating rules
        *layout.Floating.default_float_rules,
        
        # Custom floating rules for common applications
        Match(wm_class="confirmreset"),
        Match(wm_class="makebranch"),
        Match(wm_class="maketag"),
        Match(wm_class="ssh-askpass"),
        Match(title="branchdialog"),
        Match(title="pinentry"),
        
        # Application-specific rules
        Match(wm_class="Pavucontrol"),
        Match(wm_class="Blueman-manager"),
        Match(wm_class="Nm-connection-editor"),
        Match(wm_class="Arandr"),
        Match(wm_class="Gpick"),
        Match(wm_class="Kruler"),
        Match(wm_class="MessageWin"),
        Match(wm_class="Sxiv"),
        Match(wm_class="Tor Browser"),
        Match(wm_class="Wpa_gui"),
        Match(wm_class="veromix"),
        Match(wm_class="xtightvncviewer"),
        Match(wm_class="Firefox" , title="Picture-in-Picture"),
        Match(wm_class="Rofi"),
        Match(wm_class="Calculator"),
        Match(wm_class="Gnome-calculator"),
        Match(wm_class="Galculator"),
        
        # Dialog windows
        Match(wm_type="dialog"),
        Match(wm_type="utility"),
        Match(wm_type="toolbar"),
        Match(wm_type="splash"),
        Match(wm_type="notification"),
        Match(wm_type="dock"),
        Match(wm_type="desktop"),
    ]
)

# Window swallowing for terminal applications
@hook.subscribe.client_new
def client_new(window):
    """Auto-float certain windows based on their properties"""
    if window.window.get_wm_class():
        wm_class = window.window.get_wm_class()[0].lower()
        if wm_class in ['pavucontrol', 'blueman-manager', 'nm-connection-editor']:
            window.floating = True

# Focus follows mouse with delay
@hook.subscribe.client_mouse_enter
def client_mouse_enter(window):
    if qtile.config.follow_mouse_focus:
        window.group.focus(window, False)

# Additional Qtile settings
dgroups_key_binder = None
dgroups_app_rules = []
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True
auto_minimize = True
wl_input_rules = None
wmname = "LG3D"
