-- ============================================================
-- NIVELL 1
-- ============================================================

-- EXERCICI 1: crear i importar les taules

CREATE DATABASE IF NOT EXISTS transactions;
USE transactions;

CREATE TABLE IF NOT EXISTS company (
    id VARCHAR(15) PRIMARY KEY,
    company_name VARCHAR(255),
    phone VARCHAR(15),
    email VARCHAR(100),
    country VARCHAR(100),
    website VARCHAR(255)
);

-- La taula credit_card es crea a l'exercici 4.
-- La FK credit_card_id s'afegeix després d'importar les targetes.
-- No existeix cap taula user en aquest esquema, per tant user_id no té FK.
CREATE TABLE IF NOT EXISTS `transaction` (
    id VARCHAR(255) PRIMARY KEY,
    credit_card_id VARCHAR(15),
    company_id VARCHAR(15),
    user_id INT,
    lat FLOAT,
    longitude FLOAT,
    `timestamp` TIMESTAMP NULL,
    amount DECIMAL(10, 2),
    declined BOOLEAN,
    CONSTRAINT fk_transaction_company
        FOREIGN KEY (company_id) REFERENCES company(id)
);

-- Insserim les dades de transaction directament des de l'arxiu per no sobrecarregar aquest document.


-- EXERCICI 2 (JOINS)
-- 2A. Llistat dels països que estan generant vendes.
SELECT
    c.country,
    SUM(t.amount) AS vendes
FROM company c
INNER JOIN `transaction` t
    ON c.id = t.company_id
GROUP BY c.country
ORDER BY c.country;

-- 2B. Des de quants països es generen les vendes.
SELECT
    COUNT(DISTINCT c.country) AS nombre_paisos_amb_vendes
FROM company c
INNER JOIN `transaction` t
    ON c.id = t.company_id
WHERE t.declined = 0;
-- P2P: si inclogués les vendes rebutjades, tot el que digui vendes es 0
    
-- 2C. Identifica la companyia amb la mitjana més gran de vendes.
SELECT
    c.id,
    c.company_name,
    round(AVG(t.amount),2) AS mitjana_de_vendes
FROM company c
INNER JOIN `transaction` t
    ON c.id = t.company_id
GROUP BY c.id, c.company_name
ORDER BY mitjana_de_vendes DESC
LIMIT 1;
-- Bones pràctiques: Round, 2, estandard

-- EXERCICI 3 (SUBCONSULTES)

-- 3A. Mostra totes les transaccions realitzades per empreses d'Alemanya.
-- Best practices: where exists > IN
SELECT t.id
FROM `transaction` t
WHERE EXISTS (
    SELECT c.id
    FROM company c
    WHERE c.id = t.company_id
      AND c.country = 'Germany'
);


-- 3B. 
-- Llista les empreses que han realitzat transaccions per un import ('amount') 
-- superior a la mitjana de totes les transaccions.

SELECT DISTINCT
    c.id,
    c.company_name
FROM company c
INNER JOIN `transaction` t
    ON c.id = t.company_id
WHERE t.amount > (
    SELECT AVG(amount)
    FROM `transaction` t
);


-- 3C. Elimina del sistema les empreses que no tenen transaccions registrades, 
-- entrega el llistat d'aquestes empreses.
DELETE FROM company
WHERE NOT EXISTS (
    SELECT 1
    FROM `transaction` t
    WHERE t.company_id = company.id
);

-- Comprovar empreses sense transaccions.
SELECT
    c.id,
    c.company_name
FROM company 
WHERE NOT EXISTS (
    SELECT t.id
    FROM c.id t
    WHERE t.company_id = c.id
);

-- EXERCICI 4: crear credit_card i establir la relació

CREATE TABLE IF NOT EXISTS credit_card (
    id VARCHAR(15) PRIMARY KEY,
    iban VARCHAR(34),
    pan VARCHAR(19),
    pin CHAR(4),
    cvv CHAR(3),
    expiring_date DATE
);

-- Importació de les dades.

-- Comprovació de la correspondència entre transaccions i targetes.
SELECT
    COUNT(*) AS total_transactions,
    SUM(cc.id IS NOT NULL) AS matching_cards,
    SUM(cc.id IS NULL AND t.credit_card_id IS NOT NULL) AS unmatched_cards
