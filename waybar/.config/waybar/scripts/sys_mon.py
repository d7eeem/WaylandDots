#!/usr/bin/env python3
# SYS-MON MODULE
# Snapshot: 19
# Version: 1.80
# Status: Stable

import json
import psutil
import subprocess
import re
import os
import time
import shutil
import glob  # Added for AMD GPU detection

# ---------------------------------------------------
# CONFIG / ICONS
# ---------------------------------------------------
CPU_ICON_GENERAL = ""
GPU_ICON = ""
MEM_ICON = ""
SSD_ICON = ""
HDD_ICON = "󰋊"
PINK = "#f5c2e7"

# ---------------------------------------------------
# NEW COLOR TABLE (SOFTER COLORS)
# ---------------------------------------------------
COLOR_TABLE = [
    {"color": "#8caaee", "cpu_gpu_temp": (0, 25),  "cpu_power": (0.0, 20),   "gpu_power": (0.0, 50),   "mem_storage": (0.0, 10)},
    {"color": "#99d1db", "cpu_gpu_temp": (26, 30), "cpu_power": (21.0, 40),  "gpu_power": (51.0, 100), "mem_storage": (10.0, 20)},
    {"color": "#81c8be", "cpu_gpu_temp": (31, 45), "cpu_power": (41.0, 60),  "gpu_power": (101.0,200), "mem_storage": (20.0, 40)},
    {"color": "#e5c890", "cpu_gpu_temp": (46, 60), "cpu_power": (61.0, 80),  "gpu_power": (201.0,300), "mem_storage": (40.0, 60)},
    {"color": "#ef9f76", "cpu_gpu_temp": (61, 75), "cpu_power": (81.0, 100), "gpu_power": (301.0,400), "mem_storage": (60.0, 80)},
    {"color": "#ea999c", "cpu_gpu_temp": (76, 85), "cpu_power": (101.0,120), "gpu_power": (401.0,450), "mem_storage": (80.0, 90)},
    {"color": "#e78284", "cpu_gpu_temp": (86,999), "cpu_power": (121.0,999), "gpu_power": (451.0,999), "mem_storage": (90.0,100)}
]

def get_color(value, metric_type):
    if value is None:
        return "#ffffff"
    try:
        value = float(value)
    except:
        return "#ffffff"
    for entry in COLOR_TABLE:
        low, high = entry[metric_type] if metric_type in entry else (0, 0)
        if low <= value <= high:
            return entry["color"]
    return COLOR_TABLE[-1]["color"]

# ---------------------------------------------------
# CPU INFO
# ---------------------------------------------------
cpu_percent = psutil.cpu_percent(interval=0.5)
max_cpu_temp = 0
cpu_name = "AMD Ryzen 9 9900X"
current_freq = max_freq = 0

try:
    temps = psutil.sensors_temperatures() or {}
    k10 = temps.get("k10temp", [])
    for t in k10:
        if hasattr(t, "label") and t.label and t.label.lower() == "tctl":
            max_cpu_temp = int(t.current)
except:
    pass

try:
    cpu_info = psutil.cpu_freq(percpu=False)
    if cpu_info:
        current_freq = cpu_info.current or 0
        max_freq = cpu_info.max or 0
except:
    pass

# ---------------------------------------------------
# CPU POWER USING RAPL + TEMP FIX (SCALE TO 0.7)
# ---------------------------------------------------
cpu_power = 0.0
rapl_path = "/sys/class/powercap/intel-rapl:0:0/energy_uj"

try:
    with open(rapl_path, "r") as f:
        energy1 = int(f.read().strip())
    time.sleep(0.5)
    with open(rapl_path, "r") as f:
        energy2 = int(f.read().strip())
    delta_energy = energy2 - energy1
    raw_power = (delta_energy / 1_000_000) / 0.5
    cpu_power = raw_power * 0.7
except:
    CPU_TDP_W = 105
    freq_ratio = (current_freq / max_freq) if max_freq else 1.0
    raw_power = CPU_TDP_W * freq_ratio
    cpu_power = raw_power * 0.7

