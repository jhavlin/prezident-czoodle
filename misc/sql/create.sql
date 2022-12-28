CREATE TABLE votes (
    id char(36) PRIMARY KEY,
    nonces text NOT NULL,
    permutation varchar(128) NOT NULL,
    voted timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    strength integer NOT NULL,
    ip_hash char(64) NOT NULL,

    -- Two-Round Poll
    rd2_0 integer NOT NULL,
    rd2_1 integer NOT NULL,
    rd2_2 integer NOT NULL,
    rd2_3 integer NOT NULL,
    rd2_4 integer NOT NULL,
    rd2_5 integer NOT NULL,
    rd2_6 integer NOT NULL,
    rd2_7 integer NOT NULL,
    rd2_8 integer NOT NULL,
    rd2_9 integer NOT NULL,

    -- One-Round Poll
    rd1_0 integer NOT NULL,
    rd1_1 integer NOT NULL,
    rd1_2 integer NOT NULL,
    rd1_3 integer NOT NULL,
    rd1_4 integer NOT NULL,
    rd1_5 integer NOT NULL,
    rd1_6 integer NOT NULL,
    rd1_7 integer NOT NULL,
    rd1_8 integer NOT NULL,
    rd1_9 integer NOT NULL,

    -- Divide Poll
    div_0 integer NOT NULL,
    div_1 integer NOT NULL,
    div_2 integer NOT NULL,
    div_3 integer NOT NULL,
    div_4 integer NOT NULL,
    div_5 integer NOT NULL,
    div_6 integer NOT NULL,
    div_7 integer NOT NULL,
    div_8 integer NOT NULL,
    div_9 integer NOT NULL,

    -- D21 Poll
    d21_0 integer NOT NULL,
    d21_1 integer NOT NULL,
    d21_2 integer NOT NULL,
    d21_3 integer NOT NULL,
    d21_4 integer NOT NULL,
    d21_5 integer NOT NULL,
    d21_6 integer NOT NULL,
    d21_7 integer NOT NULL,
    d21_8 integer NOT NULL,
    d21_9 integer NOT NULL,

    -- Doodle Poll
    ddl_0 integer NOT NULL,
    ddl_1 integer NOT NULL,
    ddl_2 integer NOT NULL,
    ddl_3 integer NOT NULL,
    ddl_4 integer NOT NULL,
    ddl_5 integer NOT NULL,
    ddl_6 integer NOT NULL,
    ddl_7 integer NOT NULL,
    ddl_8 integer NOT NULL,
    ddl_9 integer NOT NULL,

    -- Order Poll
    ord_0 integer NOT NULL,
    ord_1 integer NOT NULL,
    ord_2 integer NOT NULL,
    ord_3 integer NOT NULL,
    ord_4 integer NOT NULL,
    ord_5 integer NOT NULL,
    ord_6 integer NOT NULL,
    ord_7 integer NOT NULL,
    ord_8 integer NOT NULL,
    ord_9 integer NOT NULL,

    -- Star Poll
    str_0 integer NOT NULL,
    str_1 integer NOT NULL,
    str_2 integer NOT NULL,
    str_3 integer NOT NULL,
    str_4 integer NOT NULL,
    str_5 integer NOT NULL,
    str_6 integer NOT NULL,
    str_7 integer NOT NULL,
    str_8 integer NOT NULL,
    str_9 integer NOT NULL,

    -- Emoji Poll
    emj_0 varchar(3) NOT NULL,
    emj_1 varchar(3) NOT NULL,
    emj_2 varchar(3) NOT NULL,
    emj_3 varchar(3) NOT NULL,
    emj_4 varchar(3) NOT NULL,
    emj_5 varchar(3) NOT NULL,
    emj_6 varchar(3) NOT NULL,
    emj_7 varchar(3) NOT NULL,
    emj_8 varchar(3) NOT NULL,
    emj_9 varchar(3) NOT NULL
);


-- INSERT INTO votes (
--     id, nonces, permutation, strength, ip_hash,
--     rd2_0, rd2_1, rd2_2, rd2_3, rd2_4, rd2_5, rd2_6, rd2_7, rd2_8, rd2_9,
--     rd1_0, rd1_1, rd1_2, rd1_3, rd1_4, rd1_5, rd1_6, rd1_7, rd1_8, rd1_9,
--     div_0, div_1, div_2, div_3, div_4, div_5, div_6, div_7, div_8, div_9,
--     d21_0, d21_1, d21_2, d21_3, d21_4, d21_5, d21_6, d21_7, d21_8, d21_9,
--     ddl_0, ddl_1, ddl_2, ddl_3, ddl_4, ddl_5, ddl_6, ddl_7, ddl_8, ddl_9,
--     ord_0, ord_1, ord_2, ord_3, ord_4, ord_5, ord_6, ord_7, ord_8, ord_9,
--     str_0, str_1, str_2, str_3, str_4, str_5, str_6, str_7, str_8, str_9,
--     emj_0, emj_1, emj_2, emj_3, emj_4, emj_5, emj_6, emj_7, emj_8, emj_9
-- ) values (
--     'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 'abc,def', '7,0,3,8,4,9,5,1,2,6', 42, 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
--     1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
--     0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
--     0, 0, 2, 0, 1, 1, 1, 0, 0, 0,
--     1, 0, 0, 1, 1, 0, -1, 0, 0, 0,
--     1, 0, 1, 2, 2, 1, 1, 2, 0, 0,
--     0, 7, 8, 3, 5, 1, 4, 2, 6, 9,
--     20, 20, 20, 60, 60, 60, 100, 100, 20, 20,
--     ':-)', ':-(', '🎄', '🎅', '🎁', '🏡', ':-)', ':-D', ':-(', ':-/'
-- );
