-- Two-Round Poll
select sum(rd2_0) as ab, sum(rd2_1) as jb, sum(rd2_2) as kd, sum(rd2_3) as pf, sum(rd2_4) as mh, sum(rd2_5) as kj, sum(rd2_6) as dn, sum(rd2_7) as pp, sum(rd2_8) as js, sum(rd2_9) as tz from votes;

-- One-Round Poll
select sum(rd1_0) as ab, sum(rd1_1) as jb, sum(rd1_2) as kd, sum(rd1_3) as pf, sum(rd1_4) as mh, sum(rd1_5) as kj, sum(rd1_6) as dn, sum(rd1_7) as pp, sum(rd1_8) as js, sum(rd1_9) as tz from votes;

-- Divide Poll
select sum(div_0) as ab, sum(div_1) as jb, sum(div_2) as kd, sum(div_3) as pf, sum(div_4) as mh, sum(div_5) as kj, sum(div_6) as dn, sum(div_7) as pp, sum(div_8) as js, sum(div_9) as tz from votes;

-- D21 Poll
select sum(d21_0) as ab, sum(d21_1) as jb, sum(d21_2) as kd, sum(d21_3) as pf, sum(d21_4) as mh, sum(d21_5) as kj, sum(d21_6) as dn, sum(d21_7) as pp, sum(d21_8) as js, sum(d21_9) as tz from votes;

-- Doodle Poll
select sum(ddl_0) as ab, sum(ddl_1) as jb, sum(ddl_2) as kd, sum(ddl_3) as pf, sum(ddl_4) as mh, sum(ddl_5) as kj, sum(ddl_6) as dn, sum(ddl_7) as pp, sum(ddl_8) as js, sum(ddl_9) as tz from votes;

-- Order Poll
select sum(ord_0) as ab, sum(ord_1) as jb, sum(ord_2) as kd, sum(ord_3) as pf, sum(ord_4) as mh, sum(ord_5) as kj, sum(ord_6) as dn, sum(ord_7) as pp, sum(ord_8) as js, sum(ord_9) as tz from votes;

-- Star Poll
select sum(str_0) as ab, sum(str_1) as jb, sum(str_2) as kd, sum(str_3) as pf, sum(str_4) as mh, sum(str_5) as kj, sum(str_6) as dn, sum(str_7) as pp, sum(str_8) as js, sum(str_9) as tz from votes;

-- Star Poll (Percents)
select
    round(sum(str_0) / (select count (*) from votes)::numeric, 2) as ab,
    round(sum(str_1) / (select count (*) from votes)::numeric, 2) as jb,
    round(sum(str_2) / (select count (*) from votes)::numeric, 2) as kd,
    round(sum(str_3) / (select count (*) from votes)::numeric, 2) as pf,
    round(sum(str_4) / (select count (*) from votes)::numeric, 2) as mh,
    round(sum(str_5) / (select count (*) from votes)::numeric, 2) as kj,
    round(sum(str_6) / (select count (*) from votes)::numeric, 2) as dn,
    round(sum(str_7) / (select count (*) from votes)::numeric, 2) as pp,
    round(sum(str_8) / (select count (*) from votes)::numeric, 2) as js,
    round(sum(str_9) / (select count (*) from votes)::numeric, 2) as tz
from votes;

--Emoji Poll
select emj_0 as ab, emj_1 as jb, emj_2 as kd, emj_3 as pf, emj_4 as mh, emj_5 as kj, emj_6 as dn, emj_7 as pp, emj_8 as js, emj_9 as tz
from votes
where emj_0 != '' or emj_1 != '' or emj_2 != '' or emj_3 != '' or emj_4 != '' or emj_5 != '' or emj_6 != '' or emj_7 != '' or emj_8 != '' or emj_9 != '';


-- Emoji Poll - ordered, joined
select
    t_ab.o as o,
    t_ab.e as ab_e, t_ab.c as ab_c,
    t_jb.e as jb_e, t_jb.c as jb_c,
    t_kd.e as kd_e, t_kd.c as kd_c,
    t_pf.e as pf_e, t_pf.c as pf_c,
    t_mh.e as mh_e, t_mh.c as mh_c,
    t_kj.e as kj_e, t_kj.c as kj_c,
    t_dn.e as dn_e, t_dn.c as dn_c,
    t_pp.e as pp_e, t_pp.c as pp_c,
    t_js.e as js_e, t_js.c as js_c,
    t_tz.e as tz_e, t_tz.c as tz_c
from
    (select row_number () over (order by count(*) desc) as o, emj_0 as e, count(*) as c from votes where emj_0 != '' group by e order by c desc) t_ab
full outer join
    (select row_number () over (order by count(*) desc) as o, emj_1 as e, count(*) as c from votes where emj_1 != '' group by e order by c desc) t_jb
    on t_ab.o = t_jb.o
full outer join
    (select row_number () over (order by count(*) desc) as o, emj_2 as e, count(*) as c from votes where emj_2 != '' group by e order by c desc) t_kd
    on t_ab.o = t_kd.o
full outer join
    (select row_number () over (order by count(*) desc) as o, emj_3 as e, count(*) as c from votes where emj_3 != '' group by e order by c desc) t_pf
    on t_ab.o = t_pf.o
full outer join
    (select row_number () over (order by count(*) desc) as o, emj_4 as e, count(*) as c from votes where emj_4 != '' group by e order by c desc) t_mh
    on t_ab.o = t_mh.o
full outer join
    (select row_number () over (order by count(*) desc) as o, emj_5 as e, count(*) as c from votes where emj_5 != '' group by e order by c desc) t_kj
    on t_ab.o = t_kj.o
full outer join
    (select row_number () over (order by count(*) desc) as o, emj_6 as e, count(*) as c from votes where emj_6 != '' group by e order by c desc) t_dn
    on t_ab.o = t_dn.o
full outer join
    (select row_number () over (order by count(*) desc) as o, emj_7 as e, count(*) as c from votes where emj_7 != '' group by e order by c desc) t_pp
    on t_ab.o = t_pp.o
full outer join
    (select row_number () over (order by count(*) desc) as o, emj_8 as e, count(*) as c from votes where emj_8 != '' group by e order by c desc) t_js
    on t_ab.o = t_js.o
full outer join
    (select row_number () over (order by count(*) desc) as o, emj_9 as e, count(*) as c from votes where emj_9 != '' group by e order by c desc) t_tz
    on t_ab.o = t_tz.o;
