CREATE TABLE peers
    (
        nickname varchar
            PRIMARY KEY,
        birthday date NOT NULL DEFAULT '1990-01-01'
    );

CREATE TABLE tasks
    (
        title varchar
            PRIMARY KEY,
        parenttask varchar,
        maxxp bigint NOT NULL
            CHECK (maxxp > 0),
        CONSTRAINT fk_tasks_parenttask
            FOREIGN KEY (parenttask) REFERENCES tasks (title)
    );

CREATE TYPE state AS enum ('Start', 'Success', 'Failure');

CREATE TABLE p2p
    (
        id bigint
            PRIMARY KEY,
        "Check" bigint NOT NULL,
        checkingpeer varchar NOT NULL,
        state state,
        "Time" time DEFAULT CURRENT_TIME
    );

CREATE TABLE verter
    (
        id bigint
            PRIMARY KEY,
        "Check" bigint NOT NULL,
        state state,
        "Time" time DEFAULT CURRENT_TIME
    );

CREATE TABLE checks
    (
        id bigint
            PRIMARY KEY,
        peer varchar NOT NULL,
        task varchar NOT NULL,
        "Date" date NOT NULL DEFAULT CURRENT_DATE
    );

ALTER TABLE p2p
    ADD CONSTRAINT fk_p2p_check
        FOREIGN KEY ("Check") REFERENCES checks (id),
    ADD CONSTRAINT fk_p2p_checkingpeer
        FOREIGN KEY (checkingpeer) REFERENCES peers (nickname);

ALTER TABLE verter
    ADD CONSTRAINT fk_verter_check
        FOREIGN KEY ("Check") REFERENCES checks (id);

ALTER TABLE checks
    ADD CONSTRAINT fk_checks_peer
        FOREIGN KEY (peer) REFERENCES peers (nickname),
    ADD CONSTRAINT fk_checks_task
        FOREIGN KEY (task) REFERENCES tasks (title);

CREATE TABLE transferredpoints
    (
        id bigint
            PRIMARY KEY,
        checkingpeer varchar NOT NULL,
        checkedpeer varchar NOT NULL
            CHECK (checkedpeer != transferredpoints.checkingpeer ),
        pointsamount bigint,
        CONSTRAINT fk_transferredpoints_checkingpeer
            FOREIGN KEY (checkingpeer) REFERENCES peers (nickname),
        CONSTRAINT fk_transferredpoints_checkedpeer
            FOREIGN KEY (checkedpeer) REFERENCES peers (nickname)
    );

CREATE TABLE friends
    (
        id bigint
            PRIMARY KEY,
        peer1 varchar NOT NULL,
        peer2 varchar NOT NULL
            CHECK (peer1 != peer2 ),
        CONSTRAINT fk_friends_peer1
            FOREIGN KEY (peer1) REFERENCES peers (nickname),
        CONSTRAINT fk_friends_peer2
            FOREIGN KEY (peer2) REFERENCES peers (nickname)
    );

CREATE TABLE recommendations
    (
        id bigint
            PRIMARY KEY,
        peer varchar NOT NULL,
        recommendedpeer varchar NOT NULL
            CHECK (recommendedpeer != peer ),
        CONSTRAINT fk_recommendations_peer
            FOREIGN KEY (peer) REFERENCES peers (nickname),
        CONSTRAINT fk_recommendations_recommendedpeer
            FOREIGN KEY (recommendedpeer) REFERENCES peers (nickname)
    );

CREATE TABLE xp
    (
        id bigint
            PRIMARY KEY,
        "Check" bigint,
        xpamount bigint,
        CONSTRAINT fk_xp_check
            FOREIGN KEY ("Check") REFERENCES checks (id)
    );

CREATE TABLE timetracking
    (
        id bigint
            PRIMARY KEY,
        peer varchar,
        "Date" date NOT NULL DEFAULT CURRENT_DATE,
        "Time" time NOT NULL DEFAULT CURRENT_TIME,
        state smallint,
        CONSTRAINT fk_timetracking_peer
            FOREIGN KEY (peer) REFERENCES peers (nickname)
    );

INSERT INTO peers
VALUES ('mkrusty', '1997-09-18');
INSERT INTO peers
VALUES ('bernarda', '1994-10-29');
INSERT INTO peers
VALUES ('ddrizzle', '1995-03-24');
INSERT INTO peers
VALUES ('kwukong', '1986-04-26');
INSERT INTO peers
VALUES ('mtickler', '1994-01-18');

