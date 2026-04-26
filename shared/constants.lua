Constants = {}

Constants.FRAMEWORK = {
    QBCORE = 'qbcore',
    QBX = 'qbx',
    ESX = 'esx',
    STANDALONE = 'standalone'
}

Constants.JOB_STATE = {
    IDLE = 'idle',
    ACCEPTED = 'accepted',
    IN_PROGRESS = 'in_progress',
    DELIVERING = 'delivering',
    COMPLETED = 'completed',
    CANCELLED = 'cancelled',
    FAILED = 'failed'
}

Constants.VEHICLE_STATE = {
    AVAILABLE = 'available',
    IN_USE = 'in_use',
    DAMAGED = 'damaged',
    OUT_OF_FUEL = 'out_of_fuel',
    MAINTENANCE = 'maintenance'
}

Constants.TRAILER_STATE = {
    DETACHED = 'detached',
    ATTACHING = 'attaching',
    ATTACHED = 'attached',
    DETACHING = 'detaching'
}

Constants.PAYMENT_TYPE = {
    CASH = 'cash',
    BANK = 'bank',
    DIRTY_MONEY = 'dirty_money'
}

Constants.NOTIFICATION = {
    SUCCESS = 'success',
    INFO = 'info',
    ERROR = 'error',
    WARNING = 'warning'
}

Constants.DAMAGE = {
    NONE = 0,
    LIGHT = 0.1,
    MODERATE = 0.25,
    HEAVY = 0.5,
    SEVERE = 1.0
}

Constants.SPEED_HACK = 150

Constants.TRUCK_MODELS = {
    phantom = 'phantom',
    hauler = 'hauler',
    biff = 'biff'
}

Constants.TRAILER_MODELS = {
    trailerlogs = 'trailerlogs',
    trailercarrier = 'trailercarrier',
    trailersmall = 'trailersmall'
}

Constants.EXPLOIT_FLAGS = {
    TELEPORT_DETECTED = 'teleport',
    SPEED_HACK = 'speed_hack',
    MONEY_DUPLICATION = 'money_dupe',
    DUPLICATE_JOB = 'duplicate_job',
    INVALID_DELIVERY = 'invalid_delivery'
}

return Constants
