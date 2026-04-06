// Ortio Onboarding Flow Generator - Figma Plugin
// Generates all 18 onboarding states as native Figma frames

// iPhone 15 Pro dimensions
const SCREEN_W = 393;
const SCREEN_H = 852;
const SPACING = 80;
const COLS = 6;

// Colors
const WHITE = { r: 1, g: 1, b: 1 };
const BLACK = { r: 0, g: 0, b: 0 };
const BLUE = { r: 0, g: 0.478, b: 1 };
const GRAY = { r: 0.557, g: 0.557, b: 0.576 };
const LIGHT_GRAY = { r: 0.898, g: 0.898, b: 0.918 };
const DARK_BG = { r: 0.078, g: 0.078, b: 0.098 };
const VIDEO_BG = { r: 0.176, g: 0.176, b: 0.196 };

// All onboarding states data
const states = [
  {
    name: "tooFewImages",
    title: "Keep moving around your object.",
    detail: "You need at least 20 images of your object to create a model.",
    buttons: [{ label: "Continue", filled: true }],
    visual: "point_cloud",
    orbits: 0,
  },
  {
    name: "firstSegment",
    title: "Scanning in progress...",
    detail: "Move slowly around your object",
    buttons: [],
    visual: "camera",
    orbits: 0,
  },
  {
    name: "firstSegmentNeedsWork",
    title: "Keep going to complete the first segment.",
    detail: "For best quality, capture three segments. Tap Skip if you can't make it all the way around, but your final model may have missing areas.",
    buttons: [
      { label: "Continue", filled: true },
      { label: "Skip", filled: false },
    ],
    visual: "point_cloud",
    orbits: 0,
  },
  {
    name: "firstSegmentComplete",
    title: "First segment complete.",
    detail: "For best quality, capture three segments.",
    buttons: [
      { label: "Continue", filled: true },
      { label: "Finish", filled: false },
    ],
    visual: "point_cloud",
    orbits: 1,
  },
  {
    name: "flipObject",
    title: "Flip object on its side and capture again.",
    detail: "Make sure that areas you captured previously can still be seen. Avoid flipping your object if it changes the shape.",
    buttons: [
      { label: "Continue", filled: true },
      { label: "Can't flip your object?", filled: false },
    ],
    visual: "video",
    videoName: "ScanPasses-FixedHeight-2",
    orbits: 1,
  },
  {
    name: "flippingObjectNotRecommended",
    title: "Flipping this object is not recommended.",
    detail: "Your object may have single color surfaces or be too reflective to add more segments. Tap Continue to capture more detail without flipping, or Flip Object Anyway.",
    buttons: [
      { label: "Continue", filled: true },
      { label: "Flip object anyway", filled: false },
    ],
    visual: "point_cloud",
    orbits: 1,
  },
  {
    name: "captureFromLowerAngle",
    title: "Capture your object again from a lower angle.",
    detail: "Move down to be level with the base of your object and capture again.",
    buttons: [
      { label: "Continue", filled: true },
      { label: "Finish", filled: false },
    ],
    visual: "video",
    videoName: "ScanPasses-unflippable-low",
    orbits: 1,
  },
  {
    name: "secondSegment",
    title: "Scanning in progress...",
    detail: "Move slowly around your flipped object",
    buttons: [],
    visual: "camera",
    orbits: 1,
  },
  {
    name: "secondSegmentNeedsWork",
    title: "Keep going to complete the second segment.",
    detail: "For best quality, capture three segments. Tap Skip if you can't make it all the way around but your final model may have missing areas.",
    buttons: [
      { label: "Continue", filled: true },
      { label: "Skip", filled: false },
    ],
    visual: "point_cloud",
    orbits: 1,
  },
  {
    name: "secondSegmentComplete",
    title: "Second segment complete.",
    detail: "For best quality, capture three segments.",
    buttons: [{ label: "Continue", filled: true }],
    visual: "point_cloud",
    orbits: 2,
  },
  {
    name: "flipObjectASecondTime",
    title: "Flip object on the opposite side and capture again.",
    detail: "Make sure that areas you captured previously can still be seen. Avoid flipping your object if it changes the shape.",
    buttons: [
      { label: "Continue", filled: true },
      { label: "Finish", filled: false },
    ],
    visual: "video",
    videoName: "ScanPasses-FixedHeight-3",
    orbits: 2,
  },
  {
    name: "captureFromHigherAngle",
    title: "Capture your object again from a higher angle.",
    detail: "Move above your object and make sure that areas you captured previously can still be seen.",
    buttons: [
      { label: "Continue", filled: true },
      { label: "Finish", filled: false },
    ],
    visual: "video",
    videoName: "ScanPasses-unflippable-high",
    orbits: 2,
  },
  {
    name: "thirdSegment",
    title: "Scanning in progress...",
    detail: "Final capture pass",
    buttons: [],
    visual: "camera",
    orbits: 2,
  },
  {
    name: "thirdSegmentNeedsWork",
    title: "Keep going to complete the final segment.",
    detail: "For best quality, capture three segments. When you're done, tap Finish to complete your object.",
    buttons: [
      { label: "Finish", filled: false },
      { label: "Continue", filled: true },
    ],
    visual: "point_cloud",
    orbits: 2,
  },
  {
    name: "thirdSegmentComplete",
    title: "All segments complete.",
    detail: "Tap Finish to process your object.",
    buttons: [{ label: "Finish", filled: true }],
    visual: "point_cloud",
    orbits: 3,
  },
  {
    name: "additionalOrbitOnCurrentSegment",
    title: "Scanning in progress...",
    detail: "Additional capture orbit",
    buttons: [],
    visual: "camera",
    orbits: 1,
  },
  {
    name: "reconstruction",
    title: "Processing your object...",
    detail: "Creating 3D model from captured data.",
    buttons: [],
    visual: "processing",
    orbits: 3,
  },
  {
    name: "dismiss",
    title: "Returning to capture",
    detail: "",
    buttons: [],
    visual: "camera",
    orbits: 0,
  },
];

