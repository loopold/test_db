use employees;

delimiter //
drop function if exists emp_dept_id //
drop function if exists emp_dept_name //
drop function if exists emp_name //
drop function if exists current_manager //
drop procedure if exists show_departments //

--
-- returns the department id of a given employee
--
create function emp_dept_id( employee_id int )
returns char(4)
reads sql data
begin
    declare max_date date;
    set max_date = (
        select
            max(from_date)
        from
            dept_emp
        where
            employee_id = employee_id
    );
    set @max_date=max_date;
    return (
        select
            department_id
        from
            dept_emp
        where
            employee_id = employee_id
            and
            from_date = max_date
            limit 1
    );
end //

--
-- returns the department name of a given employee
--

create function emp_dept_name( employee_id int )
returns varchar(40)
reads sql data
begin
    return (
        select
            dept_name
        from
            departments
        where
            department_id = emp_dept_id(employee_id)
    );
end//

--
-- returns the employee name of a given employee id
--
create function emp_name (employee_id int)
returns varchar(32)
reads SQL data
begin
    return (
        select
            concat(first_name, ' ', last_name) as name
        from
            employees
        where
            employee_id = employee_id
    );
end//

--
-- returns the manager of a department
-- choosing the most recent one
-- from the manager list
--
create function current_manager( dept_id char(4) )
returns varchar(32)
reads sql data
begin
    declare max_date date;
    set max_date = (
        select
            max(from_date)
        from
            department_managers
        where
            department_id = dept_id
    );
    set @max_date=max_date;
    return (
        select
            emp_name(employee_id)
        from
            department_managers
        where
            department_id = dept_id
            and
            from_date = max_date
            limit 1
    );
end //

delimiter ;

--
--  selects the employee records with the
--  latest department
--

CREATE OR REPLACE VIEW  v_full_employees
AS
SELECT
    employee_id,
    first_name , last_name ,
    birth_date , gender,
    hire_date,
    emp_dept_name(employee_id) as department
from
    employees;

--
-- selects the department list with manager names
--

CREATE OR REPLACE VIEW v_full_departments
AS
SELECT
    department_id, dept_name, current_manager(department_id) as manager
FROM
    departments;

delimiter //

--
-- shows the departments with the number of employees
-- per department
--
create procedure show_departments()
modifies sql data
begin
    DROP TABLE IF EXISTS department_max_date;
    DROP TABLE IF EXISTS department_people;
    CREATE TEMPORARY TABLE department_max_date
    (
        employee_id int not null primary key,
        dept_from_date date not null,
        dept_to_date  date not null, # bug#320513
        KEY (dept_from_date, dept_to_date)
    );
    INSERT INTO department_max_date
    SELECT
        employee_id, max(from_date), max(to_date)
    FROM
        dept_emp
    GROUP BY
        employee_id;

    CREATE TEMPORARY TABLE department_people
    (
        employee_id int not null,
        department_id char(4) not null,
        primary key (employee_id, department_id)
    );

    insert into department_people
    select dmd.employee_id, department_id
    from
        department_max_date dmd
        inner join dept_emp de
            on dmd.dept_from_date=de.from_date
            and dmd.dept_to_date=de.to_date
            and dmd.employee_id=de.employee_id;
    SELECT
        department_id,dept_name,manager, count(*)
        from v_full_departments
            inner join department_people using (department_id)
        group by department_id;
        # with rollup;
    DROP TABLE department_max_date;
    DROP TABLE department_people;
end //

drop function if exists employees_usage //
drop procedure if exists employees_help //

CREATE FUNCTION employees_usage ()
RETURNS TEXT
DETERMINISTIC
BEGIN
    RETURN
'
    == USAGE ==
    ====================

    PROCEDURE show_departments()

        shows the departments with the manager and
        number of employees per department

    FUNCTION current_manager (dept_id)

        Shows who is the manager of a given departmennt

    FUNCTION emp_name (emp_id)

        Shows name and surname of a given employee

    FUNCTION emp_dept_id (emp_id)

        Shows the current department of given employee
';
END //

create procedure employees_help()
deterministic
begin
    select employees_usage() as info;
end//

delimiter ;

