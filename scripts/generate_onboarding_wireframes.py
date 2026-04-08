#!/usr/bin/env python3
"""Generate iPhone wireframe mockups for all onboarding flow states."""

from PIL import Image, ImageDraw, ImageFont
import os
import textwrap

# iPhone 15 Pro dimensions at 2x
W, H = 393 * 2, 852 * 2
CORNER_R = 50
PAD = 40

# Colors
BG_COLOR = (255, 255, 255)
BLACK = (0, 0, 0)
GRAY = (142, 142, 147)
LIGHT_GRAY = (229, 229, 234)
BLUE = (0, 122, 255)
WHITE = (255, 255, 255)
DARK_BG = (28, 28, 30)
POINT_CLOUD_BG = (20, 20, 25)
VIDEO_BG = (45, 45, 50)

# Try to load fonts
def get_font(size, bold=False):
    paths = [
        "/System/Library/Fonts/SFPro-Bold.otf" if bold else "/System/Library/Fonts/SFPro-Regular.otf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for p in paths:
        try:
            return ImageFont.truetype(p, size)
        except (OSError, IOError):
            continue
    return ImageFont.load_default()

font_title = get_font(42, bold=True)
font_body = get_font(28)
font_button = get_font(30, bold=True)
font_button_link = get_font(28, bold=True)
font_small = get_font(22)
font_status = get_font(24, bold=True)
font_label = get_font(20, bold=True)
font_state_name = get_font(18, bold=True)

def rounded_rect(draw, xy, fill, radius=30):
    x0, y0, x1, y1 = xy
    draw.rounded_rectangle(xy, radius=radius, fill=fill)

def draw_status_bar(draw, y=60):
    """Draw iOS status bar."""
    draw.text((PAD + 20, y), "9:41", fill=BLACK, font=font_status)
    # Signal, wifi, battery indicators
    bx = W - PAD - 120
    for i in range(4):
        h = 14 + i * 3
        draw.rounded_rectangle((bx + i * 12, y + 20 - h, bx + i * 12 + 8, y + 20), radius=2, fill=BLACK)
    # Battery
    draw.rounded_rectangle((bx + 60, y + 4, bx + 95, y + 22), radius=4, outline=BLACK, width=2)
    draw.rounded_rectangle((bx + 63, y + 7, bx + 88, y + 19), radius=2, fill=BLACK)
    draw.rounded_rectangle((bx + 95, y + 9, bx + 99, y + 17), radius=2, fill=BLACK)

def draw_cancel_button(draw, y=120):
    """Draw Cancel button in top-left."""
    draw.text((PAD + 20, y), "Cancel", fill=BLUE, font=font_button_link)

def draw_orbit_indicators(draw, y, active_orbits=1, total=3):
    """Draw orbit completion indicators (circles)."""
    indicator_w = 40
    total_w = total * indicator_w + (total - 1) * 20
    start_x = (W - total_w) // 2
    for i in range(total):
        cx = start_x + i * (indicator_w + 20) + indicator_w // 2
        cy = y
        r = 16
        if i < active_orbits:
            draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=BLUE)
        elif i == active_orbits:
            draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=BLUE, width=3)
        else:
            draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=GRAY, width=2)

