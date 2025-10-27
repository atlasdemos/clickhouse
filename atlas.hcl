variable "clickhouse_url" {
  type = string
  description = "ClickHouse target db connection string"
  default = getenv("CLICKHOUSE_URL")
}

variable "clickhouse_dev_url" {
  type = string
  description = "ClickHouse dev db connection string"
  default = getenv("CLICKHOUSE_DEV_URL")
}

env "demo" {
  url = var.clickhouse_url
  dev = var.clickhouse_dev_url
  schema {
    src = "file://schema.sql"
    repo {
      name = "clickhouse-demo"
    }
  }
  migration {
    dir = "file://migrations"
  }
}