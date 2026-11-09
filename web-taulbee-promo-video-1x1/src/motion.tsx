import "@fontsource-variable/fraunces";
import "@fontsource-variable/fraunces/wght-italic.css";
import "@fontsource-variable/plus-jakarta-sans";
import { MotionPlayer, type SceneContent, type SceneRenderProps } from "./motion-player";
import { easeInOut, easeOut, spring } from "motion";
import { motion, useTransform, type MotionStyle, type MotionValue } from "motion/react";
import type { CSSProperties, ReactNode } from "react";

/* ------------------------------------------------------------------------------------------------
 * Format. Each version of the film is its own app; only FORMAT differs between the copies, and each
 * scene composes its own layout for it (formats.md). Every size below is design pixels in that
 * format, converted to container units by px() so export at any scale stays identical.
 * ---------------------------------------------------------------------------------------------- */
type Format = "landscape" | "portrait" | "square";
const FORMAT = "square" as Format;
const SIZES: Record<Format, [number, number]> = { landscape: [1920, 1080], portrait: [1080, 1920], square: [1080, 1080] };
const [W, H] = SIZES[FORMAT];
const pick = <T,>(landscape: T, portrait: T, square: T): T =>
  FORMAT === "landscape" ? landscape : FORMAT === "portrait" ? portrait : square;
const px = (n: number) => `${(n / W) * 100}cqw`;
const CLIP = pick("16x9", "9x16", "16x9");

/* ------------------------------------------------------------------------------------------------
 * Brand
 * ---------------------------------------------------------------------------------------------- */
const C = {
  night: "#1A0A2E",
  plum: "#2E1250",
  royal: "#63328D",
  bright: "#8B4AC4",
  lilac: "#D9BEF3",
  cream: "#FBF7F1",
  ink: "#1E1428",
  muted: "#6F6579",
};
const SERIF = "'Fraunces Variable', Georgia, serif";
const SANS = "'Plus Jakarta Sans Variable', 'Helvetica Neue', Arial, sans-serif";

type Paint = { key: string; name: string; code: string; hex: string; img: string; ink: string; at: number };
// `at` is the colors scene's local second when this paint lands on the wall, timed to the narration.
const PAINTS: Paint[] = [
  { key: "gray", name: "Agreeable Gray", code: "SW 7029", hex: "#D1CBC1", img: "/room-gray-v1.jpg", ink: C.ink, at: 2.8 },
  { key: "seasalt", name: "Sea Salt", code: "SW 6204", hex: "#CDD2CA", img: "/room-seasalt-v1.jpg", ink: C.ink, at: 4.5 },
  { key: "naval", name: "Naval", code: "SW 6244", hex: "#2F3D4C", img: "/room-naval-v1.jpg", ink: "#FFFFFF", at: 6.2 },
];
const BEFORE_HEX = "#D8C6A6";

/* ------------------------------------------------------------------------------------------------
 * Script
 * ---------------------------------------------------------------------------------------------- */
type FilmScene = SceneContent &
  (
    | { id: "hook"; headline: string; accent: string; tag: string }
    | { id: "meet"; name: string; tagline: string; badge: string }
    | { id: "colors"; steps: string[]; headline: string; subline: string; brands: string[]; fineprint: string }
    | { id: "expert"; lineA: string; lineB: string; tags: string[]; question: string; answer: string }
    | { id: "estimate"; kicker: string; headline: string; cardTitle: string; cardDetail: string; cardNote: string; tag: string }
    | { id: "close"; name: string; cta: string; url: string; tag: string }
  );

const content: FilmScene[] = [
  {
    id: "hook",
    voiceover: "/rork-vo-hook-v1.mp3",
    video: { src: `/clip-hook-${CLIP}-v1.mp4` },
    headline: "Tired of guessing",
    accent: "the right color?",
    tag: "Dramatization",
  },
  {
    id: "meet",
    voiceover: "/rork-vo-meet-v1.mp3",
    minSeconds: 3.4,
    name: "Taulbee Painting",
    tagline: "The painting app for homeowners",
    badge: "Free on iPhone",
  },
  {
    id: "colors",
    voiceover: "/rork-vo-colors-v1.mp3",
    effects: [{ src: "/rork-sfx-tap-v1.mp3", at: 1.85, volume: 0.5 }],
    steps: ["Snap a photo", "Tap your wall", "Try any color"],
    headline: "7,700+ real colors",
    subline: "Matched to the paint you can buy",
    brands: ["Sherwin-Williams", "Benjamin Moore", "PPG"],
    fineprint: "Trademarks belong to their owners.",
  },
  {
    id: "expert",
    voiceover: "/rork-vo-expert-v1.mp3",
    lineA: "Spot problems.",
    lineB: "Ask a pro.",
    tags: ["Peeling", "Water damage", "Mildew"],
    question: "Why is my ceiling paint peeling?",
    answer: "Likely moisture. Fix the leak, scrape, then use a stain-blocking primer before two topcoats.",
  },
  {
    id: "estimate",
    voiceover: "/rork-vo-estimate-v1.mp3",
    video: { src: `/clip-painter-${CLIP}-v1.mp4` },
    effects: [
      { src: "/rork-sfx-roller-v1.mp3", at: 0.1, volume: 0.45 },
      { src: "/rork-sfx-chime-v1.mp3", at: 3.4, volume: 0.3 },
    ],
    kicker: "Love the look?",
    headline: "Get a free estimate.",
    cardTitle: "Estimate request sent",
    cardDetail: "Living room · Naval SW 6244",
    cardNote: "Taulbee Painting will be in touch soon.",
    tag: "Dramatization",
  },
  {
    id: "close",
    voiceover: "/rork-vo-close-v1.mp3",
    video: { src: `/clip-family-${CLIP}-v1.mp4` },
    name: "Taulbee Painting",
    cta: "Download free on the App Store",
    url: "taulbeepainting-app.rork.app",
    tag: "Dramatization",
  },
];
const musicBed = "/rork-music-v1.mp3";
const TRANSITION_SECONDS = 0.5;

export default function MotionPresentation() {
  // width and height match data-width and data-height on index.html's composition root.
  return (
    <MotionPlayer
      content={content}
      musicBed={musicBed}
      width={W}
      height={H}
      surfaceClassName="bg-[#1A0A2E]"
      Scene={FilmSceneView}
      transitionSeconds={TRANSITION_SECONDS}
    />
  );
}

type SceneProps<Id extends FilmScene["id"]> = SceneRenderProps<Extract<FilmScene, { id: Id }>>;

function FilmSceneView(props: SceneRenderProps<FilmScene>) {
  const { scene } = props;
  switch (scene.id) {
    case "hook":
      return <HookScene {...props} scene={scene} />;
    case "meet":
      return <MeetScene {...props} scene={scene} />;
    case "colors":
      return <ColorsScene {...props} scene={scene} />;
    case "expert":
      return <ExpertScene {...props} scene={scene} />;
    case "estimate":
      return <EstimateScene {...props} scene={scene} />;
    case "close":
      return <CloseScene {...props} scene={scene} />;
  }
}

/* ------------------------------------------------------------------------------------------------
 * Clock helpers: everything is a pure function of the shared clock.
 * ---------------------------------------------------------------------------------------------- */
const pop = spring({ keyframes: [0, 1], visualDuration: 0.55, bounce: 0.35 });
const soft = spring({ keyframes: [0, 1], visualDuration: 0.7, bounce: 0.12 });
const sample = (gen: typeof pop, t: number) => (t <= 0 ? 0 : gen.next(t * 1000).value);
const clamp01 = (v: number) => Math.max(0, Math.min(1, v));

