import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import type { ReactNode } from "react";
import type {
  ActivityEvent,
  ActivityKind,
  AppearanceMode,
  ChatMessage,
  HomeownerState,
  PaintReminder,
  PaintRoom,
  PaintScan,
  VaultRecord,
  VisionProject,
} from "@/lib/homeownerTypes";

const initialState: HomeownerState = {
  version: 1,
  rooms: [],
  records: [],
  reminders: [],
  scans: [],
  projects: [],
  messages: [],
  activity: [],
  profile: { name: "", contact: "" },
  appearance: "system",
};

const DB_NAME = "taulbee-painting-homeowner";
const STORE_NAME = "state";
const STATE_KEY = "homeowner-state";

const makeId = (prefix: string): string => `${prefix}-${Date.now()}-${crypto.randomUUID?.() ?? Math.random().toString(36).slice(2)}`;
const nowISO = (): string => new Date().toISOString();

const openDatabase = (): Promise<IDBDatabase> => new Promise((resolve, reject): void => {
  const request = indexedDB.open(DB_NAME, 1);
  request.onupgradeneeded = (): void => {
    const database = request.result;
    if (!database.objectStoreNames.contains(STORE_NAME)) database.createObjectStore(STORE_NAME);
  };
  request.onsuccess = (): void => resolve(request.result);
  request.onerror = (): void => reject(request.error ?? new Error("Unable to open browser storage."));
});

const readStoredState = async (): Promise<HomeownerState> => {
  if (!("indexedDB" in window)) return initialState;
  const database = await openDatabase();
  return await new Promise<HomeownerState>((resolve): void => {
    const transaction = database.transaction(STORE_NAME, "readonly");
    const request = transaction.objectStore(STORE_NAME).get(STATE_KEY);
    request.onsuccess = (): void => {
      const saved = request.result as HomeownerState | undefined;
      resolve(saved?.version === 1 ? saved : initialState);
    };
    request.onerror = (): void => resolve(initialState);
    transaction.oncomplete = (): void => database.close();
  });
};

const writeStoredState = async (state: HomeownerState): Promise<void> => {
  if (!("indexedDB" in window)) return;
  const database = await openDatabase();
  await new Promise<void>((resolve, reject): void => {
    const transaction = database.transaction(STORE_NAME, "readwrite");
    transaction.objectStore(STORE_NAME).put(state, STATE_KEY);
    transaction.oncomplete = (): void => { database.close(); resolve(); };
    transaction.onerror = (): void => { database.close(); reject(transaction.error); };
  });
};

type HomeownerContextValue = {
  state: HomeownerState;
  isReady: boolean;
  storageError: string;
  addRoom: (room: Omit<PaintRoom, "id" | "createdAt" | "updatedAt">) => PaintRoom;
  removeRoom: (id: string) => void;
  addRecord: (record: Omit<VaultRecord, "id" | "createdAt" | "updatedAt">) => VaultRecord;
  removeRecord: (id: string) => void;
  addReminder: (reminder: Omit<PaintReminder, "id" | "createdAt" | "completedAt">) => PaintReminder;
  completeReminder: (id: string) => void;
  removeReminder: (id: string) => void;
  addScan: (scan: Omit<PaintScan, "id" | "createdAt">) => PaintScan;
  addProject: (project: Omit<VisionProject, "id" | "createdAt">) => VisionProject;
  addMessage: (message: Omit<ChatMessage, "id" | "createdAt">) => ChatMessage;
  clearMessages: () => void;
  logActivity: (kind: ActivityKind, title: string, detail?: string) => void;
  updateProfile: (profile: { name: string; contact: string }) => void;
  setAppearance: (mode: AppearanceMode) => void;
  resetAllData: () => void;
};

const HomeownerContext = createContext<HomeownerContextValue | undefined>(undefined);

const recurrenceMonths: Record<PaintReminder["recurrence"], number> = {
  None: 0,
  Monthly: 1,
  "Every 3 months": 3,
  "Every 6 months": 6,
  Yearly: 12,
};

