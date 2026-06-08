 
 /* ____________ Nivell 1 _____________________________________________
Exercici 1
A partir dels documents adjunts (estructura_dades i dades_introduir), importa
les dues taules. Mostra les característiques principals de l'esquema creat i explica
les diferents taules i variables que existeixen. Assegura't d'incloure un diagrama 
que il·lustri la relació entre les diferents taules i variables. */

SELECT*
FROM transaction;

-- Creamos la base de datos
CREATE DATABASE IF NOT EXISTS transactions;
USE transactions;

-- Creamos la tabla company
CREATE TABLE IF NOT EXISTS company (
	id VARCHAR(15) PRIMARY KEY,
	company_name VARCHAR(255),
	phone VARCHAR(15),
	email VARCHAR(100),
	country VARCHAR(100),
	website VARCHAR(255)
);


-- Creamos la tabla transaction
CREATE TABLE IF NOT EXISTS transaction (
	id VARCHAR(255) PRIMARY KEY,
	credit_card_id VARCHAR(15) REFERENCES credit_card(id),
	company_id VARCHAR(20), 
	user_id INT REFERENCES user(id),
	lat FLOAT,
	longitude FLOAT,
	timestamp TIMESTAMP,
	amount DECIMAL(10, 2),
	declined BOOLEAN,
	FOREIGN KEY (company_id) REFERENCES company(id) 
);

-- data uploaded to the 2 tables in another MySQL tab due to the length of the code...    
    
DESCRIBE company;
DESCRIBE transaction;

# to see constraints...
SELECT 
    table_name, 
    column_name, 
    constraint_name, 
    referenced_table_name, 
    referenced_column_name 
FROM 
    INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
WHERE 
referenced_table_schema = 'transactions' 
    AND referenced_table_name = 'company'; 

SHOW CREATE TABLE transaction;
# >> copied constraint details from output '... CONSTRAINT `transaction_ibfk_1` FOREIGN KEY (`company_id`) REFERENCES `company` (`id`)...

SELECT*
FROM company;

SELECT*
FROM transaction; 

/* - Exercici 2
Utilitzant JOIN realitzaràs les següents consultes:*/

# a - Llistat dels països que estan fent compres.
SELECT DISTINCT country AS paisos_compradors
FROM transaction tran
LEFT JOIN company co 
	ON co.id = tran.company_id
ORDER BY country
;

# b - Des de quants països es realitzen les compres.
# es realitzen compres des de 15 paisos diferents (numero de files apartat a)

#c - Identifica la companyia amb la mitjana més gran de vendes.*/
SELECT co.company_name, co.id, AVG(tran.amount) AS mitjana_vendes
FROM transaction tran
JOIN company co 
	ON co.id = tran.company_id
GROUP BY co.id
ORDER BY AVG(amount) DESC
LIMIT 1
;


/* - Exercici 3
Utilitzant només subconsultes (sense utilitzar JOIN):
 a) Mostra totes les transaccions realitzades per empreses d'Alemanya.*/
SELECT*
FROM transaction tran
WHERE company_id IN (SELECT id
					FROM company co
                    WHERE co.country = "Germany" 
                    AND co.id = tran.company_id)
;

# ... checking number of transactions returned doing same query but with a JOIN... = OK
SELECT co.id, amount
FROM transaction tran
JOIN company co
	ON co.id = tran.company_id
WHERE co.country = "Germany"
;

# b) Llista les empreses que han realitzat transaccions per un amount superior a la mitjana de totes les transaccions.
SELECT DISTINCT company_id AS clients_above_avg_price
			FROM transaction
			WHERE amount > (SELECT AVG(amount)
							FROM transaction)
ORDER BY company_id
;

#checking correct that all companies have atleast 1 transaction above global avg amount... OK
SELECT AVG(amount)
FROM transaction;

SELECT MAX(amount)
FROM transaction
GROUP BY company_id
ORDER BY MAX(amount);


# c) Eliminaran del sistema les empreses que no tenen transaccions registrades, entrega el llistat d'aquestes empreses.
#(... returns empty list...)
SELECT id, company_name
FROM company co
WHERE NOT EXISTS (SELECT company_id
						FROM transaction tran
                        WHERE tran.company_id = co.id)
;

# ... checking the result for C is correct, that all companies really have done transactions = OK
SELECT co.id, co.company_name, SUM(amount)
FROM company co 
LEFT JOIN transaction tran 
	ON co.id = tran.company_id
GROUP BY co.id
ORDER BY SUM(amount)
;

/* Exercici 4
La teva tasca és dissenyar i crear una taula anomenada "credit_card" que emmagatzemi detalls crucials 
sobre les targetes de crèdit. La nova taula ha de ser capaç d'identificar de manera única cada targeta 
i establir una relació adequada amb les altres dues taules ("transaction" i "company"). Després de 
crear la taula serà necessari que ingressis la informació del document denominat "dades_introduir_credit". 
Recorda mostrar el diagrama i realitzar una breu descripció d'aquest.*/

