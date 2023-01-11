-- task1

CREATE OR REPLACE FUNCTION func_p3t1()
    RETURNS table
                (
                    peer1 varchar,
                    peer2 varchar,
                    pointsamount bigint
                )
AS
$$
  WITH cte AS (SELECT checkingpeer AS peer1, checkedpeer AS peer2, pointsamount AS pointsamount
                 FROM transferredpoints
                WHERE checkingpeer < checkedpeer
                UNION ALL
               SELECT checkedpeer AS peer1, checkingpeer AS peer2, -pointsamount AS pointsamount
                 FROM transferredpoints
                WHERE checkingpeer > checkedpeer
                ORDER BY peer1, peer2)
SELECT peer1, peer2, SUM(pointsamount) AS pointsamount
  FROM cte
 GROUP BY peer1, peer2;
$$ LANGUAGE sql;

SELECT *
  FROM func_p3t1();

-- task2

CREATE OR REPLACE FUNCTION func_p3t2()
    RETURNS table
                (
                    peer varchar,
                    task varchar,
                    xp bigint
                )
AS
$$
SELECT peer AS peer, task AS task, xpamount AS xp
  FROM xp
           JOIN checks c
           ON xp."Check" = c.id;
$$ LANGUAGE sql;

SELECT *
  FROM func_p3t2();

-- task3

CREATE OR REPLACE FUNCTION func_p3t3(IN pdate date DEFAULT CURRENT_DATE)
    RETURNS table
                (
                    peer varchar
                )
AS
$$
  WITH s AS (SELECT COUNT(peer) AS count, peer FROM timetracking WHERE "Date" = pdate GROUP BY peer)
SELECT peer
  FROM s
 WHERE count = 2;
$$ LANGUAGE sql;
END;

SELECT *
  FROM func_p3t3('2023-01-02');

-- task4

CREATE OR REPLACE PROCEDURE proc_p3t4(OUT res refcursor) AS
$$
BEGIN
    res = 'result';
    OPEN res FOR WITH states AS (SELECT p.state AS ps, v.state AS vs
                                   FROM checks
                                            FULL JOIN p2p p
                                            ON checks.id = p."Check"
                                            FULL JOIN verter v
                                            ON checks.id = v."Check"
                                  WHERE p.state != 'Start'
                                    AND (v.state IS NULL OR v.state != 'Start')),
                      a AS (SELECT COUNT(state) AS all FROM p2p WHERE state = 'Start'),
                      s AS (SELECT COUNT(ps) AS success
                              FROM states
                             WHERE ps = 'Success' AND (vs IS NULL OR vs = 'Success')),
                      f AS (SELECT COUNT(ps) AS failure FROM states WHERE ps = 'Failure' OR vs = 'Failure')
               SELECT ROUND(100.0 * s.success / a.all, 2) AS successfulchecks,
                      ROUND(100.0 * f.failure / a.all, 2) AS unsuccessfulchecks
                 FROM a
                          NATURAL JOIN s
                          NATURAL JOIN f;
END
$$ LANGUAGE plpgsql;

BEGIN;
CALL proc_p3t4(NULL);
FETCH ALL FROM "result";
END;


-- task5
CREATE OR REPLACE PROCEDURE proc_p3t5(OUT res refcursor) AS
$$
BEGIN
    res = 'result';
    OPEN res FOR WITH i AS (SELECT checkingpeer, SUM(pointsamount) AS income
                              FROM transferredpoints
                             GROUP BY checkingpeer),
                      o AS (SELECT checkedpeer, SUM(pointsamount) AS outcome
                              FROM transferredpoints
                             GROUP BY checkedpeer)
               SELECT checkedpeer AS peer, (income - outcome) AS pointschange
                 FROM i
                          FULL JOIN o
                          ON checkedpeer = checkingpeer
                ORDER BY pointschange DESC;
END
$$ LANGUAGE plpgsql;

BEGIN;
CALL proc_p3t5(NULL);
FETCH ALL FROM "result";
END;

-- task6

CREATE OR REPLACE PROCEDURE proc_p3t6(INOUT res refcursor) AS
$$
BEGIN
    res = 'result';
    OPEN res FOR WITH i AS (SELECT peer1 AS peer, SUM(pointsamount) AS pointschange
                              FROM (SELECT * FROM func_p3t1()) AS s1
                             GROUP BY peer),
                      o AS (SELECT peer2 AS peer, -SUM(pointsamount) AS pointschange
                              FROM (SELECT * FROM func_p3t1()) AS s2
                             GROUP BY peer),
                      pc AS (SELECT * FROM i UNION SELECT * FROM o)
               SELECT peer, SUM(pointschange) AS pointschange
                 FROM pc
                GROUP BY peer
                ORDER BY pointschange DESC;
