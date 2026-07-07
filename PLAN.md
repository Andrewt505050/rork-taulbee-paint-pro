# Add the Taulbee Paint Expert — an AI chatbot backed by a product library

## What this adds

A new **Expert** tab: a friendly AI paint advisor your customers can ask anything — "What's the best paint for a humid bathroom?", "How do I fix peeling on my deck?", "Which Sherwin-Williams finish for kitchen cabinets?" — paired with a browsable library of recommended paint products and solutions.

## Features

- **Ask the Paint Expert**: A chat screen where customers type a question and get clear, practical answers grounded in painting best practices and your product recommendations.
- **Smart suggestions**: Tappable starter questions (interior, exterior, prep, problem-solving) so people know what to ask.
- **Product library**: A curated list of recommended paints and primers — organized by use (interior walls, trim, cabinets, exterior, ceilings, primers, specialty) with a short "best for" note on each.
- **Product detail**: Tap any product to see what it's best for, key features, and a one-tap way to ask the Expert about it.
- **Always points back to Taulbee**: When relevant, the Expert gently suggests requesting a quote for professional work.
- **Conversation stays on the device**: Chat history is kept locally so a customer can pick up where they left off.

## Design

- Same premium Taulbee purple-and-paper look so it feels like one product.
- Chat bubbles with the Taulbee mark on the Expert's replies, smooth typing/streaming feel, and a clean input bar pinned at the bottom.
- Product library shown as warm, swatch-style cards grouped by category with a quick category filter.
- A welcoming empty state introducing the Expert with a few example questions.

## Screens

- **Expert chat**: Conversation view with starter prompts, message bubbles, and a question input bar.
- **Product library**: Categorized list/grid of recommended products with filters and search.
- **Product detail**: Full product info plus an "Ask the Expert about this" shortcut.

## Navigation

- Bottom tabs: **Home, Visualize, Vault, Expert, More**. Home is the dashboard hub and routes into the dedicated Paint Defect Scanner (also reachable from More and the hero carousel).

## Premium redesign (latest)

A full design-system refresh across every screen for an App-Store-ready, premium look:

- [x] Upgraded design system: light canvas, rich purple brand, lavender accents, vivid hero gradient, softer shadows.
- [x] New 5-tab navigation (Scan, Vision, Vault, Expert, More) with cross-tab quick actions.
- [x] Home / Dashboard: welcome header, Quick Actions card, unified Your Activity feed.
- [x] Paint Defect Scanner: centered purple hero, Recent Scans, Tips for Best Results.
- [x] Vision Tool: centered hero + Recent Visualizations rows with color swatches.
- [x] Paint Expert: centered hero icon, Suggested Questions / Popular Topics segments, question cards.
- [x] Vault: filter pills (All, Scans, Visualizations, Docs, Quotes) with grouped sections.
- [x] More / Settings: profile card, Request a Quote CTA, project links, contact, privacy & settings.
- [x] Vision-first home refresh: compact brand header, "See your room in a new color" hero, Paint Project Path stepper, redesigned quick actions (incl. Request Estimate), premium activity empty state, and a custom bottom bar with a sliding pill highlight.
- [x] Mockup-driven home upgrade: dedicated Home tab (Home, Visualize, Vault, Expert, More) with a lavender pill nav, a swipeable photo hero carousel (Visualizer / Scanner / Expert slides with real room photography and serif headlines), dotted Project Path steps with numbers, subtitles and a "How it works" sheet, icon-left quick action cards, a paintbrush-and-sparkles activity empty state, and a bell notifications sheet.

## Homeowner Hub (latest)

Retention layer that turns the app into a lead magnet, customer portal, project vault, and long-term care tool:

- [x] Paint Vault upgrade: Rooms section with room cards (last painted, swatch dots, next reminder), new filter pills (All, Rooms, Scans, Visualizations, Docs, Quotes), "Never forget what color is on your walls again" header, and an Add First Room empty state.
- [x] Room Profiles: name, type, photos with Before/After tags, current color + sheen, saved color ideas (brand library or manual entry), surface checklist, last painted date, condition / touch-up / contractor / warranty notes, attached reminders, and a Request Estimate for This Room CTA.
- [x] Maintenance Reminders: Overdue / Due Soon / Upcoming / Completed sections, 14 categories, recurrence (monthly to every 3 years + custom), priorities, one-tap Recommended Care Schedule templates, local notifications (permission asked only at first reminder), and auto-rescheduling of recurring checks on completion.
- [x] Activity Timeline: rooms, colors, reminders, estimates, and photos logged as events; merged with scans, visualizations, and expert questions on Home and in a full day-grouped Activity screen.
- [x] Home integration: "Protect Your Paint" section (next reminder or Set a Reminder card) and a more useful empty state with Start Visualizing + Add Reminder.
- [x] Lead capture: in-app Request Estimate form (name, contact, room, details, photos) replacing bare email links everywhere; soft prompts after scans (Request Inspection), after saving colors (Ask a Paint Expert), after creating a room (Want pricing?), and on overdue reminders (Want us to take a look?).
- [x] More menu: Homeowner Hub group with Maintenance Reminders, Paint Vault, Saved Colors, Project Photos, and Activity Timeline.

## Functional Vision Tool (latest)

The visualizer is now a real product: instant wall painting with the complete color books.

- [x] Complete color catalogs bundled in-app: 7,734 real colors (1,526 Sherwin-Williams, 4,118 Benjamin Moore, 2,090 PPG) with true names, product codes, and swatches — browsable offline.
- [x] One-time AI surface detection per photo + surface (walls, siding, trim, door, cabinets), then unlimited instant on-device recolors that keep the room's real lighting, shadows, and texture (no per-color AI cost).
- [x] Live Paint canvas: full-bleed photo, swipeable bottom color strip with Popular bestsellers + recent library picks, current-color chip, hold-to-compare with the original, and surface switching from the toolbar.
- [x] HD Render on demand — the photorealistic AI render is now an upgrade step for the color you love (cached per color/surface).
- [x] Smart fallback: if detection can't find the surface, the canvas quietly switches to classic per-color AI renders.
- [x] Color Library upgrade: Popular Picks shelf, search by name or code across all 7,700+ colors, brand + family filters; the Vault color picker uses the full books too.
- [x] Saving, before/after slider, Ask an Expert, and Send to Taulbee all work with instant previews and HD renders.

## Note

This completes all four features from your original vision, the premium redesign, the Homeowner Hub retention layer, and the functional Vision Tool.