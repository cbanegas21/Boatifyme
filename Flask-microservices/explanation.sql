-- ===================================================================
-- 1) Create or use your desired database:
-- ===================================================================
/*
  We create (or ensure) a database named 'boatifyme_db'.
  Then we switch context to it so all tables go under this schema.
*/
CREATE DATABASE IF NOT EXISTS boatifyme_db;
USE boatifyme_db;

-- ===================================================================
-- 2) USERS TABLE
-- ===================================================================
/*
  Holds core user data (both 'owner' and 'renter').
  - user_id: primary key, auto-increment.
  - email: unique for authentication.
  - password_hash: where you store a hashed password.
  - user_type: either 'owner' or 'renter' (example constraint).
  - created_at/updated_at: timestamps for auditing.
  Typical CRUD: Sign up, retrieve profile, update info, possibly delete.
*/
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
);

-- ===================================================================
-- 3) LOCATIONS TABLE
-- ===================================================================
/*
  Represents marinas, harbors, or geographic spots.
  - location_id: primary key.
  - name/address/city/etc.: optional fields to store location data.
  - latitude/longitude: for mapping or search by coordinates.
  Typical CRUD: Admin (or system) can create new locations, 
                read them, update if addresses change, or remove old ones.
*/
CREATE TABLE locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6)
);

-- ===================================================================
-- 4) BOATS TABLE
-- ===================================================================
/*
  Main listing entity for boats.
  - owner_id: references 'users' table for the boat's owner.
  - location_id: references 'locations' for docking place or home port.
  - base_price/currency: cost details for rentals.
  Typical CRUD: Boat owners can create boat listings, 
                read them for public search, update listing details, 
                delete if no longer renting.
*/
CREATE TABLE boats (
    boat_id INT AUTO_INCREMENT PRIMARY KEY,
    owner_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    boat_type VARCHAR(50),
    capacity INT,
    base_price DECIMAL(10,2),
    currency VARCHAR(10),
    location_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(user_id),
    FOREIGN KEY (location_id) REFERENCES locations(location_id)
);

-- ===================================================================
-- 5) BOAT_IMAGES TABLE
-- ===================================================================
/*
  Stores multiple images for a given boat.
  - boat_id: references 'boats'.
  - image_url: URL/path to the uploaded image.
  - caption: short description or label for the image.
  Typical CRUD: Create new images, read/display them, update captions, delete old ones.
*/
CREATE TABLE boat_images (
    image_id INT AUTO_INCREMENT PRIMARY KEY,
    boat_id INT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    caption VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (boat_id) REFERENCES boats(boat_id)
);

-- ===================================================================
-- 6) AVAILABILITY_BOATS TABLE
-- ===================================================================
/*
  Tracks date ranges for boat availability or maintenance.
  - boat_id: references 'boats'.
  - status: can be 'available', 'booked', or 'maintenance'.
  Typical CRUD: Owners create/update availability windows, 
                renters see them, system sets status to 'booked' upon reservation.
*/
CREATE TABLE availability_boats (
    availability_id INT AUTO_INCREMENT PRIMARY KEY,
    boat_id INT NOT NULL,
    available_from TIMESTAMP NOT NULL,
    available_to TIMESTAMP NOT NULL,
    status VARCHAR(20) CHECK (status IN ('available','booked','maintenance')),
    FOREIGN KEY (boat_id) REFERENCES boats(boat_id)
);

-- ===================================================================
-- 7) RESERVATIONS TABLE
-- ===================================================================
/*
  Represents bookings made by renters.
  - boat_id: references the boat being rented.
  - renter_id: references 'users' as the renter.
  - status: can be 'pending','confirmed','cancelled','completed'.
  - start_date/end_date: actual rental duration.
  Typical CRUD: Renter creates a reservation, system updates status, 
                read reservation details, possibly cancel (delete or update status).
*/
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
    FOREIGN KEY (boat_id) REFERENCES boats(boat_id),
    FOREIGN KEY (renter_id) REFERENCES users(user_id)
);

-- ===================================================================
-- 8) DETAILS_RESERVATIONS TABLE
-- ===================================================================
/*
  Holds extra info for a reservation, like add-ons, final pricing, etc.
  - reservation_id: references 'reservations'.
  - add_ons (JSON): flexible field for listing chosen add-ons.
  - total_price/final_price: track cost breakdown.
  - payment_status: 'pending','paid','refunded'.
  Typical CRUD: Usually created automatically with a reservation, 
                updated if add-ons change or discount applies, 
                rarely deleted unless the reservation is removed entirely.
*/
CREATE TABLE details_reservations (
    detail_id INT AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT NOT NULL,
    add_ons JSON,
    total_price DECIMAL(10,2),
    discount_applied DECIMAL(10,2),
    final_price DECIMAL(10,2),
    payment_status VARCHAR(20) CHECK (payment_status IN ('pending','paid','refunded')),
    FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id)
);

