+ {qf_spokeWithEntityFirstTime} -> intro
+ {not qf_spokeWithEntityFirstTime} -> first_time

=== intro ===

(The entity hovers above the ground, its eyes gazing into the distance, seeing beyond.)

+ [Who are you?]
    Ah another new runner has joined our ranks. I'm Elio Voss, the leader of the Runner Order.

    If you need any help, directions or tips to excel in the Wyld Land please share them with me and I'll do my best to support. 

    ->intro

+ [Anything I should know?]
    The topics are endless! Let me know which subject intrigues you or else I'll talk all day.
    
    ++ [What's this chest?]
        It's a place to store items that are precious to you. In Rebirth, all your items will be lost.

        Anything you place here will be available anytime you wish to retrieve it.

        ->intro
    ++ [What's Infusing?]
        Oh the power of infusion! A skill every Runner should know and a great way to improve your gear.

        Sometimes you will find a spike on a gun or armor that you really like but it's stats aren't the best.

        Infusion helps you solve this by combining two weapons of the same archetype or two armor pieces of the same type to add that spike to gear with better stats.

        By default you start infusion by pressing V when hovering over one of the items you want to combine.

        ->intro
    ++ [How do I use the map?]
        Ah the trusty map, one of a Runners most useful tools.

        It can inform you of the danger level of an area and where world events are occuring.

        But what I have found most useful is the teleport system established by the Runners before you.

        They've made markers that allow you to instantly teleport to that area.

        By default you can open the menu with the Spacebar.

        ->intro
+ [I want to unlock Echoes!]
    #menu echoes #autoclose 
    -> END

+ [I want to do a weekly challenges.]
    You're ready for a little competition? That's exciting to hear!

    ++ [I want to do the advanced challenge.]

        ~ item_178 = true

        I just gave you one of our Weekly Dungeon Shards. Use that to compete for the best time in this week's dungeon.

        Check the Leaderboard to see where you rank. I'm excited to see who comes out on top.
        
        ->intro
    
    ++ [I want to do the basic challenge.]

        ~item_179 = true

        I just gave you one of our Weekly Dungeon Shards. Use that to compete for the best time in this week's dungeon.

        Check the Leaderboard to see where you rank. I'm excited to see who comes out on top.
        
        ->intro
    
    ++ [How do Weekly Challenge Dungeons work?]
        
        It's a special kind of shard where the Wyld energy is tamed temporarily. That means the dungeon is always the same.

        Runners like to compete to see who can get the best time. So it's for bragging rights. I've heard nothing good really drops in there.
        
        ->intro

+ {not qf_epicQuestPhaseOneActive && not qf_epicQuestComplete}[Any quests?]

    Ah, a bit of an adventerous one, aren't you?

    Well, the Untouched back home are always in need of more resources!

    To start, grab me a block of Colossus Stone, you can find it in the Underground Cave.

    ~ qf_epicQuestPhaseOneActive = true
    ~ qf_epicQuestPhaseOneItems = true

    It sometimes falls off the big, menacing creature at the end of the dungeon.

    And if you are able to complete what I need. Some of the other Haven commanders may be more inclined to give you tasks.

    Good luck.
    ->intro
+ {has qf_epicQuestPhaseOneActive && not item_120 && not qf_epicQuestPhaseTwoActive}[What was it you needed?]

    Well this isn't going very well so far if you've already forgotten.

    To start, grab me a block of Colossus Stone, you can find it in the Underground Cave.

    ->intro
+ {has qf_epicQuestPhaseOneActive && has item_120 && not qf_epicQuestPhaseTwoActive}[I brought you the Colossus Stone]

    Ahhh, fascinating. You do have what it takes to bring me some interesting pieces.

    The next batch of things I need.

    Bring me a Heart Core from the Hoarder's Den, Red Ooze from the Red King's lair, and a Wyrm Egg from the Great Wyrm herself.

    Each of these will be a little harder to acquire than the last, but when we have them all we should be able to move on to the final step.

    ~ qf_epicQuestPhaseTwoActive = true
    ~ qf_epicQuestPhaseTwoItems = true
    ~ qf_epicQuestPhaseOneItems = false
    ~ item_120 = false

    Good luck, Runner. You'll need it.

    ->intro
+ {has qf_epicQuestPhaseTwoActive && not item_121 && not item_122 && not item_123 && not qf_epicQuestPhaseThreeActive}[What was it you needed?]

    I did give you a pretty long shopping list this time around, didn't I?

    Bring me a Heart Core from the Hoarder's Den, Red Ooze from the Red King's lair, and a Wyrm Egg from the Great Wyrm herself.

    ->intro
+ {has qf_epicQuestPhaseTwoActive && has item_121 && not item_122 && not item_123 && not qf_epicQuestPhaseThreeActive}[What was it you needed?]
     I did give you a pretty long shopping list this time around, didn't I?

    Bring me a Heart Core from the Hoarder's Den, Red Ooze from the Red King's lair, and a Wyrm Egg from the Great Wyrm herself.

    ->intro
+ {has qf_epicQuestPhaseTwoActive && has item_121 && has item_122 && not item_123 && not qf_epicQuestPhaseThreeActive}[What was it you needed?]
     I did give you a pretty long shopping list this time around, didn't I?

    Bring me a Heart Core from the Hoarder's Den, Red Ooze from the Red King's lair, and a Wyrm Egg from the Great Wyrm herself.

    ->intro
+ {has qf_epicQuestPhaseTwoActive && has item_121 && not item_122 && has item_123 && not qf_epicQuestPhaseThreeActive}[What was it you needed?]
     I did give you a pretty long shopping list this time around, didn't I?

    Bring me a Heart Core from the Hoarder's Den, Red Ooze from the Red King's lair, and a Wyrm Egg from the Great Wyrm herself.

    ->intro
+ {has qf_epicQuestPhaseTwoActive && not item_121 && has item_122 && not item_123 && not qf_epicQuestPhaseThreeActive}[What was it you needed?]
     I did give you a pretty long shopping list this time around, didn't I?

    Bring me a Heart Core from the Hoarder's Den, Red Ooze from the Red King's lair, and a Wyrm Egg from the Great Wyrm herself.

    ->intro
+ {has qf_epicQuestPhaseTwoActive && not item_121 && has item_122 && has item_123 && not qf_epicQuestPhaseThreeActive}[What was it you needed?]
     I did give you a pretty long shopping list this time around, didn't I?

    Bring me a Heart Core from the Hoarder's Den, Red Ooze from the Red King's lair, and a Wyrm Egg from the Great Wyrm herself.

    ->intro
+ {has qf_epicQuestPhaseTwoActive && not item_121 && has item_122 && has item_123 && not qf_epicQuestPhaseThreeActive}[What was it you needed?]
     I did give you a pretty long shopping list this time around, didn't I?

    Bring me a Heart Core from the Hoarder's Den, Red Ooze from the Red King's lair, and a Wyrm Egg from the Great Wyrm herself.

    ->intro
+ {has qf_epicQuestPhaseTwoActive && has item_121 && has item_122 && has item_123 && not qf_epicQuestPhaseThreeActive}[I brought you those items you needed.]

    Excellent, excellent! Bring them over here and let me look at them in the light.

    Here, here!!! What a great batch!!! You just might have what it takes to go all the way.

    For your last task please fetch me the Shadow Box from the Shadow Realm.

    ~ qf_epicQuestPhaseTwoItems = false
    ~ qf_epicQuestPhaseThreeActive = true
    ~ qf_epicQuestPhaseThreeItems = true
    ~ item_121 = false
    ~ item_122 = false
    ~ item_123 = false

    This will be the last thing we need but perhaps your toughest challenge yet. Tread safely Runner.

    ->intro
+ {has qf_epicQuestPhaseThreeActive && not item_200 && not qf_epicQuestComplete}[What was it you needed?]

    Is the fatigue affecting your memory? Stay strong Runner.

    For your last task please fetch me the Shadow Box from the Shadow Realm.

    ->intro
+ {has qf_epicQuestPhaseThreeActive && has item_200 && not qf_epicQuestComplete}[I brought you the last of the items you requested.]

    A Runner with some real meat on their bones here! 

    The Untouched are gonna be thrilled with these new power cores!

    ~ qf_epicQuestPhaseThreeItems = false
    ~ qf_epicQuestComplete = true
    ~ item_200 = false
    ~ item_116 = true

    For a job well done you deserve this! A new teleportation perfect for a conquerer of the Shadow Hunter!

    And Im sure that Ghost may be open to giving you new some work now.
    ->intro
+ {has qf_epicQuestComplete && not qf_worldEventsQuest}[I think Im ready for another quest!]
    The Wyld Lands are so vast! Have you explored them yet?

    Now that I think about it I have a great idea! 

    Those in the City are in dire need of supplies. Specifically echo cores to keep the protection wards running and the monsters at bay.

    Unfortunatly these items are rare and I need one from each of the surrounding biomes.

    Oh I have an idea! Open your map and look for the "World Event" icons. These will show where you can take on challenges to find these cores.

    Bring me back a core from each biome (Mushroom Core, Foundation Core, Blizzard Core and the Swamp Core). The City will be gratful and I'll have a special something for you!

    ~ qf_worldEventsQuest = true
    ~ qf_worldEventsQuestItems = true

    Now be off! And let me know if you have any questions. Oh and before I forget.

    There are teleportation portals on the map too! Use those to get around the world faster. Now Good luck!    
    
    ->intro
+ {has qf_epicQuestComplete && has qf_worldEventsQuest && not qf_worldEventsQuestComplete && not item_208 && not item_209 && not item_210 && not item_211}[What were the quest details?]

    Not a problem young one. You need to open your map and look for the world event icons.

    When you see one teleport to the closest teleporter and then continue on to the world event. 

    Do this for each of the biomes and bring me back a Mushroom Core, Foundation Core, Blizzard Core and the Swamp Core.

    ->intro
+ {has qf_epicQuestComplete && has qf_worldEventsQuest && has item_208 && has item_209 && has item_210 && has item_211}[I've got all the cores!!!!]

    Woah you did it! 

    The Untouched back home in The City will be thrilled to live another day!

    And for your efforts! Take this!

    ~ qf_worldEventsQuestComplete = true
    ~ qf_worldEventsQuestItems = false
    ~ item_118 = true
    ~ item_208 = false
    ~ item_209 = false
    ~ item_210 = false
    ~ item_211 = false

    You can equip it to change how your teleportation looks! It's defeinetly one EYE would use!

    ->intro
+ [See you later!]
    Farewell, runner. -> END

=== first_time ===

Hello, runner. There are a few things you should know before you begin your adventures in this strange land.

~ qf_spokeWithEntityFirstTime = true

If you should perish, you will be reborn. However, while you will retain your experiences, you will lose your posessions.

Use the chest before me to store items and I will keep them safe for you, even in death.

Each time you die, you attune further to the Wyld Energy that is found all around us. Eventually, you will develop Echoes.

Echoes represent the ways in which the Wyld Energy you encounter links you with the past. Come speak to me when you want to unlock these powers.

However, only in death will these Echoes begin to manifest.

-> END