use serde::{Deserialize, Serialize};
use tokio_pg_mapper_derive::PostgresMapper;

#[derive(Deserialize, Serialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct PollsWeb {
    pub two_round: i32,
    pub one_round: i32,
    pub divide: Vec<i32>,
    pub d21: Vec<i32>,
    pub doodle: Vec<i32>,
    pub order: Vec<i32>,
    pub star: Vec<i32>,
    pub emoji: Vec<String>,
}

#[derive(Deserialize, Serialize, Debug)]
pub struct VoteWeb {
    pub uuid: String,
    pub nonces: Vec<String>,
    pub order: Vec<i32>,
    pub polls: PollsWeb,
}

#[derive(Deserialize, PostgresMapper, Serialize, Debug)]
#[pg_mapper(table = "votes")]
pub struct VoteDB {
    pub id: String,
    pub nonces: String,
    pub permutation: String,
    pub strength: i32,
    pub ip_hash: String,

    // Two-Round Poll
    pub rd2_0: i32,
    pub rd2_1: i32,
    pub rd2_2: i32,
    pub rd2_3: i32,
    pub rd2_4: i32,
    pub rd2_5: i32,
    pub rd2_6: i32,
    pub rd2_7: i32,
    pub rd2_8: i32,
    pub rd2_9: i32,

    // One-Round Poll
    pub rd1_0: i32,
    pub rd1_1: i32,
    pub rd1_2: i32,
    pub rd1_3: i32,
    pub rd1_4: i32,
    pub rd1_5: i32,
    pub rd1_6: i32,
    pub rd1_7: i32,
    pub rd1_8: i32,
    pub rd1_9: i32,

    // Divide Poll
    pub div_0: i32,
    pub div_1: i32,
    pub div_2: i32,
    pub div_3: i32,
    pub div_4: i32,
    pub div_5: i32,
    pub div_6: i32,
    pub div_7: i32,
    pub div_8: i32,
    pub div_9: i32,

    // D21 Poll
    pub d21_0: i32,
    pub d21_1: i32,
    pub d21_2: i32,
    pub d21_3: i32,
    pub d21_4: i32,
    pub d21_5: i32,
    pub d21_6: i32,
    pub d21_7: i32,
    pub d21_8: i32,
    pub d21_9: i32,

    // Doodle Poll
    pub ddl_0: i32,
    pub ddl_1: i32,
    pub ddl_2: i32,
    pub ddl_3: i32,
    pub ddl_4: i32,
    pub ddl_5: i32,
    pub ddl_6: i32,
    pub ddl_7: i32,
    pub ddl_8: i32,
    pub ddl_9: i32,

    // Ord Poll
    pub ord_0: i32,
    pub ord_1: i32,
    pub ord_2: i32,
    pub ord_3: i32,
    pub ord_4: i32,
    pub ord_5: i32,
    pub ord_6: i32,
    pub ord_7: i32,
    pub ord_8: i32,
    pub ord_9: i32,

    // Star Poll
    pub str_0: i32,
    pub str_1: i32,
    pub str_2: i32,
    pub str_3: i32,
    pub str_4: i32,
    pub str_5: i32,
    pub str_6: i32,
    pub str_7: i32,
    pub str_8: i32,
    pub str_9: i32,

    // Emoji Poll
    pub emj_0: String,
    pub emj_1: String,
    pub emj_2: String,
    pub emj_3: String,
    pub emj_4: String,
    pub emj_5: String,
    pub emj_6: String,
    pub emj_7: String,
    pub emj_8: String,
    pub emj_9: String,
}
