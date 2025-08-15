return {
	Icons = {
		[Enum.UserInputType.MouseButton1] = "rbxassetid://117700853912103",
		[Enum.UserInputType.MouseButton2] = "rbxassetid://139700294768718",
		[Enum.UserInputType.Touch] = "rbxassetid://76626894754524",
	},

	Inputs = {
		Pickaxe = {
			Keyboard = {
				Type = "UserInputType",
				Input = Enum.UserInputType.MouseButton1,
			},
			Mobile = {
				Type = "UserInputType",
				Input = Enum.UserInputType.Touch,
			},
			Gamepad = {
				Type = "KeyCode",
				Input = Enum.KeyCode.ButtonR2, -- Right Trigger
			},
		},

		Sieve = {
			Keyboard = {
				Type = "UserInputType",
				Input = Enum.UserInputType.MouseButton2,
			},

			-- Mobile handled by button

			Gamepad = {
				Type = "KeyCode",
				Input = Enum.KeyCode.ButtonB, -- Right-Diamond Right
			},
		},
	},
}
