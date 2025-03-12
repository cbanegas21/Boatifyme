-- ===================================================================
-- Completely rebuild the database from scratch
-- (WARNING: This will DROP the database if it exists, losing all data.)
-- ===================================================================

DROP DATABASE IF EXISTS boatifyme_db;
CREATE DATABASE boatifyme_db;
USE boatifyme_db;

-- Temporarily disable FK checks so we can create tables in any order
SET FOREIGN_KEY_CHECKS = 0;

-- ===================================================================
-- USERS TABLE
-- ===================================================================
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    user_type VARCHAR(20) CHECK (user_type IN ('owner','renter')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ===================================================================
-- ROLES TABLE
-- ===================================================================
CREATE TABLE roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL
) ENGINE=InnoDB;

-- ===================================================================
-- USERS_ROLES TABLE
-- Many-to-many link between users and roles
-- ===================================================================
CREATE TABLE users_roles (
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_users_roles_user
        FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_users_roles_role
        FOREIGN KEY (role_id) REFERENCES roles(role_id)
) ENGINE=InnoDB;

-- ===================================================================
-- ROLES_PERMISSIONS TABLE
-- Assign permissions to roles
-- ===================================================================
CREATE TABLE roles_permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    role_id INT NOT NULL,
    permission VARCHAR(50) NOT NULL,
    CONSTRAINT fk_roles_permissions_role
        FOREIGN KEY (role_id) REFERENCES roles(role_id)
) ENGINE=InnoDB;

