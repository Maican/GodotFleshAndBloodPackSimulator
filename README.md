# Flesh and Blood Progression Tool

A Godot 4.6 application for simulating the Flesh and Blood TCG progression experience — open packs, collect cards, build decks, and manage banlists.

## User Experience Flow

### 1. Open Packs

Select **Open Packs** from the Main Menu to enter the **Select Packs Screen**.

- Browse all available sets (Welcome to Rathe, Arcane Rising, Monarch, Rosetta, High Seas, etc.).
- Select a set and choose how many packs to open using the spinner.
- Press **Open Packs** to begin.

On the **Pack Opening Screen**, each pack is laid out as a grid of face-down cards:

- Click individual cards to flip them, or use **Flip All** to reveal the entire pack at once.
- Enable **Auto Flip** to automatically reveal cards as each new pack is generated.
- Use **Open Remaining** to rapidly open all remaining packs.
- A running tally on the right side tracks every card you've pulled, grouped by rarity (Fabled, Marvel, Legendary, Majestic, Super Rare, Rare, Common, Token).
- Hover over any card to see a detailed preview panel with stats, text, and art.

Pull rates follow the real-world odds configured per set — including foil slots, short-print majestics, equipment slots, expansion slots, and premium foils with weighted rarity rolls.

### 2. Save Cards to a Binder

After opening packs, save your pulls to a **Binder** before leaving:

- Select an existing binder from the dropdown, or create a new one with **Add Binder**.
- Use **Save Cards** to add your pulled cards to the selected binder. Duplicate cards are stacked (quantities increase).
- Optionally include **Tokens** and **Heroes** from the set using the checkboxes.
- Use **Save As** to create a new binder and save in one step.
- The app warns you if you try to leave without saving.

### 3. Manage Binders

Select **Binder Editor** from the Main Menu to view and curate your card collection.

- A master binder (`all_cards`) is automatically generated containing every imported card for easy browsing.
- Load any saved binder to see its contents.
- Add cards from the full card pool on the right side into your binder on the left side.
- Create, save, delete, and export binders.
- Apply a **Banlist** overlay to see which cards in your binder are currently banned.
- Hover over cards for a detailed preview.

### 4. Build Decks

Select **Deck Editor** from the Main Menu to construct decks from your binder.

- Choose a **Binder** as your card pool — only cards you own in that binder are available.
- Browse and filter cards using the **Filter Panel**: filter by class, rarity, type, subtype, talent, keyword, hero, and numerical stats (cost, power, defense, pitch, life, intellect).
- Search for cards by name.
- Add cards to your deck by clicking them in the card pool. Cards are placed into sections:
  - **Hero & Arena** — your hero, weapons, and equipment (with slot validation: head, chest, arms, legs, 1H/2H weapons and off-hands).
  - **Main Deck** — attack actions, defense reactions, instants, etc. (max 3 copies per card).
  - **Inventory** — sideboard / extra equipment.
  - **Maybe** — cards you're considering.
- Move cards freely between Main, Inventory, and Maybe sections.
- Card counts are displayed for each section.
- Apply a **Banlist** to highlight banned cards in your deck.
- **Save** your deck, or use **Save As** to create a new one.
- **Export** copies a formatted decklist to your clipboard for sharing.

### 5. Create & Apply Banlists

Select **Banlist Editor** from the Main Menu to manage custom banned/restricted lists.

- Create a new banlist or load an existing one.
- Browse the full card pool and add cards to the banned list.
- Set **Living Legend points** for each hero.
- Save, delete, and export banlists.
- Banlists can be applied in both the **Deck Editor** and **Binder Editor** to visually flag banned cards.

### Flow Summary

```
Main Menu
  │
  ├─► Open Packs ──► Select Set & Quantity ──► Open & Flip Cards ──► Save to Binder
  │
  ├─► Binder Editor ──► Browse / Curate Collection ──► Apply Banlists
  │
  ├─► Deck Editor ──► Pick Binder ──► Filter & Search ──► Build Deck ──► Export
  │
  └─► Banlist Editor ──► Add Banned Cards ──► Set Hero LL Points ──► Save
```

The typical progression loop is: **Open Packs → Save to Binder → Build Deck → Play** — simulating the real-world experience of cracking boosters, growing your collection over time, and building decks from what you've pulled.

---

## Supported Sets

| Set Code | Set Name |
|----------|----------|
| WTR | Welcome to Rathe |
| ARC | Arcane Rising |
| CRU | Crucible of War |
| MON | Monarch |
| ELE | Tales of Aria |
| EVR | Everfest |
| 1HP | History Pack One |
| UPR | Uprising |
| DYN | Dynasty |
| 2HP | History Pack Two |
| OUT | Outsiders |
| DTD | Dusk Till Dawn |
| EVO | Bright Lights |
| HVY | Heavy Hitters |
| MST | Part the Mistveil |
| ROS | Rosetta |
| HNT | The Hunted |
| SEA | High Seas |
| SEA-TP | Treasure Pack |
| MPG | Mastery Pack: Guardian |
| SUP | Super Slam |
| PEN | Compendium of Rathe |
| ANQ | Antiquity Pack |
| GEM | Gem Packs (1, 2, 3) |