function useLocal(scene: { start: number }, clock: MotionValue<number>) {
  return useTransform(clock, (t) => t - scene.start);
}

function useCrossFade(scene: { start: number; end: number }, clock: MotionValue<number>) {
  return useTransform(clock, (t) => {
    const fadeIn = scene.start === 0 ? 1 : (t - scene.start) / TRANSITION_SECONDS;
    const fadeOut = (scene.end + TRANSITION_SECONDS - t) / TRANSITION_SECONDS;
    return clamp01(Math.min(fadeIn, fadeOut));
  });
}

/** Opacity and lift for an element entering at `at` seconds of scene-local time. */
function useRise(local: MotionValue<number>, at: number, reducedMotion: boolean, distance = 40) {
  const opacity = useTransform(local, [at, at + 0.45], [0, 1], { ease: easeOut });
  const y = useTransform(local, (t) => (reducedMotion ? 0 : (1 - sample(soft, t - at)) * distance));
  return { opacity, y };
}

/** Scale from a bouncy spring entering at `at`. */
function usePop(local: MotionValue<number>, at: number, reducedMotion: boolean, from = 0.6) {
  return useTransform(local, (t) => (reducedMotion ? (t >= at ? 1 : from) : from + (1 - from) * sample(pop, t - at)));
}

const abs: CSSProperties = { position: "absolute" };

/* ------------------------------------------------------------------------------------------------
 * Shared pieces
 * ---------------------------------------------------------------------------------------------- */
const SCREEN_RATIO = 0.462; // iPhone screen width / height

function Phone({ width, style, children }: { width: number; style?: MotionStyle; children: ReactNode }) {
  const bezel = width * 0.034;
  return (
    <motion.div
      style={{
        ...abs,
        width: px(width + bezel * 2),
        height: px(width / SCREEN_RATIO + bezel * 2),
        padding: px(bezel),
        borderRadius: px(width * 0.17),
        background: "linear-gradient(145deg, #2A2431, #0B0810 60%)",
        boxShadow: `0 ${px(width * 0.1)} ${px(width * 0.28)} rgba(26,10,46,0.42), 0 ${px(6)} ${px(18)} rgba(26,10,46,0.25), inset 0 0 0 ${px(2.5)} #4A4352`,
        ...style,
      }}
    >
      <div
        style={{
          position: "relative",
          width: "100%",
          height: "100%",
          overflow: "hidden",
          borderRadius: px(width * 0.14),
          background: "#F6F3F9",
        }}
      >
        {children}
      </div>
    </motion.div>
  );
}

function ScreenShot({ src }: { src: string }) {
  return (
    <img
      src={src}
      alt=""
      style={{ ...abs, inset: 0, width: "100%", height: "100%", objectFit: "cover", objectPosition: "top center" }}
    />
  );
}

function DramaTag({ text }: { text: string }) {
  const pos = pick<CSSProperties>(
    { right: px(48), bottom: px(36) },
    { left: px(60), top: px(300) },
    { right: px(36), bottom: px(28) },
  );
  return (
    <div
      style={{
        ...abs,
        ...pos,
        fontFamily: SANS,
        fontSize: px(pick(17, 22, 16)),
        letterSpacing: "0.08em",
        textTransform: "uppercase",
        color: "rgba(255,255,255,0.7)",
        textShadow: "0 1px 6px rgba(0,0,0,0.45)",
      }}
    >
      {text}
    </div>
  );
}

/** A full-bleed scene video, cropped through its wrapper only. */
function FullBleedVideo({ video, scale, origin = "center" }: { video: ReactNode; scale: MotionValue<number>; origin?: string }) {
  return (
    <div style={{ ...abs, inset: 0, overflow: "hidden" }}>
      <motion.div style={{ ...abs, inset: 0, scale, transformOrigin: origin }}>{video}</motion.div>
    </div>
  );
}

/* ------------------------------------------------------------------------------------------------
 * 1. Hook: a dated beige room, and the question every homeowner asks.
 * ---------------------------------------------------------------------------------------------- */
function HookScene({ scene, clock, video, reducedMotion }: SceneProps<"hook">) {
  const local = useLocal(scene, clock);
  const opacity = useCrossFade(scene, clock);
  const zoom = useTransform(local, [0, 5], reducedMotion ? [1.02, 1.02] : [1.02, 1.1]);
  const words = scene.headline.split(" ");
  const lay = pick(
    { left: 130, top: 640, size: 112, width: 1100 },
    { left: 80, top: 1080, size: 108, width: 860 },
    { left: 72, top: 650, size: 92, width: 900 },
  );
  return (
    <motion.section style={{ ...abs, inset: 0, opacity }}>
      {video && <FullBleedVideo video={video} scale={zoom} />}
      <div
        style={{
          ...abs,
          inset: 0,
          background: pick(
            "linear-gradient(180deg, rgba(26,10,46,0) 35%, rgba(26,10,46,0.78) 100%), linear-gradient(90deg, rgba(26,10,46,0.45), rgba(26,10,46,0) 60%)",
            "linear-gradient(180deg, rgba(26,10,46,0.05) 30%, rgba(26,10,46,0.8) 85%)",
            "linear-gradient(180deg, rgba(26,10,46,0) 30%, rgba(26,10,46,0.82) 100%)",
          ),
        }}
      />
      <GuessChips local={local} reducedMotion={reducedMotion} />
      <div style={{ ...abs, left: px(lay.left), top: px(lay.top), width: px(lay.width), fontFamily: SERIF, color: "#fff" }}>
        <div style={{ fontSize: px(lay.size), lineHeight: 1.02, fontWeight: 560, letterSpacing: "-0.02em" }}>
          {words.map((word, i) => (
            <HookWord key={`${i}:${word}`} word={word} at={0.35 + i * 0.22} local={local} reducedMotion={reducedMotion} />
          ))}
        </div>
        <HookAccent text={scene.accent} local={local} reducedMotion={reducedMotion} size={lay.size} />
      </div>
      <DramaTag text={scene.tag} />
    </motion.section>
  );
}

function HookWord({ word, at, local, reducedMotion }: { word: string; at: number; local: MotionValue<number>; reducedMotion: boolean }) {
  const { opacity, y } = useRise(local, at, reducedMotion, 50);
  return (
    <motion.span style={{ display: "inline-block", marginRight: "0.24em", opacity, y }}>
      {word}
    </motion.span>
  );
}

function HookAccent({ text, local, reducedMotion, size }: { text: string; local: MotionValue<number>; reducedMotion: boolean; size: number }) {
  const { opacity, y } = useRise(local, 1.45, reducedMotion, 50);
  const underline = useTransform(local, [1.9, 2.6], [0, 1], { ease: easeInOut });
  return (
    <motion.div style={{ position: "relative", display: "inline-block", opacity, y, fontStyle: "italic", color: C.lilac, fontSize: px(size), lineHeight: 1.1, fontWeight: 480 }}>
      {text}
      <motion.div
        style={{
          ...abs,
          left: 0,
          right: 0,
          bottom: px(-6),
          height: px(10),
          borderRadius: px(6),
          background: C.bright,
          scaleX: underline,
          transformOrigin: "left center",
        }}
      />
    </motion.div>
  );
}