-- ===================================================================
-- BOATS TABLE
-- Removed location_id, added address/city/state/country/lat/long
-- ===================================================================
CREATE TABLE boats (
    boat_id INT AUTO_INCREMENT PRIMARY KEY,
    owner_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    boat_type VARCHAR(50),
    capacity INT,
    base_price DECIMAL(10,2),
    currency VARCHAR(10),
    -- Inlined location fields:
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_boats_owner
        FOREIGN KEY (owner_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- ===================================================================
-- BOAT_IMAGES TABLE
-- ===================================================================
CREATE TABLE boat_images (
    image_id INT AUTO_INCREMENT PRIMARY KEY,
    boat_id INT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    caption VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_boat_images_boat
        FOREIGN KEY (boat_id) REFERENCES boats(boat_id)
) ENGINE=InnoDB;

-- ===================================================================
-- AVAILABILITY_BOATS TABLE
-- ===================================================================
CREATE TABLE availability_boats (
    availability_id INT AUTO_INCREMENT PRIMARY KEY,
    boat_id INT NOT NULL,
    available_from TIMESTAMP NOT NULL,
    available_to TIMESTAMP NOT NULL,
    status VARCHAR(20) CHECK (status IN ('available','booked','maintenance')),
    CONSTRAINT fk_availability_boats_boat
        FOREIGN KEY (boat_id) REFERENCES boats(boat_id)
) ENGINE=InnoDB;

-- ===================================================================
-- RESERVATIONS TABLE
-- ===================================================================
CREATE TABLE reservations (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    boat_id INT NOT NULL,
    renter_id INT NOT NULL,
    reservation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) CHECK (status IN ('pending','confirmed','cancelled','completed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_reservations_boat
        FOREIGN KEY (boat_id) REFERENCES boats(boat_id),
    CONSTRAINT fk_reservations_renter
        FOREIGN KEY (renter_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- ===================================================================
-- DETAILS_RESERVATIONS TABLE
-- Additional data (add-ons, pricing breakdown, etc.)
-- ===================================================================
CREATE TABLE details_reservations (
    detail_id INT AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT NOT NULL,
    add_ons JSON,
    total_price DECIMAL(10,2),
    discount_applied DECIMAL(10,2),
    final_price DECIMAL(10,2),
    payment_status VARCHAR(20) CHECK (payment_status IN ('pending','paid','refunded')),
    CONSTRAINT fk_details_reservations_res
        FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id)
) ENGINE=InnoDB;

-- ===================================================================
-- PAYOUTS_CLIENTS TABLE
-- ===================================================================
CREATE TABLE payouts_clients (
    payout_client_id INT AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT NOT NULL,
    client_id INT NOT NULL,
    amount DECIMAL(10,2),
    payout_date TIMESTAMP,
    status VARCHAR(20) CHECK (status IN ('pending','completed','failed')),
    CONSTRAINT fk_payouts_clients_res
        FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id),
    CONSTRAINT fk_payouts_clients_user
        FOREIGN KEY (client_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- ===================================================================
-- PAYMENT_METHODS TABLE
-- ===================================================================
CREATE TABLE payment_methods (
    payment_method_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    card_number VARCHAR(255),
    card_expiry DATE,
    card_type VARCHAR(50),
    billing_address VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_payment_methods_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- ===================================================================
-- PAYOUTS_OWNERS TABLE
-- ===================================================================
CREATE TABLE payouts_owners (
    payout_owner_id INT AUTO_INCREMENT PRIMARY KEY,
    boat_id INT NOT NULL,
    owner_id INT NOT NULL,
    amount DECIMAL(10,2),
    payout_date TIMESTAMP,
    status VARCHAR(20) CHECK (status IN ('pending','completed','failed')),
    CONSTRAINT fk_payouts_owners_boat
        FOREIGN KEY (boat_id) REFERENCES boats(boat_id),
    CONSTRAINT fk_payouts_owners_user
        FOREIGN KEY (owner_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- ===================================================================
-- INVOICE TABLE
-- ===================================================================
CREATE TABLE invoice (
    invoice_id INT AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT NOT NULL,
    issued_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2),
    tax DECIMAL(10,2),
    discount DECIMAL(10,2),
    final_amount DECIMAL(10,2),
    invoice_pdf_url VARCHAR(255),
    CONSTRAINT fk_invoice_res
        FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id)
) ENGINE=InnoDB;

-- ===================================================================
-- CLIENT_REVIEWS TABLE
-- ===================================================================
CREATE TABLE client_reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT NOT NULL,
    client_id INT NOT NULL,
    boat_id INT NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_client_reviews_res
        FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id),
    CONSTRAINT fk_client_reviews_client
        FOREIGN KEY (client_id) REFERENCES users(user_id),
    CONSTRAINT fk_client_reviews_boat
        FOREIGN KEY (boat_id) REFERENCES boats(boat_id)
) ENGINE=InnoDB;

-- ===================================================================
-- OWNER_REVIEWS TABLE
-- ===================================================================
CREATE TABLE owner_reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT NOT NULL,
    owner_id INT NOT NULL,
    client_id INT NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_owner_reviews_res
        FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id),
    CONSTRAINT fk_owner_reviews_owner
        FOREIGN KEY (owner_id) REFERENCES users(user_id),
    CONSTRAINT fk_owner_reviews_client
        FOREIGN KEY (client_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- ===================================================================
-- NOTIFICATIONS TABLE
-- ===================================================================
CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    message TEXT,
    notification_type VARCHAR(50),
    status VARCHAR(20) CHECK (status IN ('unread','read')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notifications_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- ===================================================================
-- TICKET_LOGS TABLE
-- ===================================================================
CREATE TABLE ticket_logs (
    ticket_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    subject VARCHAR(255),
    description TEXT,
    status VARCHAR(20) CHECK (status IN ('open','in_progress','resolved','closed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_ticket_logs_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- ===================================================================
-- BOAT_AMENITIES TABLE
-- ===================================================================
CREATE TABLE boat_amenities (
    amenity_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

-- ===================================================================
-- BOAT_AMENITIES_MAPPING TABLE
-- Many-to-many link between boats and amenities
-- ===================================================================
CREATE TABLE boat_amenities_mapping (
    boat_id INT NOT NULL,
    amenity_id INT NOT NULL,
    PRIMARY KEY (boat_id, amenity_id),
    CONSTRAINT fk_boat_amenities_mapping_boat
        FOREIGN KEY (boat_id) REFERENCES boats(boat_id),
    CONSTRAINT fk_boat_amenities_mapping_amenity
        FOREIGN KEY (amenity_id) REFERENCES boat_amenities(amenity_id)
) ENGINE=InnoDB;

-- ===================================================================
-- CANCELLATION_POLICIES TABLE
-- ===================================================================
CREATE TABLE cancellation_policies (
    policy_id INT AUTO_INCREMENT PRIMARY KEY,
    boat_id INT NOT NULL,
    cancellation_window INT,
    penalty_percentage DECIMAL(5,2),
    description TEXT,
    CONSTRAINT fk_cancellation_policies_boat
        FOREIGN KEY (boat_id) REFERENCES boats(boat_id)
) ENGINE=InnoDB;

-- ===================================================================
-- ADDONS TABLE
-- ===================================================================
CREATE TABLE addons (
    addon_id INT AUTO_INCREMENT PRIMARY KEY,
    boat_id INT NOT NULL,
    name VARCHAR(100),
    description TEXT,
    price DECIMAL(10,2),
    available BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_addons_boat
        FOREIGN KEY (boat_id) REFERENCES boats(boat_id)
) ENGINE=InnoDB;

-- ===================================================================
-- PROMOTIONS TABLE
-- ===================================================================
CREATE TABLE promotions (
    promotion_id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    discount_percentage DECIMAL(5,2),
    fixed_discount DECIMAL(10,2),
    valid_from DATE,
    valid_to DATE,
    usage_limit INT,
    status VARCHAR(20) CHECK (status IN ('active','expired'))
) ENGINE=InnoDB;

-- ===================================================================
-- AUDIT_LOGS TABLE
-- ===================================================================
CREATE TABLE audit_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    action VARCHAR(255),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_logs_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- ===================================================================
-- STRIPE_EVENTS TABLE
-- Typically used for storing webhook payloads from Stripe
-- ===================================================================
CREATE TABLE stripe_events (
    stripe_event_id VARCHAR(100) PRIMARY KEY,
    event_type VARCHAR(100),
    payload JSON,
    received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE
) ENGINE=InnoDB;

-- ===================================================================
-- COMMUNICATION_LOGS TABLE
-- For emails, SMS, or push notifications sent out
-- ===================================================================
CREATE TABLE communication_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    communication_type VARCHAR(20) CHECK (communication_type IN ('email','SMS','push')),
    recipient VARCHAR(255),
    message_body TEXT,
    status VARCHAR(20),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_communication_logs_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- ===================================================================
-- CALENDAR_EVENTS TABLE
-- For scheduling or external calendar sync
-- ===================================================================
CREATE TABLE calendar_events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    boat_id INT NOT NULL,
    title VARCHAR(255),
    start_datetime TIMESTAMP,
    end_datetime TIMESTAMP,
    event_type VARCHAR(50),
    external_calendar_id VARCHAR(100),
    CONSTRAINT fk_calendar_events_boat
        FOREIGN KEY (boat_id) REFERENCES boats(boat_id)
) ENGINE=InnoDB;

-- ===================================================================
-- USER_DEVICES TABLE
-- Storing user device tokens for push notifications
-- ===================================================================
CREATE TABLE user_devices (
    device_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    device_token VARCHAR(255),
    platform VARCHAR(20) CHECK (platform IN ('Android','iOS')),
    last_active_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_devices_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- ===================================================================
-- WEBHOOKS TABLE
-- For logging generic inbound webhooks from other services
-- ===================================================================
CREATE TABLE webhooks (
    webhook_id INT AUTO_INCREMENT PRIMARY KEY,
    source VARCHAR(100),
    event_type VARCHAR(100),
    payload JSON,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_status BOOLEAN DEFAULT FALSE
) ENGINE=InnoDB;

-- ===================================================================
-- INTEGRATION_TOKENS TABLE
-- Storing API keys for external integrations
-- ===================================================================
CREATE TABLE integration_tokens (
    integration_id INT AUTO_INCREMENT PRIMARY KEY,
    service_name VARCHAR(100),
    api_key VARCHAR(255),
    secret VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
) ENGINE=InnoDB;

-- ===================================================================
-- FAVORITES TABLE
-- Users can "favorite" or bookmark certain boats
-- ===================================================================
CREATE TABLE favorites (
    favorite_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    boat_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_favorites_user
        FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_favorites_boat
        FOREIGN KEY (boat_id) REFERENCES boats(boat_id)
) ENGINE=InnoDB;

-- ===================================================================
-- MESSAGES TABLE
-- Private messaging between users (owner <-> renter)
-- ===================================================================
CREATE TABLE messages (
    message_id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    reservation_id INT,
    message_body TEXT,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_status BOOLEAN DEFAULT FALSE,
    CONSTRAINT fk_messages_sender
        FOREIGN KEY (sender_id) REFERENCES users(user_id),
    CONSTRAINT fk_messages_receiver
        FOREIGN KEY (receiver_id) REFERENCES users(user_id),
    CONSTRAINT fk_messages_res
        FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id)
) ENGINE=InnoDB;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;
