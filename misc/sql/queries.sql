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
