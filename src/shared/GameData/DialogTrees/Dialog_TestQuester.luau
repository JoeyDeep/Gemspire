return {
    entry = "questReady",
    nodes = {
        -- evaluator that checks statistics or history in player data to either allow player to get to questReady or notReady
        -- is player >lvl5? has player finished previous questline?
        -- begin explain zone

        questNotReady = {
            text = "Greetings, traveler. You seem inexperienced for the quest I have in mind. Return when you are stronger.",
            next = "exit",
        },
        questReady = {
            text = "Hello, adventurer! Are you ready for a quest?",
            options = "start_options",
        },
        
        accept_quest = {
            text = "I bestow upon you the reveled TestQuest. Best of luck to you, brave one.",
            post = {
                { type = "giveQuest", id = "TestQuest" },
                { type = "delay", duration = 2 },
            },
            next = "exit",
        },
        decline_quest = {
            text = "No worries! Come back when you're ready for an adventure.",
            next = "exit",
        },

        exit = {
            text = 'Safe travels, <font color="rgb(255, 231, 94)"><playerName></font>. May your path be clear and your gems plentiful.',
            post = { { type = "close" } },
        },
    },
    option_sets = {
        start_options = {
            {
                id = "yes",
                optionText = "Yes, I'm ready!",
                next = "accept_quest",
            },
            {
                id = "no",
                optionText = "Not right now.",
                next = "decline_quest",
            },
        },
    },
}