DROP TABLE IF EXISTS credit_card;
CREATE TABLE credit_card (
	id VARCHAR(255),
	iban VARCHAR(255), 
	pan VARCHAR(255),
	pin VARCHAR(255),
	cvv VARCHAR(255),
	expiring_date VARCHAR(255),
    PRIMARY KEY (id) 
);

# (here inserted the data executing the dowloaded script in another MySQL tab due to length (5000 records)...)

SELECT*
FROM credit_card;

SHOW COLUMNS 
FROM credit_card;

/*     FIXES/CHECKS:
    • id   		VARCHAR(255, check max length when data loaded)
    • iban		VARCHAR(255, check max length, dif countries have dif IBAN lengths...)
    • pan		VARCHAR(255, although digits, some have spaces, so string)
    • pin		SMALLINT
    • cvv		SMALLINT
    • expiring_date  needs to ultimately be formatted DATE (MM/DD/YY) */
    

# ammending data types (except expiring_date) now data loaded into table without any errors:
ALTER TABLE credit_card 
	MODIFY iban VARCHAR(50) NOT NULL,
    MODIFY pan VARCHAR(50) NOT NULL,
    MODIFY pin SMALLINT NOT NULL,
    MODIFY cvv SMALLINT NOT NULL
;
 
    
# changing data type of expiring_date variable (currently VARCHAR, eg value 09/27/25):
# first change the string order so is the MySQL accepted format of YYYY-MM-DD... then change to DATE

UPDATE credit_card
SET expiring_date = DATE_FORMAT(STR_TO_DATE(expiring_date, '%m/%d/%y'),'%Y-%m-%d')
WHERE id LIKE "Cc%";

ALTER TABLE credit_card 
	MODIFY expiring_date DATE NOT NULL;


# adding FK constraint for relation between the new table PK (credit_card.id) and the fact table 'transaction' FK transaction.credit_card_id:
ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_credit_card
FOREIGN KEY(credit_card_id)
REFERENCES credit_card(id);

SHOW COLUMNS
FROM transaction;


/* Exercici 5
El departament de Recursos Humans ha identificat un error en el número de compte 
associat a la targeta de crèdit amb ID CcU-2938. La informació que ha de mostrar-se 
per a aquest registre és: TR323456312213576817699999. Recorda mostrar que el canvi 
es va realitzar.*/

# first, making sure filtering to the correct record, using SELECT...
SELECT iban, id
FROM credit_card
WHERE id = "CcU-2938";

#now, use the same filter to apply the update to that record:
UPDATE credit_card
SET iban = "TR323456312213576817699999"
WHERE id = "CcU-2938";

/* Exercici 6
En la taula "transaction" ingressa una nova transacció amb la següent informació:*/

# need to first create company record for FK constraint (NULL all values except id)
INSERT INTO company (id)
VALUES ("b-9999")
;

# need to first create credit_card record for FK constraint (doesn't allow NULL, so variables have flagged/fictious data)
INSERT INTO credit_card (id, iban, pan, pin, cvv, expiring_date)
VALUES ("CcU-9999", "pending", "pending", 0000, 000, '2025-09-27')
;
# can now add transaction without FK constraint errors:
INSERT INTO transaction (id, credit_card_id, company_id, user_id, lat, longitude, amount, declined)
VALUES ("108B1D1D-5B23-A76C-55EF-C568E49A99DD", 
	"CcU-9999",
	"b-9999",
	9999,
	829.999,
	-117.999, 
	111.11,
	0
);

# checking transaction inserted = OK (also now 100001 rows in transaction table, so +1)
SELECT*
FROM transaction 
WHERE id = "108B1D1D-5B23-A76C-55EF-C568E49A99DD";

SELECT*
FROM transaction;

/* Exercici 7
Des de recursos humans et sol·liciten eliminar la columna "pan" de la taula credit_card. Recorda mostrar el canvi realitzat.*/

ALTER TABLE credit_card
DROP COLUMN pan;

SHOW COLUMNS 
FROM credit_card;

/* Exercici 8
Descarrega els arxius CSV que trobaràs a l'apartat de recursos:

american_users.csv
european_users.csv
companies.csv
credit_cards.csv
transactions.csv

Estudia'ls i dissenya una base de dades amb un esquema d'estrella que contingui, almenys 4 taules de les quals puguis realitzar les següents consultes:
La taula de products.csv l'utilitzarem més endavant.*/

CREATE DATABASE s2_transactions;
USE s2_transactions;

DROP TABLE IF EXISTS raw_american_users;
CREATE TABLE raw_american_users (
	id INT NOT NULL UNIQUE,
	name VARCHAR (100),
	surname VARCHAR (100),
	phone VARCHAR (100),
	email VARCHAR (100),
	birth_date VARCHAR (100),
	country VARCHAR (100),
	city VARCHAR (100),
	postal_code VARCHAR (50),
	address VARCHAR (200),
	signup_date DATE,
	user_segment VARCHAR (100),
	income_band VARCHAR (100)
);

