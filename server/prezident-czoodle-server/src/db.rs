use crate::{
    errors::MyError,
    models::{PollsWeb, VoteDB, VoteWeb},
};
use deadpool_postgres::Client;
use tokio_pg_mapper::FromTokioPostgresRow;

fn index_to_points(value: i32, index: i32) -> i32 {
    if index == value {
        1
    } else {
        0
    }
}

pub async fn add_vote(
    client: &Client,
    vote_info: VoteWeb,
    ip_address_hash: &str,
) -> Result<(), MyError> {
    let _stmt = include_str!("../sql/add_vote.sql");
    let stmt = client.prepare(&_stmt).await.unwrap();

    let order_as_strings: Vec<String> = vote_info.order.iter().map(|&v| v.to_string()).collect();
    let permutation: String = order_as_strings.join(",");

    let nonces_as_one_string = vote_info.nonces.join(",");

    let result = client
        .query(
            &stmt,
            &[
                &vote_info.uuid,
                &nonces_as_one_string,
                &permutation,
                &(vote_info.order.len() as i32),
                &ip_address_hash,
                // Two-Round Poll
                &(index_to_points(vote_info.polls.two_round, 0)),
                &(index_to_points(vote_info.polls.two_round, 1)),
                &(index_to_points(vote_info.polls.two_round, 2)),
                &(index_to_points(vote_info.polls.two_round, 3)),
                &(index_to_points(vote_info.polls.two_round, 4)),
                &(index_to_points(vote_info.polls.two_round, 5)),
                &(index_to_points(vote_info.polls.two_round, 6)),
                &(index_to_points(vote_info.polls.two_round, 7)),
                &(index_to_points(vote_info.polls.two_round, 8)),
                &(index_to_points(vote_info.polls.two_round, 9)),
                // One-Round Poll
                &(index_to_points(vote_info.polls.one_round, 0)),
                &(index_to_points(vote_info.polls.one_round, 1)),
                &(index_to_points(vote_info.polls.one_round, 2)),
                &(index_to_points(vote_info.polls.one_round, 3)),
                &(index_to_points(vote_info.polls.one_round, 4)),
                &(index_to_points(vote_info.polls.one_round, 5)),
                &(index_to_points(vote_info.polls.one_round, 6)),
                &(index_to_points(vote_info.polls.one_round, 7)),
                &(index_to_points(vote_info.polls.one_round, 8)),
                &(index_to_points(vote_info.polls.one_round, 9)),
                // Divide Poll
                &vote_info.polls.divide[0],
                &vote_info.polls.divide[1],
                &vote_info.polls.divide[2],
                &vote_info.polls.divide[3],
                &vote_info.polls.divide[4],
                &vote_info.polls.divide[5],
                &vote_info.polls.divide[6],
                &vote_info.polls.divide[7],
                &vote_info.polls.divide[8],
                &vote_info.polls.divide[9],
                // D21 Poll
                &vote_info.polls.d21[0],
                &vote_info.polls.d21[1],
                &vote_info.polls.d21[2],
                &vote_info.polls.d21[3],
                &vote_info.polls.d21[4],
                &vote_info.polls.d21[5],
                &vote_info.polls.d21[6],
                &vote_info.polls.d21[7],
                &vote_info.polls.d21[8],
                &vote_info.polls.d21[9],
                // Doodle Poll
                &vote_info.polls.doodle[0],
                &vote_info.polls.doodle[1],
                &vote_info.polls.doodle[2],
                &vote_info.polls.doodle[3],
                &vote_info.polls.doodle[4],
                &vote_info.polls.doodle[5],
                &vote_info.polls.doodle[6],
                &vote_info.polls.doodle[7],
                &vote_info.polls.doodle[8],
                &vote_info.polls.doodle[9],
                // Order Poll
                &vote_info.polls.order[0],
                &vote_info.polls.order[1],
                &vote_info.polls.order[2],
                &vote_info.polls.order[3],
                &vote_info.polls.order[4],
                &vote_info.polls.order[5],
                &vote_info.polls.order[6],
                &vote_info.polls.order[7],
                &vote_info.polls.order[8],
                &vote_info.polls.order[9],
                // Star Poll
                &vote_info.polls.star[0],
                &vote_info.polls.star[1],
                &vote_info.polls.star[2],
                &vote_info.polls.star[3],
                &vote_info.polls.star[4],
                &vote_info.polls.star[5],
                &vote_info.polls.star[6],
                &vote_info.polls.star[7],
                &vote_info.polls.star[8],
                &vote_info.polls.star[9],
                // Emoji Poll
                &vote_info.polls.emoji[0],
                &vote_info.polls.emoji[1],
                &vote_info.polls.emoji[2],
                &vote_info.polls.emoji[3],
                &vote_info.polls.emoji[4],
                &vote_info.polls.emoji[5],
                &vote_info.polls.emoji[6],
                &vote_info.polls.emoji[7],
                &vote_info.polls.emoji[8],
                &vote_info.polls.emoji[9],
            ],
        )
        .await;

    match result {
        Ok(_) => Result::Ok(()),
        Err(err) => Result::Err(MyError::PGError(err)),
    }
}