// State transitions for flow arrows
const transitions = [
  { from: "tooFewImages", to: "firstSegment", label: "Continue" },
  { from: "firstSegment", to: "firstSegmentNeedsWork", label: "Incomplete" },
  { from: "firstSegment", to: "firstSegmentComplete", label: "Complete" },
  { from: "firstSegmentNeedsWork", to: "firstSegment", label: "Continue" },
  { from: "firstSegmentNeedsWork", to: "flipObject", label: "Skip" },
  { from: "firstSegmentComplete", to: "flipObject", label: "Continue (flippable)" },
  { from: "firstSegmentComplete", to: "flippingObjectNotRecommended", label: "Continue (not flippable)" },
  { from: "firstSegmentComplete", to: "reconstruction", label: "Finish" },
  { from: "flipObject", to: "secondSegment", label: "Continue" },
  { from: "flipObject", to: "captureFromLowerAngle", label: "Can't flip" },
  { from: "flippingObjectNotRecommended", to: "captureFromLowerAngle", label: "Continue" },
  { from: "flippingObjectNotRecommended", to: "flipObject", label: "Flip anyway" },
  { from: "captureFromLowerAngle", to: "additionalOrbitOnCurrentSegment", label: "Continue" },
  { from: "captureFromLowerAngle", to: "reconstruction", label: "Finish" },
  { from: "secondSegment", to: "secondSegmentNeedsWork", label: "Incomplete" },
  { from: "secondSegment", to: "secondSegmentComplete", label: "Complete" },
  { from: "secondSegmentNeedsWork", to: "flipObjectASecondTime", label: "Skip (flippable)" },
  { from: "secondSegmentNeedsWork", to: "captureFromHigherAngle", label: "Skip (not flippable)" },
  { from: "secondSegmentComplete", to: "flipObjectASecondTime", label: "Continue (flippable)" },
  { from: "secondSegmentComplete", to: "captureFromHigherAngle", label: "Continue (not flippable)" },
  { from: "flipObjectASecondTime", to: "thirdSegment", label: "Continue" },
  { from: "flipObjectASecondTime", to: "reconstruction", label: "Finish" },
  { from: "captureFromHigherAngle", to: "additionalOrbitOnCurrentSegment", label: "Continue" },
  { from: "captureFromHigherAngle", to: "reconstruction", label: "Finish" },
  { from: "thirdSegment", to: "thirdSegmentNeedsWork", label: "Incomplete" },
  { from: "thirdSegment", to: "thirdSegmentComplete", label: "Complete" },
  { from: "thirdSegmentNeedsWork", to: "reconstruction", label: "Finish" },
  { from: "thirdSegmentComplete", to: "reconstruction", label: "Finish" },
];