DROP TABLE IF EXISTS raw_european_users;
CREATE TABLE raw_european_users (
	id INT NOT NULL UNIQUE,
	name VARCHAR(100),
	surname VARCHAR(100),
	phone VARCHAR(100),
	email VARCHAR(100),
	birth_date VARCHAR(100),
	country VARCHAR(100),
	city VARCHAR(100),
	postal_code VARCHAR(50),
	address VARCHAR(200),
	signup_date DATE,
	user_segment VARCHAR(100),
	income_band VARCHAR(100)
);

DROP TABLE IF EXISTS raw_companies;
CREATE TABLE raw_companies (
	company_id VARCHAR(50) NOT NULL UNIQUE,
	company_name VARCHAR(200) NOT NULL,
	phone VARCHAR(100),
	email VARCHAR(100),
	country VARCHAR(100),
	website VARCHAR(150),
	merchant_category VARCHAR(50),
	merchant_price_position VARCHAR(100)
);

DROP TABLE IF EXISTS raw_credit_cards;
CREATE TABLE raw_credit_cards (
	id VARCHAR(50) NOT NULL UNIQUE,
	user_id INT,
	iban VARCHAR(100),
	pan VARCHAR(100),
	pin INT,
	cvv INT,
	track1 VARCHAR(200),
	track2 VARCHAR(200),
	expiring_date VARCHAR(50),
	card_type VARCHAR(50),
	card_renewal_flag INT
);

DROP TABLE IF EXISTS raw_transactions;
CREATE TABLE raw_transactions (
	id VARCHAR(100) NOT NULL UNIQUE,
	card_id VARCHAR(100) NOT NULL,
	business_id VARCHAR(50) NOT NULL,
	timestamp DATETIME,
	amount FLOAT,
	declined INT,
	product_ids VARCHAR(100),
	user_id INT,
	lat VARCHAR(100),
	longitude VARCHAR(100),
	discount_amount FLOAT,
	tax_amount FLOAT,
	shipping_amount FLOAT,
	channel VARCHAR(50),
	campaign_id VARCHAR(100),
	device_type VARCHAR(50),
	is_international INT,
	decline_reason VARCHAR(100),
	distance_km FLOAT
);

SHOW TABLES
FROM s2_transactions;

# now importing data from the CSV files:

/* to use LOAD DATA to upload the files, for security reasons I need
 to put the CSV files to load in the folder at the below (secure) path*/
 
SHOW VARIABLES LIKE "secure_file_priv";
# >>> 'secure_file_priv', 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\'
# so, path is now "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\N1-Ex.8__american_users.csv" << NOTE DOUBLE BACKSLASHES!!

TRUNCATE TABLE raw_american_users;
LOAD DATA
INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\N1-Ex.8__american_users.csv'
INTO TABLE raw_american_users 
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 1 ROWS;

SELECT*
FROM raw_american_users
LIMIT 10;

TRUNCATE TABLE raw_european_users;
LOAD DATA
INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\N1-Ex.8__european_users.csv'
INTO TABLE raw_european_users 
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 1 ROWS;

SELECT*
FROM raw_european_users
;

TRUNCATE TABLE raw_companies;
LOAD DATA
INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\N1-Ex.8__companies.csv'
INTO TABLE raw_companies 
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 1 ROWS;

SELECT*
FROM raw_companies;

TRUNCATE TABLE raw_credit_cards;
LOAD DATA
INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\N1-Ex.8__credit_cards.csv'
INTO TABLE raw_credit_cards 
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 1 ROWS;

SELECT*
FROM raw_credit_cards
WHERE id = "CcU-2938";

TRUNCATE TABLE raw_transactions;
LOAD DATA
INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\N1-Ex.8__transactions.csv'
INTO TABLE raw_transactions 
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
IGNORE 1 ROWS;

/*checking records not duplicated or ids NULL:
raw_american_users
raw_european_users
raw_companies
raw_credit_cards
raw_transactions
*/
SELECT*
FROM raw_transactions
WHERE id IS NULL;

SELECT DISTINCT id
FROM raw_transactions;

SELECT DISTINCT*
FROM raw_transactions;

/*
FIXES:
2 users tables:
    • AM / EU prefixes to id (add column global_user_id)
    • birth_date string to date
    • merge 2 tables to NEW users table (create table all_users)
    • Primary Key new table: global_user_id
*/

SELECT max(id)
FROM raw_european_users;

# checking logic
SELECT id,
	CASE 
		WHEN LENGTH(id) = 1 THEN CONCAT("AM0000",id)
        WHEN LENGTH(id) = 2 THEN CONCAT("AM000",id)
        WHEN LENGTH(id) = 3 THEN CONCAT("AM00", id)
        WHEN LENGTH(id) = 4 THEN CONCAT("AM0", id)
	END AS user_fixed
FROM raw_american_users;

SELECT birth_date
FROM raw_american_users;
# format is string: 'Nov 17, 1985'

SELECT DATE_FORMAT(STR_TO_DATE(birth_date, '%b %e, %Y'),'%Y-%m-%d') AS fixed_date
FROM raw_american_users;

SHOW CREATE TABLE raw_american_users;