END
$$ LANGUAGE plpgsql;

BEGIN;
CALL proc_p3t6(NULL);
FETCH ALL FROM "result";
COMMIT;
END;

-- task7
CREATE OR REPLACE PROCEDURE proc_p3t7(OUT res refcursor) AS
$$
BEGIN
    res = 'result';
    OPEN res FOR WITH cte AS (SELECT COUNT(*) AS count, task, "Date" FROM checks GROUP BY "Date", task ORDER BY "Date"),
                      cte2 AS (SELECT "Date", MAX(count) AS max FROM cte GROUP BY "Date")
               SELECT cte."Date" AS day, task AS task
                 FROM cte2
                          JOIN cte
                          ON cte."Date" = cte2."Date" AND cte.count = cte2.max;
END
$$ LANGUAGE plpgsql;

BEGIN;
CALL proc_p3t7(NULL);
FETCH ALL FROM "result";
COMMIT;
END;

-- task8

CREATE OR REPLACE PROCEDURE proc_p3t8(OUT check_duration time) AS
$$
BEGIN
    check_duration = (WITH cte AS (SELECT *
                                     FROM p2p
                                              JOIN checks c
                                              ON c.id = p2p."Check"),
                           cte2 AS (SELECT MAX("Date") AS mdate, MAX("Time") AS mtime
                                      FROM cte
                                     WHERE state IN ('Success', 'Failure')),
                           cte3 AS (SELECT "Check" AS last
                                      FROM cte,
                                           cte2
                                     WHERE "Date" = cte2.mdate
                                       AND "Time" = cte2.mtime)
                    SELECT MAX("Time") - MIN("Time")
                      FROM p2p,
                           cte3
                     WHERE "Check" = cte3.last);
END
$$ LANGUAGE plpgsql;

CALL proc_p3t8(NULL);

-- task9

CREATE OR REPLACE PROCEDURE proc_p3t9(name varchar, OUT res refcursor) AS
$$
BEGIN
    res = 'result';
    OPEN res FOR WITH lasttask AS (SELECT MAX(title) AS title
                                     FROM tasks
                                    WHERE title IN
                                          (SELECT UNNEST(REGEXP_MATCHES(title, CONCAT('(', name, '\d.*)'))) FROM tasks))
               SELECT peer, "Date" AS day
                 FROM checks
                          FULL JOIN p2p p
                          ON checks.id = p."Check"
                          FULL JOIN verter v
                          ON checks.id = v."Check"
                          JOIN lasttask
                          ON checks.task = lasttask.title
                WHERE p.state = 'Success'
                  AND v.state NOT IN ('Start', 'Failure')
                ORDER BY day;
END
$$ LANGUAGE plpgsql;

BEGIN;
CALL proc_p3t9('A', NULL);
FETCH ALL FROM "result";
COMMIT;
END;

-- task10

CREATE OR REPLACE PROCEDURE proc_p3t10(OUT res refcursor) AS
$$
BEGIN
    res = 'result';
    OPEN res FOR WITH fr AS (SELECT nickname, f.peer2 AS friend
                               FROM peers
                                        JOIN friends f
                                        ON peers.nickname = f.peer1
                              UNION ALL
                             SELECT nickname, f2.peer1 AS friend
                               FROM peers
                                        JOIN friends f2
                                        ON peers.nickname = f2.peer2),
                      rec AS (SELECT *
                                FROM fr
                                         JOIN recommendations r
                                         ON r.peer = fr.friend
                               WHERE nickname != recommendedpeer),
                      rec2 AS (SELECT nickname, COUNT(recommendedpeer) AS count, recommendedpeer
                                 FROM rec
                                GROUP BY nickname, recommendedpeer),
                      m AS (SELECT MAX(count) AS count, nickname FROM rec2 GROUP BY nickname)
               SELECT rec2.nickname AS peer, recommendedpeer
                 FROM rec2
                          JOIN m
                          ON m.nickname = rec2.nickname AND m.count = rec2.count
                ORDER BY peer;
END
$$ LANGUAGE plpgsql;

BEGIN;
CALL proc_p3t10(NULL);
FETCH ALL FROM "result";
COMMIT;
END;

--  task11

