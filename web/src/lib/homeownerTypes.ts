export type PaintBrand = "Sherwin-Williams" | "Benjamin Moore" | "PPG";
export type ColorFamily = "Whites" | "Neutrals" | "Reds" | "Oranges" | "Yellows" | "Greens" | "Blues" | "Purples" | "Darks";
export type PaintColor = { id: string; brand: PaintBrand; name: string; code: string; hex: string; family: ColorFamily };
export type SurfaceTarget = "Interior walls" | "Exterior siding" | "Trim & accents" | "Front door" | "Cabinets";
export type SurfacePaint = { surface: SurfaceTarget; color: PaintColor };
export type SurfacePoint = { x: number; y: number };

export type VisionProject = {
  id: string; createdAt: string; originalImage: string; resultImage: string; scheme: SurfacePaint[]; notes: string;
  surfacePoints?: Partial<Record<SurfaceTarget, SurfacePoint>>;
};

export type DefectAnalysis = {
  isPaintIssue: boolean; defectName: string; confidence: number; severity: "minor" | "moderate" | "serious";
  summary: string; surface: string; causes: string[]; solutions: string[]; whenToCallPro: string;
};
export type PaintScan = DefectAnalysis & { id: string; createdAt: string; image: string };
export type SavedColor = PaintColor & { savedAt: string };
export type RoomPhoto = { id: string; data: string; label: "Before" | "After" | "Reference"; caption: string };

export type PaintRoom = {
  id: string; createdAt: string; updatedAt: string; name: string; type: string; currentColor?: PaintColor;
  sheen: string; surfaces: string[]; lastPaintedDate: string; notes: string; conditionNotes: string;
  touchUpInstructions: string; contractorNotes: string; careNotes: string; photos: string[];
  photoDetails?: RoomPhoto[]; savedColors: SavedColor[];
};

export type VaultRecord = {
  id: string; createdAt: string; updatedAt: string; title: string;
  category: "Receipt" | "Contract / Quote" | "Warranty" | "Paint Color" | "Manual" | "Service Record" | "Other";
  room: string; notes: string; purchaseDate: string; expiryDate: string; color?: PaintColor;
  attachments: { name: string; type: string; data: string }[];
};

export type ReminderRecurrence = "None" | "Monthly" | "Every 3 months" | "Every 6 months" | "Yearly" | "Every 2 years" | "Every 3 years" | "Custom";
export type PaintReminder = {
  id: string; createdAt: string; title: string; detail: string;
  category: "Inspection" | "Cleaning" | "Touch-up" | "Caulk" | "Exterior" | "Moisture" | "Warranty" | "Custom";
  roomId: string; surface: string; dueDate: string; recurrence: ReminderRecurrence; customMonths?: number;
  priority: "Low" | "Normal" | "High"; notes: string; completedAt: string;
};

export type ActivityKind = "room" | "color" | "reminder" | "reminderDone" | "estimate" | "photo" | "scan" | "vision" | "expert" | "document";
export type ActivityEvent = { id: string; createdAt: string; kind: ActivityKind; title: string; detail: string; contextId?: string };
export type ChatMessage = { id: string; createdAt: string; role: "user" | "assistant"; text: string };
export type AppearanceMode = "system" | "light" | "dark";

export type HomeownerState = {
  version: 2; rooms: PaintRoom[]; records: VaultRecord[]; reminders: PaintReminder[]; scans: PaintScan[];
  projects: VisionProject[]; messages: ChatMessage[]; activity: ActivityEvent[];
  profile: { name: string; contact: string }; appearance: AppearanceMode; recentColors: PaintColor[];
};