#create SILVER level table to populate with fixes and merged data:
DROP TABLE IF EXISTS users;
CREATE TABLE users (
	global_user_id VARCHAR(10) NOT NULL UNIQUE,
	name varchar(100) NOT NULL,
	surname varchar(100) NOT NULL,
	phone varchar(100),
	email varchar(100),
	birth_date DATE,
	country varchar(50),
	city varchar(100),
	postal_code varchar(50),
	address varchar(200),
	signup_date DATE,
	user_segment varchar(100),
	income_band varchar(100)
);

SELECT*
FROM users;

# clear table, just in case, then populate new table with american_users_data:
TRUNCATE TABLE users;
INSERT INTO users (
				global_user_id,
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
				income_band)
SELECT
	CASE 
		WHEN LENGTH(id) = 1 THEN CONCAT("AM0000",id)
        WHEN LENGTH(id) = 2 THEN CONCAT("AM000",id)
        WHEN LENGTH(id) = 3 THEN CONCAT("AM00", id)
        WHEN LENGTH(id) = 4 THEN CONCAT("AM0", id)
	END AS global_user_id,
	name,
	surname,
	phone,
	email,
    DATE_FORMAT(STR_TO_DATE(birth_date, '%b %e, %Y'),'%Y-%m-%d') AS fixed_date,
	country,
	city,
	postal_code,
	address,
	signup_date,
	user_segment,
	income_band
FROM raw_american_users;

# and now populate with european_users_data:
# >> WITHOUT TRUNCATE so don't eliminate already inserted USA users!!!
INSERT INTO users (
				global_user_id,
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
				income_band)
SELECT
	CASE 
		WHEN LENGTH(id) = 1 THEN CONCAT("EU0000",id)
        WHEN LENGTH(id) = 2 THEN CONCAT("EU000",id)
        WHEN LENGTH(id) = 3 THEN CONCAT("EU00", id)
        WHEN LENGTH(id) = 4 THEN CONCAT("EU0", id)
	END AS global_user_id,
	name,
	surname,
	phone,
	email,
    DATE_FORMAT(STR_TO_DATE(birth_date, '%b %e, %Y'),'%Y-%m-%d') AS fixed_date,
	country,
	city,
	postal_code,
	address,
	signup_date,
	user_segment,
	income_band
FROM raw_european_users;

SELECT*
FROM users;

#create final companies table, no fixes required (quality check ok)
DROP TABLE IF EXISTS companies;
CREATE TABLE companies AS
SELECT*
FROM raw_companies;

SHOW CREATE TABLE raw_credit_cards;

# create credit_cards table to populate with fixes:
DROP TABLE IF EXISTS credit_cards;
CREATE TABLE credit_cards (
	id VARCHAR(50) NOT NULL UNIQUE,
	iban VARCHAR(100),
	pan VARCHAR(100),
	pin INT,
	cvv INT,
	track1 VARCHAR(200),
	track2 VARCHAR(200),
	expiring_date DATE,
	card_type VARCHAR(50),
	card_renewal_flag INT
);

# populate final credit_card table:
TRUNCATE TABLE credit_cards;
INSERT INTO credit_cards (
				id,
				iban,
				pan,
				pin,
				cvv,
				track1,
				track2,
				expiring_date,
				card_type,
				card_renewal_flag)
SELECT
	id,
	iban,
	pan,
	pin,
	cvv,
	track1,
	track2,
    DATE_FORMAT(STR_TO_DATE(expiring_date, '%m/%d/%y'),'%Y-%m-%d'),
	card_type,
	card_renewal_flag
FROM raw_credit_cards;

SELECT*
FROM credit_cards;

SHOW TABLES;

SHOW CREATE TABLE raw_transactions;

# trying extracting individual product ids....
# works, but does 5 products for each, repeating last true value.... need a condition to control number of items
SELECT product_ids, 
    SUBSTRING_INDEX(product_ids,",",1) AS a,
	SUBSTRING_INDEX(SUBSTRING_INDEX(product_ids, ",", 2),",",-1) AS b, 
    SUBSTRING_INDEX(SUBSTRING_INDEX(product_ids, ",", 3),",",-1) AS c, 
    SUBSTRING_INDEX(SUBSTRING_INDEX(product_ids, ",", 4),",",-1) AS d, 
    SUBSTRING_INDEX(SUBSTRING_INDEX(product_ids, ",", 5),",",-1) AS e
FROM raw_transactions
ORDER BY LENGTH(product_ids) DESC;

# deleting test table created = OK
DROP TABLE test_products_details;

# counting commas (length with commas - length removing commas) to get number of items in product_ids:
SELECT id, product_ids, LENGTH(product_ids) - LENGTH(REPLACE(product_ids, ',', '')) + 1 AS number_of_products
FROM raw_transactions;

# recursive CTE to split the product lists:
WITH RECURSIVE num AS (
    -- anchor query
    SELECT 1 AS n
    UNION ALL
    -- recursive query
    SELECT n + 1 
    FROM num 
    -- break condition
    WHERE n < (SELECT MAX(LENGTH(product_ids) - LENGTH(REPLACE(product_ids, ',', '')) + 1) FROM raw_transactions)
)
-- main query
SELECT id, SUBSTRING_INDEX(SUBSTRING_INDEX(t.product_ids, ',', n.n), ',', -1) AS product_id
FROM raw_transactions t
JOIN num n
  ON CHAR_LENGTH(t.product_ids) - CHAR_LENGTH(REPLACE(t.product_ids, ',', '')) >= n.n - 1;


