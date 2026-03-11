DO $$
BEGIN
    CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD '123';
EXCEPTION
    WHEN duplicate_object THEN 
        RAISE NOTICE 'User replicator already exists';
END
$$;

-- Создаем слот репликации
DO $$
BEGIN
    PERFORM pg_create_physical_replication_slot('replica_slot');
EXCEPTION
    WHEN duplicate_object THEN 
        RAISE NOTICE 'Slot replica_slot already exists';
END
$$;

-- Пользователь для мониторинга
DO $$
BEGIN
    CREATE USER prometheus WITH PASSWORD 'prometheus';
    GRANT pg_monitor TO prometheus;
EXCEPTION
    WHEN duplicate_object THEN 
        RAISE NOTICE 'User prometheus already exists';
END
$$;

-- Создаем БД БЕЗ IF NOT EXISTS (PG 16)
DO $$
BEGIN
    EXECUTE 'CREATE DATABASE db';
EXCEPTION
    WHEN duplicate_database THEN 
        RAISE NOTICE 'Database db already exists';
END
$$;

-- Переключаемся в БД и создаем таблицу
\c db

DO $$
BEGIN
    CREATE TABLE test_table (
        id SERIAL PRIMARY KEY,
        data TEXT,
        created_at TIMESTAMP DEFAULT NOW()
    );
EXCEPTION
    WHEN duplicate_table THEN 
        RAISE NOTICE 'Table test_table already exists';
END
$$;

INSERT INTO test_table (data) VALUES ('Primary ready') 
ON CONFLICT DO NOTHING;

-- Настройки WAL для репликации
ALTER SYSTEM SET wal_level = 'replica';
ALTER SYSTEM SET max_wal_senders = 10;
ALTER SYSTEM SET max_replication_slots = 10;
SELECT pg_reload_conf();