# ---------------------------------------------------
# GPU INFO FOR AMD
# ---------------------------------------------------
gpu_percent = 0
gpu_temp = 0
gpu_power = 0.0
gpu_name = "AMD GPU"
gpu_freq_current = 0
gpu_freq_max = 2500  # Default for AMD GPUs, adjust as needed

# Try ROCm SMI for AMD GPUs
try:
    output = subprocess.check_output(
        ["rocm-smi", "--showuse", "--showtemp", "--showpower", "--showclocks"],
        text=True,
        stderr=subprocess.DEVNULL
    )
    
    # Parse ROCm SMI output
    temp_match = re.search(r"Temperature\s*\(C\):\s*(\d+)", output)
    if temp_match:
        gpu_temp = int(temp_match.group(1))
    
    use_match = re.search(r"GPU use\s*\(%\):\s*(\d+)", output)
    if use_match:
        gpu_percent = int(use_match.group(1))
    
    power_match = re.search(r"Average Graphics Package Power\s*\(W\):\s*([\d\.]+)", output)
    if power_match:
        gpu_power = float(power_match.group(1))
    
    freq_match = re.search(r"GPU Clock Level \(MHz\):\s*(\d+)\s*\(MCLK:\s*\d+\s*,\s*SCLK:\s*(\d+)", output)
    if freq_match:
        gpu_freq_current = int(freq_match.group(2))
        
except (subprocess.CalledProcessError, FileNotFoundError):
    # Fallback: Try using sysfs for AMD GPU
    try:
        # Check sysfs for AMD GPU info
        hwmon_paths = glob.glob("/sys/class/hwmon/hwmon*/name")
        for hwmon_path in hwmon_paths:
            try:
                with open(hwmon_path, "r") as f:
                    name = f.read().strip()
                if "amdgpu" in name.lower():
                    base_path = os.path.dirname(hwmon_path)
                    
                    # Try to get temperature
                    temp_path = os.path.join(base_path, "temp1_input")
                    if os.path.exists(temp_path):
                        with open(temp_path, "r") as f:
                            milli_temp = int(f.read().strip())
                            gpu_temp = milli_temp // 1000
                    
                    # Try to get power
                    power_path = os.path.join(base_path, "power1_average")
                    if os.path.exists(power_path):
                        with open(power_path, "r") as f:
                            micro_watts = int(f.read().strip())
                            gpu_power = micro_watts / 1_000_000
                    
                    # Try to get frequency
                    pp_dpm_sclk_path = "/sys/class/drm/card0/device/pp_dpm_sclk"
                    if os.path.exists(pp_dpm_sclk_path):
                        with open(pp_dpm_sclk_path, "r") as f:
                            lines = f.readlines()
                            for line in lines:
                                if "*" in line:
                                    freq_match = re.search(r"(\d+)Mhz", line)
                                    if freq_match:
                                        gpu_freq_current = int(freq_match.group(1))
            except:
                continue
    except:
        pass

# Calculate frequency percentage safely
gpu_freq_percent = 0
if gpu_freq_max > 0:
    gpu_freq_percent = (gpu_freq_current / gpu_freq_max) * 100

# ---------------------------------------------------
# MEMORY INFO
# ---------------------------------------------------
mem = psutil.virtual_memory()
mem_used_gb = mem.used / (1024**3)
mem_total_gb = mem.total / (1024**3)
mem_percent = mem.percent

memory_modules = [
    {"label": "DIMM1", "size": "16 GB", "speed": "3200 MHz", "temp": 42},
    {"label": "DIMM2", "size": "16 GB", "speed": "3200 MHz", "temp": 41},
]

# ---------------------------------------------------
# STORAGE INFO
# ---------------------------------------------------
EXCLUDE_MOUNTS = {"pkg", "log", "home", "boot"}
partitions = [
    p for p in psutil.disk_partitions(all=False)
    if 'rw' in p.opts and not (p.fstype or "").startswith('tmp')
    and os.path.basename(p.mountpoint) not in EXCLUDE_MOUNTS
]