function GuessChips({ local, reducedMotion }: { local: MotionValue<number>; reducedMotion: boolean }) {
  const spots = pick(
    [
      { x: 1290, y: 170, r: -9 },
      { x: 1500, y: 250, r: 5 },
      { x: 1700, y: 160, r: 13 },
    ],
    [
      { x: 110, y: 470, r: -9 },
      { x: 380, y: 540, r: 4 },
      { x: 650, y: 460, r: 12 },
    ],
    [
      { x: 560, y: 90, r: -9 },
      { x: 730, y: 150, r: 5 },
      { x: 890, y: 80, r: 12 },
    ],
  );
  const size = pick(190, 230, 150);
  return (
    <>
      {PAINTS.map((paint, i) => (
        <GuessChip key={paint.key} paint={paint} spot={spots[i]} size={size} at={1.7 + i * 0.22} local={local} reducedMotion={reducedMotion} />
      ))}
    </>
  );
}

function GuessChip({
  paint,
  spot,
  size,
  at,
  local,
  reducedMotion,
}: {
  paint: Paint;
  spot: { x: number; y: number; r: number };
  size: number;
  at: number;
  local: MotionValue<number>;
  reducedMotion: boolean;
}) {
  const scale = usePop(local, at, reducedMotion, 0);
  const rotate = useTransform(local, (t) => spot.r + (reducedMotion ? 0 : Math.sin((t - at) * 2.2 + spot.r) * 3));
  const y = useTransform(local, (t) => (reducedMotion ? 0 : Math.sin((t - at) * 1.6 + spot.x) * 8));
  return (
    <motion.div
      style={{
        ...abs,
        left: px(spot.x),
        top: px(spot.y),
        width: px(size),
        height: px(size * 1.28),
        padding: px(size * 0.06),
        borderRadius: px(size * 0.08),
        background: "#fff",
        boxShadow: `0 ${px(18)} ${px(40)} rgba(26,10,46,0.35)`,
        scale,
        rotate,
        y,
      }}
    >
      <div
        style={{
          width: "100%",
          height: "72%",
          borderRadius: px(size * 0.04),
          background: paint.hex,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontFamily: SERIF,
          fontSize: px(size * 0.42),
          color: paint.ink === "#FFFFFF" ? "rgba(255,255,255,0.85)" : "rgba(30,20,40,0.55)",
          fontWeight: 600,
        }}
      >
        ?
      </div>
      <div style={{ marginTop: px(size * 0.05), fontFamily: SANS, fontWeight: 700, fontSize: px(size * 0.085), color: C.ink, whiteSpace: "nowrap" }}>
        {paint.name}
      </div>
      <div style={{ fontFamily: SANS, fontSize: px(size * 0.07), color: C.muted }}>{paint.code}</div>
    </motion.div>
  );
}

/* ------------------------------------------------------------------------------------------------
 * 2. Meet the app: a cream-then-purple brush wipe lands the icon, name and home screen.
 * ---------------------------------------------------------------------------------------------- */
function MeetScene({ scene, clock, reducedMotion }: SceneProps<"meet">) {
  const local = useLocal(scene, clock);
  const fadeOut = useTransform(clock, (t) => clamp01((scene.end + TRANSITION_SECONDS - t) / TRANSITION_SECONDS));
  const wipe = (delay: number) =>
    (t: number) => {
      if (reducedMotion) return "none";
      const p = easeInOut(clamp01((t - delay) / 0.55));
      const edge = p * 140;
      return `polygon(0% 0%, ${edge}% 0%, ${edge - 40}% 100%, 0% 100%)`;
    };
  const creamClip = useTransform(local, wipe(0));
  const purpleClip = useTransform(local, wipe(0.1));

  const lay = pick(
    { iconX: 150, iconY: 250, icon: 210, textX: 150, titleY: 500, title: 128, tagY: 660, tag: 40, badgeY: 740, phoneX: 1180, phoneY: 120, phone: 400 },
    { iconX: 80, iconY: 300, icon: 190, textX: 80, titleY: 520, title: 112, tagY: 660, tag: 38, badgeY: 730, phoneX: 380, phoneY: 840, phone: 470 },
    { iconX: 72, iconY: 170, icon: 160, textX: 72, titleY: 360, title: 76, tagY: 470, tag: 30, badgeY: 535, phoneX: 690, phoneY: 300, phone: 330 },
  );
  const iconScale = usePop(local, 0.45, reducedMotion, 0.3);
  const iconRotate = useTransform(local, (t) => (reducedMotion ? 0 : (1 - sample(pop, t - 0.45)) * -18));
  const title = useRise(local, 0.75, reducedMotion, 36);
  const tag = useRise(local, 1.0, reducedMotion, 28);
  const badge = useRise(local, 1.25, reducedMotion, 20);
  const phoneY = useTransform(local, (t) => (reducedMotion ? 0 : (1 - sample(soft, t - 0.6)) * 420));
  const phoneRotate = useTransform(local, (t) => (reducedMotion ? -4 : 10 - 14 * sample(soft, t - 0.6)));
  const phoneDrift = useTransform(local, (t) => (reducedMotion ? 0 : -Math.max(0, t - 1.2) * 10));
  const glow = useTransform(local, [0.3, 1.4], [0, 1]);

  return (
    <motion.section style={{ ...abs, inset: 0, opacity: fadeOut }}>
      <motion.div style={{ ...abs, inset: 0, background: C.cream, clipPath: creamClip }} />
      <motion.div
        style={{
          ...abs,
          inset: 0,
          clipPath: purpleClip,
          background: `radial-gradient(circle at ${pick("72% 45%", "50% 70%", "75% 60%")}, ${C.bright} 0%, #4B1D78 38%, ${C.night} 100%)`,
          overflow: "hidden",
        }}
      >
        <motion.div
          style={{
            ...abs,
            left: px(pick(1080, 140, 520)),
            top: px(pick(-80, 640, 120)),
            width: px(pick(820, 820, 640)),
            height: px(pick(820, 820, 640)),
            borderRadius: "50%",
            border: `${px(2)} solid rgba(217,190,243,0.18)`,
            boxShadow: `0 0 0 ${px(90)} rgba(217,190,243,0.05), 0 0 0 ${px(200)} rgba(217,190,243,0.03)`,
            opacity: glow,
          }}
        />
        <Phone
          width={lay.phone}
          style={{ left: px(lay.phoneX), top: px(lay.phoneY), y: phoneY, rotate: phoneRotate, translateY: phoneDrift }}
        >
          <ScreenShot src="/screen-home-v2.png" />
        </Phone>
        <motion.img
          src="/taulbee-icon-v1.png"
          alt=""
          style={{
            ...abs,
            left: px(lay.iconX),
            top: px(lay.iconY),
            width: px(lay.icon),
            height: px(lay.icon),
            borderRadius: px(lay.icon * 0.225),
            boxShadow: `0 ${px(20)} ${px(50)} rgba(10,2,20,0.5), inset 0 0 0 ${px(1)} rgba(255,255,255,0.2)`,
            scale: iconScale,
            rotate: iconRotate,
          }}
        />
        <motion.div
          style={{
            ...abs,
            left: px(lay.textX),
            top: px(lay.titleY),
            fontFamily: SERIF,
            fontWeight: 600,
            fontSize: px(lay.title),
            lineHeight: 1,
            letterSpacing: "-0.025em",
            color: "#fff",
            whiteSpace: "nowrap",
            ...title,
          }}
        >
          {scene.name}
        </motion.div>
        <motion.div
          style={{ ...abs, left: px(lay.textX), top: px(lay.tagY), fontFamily: SANS, fontWeight: 500, fontSize: px(lay.tag), color: C.lilac, ...tag }}
        >
          {scene.tagline}
        </motion.div>
        <motion.div
          style={{
            ...abs,
            left: px(lay.textX),
            top: px(lay.badgeY),
            padding: `${px(12)} ${px(26)}`,
            borderRadius: px(999),
            background: "rgba(251,247,241,0.12)",
            border: `${px(1.5)} solid rgba(251,247,241,0.3)`,
            fontFamily: SANS,
            fontWeight: 700,
            fontSize: px(lay.tag * 0.7),
            letterSpacing: "0.06em",
            textTransform: "uppercase",
            color: C.cream,
            ...badge,
          }}
        >
          {scene.badge}
        </motion.div>
      </motion.div>
    </motion.section>
  );
}

