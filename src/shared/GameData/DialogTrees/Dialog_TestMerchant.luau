return {
    entry = "merchantStart",

    nodes = {
        merchantStart = {
            nextLogic = {
                -- evaluate in order. if we pass a condition take the result. 
                -- if there is no condition take the result
                -- a conditon can have more than one requirement
                {
                    conditions = {
                        spoken_to = "TestMerchant"
                    },
                    result = "welcome_back"
                },
                {
                    -- like default
                    result = "menu"
                },
            }
        },
        welcome_back = {
            text = "Welcome back.",
            next = "menu",
        },
        menu = {
            text = {
                `Looking to sell some gems, <font color="rgb(255, 231, 94)"><playerName></font>?`,
                `Got some shiny stones to sell, <font color="rgb(255, 231, 94)"><playerName></font>?`,
            },
            options = "menu_options",
        },
        repeat_menu = {
            text = {
                `What else can I do for you, <font color="rgb(255, 231, 94)"><playerName></font>?`,
                `Anything more, <font color="rgb(255, 231, 94)"><playerName></font>?`
            },
            options = "menu_options",
        },
        sell_all_result = {
            fncText = "sellAllLoot",
            next = "repeat_menu",
            post = { { type = "delay", duration = 3 } },
            fncResponse = {
                success = {
                    `You sold <font color="rgb(25, 255, 25)">($itemsSold)</font> items for a total of <font color="rgb(25, 255, 25)">($totalEarned)</font> coins.</font>`,
                    `I count <font color="rgb(25, 255, 25)">($itemsSold)</font> things, for <font color="rgb(25, 255, 25)">($totalEarned)</font> coins. Pleasure doing business with you!`,
                },
                invalid = {
                    `Looks like you don't have any loot to sell.`,
                    `Would you like to go out and find some more?`,
                    `Come back when you have something to sell.`,
                },
            }
        },
        sell_result = {
            fncText = "sellThis",
            next = "repeat_menu",
            post = { { type = "delay", duration = 3 } },
            fncResponse = {
                success = {
                    `Pleasure doing business with you! Here's <font color="rgb(25, 255, 25)">($sellPrice)</font> coins for your <font color="rgb(255, 255, 0)">($lootName)</font>.`,
                    `Beautiful <font color="rgb(255, 255, 0)">($lootName)</font> you got there! Here's <font color="rgb(25, 255, 25)">($sellPrice)</font> coins for it.`,
                },
                geode = {
                    `You'd be better off crackin' that sucker open instead.`,
                    `Don't you want to know what's inside? Go crack it open!`,
                },
                invalid = {
                    `Hmm, that one's locked. I can't buy locked items.`,
                    `You need to unlock it first before I can buy it.`,
                },
                null = {
                    `Looks like you forgot to hold something up for me to see.`,
                    `I need to <i>actually see it</i> to be able to give you coin for it.`,
                },
            }
        },
        appraise_result = {
            fncText = "appraiseThis",
            next = "repeat_menu",
            post = { { type = "delay", duration = 3 } },
            fncResponse = {
                success = {
                    `That's a <font color="rgb(255, 255, 0)">($lootName)</font>, looks to be about <font color="rgb(25, 255, 25)">($lootWeight)kg</font>. I could give you <font color="rgb(25, 255, 25)">($sellPrice)</font> coins for it.`,
                    `A fine specimen of <font color="rgb(255, 255, 0)">($lootName)</font> you have there. It's about <font color="rgb(25, 255, 25)">($lootWeight)kg</font>, I could give you <font color="rgb(25, 255, 25)">($sellPrice)</font> coins for it.`,
                },
                invalid = {
                    `This isn't something I'm willing to buy.`,
                    `Quite a nice item, but I don't deal with these kinds of things.`,
                },
                null = {
                    `You need to hold up the item you want me to appraise.`,
                    `I can't appraise something I can't see! Hold it up for me.`,
                },
            }
        },
        saidhello = {
            text = "Ah, Quester sent you, did they? He's a fart smeller ... I mean a smart feller.",
            post = {
                { type = "delay", duration = 2 },
            },
            next = "menu",
        },

        exit = {
            text = 'Safe travels, <font color="rgb(255, 231, 94)"><playerName></font>. May your path be clear and your gems plentiful.',
            post = { { type = "close" } },
        },
    },

    option_sets = {
        menu_options = {
            {
                id = "sell_all",
                optionText = "Sell all my loot",
                bubbleText = "I'd like to sell all my gems.",
                next = "sell_all_result",
            },
            {
                id = "sell_this",
                optionText = "Sell this item",
                bubbleText = "I'd like to sell this item.",
                next = "sell_result",
            },
            {
                id = "appraise",
                optionText = "How much is this worth?",
                bubbleText = "I'd like to appraise this item.",
                next = "appraise_result",
            },
            {
                id = "imrich",
                optionText = "I'm rich.",
                bubbleText = "I'm so rich!",
                next = "repeat_menu",
                displayLogic = {
                    {
                        conditions = {
                            completed_quests = {"become_rich"}
                        },
                        result = true,
                    },
                    {
                        result = false,
                    }
                }
            },
            {
                id = "sayhello",
                optionText = "Quester sent me.",
                bubbleText = "Quester wanted me to say hello.",
                next = "saidhello",
                displayLogic = {
                    {
                        conditions = {
                            hasQuestAtNode = "TestQuest/testSpeakTo"
                        },
                        result = true,
                    },
                    {
                        result = false,
                    }
                }
            },
            {
                id = "bye",
                optionText = "Nothing for now.",
                bubbleText = "That's all for now.",
                next = "exit",
            },
        }
    },
}