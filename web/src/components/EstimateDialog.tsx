import { useEffect, useState } from "react";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { Camera, CheckCircle2, LoaderCircle, Paintbrush, Send, X } from "lucide-react";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { useHomeowner } from "@/hooks/useHomeowner";
import { prepareImage } from "@/lib/ai";

const estimateSchema = z.object({
  name: z.string().trim().min(2, "Please enter your name."),
  contact: z.string().trim().min(5, "Please enter an email address or phone number."),
  room: z.string(),
  details: z.string().trim().max(2000, "Keep the project details under 2,000 characters."),
});

type EstimateForm = z.infer<typeof estimateSchema>;

type EstimateDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  context?: string;
  prefilledRoom?: string;
};

const EstimateDialog = ({ open, onOpenChange, context = "", prefilledRoom = "" }: EstimateDialogProps) => {
  const { state, updateProfile, logActivity } = useHomeowner();
  const [photos, setPhotos] = useState<{ file: File; preview: string }[]>([]);
  const [isPreparing, setIsPreparing] = useState<boolean>(false);
  const [sent, setSent] = useState<boolean>(false);
  const { register, handleSubmit, reset, formState: { errors, isSubmitting } } = useForm<EstimateForm>({
    resolver: zodResolver(estimateSchema),
    defaultValues: { name: state.profile.name, contact: state.profile.contact, room: prefilledRoom, details: "" },
  });

  useEffect((): void => {
    if (open) {
      reset({ name: state.profile.name, contact: state.profile.contact, room: prefilledRoom, details: "" });
      setSent(false);
    }
  }, [open, prefilledRoom, reset, state.profile.contact, state.profile.name]);

  const addPhotos = async (files: FileList | null): Promise<void> => {
    if (!files) return;
    setIsPreparing(true);
    try {
      const available = Math.max(0, 4 - photos.length);
      const selected = Array.from(files).slice(0, available);
      const prepared = await Promise.all(selected.map(async (file: File) => ({ file, preview: await prepareImage(file, 1200) })));
      setPhotos((current) => [...current, ...prepared]);
    } finally {
      setIsPreparing(false);
    }
  };

  const submit = async (values: EstimateForm): Promise<void> => {
    updateProfile({ name: values.name, contact: values.contact });
    const lines = [
      "New estimate request from the Taulbee Painting web app", "",
      `Name: ${values.name}`, `Contact: ${values.contact}`,
      values.room ? `Room / area: ${values.room}` : "",
      context,
      values.details ? `\nProject details:\n${values.details}` : "",
    ].filter(Boolean);
    const body = lines.join("\n");
    logActivity("estimate", values.room ? `Estimate requested for ${values.room}` : "Estimate requested", context || values.details);

    if (photos.length > 0 && navigator.share && navigator.canShare?.({ files: photos.map((photo) => photo.file) })) {
      try {
        await navigator.share({ title: `Estimate request — ${values.name}`, text: body, files: photos.map((photo) => photo.file) });
        setSent(true);
        return;
      } catch (error: unknown) {
        if (error instanceof DOMException && error.name === "AbortError") return;
      }
    }

    const subject = encodeURIComponent(`Estimate request — ${values.name}`);
    window.location.href = `mailto:taulbeepainting2@gmail.com?subject=${subject}&body=${encodeURIComponent(body)}`;
    setSent(true);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[92vh] overflow-y-auto sm:max-w-xl">
        {sent ? (
          <div className="py-8 text-center">
            <CheckCircle2 className="mx-auto h-16 w-16 text-emerald-600" />
            <h2 className="mt-4 font-display text-2xl font-bold">Your request is ready</h2>
            <p className="mx-auto mt-2 max-w-sm text-sm leading-6 text-muted-foreground">Finish sending it in the email or share window that opened. Taulbee Painting usually replies within one business day.</p>
            <button type="button" onClick={() => onOpenChange(false)} className="mt-6 min-h-11 rounded-full bg-primary px-6 text-sm font-bold text-primary-foreground">Done</button>
          </div>
        ) : (
          <>
            <DialogHeader>
              <div className="mb-2 flex h-12 w-12 items-center justify-center rounded-2xl bg-primary text-primary-foreground"><Paintbrush className="h-5 w-5" /></div>
              <DialogTitle className="font-display text-2xl">Request a free estimate</DialogTitle>
              <DialogDescription>Tell us what you’re planning. No pressure—just clear pricing from the Taulbee Painting team.</DialogDescription>
            </DialogHeader>
            {context && <div className="rounded-xl bg-accent px-3 py-2 text-xs font-semibold text-primary">{context}</div>}
            <form onSubmit={handleSubmit(submit)} className="space-y-4">
              <label className="block text-sm font-semibold">Your name
                <input {...register("name")} autoComplete="name" className="mt-1.5 min-h-12 w-full rounded-xl border border-input bg-background px-3 text-base outline-none focus:ring-2 focus:ring-ring" placeholder="Jamie Carter" />
                {errors.name && <span className="mt-1 block text-xs text-destructive">{errors.name.message}</span>}
              </label>
              <label className="block text-sm font-semibold">Email or phone
                <input {...register("contact")} autoComplete="email" className="mt-1.5 min-h-12 w-full rounded-xl border border-input bg-background px-3 text-base outline-none focus:ring-2 focus:ring-ring" placeholder="How should we reach you?" />
                {errors.contact && <span className="mt-1 block text-xs text-destructive">{errors.contact.message}</span>}
              </label>
              {state.rooms.length > 0 && <label className="block text-sm font-semibold">Room or area
                <select {...register("room")} className="mt-1.5 min-h-12 w-full rounded-xl border border-input bg-background px-3 text-base outline-none focus:ring-2 focus:ring-ring">
                  <option value="">Choose an area (optional)</option>
                  {state.rooms.map((room) => <option key={room.id} value={room.name}>{room.name}</option>)}
                </select>
              </label>}
              <label className="block text-sm font-semibold">Project details
                <textarea {...register("details")} rows={4} className="mt-1.5 w-full rounded-xl border border-input bg-background p-3 text-base outline-none focus:ring-2 focus:ring-ring" placeholder="What would you like painted or looked at?" />
                {errors.details && <span className="mt-1 block text-xs text-destructive">{errors.details.message}</span>}
              </label>
              <div>
                <div className="text-sm font-semibold">Photos <span className="font-normal text-muted-foreground">(optional, up to 4)</span></div>
                <div className="mt-2 flex flex-wrap gap-2">
                  {photos.map((photo, index) => <div key={`${photo.file.name}-${index}`} className="relative h-20 w-20 overflow-hidden rounded-xl border border-border">
                    <img src={photo.preview} alt="Project preview" className="h-full w-full object-cover" />
                    <button type="button" onClick={() => setPhotos((current) => current.filter((_, currentIndex) => currentIndex !== index))} className="absolute right-1 top-1 flex h-7 w-7 items-center justify-center rounded-full bg-black/65 text-white" aria-label="Remove photo"><X className="h-3.5 w-3.5" /></button>
                  </div>)}
                  {photos.length < 4 && <label className="flex h-20 w-20 cursor-pointer flex-col items-center justify-center rounded-xl border border-dashed border-primary/40 bg-accent/60 text-xs font-bold text-primary">
                    {isPreparing ? <LoaderCircle className="h-5 w-5 animate-spin" /> : <Camera className="h-5 w-5" />}<span className="mt-1">Add</span>
                    <input type="file" accept="image/*" multiple className="sr-only" onChange={(event) => void addPhotos(event.target.files)} />
                  </label>}
                </div>
                {photos.length > 0 && <p className="mt-2 text-xs leading-5 text-muted-foreground">On supported devices, photos are included through the share sheet. Otherwise your email app opens with the request text and you can attach the selected photos there.</p>}
              </div>
              <button type="submit" disabled={isSubmitting || isPreparing} className="inline-flex min-h-12 w-full items-center justify-center gap-2 rounded-xl bg-primary px-5 text-sm font-bold text-primary-foreground shadow-lg shadow-primary/20 disabled:opacity-50">
                {isSubmitting ? <LoaderCircle className="h-4 w-4 animate-spin" /> : <Send className="h-4 w-4" />} Send Request
              </button>
            </form>
          </>
        )}
      </DialogContent>
    </Dialog>
  );
};

export default EstimateDialog;