#creating transaction_details table:
DROP TABLE IF EXISTS transaction_details;
CREATE TABLE transaction_details (
	details_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id VARCHAR(100),
    product_id VARCHAR(10) NOT NULL
);


# populating the new table using the recursive CTE...
TRUNCATE transaction_details;
INSERT INTO transaction_details (transaction_id, product_id)
WITH RECURSIVE num AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 
    FROM num 
    WHERE n < (SELECT MAX(CHAR_LENGTH(product_ids) - CHAR_LENGTH(REPLACE(product_ids, ',', '')) + 1) FROM raw_transactions)
)
SELECT 
    trans.id AS transaction_id, 
    SUBSTRING_INDEX(SUBSTRING_INDEX(trans.product_ids, ',', n.n), ',', -1) AS product_id
FROM raw_transactions trans
JOIN num n
  ON CHAR_LENGTH(trans.product_ids) - CHAR_LENGTH(REPLACE(trans.product_ids, ',', '')) >= n.n - 1;


#create final transactions table (renaming product_ids to list_products_ids and formatting monetary variables)
DROP TABLE IF EXISTS transactions;
CREATE TABLE transactions (
				id VARCHAR(100) NOT NULL UNIQUE,
				card_id VARCHAR(100) NOT NULL,
				business_id VARCHAR(50) NOT NULL,
				timestamp DATETIME,
				amount DECIMAL(10, 2),
				declined INT,
				list_product_ids VARCHAR(100),
				global_user_id VARCHAR(10),
				lat VARCHAR(100),
				longitude VARCHAR(100),
				discount_amount DECIMAL(10, 2),
				tax_amount DECIMAL(10, 2),
				shipping_amount DECIMAL(10, 2),
				channel VARCHAR(50),
				campaign_id VARCHAR(100),
				device_type VARCHAR(50),
				is_international INT,
				decline_reason VARCHAR(100),
				distance_km float
);

SHOW TABLES;

# checking with SELECT user_id fix in transactions table (so global_user_id)...
SELECT DISTINCT(user_id)
FROM raw_transactions
WHERE user_id IN (SELECT id
					FROM raw_american_users)
;

SELECT user_id,
	CASE 
		WHEN LENGTH(user_id) = 1 AND user_id in (SELECT id FROM raw_american_users) THEN CONCAT("AM0000",user_id)
        WHEN LENGTH(user_id) = 1 AND user_id in (SELECT id FROM raw_european_users) THEN CONCAT("EU0000",user_id)
        WHEN LENGTH(user_id) = 2 AND user_id in (SELECT id FROM raw_american_users) THEN CONCAT("AM000",user_id)
        WHEN LENGTH(user_id) = 2 AND user_id in (SELECT id FROM raw_european_users) THEN CONCAT("EU000",user_id)
        WHEN LENGTH(user_id) = 3 AND user_id in (SELECT id FROM raw_american_users) THEN CONCAT("AM00",user_id)
        WHEN LENGTH(user_id) = 3 AND user_id in (SELECT id FROM raw_european_users) THEN CONCAT("EU00",user_id)
        WHEN LENGTH(user_id) = 4 AND user_id in (SELECT id FROM raw_american_users) THEN CONCAT("AM0",user_id)
        WHEN LENGTH(user_id) = 4 AND user_id in (SELECT id FROM raw_european_users) THEN CONCAT("EU0",user_id)
	END AS global_user_id
FROM raw_transactions
;


# checking with SELECT fixing the data type in raw_transactions table
SELECT amount, CAST(amount AS DECIMAL(10,2))
FROM raw_transactions;

TRUNCATE TABLE transactions;
INSERT INTO transactions (
				id, 
				card_id,
				business_id,
				timestamp,
				amount,
				declined,
				list_product_ids,
				global_user_id,
				lat,
				longitude,
				discount_amount, 
				tax_amount,
				shipping_amount,
				channel,
				campaign_id,
				device_type,
				is_international, 
				decline_reason,
				distance_km)
SELECT id, 
		card_id,
		business_id,
		timestamp,
		CAST(amount AS DECIMAL(10,2)),
		declined,
		product_ids,
        CASE 
		WHEN LENGTH(user_id) = 1 AND user_id in (SELECT id FROM raw_american_users) THEN CONCAT("AM0000",user_id)
        WHEN LENGTH(user_id) = 1 AND user_id in (SELECT id FROM raw_european_users) THEN CONCAT("EU0000",user_id)
        WHEN LENGTH(user_id) = 2 AND user_id in (SELECT id FROM raw_american_users) THEN CONCAT("AM000",user_id)
        WHEN LENGTH(user_id) = 2 AND user_id in (SELECT id FROM raw_european_users) THEN CONCAT("EU000",user_id)
        WHEN LENGTH(user_id) = 3 AND user_id in (SELECT id FROM raw_american_users) THEN CONCAT("AM00",user_id)
        WHEN LENGTH(user_id) = 3 AND user_id in (SELECT id FROM raw_european_users) THEN CONCAT("EU00",user_id)
        WHEN LENGTH(user_id) = 4 AND user_id in (SELECT id FROM raw_american_users) THEN CONCAT("AM0",user_id)
        WHEN LENGTH(user_id) = 4 AND user_id in (SELECT id FROM raw_european_users) THEN CONCAT("EU0",user_id)
	END AS global_user_id,
		lat,
		longitude,
		CAST(discount_amount AS DECIMAL(10,2)), 
		CAST(tax_amount AS DECIMAL(10,2)),
		CAST(shipping_amount AS DECIMAL(10,2)),
		channel,
		campaign_id,
		device_type,
		is_international, 
		decline_reason,
		distance_km
