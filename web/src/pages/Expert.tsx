import { useEffect, useMemo, useRef, useState } from "react";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { BookOpen, Bot, ChevronRight, Droplets, Eraser, Home, LoaderCircle, MessageCircleQuestion, Paintbrush, Search, Send, Sparkles, Trash2 } from "lucide-react";
import EstimateDialog from "@/components/EstimateDialog";
import { useHomeowner } from "@/hooks/useHomeowner";
import { askPaintExpert } from "@/lib/ai";
import type { ChatMessage } from "@/lib/homeownerTypes";

const questionSchema = z.object({ question: z.string().trim().min(2).max(1000) });
type QuestionForm = z.infer<typeof questionSchema>;

type Product = { id: string; name: string; brand: string; category: string; finish: string; bestFor: string; features: string[] };
const PRODUCTS: Product[] = [
  { id: "sw-emerald", name: "Emerald Interior Acrylic Latex", brand: "Sherwin-Williams", category: "Interior walls", finish: "Matte / Satin", bestFor: "Premium washable walls in high-traffic living spaces.", features: ["Excellent scrubbability", "Strong hide", "Low odor and low VOC"] },
  { id: "bm-regal", name: "Regal Select Interior", brand: "Benjamin Moore", category: "Interior walls", finish: "Matte / Eggshell", bestFor: "Smooth, durable bedrooms, hallways, and living rooms.", features: ["Easy touch-up", "Stain release", "Self-priming on many surfaces"] },
  { id: "ppg-diamond", name: "Diamond Interior", brand: "PPG", category: "Interior walls", finish: "Eggshell", bestFor: "Budget-friendly durability for busy households.", features: ["Scuff resistant", "Paint and primer", "Mildew-resistant finish"] },
  { id: "bm-advance", name: "Advance Interior Alkyd", brand: "Benjamin Moore", category: "Trim & cabinets", finish: "Satin / Semi-Gloss", bestFor: "Furniture-smooth trim, doors, and cabinetry.", features: ["Hard enamel cure", "Excellent leveling", "Soap-and-water cleanup"] },
  { id: "sw-urethane", name: "Emerald Urethane Trim Enamel", brand: "Sherwin-Williams", category: "Trim & cabinets", finish: "Satin / Semi-Gloss", bestFor: "An ultra-hard finish on trim, doors, and cabinets.", features: ["Chip resistance", "Smooth leveling", "Washable finish"] },
  { id: "sw-duration", name: "Duration Exterior Acrylic", brand: "Sherwin-Williams", category: "Exterior", finish: "Flat / Satin", bestFor: "Long-lasting protection on siding and stucco.", features: ["Flexible coating", "Fade resistance", "Mildew resistance"] },
  { id: "bm-aura", name: "Aura Exterior", brand: "Benjamin Moore", category: "Exterior", finish: "Low-Lustre / Satin", bestFor: "Rich exterior color with excellent fade resistance.", features: ["Color Lock technology", "Cool-weather application", "Strong coverage"] },
  { id: "zinsser-bin", name: "B-I-N Shellac Primer", brand: "Zinsser", category: "Primer", finish: "Primer", bestFor: "Blocking water, smoke, tannin stains, knots, and odors.", features: ["Fast drying", "Glossy-surface adhesion", "Powerful stain blocking"] },
];

const STARTERS = [
  "What's the best paint for a humid bathroom?",
  "How do I fix peeling paint on my deck?",
  "Which finish should I use for kitchen cabinets?",
  "How do I prep walls before painting?",
  "What primer blocks water stains on a ceiling?",
];

