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

    #[derive(Deserialize, PostgresMapper, Serialize)]
    #[pg_mapper(table = "votes")]
    pub struct VoteDB {
        id: String,
        nonces: String,
        permutation: String,
        strength: i32,
        ip_hash: String,

        // Two-Round Poll
        rd2_0: i32,
        rd2_1: i32,
        rd2_2: i32,
        rd2_3: i32,
        rd2_4: i32,
        rd2_5: i32,
        rd2_6: i32,
        rd2_7: i32,
        rd2_8: i32,
        rd2_9: i32,

        // One-Round Poll
        rd1_0: i32,
        rd1_1: i32,
        rd1_2: i32,
        rd1_3: i32,
        rd1_4: i32,
        rd1_5: i32,
        rd1_6: i32,
        rd1_7: i32,
        rd1_8: i32,
        rd1_9: i32,

        // Divide Poll
        div_0: i32,
        div_1: i32,
        div_2: i32,
        div_3: i32,
        div_4: i32,
        div_5: i32,
        div_6: i32,
        div_7: i32,
        div_8: i32,
        div_9: i32,

        // D21 Poll
        d21_0: i32,
        d21_1: i32,
        d21_2: i32,
        d21_3: i32,
        d21_4: i32,
        d21_5: i32,
        d21_6: i32,
        d21_7: i32,
        d21_8: i32,
        d21_9: i32,

        // Doodle Poll
        ddl_0: i32,
        ddl_1: i32,
        ddl_2: i32,
        ddl_3: i32,
        ddl_4: i32,
        ddl_5: i32,
        ddl_6: i32,
        ddl_7: i32,
        ddl_8: i32,
        ddl_9: i32,

        // Ord Poll
        ord_0: i32,
        ord_1: i32,
        ord_2: i32,
        ord_3: i32,
        ord_4: i32,
        ord_5: i32,
        ord_6: i32,
        ord_7: i32,
        ord_8: i32,
        ord_9: i32,

        // Star Poll
        str_0: i32,
        str_1: i32,
        str_2: i32,
        str_3: i32,
        str_4: i32,
        str_5: i32,
        str_6: i32,
        str_7: i32,
        str_8: i32,
        str_9: i32,

        // Emoji Poll
        emj_0: String,
        emj_1: String,
        emj_2: String,
        emj_3: String,
        emj_4: String,
        emj_5: String,
        emj_6: String,
        emj_7: String,
        emj_8: String,
        emj_9: String,
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
                _ => HttpResponse::InternalServerError().finish(),
            }
        }
    }
}

mod db {
    use deadpool_postgres::Client;
    use tokio_pg_mapper::FromTokioPostgresRow;

    use crate::{errors::MyError, models::VoteWeb, models::VoteDB};

    fn index_to_points(value: i32, index: i32) -> i32 {
        if index == value { 1 } else { 0 }
    }

    pub async fn add_vote(client: &Client, vote_info: VoteWeb) -> Result<VoteDB, MyError> {
        let _stmt = include_str!("../sql/add_vote.sql");
        let stmt = client.prepare(&_stmt).await.unwrap();

        let order_as_strings: Vec<String> = vote_info.order.iter().map(|&v| v.to_string()).collect();
        let permutation: String = order_as_strings.join(",");

        let nonces_as_one_string = vote_info.nonces.join(",");

        client
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
            .await?
            .iter()
            .map(|row| VoteDB::from_row_ref(row).unwrap())
            .collect::<Vec<VoteDB>>()
            .pop()
            .ok_or(MyError::NotFound) // more applicable for SELECTs
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

        println!("Add vote with uuid {}", vote_info.uuid);

        let res = db::add_vote(&client, vote_info).await;

        match res {
            Err(e) => { println!("{:#?}", e); Ok(HttpResponse::Ok().finish()) },
            Ok(_) => Ok(HttpResponse::Ok().finish()),
        }
    }

    pub async fn get_vote() -> Result<HttpResponse, Error> {

        println!("Hello");

        Ok(HttpResponse::Ok().finish())
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
            .route("/get_vote", web::get().to(handlers::get_vote))
    })
    .bind(config.server_addr.clone())?
    .run();
    println!("Server running at http://{}/", config.server_addr);

    server.await
}
