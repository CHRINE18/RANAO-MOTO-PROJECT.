-- =====================================================
-- Ranao Moto: Web-Based ECU Tuning Service and Sales
-- Management System (MySQL 8 / MariaDB)
-- =====================================================

CREATE DATABASE IF NOT EXISTS ranao_moto
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ranao_moto;

-- ---------- Lookup / independent tables ----------

CREATE TABLE roles (
  role_id      INT AUTO_INCREMENT PRIMARY KEY,
  role_name    VARCHAR(50)  NOT NULL UNIQUE,
  description  VARCHAR(255),
  status       ENUM('active','inactive') NOT NULL DEFAULT 'active'
) ENGINE=InnoDB;

CREATE TABLE address (
  address_id   INT AUTO_INCREMENT PRIMARY KEY,
  barangay     VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE categories (
  category_id    INT AUTO_INCREMENT PRIMARY KEY,
  category_name  VARCHAR(100) NOT NULL UNIQUE,
  description    VARCHAR(255),
  status         ENUM('active','inactive') NOT NULL DEFAULT 'active'
) ENGINE=InnoDB;

CREATE TABLE payment_method (
  payment_method_id INT AUTO_INCREMENT PRIMARY KEY,
  method_name       VARCHAR(50) NOT NULL UNIQUE,
  description       VARCHAR(255),
  status            ENUM('active','inactive') NOT NULL DEFAULT 'active'
) ENGINE=InnoDB;

CREATE TABLE motorcycle_brand (
  motorcycle_brand_id INT AUTO_INCREMENT PRIMARY KEY,
  model               VARCHAR(100) NOT NULL,
  year                YEAR
) ENGINE=InnoDB;

-- ---------- Users and customers ----------

CREATE TABLE users (
  user_id     INT AUTO_INCREMENT PRIMARY KEY,
  role_id     INT NOT NULL,
  username    VARCHAR(50)  NOT NULL UNIQUE,
  password    VARCHAR(255) NOT NULL,          -- store a hash (bcrypt/argon2), never plain text
  first_name  VARCHAR(100) NOT NULL,
  last_name   VARCHAR(100) NOT NULL,
  status      ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(role_id)
) ENGINE=InnoDB;

CREATE TABLE customers (
  customer_id     INT AUTO_INCREMENT PRIMARY KEY,
  customer_name   VARCHAR(150) NOT NULL,
  contact_number  VARCHAR(20),
  address_id      INT,
  status          ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_customers_address FOREIGN KEY (address_id) REFERENCES address(address_id)
) ENGINE=InnoDB;

CREATE TABLE motorcycles (
  motorcycle_id        INT AUTO_INCREMENT PRIMARY KEY,
  customer_id          INT NOT NULL,
  plate_number         VARCHAR(20) NOT NULL UNIQUE,
  motorcycle_brand_id  INT NOT NULL,
  color                VARCHAR(50),
  status               ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_moto_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT fk_moto_brand    FOREIGN KEY (motorcycle_brand_id) REFERENCES motorcycle_brand(motorcycle_brand_id)
) ENGINE=InnoDB;

-- ---------- Services ----------

CREATE TABLE services (
  service_id     INT AUTO_INCREMENT PRIMARY KEY,
  category_id    INT NOT NULL,
  service_name   VARCHAR(150) NOT NULL,
  service_price  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  description    VARCHAR(255),
  status         ENUM('active','inactive') NOT NULL DEFAULT 'active',
  CONSTRAINT fk_services_category FOREIGN KEY (category_id) REFERENCES categories(category_id)
) ENGINE=InnoDB;

-- ---------- Sales ----------

CREATE TABLE sales (
  sale_id       INT AUTO_INCREMENT PRIMARY KEY,
  user_id       INT NOT NULL,
  customer_id   INT NOT NULL,
  sale_date     DATE NOT NULL,
  total_amount  DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  status        ENUM('pending','paid','partial','cancelled') NOT NULL DEFAULT 'pending',
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_sales_user     FOREIGN KEY (user_id)     REFERENCES users(user_id),
  CONSTRAINT fk_sales_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
) ENGINE=InnoDB;

CREATE TABLE sale_details (
  sale_detail_id  INT AUTO_INCREMENT PRIMARY KEY,
  sale_id         INT NOT NULL,
  service_id      INT NOT NULL,
  motorcycle_id   INT NOT NULL,
  quantity        INT NOT NULL DEFAULT 1,
  unit_price      DECIMAL(10,2) NOT NULL,
  subtotal        DECIMAL(12,2) NOT NULL,
  CONSTRAINT fk_sd_sale       FOREIGN KEY (sale_id)       REFERENCES sales(sale_id) ON DELETE CASCADE,
  CONSTRAINT fk_sd_service    FOREIGN KEY (service_id)    REFERENCES services(service_id),
  CONSTRAINT fk_sd_motorcycle FOREIGN KEY (motorcycle_id) REFERENCES motorcycles(motorcycle_id)
) ENGINE=InnoDB;

CREATE TABLE ecu_tuning (
  tuning_id       INT AUTO_INCREMENT PRIMARY KEY,
  sale_detail_id  INT NOT NULL,
  motorcycle_id   INT NOT NULL,
  user_id         INT NOT NULL,               -- technician who did the tuning
  tuning_date     DATE NOT NULL,
  ecu_type        VARCHAR(100),
  ecu_before      TEXT,
  ecu_after       TEXT,
  tuning_status   ENUM('pending','in_progress','completed','cancelled') NOT NULL DEFAULT 'pending',
  CONSTRAINT fk_tuning_sale_detail FOREIGN KEY (sale_detail_id) REFERENCES sale_details(sale_detail_id),
  CONSTRAINT fk_tuning_motorcycle  FOREIGN KEY (motorcycle_id)  REFERENCES motorcycles(motorcycle_id),
  CONSTRAINT fk_tuning_user        FOREIGN KEY (user_id)        REFERENCES users(user_id)
) ENGINE=InnoDB;

-- ---------- Purchases ----------

CREATE TABLE purchases (
  purchase_id       INT AUTO_INCREMENT PRIMARY KEY,
  user_id           INT NOT NULL,
  purchase_date     DATE NOT NULL,
  reference_number  VARCHAR(50),
  total_amount      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  status            ENUM('pending','paid','partial','cancelled') NOT NULL DEFAULT 'pending',
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_purchases_user FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

CREATE TABLE purchase_details (
  purchase_detail_id  INT AUTO_INCREMENT PRIMARY KEY,
  purchase_id         INT NOT NULL,
  quantity            INT NOT NULL DEFAULT 1,
  unit_cost           DECIMAL(10,2) NOT NULL,
  subtotal            DECIMAL(12,2) NOT NULL,
  CONSTRAINT fk_pd_purchase FOREIGN KEY (purchase_id) REFERENCES purchases(purchase_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------- Payments ----------

CREATE TABLE payments (
  payment_id         INT AUTO_INCREMENT PRIMARY KEY,
  sale_id            INT NULL,                -- set for customer payments
  purchase_id        INT NULL,                -- set for supplier payments
  payment_method_id  INT NOT NULL,
  received_by        VARCHAR(100),
  amount_paid        DECIMAL(12,2) NOT NULL,
  reference_number   VARCHAR(50),
  payment_status     ENUM('pending','completed','failed','refunded') NOT NULL DEFAULT 'completed',
  payment_date       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pay_sale     FOREIGN KEY (sale_id)           REFERENCES sales(sale_id),
  CONSTRAINT fk_pay_purchase FOREIGN KEY (purchase_id)       REFERENCES purchases(purchase_id),
  CONSTRAINT fk_pay_method   FOREIGN KEY (payment_method_id) REFERENCES payment_method(payment_method_id),
  CONSTRAINT chk_pay_target  CHECK (sale_id IS NOT NULL OR purchase_id IS NOT NULL)
) ENGINE=InnoDB;

-- ---------- System tables ----------

CREATE TABLE notifications (
  notification_id    INT AUTO_INCREMENT PRIMARY KEY,
  user_id            INT NOT NULL,
  notification_type  VARCHAR(50),
  message            VARCHAR(255) NOT NULL,
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notif_user FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

CREATE TABLE activity_logs (
  log_id       INT AUTO_INCREMENT PRIMARY KEY,
  user_id      INT NOT NULL,
  action       VARCHAR(100) NOT NULL,
  module       VARCHAR(100),
  description  VARCHAR(255),
  ip_address   VARCHAR(45),
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_log_user FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- ---------- Helpful indexes for reports / analytics ----------
CREATE INDEX idx_sales_date        ON sales(sale_date);
CREATE INDEX idx_payments_date     ON payments(payment_date);
CREATE INDEX idx_tuning_date       ON ecu_tuning(tuning_date);
CREATE INDEX idx_logs_created      ON activity_logs(created_at);

-- ---------- Starter data ----------
INSERT INTO roles (role_name, description) VALUES
  ('Admin', 'Full system access'),
  ('Staff', 'Handles sales and payments'),
  ('Technician', 'Performs ECU tuning');

INSERT INTO payment_method (method_name, description) VALUES
  ('Cash', 'Cash payment'),
  ('GCash', 'E-wallet payment'),
  ('Bank Transfer', 'Bank deposit or transfer');