pub async fn get_vote(client: &Client, uuid: &String) -> Result<VoteWeb, MyError> {
    let _stmt = include_str!("../sql/get_vote.sql");
    let stmt = client.prepare(&_stmt).await.unwrap();

    let record = client
        .query(&stmt, &[&uuid])
        .await
        .map_err(MyError::PGError)?
        .iter()
        .map(|row| VoteDB::from_row_ref(row).unwrap())
        .collect::<Vec<VoteDB>>()
        .pop()
        .ok_or(MyError::NotFound)?;

    let two_round = [
        record.rd2_0,
        record.rd2_1,
        record.rd2_2,
        record.rd2_3,
        record.rd2_4,
        record.rd2_5,
        record.rd2_6,
        record.rd2_7,
        record.rd2_8,
        record.rd2_9,
    ];
    let one_round = [
        record.rd1_0,
        record.rd1_1,
        record.rd1_2,
        record.rd1_3,
        record.rd1_4,
        record.rd1_5,
        record.rd1_6,
        record.rd1_7,
        record.rd1_8,
        record.rd1_9,
    ];
    let divide = [
        record.div_0,
        record.div_1,
        record.div_2,
        record.div_3,
        record.div_4,
        record.div_5,
        record.div_6,
        record.div_7,
        record.div_8,
        record.div_9,
    ];
    let d21 = [
        record.d21_0,
        record.d21_1,
        record.d21_2,
        record.d21_3,
        record.d21_4,
        record.d21_5,
        record.d21_6,
        record.d21_7,
        record.d21_8,
        record.d21_9,
    ];
    let doodle = [
        record.ddl_0,
        record.ddl_1,
        record.ddl_2,
        record.ddl_3,
        record.ddl_4,
        record.ddl_5,
        record.ddl_6,
        record.ddl_7,
        record.ddl_8,
        record.ddl_9,
    ];
    let order = [
        record.ord_0,
        record.ord_1,
        record.ord_2,
        record.ord_3,
        record.ord_4,
        record.ord_5,
        record.ord_6,
        record.ord_7,
        record.ord_8,
        record.ord_9,
    ];
    let star = [
        record.str_0,
        record.str_1,
        record.str_2,
        record.str_3,
        record.str_4,
        record.str_5,
        record.str_6,
        record.str_7,
        record.str_8,
        record.str_9,
    ];
    let emoji = [
        record.emj_0,
        record.emj_1,
        record.emj_2,
        record.emj_3,
        record.emj_4,
        record.emj_5,
        record.emj_6,
        record.emj_7,
        record.emj_8,
        record.emj_9,
    ];

    let polls = PollsWeb {
        two_round: two_round
            .iter()
            .enumerate()
            .find(|&(_i, &v)| v > 0)
            .map(|p| p.0 as i32)
            .unwrap_or_else(|| -1),
        one_round: one_round
            .iter()
            .enumerate()
            .find(|&(_i, &v)| v > 0)
            .map(|p| p.0 as i32)
            .unwrap_or_else(|| -1),
        divide: divide.to_vec(),
        d21: d21.to_vec(),
        doodle: doodle.to_vec(),
        order: order.to_vec(),
        star: star.to_vec(),
        emoji: emoji.to_vec(),
    };

    let nonces_vec: Vec<String> = record.nonces.split(",").map(|s| s.to_string()).collect();

    let order_vec: Vec<i32> = record
        .permutation
        .split(",")
        .filter_map(|s| i32::from_str_radix(s, 10).ok())
        .collect();

    let vote_web = VoteWeb {
        uuid: record.id,
        nonces: nonces_vec,
        order: order_vec,
        polls,
    };

    Result::Ok(vote_web)
}