CREATE OR REPLACE PROCEDURE proc_p3t11(nameblock1 varchar, nameblock2 varchar,
                                       OUT startedblock1 float, OUT startedblock2 float,
                                       OUT startedbothblocks float, OUT didntstartanyblock float) AS
$$
DECLARE
    countpeers bigint := (SELECT COUNT(nickname)
                            FROM peers);
BEGIN
    IF countpeers > 0 THEN
        startedbothblocks = (SELECT COUNT(a.peer) / (countpeers / 100.0)
                               FROM ((SELECT peer
                                        FROM checks
                                       WHERE task IN
                                             (SELECT UNNEST(REGEXP_MATCHES(title, CONCAT('(', nameblock1, '\d.*)')))
                                                FROM tasks)
                                       GROUP BY peer)
                               INTERSECT
                               (SELECT peer
                                  FROM checks
                                 WHERE task IN (SELECT UNNEST(REGEXP_MATCHES(title, CONCAT('(', nameblock2, '\d.*)')))
                                                  FROM tasks)
                                 GROUP BY peer)) AS a);
        startedblock1 = (SELECT (COUNT(a.peer) / (countpeers / 100.0) - startedbothblocks)
                           FROM (SELECT peer
                                   FROM checks
                                  WHERE task IN (SELECT UNNEST(REGEXP_MATCHES(title, CONCAT('(', nameblock1, '\d.*)')))
                                                   FROM tasks)
                                  GROUP BY peer) AS a);
        startedblock2 = (SELECT (COUNT(a.peer) / (countpeers / 100.0) - startedbothblocks)
                           FROM (SELECT peer
                                   FROM checks
                                  WHERE task IN (SELECT UNNEST(REGEXP_MATCHES(title, CONCAT('(', nameblock2, '\d.*)')))
                                                   FROM tasks)
                                  GROUP BY peer) AS a);

        didntstartanyblock = 100 - startedblock1 - startedblock2 - startedbothblocks;
    ELSE
        startedblock1 = 0;
        startedblock2 = 0;
        startedbothblocks = 0;
        didntstartanyblock = 0;
    END IF;
END;
$$ LANGUAGE plpgsql;

CALL proc_p3t11('C', 'CPP', NULL, NULL, NULL, NULL);

-- task12

CREATE OR REPLACE PROCEDURE proc_p3t12(n integer, INOUT _result_one refcursor = '_result_one')
    LANGUAGE plpgsql AS
$$
BEGIN
    OPEN _result_one FOR SELECT COUNT(peer) AS count, peer
                           FROM (SELECT id, peer1 AS peer FROM friends UNION SELECT id, peer2 AS peer FROM friends) AS l
                          GROUP BY peer
                          ORDER BY count DESC
                          LIMIT n;
END;
$$;

BEGIN;
CALL proc_p3t12(2, '_result_one');
FETCH ALL FROM "_result_one";
COMMIT;

-- task 13

CREATE OR REPLACE PROCEDURE proc_p3t13(OUT successfulchecks float, OUT unsuccessfulchecks float) AS
$$
BEGIN
      WITH countpeers AS (SELECT COUNT(nickname) AS "count" FROM peers),
           successonbirthday AS (SELECT peers.nickname
                                   FROM peers
                                            JOIN checks c
                                            ON peers.nickname = c.peer
                                            JOIN p2p
                                            ON p2p."Check" = c.id
                                            JOIN verter v
                                            ON v."Check" = c.id
                                  WHERE EXTRACT(DAY FROM peers.birthday) = EXTRACT(DAY FROM c."Date")
                                    AND EXTRACT(MONTH FROM peers.birthday) = EXTRACT(MONTH FROM c."Date")
                                    AND p2p.state = 'Success'
                                    AND v.state = 'Success'
                                  GROUP BY peers.nickname)
    SELECT (COUNT(distnicks.nickname) * (SELECT 100.0 / "count" FROM countpeers))
      INTO successfulchecks
      FROM (SELECT * FROM successonbirthday) AS distnicks;

      WITH countpeers AS (SELECT COUNT(nickname) AS "count" FROM peers),
           unsuccessonbirthday AS (SELECT peers.nickname
                                     FROM peers
                                              JOIN checks c
                                              ON peers.nickname = c.peer
                                              JOIN p2p
                                              ON p2p."Check" = c.id
                                              JOIN verter v
                                              ON v."Check" = c.id
                                    WHERE EXTRACT(DAY FROM peers.birthday) = EXTRACT(DAY FROM c."Date")
                                      AND EXTRACT(MONTH FROM peers.birthday) = EXTRACT(MONTH FROM c."Date")
                                      AND p2p.state = 'Failure'
                                      AND v.state = 'Failure'
                                    GROUP BY peers.nickname)
    SELECT (COUNT(distnicks.nickname) * (SELECT 100.0 / "count" FROM countpeers))
      INTO unsuccessfulchecks
      FROM (SELECT * FROM unsuccessonbirthday) AS distnicks;