FROM raw_transactions;

SELECT*
FROM transactions;

# now define relations (constraints) between all the final tables ... CAREFUL ORDER!!:
SHOW TABLES;

/* table order for alterations to not have parent/child issues:
users
companies
credit_cards
transactions
transaction_details (excl. FK products table not yet created)
*/

ALTER TABLE users
	ADD PRIMARY KEY (global_user_id);

ALTER TABLE companies
	ADD PRIMARY KEY (company_id);

ALTER TABLE credit_cards
	ADD PRIMARY KEY (id);

ALTER TABLE transactions
	ADD PRIMARY KEY (id),
    ADD CONSTRAINT fk_transactions_credit_cards
		FOREIGN KEY(card_id)
		REFERENCES credit_cards(id),
	ADD CONSTRAINT fk_transactions_companies
		FOREIGN KEY(business_id)
        REFERENCES companies(company_id),
	ADD CONSTRAINT fk_transactions_users
		FOREIGN KEY(global_user_id)
        REFERENCES users(global_user_id);
 
 # and constraints for transaction_details (excl. FK products table not yet created):
 
ALTER TABLE transaction_details
	MODIFY transaction_id VARCHAR(100) NOT NULL;
    
ALTER TABLE transaction_details
    ADD CONSTRAINT fk_transactions_details_transactions
		FOREIGN KEY(transaction_id)
		REFERENCES transactions(id);
	
/* Exercici 9
Realitza una subconsulta que mostri tots els usuaris amb més de 80 transaccions utilitzant almenys 2 taules.*/
SELECT*
FROM users
WHERE global_user_id IN (SELECT global_user_id
						FROM transactions
                        WHERE declined = 0
						GROUP BY global_user_id
						HAVING COUNT(id) > 80);
    
/* done with join to check results = OK
SELECT tr.global_user_id, u.name, u.surname, COUNT(tr.id)
FROM transactions tr
JOIN users u
	ON tr.global_user_id = u.global_user_id
WHERE tr.declined = 0
GROUP BY tr.global_user_id, u.name, u.surname
HAVING COUNT(tr.id) > 80;
*/

/* EXERCISE 10
Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, utilitza almenys 2 taules.
*/

SELECT co.company_name, cr.iban, ROUND(AVG(tr.amount),2) AS average_amount
FROM transactions tr
JOIN credit_cards cr
	ON tr.card_id = cr.id
JOIN companies co
	ON co.company_id = tr.business_id
WHERE co.company_name = "Donec Ltd"
	AND tr.declined = 0
GROUP BY co.company_name, cr.iban
ORDER BY ROUND(AVG(tr.amount),2) DESC;

/* _________ NIVELL 2 ____________________________________________________

Exercici 1
Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a 
l'empresa per vendes. Mostra la data de cada transacció juntament amb el total 
de les vendes.
*/
SELECT DATE(timestamp), SUM(amount)
FROM transactions
WHERE declined = 0
GROUP BY DATE(timestamp)
ORDER BY SUM(amount) DESC
LIMIT 5
;

/* Exercici 2
Presenta el nom, telèfon, país, data i amount, d'aquelles empreses que van 
realitzar transaccions amb un valor comprès entre 350 i 400 euros i en alguna 
d'aquestes dates: 29 d'abril del 2015, 20 de juliol del 2018 i 13 de març del 
2024. Ordena els resultats de major a menor quantitat.*/

SELECT co.company_name, co.phone, DATE(tr.timestamp), tr.amount
FROM companies co
JOIN transactions tr
	ON tr.business_id = co.company_id