CUSTOM_DRIVE_NAMES = [
    "1 TB - Omarchy  SSD",
    "1 TB - CachyOS  SSD",
    "1 TB - Windows  SSD",
    "2 TB - Games    SSD",
    "2 TB - Media    HDD"
]

storage_entries = []
hwmon_list = sorted(os.listdir("/sys/class/hwmon")) if os.path.exists("/sys/class/hwmon") else []

for idx, p in enumerate(partitions):
    temp = None
    if idx < len(hwmon_list):
        hwmon_path = f"/sys/class/hwmon/{hwmon_list[idx]}/temp1_input"
        if os.path.exists(hwmon_path):
            try:
                milli = int(open(hwmon_path).read().strip())
                temp = milli // 1000
            except:
                temp = None

    usage_percent = None
    try:
        usage_percent = psutil.disk_usage(p.mountpoint).percent
    except:
        usage_percent = None

    label_full = CUSTOM_DRIVE_NAMES[idx] if idx < len(CUSTOM_DRIVE_NAMES) else os.path.basename(p.mountpoint)
    drive_icon = HDD_ICON if "Media" in label_full else SSD_ICON
    storage_entries.append((drive_icon, label_full, temp, usage_percent))

# ---------------------------------------------------
# BAR TEXT
# ---------------------------------------------------
try:
    total_tb = sum(int(re.search(r"(\d+)", e[1]).group(1)) for e in storage_entries)
    total_used_tb = sum((int(re.search(r"(\d+)", e[1]).group(1)) * (e[3]/100 if e[3] else 0)) for e in storage_entries)
    total_percent = int(sum((e[3] or 0) for e in storage_entries) / len(storage_entries))
except:
    total_tb = 0
    total_used_tb = 0
    total_percent = 0

text = (
    f"| {CPU_ICON_GENERAL} <span foreground='{get_color(max_cpu_temp,'cpu_gpu_temp')}'>{max_cpu_temp}°C</span>  "
    f"{GPU_ICON} <span foreground='{get_color(gpu_temp,'cpu_gpu_temp')}'>{gpu_temp}°C</span>  "
    f"{MEM_ICON} <span foreground='{get_color(mem_percent,'mem_storage')}'>{mem_percent}%</span>  "
    f"{SSD_ICON} <span foreground='{get_color(total_percent,'mem_storage')}'>{total_percent}%</span> |"
)

# ---------------------------------------------------
# TOOLTIP BUILDING
# ---------------------------------------------------
tooltip_lines = []

# -------------------------
# CPU Section
# -------------------------
tooltip_lines.append("")
cpu_header_text = f"{CPU_ICON_GENERAL} CPU"
tooltip_lines.append(f"<span foreground='{PINK}'>{cpu_header_text}</span>:")

cpu_rows = [
    (CPU_ICON_GENERAL, f"Type: {cpu_name}"),
    ("", f"Frequency: <span foreground='{get_color(current_freq/max_freq*100, 'cpu_power')}'>{current_freq:.0f} MHz</span> / {max_freq:.0f} MHz"),
    ("", f"Temperature: <span foreground='{get_color(max_cpu_temp,'cpu_gpu_temp')}'>{max_cpu_temp}°C</span>"),
    ("", f"Power: <span foreground='{get_color(cpu_power,'cpu_power')}'>{cpu_power:.1f} W</span>"),
    ("", f"Utilization: <span foreground='{get_color(cpu_percent,'cpu_power')}'>{cpu_percent:.0f}%</span>")
]

