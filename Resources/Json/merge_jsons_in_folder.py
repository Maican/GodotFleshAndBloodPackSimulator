import json
import sys
from pathlib import Path

# Base-level fields from the main card entry
BASE_FIELDS = [
    "classes", "legalHeroes", "legalFormats", "subtypes",
    "types", "typeText", "functionalText", "pitch", "power", "cost", "defense", "keywords", "life",
    "intellect", "talents", "oppositeSideCardIdentifier", "rarities"
]

# Fields that may exist in the printing
PRINTING_FIELDS = ["rarity", "artists", "isExpansionSlot"]

def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def save_json(data, path):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)

def build_fabrary_print_index(fabrary_cards):
    """Build a lookup from printing identifier to (card, printing) pair"""
    index = {}
    for card in fabrary_cards:
        for printing in card.get("printings", []):
            ident = printing.get("identifier")
            if ident:
                index[ident] = (card, printing)
    return index

def build_fabrary_name_index(fabrary_cards):
    """Build a lookup from card name to card (first printing only)"""
    name_index = {}
    for card in fabrary_cards:
        name = card.get("name") or card.get("Card Name")
        if name and name not in name_index:
            name_index[name] = card
    return name_index

def build_fabrary_identifier_index(fabrary_cards):
    """Build a lookup from cardIdentifier to card (first printing only)"""
    id_index = {}
    for card in fabrary_cards:
        cid = card.get("cardIdentifier")
        cid = cid.replace("-red", "-1").replace("-yellow", "-2").replace("-blue", "-3") if cid else None
        if cid and cid not in id_index:
            id_index[cid] = card
    return id_index

def augment_cards(fabrary_index, set_path: Path, output_path: Path):
    set_data = load_json(set_path)

    # Use alternate matching for History Pack Two
    if "HistoryPackTwo" in str(set_path):
        fabrary_id_index = build_fabrary_identifier_index([c[0] for c in fabrary_index.values()])
        for card in set_data:
            card_id = card.get("card_id")
            base_card = fabrary_id_index.get(card_id)
            if base_card:
                for field in BASE_FIELDS:
                    if field in base_card:
                        card[field] = base_card[field]
                    if "oppositeSideCardIdentifier" in base_card and "image" in card and "large" in card["image"]:
                        large_url = card["image"]["large"]
                        flip_url = large_url.replace(".webp", "_BACK.webp")
                        card["flipImage"] = {"large": flip_url}
                #need to handle rarity separately
                if "rarity" in base_card:
                    card["rarity"] = base_card["rarity"]
                if "artists" in base_card and len(base_card["artists"]) > 0:
                    card["artist"] = base_card["artists"][0]
            else:
                print(f"Didn't match for card_id: {card_id}")
    else:
        for card in set_data:
            for print_entry in card.get("prints", []):
                print_id = print_entry.get("print_id", "")
                if print_id.endswith("-CF") or print_id.endswith("-RF") or print_id.endswith("-MV") or print_id.endswith("-A") or print_id.endswith("-B") or print_id.endswith("-TP"):
                    print_id = print_id.split("-")[0]  # Strip foil suffix
                if print_id.startswith("FR_"):
                    print_id = print_id.split("_")[1] #Strip french suffix.
                matched = fabrary_index.get(print_id)
                if matched:
                    base_card, printing = matched
                    for field in BASE_FIELDS:
                        if field in base_card:
                            card[field] = base_card[field]
                        if "oppositeSideCardIdentifier" in base_card and "image" in card and "large" in card["image"]:
                            large_url = card["image"]["large"]
                            flip_url = large_url.replace(".webp", "_BACK.webp")
                            card["flipImage"] = {"large": flip_url}
                    for field in PRINTING_FIELDS:
                        if field in printing:
                            card[field] = printing[field]
                    break  # One match is enough
                else:
                    print(f"Didn't match for: {print_id}")

    save_json(set_data, output_path)
    print(f"✅ Saved: {output_path.name}")

def main(fabrary_file: str, directory: str):
    fabrary_data = load_json(fabrary_file)
    fabrary_index = build_fabrary_print_index(fabrary_data["cards"])

    dir_path = Path(directory)
    for file_path in dir_path.glob("*.json"):
        if file_path.name == Path(fabrary_file).name:
            continue  # Skip the fabrary file itself

        output_path = file_path.with_stem(file_path.stem + "_augmented")
        augment_cards(fabrary_index, file_path, output_path)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python merge_json.py <fabrary_file> <directory_of_set_files>")
        sys.exit(1)

    fabrary_file = sys.argv[1]
    directory = sys.argv[2]
    main(fabrary_file, directory)
