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
    ValidationError(String),
}
impl std::error::Error for MyError {}

impl ResponseError for MyError {
    fn error_response(&self) -> HttpResponse {
        match *self {
            MyError::NotFound => HttpResponse::NotFound().finish(),
            MyError::PoolError(ref err) => {
                HttpResponse::InternalServerError().body(err.to_string())
            }
            MyError::PGError(ref err) => HttpResponse::InternalServerError().body(err.to_string()),
            MyError::ValidationError(ref description) => {
                HttpResponse::InternalServerError().body(description.to_string())
            }
            _ => HttpResponse::InternalServerError().finish(),
        }
    }
}
