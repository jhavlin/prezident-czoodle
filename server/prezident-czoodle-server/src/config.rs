use serde::Deserialize;

#[derive(Debug, Default, Deserialize)]
pub struct ExampleConfig {
    pub server_addr: String,
    pub pg: deadpool_postgres::Config,
}
