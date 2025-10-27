-- Create "users" table
CREATE TABLE `users` (
  `id` UInt64 NOT NULL,
  `email` String,
  `display_name` String,
  `full_name` String,
  `created_at` DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY `id`;

-- Create "events" table
CREATE TABLE `events` (
  `id` UInt64 NOT NULL,
  `user_id` UInt64,
  `event_type` String,
  `event_data` String,
  `created_at` DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (`user_id`, `created_at`);