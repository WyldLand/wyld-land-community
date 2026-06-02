+ -> intro

=== intro ===

I've seen you around, and you seem to know your way around the Wyld.

+ [Who are you?]
    New here aren't you old chap? Or I guess in this case young chap! OHOHOHO!

    I jest, I jest. But you certainly must be new if you are asking. Im Eziekiel Thornwood at your service!

    I organize teams for tackling raids. But only for the best of the best! 

    ~ qf_metThornwood = true

    ->intro

+ {has qf_metThornwood && not qf_hunterQuestComplete}[I want to Raid!]

    Another bright-eyed Runner with more enthusiasm than experience? Lovely.

    Look here, young one. My raid teams are for Runners who've proven they can walk and chew gum at the same time. You haven't even finished Ghost's glorified scavenger hunt? 
    
    That's like trying to join a swimming competition before learning that water is wet!

    Come back when Ghost doesn't roll his eyes at the mention of your name. Until then, perhaps practice not getting eaten by the smaller, friendlier monsters? 
    
    You know, the ones that only want to nibble your extremities instead of swallowing you whole.

    ->intro
+ {has qf_metThornwood && has qf_hunterQuestCompletedisabled && not qf_raidOne}[Ghost said to talk to you about joining a Raid?]

    Ahem! The successful hunter returns! Ghost mentioned you only died, what, few times during his trials? That's practically a record around here!

    I've been organizing a raid team for a special excursion. And by 'organizing,' I mean 'trying to find Runners who won't immediately become monster snacks.

    Now take this dohickey. It’s the only way to spawn a good ole Raid portal. These dungeons are a little bit different than what you’re used to. The power of Victor is so strong that unlike normal dungeons his doesn't change.

    Every time you go you’ll be facing the same trials. Don’t you start getting overconfident. That may sound easier than normal but trust me it’s a challenge like you have never seen before!

    I hope you’ve been making friends because there’s no way you’ll be able to defeat him yourself. You and 5 others who have also proved themselves to Ghost will have to tackle this challenge together.

    I can’t emphasize how important it is to be careful out there. Death comes faster when attempting to thwart beings of high ethos.

    Take an old man's heed. If I were you I wouldn't waste your best gear on a first attempt. You and your friends will almost surely die.

    Wait until you understand the raid's mechanics and have a plan before going all in.

    The perils may be strong but the rewards...Heheh are well worth it!

    ~ item_204 = true
    ~ qf_raidOne = true
    ~ qf_raidOneItems = true

    ->intro

+ {has qf_metThornwood && has qf_hunterQuestCompletedisabled && has qf_raidOne && not item_204}[Can I have another Raid dohickey?]

    Need another chance at the raid huh? Told you it would take more than one try! 

    Here ya go!

    ~ item_204 = true

    ->intro

+ {has qf_metThornwood && has qf_hunterQuestCompletedisabled && has qf_raidOne}[Any Raid tips?]

    Take an old man's heed. If I were you I wouldn't waste your best gear on a first attempt. You and your friends will almost surely die.

    Wait until you understand the raid's mechanics and have a plan before going all in.

    ->intro
    
+ {has qf_metThornwood && has qf_hunterQuestComplete && has qf_raidTwo && has item_207 && not qf_raidTwoComplete} [We defeated the Dungeons!!!!!]

    The Runner of the hour! Or should I say, the Runner of the year? Two raid dungeons conquered! Victor's chaotic magic AND Weber's eight-legged circus—both survived with all your original limbs intact! More or less.

    Look at this collection! Absolutely unprecedented data! The Commander actually smiled when I showed him these findings—well, it might have been indigestion, but I'm counting it as a smile.

    You know, when you first wandered in here looking like fresh meat for the grinder, I had my doubts. Statistically speaking, your chances of survival were somewhere between 'snowball in a furnace' and 'chocolate teapot effectiveness.'
    
    Now, about your next assignment... [notices your expression] What? Did you think two raid dungeons was the end? Oh my dear Runner, we've barely scratched the surface! I’ll need time to figure out these new portals but check in with me regularly! Never know when I’ll have something new for ya!

    Now where did I put that specialized collection vial? The one that doesn't melt when exposed to sentient sap...

    ~ item_206 = false
    ~ qf_raidTwoItems = false
    ~ qf_raidTwoItems = false
    ~ qf_raidTwoComplete = true
    ~ item_119 = true

    ->intro
+ {has qf_metThornwood && has qf_raidTwoComplete} [Any more raids for us to try???]

    SILENCE BOY! Im studying this web.

    Come back later!
    
    ->intro
+ [See you later!]
    Cheerio! -> END

- -> END