FROM `transaction` t
LEFT JOIN credit_card cc
    ON t.credit_card_id = cc.id;

-- Aquesta consulta ha de retornar 0 files abans de crear la FK.
SELECT
    t.id AS transaction_id,
    t.credit_card_id
FROM `transaction` t
LEFT JOIN credit_card cc
    ON t.credit_card_id = cc.id
WHERE t.credit_card_id IS NOT NULL
  AND cc.id IS NULL;

ALTER TABLE `transaction`
ADD CONSTRAINT fk_transaction_credit_card
FOREIGN KEY (credit_card_id)
REFERENCES credit_card(id);

SHOW CREATE TABLE `transaction`;


-- EXERCICI 5

UPDATE credit_card
SET iban = 'TR323456312213576817699999'
WHERE id = 'CcU-2938';


-- EXERCICI 6

INSERT IGNORE INTO company
    (id, company_name, phone, email, country, website)
VALUES
    ('b-9999', 'Sharm Inn Resort', '00 22 30 45 05',
     'sharminn@gmail.com', 'Egypt', 'https://instagram.com/sharmInn');

INSERT IGNORE INTO credit_card (id)
VALUES ('CcU-9999');

INSERT IGNORE INTO `transaction`
    (id, credit_card_id, company_id, user_id, lat, longitude, amount, declined)
VALUES
    ('108B1D1D-5B23-A76C-55EF-C568E49A99DD',
     'CcU-9999', 'b-9999', 9999, 829.999, -117.999, 111.11, 0);


-- EXERCICI 7

ALTER TABLE credit_card
DROP COLUMN pan;

DESCRIBE credit_card;


-- ============================================================
-- EXERCICI 8: esquema d'estrella a global_transactions
-- ============================================================

CREATE DATABASE IF NOT EXISTS global_transactions;
USE global_transactions;

CREATE TABLE IF NOT EXISTS american_users (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    surname VARCHAR(100),
    phone VARCHAR(30),
    email VARCHAR(150),
    birth_date DATE,
    country VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    address VARCHAR(255),
    signup_date DATE,
    user_segment VARCHAR(50),
    income_band VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS european_users (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    surname VARCHAR(100),
    phone VARCHAR(30),
    email VARCHAR(150),
    birth_date DATE,
    country VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    address VARCHAR(255),
    signup_date DATE,
    user_segment VARCHAR(50),
    income_band VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS companies (
    company_id VARCHAR(20) PRIMARY KEY,
    company_name VARCHAR(150),
    phone VARCHAR(30),
    email VARCHAR(150),
    country VARCHAR(100),
    website VARCHAR(255),
    merchant_category VARCHAR(50),
    merchant_price_position VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS credit_cards (
    id VARCHAR(15) PRIMARY KEY,
    user_id INT,
    iban VARCHAR(34),
    pan VARCHAR(30),
    pin VARCHAR(10),
    cvv VARCHAR(10),
    track1 VARCHAR(100),
    track2 VARCHAR(100),
    expiring_date DATE,
    card_type VARCHAR(50),
    card_renewal_flag TINYINT
);


CREATE TABLE IF NOT EXISTS transactions (
    id VARCHAR(40) PRIMARY KEY,
    card_id VARCHAR(15),
    business_id VARCHAR(20),
    `timestamp` DATETIME,
    amount DECIMAL(12,2),
    declined TINYINT,
    product_ids VARCHAR(255),
    user_id INT,
    lat DECIMAL(18,15),
    longitude DECIMAL(24,21),
    discount_amount DECIMAL(12,2),
    tax_amount DECIMAL(12,2),
    shipping_amount DECIMAL(12,2),
    channel VARCHAR(30),
    campaign_id VARCHAR(50),
    device_type VARCHAR(30),
    is_international TINYINT,
    decline_reason VARCHAR(100),
    distance_km DECIMAL(12,2),
    

-- modificació de dades de users i unificació de taules

ALTER TABLE american_users
ADD COLUMN region VARCHAR(20);

UPDATE american_users
SET region = 'America';

ALTER TABLE european_users
ADD COLUMN region VARCHAR(20);

UPDATE european_users
SET region = 'Europe';


CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    original_user_id INT NOT NULL,
    region VARCHAR(20),
    name VARCHAR(100),
    surname VARCHAR(100),
    phone VARCHAR(30),
    email VARCHAR(150),
    birth_date DATE,
    country VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    address VARCHAR(255),
    signup_date DATE,
    user_segment VARCHAR(50),
    income_band VARCHAR(20),
    UNIQUE (original_user_id, region)
);


-- CÀRREGA DE DADES

LOAD DATA LOCAL INFILE '/Users/mireia/Library/Mobile Documents/com~apple~CloudDocs/🗄️ DA/american_users.csv'
INTO TABLE american_users
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, name, surname, phone, email, @birth_date, country, city,
 postal_code, address, @signup_date, user_segment, income_band)
SET
    birth_date = STR_TO_DATE(@birth_date, '%b %e, %Y'),
    signup_date = STR_TO_DATE(@signup_date, '%Y-%m-%d');

LOAD DATA LOCAL INFILE '/Users/mireia/Library/Mobile Documents/com~apple~CloudDocs/🗄️ DA/companies.csv'
INTO TABLE companies
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(company_id, company_name, phone, email, country, website,
 merchant_category, merchant_price_position);

LOAD DATA LOCAL INFILE '/Users/mireia/Library/Mobile Documents/com~apple~CloudDocs/🗄️ DA/credit_cards.csv'
INTO TABLE credit_cards
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, user_id, iban, pan, pin, cvv, track1, track2,
 @expiring_date, card_type, card_renewal_flag)
SET expiring_date = STR_TO_DATE(@expiring_date, '%m/%d/%y');

LOAD DATA LOCAL INFILE '/Users/mireia/Library/Mobile Documents/com~apple~CloudDocs/🗄️ DA/european_users.csv'
INTO TABLE european_users
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, name, surname, phone, email, @birth_date, country, city,
 postal_code, address, @signup_date, user_segment, income_band)
