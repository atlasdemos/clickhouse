-- Create "users" table
CREATE TABLE IF NOT EXISTS `users` (
  `id` UInt64 NOT NULL,
  `email` String,
  `display_name` String,
  `created_at` DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY `id`;