END;
$$ LANGUAGE plpgsql;

CALL proc_p3t13(NULL, NULL);

-- task 14

CREATE OR REPLACE PROCEDURE proc_p3t14(OUT tab refcursor) AS
$$
BEGIN
    tab = 'peer_list';
    OPEN tab FOR WITH nicktaskxp AS (SELECT peers.nickname, c.task, MAX(xp.xpamount) AS xp
                                       FROM peers
                                                JOIN checks c
                                                ON peers.nickname = c.peer
                                                JOIN xp
                                                ON c.id = xp."Check"
                                      GROUP BY peers.nickname, c.task)
               SELECT nickname AS peer, SUM(xp) AS xp
                 FROM nicktaskxp
                GROUP BY nickname;
END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL proc_p3t14(NULL);
FETCH ALL FROM "peer_list";
COMMIT;
END;

-- task 15

CREATE OR REPLACE PROCEDURE proc_p3t15(nameblock1 varchar, nameblock2 varchar, nameblock3 varchar,
                                       OUT peers refcursor) AS
$$
BEGIN
    peers = 'peer_list';
    OPEN peers FOR WITH joinedtable AS (SELECT peers.nickname AS nickname, c.task AS task, p2p.state AS p2pstate,
                                               v.state AS vstate
                                          FROM peers
                                                   JOIN checks c
                                                   ON peers.nickname = c.peer
                                                   JOIN p2p
                                                   ON c.id = p2p."Check"
                                                   LEFT JOIN verter v
                                                   ON c.id = v."Check"),
                        success1 AS (SELECT s1.nickname
                                       FROM (SELECT *
                                               FROM joinedtable
                                              WHERE joinedtable.task = nameblock1
                                                AND joinedtable.p2pstate = 'Success'
                                                AND (joinedtable.vstate = 'Success' OR joinedtable.vstate IS NULL)) AS s1
                                      GROUP BY s1.nickname),
                        success2 AS (SELECT s2.nickname
                                       FROM (SELECT *
                                               FROM joinedtable
                                              WHERE joinedtable.task = nameblock2
                                                AND joinedtable.p2pstate = 'Success'
                                                AND (joinedtable.vstate = 'Success' OR joinedtable.vstate IS NULL)) AS s2
                                      GROUP BY s2.nickname),
                        unsuccess3 AS (SELECT nickname
                                         FROM peers
                                       EXCEPT
                                       SELECT s2.nickname
                                         FROM (SELECT *
                                                 FROM joinedtable
                                                WHERE joinedtable.task = nameblock3
                                                  AND joinedtable.p2pstate = 'Success'
                                                  AND (joinedtable.vstate = 'Success' OR joinedtable.vstate IS NULL)) AS s2
                                        GROUP BY s2.nickname)
                 SELECT *
                   FROM (SELECT * FROM success1 INTERSECT SELECT * FROM success2) AS success
              INTERSECT
                 SELECT *
                   FROM unsuccess3;
END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL proc_p3t15('A1_Maze', 'CPP7_MLP', 'DO1_Linux', NULL);
FETCH ALL FROM "peer_list";
COMMIT;
END;

-- task 16

CREATE OR REPLACE PROCEDURE proc_p3t16(OUT task refcursor) AS
$$
BEGIN
    task = 'Task';
    OPEN task FOR WITH RECURSIVE ptasks AS (SELECT title AS task, 0 AS prevcount
                                              FROM tasks
                                             WHERE parenttask IS NULL
                                             UNION ALL
                                            SELECT tasks.title, ptasks.prevcount + 1 AS prevcount
                                              FROM tasks
                                                       JOIN ptasks
                                                       ON tasks.parenttask = ptasks.task)
                SELECT *
                  FROM ptasks;
END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL proc_p3t16(NULL);
FETCH ALL FROM "Task";
COMMIT;
END;

-- task 17

CREATE OR REPLACE FUNCTION func_on_every_day(n integer, day date) RETURNS boolean AS
$$
DECLARE
    i integer := 0;
    r record;
