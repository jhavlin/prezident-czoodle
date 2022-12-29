mod config;
mod crypto_utils;
mod db;
mod errors;
mod models;

use crate::{errors::MyError, models::VoteWeb};
use ::config::Config;
use actix_web::{web, App, Error, HttpRequest, HttpResponse, HttpServer};
use deadpool_postgres::{Client, Pool};
use dotenv::dotenv;
use std::sync::Arc;
use tokio_postgres::NoTls;

use crate::config::ExampleConfig;

#[derive(Debug, Clone)]
pub struct HandlerConfig {
    pub ip_hash_salt: Arc<String>,
}

pub async fn add_vote(
    req: HttpRequest,
    vote: web::Json<VoteWeb>,
    db_pool: web::Data<Pool>,
    handler_config: web::Data<HandlerConfig>,
) -> Result<HttpResponse, Error> {
    let vote_info: VoteWeb = vote.into_inner();

    let ip_address = req
        .headers()
        .get("x-real-ip")
        .map(|v| v.to_str().unwrap_or_else(|_| ""))
        .unwrap_or_else(|| "");

    let ip_address_hash =
        crypto_utils::sha256(&format!("{}{}", &ip_address, &handler_config.ip_hash_salt));

    println!("{:#?}", &handler_config);
    println!("{:#?}", &ip_address);
    println!("{:#?}", &ip_address_hash);

    let client: Client = db_pool.get().await.map_err(MyError::PoolError)?;

    db::add_vote(&client, vote_info, &ip_address_hash).await?;

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

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    dotenv().ok();

    let config_ = Config::builder()
        .add_source(::config::Environment::default())
        .build()
        .unwrap();

    let config: ExampleConfig = config_.try_deserialize().unwrap();

    let pool = config.pg.create_pool(None, NoTls).unwrap();

    let handler_config = HandlerConfig {
        ip_hash_salt: Arc::new(config.hash_salt),
    };

    let server = HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(pool.clone()))
            .app_data(web::Data::new(handler_config.clone()))
            .route("/add_vote", web::post().to(add_vote))
            .route("/get_vote/{uuid}", web::get().to(get_vote))
    })
    .bind(config.server_addr.clone())?
    .run();
    println!("Server running at http://{}/", config.server_addr);

    server.await
}
