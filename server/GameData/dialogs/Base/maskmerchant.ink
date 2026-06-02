+ -> intro

=== intro ===
A hunt a day keeps the doctor away.

+ [Who are you?]
    Another new Runner? Y'all popping up like flies to a turd these days. Im Kade Mercer but you can call me Ghost.

    I'm lucky enough to have fought some of the greatest hunts! Maybe one day I'll tell you where to find them.

    ~qf_metGhost = true
    
    ->intro
+ {has qf_metGhost && not qf_epicQuestComplete && not qf_hunterQuestPhaseOne}[Can you tell me about one of those special hunts?]
    A whelp like you? Get some hair on your chest first kid.

    Come talk to me once you've atleast proven yourself to Elio Voss.

    ->intro
    
+ {has qf_epicQuestComplete && not qf_hunterQuestPhaseOne}[Elio said I should talk to you about a quest.]

    New blood, standing before me... interesting. Most give the Huntmaster a wider berth. Either brave or foolish. Sometimes there's no difference.
        
    The Runner Order needs more than bodies to throw at the Wyld. It needs fighters who understand the dance between predator and prey. You want to be useful? Prove you can hunt.
                
    I'd like you to go after the Young Hunter - a juvenile Echo-beast.

    Fresh Runners think it's easy prey because of its youth. They quickly return with their tails between their legs.

    Bring me proof of its defeat. Not just any part - I need its Adaptation Gland. Located at the base of its skull.
        
    ~ qf_hunterQuestPhaseOne = true
    ~ qf_hunterQuestPhaseOneItems = true 

    Don't disappoint me, Runner. The Young Hunter is the first test. Succeed... and perhaps you'll be worthy of greater hunts.

    ->intro
+ {has qf_hunterQuestPhaseOne && not item_201 && not qf_hunterQuestPhaseTwo}[Remind me again, what was it you needed?]

    Well this isn't going very well so far if you've already forgotten.

    Return with an Adaption Gland Stone, from the Young Hunter!

    ->intro
+ {has qf_hunterQuestPhaseOne && has item_201}[I brought you the Adaption Gland.]

    You survived? And with the Adaptation Gland intact? Impressive.
    
    Most think the Young Hunter is a fluke. A random mutation. They're wrong. It's part of something... larger. A hierarchy of hunters, each more evolved than the last.
    
    These are confirmed sightings of what we call the Dark Hunter. 
    
    Return with the Dark Adaption Gland, and we'll discuss the final trial. Few make it this far. Even fewer complete what comes next.


    ~ qf_hunterQuestPhaseTwo = true
    ~ qf_hunterQuestPhaseTwoItems = true
    ~ qf_hunterQuestPhaseOneItems = false
    ~ item_201 = false

    Good luck, Runner. You'll need it.

    ->intro
+ {has qf_hunterQuestPhaseTwo && not qf_hunterQuestComplete && not item_202}[Remind me again, what was it you needed?]

    Wow...and I thought you had promise.

    It's like the last item you retrieved but darker.

    It's the DARK Adaption Gland.

    ->intro
+ {has qf_hunterQuestPhaseTwo && has item_202}[I brought you the Dark Adaption Gland.]

    You... you actually did it? Guess you're not just another welp.

    Thornwood's been pestering me about qualified Runners for his raid teams. And I think we just found another.
    
    Go see Thornwood. Tell him Ghost says you're raid-ready. He'll probably fall off his chair.

    Welcome to the real Hunt, Runner. It never ends - it just changes form.

    ~ qf_hunterQuestPhaseTwoItems = false
    ~ qf_hunterQuestComplete = true
    ~ item_202 = false
    ~ item_119 = true

    ->intro
+ {has qf_hunterQuestComplete}[Any other hunter quests?]

    Not for now but scouts are searching. 

    As the seasons change so do the hunts.

    Check back in later.

+ [See you later!]
    Yeah, yeah. -> END

- -> END