SET
    birth_date = STR_TO_DATE(@birth_date, '%b %e, %Y'),
    signup_date = STR_TO_DATE(@signup_date, '%Y-%m-%d');

LOAD DATA LOCAL INFILE '/Users/mireia/Library/Mobile Documents/com~apple~CloudDocs/🗄️ DA/transactions.csv'
INTO TABLE transactions
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, card_id, business_id, `timestamp`, amount, declined,
 product_ids, user_id, lat, longitude, discount_amount,
 tax_amount, shipping_amount, channel, campaign_id,
 device_type, is_international, decline_reason, distance_km);


INSERT INTO users (
    original_user_id,
    name,
    surname,
    phone,
    email,
    birth_date,
    country,
    city,
    postal_code,
    address,
    signup_date,
    user_segment,
    income_band,
    region
)
SELECT
    id, name, surname, phone, email, birth_date,
    country, city, postal_code, address, signup_date,
    user_segment, income_band, region
FROM american_users

UNION ALL

SELECT
    id, name, surname, phone, email, birth_date,
    country, city, postal_code, address, signup_date,
    user_segment, income_band, region
FROM european_users;

-- modificacions al convergir taules 
ALTER TABLE transactions
    DROP COLUMN american_users_id,
    DROP COLUMN european_users_id;

ALTER TABLE transactions
    DROP FOREIGN KEY fk_transactions_american_users,
    DROP FOREIGN KEY fk_transactions_european_users;
    
drop table american_users;
drop table european_users;

ALTER TABLE transactions
MODIFY COLUMN user_id INT;

-- relacions 
ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_users
FOREIGN KEY (user_id) REFERENCES users(user_id);

ALTER TABLE transactions

    ADD CONSTRAINT fk_transactions_credit_cards
        FOREIGN KEY (card_id)
        REFERENCES credit_cards(id),

    ADD CONSTRAINT fk_transactions_companies
        FOREIGN KEY (business_id)
        REFERENCES companies(company_id);

SELECT
    CONSTRAINT_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'global_transactions'
  AND TABLE_NAME = 'transactions'
  AND REFERENCED_TABLE_NAME IS NOT NULL;