/* ------------------------------------------------------------------------------------------------
 * 3. Try colors: snap, tap the wall, and watch real paint colors fill the room and the frame.
 * ---------------------------------------------------------------------------------------------- */
const TAP_AT = 1.9;
const SNAP_AT = 0.55;
// Where the finger lands inside the visualizer photo, in percent of the photo card.
const TAP_POINT = { x: 58, y: 26 };

function ColorsScene({ scene, clock, reducedMotion }: SceneProps<"colors">) {
  const local = useLocal(scene, clock);
  const opacity = useCrossFade(scene, clock);
  const lay = pick(
    {
      textX: 120, stepsY: 150, headY: 330, head: 84, subY: 540, brandsY: 660, brand: 40,
      phoneX: 640, phoneY: 110, phone: 390,
      panel: { left: 1120, top: 0, width: 800, height: 1080 },
      nameX: 1190, nameY: 840, name: 84,
    },
    {
      textX: 80, stepsY: 300, headY: 390, head: 92, subY: 500, brandsY: -1, brand: 34,
      phoneX: 300, phoneY: 600, phone: 440,
      panel: { left: 0, top: 0, width: 1080, height: 1920 },
      nameX: 80, nameY: 1600, name: 0,
    },
    {
      textX: 470, stepsY: 100, headY: 250, head: 66, subY: 330, brandsY: 395, brand: 28,
      phoneX: 70, phoneY: 120, phone: 360,
      panel: { left: 450, top: 620, width: 630, height: 460 },
      nameX: 500, nameY: 900, name: 72,
    },
  );
  const headline = useRise(local, 2.4, reducedMotion, 30);
  const sub = useRise(local, 2.7, reducedMotion, 20);
  const phoneIn = useRise(local, 0, reducedMotion, 120);
  const fine = useTransform(local, [3.6, 4.2], [0, 0.7]);
  // In portrait the paint fills the whole frame, so the type turns light as the dark Naval rolls on.
  const darkAt = PAINTS[2].at + 0.25;
  const headInk = useTransform(local, [darkAt, darkAt + 0.35], FORMAT === "portrait" ? [C.ink, "#FBF7F1"] : [C.ink, C.ink]);
  const subInk = useTransform(local, [darkAt, darkAt + 0.35], FORMAT === "portrait" ? [C.muted, "rgba(251,247,241,0.75)"] : [C.muted, C.muted]);
  return (
    <motion.section style={{ ...abs, inset: 0, opacity, background: C.cream, overflow: "hidden" }}>
      <PaintPanel local={local} rect={lay.panel} reducedMotion={reducedMotion} nameX={lay.nameX} nameY={lay.nameY} nameSize={lay.name} />
      <div style={{ ...abs, left: px(lay.textX), top: px(lay.stepsY), display: "flex", gap: px(14), flexWrap: "wrap", maxWidth: px(pick(480, 920, 580)) }}>
        {scene.steps.map((step, i) => (
          <StepChip key={step} index={i} label={step} at={[0.3, 1.45, 2.45][i]} local={local} reducedMotion={reducedMotion} />
        ))}
      </div>
      <motion.div
        style={{
          ...abs,
          left: px(lay.textX),
          top: px(lay.headY),
          width: px(pick(500, 920, 600)),
          fontFamily: SERIF,
          fontWeight: 600,
          fontSize: px(lay.head),
          lineHeight: 1,
          letterSpacing: "-0.025em",
          color: headInk,
          ...headline,
        }}
      >
        {scene.headline}
      </motion.div>
      <motion.div
        style={{ ...abs, left: px(lay.textX), top: px(lay.subY), fontFamily: SANS, fontWeight: 500, fontSize: px(pick(28, 34, 24)), color: subInk, ...sub }}
      >
        {scene.subline}
      </motion.div>
      {lay.brandsY >= 0 && (
        <div style={{ ...abs, left: px(lay.textX), top: px(lay.brandsY) }}>
          {scene.brands.map((brand, i) => (
            <BrandLine key={brand} label={brand} at={[3.9, 4.9, 5.85][i]} local={local} size={lay.brand} reducedMotion={reducedMotion} />
          ))}
          <motion.div style={{ marginTop: px(18), fontFamily: SANS, fontSize: px(16), color: C.muted, opacity: fine }}>{scene.fineprint}</motion.div>
        </div>
      )}
      <Phone width={lay.phone} style={{ left: px(lay.phoneX), top: px(lay.phoneY), opacity: phoneIn.opacity, y: phoneIn.y }}>
        <VisualizerScreen local={local} width={lay.phone} reducedMotion={reducedMotion} />
      </Phone>
    </motion.section>
  );
}

function StepChip({ index, label, at, local, reducedMotion }: { index: number; label: string; at: number; local: MotionValue<number>; reducedMotion: boolean }) {
  const scale = usePop(local, at, reducedMotion, 0.5);
  const opacity = useTransform(local, [at, at + 0.2], [0, 1]);
  return (
    <motion.div
      style={{
        display: "flex",
        alignItems: "center",
        gap: px(10),
        padding: `${px(10)} ${px(20)} ${px(10)} ${px(10)}`,
        borderRadius: px(999),
        background: "#fff",
        boxShadow: `0 ${px(6)} ${px(20)} rgba(46,18,80,0.12)`,
        fontFamily: SANS,
        fontWeight: 700,
        fontSize: px(pick(22, 28, 19)),
        color: C.ink,
        scale,
        opacity,
        transformOrigin: "left center",
      }}
    >
      <span
        style={{
          width: px(pick(34, 42, 30)),
          height: px(pick(34, 42, 30)),
          borderRadius: "50%",
          background: C.royal,
          color: "#fff",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: px(pick(18, 22, 16)),
        }}
      >
        {index + 1}
      </span>
      {label}
    </motion.div>
  );
}

function BrandLine({ label, at, local, size, reducedMotion }: { label: string; at: number; local: MotionValue<number>; size: number; reducedMotion: boolean }) {
  const opacity = useTransform(local, [at - 0.2, at + 0.2], [0, 1]);
  const x = useTransform(local, (t) => (reducedMotion ? 0 : (1 - sample(soft, t - at + 0.2)) * -30));
  return (
    <motion.div
      style={{
        display: "flex",
        alignItems: "center",
        gap: px(16),
        marginBottom: px(14),
        fontFamily: SANS,
        fontWeight: 700,
        fontSize: px(size),
        color: C.ink,
        letterSpacing: "-0.01em",
        opacity,
        x,
      }}
    >
      <span style={{ width: px(size * 0.32), height: px(size * 0.32), borderRadius: "50%", background: C.bright }} />
      {label}
    </motion.div>
  );
}

