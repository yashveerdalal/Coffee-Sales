
CREATE DATABASE IF NOT EXISTS `coffeeSales`;
USE `coffeeSales`;

DROP TABLE IF EXISTS `coffee_sales_source`;
CREATE TABLE `coffee_sales_source` (
    `date`         VARCHAR(20),
    `datetime`     VARCHAR(40),
    `cash_type`    VARCHAR(20),
    `card`         VARCHAR(40),
    `money`        VARCHAR(20),
    `coffee_name`  VARCHAR(60)
);

LOAD DATA LOCAL INFILE '/Users/yashdalal/Desktop/coffee_sales.csv'
INTO TABLE `coffee_sales_source`
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

DROP TABLE IF EXISTS `coffee_sales_stageA`;
CREATE TABLE `coffee_sales_stageA` AS
SELECT * FROM `coffee_sales_source`;

ALTER TABLE `coffee_sales_stageA`
  ADD COLUMN `cleaned_date`      DATE,
  ADD COLUMN `cleaned_time`      TIME,
  ADD COLUMN `cleaned_money`     DECIMAL(10,2),
  ADD COLUMN `product_cleaned`   VARCHAR(60),
  ADD COLUMN `payment_cleaned`   VARCHAR(20);

UPDATE `coffee_sales_stageA`
SET `cleaned_date` = CASE
        WHEN `date` LIKE '__/__/__'   THEN STR_TO_DATE(`date`, '%d/%m/%y')
        WHEN `date` LIKE '____-__-__' THEN CAST(`date` AS DATE)
        ELSE NULL
    END
WHERE `cleaned_date` IS NULL;

UPDATE `coffee_sales_stageA`
SET `cleaned_time` = CASE
        WHEN `datetime` LIKE '%:%:%' AND `datetime` LIKE '% %' THEN
             STR_TO_DATE(SUBSTRING_INDEX(`datetime`, ' ', -1), '%H:%i:%s.%f')
        WHEN `datetime` LIKE '__:__._%' AND 
             SUBSTRING_INDEX(`datetime`, ':', 1) + 0 BETWEEN 0 AND 23 THEN
             STR_TO_DATE(`datetime`, '%H:%i.%s')
        WHEN `datetime` LIKE '__:__:__' AND 
             SUBSTRING_INDEX(`datetime`, ':', 1) + 0 BETWEEN 0 AND 23 THEN
             STR_TO_DATE(`datetime`, '%H:%i:%s')
        ELSE NULL
    END
WHERE `cleaned_time` IS NULL;

UPDATE `coffee_sales_stageA`
SET `cleaned_money` = CAST(`money` AS DECIMAL(10,2))
WHERE `cleaned_money` IS NULL;

UPDATE `coffee_sales_stageA`
SET `product_cleaned` = TRIM(`coffee_name`)
WHERE `product_cleaned` IS NULL;

UPDATE `coffee_sales_stageA`
SET `payment_cleaned` = LOWER(TRIM(`cash_type`))
WHERE `payment_cleaned` IS NULL;

DROP TABLE IF EXISTS `coffee_sales_stageB`;
CREATE TABLE `coffee_sales_stageB` AS
SELECT
    cleaned_date     AS order_date,
    cleaned_time     AS order_time,
    payment_cleaned  AS payment_type,
    card             AS customer_card,
    cleaned_money    AS amount_spent,
    product_cleaned  AS product
FROM   `coffee_sales_stageA`;

SELECT COUNT(*)        AS total_rows,
       MIN(order_date) AS first_date,
       MAX(order_date) AS last_date,
       COUNT(IF(order_time IS NULL,1,NULL)) AS null_times
FROM   `coffee_sales_stageB`;

SELECT * FROM `coffee_sales_stageB` LIMIT 20;
