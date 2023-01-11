-----------------------------------Task1-------------------------------------

CREATE OR REPLACE PROCEDURE add_p2p(checkedpeer varchar, checkingpeer varchar, task varchar,
                                    state varchar, "time" time) AS
$$
DECLARE
    idxcheck1 bigint := (SELECT MAX(id) + 1
                           FROM checks);
    idxcheck2 bigint := (SELECT MAX("Check")
                           FROM p2p
                          WHERE p2p.state = 'Start'
                            AND p2p.checkingpeer = add_p2p.checkingpeer);
    idxp2p    bigint := (SELECT MAX(id) + 1
                           FROM p2p);
BEGIN
    IF state = 'Start' THEN
        EXECUTE FORMAT('insert into Checks values (%L, %L, %L, %L)', idxcheck1, checkedpeer, task, CURRENT_DATE);
        EXECUTE FORMAT('insert into P2P values (%L, %L, %L, %L, %L)', idxp2p, idxcheck1, checkingpeer, state, "time");
    ELSE
        EXECUTE FORMAT('insert into P2P values (%L, %L, %L, %L, %L)', idxp2p, idxcheck2, checkingpeer, state, "time");
    END IF;
END;
$$ LANGUAGE plpgsql;

--------Tests for task1------------

CALL add_p2p('ddrizzle', 'mtickler', 'CPP7_MLP', 'Start', '22:23');
CALL add_p2p('ddrizzle', 'mtickler', 'CPP7_MLP', 'Success', '23:23');

SELECT *
  FROM checks
 WHERE peer = 'ddrizzle'
   AND task = 'CPP7_MLP';
SELECT *
  FROM p2p
 WHERE checkingpeer = 'mtickler'
   AND "Time" = '22:23' OR "Time" = '23:23';

DELETE
  FROM p2p
 WHERE "Check" IN (SELECT id FROM checks WHERE "Date" = CURRENT_DATE);
DELETE
  FROM checks
 WHERE "Date" = CURRENT_DATE;

-----------------------------------------------------------------------------
-----------------------------------Task2-------------------------------------

CREATE OR REPLACE PROCEDURE add_verter(checkedpeer varchar, task varchar, state varchar, "time" time) AS
$$
DECLARE
    idxcheck  bigint := (SELECT MAX("Check")
                           FROM p2p
                                    JOIN checks
                                    ON p2p."Check" = checks.id
                          WHERE p2p.state = 'Success'
                            AND checks.peer = add_verter.checkedpeer
                            AND checks.task = add_verter.task);
    idxverter bigint := (SELECT MAX(id) + 1
                           FROM verter);
BEGIN
    EXECUTE FORMAT('insert into Verter values (%L, %L, %L, %L)', idxverter, idxcheck, state, "time");
END;
$$ LANGUAGE plpgsql;

--------Tests for task2------------
CALL add_p2p('ddrizzle', 'mtickler', 'CPP7_MLP', 'Start', '22:23');
CALL add_p2p('ddrizzle', 'mtickler', 'CPP7_MLP', 'Success', '23:23');

CALL add_verter('ddrizzle', 'CPP7_MLP', 'Start', '20:21');

SELECT *
  FROM verter
 WHERE "Time" = '20:21';

DELETE
  FROM verter
 WHERE "Check" IN (SELECT id FROM checks WHERE "Time" = '20:21');


-----------------------------------------------------------------------------
-----------------------------------Task3-------------------------------------

CREATE OR REPLACE FUNCTION change_transferredpoints() RETURNS trigger AS
$trg_p2p_audit$
DECLARE
    checkedpeers varchar := (SELECT peer
                               FROM p2p
                                        JOIN checks c
                                        ON p2p."Check" = c.id
                              WHERE state = 'Start'
                                AND c.id = new."Check");
BEGIN
    UPDATE transferredpoints
       SET pointsamount = pointsamount + 1
     WHERE checkingpeer = new.checkingpeer
       AND checkedpeer = checkedpeers;
    RETURN new;
END;
$trg_p2p_audit$ LANGUAGE plpgsql;

CREATE TRIGGER trg_p2p_audit
    AFTER INSERT
    ON p2p
    FOR EACH ROW
EXECUTE FUNCTION change_transferredpoints();

--------Tests for task3------------

SELECT *
  FROM transferredpoints
 WHERE checkedpeer = 'kwukong'
   AND checkingpeer = 'bernarda';

CALL add_p2p('kwukong', 'bernarda', 'CPP7_MLP', 'Start', '09:37');

DELETE
  FROM p2p
 WHERE "Check" IN (SELECT id FROM checks WHERE "Date" = CURRENT_DATE);
DELETE
  FROM checks
 WHERE "Date" = CURRENT_DATE;
UPDATE transferredpoints
   SET pointsamount = 0
 WHERE checkedpeer = 'kwukong'
   AND checkingpeer = 'bernarda';


-----------------------------------------------------------------------------
-----------------------------------Task4-------------------------------------

CREATE OR REPLACE FUNCTION check_xp() RETURNS trigger AS
$trg_xp_audit$
BEGIN
    IF (new.xpamount > (SELECT maxxp
                          FROM checks
                                   JOIN tasks
                                   ON checks.task = tasks.title
                         WHERE checks.id = new."Check")) OR
       (NOT EXISTS(SELECT * FROM p2p WHERE p2p."Check" = new."Check" AND p2p.state = 'Success')) OR
       (EXISTS(SELECT * FROM verter WHERE verter."Check" = new."Check" AND verter.state = 'Start') AND
        NOT EXISTS(SELECT * FROM verter WHERE verter."Check" = new."Check" AND verter.state = 'Success')) THEN
--         RETURN NULL;
        RAISE EXCEPTION 'Can''t add this amount of xp';
    ELSE
        RETURN new;
    END IF;
END
$trg_xp_audit$ LANGUAGE plpgsql;

CREATE TRIGGER trg_p2p_audit
    BEFORE INSERT
    ON xp
    FOR EACH ROW
EXECUTE FUNCTION check_xp();

--------Tests for task4------------

INSERT INTO xp
VALUES ((SELECT MAX(id) + 1 FROM xp), 7, 201); -- проверка вертера failure
INSERT INTO xp
VALUES ((SELECT MAX(id) + 1 FROM xp), 8, 202); -- проверка вертера не закончена
INSERT INTO xp
VALUES ((SELECT MAX(id) + 1 FROM xp), 1, 900); -- опыта больше чем возможно получить
INSERT INTO xp
VALUES ((SELECT MAX(id) + 1 FROM xp), 2, 203); -- проверка р2р failure
INSERT INTO xp
VALUES ((SELECT MAX(id) + 1 FROM xp), 1, 204); -- нормальное значение

SELECT *
  FROM xp
 WHERE id = (SELECT MAX(id) FROM xp);

DELETE
  FROM xp
 WHERE id = (SELECT MAX(id) FROM xp);
