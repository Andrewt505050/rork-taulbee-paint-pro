import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import type { ReactNode } from "react";
import type { ActivityEvent, ActivityKind, AppearanceMode, ChatMessage, HomeownerState, PaintColor, PaintReminder, PaintRoom, PaintScan, VaultRecord, VisionProject } from "@/lib/homeownerTypes";

const initialState: HomeownerState = { version: 2, rooms: [], records: [], reminders: [], scans: [], projects: [], messages: [], activity: [], profile: { name: "", contact: "" }, appearance: "system", recentColors: [] };
const DB_NAME = "taulbee-painting-homeowner";
const STORE_NAME = "state";
const STATE_KEY = "homeowner-state";
const makeId = (prefix: string): string => `${prefix}-${Date.now()}-${crypto.randomUUID?.() ?? Math.random().toString(36).slice(2)}`;
const nowISO = (): string => new Date().toISOString();

const openDatabase = (): Promise<IDBDatabase> => new Promise((resolve, reject): void => {
  if (!("indexedDB" in window)) { reject(new Error("Private browser storage is unavailable.")); return; }
  const request = indexedDB.open(DB_NAME, 1);
  request.onupgradeneeded = (): void => { if (!request.result.objectStoreNames.contains(STORE_NAME)) request.result.createObjectStore(STORE_NAME); };
  request.onsuccess = (): void => resolve(request.result);
  request.onerror = (): void => reject(request.error ?? new Error("Unable to open browser storage."));
});

const migrateState = (value: unknown): HomeownerState => {
  if (!value || typeof value !== "object") return initialState;
  const saved = value as Partial<HomeownerState> & { version?: number };
  return {
    ...initialState,
    ...saved,
    version: 2,
    rooms: Array.isArray(saved.rooms) ? saved.rooms.map((room: PaintRoom) => ({ ...room, contractorNotes: room.contractorNotes ?? "", photos: room.photos ?? [], savedColors: room.savedColors ?? [] })) : [],
    records: Array.isArray(saved.records) ? saved.records : [], reminders: Array.isArray(saved.reminders) ? saved.reminders : [],
    scans: Array.isArray(saved.scans) ? saved.scans : [], projects: Array.isArray(saved.projects) ? saved.projects : [],
    messages: Array.isArray(saved.messages) ? saved.messages : [], activity: Array.isArray(saved.activity) ? saved.activity : [],
    recentColors: Array.isArray(saved.recentColors) ? saved.recentColors : [],
    profile: saved.profile ?? initialState.profile, appearance: saved.appearance ?? "system",
  };
};

const readStoredState = async (): Promise<HomeownerState> => {
  const database = await openDatabase();
  return await new Promise<HomeownerState>((resolve, reject): void => {
    const transaction = database.transaction(STORE_NAME, "readonly");
    const request = transaction.objectStore(STORE_NAME).get(STATE_KEY);
    request.onsuccess = (): void => resolve(migrateState(request.result));
    request.onerror = (): void => reject(request.error ?? new Error("Unable to read browser storage."));
    transaction.oncomplete = (): void => database.close();
  });
};

const writeStoredState = async (state: HomeownerState): Promise<void> => {
  const database = await openDatabase();
  await new Promise<void>((resolve, reject): void => {
    const transaction = database.transaction(STORE_NAME, "readwrite");
    transaction.objectStore(STORE_NAME).put(state, STATE_KEY);
    transaction.oncomplete = (): void => { database.close(); resolve(); };
    transaction.onerror = (): void => { database.close(); reject(transaction.error ?? new Error("Unable to save browser data.")); };
  });
};

type HomeownerContextValue = {
  state: HomeownerState; isReady: boolean; storageError: string; lastSavedAt: string;
  addRoom: (input: Omit<PaintRoom, "id" | "createdAt" | "updatedAt">) => PaintRoom; updateRoom: (id: string, input: Partial<PaintRoom>) => void; removeRoom: (id: string) => void;
  addRecord: (input: Omit<VaultRecord, "id" | "createdAt" | "updatedAt">) => VaultRecord; updateRecord: (id: string, input: Partial<VaultRecord>) => void; removeRecord: (id: string) => void;
  addReminder: (input: Omit<PaintReminder, "id" | "createdAt" | "completedAt">) => PaintReminder; updateReminder: (id: string, input: Partial<PaintReminder>) => void; completeReminder: (id: string) => void; removeReminder: (id: string) => void;
  addScan: (input: Omit<PaintScan, "id" | "createdAt">) => PaintScan; removeScan: (id: string) => void;
  addProject: (input: Omit<VisionProject, "id" | "createdAt">) => VisionProject; removeProject: (id: string) => void;
  addMessage: (input: Omit<ChatMessage, "id" | "createdAt">) => ChatMessage; clearMessages: () => void;
  rememberColor: (color: PaintColor) => void; logActivity: (kind: ActivityKind, title: string, detail?: string, contextId?: string) => void;
  updateProfile: (profile: { name: string; contact: string }) => void; setAppearance: (mode: AppearanceMode) => void; resetAllData: () => void;
};

