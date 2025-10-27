-- Create "events" table
CREATE TABLE IF NOT EXISTS `events` (
  `id` UInt64 NOT NULL,
  `user_id` UInt64,
  `event_type` String,
  `event_data` String,
  `created_at` DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (`user_id`, `created_at`);