async function createScreen(state, index, parentFrame) {
  const col = index % COLS;
  const row = Math.floor(index / COLS);
  const x = col * (SCREEN_W + SPACING);
  const y = row * (SCREEN_H + SPACING + 40);

  // Screen frame
  const screen = figma.createFrame();
  screen.name = `${String(index + 1).padStart(2, "0")} - ${state.name}`;
  screen.resize(SCREEN_W, SCREEN_H);
  screen.x = x;
  screen.y = y + 30;
  screen.cornerRadius = 40;
  screen.clipsContent = true;
  screen.fills = [{ type: "SOLID", color: WHITE }];

  // State name label above frame
  const label = figma.createText();
  await figma.loadFontAsync({ family: "Inter", style: "Bold" });
  await figma.loadFontAsync({ family: "Inter", style: "Regular" });
  await figma.loadFontAsync({ family: "Inter", style: "Semi Bold" });
  label.fontName = { family: "Inter", style: "Bold" };
  label.characters = `.${state.name}`;
  label.fontSize = 14;
  label.fills = [{ type: "SOLID", color: GRAY }];
  label.x = x;
  label.y = y + 5;
  parentFrame.appendChild(label);

  // --- Status bar ---
  const statusTime = figma.createText();
  statusTime.fontName = { family: "Inter", style: "Semi Bold" };
  statusTime.characters = "9:41";
  statusTime.fontSize = 15;
  statusTime.fills = [{ type: "SOLID", color: BLACK }];
  statusTime.x = 30;
  statusTime.y = 18;
  screen.appendChild(statusTime);

  // --- Cancel button ---
  const cancelBtn = figma.createText();
  cancelBtn.fontName = { family: "Inter", style: "Semi Bold" };
  cancelBtn.characters = "Cancel";
  cancelBtn.fontSize = 17;
  cancelBtn.fills = [{ type: "SOLID", color: BLUE }];
  cancelBtn.x = 20;
  cancelBtn.y = 60;
  screen.appendChild(cancelBtn);

  // --- Visual area ---
  const visY = 100;
  const visH = 280;
  const visPad = 16;

  const visualArea = figma.createRectangle();
  visualArea.x = visPad;
  visualArea.y = visY;
  visualArea.resize(SCREEN_W - visPad * 2, visH);
  visualArea.cornerRadius = 16;

  if (state.visual === "point_cloud" || state.visual === "processing") {
    visualArea.fills = [{ type: "SOLID", color: DARK_BG }];

    // Point cloud label
    const pcLabel = figma.createText();
    pcLabel.fontName = { family: "Inter", style: "Regular" };
    pcLabel.characters =
      state.visual === "processing"
        ? "Processing..."
        : "Point Cloud Preview";
    pcLabel.fontSize = 12;
    pcLabel.fills = [
      { type: "SOLID", color: { r: 0.6, g: 0.6, b: 0.65 } },
    ];
    pcLabel.x = SCREEN_W / 2 - 45;
    pcLabel.y = visY + visH / 2 - 8;
    screen.appendChild(pcLabel);
  } else if (state.visual === "video") {
    visualArea.fills = [{ type: "SOLID", color: VIDEO_BG }];

    // Play triangle
    const play = figma.createPolygon();
    play.pointCount = 3;
    play.resize(30, 30);
    play.x = SCREEN_W / 2 - 15;
    play.y = visY + visH / 2 - 15;
    play.rotation = -90;
    play.fills = [
      { type: "SOLID", color: WHITE, opacity: 0.8 },
    ];
    screen.appendChild(play);

    // Video name
    if (state.videoName) {
      const vLabel = figma.createText();
      vLabel.fontName = { family: "Inter", style: "Regular" };
      vLabel.characters = state.videoName + ".mp4";
      vLabel.fontSize = 10;
      vLabel.fills = [
        { type: "SOLID", color: { r: 0.6, g: 0.6, b: 0.65 } },
      ];
      vLabel.x = SCREEN_W / 2 - 55;
      vLabel.y = visY + visH - 25;
      screen.appendChild(vLabel);
    }
  } else if (state.visual === "camera") {
    visualArea.fills = [
      { type: "SOLID", color: { r: 0.06, g: 0.06, b: 0.07 } },
    ];

    // Camera crosshair
    const hLine = figma.createRectangle();
    hLine.x = SCREEN_W / 2 - 40;
    hLine.y = visY + visH / 2;
    hLine.resize(80, 1);
    hLine.fills = [
      { type: "SOLID", color: { r: 0.3, g: 0.3, b: 0.35 } },
    ];
    screen.appendChild(hLine);

    const vLine = figma.createRectangle();
    vLine.x = SCREEN_W / 2;
    vLine.y = visY + visH / 2 - 40;
    vLine.resize(1, 80);
    vLine.fills = [
      { type: "SOLID", color: { r: 0.3, g: 0.3, b: 0.35 } },
    ];
    screen.appendChild(vLine);

    // Scanning label
    const scanLabel = figma.createText();
    scanLabel.fontName = { family: "Inter", style: "Semi Bold" };
    scanLabel.characters = "SCANNING";
    scanLabel.fontSize = 11;
    scanLabel.fills = [
      { type: "SOLID", color: { r: 0, g: 0.78, b: 0.47 } },
    ];
    scanLabel.x = SCREEN_W / 2 - 28;
    scanLabel.y = visY + visH - 30;
    screen.appendChild(scanLabel);
  }

  screen.appendChild(visualArea);

  // --- Orbit indicators ---
  const orbitY = visY + visH + 15;
  const totalOrbits = 3;
  const dotSize = 10;
  const dotSpacing = 24;
  const orbitStartX = SCREEN_W / 2 - ((totalOrbits - 1) * dotSpacing) / 2;

  for (let i = 0; i < totalOrbits; i++) {
    const dot = figma.createEllipse();
    dot.resize(dotSize, dotSize);
    dot.x = orbitStartX + i * dotSpacing - dotSize / 2;
    dot.y = orbitY;

    if (i < state.orbits) {
      dot.fills = [{ type: "SOLID", color: BLUE }];
    } else if (i === state.orbits) {
      dot.fills = [];
      dot.strokes = [{ type: "SOLID", color: BLUE }];
      dot.strokeWeight = 1.5;
    } else {
      dot.fills = [];
      dot.strokes = [{ type: "SOLID", color: GRAY }];
      dot.strokeWeight = 1;
    }
    screen.appendChild(dot);
  }

  // --- Title ---
  if (state.title) {
    const titleText = figma.createText();
    titleText.fontName = { family: "Inter", style: "Bold" };
    titleText.characters = state.title;
    titleText.fontSize = 22;
    titleText.fills = [{ type: "SOLID", color: BLACK }];
    titleText.textAlignHorizontal = "CENTER";
    titleText.x = 24;
    titleText.y = orbitY + 30;
    titleText.resize(SCREEN_W - 48, titleText.height);
    titleText.textAutoResize = "HEIGHT";
    screen.appendChild(titleText);

    // --- Detail text ---
    if (state.detail) {
      const detailText = figma.createText();
      detailText.fontName = { family: "Inter", style: "Regular" };
      detailText.characters = state.detail;
      detailText.fontSize = 14;
      detailText.fills = [{ type: "SOLID", color: GRAY }];
      detailText.textAlignHorizontal = "CENTER";
      detailText.x = 30;
      detailText.y = orbitY + 30 + titleText.height + 12;
      detailText.resize(SCREEN_W - 60, detailText.height);
      detailText.textAutoResize = "HEIGHT";
      screen.appendChild(detailText);
    }
  }

  // --- Buttons ---
  const btnPad = 16;
  let btnY = SCREEN_H - 40 - state.buttons.length * 52;

  for (const btn of state.buttons) {
    const btnW = SCREEN_W - btnPad * 2 - 20;
    const btnH = 44;

    if (btn.filled) {
      // Filled button with background
      const btnBg = figma.createRectangle();
      btnBg.x = btnPad + 10;
      btnBg.y = btnY;
      btnBg.resize(btnW, btnH);
      btnBg.cornerRadius = 12;
      btnBg.fills = [{ type: "SOLID", color: BLUE }];
      screen.appendChild(btnBg);

      const btnText = figma.createText();
      btnText.fontName = { family: "Inter", style: "Bold" };
      btnText.characters = btn.label;
      btnText.fontSize = 16;
      btnText.fills = [{ type: "SOLID", color: WHITE }];
      btnText.textAlignHorizontal = "CENTER";
      btnText.x = btnPad + 10;
      btnText.y = btnY + 12;
      btnText.resize(btnW, 20);
      screen.appendChild(btnText);
    } else {
      // Text-only button
      const btnText = figma.createText();
      btnText.fontName = { family: "Inter", style: "Semi Bold" };
      btnText.characters = btn.label;
      btnText.fontSize = 16;
      btnText.fills = [{ type: "SOLID", color: BLUE }];
      btnText.textAlignHorizontal = "CENTER";
      btnText.x = btnPad + 10;
      btnText.y = btnY + 12;
      btnText.resize(btnW, 20);
      screen.appendChild(btnText);
    }

    btnY += 52;
  }

  // --- Home indicator ---
  const homeBar = figma.createRectangle();
  homeBar.x = SCREEN_W / 2 - 60;
  homeBar.y = SCREEN_H - 14;
  homeBar.resize(120, 5);
  homeBar.cornerRadius = 3;
  homeBar.fills = [{ type: "SOLID", color: BLACK }];
  screen.appendChild(homeBar);

  parentFrame.appendChild(screen);
  return screen;
}