const HomeownerContext = createContext<HomeownerContextValue | undefined>(undefined);
const recurrenceMonths = (reminder: PaintReminder): number => ({ None: 0, Monthly: 1, "Every 3 months": 3, "Every 6 months": 6, Yearly: 12, "Every 2 years": 24, "Every 3 years": 36, Custom: Math.max(1, reminder.customMonths ?? 1) })[reminder.recurrence];

export const HomeownerProvider = ({ children }: { children: ReactNode }) => {
  const [state, setState] = useState<HomeownerState>(initialState);
  const [isReady, setIsReady] = useState<boolean>(false);
  const [storageError, setStorageError] = useState<string>("");
  const [lastSavedAt, setLastSavedAt] = useState<string>("");
  const saveTimer = useRef<number | undefined>(undefined);

  useEffect((): (() => void) => { let mounted = true; void readStoredState().then((saved) => { if (mounted) setState(saved); }).catch(() => { if (mounted) setStorageError("Your browser blocked private storage. Changes will not survive after you leave."); }).finally(() => { if (mounted) setIsReady(true); }); return () => { mounted = false; }; }, []);
  useEffect((): (() => void) | void => { if (!isReady) return; window.clearTimeout(saveTimer.current); saveTimer.current = window.setTimeout(() => { void writeStoredState(state).then(() => { setStorageError(""); setLastSavedAt(nowISO()); }).catch(() => setStorageError("Browser storage is full or unavailable. Remove large photos before saving more work.")); }, 200); return () => window.clearTimeout(saveTimer.current); }, [isReady, state]);
  useEffect((): void => { const root = document.documentElement; root.classList.remove("dark"); if (state.appearance === "dark" || (state.appearance === "system" && window.matchMedia("(prefers-color-scheme: dark)").matches)) root.classList.add("dark"); }, [state.appearance]);

  const logActivity = useCallback((kind: ActivityKind, title: string, detail = "", contextId?: string): void => setState((current) => ({ ...current, activity: [{ id: makeId("activity"), createdAt: nowISO(), kind, title, detail, contextId }, ...current.activity].slice(0, 300) })), []);
  const addRoom = useCallback((input: Omit<PaintRoom, "id" | "createdAt" | "updatedAt">): PaintRoom => { const createdAt = nowISO(); const room = { ...input, id: makeId("room"), createdAt, updatedAt: createdAt }; setState((current) => ({ ...current, rooms: [room, ...current.rooms], activity: [{ id: makeId("activity"), createdAt, kind: "room", title: `${room.name} added`, detail: room.type, contextId: room.id }, ...current.activity] })); return room; }, []);
  const updateRoom = useCallback((id: string, input: Partial<PaintRoom>): void => setState((current) => ({ ...current, rooms: current.rooms.map((item) => item.id === id ? { ...item, ...input, id, updatedAt: nowISO() } : item) })), []);
  const removeRoom = useCallback((id: string): void => setState((current) => ({ ...current, rooms: current.rooms.filter((item) => item.id !== id), reminders: current.reminders.map((item) => item.roomId === id ? { ...item, roomId: "" } : item) })), []);
  const addRecord = useCallback((input: Omit<VaultRecord, "id" | "createdAt" | "updatedAt">): VaultRecord => { const createdAt = nowISO(); const record = { ...input, id: makeId("record"), createdAt, updatedAt: createdAt }; setState((current) => ({ ...current, records: [record, ...current.records], activity: [{ id: makeId("activity"), createdAt, kind: "document", title: `${record.title} saved`, detail: record.category, contextId: record.id }, ...current.activity] })); return record; }, []);
  const updateRecord = useCallback((id: string, input: Partial<VaultRecord>): void => setState((current) => ({ ...current, records: current.records.map((item) => item.id === id ? { ...item, ...input, id, updatedAt: nowISO() } : item) })), []);
  const removeRecord = useCallback((id: string): void => setState((current) => ({ ...current, records: current.records.filter((item) => item.id !== id) })), []);
  const addReminder = useCallback((input: Omit<PaintReminder, "id" | "createdAt" | "completedAt">): PaintReminder => { const createdAt = nowISO(); const reminder = { ...input, id: makeId("reminder"), createdAt, completedAt: "" }; setState((current) => ({ ...current, reminders: [...current.reminders, reminder], activity: [{ id: makeId("activity"), createdAt, kind: "reminder", title: reminder.title, detail: reminder.dueDate, contextId: reminder.id }, ...current.activity] })); return reminder; }, []);
  const updateReminder = useCallback((id: string, input: Partial<PaintReminder>): void => setState((current) => ({ ...current, reminders: current.reminders.map((item) => item.id === id ? { ...item, ...input, id } : item) })), []);
  const completeReminder = useCallback((id: string): void => setState((current) => { const reminder = current.reminders.find((item) => item.id === id); if (!reminder || reminder.completedAt) return current; const completedAt = nowISO(); const months = recurrenceMonths(reminder); const due = new Date(`${reminder.dueDate}T12:00:00`); due.setMonth(due.getMonth() + months); const next = months ? [{ ...reminder, id: makeId("reminder"), createdAt: completedAt, dueDate: due.toISOString().slice(0, 10), completedAt: "" }] : []; return { ...current, reminders: [...current.reminders.map((item) => item.id === id ? { ...item, completedAt } : item), ...next], activity: [{ id: makeId("activity"), createdAt: completedAt, kind: "reminderDone", title: `${reminder.title} completed`, detail: reminder.surface, contextId: id }, ...current.activity] }; }), []);
  const removeReminder = useCallback((id: string): void => setState((current) => ({ ...current, reminders: current.reminders.filter((item) => item.id !== id) })), []);
  const addScan = useCallback((input: Omit<PaintScan, "id" | "createdAt">): PaintScan => { const scan = { ...input, id: makeId("scan"), createdAt: nowISO() }; setState((current) => ({ ...current, scans: [scan, ...current.scans], activity: [{ id: makeId("activity"), createdAt: scan.createdAt, kind: "scan", title: scan.defectName, detail: scan.surface, contextId: scan.id }, ...current.activity] })); return scan; }, []);
  const removeScan = useCallback((id: string): void => setState((current) => ({ ...current, scans: current.scans.filter((item) => item.id !== id) })), []);
  const addProject = useCallback((input: Omit<VisionProject, "id" | "createdAt">): VisionProject => { const project = { ...input, id: makeId("vision"), createdAt: nowISO() }; setState((current) => ({ ...current, projects: [project, ...current.projects], activity: [{ id: makeId("activity"), createdAt: project.createdAt, kind: "vision", title: `${project.scheme[0]?.color.name ?? "Paint"} visualization`, detail: project.scheme.map((item) => item.surface).join(", "), contextId: project.id }, ...current.activity] })); return project; }, []);
  const removeProject = useCallback((id: string): void => setState((current) => ({ ...current, projects: current.projects.filter((item) => item.id !== id) })), []);
  const addMessage = useCallback((input: Omit<ChatMessage, "id" | "createdAt">): ChatMessage => { const message = { ...input, id: makeId("message"), createdAt: nowISO() }; setState((current) => ({ ...current, messages: [...current.messages, message], activity: input.role === "user" ? [{ id: makeId("activity"), createdAt: message.createdAt, kind: "expert", title: input.text, detail: "Paint Expert" }, ...current.activity] : current.activity })); return message; }, []);
  const clearMessages = useCallback((): void => setState((current) => ({ ...current, messages: [] })), []);
  const rememberColor = useCallback((color: PaintColor): void => setState((current) => ({ ...current, recentColors: [color, ...current.recentColors.filter((item) => item.id !== color.id)].slice(0, 18) })), []);
  const updateProfile = useCallback((profile: { name: string; contact: string }): void => setState((current) => ({ ...current, profile })), []);
  const setAppearance = useCallback((appearance: AppearanceMode): void => setState((current) => ({ ...current, appearance })), []);
  const resetAllData = useCallback((): void => setState((current) => ({ ...initialState, appearance: current.appearance })), []);

  const value = useMemo<HomeownerContextValue>(() => ({ state, isReady, storageError, lastSavedAt, addRoom, updateRoom, removeRoom, addRecord, updateRecord, removeRecord, addReminder, updateReminder, completeReminder, removeReminder, addScan, removeScan, addProject, removeProject, addMessage, clearMessages, rememberColor, logActivity, updateProfile, setAppearance, resetAllData }), [state, isReady, storageError, lastSavedAt, addRoom, updateRoom, removeRoom, addRecord, updateRecord, removeRecord, addReminder, updateReminder, completeReminder, removeReminder, addScan, removeScan, addProject, removeProject, addMessage, clearMessages, rememberColor, logActivity, updateProfile, setAppearance, resetAllData]);
  return <HomeownerContext.Provider value={value}>{children}</HomeownerContext.Provider>;
};

/** Accesses private browser-local homeowner records and mutations. */
export const useHomeowner = (): HomeownerContextValue => { const context = useContext(HomeownerContext); if (!context) throw new Error("useHomeowner must be used inside HomeownerProvider."); return context; };
