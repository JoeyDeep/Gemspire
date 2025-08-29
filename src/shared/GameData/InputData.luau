return {
	Icons = {
		[Enum.UserInputType.MouseButton1] = "rbxassetid://117700853912103",
		[Enum.UserInputType.MouseButton2] = "rbxassetid://139700294768718",
		[Enum.UserInputType.Touch] = "rbxassetid://76626894754524",

		[Enum.KeyCode.E] = "rbxassetid://93714754759492",
		[Enum.KeyCode.G] = "rbxassetid://75764258051372",

		[Enum.KeyCode.ButtonA] = "rbxassetid://133270261665784",
		[Enum.KeyCode.ButtonX] = "rbxassetid://124728416407953",
		[Enum.KeyCode.ButtonR2] = "rbxassetid://87986095147448",
		[Enum.KeyCode.DPadUp] = "rbxassetid://135670239148826",
	},

	Inputs = {
		Backpack = {
			MouseKeyboard = {
				Type = "KeyCode",
				Input = Enum.KeyCode.G,
			},

			-- Mobile handled by UI button

			Gamepad = {
				Type = "KeyCode",
				Input = Enum.KeyCode.DPadUp,
			},
		},

		Pickaxe = {
			MouseKeyboard = {
				Type = "UserInputType",
				Input = Enum.UserInputType.MouseButton1,
			},
			Touch = {
				Type = "UserInputType",
				Input = Enum.UserInputType.Touch,
			},
			Gamepad = {
				Type = "KeyCode",
				Input = Enum.KeyCode.ButtonR2, -- Right Trigger
			},
		},

		Refine = {
			MouseKeyboard = {
				Type = "KeyCode",
				Input = Enum.KeyCode.E,
			},

			-- Mobile handled by UI button

			Gamepad = {
				Type = "KeyCode",
				Input = Enum.KeyCode.ButtonX,
			},
		},
		MalletSmash = {
			MouseKeyboard = {
				Type = "UserInputType",
				Input = Enum.UserInputType.MouseButton1,
			},

			Touch = {
				Type = "UserInputType",
				Input = Enum.UserInputType.Touch,
			},

			Gamepad = {
				Type = "KeyCode",
				Input = Enum.KeyCode.ButtonA,
			},
		},
	},
}
