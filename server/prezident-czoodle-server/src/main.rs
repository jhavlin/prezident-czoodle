mod config {
    use serde::Deserialize;
    #[derive(Debug, Default, Deserialize)]
    pub struct ExampleConfig {
        pub server_addr: String,
        pub pg: deadpool_postgres::Config,
    }
}

mod models {
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
}

mod errors {
    use actix_web::{HttpResponse, ResponseError};
    use deadpool_postgres::PoolError;
    use derive_more::{Display, From};
    use tokio_pg_mapper::Error as PGMError;
    use tokio_postgres::error::Error as PGError;

    #[derive(Display, From, Debug)]
    pub enum MyError {
        NotFound,
        PGError(PGError),
        PGMError(PGMError),
        PoolError(PoolError),
    }
    impl std::error::Error for MyError {}

    impl ResponseError for MyError {
        fn error_response(&self) -> HttpResponse {
            match *self {
                MyError::NotFound => HttpResponse::NotFound().finish(),
                MyError::PoolError(ref err) => {
                    HttpResponse::InternalServerError().body(err.to_string())
                }
                MyError::PGError(ref err) => {
                    HttpResponse::InternalServerError().body(err.to_string())
                }
                _ => HttpResponse::InternalServerError().finish(),
            }
        }
    }
}

mod db {
    use crate::{
        errors::MyError,
        models::VoteWeb,
        models::{PollsWeb, VoteDB},
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

    pub async fn add_vote(client: &Client, vote_info: VoteWeb) -> Result<(), MyError> {
        let _stmt = include_str!("../sql/add_vote.sql");
        let stmt = client.prepare(&_stmt).await.unwrap();

        let order_as_strings: Vec<String> =
            vote_info.order.iter().map(|&v| v.to_string()).collect();
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
                    &"ip_hash", // TODO
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
}

mod handlers {
    use actix_web::{web, Error, HttpResponse};
    use deadpool_postgres::{Client, Pool};

    use crate::{db, errors::MyError, models::VoteWeb};

    pub async fn add_vote(
        vote: web::Json<VoteWeb>,
        db_pool: web::Data<Pool>,
    ) -> Result<HttpResponse, Error> {
        let vote_info: VoteWeb = vote.into_inner();

        let client: Client = db_pool.get().await.map_err(MyError::PoolError)?;

        db::add_vote(&client, vote_info).await?;

        Ok(HttpResponse::Ok().finish())
    }

    pub async fn get_vote(
        path: web::Path<String>,
        db_pool: web::Data<Pool>,
    ) -> Result<HttpResponse, Error> {
        let uuid: String = path.into_inner();
        let client: Client = db_pool.get().await.map_err(MyError::PoolError)?;

        let result: VoteWeb = db::get_vote(&client, &uuid).await?;

        Ok(HttpResponse::Ok().json(result))
    }
}

use ::config::Config;
use actix_web::{web, App, HttpServer};
use dotenv::dotenv;
use tokio_postgres::NoTls;

use crate::config::ExampleConfig;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    dotenv().ok();

    let config_ = Config::builder()
        .add_source(::config::Environment::default())
        .build()
        .unwrap();

    let config: ExampleConfig = config_.try_deserialize().unwrap();

    let pool = config.pg.create_pool(None, NoTls).unwrap();

    let server = HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(pool.clone()))
            .route("/add_vote", web::post().to(handlers::add_vote))
            .route("/get_vote/{uuid}", web::get().to(handlers::get_vote))
    })
    .bind(config.server_addr.clone())?
    .run();
    println!("Server running at http://{}/", config.server_addr);

    server.await
}