async function main() {
  // Create main page frame
  const page = figma.currentPage;
  page.name = "Onboarding Flow";

  // Section title
  const sectionTitle = figma.createText();
  await figma.loadFontAsync({ family: "Inter", style: "Bold" });
  await figma.loadFontAsync({ family: "Inter", style: "Regular" });
  await figma.loadFontAsync({ family: "Inter", style: "Semi Bold" });
  sectionTitle.fontName = { family: "Inter", style: "Bold" };
  sectionTitle.characters = "Ortio - Onboarding Flow States";
  sectionTitle.fontSize = 32;
  sectionTitle.fills = [{ type: "SOLID", color: BLACK }];
  sectionTitle.x = 0;
  sectionTitle.y = -60;
  page.appendChild(sectionTitle);

  // Subtitle
  const subtitle = figma.createText();
  subtitle.fontName = { family: "Inter", style: "Regular" };
  subtitle.characters =
    "18 states covering the complete 3D object capture onboarding flow. States with tutorials show video, others show point cloud preview.";
  subtitle.fontSize = 14;
  subtitle.fills = [{ type: "SOLID", color: GRAY }];
  subtitle.x = 0;
  subtitle.y = -20;
  subtitle.resize(800, 20);
  subtitle.textAutoResize = "HEIGHT";
  page.appendChild(subtitle);

  // Create all screen frames
  const screenNodes = {};
  for (let i = 0; i < states.length; i++) {
    const screen = await createScreen(states[i], i, page);
    screenNodes[states[i].name] = screen;
    figma.notify(`Creating screen ${i + 1}/${states.length}: ${states[i].name}`);
  }

  // Add flow section below screens
  const flowY =
    Math.ceil(states.length / COLS) * (SCREEN_H + SPACING + 40) + 80;

  const flowTitle = figma.createText();
  flowTitle.fontName = { family: "Inter", style: "Bold" };
  flowTitle.characters = "State Transition Map";
  flowTitle.fontSize = 24;
  flowTitle.fills = [{ type: "SOLID", color: BLACK }];
  flowTitle.x = 0;
  flowTitle.y = flowY;
  page.appendChild(flowTitle);

  // Create transition annotations as text
  let transY = flowY + 40;
  for (const t of transitions) {
    const transText = figma.createText();
    transText.fontName = { family: "Inter", style: "Regular" };
    transText.characters = `${t.from}  \u2192  ${t.to}   [${t.label}]`;
    transText.fontSize = 12;
    transText.fills = [{ type: "SOLID", color: { r: 0.3, g: 0.3, b: 0.3 } }];
    transText.x = 0;
    transText.y = transY;
    page.appendChild(transText);
    transY += 22;
  }

  // Zoom to fit
  figma.viewport.scrollAndZoomIntoView(page.children);

  figma.notify(
    `Done! Created ${states.length} onboarding screens with state transitions.`,
    { timeout: 5000 }
  );
  figma.closePlugin();
}

main();
