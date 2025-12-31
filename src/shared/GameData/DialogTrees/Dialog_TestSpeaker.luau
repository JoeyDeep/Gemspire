return  {
    entry = "hello",

    nodes = {
        hello = {
            text = {
                `Dello there <font color="rgb(255, 231, 94)"><playerName></font>! Welcome to the world of Gemspire.`,
                `Ah, a fresh face! Gemspire's luck be with you, <font color="rgb(255, 231, 94)"><playerName></font>.`,
            },
            next = "menu",
        },

        menu = {
            text = "What would you like to know?",
            options = "menu_options"
        },

        about_world = {
            text = "Gemspire is stitched together by rifts and veins of power. Seek shrines, avoid the cracks—they stare back.",
            post = {
                { type = "giveItem", id = "LorePage01", amount = 1 },
            },
            next = "menu",
        },

        about_leveling = {
            text = "Train with the Sifters' Guild. Strength comes from rhythm: gather, craft, repeat.",
            post = {
                { type = "giveItem", id = "TrainingVoucher", amount = 1 },
            },
            next = "menu",
        },

        merchant_answer = {
            text = "The merchant can buy your stuff.",
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
                id = "world",
                optionText = "Tell me about Gemspire.",
                next = "about_world",
                post = { { type = "addCoins", amount = 1 } },
            },
            {
                id = "help",
                optionText = "How can I get stronger?",
                next = "about_leveling",
            },
            {
                id = "bye",
                optionText = "Nothing for now.",
                next = "exit",
            },
            {
                id = "merchant",
                optionText = "What do you think of the merchant?",
                bubbleText = "Do you know the merchant?",
                next = "merchant_answer",
                displayLogic = {
                    {
                        conditions = {
                            spoken_to = "TestMerchant"
                        },
                        result = true,
                    },
                    {
                        result = false,
                    }
                }
            },
        }
    }
}
