CREATE TABLE IF NOT EXISTS `trucking_progression` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(255) UNIQUE NOT NULL,
    `level` INT DEFAULT 1,
    `xp` INT DEFAULT 0,
    `total_xp` INT DEFAULT 0,
    `jobs_completed` INT DEFAULT 0,
    `distance_traveled` INT DEFAULT 0,
    `money_earned` INT DEFAULT 0,
    `skill_distance_driving` INT DEFAULT 0,
    `skill_fragile_handling` INT DEFAULT 0,
    `skill_speed_efficiency` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS `trucking_jobs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(255) NOT NULL,
    `job_type` VARCHAR(50) NOT NULL,
    `distance` INT DEFAULT 0,
    `payment` INT DEFAULT 0,
    `xp_earned` INT DEFAULT 0,
    `was_damaged` BOOLEAN DEFAULT FALSE,
    `damage_percent` INT DEFAULT 0,
    `was_late` BOOLEAN DEFAULT FALSE,
    `time_taken` INT DEFAULT 0,
    `vehicle_used` VARCHAR(50),
    `completed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `identifier_idx` (`identifier`),
    INDEX `job_type_idx` (`job_type`),
    INDEX `completed_at_idx` (`completed_at`)
);

CREATE TABLE IF NOT EXISTS `trucking_vehicles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(255) NOT NULL,
    `vehicle_type` VARCHAR(50) NOT NULL,
    `fuel` INT DEFAULT 100,
    `health` INT DEFAULT 1000,
    `plate` VARCHAR(20) UNIQUE,
    `purchased_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `identifier_idx` (`identifier`)
);