/** The big color field that fills as each paint is named. */
function PaintPanel({
  local,
  rect,
  reducedMotion,
  nameX,
  nameY,
  nameSize,
}: {
  local: MotionValue<number>;
  rect: { left: number; top: number; width: number; height: number };
  reducedMotion: boolean;
  nameX: number;
  nameY: number;
  nameSize: number;
}) {
  const panelIn = useTransform(local, (t) => (reducedMotion ? 1 : sample(soft, t - 0.15)));
  const panelClip = useTransform(panelIn, (p) => `inset(${(1 - p) * 100}% 0% 0% 0%)`);
  return (
    <motion.div
      style={{
        ...abs,
        left: px(rect.left),
        top: px(rect.top),
        width: px(rect.width),
        height: px(rect.height),
        overflow: "hidden",
        background: BEFORE_HEX,
        clipPath: panelClip,
        borderRadius: FORMAT === "square" ? `${px(36)} 0 0 0` : 0,
      }}
    >
      {PAINTS.map((paint) => (
        <PaintFill key={paint.key} paint={paint} local={local} reducedMotion={reducedMotion} rect={rect} nameX={nameX} nameY={nameY} nameSize={nameSize} />
      ))}
    </motion.div>
  );
}

function PaintFill({
  paint,
  local,
  reducedMotion,
  rect,
  nameX,
  nameY,
  nameSize,
}: {
  paint: Paint;
  local: MotionValue<number>;
  reducedMotion: boolean;
  rect: { left: number; top: number; width: number; height: number };
  nameX: number;
  nameY: number;
  nameSize: number;
}) {
  const progress = useTransform(local, (t) => (reducedMotion ? (t >= paint.at ? 1 : 0) : easeInOut(clamp01((t - paint.at) / 0.7))));
  const clipPath = useTransform(progress, (p) => {
    // A roller-like wipe from the bottom with a slight slant.
    const top = 100 - p * 112;
    return `polygon(0% ${top + 8}%, 100% ${top}%, 100% 100%, 0% 100%)`;
  });
  const label = useRise(local, paint.at + 0.25, reducedMotion, 30);
  const showName = nameSize > 0;
  return (
    <motion.div style={{ ...abs, inset: 0, background: paint.hex, clipPath }}>
      {showName && (
        <motion.div style={{ ...abs, left: px(nameX - rect.left), top: px(nameY - rect.top), color: paint.ink, ...label }}>
          <div style={{ fontFamily: SANS, fontWeight: 700, fontSize: px(nameSize * 0.24), letterSpacing: "0.14em", textTransform: "uppercase", opacity: 0.7 }}>
            Sherwin-Williams · {paint.code}
          </div>
          <div style={{ fontFamily: SERIF, fontWeight: 560, fontSize: px(nameSize), lineHeight: 1.05, letterSpacing: "-0.02em", whiteSpace: "nowrap" }}>
            {paint.name}
          </div>
        </motion.div>
      )}
    </motion.div>
  );
}

/** A code-drawn Color Visualizer screen: the photo, the tap, the glow, then each paint. */
function VisualizerScreen({ local, width, reducedMotion }: { local: MotionValue<number>; width: number; reducedMotion: boolean }) {
  const u = (n: number) => px((n / 390) * width); // design in a 390-point-wide iPhone screen
  const viewfinder = useTransform(local, [SNAP_AT - 0.05, SNAP_AT + 0.1], [1, 0]);
  const flash = useTransform(local, [SNAP_AT, SNAP_AT + 0.08, SNAP_AT + 0.5], [0, 0.95, 0]);
  const photoScale = useTransform(local, (t) => (reducedMotion ? 1 : t < SNAP_AT ? 1.12 : 1 + 0.12 * (1 - sample(soft, t - SNAP_AT))));
  const glow = useTransform(local, (t) => {
    if (t < TAP_AT + 0.05 || t > PAINTS[0].at + 0.4) return 0;
    const k = t - TAP_AT - 0.05;
    return clamp01(k / 0.2) * (0.42 + 0.18 * Math.sin(k * 9)) * clamp01((PAINTS[0].at + 0.4 - t) / 0.3);
  });
  const finger = useTransform(local, [TAP_AT - 0.35, TAP_AT - 0.1, TAP_AT + 0.35, TAP_AT + 0.6], [0, 1, 1, 0]);
  const fingerScale = useTransform(local, [TAP_AT - 0.35, TAP_AT, TAP_AT + 0.12], [1.5, 0.85, 1]);
  const ripple = useTransform(local, [TAP_AT, TAP_AT + 0.7], [0, 1]);
  const rippleOpacity = useTransform(ripple, [0, 0.1, 1], [0, 0.9, 0]);
  const rippleScale = useTransform(ripple, [0, 1], [0.3, 3.2]);
  const hint = useTransform(local, [1.1, 1.4, TAP_AT, TAP_AT + 0.3], [0, 1, 1, 0]);

  return (
    <div style={{ ...abs, inset: 0, fontFamily: SANS, color: C.ink, background: "#F6F3F9" }}>
      {/* status bar */}
      <div style={{ ...abs, left: u(34), top: u(16), fontWeight: 700, fontSize: u(16) }}>9:41</div>
      <div style={{ ...abs, left: "50%", top: u(11), width: u(118), height: u(34), marginLeft: u(-59), borderRadius: u(20), background: "#000" }} />
      <div style={{ ...abs, right: u(30), top: u(20), width: u(25), height: u(12), borderRadius: u(4), border: `${u(1.5)} solid ${C.ink}` }}>
        <div style={{ margin: u(1.5), height: `calc(100% - ${u(3)})`, width: "75%", borderRadius: u(2), background: C.ink }} />
      </div>
      {/* header */}
      <div style={{ ...abs, left: u(20), top: u(62), fontSize: u(30), fontWeight: 800, letterSpacing: "-0.02em" }}>Visualize</div>
      <div style={{ ...abs, left: u(20), top: u(102), fontSize: u(14), color: C.muted }}>Tap a wall to paint it</div>
      {/* photo card */}
      <div style={{ ...abs, left: u(16), right: u(16), top: u(134), height: u(420), borderRadius: u(22), overflow: "hidden", background: "#1b1420" }}>
        <motion.div style={{ ...abs, inset: 0, scale: photoScale }}>
          <RoomImage src="/room-beige-v1.jpg" />
          {PAINTS.map((paint) => (
            <PaintReveal key={paint.key} paint={paint} local={local} reducedMotion={reducedMotion} />
          ))}
          <motion.div
            style={{
              ...abs,
              inset: 0,
              background: `linear-gradient(135deg, ${C.bright}, #C08CF0)`,
              WebkitMaskImage: "url(/room-wall-mask-v1.png)",
              maskImage: "url(/room-wall-mask-v1.png)",
              WebkitMaskSize: "cover",
              maskSize: "cover",
              WebkitMaskPosition: "center",
              maskPosition: "center",
              opacity: glow,
              mixBlendMode: "screen",
            }}
          />
        </motion.div>
        {/* viewfinder brackets before the snap */}
        <motion.div style={{ ...abs, inset: u(18), opacity: viewfinder }}>
          {["tl", "tr", "bl", "br"].map((corner) => (
            <div
              key={corner}
              style={{
                ...abs,
                width: u(34),
                height: u(34),
                borderColor: "#fff",
                borderStyle: "solid",
                borderWidth: 0,
                ...(corner[0] === "t" ? { top: 0, borderTopWidth: u(3) } : { bottom: 0, borderBottomWidth: u(3) }),
                ...(corner[1] === "l" ? { left: 0, borderLeftWidth: u(3) } : { right: 0, borderRightWidth: u(3) }),
              }}
            />
          ))}
        </motion.div>
        <motion.div style={{ ...abs, inset: 0, background: "#fff", opacity: flash }} />
        {/* tap hint, finger and ripple */}
        <motion.div
          style={{
            ...abs,
            left: "50%",
            top: u(14),
            transform: "translateX(-50%)",
            padding: `${u(6)} ${u(12)}`,
            borderRadius: u(999),
            background: "rgba(26,10,46,0.72)",
            color: "#fff",
            fontSize: u(12),
            fontWeight: 700,
            whiteSpace: "nowrap",
            opacity: hint,
          }}
        >
          Tap the surface to paint
        </motion.div>
        <motion.div
          style={{
            ...abs,
            left: `${TAP_POINT.x}%`,
            top: `${TAP_POINT.y}%`,
            width: u(40),
            height: u(40),
            marginLeft: u(-20),
            marginTop: u(-20),
            borderRadius: "50%",
            border: `${u(2.5)} solid #fff`,
            opacity: rippleOpacity,
            scale: rippleScale,
          }}
        />
        <motion.div
          style={{
            ...abs,
            left: `${TAP_POINT.x}%`,
            top: `${TAP_POINT.y}%`,
            width: u(46),
            height: u(46),
            marginLeft: u(-23),
            marginTop: u(-23),
            borderRadius: "50%",
            background: "rgba(255,255,255,0.55)",
            boxShadow: `0 0 0 ${u(2)} rgba(255,255,255,0.9), 0 ${u(4)} ${u(14)} rgba(0,0,0,0.25)`,
            opacity: finger,
            scale: fingerScale,
          }}
        />
      </div>
      {/* swatch row */}
      <div style={{ ...abs, left: u(16), right: u(16), top: u(572), height: u(88), borderRadius: u(20), background: "#fff", boxShadow: `0 ${u(4)} ${u(16)} rgba(46,18,80,0.08)` }}>
        {PAINTS.map((paint, i) => (
          <SwatchDot key={paint.key} paint={paint} index={i} local={local} u={u} />
        ))}
        <div style={{ ...abs, left: u(176), top: u(20), right: u(12), height: u(48) }}>
          {PAINTS.map((paint) => (
            <SwatchLabel key={paint.key} paint={paint} local={local} u={u} />
          ))}
        </div>
      </div>
      {/* estimate button */}
      <div
        style={{
          ...abs,
          left: u(16),
          right: u(16),
          top: u(676),
          height: u(54),
          borderRadius: u(16),
          background: `linear-gradient(135deg, ${C.royal}, #4B1D78)`,
          color: "#fff",
          fontWeight: 700,
          fontSize: u(16),
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        Get a Free Estimate
      </div>
      {/* tab bar */}
      <div style={{ ...abs, left: 0, right: 0, bottom: 0, height: u(84), background: "rgba(255,255,255,0.92)", borderTop: `${u(1)} solid rgba(0,0,0,0.06)`, display: "flex", justifyContent: "space-around", paddingTop: u(14) }}>
        {["Home", "Visualize", "Vault", "Expert", "More"].map((tab) => (
          <div key={tab} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: u(5), fontSize: u(10.5), fontWeight: 600, color: tab === "Visualize" ? C.royal : "#8C8494" }}>
            <div style={{ width: u(22), height: u(22), borderRadius: u(7), background: tab === "Visualize" ? C.royal : "#C9C3CF", opacity: tab === "Visualize" ? 1 : 0.7 }} />
            {tab}
          </div>
        ))}
      </div>
    </div>
  );
}