cpu_line_texts = [f"{icon} | {text}" for icon, text in cpu_rows]
storage_line_lengths = []
for idx, (icon, label_full, temp, usage_percent) in enumerate(storage_entries):
    label = ["Omarchy", "CachyOS", "Windows", "Games", "Media"][idx] if idx < 5 else "Drive"
    size_match = re.search(r"(\d+)\s*TB", label_full)
    capacity_tb = int(size_match.group(1)) if size_match else 1
    capacity_str = f"{capacity_tb}TB"
    usage_percent_str = f"0{int(usage_percent)}%" if usage_percent is not None and usage_percent < 10 else f"{int(usage_percent)}%" if usage_percent is not None else "N/A"
    usage_tb = capacity_tb * (usage_percent / 100) if usage_percent is not None else 0
    usage_str = f"{usage_tb:.1f} TB ({usage_percent_str})" if usage_percent is not None else "N/A"
    temp_str = f"{temp:2d}°C" if temp is not None else "N/A"
    line_len = len(f"{icon} | {label} {capacity_str} | {usage_str} | {temp_str}")
    storage_line_lengths.append(line_len)

max_line_len = max(max(len(re.sub(r'<.*?>','',line)) for line in cpu_line_texts), max(storage_line_lengths))

cpu_hline = "─" * max_line_len
cpu_dash = "-" * max_line_len
tooltip_lines.append(cpu_hline)
tooltip_lines.append(cpu_rows[0][0] + " | " + cpu_rows[0][1])
tooltip_lines.append(cpu_dash)
for icon, text_row in cpu_rows[1:]:
    tooltip_lines.append(f"{icon} | {text_row}")
tooltip_lines.append(cpu_hline)

# -------------------------
# GPU Section
# -------------------------
tooltip_lines.append("")
gpu_header_text = f"{GPU_ICON} GPU"
tooltip_lines.append(f"<span foreground='{PINK}'>{gpu_header_text}</span>:")

gpu_rows = [
    (GPU_ICON, f"Type: {gpu_name}"),
    ("", f"Frequency: <span foreground='{get_color(gpu_freq_percent, 'gpu_power')}'>{gpu_freq_current} MHz</span> / {gpu_freq_max} MHz"),
    ("", f"Temperature: <span foreground='{get_color(gpu_temp,'cpu_gpu_temp')}'>{gpu_temp}°C</span>"),
    ("", f"Power: <span foreground='{get_color(gpu_power,'gpu_power')}'>{gpu_power:.1f} W</span>"),
    ("", f"Utilization: <span foreground='{get_color(gpu_percent,'gpu_power')}'>{gpu_percent}%</span>")
]

gpu_line_texts = [f"{icon} | {text}" for icon, text in gpu_rows]
gpu_hline = "─" * max_line_len
gpu_dash = "-" * max_line_len
tooltip_lines.append(gpu_hline)
tooltip_lines.append(gpu_rows[0][0] + " | " + gpu_rows[0][1])
tooltip_lines.append(gpu_dash)
for icon, text_row in gpu_rows[1:]:
    tooltip_lines.append(f"{icon} | {text_row}")
tooltip_lines.append(gpu_hline)

# ---------------------------------------------------
# MEMORY SECTION
# ---------------------------------------------------
tooltip_lines.append("")
mem_header_text = f"{MEM_ICON} Memory"
tooltip_lines.append(f"<span foreground='{PINK}'>{mem_header_text}</span>:")

if memory_modules:
    icon_col = []
    label_col = []
    size_col = []
    speed_col = []
    temp_col = []

    for mod in memory_modules:
        icon_col.append(MEM_ICON)
        label_col.append(mod["label"])
        size_col.append(mod["size"])
        speed_col.append(mod["speed"])
        temp_col.append(f"<span foreground='{get_color(mod['temp'],'cpu_gpu_temp')}'>{mod['temp']}°C</span>")

    max_label_len = max(len(l) for l in label_col)
    max_size_len = max(len(s) for s in size_col)
    max_speed_len = max(len(sp) for sp in speed_col)
    mem_table_width = max_line_len

    mem_hline = "─" * mem_table_width
    tooltip_lines.append(mem_hline)

    usage_line = f" | Usage: {mem_used_gb:.1f} / {mem_total_gb:.1f} GB (<span foreground='{get_color(mem_percent,'mem_storage')}'>{mem_percent}%</span>)"
    tooltip_lines.append(usage_line)
    usage_dash_line = "-" * mem_table_width
    tooltip_lines.append(usage_dash_line)

    for i in range(len(memory_modules)):
        line = (
            f"{icon_col[i]} |"
            f"{label_col[i]:<{max_label_len}} | "
            f"{size_col[i]:<{max_size_len}} | "
            f"{speed_col[i]:<{max_speed_len}} | "
            f"{temp_col[i]:>4}"
        )
        tooltip_lines.append(line)

    tooltip_lines.append(mem_hline)

