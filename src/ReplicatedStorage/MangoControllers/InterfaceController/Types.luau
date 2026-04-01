-- Indexed from: X:\Projects\Roblox Repos\Mango Framework v2\src\ReplicatedStorage\MangoControllers\InterfaceController\InterfaceHandlers
-- Indexed from: X:\Projects\Roblox Repos\Mango Framework v2\src\ReplicatedStorage\MangoControllers\InterfaceController\InterfaceHelpers
-- Indexed from: X:\Projects\Roblox Repos\Mango Framework v2\src\ReplicatedStorage\MangoControllers\InterfaceController\MangoInterfaceHelpers

export type ModuleNames = "TemplateInterface" | "TemplateHelper" | "DynamicScaling"
export type Modules = (("TemplateInterface") -> (typeof(require(game.ReplicatedStorage.MangoControllers.InterfaceController.InterfaceHandlers.TemplateInterface)))) & (("TemplateHelper") -> (typeof(require(game.ReplicatedStorage.MangoControllers.InterfaceController.InterfaceHelpers.TemplateHelper)))) & (("DynamicScaling") -> (typeof(require(game.ReplicatedStorage.MangoControllers.InterfaceController.MangoInterfaceHelpers.DynamicScaling))))

return {}
