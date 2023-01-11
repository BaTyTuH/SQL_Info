CREATE SCHEMA part4;

CREATE TABLE part4.weather
    (
        id bigint,
        name varchar,
        status varchar
    );

INSERT INTO part4.weather
VALUES (1, 'a', 'bad');
INSERT INTO part4.weather
VALUES (2, 'b', 'bad');
INSERT INTO part4.weather
VALUES (3, 'c', 'good');
INSERT INTO part4.weather
VALUES (3, 'c', NULL);
INSERT INTO part4.weather
VALUES (NULL, NULL, NULL);

CREATE TABLE part4.tablename
    (
        id bigint NOT NULL,
        name varchar NOT NULL,
        status varchar NOT NULL
    );

INSERT INTO part4.tablename
VALUES (1, 'x', 'bad');
INSERT INTO part4.tablename
VALUES (2, 'y', 'bad');
INSERT INTO part4.tablename
VALUES (3, 'z', 'good');

CREATE TABLE part4.stablename
    (
        id bigint NOT NULL,
        name varchar NOT NULL,
        status varchar NOT NULL
    );
INSERT INTO part4.stablename
VALUES (1, 'x', 'bad');
INSERT INTO part4.stablename
VALUES (2, 'y', 'bad');
INSERT INTO part4.stablename
VALUES (3, 'z', 'good');

CREATE TABLE part4.tablenameasd
    (
        id bigint NOT NULL,
        name varchar NOT NULL,
        status varchar NOT NULL
    );
INSERT INTO part4.tablenameasd
VALUES (1, 'x', 'bad');
INSERT INTO part4.tablenameasd
VALUES (2, 'x', 'bad');
INSERT INTO part4.tablenameasd
VALUES (3, 'x', 'bad');

CREATE OR REPLACE FUNCTION part4.lalala_func() RETURNS void AS
$$
BEGIN
    NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION part4.lalala_func_with_1param(int) RETURNS void AS
$$
BEGIN
    NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION part4.lalala_func_with_2param(int, int) RETURNS void AS
$$
BEGIN
    NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION part4.lalala_func_with_dif_param(int, time) RETURNS void AS
$$
BEGIN
    NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION part4.lalala_func_with_1param(varchar(5)) RETURNS void AS
$$
BEGIN
    NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION part4.for_trigger() RETURNS trigger AS
$trg_audit$
BEGIN
    NULL;
END;
$trg_audit$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit
    BEFORE INSERT
    ON part4.weather
    FOR EACH ROW
EXECUTE FUNCTION part4.for_trigger();


-------------------------Task1----------------------------

CREATE OR REPLACE PROCEDURE part4.first_task() AS
$$
DECLARE
    r varchar;
BEGIN
    FOR r IN SELECT table_name
               FROM information_schema.tables
              WHERE table_name ILIKE 'TableName%' AND table_schema = 'part4' LOOP
        EXECUTE FORMAT('drop table part4.%I cascade', r);
    END LOOP;
END
$$ LANGUAGE plpgsql;

CALL part4.first_task();


----------------------------------------------------------
-------------------------Task2----------------------------

CREATE OR REPLACE PROCEDURE part4.second_task(OUT countrec int, INOUT result refcursor = 'result') AS
$$
BEGIN
    OPEN result FOR SELECT routines.routine_name || '(' || ARRAY_TO_STRING(ARRAY_AGG(parameters.data_type), ', ') ||
                           ')' AS result
                      FROM information_schema.routines
                               JOIN information_schema.parameters
                               ON routines.specific_name = parameters.specific_name
                     WHERE routine_type = 'FUNCTION'
                       AND routines.specific_schema = 'part4'
                     GROUP BY routines.routine_name, routines.specific_name;
    countrec = (SELECT COUNT(*)
                  FROM (SELECT routines.routine_name || '(' || ARRAY_TO_STRING(ARRAY_AGG(parameters.data_type), ', ') ||
                               ')' AS result
                          FROM information_schema.routines
                                   JOIN information_schema.parameters
                                   ON routines.specific_name = parameters.specific_name
                         WHERE routine_type = 'FUNCTION'
                           AND routines.specific_schema = 'part4'
                         GROUP BY routines.routine_name, routines.specific_name) AS t);
END
$$ LANGUAGE plpgsql;


BEGIN;
CALL part4.second_task(NULL, 'result');
FETCH ALL FROM "result";
END;

----------------------------------------------------------
-------------------------Task3----------------------------

CREATE OR REPLACE PROCEDURE part4.third_task(OUT int) AS
$$
DECLARE
    r record;
BEGIN
    $1 = 0;
    FOR r IN SELECT trigger_name AS name, event_object_table AS table
               FROM information_schema.triggers
              WHERE trigger_schema = 'part4' LOOP
        EXECUTE FORMAT('drop trigger %I on part4.%I cascade', r.name, r.table);
        $1 = $1 + 1;
    END LOOP;
END
$$ LANGUAGE plpgsql;

CALL part4.third_task(NULL);

----------------------------------------------------------
-------------------------Task4----------------------------

CREATE OR REPLACE PROCEDURE part4.fourth_task(string varchar, INOUT result_4 refcursor = 'result_4') AS
$$
BEGIN
    OPEN result_4 FOR (WITH task AS (SELECT PG_GET_FUNCTIONDEF(f.oid) AS text, proname AS name, prokind AS type
                                       FROM pg_catalog.pg_proc f
                                                JOIN pg_catalog.pg_namespace n
                                                ON f.pronamespace = n.oid
                                      WHERE prokind != 'a'
                                        AND n.nspname = 'part4')

                     SELECT name, type
                       FROM task
                      WHERE text LIKE CONCAT('%', $1, '%'));
END
$$ LANGUAGE plpgsql;


BEGIN;
CALL part4.fourth_task('procedure', 'result');
FETCH ALL FROM "result";
END;