export const HomeownerProvider = ({ children }: { children: ReactNode }) => {
  const [state, setState] = useState<HomeownerState>(initialState);
  const [isReady, setIsReady] = useState<boolean>(false);
  const [storageError, setStorageError] = useState<string>("");
  const saveTimer = useRef<number | undefined>(undefined);

  useEffect((): (() => void) => {
    let isMounted = true;
    void readStoredState().then((saved: HomeownerState): void => {
      if (isMounted) setState(saved);
    }).catch((): void => {
      if (isMounted) setStorageError("Your browser blocked private project storage. Changes may not be saved.");
    }).finally((): void => {
      if (isMounted) setIsReady(true);
    });
    return (): void => { isMounted = false; };
  }, []);

  useEffect((): (() => void) | void => {
    if (!isReady) return;
    window.clearTimeout(saveTimer.current);
    saveTimer.current = window.setTimeout((): void => {
      void writeStoredState(state).catch((): void => setStorageError("Browser storage is full. Remove large projects or photos, then try again."));
    }, 250);
    return (): void => window.clearTimeout(saveTimer.current);
  }, [isReady, state]);

  useEffect((): void => {
    const root = document.documentElement;
    root.classList.remove("dark");
    const shouldUseDark = state.appearance === "dark" || (state.appearance === "system" && window.matchMedia("(prefers-color-scheme: dark)").matches);
    if (shouldUseDark) root.classList.add("dark");
  }, [state.appearance]);

  const logActivity = useCallback((kind: ActivityKind, title: string, detail = ""): void => {
    const event: ActivityEvent = { id: makeId("activity"), createdAt: nowISO(), kind, title, detail };
    setState((current: HomeownerState): HomeownerState => ({ ...current, activity: [event, ...current.activity].slice(0, 250) }));
  }, []);

  const addRoom = useCallback((input: Omit<PaintRoom, "id" | "createdAt" | "updatedAt">): PaintRoom => {
    const createdAt = nowISO();
    const room: PaintRoom = { ...input, id: makeId("room"), createdAt, updatedAt: createdAt };
    const event: ActivityEvent = { id: makeId("activity"), createdAt, kind: "room", title: `${room.name} added`, detail: room.type };
    setState((current: HomeownerState): HomeownerState => ({ ...current, rooms: [room, ...current.rooms], activity: [event, ...current.activity] }));
    return room;
  }, []);

  const removeRoom = useCallback((id: string): void => setState((current: HomeownerState): HomeownerState => ({
    ...current,
    rooms: current.rooms.filter((room: PaintRoom): boolean => room.id !== id),
    reminders: current.reminders.filter((reminder: PaintReminder): boolean => reminder.roomId !== id),
  })), []);

  const addRecord = useCallback((input: Omit<VaultRecord, "id" | "createdAt" | "updatedAt">): VaultRecord => {
    const createdAt = nowISO();
    const record: VaultRecord = { ...input, id: makeId("record"), createdAt, updatedAt: createdAt };
    const event: ActivityEvent = { id: makeId("activity"), createdAt, kind: "document", title: `${record.title} saved`, detail: record.category };
    setState((current: HomeownerState): HomeownerState => ({ ...current, records: [record, ...current.records], activity: [event, ...current.activity] }));
    return record;
  }, []);

  const removeRecord = useCallback((id: string): void => setState((current: HomeownerState): HomeownerState => ({ ...current, records: current.records.filter((record: VaultRecord): boolean => record.id !== id) })), []);

  const addReminder = useCallback((input: Omit<PaintReminder, "id" | "createdAt" | "completedAt">): PaintReminder => {
    const createdAt = nowISO();
    const reminder: PaintReminder = { ...input, id: makeId("reminder"), createdAt, completedAt: "" };
    const event: ActivityEvent = { id: makeId("activity"), createdAt, kind: "reminder", title: reminder.title, detail: reminder.dueDate };
    setState((current: HomeownerState): HomeownerState => ({ ...current, reminders: [...current.reminders, reminder], activity: [event, ...current.activity] }));
    return reminder;
  }, []);

  const completeReminder = useCallback((id: string): void => {
    setState((current: HomeownerState): HomeownerState => {
      const reminder = current.reminders.find((item: PaintReminder): boolean => item.id === id);
      if (!reminder || reminder.completedAt) return current;
      const completedAt = nowISO();
      const completed = { ...reminder, completedAt };
      const months = recurrenceMonths[reminder.recurrence];
      const nextDate = new Date(reminder.dueDate);
      nextDate.setMonth(nextDate.getMonth() + months);
      const next: PaintReminder[] = months > 0 ? [{ ...reminder, id: makeId("reminder"), createdAt: completedAt, dueDate: nextDate.toISOString().slice(0, 10), completedAt: "" }] : [];
      const event: ActivityEvent = { id: makeId("activity"), createdAt: completedAt, kind: "reminderDone", title: `${reminder.title} completed`, detail: reminder.surface };
      return {
        ...current,
        reminders: [...current.reminders.map((item: PaintReminder): PaintReminder => item.id === id ? completed : item), ...next],
        activity: [event, ...current.activity],
      };
    });
  }, []);

  const removeReminder = useCallback((id: string): void => setState((current: HomeownerState): HomeownerState => ({ ...current, reminders: current.reminders.filter((item: PaintReminder): boolean => item.id !== id) })), []);

  const addScan = useCallback((input: Omit<PaintScan, "id" | "createdAt">): PaintScan => {
    const createdAt = nowISO();
    const scan: PaintScan = { ...input, id: makeId("scan"), createdAt };
    const event: ActivityEvent = { id: makeId("activity"), createdAt, kind: "scan", title: scan.defectName, detail: scan.surface };
    setState((current: HomeownerState): HomeownerState => ({ ...current, scans: [scan, ...current.scans], activity: [event, ...current.activity] }));
    return scan;
  }, []);

  const addProject = useCallback((input: Omit<VisionProject, "id" | "createdAt">): VisionProject => {
    const createdAt = nowISO();
    const project: VisionProject = { ...input, id: makeId("vision"), createdAt };
    const event: ActivityEvent = { id: makeId("activity"), createdAt, kind: "vision", title: `${project.scheme[0]?.color.name ?? "Paint"} visualization`, detail: project.scheme.map((item) => item.surface).join(", ") };
    setState((current: HomeownerState): HomeownerState => ({ ...current, projects: [project, ...current.projects], activity: [event, ...current.activity] }));
    return project;
  }, []);

  const addMessage = useCallback((input: Omit<ChatMessage, "id" | "createdAt">): ChatMessage => {
    const createdAt = nowISO();
    const message: ChatMessage = { ...input, id: makeId("message"), createdAt };
    setState((current: HomeownerState): HomeownerState => ({
      ...current,
      messages: [...current.messages, message],
      activity: input.role === "user" ? [{ id: makeId("activity"), createdAt, kind: "expert", title: input.text, detail: "Paint Expert" }, ...current.activity] : current.activity,
    }));
    return message;
  }, []);

  const clearMessages = useCallback((): void => setState((current: HomeownerState): HomeownerState => ({ ...current, messages: [] })), []);
  const updateProfile = useCallback((profile: { name: string; contact: string }): void => setState((current: HomeownerState): HomeownerState => ({ ...current, profile })), []);
  const setAppearance = useCallback((appearance: AppearanceMode): void => setState((current: HomeownerState): HomeownerState => ({ ...current, appearance })), []);
  const resetAllData = useCallback((): void => setState({ ...initialState, appearance: state.appearance }), [state.appearance]);

  const value = useMemo<HomeownerContextValue>(() => ({
    state, isReady, storageError, addRoom, removeRoom, addRecord, removeRecord, addReminder,
    completeReminder, removeReminder, addScan, addProject, addMessage, clearMessages,
    logActivity, updateProfile, setAppearance, resetAllData,
  }), [state, isReady, storageError, addRoom, removeRoom, addRecord, removeRecord, addReminder, completeReminder, removeReminder, addScan, addProject, addMessage, clearMessages, logActivity, updateProfile, setAppearance, resetAllData]);

  return <HomeownerContext.Provider value={value}>{children}</HomeownerContext.Provider>;
};

/** Accesses private browser-local homeowner records and mutations. */
export const useHomeowner = (): HomeownerContextValue => {
  const context = useContext(HomeownerContext);
  if (!context) throw new Error("useHomeowner must be used inside HomeownerProvider.");
  return context;
};