def draw_point_cloud_area(draw, y, h, label="Point Cloud Preview"):
    """Draw point cloud visualization area."""
    rounded_rect(draw, (PAD + 20, y, W - PAD - 20, y + h), fill=POINT_CLOUD_BG, radius=20)
    # Fake point cloud dots
    import random
    random.seed(42)
    cx, cy = W // 2, y + h // 2
    for _ in range(200):
        angle = random.uniform(0, 6.28)
        dist = random.gauss(0, h * 0.2)
        px = int(cx + dist * 1.3 * (0.5 + 0.5 * random.random()) * (1 if random.random() > 0.5 else -1))
        py = int(cy + dist * 0.8 * (0.5 + 0.5 * random.random()) * (1 if random.random() > 0.5 else -1))
        if PAD + 30 < px < W - PAD - 30 and y + 10 < py < y + h - 10:
            colors = [(100, 200, 255), (120, 220, 180), (200, 180, 255), (255, 200, 100)]
            c = random.choice(colors)
            s = random.randint(2, 5)
            draw.ellipse((px - s, py - s, px + s, py + s), fill=c)
    # Label
    draw.text((W // 2 - 100, y + h - 50), label, fill=(150, 150, 160), font=font_small)

def draw_video_area(draw, y, h, video_name="Tutorial Video"):
    """Draw tutorial video placeholder area."""
    rounded_rect(draw, (PAD + 20, y, W - PAD - 20, y + h), fill=VIDEO_BG, radius=20)
    # Play button
    cx, cy = W // 2, y + h // 2
    # Triangle play icon
    draw.polygon([(cx - 30, cy - 40), (cx - 30, cy + 40), (cx + 40, cy)], fill=(255, 255, 255, 180))
    # Video label
    tw = draw.textlength(video_name, font=font_small)
    draw.text((W // 2 - tw // 2, y + h - 50), video_name, fill=(150, 150, 160), font=font_small)

def draw_primary_button(draw, y, label, filled=True):
    """Draw a primary (filled) or text button."""
    bx = PAD + 30
    bw = W - 2 * (PAD + 30)
    bh = 60
    if filled:
        rounded_rect(draw, (bx, y, bx + bw, y + bh), fill=BLUE, radius=16)
        tw = draw.textlength(label, font=font_button)
        draw.text((W // 2 - tw // 2, y + 12), label, fill=WHITE, font=font_button)
    else:
        tw = draw.textlength(label, font=font_button_link)
        draw.text((W // 2 - tw // 2, y + 12), label, fill=BLUE, font=font_button_link)
    return y + bh + 8

def draw_text_centered(draw, y, text, font, fill, max_width=None, line_spacing=8):
    """Draw multiline centered text, return new y."""
    if max_width is None:
        max_width = W - 2 * (PAD + 40)
    # Word wrap
    words = text.split()
    lines = []
    current = ""
    for word in words:
        test = current + " " + word if current else word
        tw = draw.textlength(test, font=font)
        if tw > max_width and current:
            lines.append(current)
            current = word
        else:
            current = test
    if current:
        lines.append(current)

    for line in lines:
        tw = draw.textlength(line, font=font)
        draw.text((W // 2 - tw // 2, y), line, fill=fill, font=font)
        bbox = font.getbbox(line)
        y += (bbox[3] - bbox[1]) + line_spacing
    return y

def draw_home_indicator(draw):
    """Draw the bottom home indicator bar."""
    bar_w = 200
    bar_h = 8
    x = (W - bar_w) // 2
    y = H - 40
    draw.rounded_rectangle((x, y, x + bar_w, y + bar_h), radius=4, fill=BLACK)

def create_screen(state_name, title, detail, buttons, visual_type="point_cloud",
                  video_name=None, orbit_count=1, state_index=""):
    """Create a wireframe screen for a given state."""
    img = Image.new("RGB", (W, H), BG_COLOR)
    draw = ImageDraw.Draw(img)

    # State label at top
    state_label = f"{state_index}  .{state_name}"
    draw.rounded_rectangle((PAD, 10, PAD + draw.textlength(state_label, font=font_state_name) + 20, 38),
                           radius=6, fill=(240, 240, 245))
    draw.text((PAD + 10, 12), state_label, fill=GRAY, font=font_state_name)

    draw_status_bar(draw)
    draw_cancel_button(draw)

    # Visual area
    vis_y = 180
    vis_h = 520

    if visual_type == "point_cloud":
        draw_point_cloud_area(draw, vis_y, vis_h)
        draw_orbit_indicators(draw, vis_y + vis_h - 70, active_orbits=orbit_count)
    elif visual_type == "video":
        vn = video_name or "Tutorial Video"
        draw_video_area(draw, vis_y, vis_h, vn)
        draw_orbit_indicators(draw, vis_y + vis_h - 70, active_orbits=orbit_count)
    elif visual_type == "camera":
        # Live camera feed placeholder
        rounded_rect(draw, (0, vis_y - 60, W, vis_y + vis_h + 100), fill=(15, 15, 18), radius=0)
        cx, cy = W // 2, vis_y + vis_h // 2
        # Camera viewfinder
        draw.rectangle((cx - 100, cy - 100, cx + 100, cy + 100), outline=(80, 80, 85), width=2)
        draw.line((cx - 120, cy, cx - 100, cy), fill=(80, 80, 85), width=2)
        draw.line((cx + 100, cy, cx + 120, cy), fill=(80, 80, 85), width=2)
        draw.line((cx, cy - 120, cx, cy - 100), fill=(80, 80, 85), width=2)
        draw.line((cx, cy + 100, cx, cy + 120), fill=(80, 80, 85), width=2)
        # Scanning indicator
        for i in range(60):
            import random
            random.seed(i + 100)
            px = cx + random.randint(-180, 180)
            py = cy + random.randint(-120, 120)
            s = random.randint(2, 4)
            draw.ellipse((px - s, py - s, px + s, py + s), fill=(0, 200, 120))
        draw_text_centered(draw, vis_y + vis_h + 50, "SCANNING...", font_label, (0, 200, 120))
        draw_orbit_indicators(draw, vis_y + vis_h + 120, active_orbits=orbit_count)
        draw_home_indicator(draw)
        return img
    elif visual_type == "processing":
        rounded_rect(draw, (PAD + 20, vis_y, W - PAD - 20, vis_y + vis_h), fill=POINT_CLOUD_BG, radius=20)
        # Processing spinner
        cx, cy = W // 2, vis_y + vis_h // 2 - 30
        r = 40
        for i in range(12):
            import math
            angle = i * math.pi / 6
            x1 = cx + int((r - 10) * math.cos(angle))
            y1 = cy + int((r - 10) * math.sin(angle))
            x2 = cx + int(r * math.cos(angle))
            y2 = cy + int(r * math.sin(angle))
            alpha = 80 + i * 15
            draw.line((x1, y1, x2, y2), fill=(alpha, alpha, alpha + 20), width=4)
        draw_text_centered(draw, cy + 60, "Processing...", font_body, (180, 180, 185))

    # Title
    title_y = vis_y + vis_h + 30
    new_y = draw_text_centered(draw, title_y, title, font_title, BLACK)

    # Detail text
    if detail:
        detail_y = new_y + 10
        draw_text_centered(draw, detail_y, detail, font_body, GRAY)

    # Buttons
    btn_y = H - 60 - len(buttons) * 72
    for btn in buttons:
        label = btn["label"]
        filled = btn.get("filled", False)
        btn_y = draw_primary_button(draw, btn_y, label, filled=filled)

    draw_home_indicator(draw)
    return img


# Define all onboarding states
states = [
    {
        "name": "tooFewImages",
        "title": "Keep moving around your object.",
        "detail": "You need at least 20 images of your object to create a model.",
        "buttons": [{"label": "Continue", "filled": True}],
        "visual": "point_cloud",
        "orbits": 0,
    },
    {
        "name": "firstSegment",
        "title": "",
        "detail": "",
        "buttons": [],
        "visual": "camera",
        "orbits": 0,
        "camera_label": "Active Capture - First Segment",
    },
    {
        "name": "firstSegmentNeedsWork",
        "title": "Keep going to complete the first segment.",
        "detail": "For best quality, capture three segments. Tap Skip if you can't make it all the way around, but your final model may have missing areas.",
        "buttons": [
            {"label": "Continue", "filled": True},
            {"label": "Skip", "filled": False},
        ],
        "visual": "point_cloud",
        "orbits": 0,
    },
    {
        "name": "firstSegmentComplete",
        "title": "First segment complete.",
        "detail": "For best quality, capture three segments.",
        "buttons": [
            {"label": "Continue", "filled": True},
            {"label": "Finish", "filled": False},
        ],
        "visual": "point_cloud",
        "orbits": 1,
    },
    {
        "name": "flipObject",
        "title": "Flip object on its side and capture again.",
        "detail": "Make sure that areas you captured previously can still be seen. Avoid flipping your object if it changes the shape.",
        "buttons": [
            {"label": "Continue", "filled": True},
            {"label": "Can't flip your object?", "filled": False},
        ],
        "visual": "video",
        "video_name": "ScanPasses-FixedHeight-2.mp4",
        "orbits": 1,
    },
    {
        "name": "flippingObjectNotRecommended",
        "title": "Flipping this object is not recommended.",
        "detail": "Your object may have single color surfaces or be too reflective to add more segments. Tap Continue to capture more detail without flipping, or Flip Object Anyway.",
        "buttons": [
            {"label": "Continue", "filled": True},
            {"label": "Flip object anyway", "filled": False},
        ],
        "visual": "point_cloud",
        "orbits": 1,
    },
    {
        "name": "captureFromLowerAngle",
        "title": "Capture your object again from a lower angle.",
        "detail": "Move down to be level with the base of your object and capture again.",
        "buttons": [
            {"label": "Continue", "filled": True},
            {"label": "Finish", "filled": False},
        ],
        "visual": "video",
        "video_name": "ScanPasses-unflippable-low.mp4",
        "orbits": 1,
    },
    {
        "name": "secondSegment",
        "title": "",
        "detail": "",
        "buttons": [],
        "visual": "camera",
        "orbits": 1,
        "camera_label": "Active Capture - Second Segment",
    },
    {
        "name": "secondSegmentNeedsWork",
        "title": "Keep going to complete the second segment.",
        "detail": "For best quality, capture three segments. Tap Skip if you can't make it all the way around but your final model may have missing areas.",
        "buttons": [
            {"label": "Continue", "filled": True},
            {"label": "Skip", "filled": False},
        ],
        "visual": "point_cloud",
        "orbits": 1,
    },
    {
        "name": "secondSegmentComplete",
        "title": "Second segment complete.",
        "detail": "For best quality, capture three segments.",
        "buttons": [
            {"label": "Continue", "filled": True},
        ],
        "visual": "point_cloud",
        "orbits": 2,
    },
    {
        "name": "flipObjectASecondTime",
        "title": "Flip object on the opposite side and capture again.",
        "detail": "Make sure that areas you captured previously can still be seen. Avoid flipping your object if it changes the shape.",
        "buttons": [
            {"label": "Continue", "filled": True},
            {"label": "Finish", "filled": False},
        ],
        "visual": "video",
        "video_name": "ScanPasses-FixedHeight-3.mp4",
        "orbits": 2,
    },
    {
        "name": "captureFromHigherAngle",
        "title": "Capture your object again from a higher angle.",
        "detail": "Move above your object and make sure that areas you captured previously can still be seen.",
        "buttons": [
            {"label": "Continue", "filled": True},
            {"label": "Finish", "filled": False},
        ],
        "visual": "video",
        "video_name": "ScanPasses-unflippable-high.mp4",
        "orbits": 2,
    },
    {
        "name": "thirdSegment",
        "title": "",
        "detail": "",
        "buttons": [],
        "visual": "camera",
        "orbits": 2,
        "camera_label": "Active Capture - Third Segment",
    },
    {
        "name": "thirdSegmentNeedsWork",
        "title": "Keep going to complete the final segment.",
        "detail": "For best quality, capture three segments. When you're done, tap Finish to complete your object.",
        "buttons": [
            {"label": "Finish", "filled": False},
            {"label": "Continue", "filled": True},
        ],
        "visual": "point_cloud",
        "orbits": 2,
    },
    {
        "name": "thirdSegmentComplete",
        "title": "All segments complete.",
        "detail": "Tap Finish to process your object.",
        "buttons": [
            {"label": "Finish", "filled": True},
        ],
        "visual": "point_cloud",
        "orbits": 3,
    },
    {
        "name": "additionalOrbitOnCurrentSegment",
        "title": "",
        "detail": "",
        "buttons": [],
        "visual": "camera",
        "orbits": 1,
        "camera_label": "Active Capture - Additional Orbit",
    },
    {
        "name": "reconstruction",
        "title": "Processing your object...",
        "detail": "Creating 3D model from captured data.",
        "buttons": [],
        "visual": "processing",
        "orbits": 3,
    },
    {
        "name": "dismiss",
        "title": "",
        "detail": "Returns to the main capture interface.",
        "buttons": [],
        "visual": "camera",
        "orbits": 0,
        "camera_label": "Back to Capture View",
    },
]

# Create output directory
out_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "design", "onboarding-states")
os.makedirs(out_dir, exist_ok=True)

# Generate all screens
for i, state in enumerate(states):
    idx = f"{i + 1:02d}"
    img = create_screen(
        state_name=state["name"],
        title=state["title"],
        detail=state["detail"],
        buttons=state["buttons"],
        visual_type=state["visual"],
        video_name=state.get("video_name"),
        orbit_count=state.get("orbits", 0),
        state_index=idx,
    )
    filename = f"{idx}_{state['name']}.png"
    filepath = os.path.join(out_dir, filename)
    img.save(filepath, "PNG", quality=95)
    print(f"Generated: {filename}")

# Also generate an overview image with all screens in a grid
print("\nGenerating overview grid...")
cols = 6
rows = (len(states) + cols - 1) // cols
thumb_w = W // 3
thumb_h = H // 3
grid_pad = 30
grid_w = cols * thumb_w + (cols + 1) * grid_pad
grid_h = rows * thumb_h + (rows + 1) * grid_pad + 60

overview = Image.new("RGB", (grid_w, grid_h), (245, 245, 250))
overview_draw = ImageDraw.Draw(overview)

# Title
overview_draw.text((grid_pad, 15), "Ortio - Onboarding Flow States", fill=BLACK, font=get_font(36, bold=True))

for i, state in enumerate(states):
    row = i // cols
    col = i % cols
    x = grid_pad + col * (thumb_w + grid_pad)
    y = 60 + grid_pad + row * (thumb_h + grid_pad)

    filename = f"{i + 1:02d}_{state['name']}.png"
    filepath = os.path.join(out_dir, filename)
    thumb = Image.open(filepath)
    thumb = thumb.resize((thumb_w, thumb_h), Image.Resampling.LANCZOS)

    # Drop shadow
    overview_draw.rounded_rectangle(
        (x + 4, y + 4, x + thumb_w + 4, y + thumb_h + 4),
        radius=16, fill=(200, 200, 210)
    )
    overview.paste(thumb, (x, y))
    # Border
    overview_draw.rounded_rectangle(
        (x, y, x + thumb_w, y + thumb_h),
        radius=16, outline=(200, 200, 210), width=2
    )

overview_path = os.path.join(out_dir, "00_overview.png")
overview.save(overview_path, "PNG", quality=95)
print(f"Generated: 00_overview.png")
print(f"\nAll files saved to: {out_dir}")
