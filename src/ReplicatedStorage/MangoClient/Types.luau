-- Indexed from: X:\Projects\Roblox Repos\Mango Framework v2\src\ReplicatedStorage\Controllers
-- Indexed from: X:\Projects\Roblox Repos\Mango Framework v2\src\ReplicatedStorage\Settings
-- Indexed from: X:\Projects\Roblox Repos\Mango Framework v2\src\ReplicatedStorage\Resources

export type ModuleNames = "GameController" | "RuntimeSettings"
export type Modules = (("GameController") -> (typeof(require(game.ReplicatedStorage.Controllers.GameController)))) & (("RuntimeSettings") -> (typeof(require(game.ReplicatedStorage.Settings.RuntimeSettings))))

return {}
