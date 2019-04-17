--  Sample employee database 
--  See changelog table for details
--  Copyright (C) 2007,2008, MySQL AB
--  
--  Original data created by Fusheng Wang and Carlo Zaniolo
--  http://www.cs.aau.dk/TimeCenter/software.htm
--  http://www.cs.aau.dk/TimeCenter/Data/employeeTemporalDataSet.zip
-- 
--  Current schema by Giuseppe Maxia 
--  Data conversion from XML to relational by Patrick Crews
-- 
-- This work is licensed under the 
-- Creative Commons Attribution-Share Alike 3.0 Unported License. 
-- To view a copy of this license, visit 
-- http://creativecommons.org/licenses/by-sa/3.0/ or send a letter to 
-- Creative Commons, 171 Second Street, Suite 300, San Francisco, 
-- California, 94105, USA.
-- 
--  DISCLAIMER
--  To the best of our knowledge, this data is fabricated, and
--  it does not correspond to real people. 
--  Any similarity to existing people is purely coincidental.
-- 

DROP DATABASE IF EXISTS employees_development;
CREATE DATABASE IF NOT EXISTS employees_development;
USE employees_development;

SELECT 'CREATING DATABASE STRUCTURE' as 'INFO';

DROP TABLE IF EXISTS department_employees,
                     department_managers,
                     titles,
                     salaries, 
                     employees, 
                     departments;

/*!50503 set default_storage_engine = InnoDB */;
/*!50503 select CONCAT('storage engine: ', @@default_storage_engine) as INFO */;

CREATE TABLE employees (
    employee_id      INT             NOT NULL,
    birth_date  DATE            NOT NULL,
    first_name  VARCHAR(14)     NOT NULL,
    last_name   VARCHAR(16)     NOT NULL,
    gender      ENUM ('M','F')  NOT NULL,    
    hire_date   DATE            NOT NULL,
    PRIMARY KEY (employee_id)
);

CREATE TABLE departments (
    department_id     CHAR(4)         NOT NULL,
    dept_name   VARCHAR(40)     NOT NULL,
    PRIMARY KEY (department_id),
    UNIQUE  KEY (dept_name)
);

CREATE TABLE department_managers (
   employee_id       INT             NOT NULL,
   department_id      CHAR(4)         NOT NULL,
   from_date    DATE            NOT NULL,
   to_date      DATE            NOT NULL,
   FOREIGN KEY (employee_id)  REFERENCES employees (employee_id)    ON DELETE CASCADE,
   FOREIGN KEY (department_id) REFERENCES departments (department_id) ON DELETE CASCADE,
   PRIMARY KEY (employee_id,department_id)
); 

CREATE TABLE department_employees (
    employee_id      INT             NOT NULL,
    department_id     CHAR(4)         NOT NULL,
    from_date   DATE            NOT NULL,
    to_date     DATE            NOT NULL,
    FOREIGN KEY (employee_id)  REFERENCES employees   (employee_id)  ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES departments (department_id) ON DELETE CASCADE,
    PRIMARY KEY (employee_id,department_id)
);

CREATE TABLE titles (
    employee_id      INT             NOT NULL,
    title       VARCHAR(50)     NOT NULL,
    from_date   DATE            NOT NULL,
    to_date     DATE,
    FOREIGN KEY (employee_id) REFERENCES employees (employee_id) ON DELETE CASCADE,
    PRIMARY KEY (employee_id,title, from_date)
) 
; 

CREATE TABLE salaries (
    employee_id      INT             NOT NULL,
    amount      INT             NOT NULL,
    from_date   DATE            NOT NULL,
    to_date     DATE            NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employees (employee_id) ON DELETE CASCADE,
    PRIMARY KEY (employee_id, from_date)
) 
; 

CREATE OR REPLACE VIEW department_employees_latest_date AS
    SELECT employee_id, MAX(from_date) AS from_date, MAX(to_date) AS to_date
    FROM department_employees
    GROUP BY employee_id;

# shows only the current department for each employee
CREATE OR REPLACE VIEW current_department_employees AS
    SELECT l.employee_id, department_id, l.from_date, l.to_date
    FROM department_employees d
        INNER JOIN department_employees_latest_date l
        ON d.employee_id=l.employee_id AND d.from_date=l.from_date AND l.to_date = d.to_date;

flush /*!50503 binary */ logs;

SELECT 'LOADING departments' as 'INFO';
source load_departments.dump ;
SELECT 'LOADING employees' as 'INFO';
source load_employees.dump ;
SELECT 'LOADING department_employees' as 'INFO';
source load_department_employees.dump ;
SELECT 'LOADING department_managers' as 'INFO';
source load_department_managers.dump ;
SELECT 'LOADING titles' as 'INFO';
source load_titles.dump ;
SELECT 'LOADING salaries' as 'INFO';
source load_salaries1.dump ;
source load_salaries2.dump ;
source load_salaries3.dump ;

source show_elapsed.sql ;