-- ===================================================================
-- 9) CANCELLATION_POLICIES TABLE
-- ===================================================================
/*
  Each boat can have a custom cancellation policy.
  - cancellation_window: number of days before start_date for free cancellation.
  - penalty_percentage: how much the renter pays if canceling late.
  Typical CRUD: Owners or admins create/update for a boat. 
                Rarely deleted unless policy is replaced.
*/
CREATE TABLE cancellation_policies (
    policy_id INT AUTO_INCREMENT PRIMARY KEY,
    boat_id INT NOT NULL,
    cancellation_window INT,
    penalty_percentage DECIMAL(5,2),
    description TEXT,
    FOREIGN KEY (boat_id) REFERENCES boats(boat_id)
);

-- ===================================================================
-- 10) ADDONS TABLE
-- ===================================================================
/*
  Represents extra services or items for a boat (e.g. skipper, catering).
  - boat_id: references 'boats'.
  - available: whether currently offered.
  Typical CRUD: Owners create add-ons, read them, update price, or delete if discontinued.
*/
CREATE TABLE addons (
    addon_id INT AUTO_INCREMENT PRIMARY KEY,
    boat_id INT NOT NULL,
    name VARCHAR(100),
    description TEXT,
    price DECIMAL(10,2),
    available BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (boat_id) REFERENCES boats(boat_id)
);

-- ===================================================================
-- 11) PROMOTIONS TABLE
-- ===================================================================
/*
  Stores discount codes or seasonal offers.
  - code: unique discount identifier.
  - discount_percentage/fixed_discount: handle flexible discount logic.
  - usage_limit: how many times it can be used.
  - status: 'active' or 'expired'.
  Typical CRUD: Admin/marketing create new promotions, read or apply them, 
                update (extend dates), or mark as expired.
*/
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
);

-- ===================================================================
-- 12) PAYMENT_METHODS TABLE
-- ===================================================================
/*
  Stores user's saved payment details.
  - user_id: references 'users'.
  - card_number: typically encrypted or tokenized in real-world apps.
  - created_at: track when added.
  Typical CRUD: Users create new payment methods, read them, update details, or delete.
*/
CREATE TABLE payment_methods (
    payment_method_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    card_number VARCHAR(255),
    card_expiry DATE,
    card_type VARCHAR(50),
    billing_address VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- ===================================================================
-- 13) CLIENT_REVIEWS TABLE
-- ===================================================================
/*
  Clients reviewing boats.
  - reservation_id: references 'reservations' for a completed trip.
  - rating: 1 to 5 star rating.
  - review_text: optional text feedback.
  Typical CRUD: Client creates review, read by others, might update or delete.
*/
CREATE TABLE client_reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT NOT NULL,
    client_id INT NOT NULL,
    boat_id INT NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id),
    FOREIGN KEY (client_id) REFERENCES users(user_id),
    FOREIGN KEY (boat_id) REFERENCES boats(boat_id)
);

-- ===================================================================
-- 14) OWNER_REVIEWS TABLE
-- ===================================================================
/*
  Owners reviewing renters.
  - Helps other owners gauge renter reliability.
  - rating: 1 to 5 star rating.
  Typical CRUD: Owner creates review post-reservation, read by future owners, 
                might update or delete. 
*/
CREATE TABLE owner_reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT NOT NULL,
    owner_id INT NOT NULL,
    client_id INT NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id),
    FOREIGN KEY (owner_id) REFERENCES users(user_id),
    FOREIGN KEY (client_id) REFERENCES users(user_id)
);

-- ===================================================================
-- 15) FAVORITES TABLE
-- ===================================================================
/*
  Users can "favorite" or bookmark boats for quick access later.
  - user_id: references 'users'.
  - boat_id: references 'boats'.
  Typical CRUD: User creates a favorite, reads their favorites, 
                rarely updates (?), or deletes if they unfavorite.
*/
CREATE TABLE favorites (
    favorite_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    boat_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (boat_id) REFERENCES boats(boat_id)
);

-- ===================================================================
-- 16) MESSAGES TABLE
-- ===================================================================
/*
  Private messaging between owners and renters, or user-user comms.
  - sender_id / receiver_id: both reference 'users'.
  - reservation_id: optional link if the conversation is about a booking.
  - read_status: to mark read/unread.
  Typical CRUD: create new messages, read them, update read status, delete old messages (maybe).
*/
CREATE TABLE messages (
    message_id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    reservation_id INT,
    message_body TEXT,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_status BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (sender_id) REFERENCES users(user_id),
    FOREIGN KEY (receiver_id) REFERENCES users(user_id),
    FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id)
);

-- ===================================================================
-- 17) NOTIFICATIONS TABLE
-- ===================================================================
/*
  System or user-triggered alerts (e.g., booking updates, payment reminders).
  - user_id: who receives the notification.
  - notification_type: e.g., booking, payment, system, etc.
  - status: 'unread' or 'read'.
  Typical CRUD: create notifications on events, read them, update status, 
                delete or auto-clear old notifications.
*/
CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    message TEXT,
    notification_type VARCHAR(50),
    status VARCHAR(20) CHECK (status IN ('unread','read')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- ===================================================================
-- End of script
-- ===================================================================
/*
  This script creates the 16 core CRUD tables needed for the boat-rental platform.
  Adjust foreign key constraints, indexing, and InnoDB engine as needed for production.
  Also consider using encryption or hashing at the application layer for sensitive fields.
*/
