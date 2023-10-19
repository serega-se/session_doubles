CREATE TABLE t_session_members
SELECT id, session_id, client_id FROM session_members;

CREATE TABLE t_session
SELECT * FROM sessions;

CREATE UNIQUE INDEX idx_session_members_unique
    ON session_members (session_id, client_id);

CREATE TABLE t_sessions_prim
SELECT MIN(id) as pid, start_time, session_configuration_id, count(id)
FROM sessions s
GROUP BY start_time, session_configuration_id;

CREATE TABLE t_sessions_doubles
SELECT * FROM sessions WHERE id NOT IN (SELECT pid FROM t_sessions_prim);

CREATE TABLE t_sessions_prim_doubles_ids
SELECT id, pid
FROM t_sessions_doubles tsd
LEFT JOIN t_sessions_prim tsp ON tsd.session_configuration_id = tsp.session_configuration_id AND tsd.start_time = tsp.start_time;

INSERT IGNORE INTO session_members(session_id, client_id)
SELECT smp.session_id, smp.client_id
FROM t_sessions_prim_doubles_ids as i
JOIN t_session_members as smp ON smp.session_id = i.pid;

DELETE 
FROM session_members 
WHERE id IN (
    SELECT smd.id
    FROM t_sessions_prim_doubles_ids as i
    JOIN t_session_members as smd ON smd.session_id = i.id 
    );

DELETE FROM sessions WHERE id IN (SELECT id FROM t_sessions_prim_doubles_ids);

CREATE UNIQUE INDEX idx_sessions_unique
    ON sessions (start_time, session_configuration_id);

DROP TABLE t_session;
DROP TABLE t_session_members;
DROP TABLE t_sessions_doubles;
DROP TABLE t_sessions_prim;
DROP TABLE t_sessions_prim_doubles_ids;
