CREATE DATABASE IF NOT EXISTS wedapola CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE wedapola;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    google_user_id VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50) UNIQUE,
    role ENUM('CUSTOMER', 'TECHNICIAN', 'ADMIN') NOT NULL DEFAULT 'CUSTOMER',
    status ENUM('ACTIVE', 'SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS customer_profiles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    avatar_url VARCHAR(255),
    rating DECIMAL(3, 2) DEFAULT 5.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS technician_profiles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    bio TEXT,
    verification_status ENUM('PENDING', 'BASIC_VERIFIED', 'TRUSTED', 'PRO', 'REJECTED', 'SUSPENDED') NOT NULL DEFAULT 'PENDING',
    nic_number VARCHAR(20),
    nic_front_key VARCHAR(255),
    nic_back_key VARCHAR(255),
    selfie_key VARCHAR(255),
    address_proof_key VARCHAR(255),
    nvq_cert_key VARCHAR(255),
    police_report_status ENUM('NOT_SUBMITTED', 'RECEIPT_SUBMITTED', 'VERIFIED') DEFAULT 'NOT_SUBMITTED',
    police_report_key VARCHAR(255),
    guarantor_name VARCHAR(255),
    guarantor_phone VARCHAR(50),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    service_radius INT DEFAULT 15,
    rating DECIMAL(3, 2) DEFAULT 0.00,
    total_reviews INT DEFAULT 0,
    completed_jobs_count INT DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS worker_devices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    worker_id INT NOT NULL,
    fcm_token VARCHAR(255) NOT NULL UNIQUE,
    device_type ENUM('ANDROID', 'IOS', 'WEB') DEFAULT 'ANDROID',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (worker_id) REFERENCES technician_profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS service_categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    group_name_en VARCHAR(255) NOT NULL,
    group_name_si VARCHAR(255) NOT NULL,
    name_en VARCHAR(255) NOT NULL,
    name_si VARCHAR(255) NOT NULL,
    icon VARCHAR(255),
    requires_pro_badge BOOLEAN DEFAULT FALSE,
    display_order INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS technician_services (
    technician_id INT NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (technician_id, category_id),
    FOREIGN KEY (technician_id) REFERENCES technician_profiles(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES service_categories(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS service_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    category_id INT NOT NULL,
    description TEXT NOT NULL,
    status ENUM('REQUESTED', 'QUOTED', 'ACCEPTED', 'TECHNICIAN_ON_THE_WAY', 'ARRIVED', 'IN_PROGRESS', 'COMPLETED', 'CUSTOMER_CONFIRMED', 'REVIEWED', 'CANCELLED', 'DISPUTED') NOT NULL DEFAULT 'REQUESTED',
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    urgency ENUM('LOW', 'MEDIUM', 'HIGH', 'EMERGENCY') NOT NULL DEFAULT 'MEDIUM',
    preferred_time DATETIME,
    equipment_provided BOOLEAN DEFAULT FALSE, -- Customer has equipment vs worker must bring tools
    near_hazard BOOLEAN DEFAULT FALSE,        -- Near power lines or fragile roof
    target_technician_id INT NULL,            -- Direct invite worker ID (with head start)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customer_profiles(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES service_categories(id),
    FOREIGN KEY (target_technician_id) REFERENCES technician_profiles(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS quotes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL,
    technician_id INT NOT NULL,
    labor_cost DECIMAL(10, 2) NOT NULL,
    material_cost DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    total DECIMAL(10, 2) NOT NULL,
    description TEXT,
    estimated_duration_hours INT,
    available_time DATETIME,
    is_final_locked BOOLEAN DEFAULT TRUE,
    status ENUM('PENDING', 'ACCEPTED', 'REJECTED') NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (request_id) REFERENCES service_requests(id) ON DELETE CASCADE,
    FOREIGN KEY (technician_id) REFERENCES technician_profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS jobs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL,
    quote_id INT NOT NULL,
    technician_id INT NOT NULL,
    customer_id INT NOT NULL,
    status ENUM('ACCEPTED', 'TECHNICIAN_ON_THE_WAY', 'ARRIVED', 'IN_PROGRESS', 'COMPLETED', 'CUSTOMER_CONFIRMED', 'REVIEWED', 'CANCELLED', 'DISPUTED') NOT NULL DEFAULT 'ACCEPTED',
    start_pin VARCHAR(6),
    before_photo_key VARCHAR(255),
    after_photo_key VARCHAR(255),
    scheduled_time DATETIME,
    started_time DATETIME,
    completed_time DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (request_id) REFERENCES service_requests(id) ON DELETE CASCADE,
    FOREIGN KEY (quote_id) REFERENCES quotes(id),
    FOREIGN KEY (technician_id) REFERENCES technician_profiles(id),
    FOREIGN KEY (customer_id) REFERENCES customer_profiles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS job_status_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    job_id INT NOT NULL,
    status ENUM('ACCEPTED', 'TECHNICIAN_ON_THE_WAY', 'ARRIVED', 'IN_PROGRESS', 'COMPLETED', 'CUSTOMER_CONFIRMED', 'REVIEWED', 'CANCELLED', 'DISPUTED') NOT NULL,
    notes TEXT,
    changed_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    job_id INT NOT NULL,
    reviewer_role ENUM('CUSTOMER', 'TECHNICIAN') NOT NULL DEFAULT 'CUSTOMER',
    reviewer_id INT NOT NULL,
    target_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    behavior_tags JSON,
    comment TEXT,
    status ENUM('PUBLISHED', 'QUARANTINED', 'DISPUTED') NOT NULL DEFAULT 'PUBLISHED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE,
    FOREIGN KEY (reviewer_id) REFERENCES users(id),
    FOREIGN KEY (target_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS storage_files (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner_id INT NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INT,
    storage_provider VARCHAR(50) NOT NULL DEFAULT 'local',
    storage_key VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255),
    mime_type VARCHAR(100),
    file_size INT,
    visibility ENUM('PUBLIC', 'PRIVATE') NOT NULL DEFAULT 'PRIVATE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    channel ENUM('PUSH', 'WHATSAPP', 'SMS', 'IN_APP') NOT NULL DEFAULT 'IN_APP',
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    payload JSON,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Initial Seed Data: Sri Lankan Localization & Service Taxonomy
INSERT INTO service_categories (group_name_en, group_name_si, name_en, name_si, icon, requires_pro_badge, display_order) VALUES
-- 1. Garden, Tree & Estate Work
('Garden, Tree & Estate Work', 'ගෙවතු, ගස් කැපීම සහ වතු පිටි නඩත්තුව', 'Tree Pruning & Felling', 'ගස් වල අතු කැපීම සහ ගස් කැපීම', 'park', FALSE, 1),
('Garden, Tree & Estate Work', 'ගෙවතු, ගස් කැපීම සහ වතු පිටි නඩත්තුව', 'Grass Cutting & Lawn Care', 'තණකොළ කැපීම සහ ගෙවතු පිරිසිදු කිරීම', 'grass', FALSE, 2),
('Garden, Tree & Estate Work', 'ගෙවතු, ගස් කැපීම සහ වතු පිටි නඩත්තුව', 'Coconut Plucking & Estate Care', 'පොල් කැඩීම සහ පොල් වතු නඩත්තුව', 'nature', FALSE, 3),
('Garden, Tree & Estate Work', 'ගෙවතු, ගස් කැපීම සහ වතු පිටි නඩත්තුව', 'Landscaping & Drainage', 'ගෙවතු අලංකරණය සහ කාණු සුද්ධ කිරීම', 'yard', FALSE, 4),

-- 2. Home & Commercial Cleaning
('Home & Commercial Cleaning', 'නිවෙස් සහ ව්‍යාපාරික ස්ථාන පිරිසිදු කිරීම', 'Deep House Cleaning', 'නිවෙස් ගැඹුරින් පිරිසිදු කිරීම', 'cleaning_services', FALSE, 5),
('Home & Commercial Cleaning', 'නිවෙස් සහ ව්‍යාපාරික ස්ථාන පිරිසිදු කිරීම', 'Sofa, Mattress & Carpet Shampooing', 'සෝෆා, මෙට්ට සහ කාපට් පිරිසිදු කිරීම', 'weekend', FALSE, 6),
('Home & Commercial Cleaning', 'නිවෙස් සහ ව්‍යාපාරික ස්ථාන පිරිසිදු කිරීම', 'Water Tank & Roof Cleaning', 'වතුර ටැංකි සහ වහල පිරිසිදු කිරීම', 'water_drop', FALSE, 7),
('Home & Commercial Cleaning', 'නිවෙස් සහ ව්‍යාපාරික ස්ථාන පිරිසිදු කිරීම', 'Post-Construction Cleaning', 'ඉදිකිරීම් වලින් පසු පිරිසිදු කිරීම', 'construction', FALSE, 8),

-- 3. Vehicle Repair & Mobile Auto Care
('Vehicle Repair & Mobile Auto Care', 'වාහන අලුත්වැඩියා සහ නඩත්තු', 'Mobile Mechanic / Breakdown Assistance', 'හදිසි වාහන අලුත්වැඩියාව', 'car_repair', TRUE, 9),
('Vehicle Repair & Mobile Auto Care', 'වාහන අලුත්වැඩියා සහ නඩත්තු', 'Battery Jumpstart & Replacement', 'බැටරි ආරෝපණය සහ මාරු කිරීම', 'battery_charging_full', FALSE, 10),
('Vehicle Repair & Mobile Auto Care', 'වාහන අලුත්වැඩියා සහ නඩත්තු', 'Tire Puncture & Wheel Services', 'ටයර් පැච් දැමීම සහ මාරු කිරීම', 'tire_repair', FALSE, 11),
('Vehicle Repair & Mobile Auto Care', 'වාහන අලුත්වැඩියා සහ නඩත්තු', 'Auto Electrical & AC', 'වාහන විදුලි කාර්මික සහ A/C', 'electric_car', TRUE, 12),
('Vehicle Repair & Mobile Auto Care', 'වාහන අලුත්වැඩියා සහ නඩත්තු', 'Home Car Wash & Interior Detailing', 'නිවසට පැමිණ වාහන සේදීම', 'local_car_wash', FALSE, 13),

-- 4. Core Technical Trades
('Core Technical Trades', 'ප්‍රධාන තාක්ෂණික ශිල්පීන්', 'Electrical & Wiring', 'විදුලි කාර්මික', 'electrical_services', TRUE, 14),
('Core Technical Trades', 'ප්‍රධාන තාක්ෂණික ශිල්පීන්', 'Plumbing & Water Pumps', 'ජලනල සහ වතුර පොම්ප', 'plumbing', FALSE, 15),
('Core Technical Trades', 'ප්‍රධාන තාක්ෂණික ශිල්පීන්', 'AC & Refrigeration', 'වායු සමීකරණ සහ ශීතකරණ', 'ac_unit', TRUE, 16),
('Core Technical Trades', 'ප්‍රධාන තාක්ෂණික ශිල්පීන්', 'Home Appliance Repair', 'ගෘහ විදුලි උපකරණ අලුත්වැඩියාව', 'home_repair_service', FALSE, 17),

-- 5. Construction, Wood & Metalwork
('Construction, Wood & Metalwork', 'ඉදිකිරීම්, වඩු සහ ලෝහ වැඩ', 'Masonry, Tiling & Waterproofing', 'පෙදරේරු, ටයිල් සහ වහල ලීක් වැසීම', 'foundation', FALSE, 18),
('Construction, Wood & Metalwork', 'ඉදිකිරීම්, වඩු සහ ලෝහ වැඩ', 'Carpentry & Aluminum', 'වඩු සහ ඇලුමිනියම් වැඩ', 'carpenter', FALSE, 19),
('Construction, Wood & Metalwork', 'ඉදිකිරීම්, වඩු සහ ලෝහ වැඩ', 'Painting & Polishing', 'පින්තාරු සහ පොලිෂ් වැඩ', 'format_paint', FALSE, 20),
('Construction, Wood & Metalwork', 'ඉදිකිරීම්, වඩු සහ ලෝහ වැඩ', 'Welding & Gate Repairs', 'වෑල්ඩින් සහ ගේට්ටු අලුත්වැඩියාව', 'hardware', FALSE, 21),

-- 6. General Labor & Moving Help
('General Labor & Moving Help', 'සාමාන්‍ය කම්කරු සහ බඩු ප්‍රවාහන සහාය', 'House Shifting & Heavy Lifting', 'නිවෙස් මාරු කිරීම සහ බඩු එසවීම', 'local_shipping', FALSE, 22),
('General Labor & Moving Help', 'සාමාන්‍ය කම්කරු සහ බඩු ප්‍රවාහන සහාය', 'General Handyman / Odd Jobs', 'සුළු අලුත්වැඩියා සහ විවිධ වැඩ', 'handyman', FALSE, 23);
