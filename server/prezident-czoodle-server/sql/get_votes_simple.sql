SELECT
    '' AS id, '' AS nonces, '' AS permutation, 0 AS strength, '' AS ip_hash,
    rd2_0, rd2_1, rd2_2, rd2_3, rd2_4, rd2_5, rd2_6, rd2_7, rd2_8, rd2_9,
    rd1_0, rd1_1, rd1_2, rd1_3, rd1_4, rd1_5, rd1_6, rd1_7, rd1_8, rd1_9,
    div_0, div_1, div_2, div_3, div_4, div_5, div_6, div_7, div_8, div_9,
    d21_0, d21_1, d21_2, d21_3, d21_4, d21_5, d21_6, d21_7, d21_8, d21_9,
    ddl_0, ddl_1, ddl_2, ddl_3, ddl_4, ddl_5, ddl_6, ddl_7, ddl_8, ddl_9,
    ord_0, ord_1, ord_2, ord_3, ord_4, ord_5, ord_6, ord_7, ord_8, ord_9,
    str_0, str_1, str_2, str_3, str_4, str_5, str_6, str_7, str_8, str_9,
    emj_0, emj_1, emj_2, emj_3, emj_4, emj_5, emj_6, emj_7, emj_8, emj_9
FROM
    votes
WHERE
    voted < CAST (CAST ($1 AS TEXT) AS TIMESTAMP);