WHERE DATE(tr.timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13')
	AND tr.amount BETWEEN 350 and 400
    AND declined = 0
ORDER BY tr.amount DESC;

SELECT DISTINCT declined
FROM transactions;

/* EXERCISE 3
Necessitem optimitzar l'assignació dels recursos i dependrà de la capacitat 
operativa que es requereixi, per la qual cosa et demanen la informació sobre 
la quantitat de transaccions que realitzen les empreses, però el departament 
de recursos humans és exigent i vol un llistat de les empreses on especifiquis 
si tenen igual o més de 400 transaccions o menys.*/

SELECT DISTINCT company_id, 
		company_name,
        CASE 
			WHEN company_id IN (SELECT tr.business_id
									FROM transactions tr
									WHERE declined = 0
									GROUP BY tr.business_id
									HAVING COUNT(tr.id) >= 400) 
						THEN "400 or more transactions"
						ELSE "less than 400 transactions" 
		END AS volume
FROM companies
ORDER BY volume DESC, company_name
;


/* EXERCISE 4
Elimina de la taula transaction el registre amb ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD de la base de dades.

#testing with SELECT statements first to check filter = OK

SELECT*
FROM transaction_details -- related record first
WHERE transaction_id = "000447FE-B650-4DCF-85DE-C7ED0EE1CAAD";

SELECT*
FROM transactions -- then source record
WHERE id = "000447FE-B650-4DCF-85DE-C7ED0EE1CAAD";*/


DELETE FROM transaction_details 
WHERE transaction_id = "000447FE-B650-4DCF-85DE-C7ED0EE1CAAD";

DELETE FROM transactions
WHERE id = "000447FE-B650-4DCF-85DE-C7ED0EE1CAAD";

/* EXERCISE 5:
La secció de màrqueting desitja tenir accés a informació específica per a realitzar anàlisi i estratègies
 efectives. S'ha sol·licitat crear una vista que proporcioni detalls clau sobre les companyies i les seves
 transaccions. Serà necessària que creïs una vista anomenada VistaMarketing que contingui la següent 
 informació: Nom de la companyia. Telèfon de contacte. País de residència. Mitjana de compra realitzat per 
 cada companyia. Presenta la vista creada, ordenant les dades de major a menor mitjana de compra.*/ 

SELECT decline_reason

CREATE VIEW VistaMarketing AS
SELECT co.company_name, co.phone, co.country, ROUND(avg_calc.average_amount,2) AS avg_amount
FROM companies co
JOIN (SELECT business_id, AVG(amount) AS average_amount 
		FROM transactions 
        WHERE declined = 0
        GROUP BY business_id) AS avg_calc
	ON avg_calc.business_id = co.company_id
ORDER BY avg_calc.average_amount DESC;

SELECT*
FROM VistaMarketing;

/* ______________NIVELL 3 _____________________________________
Nivell 3
Exercici 1
Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les tres últimes 
transaccions han estat declinades aleshores és inactiu, si almenys una no és rebutjada aleshores és 
actiu. 
Partint d’aquesta taula respon: Quantes targetes estan actives?*/

# window functions to get last3:

SELECT card_id, timestamp
FROM (SELECT*,
		ROW_NUMBER() OVER (
		PARTITION BY card_id
        ORDER BY timestamp DESC
	) AS transaction_order
	FROM transactions
) ordered
WHERE transaction_order <=3
;

# checking total number of different cards used in transactions = 5000
SELECT DISTINCT card_id
FROM transactions;

#checking just 3 transactions per card in CTE results = OK
SELECT COUNT(card_id)
FROM (SELECT*,
		ROW_NUMBER() OVER (
		PARTITION BY card_id
        ORDER BY timestamp DESC
	) AS transaction_order
	FROM transactions
	) ordered
WHERE transaction_order <=3
GROUP BY card_id
ORDER BY COUNT(card_id) DESC;


# window function saved as CTE, so can join with main query: = gives 4203 cards active
WITH last3 AS (
	SELECT card_id, timestamp
	FROM (SELECT*,
		ROW_NUMBER() OVER (
		PARTITION BY card_id
        ORDER BY timestamp DESC
	) AS transaction_order
	FROM transactions
	) ordered
	WHERE transaction_order <=3)
-- main query to get aggregate SUM of declined, right joined to CTE to calculate only on only top3:
SELECT tr.card_id, SUM(tr.declined)
FROM transactions tr
RIGHT JOIN last3
	ON last3.card_id = tr.card_id
GROUP BY tr.card_id
HAVING SUM(tr.declined) <=2;

# now checking against how many INACTIVE (sum = 3) = OK (797 cards declined last 3 transactions)
WITH last3 AS (
	SELECT card_id, timestamp
	FROM (SELECT*,
		ROW_NUMBER() OVER (
		PARTITION BY card_id
        ORDER BY timestamp DESC
	) AS transaction_order
	FROM transactions
	) ordered
	WHERE transaction_order <=3)
-- main query:
SELECT tr.card_id, SUM(tr.declined)
FROM transactions tr
RIGHT JOIN last3
	ON last3.card_id = tr.card_id
GROUP BY tr.card_id
HAVING SUM(tr.declined) >=3; -- INACTIVE

# now to create credit_card_status table and populate using this script with CASE:
DROP TABLE IF EXISTS credit_card_status;
CREATE TABLE credit_card_status(
	status_id INT AUTO_INCREMENT PRIMARY KEY,
    credit_card_id VARCHAR(50) NOT NULL,
    status_inactive INT
);

#create a view to identify the inactive cards via CTE and main query...
CREATE VIEW inactive_card AS
WITH last3 AS (
	SELECT card_id, timestamp
	FROM (SELECT*,
		ROW_NUMBER() OVER (
		PARTITION BY card_id
        ORDER BY timestamp DESC
	) AS transaction_order
	FROM transactions
	) ordered
	WHERE transaction_order <=3)
-- main query:
SELECT tr.card_id, SUM(tr.declined)
FROM transactions tr
RIGHT JOIN last3
	ON last3.card_id = tr.card_id
GROUP BY tr.card_id
HAVING SUM(tr.declined) >=3; -- INACTIVE;

#checking using view works:
SELECT id
FROM credit_cards
WHERE id = (SELECT card_id
					FROM inactive_card
                    WHERE card_id = credit_cards.id);


# 'insert into' to populate credit_card_status using inactive-card view in the CASE statement...
TRUNCATE TABLE credit_card_status;
INSERT INTO credit_card_status (
	credit_card_id,
    status_inactive
    )
SELECT
	id,
    CASE 
		WHEN id = (SELECT card_id
					FROM inactive_card
                    WHERE card_id = credit_cards.id) THEN 1
		ELSE 0
        END AS status_inactive
FROM credit_cards;
   
#adding FK to credit_card_status table:
ALTER TABLE credit_card_status
    ADD CONSTRAINT fk_credit_card_status_credit_cards
		FOREIGN KEY(credit_card_id)
		REFERENCES credit_cards(id);
   
 SELECT COUNT(*)
 FROM credit_card_status
 WHERE status_inactive = 0;

/* Exercici 2
Crea una taula amb la qual puguem unir les dades de l'arxiu de products.csv amb la 
base de dades creada (ja que fins ara no podíem fer-ho), tenint en compte que des 
de transaction tens product_ids. Genera la següent consulta:
Necessitem conèixer el nombre de vegades que s'ha venut cada producte. */



#creating table for raw import from csv:
DROP TABLE IF EXISTS raw_products;
CREATE TABLE raw_products(
	product_id VARCHAR(10) UNIQUE,
    product_name VARCHAR(100) NOT NULL,
	price VARCHAR(50),
    colour VARCHAR(20),
    weight FLOAT,
    warehouse_id VARCHAR(10),
    category VARCHAR(50),
    brand VARCHAR(50),
    cost VARCHAR(50),
    launch_date DATE
);

# importing data from csv (in secure path and with double backslashes):
TRUNCATE TABLE raw_products;
LOAD DATA
INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\N1-Ex.8__products.csv'
INTO TABLE raw_products
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 1 ROWS;

SELECT*
FROM raw_products;

# checking with SELECT removal of dollar sign
SELECT price, REPLACE(price,"$","") as not_money, cost
FROM raw_products
ORDER BY not_money;

#create final products table:
DROP TABLE IF EXISTS products;
CREATE TABLE products(
	product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
	price DECIMAL(10,2),
    colour VARCHAR(20),
    weight FLOAT,
    warehouse_id VARCHAR(10),
    category VARCHAR(50),
    brand VARCHAR(50),
    cost DECIMAL(10,2),
    launch_date DATE
);

# populate final products table with fixes:
TRUNCATE TABLE products;
INSERT INTO products (
	product_id,
    product_name,
	price,
    colour,
    weight,
    warehouse_id,
    category,
    brand,
    cost,
    launch_date
    )
SELECT
	product_id,
    product_name,
	CAST((REPLACE(price,"$","")) AS DECIMAL(10,2)),
    colour,
    weight,
    warehouse_id,
    category,
    brand,
    CAST((REPLACE(cost,"$","")) AS DECIMAL(10,2)),
    launch_date
FROM raw_products;

SELECT*
FROM products;

# adding FK to transaction_details table (on product_id)
# >>>> Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails
ALTER TABLE transaction_details
ADD CONSTRAINT fk_transaction_details_products
FOREIGN KEY(product_id)
REFERENCES products(product_id)
ON DELETE CASCADE;

# error due to whitespace in product_id in transaction_details table!
SELECT td.product_id, LENGTH(td.product_id), LENGTH(TRIM(td.product_id))
FROM products p
RIGHT JOIN transaction_details td
	ON td.product_id = p.product_id
WHERE p.product_id IS NULL;  

# removing whitespace on transaction_details product_id variable, first checking how many wrong (153389):
SELECT CHAR_LENGTH(product_id), CHAR_LENGTH(TRIM(product_id)), CHAR_LENGTH(product_id) - CHAR_LENGTH(TRIM(product_id))
FROM transaction_details
WHERE CHAR_LENGTH(product_id) - CHAR_LENGTH(TRIM(product_id)) != 0
ORDER BY CHAR_LENGTH(product_id);

# then updating
UPDATE transaction_details
SET product_id = TRIM(product_id)
WHERE details_id > 0;

# adding FK to transaction_details table (on product_id)
ALTER TABLE transaction_details
ADD CONSTRAINT fk_transaction_details_products
FOREIGN KEY(product_id)
REFERENCES products(product_id);

# QUESTION: Necessitem conèixer el nombre de vegades que s'ha venut cada producte.
SELECT pr.product_id, COUNT(pr.product_id) AS units_sold
FROM products pr
JOIN transaction_details td
	ON td.product_id = pr.product_id
JOIN transactions tr
	ON tr.id = td.transaction_id
WHERE declined = 0
GROUP BY pr.product_id
ORDER BY COUNT(pr.product_id) DESC;