function RoomImage({ src, style }: { src: string; style?: MotionStyle }) {
  return (
    <motion.img
      src={src}
      alt=""
      style={{ ...abs, inset: 0, width: "100%", height: "100%", objectFit: "cover", objectPosition: "center", ...style }}
    />
  );
}

function PaintReveal({ paint, local, reducedMotion }: { paint: Paint; local: MotionValue<number>; reducedMotion: boolean }) {
  const clipPath = useTransform(local, (t) => {
    const p = reducedMotion ? (t >= paint.at ? 1 : 0) : easeOut(clamp01((t - paint.at) / 0.65));
    return `circle(${p * 160}% at ${TAP_POINT.x}% ${TAP_POINT.y}%)`;
  });
  return <RoomImage src={paint.img} style={{ clipPath }} />;
}

function SwatchDot({ paint, index, local, u }: { paint: Paint; index: number; local: MotionValue<number>; u: (n: number) => string }) {
  const next = PAINTS[index + 1]?.at ?? Infinity;
  const ring = useTransform(local, (t) => (t >= paint.at && t < next ? 1 : 0));
  const scale = useTransform(local, (t) => (t >= paint.at && t < next ? 0.94 + 0.12 * sample(pop, t - paint.at) : 1));
  return (
    <motion.div
      style={{
        ...abs,
        left: u(16 + index * 52),
        top: u(22),
        width: u(44),
        height: u(44),
        borderRadius: "50%",
        background: paint.hex,
        boxShadow: `inset 0 0 0 ${u(1)} rgba(0,0,0,0.12)`,
        scale,
      }}
    >
      <motion.div style={{ ...abs, inset: u(-5), borderRadius: "50%", border: `${u(2.5)} solid ${C.royal}`, opacity: ring }} />
    </motion.div>
  );
}

function SwatchLabel({ paint, local, u }: { paint: Paint; local: MotionValue<number>; u: (n: number) => string }) {
  const index = PAINTS.indexOf(paint);
  const next = PAINTS[index + 1]?.at ?? Infinity;
  const opacity = useTransform(local, (t) => (t < paint.at || t >= next ? 0 : clamp01((t - paint.at) / 0.2)));
  return (
    <motion.div style={{ ...abs, inset: 0, opacity }}>
      <div style={{ fontWeight: 800, fontSize: u(15), whiteSpace: "nowrap" }}>{paint.name}</div>
      <div style={{ fontSize: u(12), color: C.muted, marginTop: u(3) }}>{paint.code}</div>
    </motion.div>
  );
}

/* ------------------------------------------------------------------------------------------------
 * 4. Expert help: the real defect scanner and Paint Expert screens.
 * ---------------------------------------------------------------------------------------------- */