INSERT INTO tasks
VALUES ('C2_SimpleBashUtils', NULL, 250);
INSERT INTO tasks
VALUES ('C3_s21_string+', 'C2_SimpleBashUtils', 500);
INSERT INTO tasks
VALUES ('C5_s21_decimal', 'C2_SimpleBashUtils', 350);
INSERT INTO tasks
VALUES ('C8_3DViewer_v1.0', 'C5_s21_decimal', 750);
INSERT INTO tasks
VALUES ('CPP2_s21_containers', 'C8_3DViewer_v1.0', 350);
INSERT INTO tasks
VALUES ('CPP4_3DViewer_v2.0', 'CPP2_s21_containers', 750);
INSERT INTO tasks
VALUES ('CPP7_MLP', 'CPP4_3DViewer_v2.0', 700);
INSERT INTO tasks
VALUES ('CPP9_MonitoringSystem', 'CPP4_3DViewer_v2.0', 1000);
INSERT INTO tasks
VALUES ('A1_Maze', 'CPP4_3DViewer_v2.0', 300);
INSERT INTO tasks
VALUES ('DO1_Linux', 'C3_s21_string+', 300);
INSERT INTO tasks
VALUES ('DO4_LinuxMonitoring_v2.0', 'DO1_Linux', 350);


INSERT INTO friends
VALUES (1, 'mkrusty', 'ddrizzle');
INSERT INTO friends
VALUES (2, 'bernarda', 'ddrizzle');
INSERT INTO friends
VALUES (3, 'kwukong', 'ddrizzle');
INSERT INTO friends
VALUES (4, 'mtickler', 'ddrizzle');
INSERT INTO friends
VALUES (5, 'mkrusty', 'bernarda');
INSERT INTO friends
VALUES (6, 'bernarda', 'kwukong');


INSERT INTO recommendations
VALUES (1, 'mkrusty', 'ddrizzle');
INSERT INTO recommendations
VALUES (2, 'mkrusty', 'bernarda');
INSERT INTO recommendations
VALUES (3, 'ddrizzle', 'mkrusty');
INSERT INTO recommendations
VALUES (4, 'kwukong', 'bernarda');
INSERT INTO recommendations
VALUES (5, 'mtickler', 'bernarda');
INSERT INTO recommendations
VALUES (6, 'bernarda', 'mkrusty');


INSERT INTO timetracking
VALUES (1, 'mtickler', '2023-01-01', '13:30', 1);
INSERT INTO timetracking
VALUES (2, 'mtickler', '2023-01-01', '15:48', 2);
INSERT INTO timetracking
VALUES (3, 'bernarda', '2023-01-01', '10:37', 1);
INSERT INTO timetracking
VALUES (4, 'bernarda', '2023-01-01', '18:37', 2);
INSERT INTO timetracking
VALUES (5, 'bernarda', '2023-01-01', '19:37', 1);
INSERT INTO timetracking
VALUES (6, 'bernarda', '2023-01-01', '20:37', 2);
INSERT INTO timetracking
VALUES (7, 'mkrusty', '2023-01-02', '10:20', 1);
INSERT INTO timetracking
VALUES (8, 'mkrusty', '2023-01-02', '22:00', 2);
INSERT INTO timetracking
VALUES (9, 'ddrizzle', '2023-01-02', '13:20', 1);
INSERT INTO timetracking
VALUES (10, 'ddrizzle', '2023-01-02', '14:50', 2);


INSERT INTO checks
VALUES (1, 'mtickler', 'CPP7_MLP', '2023-01-01');
INSERT INTO checks
VALUES (2, 'kwukong', 'A1_Maze', '2023-01-01');
INSERT INTO checks
VALUES (3, 'kwukong', 'A1_Maze', '2023-01-02');
INSERT INTO checks
VALUES (4, 'mtickler', 'A1_Maze', '2023-01-01');
INSERT INTO checks
VALUES (5, 'ddrizzle', 'DO1_Linux', '2023-01-01');
INSERT INTO checks
VALUES (6, 'bernarda', 'C5_s21_decimal', '2023-01-01');
INSERT INTO checks
VALUES (7, 'mkrusty', 'C5_s21_decimal', '2023-01-02');
INSERT INTO checks
VALUES (8, 'ddrizzle', 'DO4_LinuxMonitoring_v2.0', '2023-01-02');


INSERT INTO xp
VALUES (1, 1, 600);
INSERT INTO xp
VALUES (2, 3, 200);
INSERT INTO xp
VALUES (3, 4, 295);
INSERT INTO xp
VALUES (4, 5, 300);
INSERT INTO xp
VALUES (5, 6, 345);