-- EXERCICI 9
-- Realitza una subconsulta que mostri tots els usuaris amb més de 80 transaccions utilitzant almenys 2 taules.
SELECT
    u.user_id,
    u.name,
    u.surname
FROM users u
WHERE EXISTS (
    SELECT t.user_id
    FROM transactions t
    WHERE t.user_id = u.user_id
    GROUP BY t.user_id
    HAVING COUNT(*) > 80
);


-- EXERCICI 10 
-- Mitjana d'amount per IBAN a la companyia Donec Ltd utilitzant almenys 2 taules..
SELECT round(AVG(t.amount),2) AS mitjana_amount,
	   cc.iban,
	   c.company_name
FROM transactions t
INNER JOIN credit_cards cc
	ON t.card_id = cc.id
INNER JOIN companies c
	ON t.business_id = c.company_id
    WHERE c.company_name = 'Donec Ltd'
GROUP BY cc.iban, c.company_name
;



-- ============================================================
-- NIVELL 2
-- ============================================================

-- EXERCICI 1
/*
Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a l'empresa per vendes. 
Mostra la data de cada transacció juntament amb el total de les vendes
*/

SELECT
    DATE(t.`timestamp`) AS fecha,
    SUM(t.amount) AS total_vendes
FROM transactions t
GROUP BY DATE(t.`timestamp`)
ORDER BY total_vendes DESC
LIMIT 5;


-- EXERCICI 2
/*
Presenta el nom, telèfon, país, data i amount, d'aquelles empreses que van realitzar transaccions amb un valor comprès entre 350 i 400 euros 
i en alguna d'aquestes dates: 29 d'abril del 2015, 20 de juliol del 2018 i 13 de març del 2024. 
Ordena els resultats de major a menor quantitat.
*/

SELECT
    c.company_name AS nom,
    c.phone AS telefon,
    c.country AS país,
    DATE(t.`timestamp`) AS data,
    t.amount AS valor_de_la_transacció
FROM companies c 
INNER JOIN transactions t
    ON t.business_id = c.company_id
WHERE t.amount BETWEEN 350 AND 400
  AND (
    DATE(t.`timestamp`) = '2015-04-29'
    OR DATE(t.`timestamp`) = '2018-07-20'
    OR DATE(t.`timestamp`) = '2024-03-13'
)
ORDER BY t.amount DESC;


-- EXERCICI 3
/*
Necessitem optimitzar l'assignació dels recursos i dependrà de la capacitat operativa que es requereixi, 
per la qual cosa et demanen la informació sobre la quantitat de transaccions que realitzen les empreses, 
però el departament de recursos humans és exigent 
i vol un llistat de les empreses on especifiquis si tenen igual o més de 400 transaccions o menys.
*/
-- Sino és left join no incliu les de 0 transaccions.

SELECT 
    c.company_id,
    c.company_name,
    COUNT(t.id) AS total_transactions,
    CASE
        WHEN COUNT(t.id) >= 400 THEN '400 o més'
        ELSE 'Menys de 400'
    END AS classification
FROM companies c
LEFT JOIN transactions t
    ON c.company_id = t.business_id
GROUP BY c.company_id, c.company_name;


-- EXERCICI 4: eliminar el registre indicat i comprovar-ne l'eliminació.

DELETE FROM transactions
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

SELECT COUNT(*) AS registres_restants
FROM transactions
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';


-- EXERCICI 5
/*
La secció de màrqueting desitja tenir accés a informació específica per a realitzar anàlisi i estratègies efectives. 
S'ha sol·licitat crear una vista que proporcioni detalls clau sobre les companyies i les seves transaccions. 
Serà necessària que creïs una vista anomenada VistaMarketing que contingui la següent informació: 
Nom de la companyia. Telèfon de contacte. País de residència. Mitjana de compra realitzat per cada companyia. 
Presenta la vista creada, ordenant les dades de major a menor mitjana de compra.
*/

CREATE OR REPLACE VIEW VistaMarketing AS
SELECT
    c.company_name AS nom_de_la_companyia,
    c.phone AS telefon,
    c.country AS pais_residencia,
    AVG(t.amount) AS mitjana_de_compra
FROM companies c
INNER JOIN transactions t
    ON c.company_id = t.business_id
