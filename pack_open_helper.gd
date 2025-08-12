extends Node

enum Sets {
WelcomeToRathe,
ArcaneRising,
CrucibleOfWar,
Monarch,
TalesOfAria,
Everfest,
HistoryPackOne,
Uprising,
Dynasty,
HistoryPackTwo,
Outsiders,
DuskTillDawn,
BrightLights,
HeavyHitters,
PartTheMistveil,
Rosetta,
GemPack1,
TheHunted,
GemPack2,
TreasurePack,
HighSeas,
MasteryPackGuardian
}

var opening_pack_resource : PackResource
var opened_cards : Dictionary[String, Array] = {}
var packs_to_open : int = 0