INSERT INTO p2p
VALUES (1, 1, 'ddrizzle', 'Start', '13:00');
INSERT INTO p2p
VALUES (2, 1, 'ddrizzle', 'Success', '14:00');
INSERT INTO p2p
VALUES (3, 2, 'bernarda', 'Start', '14:30');
INSERT INTO p2p
VALUES (4, 2, 'bernarda', 'Failure', '15:00');
INSERT INTO p2p
VALUES (5, 3, 'ddrizzle', 'Start', '11:30');
INSERT INTO p2p
VALUES (6, 3, 'ddrizzle', 'Success', '12:00');
INSERT INTO p2p
VALUES (7, 4, 'mkrusty', 'Start', '10:30');
INSERT INTO p2p
VALUES (8, 4, 'mkrusty', 'Success', '11:00');
INSERT INTO p2p
VALUES (9, 5, 'kwukong', 'Start', '11:00');
INSERT INTO p2p
VALUES (10, 5, 'kwukong', 'Success', '11:30');
INSERT INTO p2p
VALUES (11, 6, 'mtickler', 'Start', '21:30');
INSERT INTO p2p
VALUES (12, 6, 'mtickler', 'Success', '22:00');
INSERT INTO p2p
VALUES (13, 7, 'bernarda', 'Start', '18:00');
INSERT INTO p2p
VALUES (14, 7, 'bernarda', 'Success', '18:15');
INSERT INTO p2p
VALUES (15, 8, 'mtickler', 'Start', '21:30');
INSERT INTO p2p
VALUES (16, 8, 'mtickler', 'Success', '22:00');


INSERT INTO verter
VALUES (1, 1, 'Start', '14:20');
INSERT INTO verter
VALUES (2, 1, 'Success', '14:30');
INSERT INTO verter
VALUES (3, 3, 'Start', '12:50');
INSERT INTO verter
VALUES (4, 3, 'Success', '13:00');
INSERT INTO verter
VALUES (6, 4, 'Start', '11:50');
INSERT INTO verter
VALUES (7, 4, 'Success', '12:00');
INSERT INTO verter
VALUES (8, 5, 'Start', '12:20');
INSERT INTO verter
VALUES (9, 5, 'Success', '12:30');
INSERT INTO verter
VALUES (10, 6, 'Start', '22:50');
INSERT INTO verter
VALUES (11, 6, 'Success', '23:00');
INSERT INTO verter
VALUES (12, 7, 'Start', '19:00');
INSERT INTO verter
VALUES (13, 7, 'Failure', '19:15');
INSERT INTO verter
VALUES (14, 8, 'Start', '23:00');


INSERT INTO transferredpoints
VALUES (1, 'mkrusty', 'bernarda', 1);
INSERT INTO transferredpoints
VALUES (2, 'mkrusty', 'ddrizzle', 0);
INSERT INTO transferredpoints
VALUES (3, 'mkrusty', 'kwukong', 0);
INSERT INTO transferredpoints
VALUES (4, 'mkrusty', 'mtickler', 0);
INSERT INTO transferredpoints
VALUES (5, 'bernarda', 'mkrusty', 0);
INSERT INTO transferredpoints
VALUES (6, 'bernarda', 'ddrizzle', 0);
INSERT INTO transferredpoints
VALUES (7, 'bernarda', 'kwukong', 0);
INSERT INTO transferredpoints
VALUES (8, 'bernarda', 'mtickler', 1);
INSERT INTO transferredpoints
VALUES (9, 'ddrizzle', 'mkrusty', 0);
INSERT INTO transferredpoints
VALUES (10, 'ddrizzle', 'bernarda', 0);
INSERT INTO transferredpoints
VALUES (11, 'ddrizzle', 'mtickler', 1);
INSERT INTO transferredpoints
VALUES (12, 'ddrizzle', 'kwukong', 1);
INSERT INTO transferredpoints
VALUES (13, 'kwukong', 'mkrusty', 0);
INSERT INTO transferredpoints
VALUES (14, 'kwukong', 'bernarda', 1);
INSERT INTO transferredpoints
VALUES (15, 'kwukong', 'ddrizzle', 1);
INSERT INTO transferredpoints
VALUES (16, 'kwukong', 'mtickler', 0);
INSERT INTO transferredpoints
VALUES (17, 'mtickler', 'mkrusty', 1);
INSERT INTO transferredpoints
VALUES (18, 'mtickler', 'bernarda', 0);
INSERT INTO transferredpoints
VALUES (19, 'mtickler', 'ddrizzle', 1);
INSERT INTO transferredpoints
VALUES (20, 'mtickler', 'kwukong', 0);

CREATE OR REPLACE PROCEDURE fnc_import_from_file(nametable varchar, namefile varchar, delim varchar) AS
$$
BEGIN
    EXECUTE FORMAT('
        copy %L
        from %L
        with ( format csv,
            header,
            delimiter %L);', nametable, namefile, delim);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE fnc_export_to_file(nametable varchar, namefile varchar, delim varchar) AS
$$
BEGIN
    EXECUTE FORMAT('
        copy %L
        to %L
        with (format csv,
            header,
            delimiter %L);', nametable, namefile, delim);
END;
$$ LANGUAGE plpgsql;