GROUP BY
    c.company_id,
    c.company_name,
    c.phone,
    c.country;

SELECT *
FROM VistaMarketing
ORDER BY mitjana_de_compra DESC;


-- ============================================================
-- NIVELL 3
-- ============================================================

-- EXERCICI 1
/*
Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en 
si les tres últimes transaccions han estat declinades aleshores és inactiu, 
si almenys una no és rebutjada aleshores és actiu. -- Partint d’aquesta taula respon: 👉 Quantes targetes estan actives?
*/


CREATE TABLE IF NOT EXISTS estat_targeta AS
SELECT
    card_id,
    CASE
        WHEN SUM(declined) = 3 THEN 'inactiva'
        ELSE 'activa'
    END AS estat
FROM (
    SELECT
        card_id,
        declined,
        `timestamp`,
        ROW_NUMBER() OVER (
            PARTITION BY card_id
            ORDER BY `timestamp` DESC
        ) AS numero_fila
    FROM transactions
) AS transaccions_recents
WHERE numero_fila <= 3
GROUP BY card_id;

ALTER TABLE estat_targeta
    ADD PRIMARY KEY (card_id),
    ADD CONSTRAINT fk_estat_targeta_targeta
        FOREIGN KEY (card_id) REFERENCES credit_cards(id);

-- Nombre de targetes actives.
SELECT COUNT(card_id) AS targetes_actives
FROM estat_targeta
WHERE estat = 'activa';


-- EXERCICI 2
/*
Crea una taula amb la qual puguem unir les dades de l'arxiu de products.csv amb la base de dades creada 
(ja que fins ara no podíem fer-ho), tenint en compte que des de transaction tens product_ids. Genera la següent consulta:
👉 Necessitem conèixer el nombre de vegades que s'ha venut cada producte.
*/

CREATE TABLE IF NOT EXISTS products (
    id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(150),
    price DECIMAL(10,2),
    colour VARCHAR(50),
    weight DECIMAL(5,2),
    warehouse_id VARCHAR(50),
    category VARCHAR(50),
    brand VARCHAR(150),
    cost DECIMAL(10,2),
    launch_date DATE
);

LOAD DATA LOCAL INFILE '/Users/mireia/Library/Mobile Documents/com~apple~CloudDocs/🗄️ DA/products_semicolon.csv'
INTO TABLE products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, product_name, @price, colour, weight, warehouse_id, category, brand, @cost, launch_date)
SET
    price = NULLIF(REPLACE(@price, '$', ''), ''),
    cost = NULLIF(REPLACE(@cost, '$', ''), '');

-- Taula intermitja
CREATE TABLE IF NOT EXISTS transaction_products (
    transaction_id VARCHAR(40) NOT NULL,
    product_id VARCHAR(10) NOT NULL,
    PRIMARY KEY (transaction_id, product_id),
    CONSTRAINT fk_transaction_products_transaction
        FOREIGN KEY (transaction_id) REFERENCES transactions(id),
    CONSTRAINT fk_transaction_products_product
        FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Convertir una llista d'identificadors de productes en registres individuals 
-- que relacionen cada transacció amb els seus productes.
INSERT IGNORE INTO transaction_products (transaction_id, product_id)
SELECT
    t.id,
    p.id
FROM transactions t
INNER JOIN products p
    ON FIND_IN_SET(p.id, REPLACE(t.product_ids, ' ', '')) > 0
WHERE t.product_ids IS NOT NULL
  AND TRIM(t.product_ids) <> '';
  
  
-- Comprovacions de la taula pont.
SELECT
    COUNT(*) AS total_relacions,
    COUNT(DISTINCT transaction_id) AS total_transactions,
    COUNT(DISTINCT product_id) AS total_products
FROM transaction_products;

-- Nombre de vegades que s'ha venut cada producte.
-- Left join per incloure també els que tinguin 0 vendes.

SELECT
    p.id,
    p.product_name,
    COUNT(tp.product_id) AS nombre_vegades_vendes
FROM products p
LEFT JOIN transaction_products tp
    ON p.id = tp.product_id
GROUP BY 
p.id,
p.product_name
ORDER BY nombre_vegades_vendes DESC;