BEGIN
    FOR r IN (WITH p2p_status AS (SELECT "Check", state AS state_p2p FROM p2p WHERE state != 'Start'),
                   verter_status AS (SELECT "Check", state AS state_verter FROM verter WHERE state != 'Start')
            SELECT state_p2p, state_verter, "Time", xpamount::float / maxxp AS percent
              FROM p2p
                       JOIN checks
                       ON p2p."Check" = checks.id
                       JOIN p2p_status
                       ON p2p."Check" = p2p_status."Check"
                       LEFT JOIN verter_status
                       ON p2p."Check" = verter_status."Check"
                       LEFT JOIN xp x
                       ON checks.id = x."Check"
                       JOIN tasks t
                       ON checks.task = t.title
             WHERE state = 'Start'
               AND NOT (state_p2p = 'Success' AND state_verter IS NULL)
               AND "Date" = day
             ORDER BY "Date", "Time", 1, 2, 4) LOOP
        IF r.state_p2p = 'Success' AND (r.state_verter = 'Success' OR r.state_verter IS NULL) AND r.percent > 0.8 THEN
            i = i + 1;
        ELSE
            i = 0;
        END IF;
        IF i = n THEN RETURN TRUE; END IF;
    END LOOP;
    RETURN FALSE;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE proc_p3t17(n integer, INOUT result refcursor = 'result') AS
$$
BEGIN
    OPEN result FOR SELECT *
                      FROM (SELECT "Date" FROM checks GROUP BY "Date") AS days
                     WHERE func_on_every_day(n, "Date");
END
$$ LANGUAGE plpgsql;

BEGIN;
CALL proc_p3t17(1, 'result');
FETCH ALL FROM "result";
END;

-- task 18

CREATE OR REPLACE PROCEDURE proc_p3t18(INOUT result refcursor = 'result') AS
$$
BEGIN
    OPEN result FOR WITH res AS (SELECT peer, COUNT(task) AS xp
                                   FROM checks
                                            JOIN xp x
                                            ON checks.id = x."Check"
                                  GROUP BY peer)
                  SELECT peer, xp
                    FROM res
                   WHERE xp = (SELECT MAX(xp) FROM res);
END
$$ LANGUAGE plpgsql;

BEGIN;
CALL proc_p3t18('result');
FETCH ALL FROM "result";
END;

-- task 19

CREATE OR REPLACE PROCEDURE proc_p3t19(INOUT result refcursor = 'result') AS
$$
BEGIN
    OPEN result FOR WITH res AS (SELECT peer, SUM(xpamount) AS xp
                                   FROM checks
                                            JOIN xp x
                                            ON checks.id = x."Check"
                                  GROUP BY peer)
                  SELECT peer, xp
                    FROM res
                   WHERE xp = (SELECT MAX(xp) FROM res);
END
$$ LANGUAGE plpgsql;

BEGIN;
CALL proc_p3t19('result');
FETCH ALL FROM "result";
END;

-- task20

CREATE OR REPLACE PROCEDURE proc_p3t20(d DATE, INOUT _result_one refcursor = '_result_one')
    LANGUAGE plpgsql AS
$$
BEGIN
    OPEN _result_one FOR WITH cte AS (SELECT *, -"Time" AS t
                                        FROM timetracking
                                       WHERE "Date" = d
                                         AND state = 1
                                       UNION
                                      SELECT *, 1 * "Time" AS t
                                        FROM timetracking
                                       WHERE "Date" = d
                                         AND state = 2),
                              cte2 AS (SELECT SUM(t) AS s, peer FROM cte GROUP BY peer)
                       SELECT peer
                         FROM cte2
                        ORDER BY s DESC
                        LIMIT 1;
END;
$$;

BEGIN;
CALL proc_p3t20('2023-01-01', '_result_one');
FETCH ALL FROM "_result_one";
COMMIT;


-- task21

CREATE OR REPLACE PROCEDURE proc_p3t21(t TIME, n integer, INOUT _result_one refcursor = '_result_one')
    LANGUAGE plpgsql AS
$$
BEGIN
    OPEN _result_one FOR WITH cte AS (SELECT COUNT(peer) AS c, peer
                                        FROM timetracking
                                       WHERE "Time" < t AND state = 1
                                       GROUP BY peer)
                       SELECT peer
                         FROM cte
                        WHERE c >= n;
END;
$$;

