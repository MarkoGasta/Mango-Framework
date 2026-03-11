-- Indexed from: X:\Projects\Roblox Repos\Mango Framework v2\src\ServerStorage\Services
-- Indexed from: X:\Projects\Roblox Repos\Mango Framework v2\src\ServerStorage\Resources
-- Indexed from: X:\Projects\Roblox Repos\Mango Framework v2\src\ReplicatedStorage\Settings
-- Indexed from: X:\Projects\Roblox Repos\Mango Framework v2\src\ReplicatedStorage\Resources\Shared

export type ModuleNames = "GameService" | "RuntimeSettings"
export type Modules = (("GameService") -> (typeof(require(game.ServerStorage.Services.GameService)))) & (("RuntimeSettings") -> (typeof(require(game.ReplicatedStorage.Settings.RuntimeSettings))))

return {}