function ExpertScene({ scene, clock, reducedMotion }: SceneProps<"expert">) {
  const local = useLocal(scene, clock);
  const opacity = useCrossFade(scene, clock);
  const lay = pick(
    { textX: 120, aY: 320, bY: 440, size: 96, scanX: 990, scanY: 150, expX: 1440, expY: 110, phone: 360, tagsX: 840, tagsY: 560, bubbleX: 1220, bubbleY: 700, bubbleW: 520 },
    { textX: 80, aY: 290, bY: 400, size: 100, scanX: 90, scanY: 680, expX: 540, expY: 640, phone: 390, tagsX: 80, tagsY: 545, bubbleX: 290, bubbleY: 1250, bubbleW: 600 },
    { textX: 70, aY: 120, bY: 220, size: 84, scanX: 430, scanY: 330, expX: 760, expY: 290, phone: 270, tagsX: 70, tagsY: 400, bubbleX: 120, bubbleY: 780, bubbleW: 560 },
  );
  const a = useRise(local, 0.3, reducedMotion, 40);
  const b = useRise(local, 2.3, reducedMotion, 40);
  const scanY = useTransform(local, (t) => (reducedMotion ? 0 : (1 - sample(soft, t - 0.1)) * 600));
  const scanR = useTransform(local, (t) => (reducedMotion ? -6 : -6 - (1 - sample(soft, t - 0.1)) * 10));
  const expY = useTransform(local, (t) => (reducedMotion ? 0 : (1 - sample(soft, t - 1.9)) * 700));
  const expR = useTransform(local, (t) => (reducedMotion ? 5 : 5 + (1 - sample(soft, t - 1.9)) * 12));
  const bubble = useRise(local, 2.9, reducedMotion, 30);
  const bubbleScale = usePop(local, 2.9, reducedMotion, 0.8);
  const scanLine = useTransform(local, (t) => `${10 + (((t - 0.6) * 55) % 80 + 80) % 80}%`);
  const scanLineOpacity = useTransform(local, [0.6, 0.9, 2.0, 2.3], [0, 1, 1, 0]);
  return (
    <motion.section
      style={{
        ...abs,
        inset: 0,
        opacity,
        overflow: "hidden",
        background: `radial-gradient(circle at ${pick("75% 40%", "50% 55%", "70% 55%")}, #EBDDF8 0%, ${C.cream} 55%)`,
      }}
    >
      <motion.div style={{ ...abs, left: px(lay.textX), top: px(lay.aY), fontFamily: SERIF, fontWeight: 600, fontSize: px(lay.size), letterSpacing: "-0.025em", color: C.ink, whiteSpace: "nowrap", ...a }}>
        {scene.lineA}
      </motion.div>
      <motion.div
        style={{ ...abs, left: px(lay.textX), top: px(lay.bY), fontFamily: SERIF, fontStyle: "italic", fontWeight: 480, fontSize: px(lay.size), letterSpacing: "-0.02em", color: C.royal, whiteSpace: "nowrap", ...b }}
      >
        {scene.lineB}
      </motion.div>
      <Phone width={lay.phone} style={{ left: px(lay.scanX), top: px(lay.scanY), y: scanY, rotate: scanR }}>
        <ScreenShot src="/screen-scanner-v2.png" />
        <motion.div
          style={{
            ...abs,
            left: "6%",
            right: "6%",
            top: scanLine,
            height: px(4),
            borderRadius: px(4),
            background: C.bright,
            boxShadow: `0 0 ${px(18)} ${px(4)} rgba(139,74,196,0.6)`,
            opacity: scanLineOpacity,
          }}
        />
      </Phone>
      <Phone width={lay.phone} style={{ left: px(lay.expX), top: px(lay.expY), y: expY, rotate: expR }}>
        <ScreenShot src="/screen-expert-v2.png" />
      </Phone>
      <div style={{ ...abs, left: px(lay.tagsX), top: px(lay.tagsY), display: "flex", flexDirection: FORMAT === "portrait" ? "row" : "column", gap: px(16), alignItems: "flex-start" }}>
        {scene.tags.map((tag, i) => (
          <ProblemTag key={tag} label={tag} at={0.8 + i * 0.3} local={local} reducedMotion={reducedMotion} />
        ))}
      </div>
      <motion.div
        style={{
          ...abs,
          left: px(lay.bubbleX),
          top: px(lay.bubbleY),
          width: px(lay.bubbleW),
          padding: px(pick(26, 30, 22)),
          borderRadius: px(28),
          borderTopLeftRadius: px(8),
          background: "#fff",
          boxShadow: `0 ${px(20)} ${px(50)} rgba(46,18,80,0.18)`,
          fontFamily: SANS,
          color: C.ink,
          transformOrigin: "top left",
          opacity: bubble.opacity,
          y: bubble.y,
          scale: bubbleScale,
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: px(10), fontWeight: 800, fontSize: px(pick(20, 24, 18)), color: C.royal, letterSpacing: "0.04em", textTransform: "uppercase" }}>
          <span style={{ width: px(12), height: px(12), borderRadius: "50%", background: C.bright }} />
          Paint Expert
        </div>
        <div style={{ marginTop: px(10), fontWeight: 700, fontSize: px(pick(24, 30, 21)) }}>{scene.question}</div>
        <div style={{ marginTop: px(8), fontWeight: 500, fontSize: px(pick(22, 27, 19)), lineHeight: 1.4, color: C.muted }}>{scene.answer}</div>
      </motion.div>
    </motion.section>
  );
}

function ProblemTag({ label, at, local, reducedMotion }: { label: string; at: number; local: MotionValue<number>; reducedMotion: boolean }) {
  const scale = usePop(local, at, reducedMotion, 0.4);
  const opacity = useTransform(local, [at, at + 0.15], [0, 1]);
  return (
    <motion.div
      style={{
        display: "flex",
        alignItems: "center",
        gap: px(12),
        padding: `${px(12)} ${px(22)}`,
        borderRadius: px(999),
        background: C.night,
        color: "#fff",
        fontFamily: SANS,
        fontWeight: 700,
        fontSize: px(pick(24, 28, 21)),
        boxShadow: `0 ${px(10)} ${px(26)} rgba(26,10,46,0.3)`,
        scale,
        opacity,
        transformOrigin: "left center",
        whiteSpace: "nowrap",
      }}
    >
      <span style={{ width: px(14), height: px(14), borderRadius: "50%", background: "#FF9F5A", boxShadow: `0 0 0 ${px(5)} rgba(255,159,90,0.25)` }} />
      {label}
    </motion.div>
  );
}

/* ------------------------------------------------------------------------------------------------
 * 5. Free estimate: the chosen color goes on the wall, and the request is sent.
 * ---------------------------------------------------------------------------------------------- */