# ---------------------------------------------------
# STORAGE SECTION
# ---------------------------------------------------
tooltip_lines.append("")
storage_header_text = f"{SSD_ICON} Storage"
tooltip_lines.append(f"<span foreground='{PINK}'>{storage_header_text}</span>:")

if storage_entries:
    SHORT_LABELS = ["Omarchy", "CachyOS", "Windows", "Games", "Media"]

    icon_col = []
    namecap_col = []
    usage_col = []
    temp_col = []

    for idx, (icon, label_full, temp, usage_percent) in enumerate(storage_entries):
        label = SHORT_LABELS[idx] if idx < len(SHORT_LABELS) else "Drive"
        size_match = re.search(r"(\d+)\s*TB", label_full)
        capacity_tb = int(size_match.group(1)) if size_match else 1
        capacity_str = f"{capacity_tb}TB"

        if usage_percent is not None and usage_percent < 10:
            usage_percent_str = f"0{int(usage_percent)}%"
        elif usage_percent is not None:
            usage_percent_str = f"{int(usage_percent)}%"
        else:
            usage_percent_str = "N/A"

        usage_tb = capacity_tb * (usage_percent / 100) if usage_percent is not None else 0
        usage_str = f"{usage_tb:.1f} TB (<span foreground='{get_color(usage_percent,'mem_storage')}'>{usage_percent_str}</span>)" if usage_percent is not None else "N/A"
        temp_str = f"<span foreground='{get_color(temp,'cpu_gpu_temp')}'>{temp:2d}°C</span>" if temp is not None else "N/A"

        icon_col.append(icon)
        namecap_col.append(f"{label} {capacity_str}")
        usage_col.append(usage_str)
        temp_col.append(temp_str)

    max_namecap_len = max(len(re.sub(r'<.*?>', '', s)) for s in namecap_col)
    max_usage_len = max(len(re.sub(r'<.*?>', '', s)) for s in usage_col)

    storage_table_width = max_line_len

    storage_hline = "─" * storage_table_width
    storage_dash = "-" * storage_table_width
    tooltip_lines.append(storage_hline)

    usage_line = f" | Usage: {total_used_tb:.1f} / {total_tb} TB (<span foreground='{get_color(total_percent,'mem_storage')}'>{total_percent}%</span>)"
    tooltip_lines.append(usage_line)
    tooltip_lines.append(storage_dash)

    for i in range(len(storage_entries)):
        line = (
            f"{icon_col[i]} |"
            f"{namecap_col[i]:<{max_namecap_len}} | "
            f"{usage_col[i]:<{max_usage_len}} | "
            f"{temp_col[i]:>5}"
        )
        tooltip_lines.append(line)

    tooltip_lines.append(storage_hline)

# ---------------------------------------------------
# OUTPUT JSON (click-handling)
# ---------------------------------------------------

# Add click hint at the bottom
tooltip_lines.append("")
tooltip_lines.append("🖱️ LMB: Btop | 🖱️ RMB: CoolerControl")

tooltip = "\n".join(tooltip_lines)

# Detect default terminal
TERMINAL = os.environ.get("TERMINAL") or shutil.which("alacritty") or shutil.which("kitty") or shutil.which("gnome-terminal") or "xterm"

# Detect click type
click_type = os.environ.get("WAYBAR_CLICK_TYPE")  # 'left', 'right', 'middle'

if click_type == "left":
    subprocess.Popen([TERMINAL, "-e", "btop"])
elif click_type == "right":
    subprocess.Popen(["/usr/bin/coolercontrol"])  # or your full script path

output = {
    "text": text,
    "tooltip": tooltip,
    "markup": "pango",
    "click-events": True
}

print(json.dumps(output))