BEGIN;
CALL proc_p3t21('21:00:00', 2, '_result_one');
FETCH ALL FROM "_result_one";
COMMIT;

-- task22

CREATE OR REPLACE PROCEDURE proc_p3t22(n integer, m integer, INOUT _result_one refcursor = '_result_one')
    LANGUAGE plpgsql AS
$$
BEGIN
    OPEN _result_one FOR WITH cte AS (SELECT COUNT(peer) / 2 - 1 AS c, peer, "Date"
                                        FROM timetracking
                                       GROUP BY peer, "Date")
                       SELECT peer
                         FROM cte
                        WHERE c > m
                          AND "Date" > (CURRENT_DATE - n);
END;
$$;

BEGIN;
CALL proc_p3t22(1000, 0, '_result_one');
FETCH ALL FROM "_result_one";
COMMIT;

-- task23

CREATE OR REPLACE PROCEDURE proc_p3t23(INOUT _result_one refcursor = '_result_one')
    LANGUAGE plpgsql AS
$$
BEGIN
    OPEN _result_one FOR WITH cte AS (SELECT MIN("Time") AS time, peer
                                        FROM timetracking
                                       WHERE state = 1 AND "Date" = CURRENT_DATE
                                       GROUP BY peer)
                       SELECT peer
                         FROM cte
                        ORDER BY time DESC
                        LIMIT 1;
END;
$$;

BEGIN;
CALL proc_p3t23('_result_one');
FETCH ALL FROM "_result_one";
COMMIT;

-- task 24

CREATE OR REPLACE FUNCTION func_for_identity_walking_peers(minutes time, human varchar) RETURNS boolean AS
$$
DECLARE
    r1 record;
    r2 record;
BEGIN
    FOR r2 IN SELECT * FROM timetracking WHERE "Date" = CURRENT_DATE - 1 AND peer = human ORDER BY "Time" LIMIT 1 LOOP
    END LOOP;
    FOR r1 IN SELECT * FROM timetracking WHERE "Date" = CURRENT_DATE - 1 AND peer = human ORDER BY "Time" LOOP
        IF r1.peer = r2.peer AND r1.state = 1 AND r2.state = 2 AND r1."Time" - r2."Time" > minutes THEN
            RETURN TRUE;
        END IF;
        r2 = r1;
    END LOOP;
    RETURN FALSE;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE proc_p3t24(min time, INOUT result refcursor = 'result') AS
$$
BEGIN
    OPEN result FOR SELECT peer FROM timetracking WHERE func_for_identity_walking_peers(min, peer) GROUP BY peer;
END
$$ LANGUAGE plpgsql;

BEGIN;
CALL proc_p3t24('00:01', 'result');
FETCH ALL FROM "result";
END;

-- task 25

CREATE OR REPLACE PROCEDURE proc_p3t25(OUT res refcursor) AS
$$
BEGIN
    res = 'result';
    OPEN res FOR WITH people AS (SELECT EXTRACT(MONTH FROM birthday) AS month, MIN("Time") AS time
                                   FROM timetracking
                                            JOIN peers p
                                            ON timetracking.peer = p.nickname
                                  GROUP BY "Date", peer, birthday
                                  ORDER BY 1),
                      year AS (SELECT column1 AS month, column2 AS monthname
                                 FROM (VALUES (1, 'January'),
                                              (2, 'February'),
                                              (3, 'March'),
                                              (4, 'April'),
                                              (5, 'May'),
                                              (6, 'June'),
                                              (7, 'July'),
                                              (8, 'August'),
                                              (9, 'September'),
                                              (10, 'October'),
                                              (11, 'November'),
                                              (12, 'December')) AS y),
                      stats AS (SELECT year.month, "time", year.monthname
                                  FROM people
                                           RIGHT JOIN year
                                           ON people.month = year.month
                                 ORDER BY month)
               SELECT year.monthname AS month,
                      CASE WHEN incoming.count IS NOT NULL THEN incoming.count::float / (SELECT COUNT("time")
                                                                                           FROM stats
                                                                                          WHERE year.monthname = stats.monthname
                                                                                          GROUP BY monthname) * 100
                           ELSE 0 END AS earlyentries
                 FROM (SELECT COUNT("time"), monthname FROM stats WHERE time < '12:00' GROUP BY monthname) AS incoming
                          RIGHT JOIN year
                          ON incoming.monthname = year.monthname;
END
$$ LANGUAGE plpgsql;

BEGIN;
CALL proc_p3t25(NULL);
FETCH ALL FROM "result";
END;