const Expert = () => {
  const { state, addMessage, clearMessages } = useHomeowner();
  const [tab, setTab] = useState<"chat" | "products">("chat");
  const [isThinking, setIsThinking] = useState<boolean>(false);
  const [error, setError] = useState<string>("");
  const [productQuery, setProductQuery] = useState<string>("");
  const [estimateOpen, setEstimateOpen] = useState<boolean>(false);
  const bottomRef = useRef<HTMLDivElement>(null);
  const { register, handleSubmit, reset, setValue, formState: { isValid } } = useForm<QuestionForm>({ resolver: zodResolver(questionSchema), mode: "onChange", defaultValues: { question: "" } });

  useEffect((): void => bottomRef.current?.scrollIntoView({ behavior: "smooth" }), [state.messages, isThinking]);

  const send = async (rawQuestion: string): Promise<void> => {
    const question = rawQuestion.trim();
    if (!question || isThinking) return;
    setTab("chat");
    setError("");
    reset({ question: "" });
    const user = addMessage({ role: "user", text: question });
    setIsThinking(true);
    try {
      const reply = await askPaintExpert([...state.messages, user]);
      addMessage({ role: "assistant", text: reply });
    } catch (chatError: unknown) {
      setError(chatError instanceof Error ? chatError.message : "The Paint Expert couldn't answer right now.");
    } finally {
      setIsThinking(false);
    }
  };

  const submit = (values: QuestionForm): void => { void send(values.question); };
  const filteredProducts = useMemo<Product[]>(() => PRODUCTS.filter((product: Product): boolean => `${product.name} ${product.brand} ${product.category}`.toLowerCase().includes(productQuery.toLowerCase())), [productQuery]);

  return (
    <div className="mx-auto max-w-4xl">
      <div className="flex flex-wrap items-end justify-between gap-3"><div><p className="text-sm font-bold uppercase tracking-[0.16em] text-primary/70">Practical guidance</p><h1 className="mt-1 font-display text-3xl font-bold sm:text-4xl">Paint Expert</h1><p className="mt-2 text-sm text-muted-foreground">Real answers for prep, color, finishes, and product choices.</p></div><div className="flex rounded-full bg-muted p-1"><button type="button" onClick={() => setTab("chat")} className={`min-h-10 rounded-full px-4 text-sm font-bold ${tab === "chat" ? "bg-card text-primary shadow-sm" : "text-muted-foreground"}`}>Ask Expert</button><button type="button" onClick={() => setTab("products")} className={`min-h-10 rounded-full px-4 text-sm font-bold ${tab === "products" ? "bg-card text-primary shadow-sm" : "text-muted-foreground"}`}>Product Library</button></div></div>

      {tab === "chat" ? <div className="mt-5 overflow-hidden rounded-[1.75rem] border border-border bg-card shadow-lg">
        <div className="flex min-h-[60vh] flex-col">
          <div className="flex-1 space-y-4 overflow-y-auto p-4 sm:p-6">
            {state.messages.length === 0 && <div className="py-5 text-center"><span className="mx-auto flex h-20 w-20 items-center justify-center rounded-full bg-primary text-primary-foreground shadow-xl shadow-primary/25"><MessageCircleQuestion className="h-8 w-8" /></span><h2 className="mt-4 font-display text-2xl font-bold">What are you working on?</h2><p className="mt-2 text-sm text-muted-foreground">Choose a common question or ask your own.</p><div className="mx-auto mt-6 grid max-w-2xl gap-2 sm:grid-cols-2">{STARTERS.map((question: string, index: number) => <button type="button" key={question} onClick={() => void send(question)} className="flex min-h-14 items-center gap-3 rounded-2xl border border-border bg-background p-3 text-left text-sm font-semibold transition hover:border-primary/35 hover:bg-accent/50"><span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-accent text-primary">{index === 0 ? <Droplets className="h-4 w-4" /> : index === 1 ? <Home className="h-4 w-4" /> : <Sparkles className="h-4 w-4" />}</span>{question}</button>)}</div></div>}
            {state.messages.map((message: ChatMessage) => <div key={message.id} className={`flex ${message.role === "user" ? "justify-end" : "justify-start"}`}><div className={`max-w-[86%] rounded-2xl px-4 py-3 text-sm leading-6 sm:max-w-[74%] ${message.role === "user" ? "rounded-br-md bg-primary text-primary-foreground" : "rounded-bl-md bg-muted text-foreground"}`}><div className="mb-1 flex items-center gap-1.5 text-[10px] font-extrabold uppercase tracking-wider opacity-70">{message.role === "user" ? "You" : <><Bot className="h-3 w-3" /> Taulbee Paint Expert</>}</div><div className="whitespace-pre-wrap">{message.text}</div></div></div>)}
            {isThinking && <div className="flex justify-start"><div className="flex items-center gap-2 rounded-2xl rounded-bl-md bg-muted px-4 py-3 text-sm font-semibold text-muted-foreground"><LoaderCircle className="h-4 w-4 animate-spin" /> Thinking through your project…</div></div>}
            {error && <div role="alert" className="rounded-xl border border-destructive/25 bg-destructive/5 p-3 text-center text-sm font-semibold text-destructive">{error}</div>}
            <div ref={bottomRef} />
          </div>
          <form onSubmit={handleSubmit(submit)} className="border-t border-border bg-background/80 p-3 backdrop-blur sm:p-4"><div className="flex items-end gap-2"><textarea {...register("question")} rows={1} className="min-h-12 max-h-32 flex-1 resize-y rounded-2xl border border-input bg-card px-4 py-3 text-base outline-none focus:ring-2 focus:ring-ring" placeholder="Ask about paint, prep, color…" /><button type="submit" disabled={!isValid || isThinking} className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground disabled:opacity-40" aria-label="Send question"><Send className="h-5 w-5" /></button></div>{state.messages.length > 0 && <div className="mt-2 flex items-center justify-between"><button type="button" onClick={clearMessages} className="inline-flex min-h-9 items-center gap-1.5 px-2 text-xs font-bold text-muted-foreground hover:text-destructive"><Trash2 className="h-3.5 w-3.5" /> Clear conversation</button><button type="button" onClick={() => setEstimateOpen(true)} className="text-xs font-bold text-primary">Ask Taulbee for a quote</button></div>}</form>
        </div>
      </div> : <div className="mt-5"><div className="relative"><Search className="absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" /><input value={productQuery} onChange={(event) => setProductQuery(event.target.value)} className="min-h-12 w-full rounded-2xl border border-input bg-card pl-11 pr-4 outline-none focus:ring-2 focus:ring-ring" placeholder="Search recommended products" /></div><div className="mt-4 grid gap-3 sm:grid-cols-2">{filteredProducts.map((product: Product) => <article key={product.id} className="rounded-2xl border border-border bg-card p-5 shadow-sm"><div className="flex items-start gap-3"><span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-accent text-primary"><Paintbrush className="h-5 w-5" /></span><div><div className="text-xs font-extrabold uppercase tracking-wider text-primary/70">{product.brand}</div><h2 className="mt-1 font-display text-lg font-bold leading-tight">{product.name}</h2><p className="mt-1 text-xs font-semibold text-muted-foreground">{product.category} · {product.finish}</p></div></div><p className="mt-4 text-sm leading-6 text-muted-foreground">{product.bestFor}</p><ul className="mt-3 space-y-1.5">{product.features.map((feature: string) => <li key={feature} className="flex items-center gap-2 text-xs"><span className="h-1.5 w-1.5 rounded-full bg-primary" />{feature}</li>)}</ul><button type="button" onClick={() => void send(`Would ${product.brand} ${product.name} be a good choice for my project? What prep and finish do you recommend?`)} className="mt-4 inline-flex min-h-10 w-full items-center justify-center gap-2 rounded-xl bg-accent text-xs font-bold text-primary"><BookOpen className="h-4 w-4" /> Ask about this product <ChevronRight className="h-4 w-4" /></button></article>)}</div></div>}
      <EstimateDialog open={estimateOpen} onOpenChange={setEstimateOpen} context="Regarding: help with a paint project" />
    </div>
  );
};

export default Expert;
