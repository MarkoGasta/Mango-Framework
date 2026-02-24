return {
    DEFAULT_PRIORITY = 10,
    CONSTRUCTED_FLAG = "__IsConstructed",
    CONSTRUCTION_METHOD = "__Construct",
    INITIALIZATION_METHOD = "__Init",

    CONTROLLER_PRIORITIES = {
        GameController = 99,
        DataController = 9,
        RemoteController = 1,
    },
    SERVICE_PRIORITIES = {
        GameService = 99,
        DataService = 9,
        RemoteService = 1,
    },
}