function EstimateScene({ scene, clock, video, reducedMotion }: SceneProps<"estimate">) {
  const local = useLocal(scene, clock);
  const opacity = useCrossFade(scene, clock);
  const zoom = useTransform(local, [0, 5.5], reducedMotion ? [1.08, 1.08] : [1.08, 1.02]);
  const lay = pick(
    { x: 110, kickerY: 150, headY: 220, head: 100, cardX: 110, cardY: 700, cardW: 560 },
    { x: 80, kickerY: 370, headY: 440, head: 96, cardX: 80, cardY: 1250, cardW: 760 },
    { x: 64, kickerY: 80, headY: 140, head: 78, cardX: 64, cardY: 760, cardW: 560 },
  );
  const kicker = useRise(local, 0.3, reducedMotion, 24);
  const head = useRise(local, 1.4, reducedMotion, 36);
  const card = useRise(local, 3.2, reducedMotion, 80);
  const check = useTransform(local, [3.45, 3.85], [0, 1], { ease: easeOut });
  return (
    <motion.section style={{ ...abs, inset: 0, opacity }}>
      {video && <FullBleedVideo video={video} scale={zoom} origin="center bottom" />}
      <div
        style={{
          ...abs,
          inset: 0,
          background: pick(
            "linear-gradient(90deg, rgba(26,10,46,0.55) 0%, rgba(26,10,46,0.15) 45%, rgba(26,10,46,0) 60%)",
            "linear-gradient(180deg, rgba(26,10,46,0.55) 0%, rgba(26,10,46,0.05) 35%, rgba(26,10,46,0.05) 60%, rgba(26,10,46,0.5) 100%)",
            "linear-gradient(90deg, rgba(26,10,46,0.55) 0%, rgba(26,10,46,0.1) 55%, rgba(26,10,46,0) 70%)",
          ),
        }}
      />
      <motion.div style={{ ...abs, left: px(lay.x), top: px(lay.kickerY), fontFamily: SANS, fontWeight: 700, fontSize: px(lay.head * 0.34), letterSpacing: "0.12em", textTransform: "uppercase", color: C.lilac, ...kicker }}>
        {scene.kicker}
      </motion.div>
      <motion.div
        style={{
          ...abs,
          left: px(lay.x),
          top: px(lay.headY),
          width: px(pick(640, 900, 520)),
          fontFamily: SERIF,
          fontWeight: 600,
          fontSize: px(lay.head),
          lineHeight: 1.02,
          letterSpacing: "-0.025em",
          color: "#fff",
          textShadow: "0 4px 30px rgba(10,4,20,0.35)",
          ...head,
        }}
      >
        {scene.headline}
      </motion.div>
      <motion.div
        style={{
          ...abs,
          left: px(lay.cardX),
          top: px(lay.cardY),
          width: px(lay.cardW),
          display: "flex",
          gap: px(22),
          alignItems: "center",
          padding: px(26),
          borderRadius: px(30),
          background: "rgba(251,247,241,0.96)",
          boxShadow: `0 ${px(30)} ${px(70)} rgba(10,4,20,0.4)`,
          fontFamily: SANS,
          color: C.ink,
          ...card,
        }}
      >
        <div style={{ position: "relative", flex: "none", width: px(78), height: px(78), borderRadius: "50%", background: C.royal }}>
          <svg viewBox="0 0 40 40" style={{ ...abs, inset: 0, width: "100%", height: "100%" }}>
            <motion.path d="M12 20.5 L18 26.5 L28.5 14" fill="none" stroke="#fff" strokeWidth={3.6} strokeLinecap="round" strokeLinejoin="round" style={{ pathLength: check }} />
          </svg>
        </div>
        <div>
          <div style={{ fontWeight: 800, fontSize: px(pick(30, 38, 28)), letterSpacing: "-0.01em" }}>{scene.cardTitle}</div>
          <div style={{ display: "flex", alignItems: "center", gap: px(10), marginTop: px(6), fontWeight: 600, fontSize: px(pick(22, 27, 20)), color: C.ink }}>
            <span style={{ width: px(20), height: px(20), borderRadius: px(6), background: PAINTS[2].hex }} />
            {scene.cardDetail}
          </div>
          <div style={{ marginTop: px(4), fontWeight: 500, fontSize: px(pick(20, 25, 18)), color: C.muted }}>{scene.cardNote}</div>
        </div>
      </motion.div>
      <DramaTag text={scene.tag} />
    </motion.section>
  );
}

/* ------------------------------------------------------------------------------------------------
 * 6. Close: a happy finished room, the logo and the call to action.
 * ---------------------------------------------------------------------------------------------- */
function CloseScene({ scene, clock, video, reducedMotion }: SceneProps<"close">) {
  const local = useLocal(scene, clock);
  const opacity = useCrossFade(scene, clock);
  const zoom = useTransform(local, [0, 5], reducedMotion ? [1.02, 1.02] : [1.02, 1.08]);
  const lay = pick(
    { x: 120, logoY: 180, logo: 230, titleY: 450, title: 104, ctaY: 600, urlY: 720, align: "left" as const },
    { x: 80, logoY: 1000, logo: 200, titleY: 1220, title: 96, ctaY: 1350, urlY: 1460, align: "left" as const },
    { x: 64, logoY: 110, logo: 170, titleY: 310, title: 80, ctaY: 420, urlY: 520, align: "left" as const },
  );
  const logoScale = usePop(local, 0.25, reducedMotion, 0.4);
  const title = useRise(local, 0.5, reducedMotion, 30);
  const cta = useRise(local, 0.9, reducedMotion, 30);
  const url = useRise(local, 1.3, reducedMotion, 20);
  const shine = useTransform(local, (t) => `${-60 + clamp01((t - 1.8) / 0.9) * 220}%`);
  return (
    <motion.section style={{ ...abs, inset: 0, opacity }}>
      {video && <FullBleedVideo video={video} scale={zoom} />}
      <div
        style={{
          ...abs,
          inset: 0,
          background: pick(
            `linear-gradient(90deg, rgba(26,10,46,0.94) 0%, rgba(46,18,80,0.82) 34%, rgba(46,18,80,0.15) 62%, rgba(46,18,80,0) 75%)`,
            `linear-gradient(180deg, rgba(26,10,46,0) 25%, rgba(46,18,80,0.85) 48%, rgba(26,10,46,0.96) 100%)`,
            `linear-gradient(90deg, rgba(26,10,46,0.94) 0%, rgba(46,18,80,0.8) 50%, rgba(46,18,80,0.1) 85%)`,
          ),
        }}
      />
      <motion.div
        style={{
          ...abs,
          left: px(lay.x),
          top: px(lay.logoY),
          width: px(lay.logo),
          height: px(lay.logo),
          borderRadius: "50%",
          background: C.cream,
          boxShadow: `0 ${px(20)} ${px(50)} rgba(10,2,20,0.45)`,
          overflow: "hidden",
          scale: logoScale,
        }}
      >
        <img src="/taulbee-logo-v1.png" alt="" style={{ ...abs, inset: "4%", width: "92%", height: "92%", objectFit: "contain" }} />
      </motion.div>
      <motion.div
        style={{ ...abs, left: px(lay.x), top: px(lay.titleY), fontFamily: SERIF, fontWeight: 600, fontSize: px(lay.title), letterSpacing: "-0.025em", lineHeight: 1, color: "#fff", whiteSpace: "nowrap", ...title }}
      >
        {scene.name}
      </motion.div>
      <motion.div
        style={{
          ...abs,
          left: px(lay.x),
          top: px(lay.ctaY),
          display: "flex",
          alignItems: "center",
          gap: px(16),
          padding: `${px(20)} ${px(34)} ${px(20)} ${px(20)}`,
          borderRadius: px(999),
          background: C.cream,
          overflow: "hidden",
          boxShadow: `0 ${px(16)} ${px(40)} rgba(10,2,20,0.35)`,
          fontFamily: SANS,
          fontWeight: 800,
          fontSize: px(pick(32, 38, 28)),
          color: C.plum,
          whiteSpace: "nowrap",
          ...cta,
        }}
      >
        <img src="/taulbee-icon-v1.png" alt="" style={{ width: px(pick(56, 66, 50)), height: px(pick(56, 66, 50)), borderRadius: px(14) }} />
        {scene.cta}
        <motion.div
          style={{
            ...abs,
            top: 0,
            bottom: 0,
            width: "30%",
            left: shine,
            background: "linear-gradient(100deg, rgba(255,255,255,0) 0%, rgba(255,255,255,0.75) 50%, rgba(255,255,255,0) 100%)",
          }}
        />
      </motion.div>
      <motion.div style={{ ...abs, left: px(lay.x + 8), top: px(lay.urlY), fontFamily: SANS, fontWeight: 600, fontSize: px(pick(30, 34, 26)), color: C.lilac, letterSpacing: "0.01em", ...url }}>
        {scene.url}
      </motion.div>
      <DramaTag text={scene.tag} />
    </motion.section>
  );
}
