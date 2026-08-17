--
-- PostgreSQL database dump
--

\restrict YbaHzY9KHjJqjPoVKHAMchbtbmVGD9KqbeRxjhgqarEZb4uh2ymeX0G4amaPvNC

-- Dumped from database version 16.14
-- Dumped by pg_dump version 16.14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: affiliate_activation_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.affiliate_activation_status AS ENUM (
    'inactive',
    'pending',
    'active',
    'rejected'
);


--
-- Name: asset_class; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.asset_class AS ENUM (
    'forex',
    'crypto',
    'stocks',
    'mixed'
);


--
-- Name: asset_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.asset_type AS ENUM (
    'stock',
    'crypto',
    'forex',
    'commodity'
);


--
-- Name: calendar_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.calendar_status AS ENUM (
    'active',
    'paused',
    'ended'
);


--
-- Name: commission_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.commission_status AS ENUM (
    'pending',
    'credited',
    'cancelled'
);


--
-- Name: contest_duration_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.contest_duration_type AS ENUM (
    'rush_30min',
    'hourly',
    'four_hour',
    'daily',
    'weekly'
);


--
-- Name: contest_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.contest_status AS ENUM (
    'draft',
    'scheduled',
    'registration_open',
    'registration_closed',
    'running',
    'settling',
    'paused',
    'completed',
    'cancelled'
);


--
-- Name: contest_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.contest_type AS ENUM (
    'rush',
    'standard',
    'tournament',
    'championship',
    'practice'
);


--
-- Name: kyc_document_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.kyc_document_type AS ENUM (
    'passport',
    'national_id',
    'drivers_license',
    'residence_permit',
    'birth_certificate'
);


--
-- Name: kyc_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.kyc_status AS ENUM (
    'none',
    'pending',
    'under_review',
    'verified',
    'rejected',
    'expired'
);


--
-- Name: ledger_ref_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.ledger_ref_type AS ENUM (
    'payment_intent',
    'payout',
    'contest',
    'admin_action'
);


--
-- Name: ledger_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.ledger_type AS ENUM (
    'deposit',
    'withdrawal',
    'contest_entry',
    'contest_refund',
    'prize_credit',
    'adjustment',
    'withdraw_fee',
    'withdrawal_refund',
    'withdraw_fee_refund'
);


--
-- Name: market_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.market_type AS ENUM (
    'crypto',
    'forex'
);


--
-- Name: oauth_provider; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.oauth_provider AS ENUM (
    'google',
    'github',
    'facebook',
    'apple',
    'discord'
);


--
-- Name: order_side; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.order_side AS ENUM (
    'buy',
    'sell'
);


--
-- Name: order_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.order_status AS ENUM (
    'pending',
    'open',
    'partially_filled',
    'filled',
    'cancelled',
    'rejected',
    'expired'
);


--
-- Name: order_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.order_type AS ENUM (
    'market',
    'limit',
    'stop',
    'stop_limit',
    'buy_limit',
    'sell_limit',
    'buy_stop',
    'sell_stop'
);


--
-- Name: payment_intent_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.payment_intent_status AS ENUM (
    'pending',
    'processing',
    'succeeded',
    'failed',
    'cancelled',
    'refunded',
    'expired'
);


--
-- Name: payout_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.payout_status AS ENUM (
    'pending',
    'processing',
    'succeeded',
    'failed',
    'cancelled',
    'rejected'
);


--
-- Name: position_side; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.position_side AS ENUM (
    'long',
    'short'
);


--
-- Name: prize_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.prize_status AS ENUM (
    'pending',
    'credited',
    'failed'
);


--
-- Name: recurrence_pattern; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.recurrence_pattern AS ENUM (
    'daily',
    'weekly',
    'biweekly',
    'monthly',
    'custom_cron'
);


--
-- Name: referral_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.referral_status AS ENUM (
    'pending',
    'qualified',
    'paid'
);


--
-- Name: settlement_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.settlement_status AS ENUM (
    'pending',
    'in_progress',
    'completed',
    'failed',
    'partial'
);


--
-- Name: shard_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.shard_status AS ENUM (
    'active',
    'draining',
    'inactive',
    'maintenance'
);


--
-- Name: template_duration_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.template_duration_type AS ENUM (
    'quick_30m',
    'free_1h',
    'four_hour',
    'daily',
    'weekly',
    'special'
);


--
-- Name: ticket_category; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.ticket_category AS ENUM (
    'account',
    'payment',
    'contest',
    'technical',
    'kyc',
    'other'
);


--
-- Name: ticket_priority; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.ticket_priority AS ENUM (
    'low',
    'medium',
    'high',
    'urgent'
);


--
-- Name: ticket_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.ticket_status AS ENUM (
    'open',
    'answered',
    'user_replied',
    'closed',
    'resolved'
);


--
-- Name: user_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_status AS ENUM (
    'active',
    'suspended',
    'pending'
);


--
-- Name: wallet_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.wallet_status AS ENUM (
    'active',
    'frozen',
    'closed'
);


--
-- Name: weekend_behavior; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.weekend_behavior AS ENUM (
    'crypto_only',
    'skip',
    'normal'
);


--
-- Name: calculate_tragge_point_contribution(numeric, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_tragge_point_contribution(p_score numeric, p_rank integer, p_participants integer) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    v_participant_mult DECIMAL(10, 6);
    v_rank_bonus DECIMAL(10, 6);
    v_contribution DECIMAL(20, 4);
BEGIN
    -- Only positive scores contribute
    IF p_score <= 0 THEN
        RETURN 0;
    END IF;

    -- Handle edge case of no participants
    IF p_participants <= 0 THEN
        RETURN 0;
    END IF;

    -- Participant multiplier: log10(participants) / log10(1000)
    v_participant_mult := LOG(GREATEST(p_participants, 1)) / LOG(1000);

    -- Clamp participant multiplier to [0.1, 1.5]
    v_participant_mult := GREATEST(0.1, LEAST(1.5, v_participant_mult));

    -- Rank bonus: 1.0 + (0.5 * (1 - rank/total))
    v_rank_bonus := 1.0 + (0.5 * (1.0 - (p_rank::DECIMAL / p_participants::DECIMAL)));

    -- Clamp rank bonus to [1.0, 1.5]
    v_rank_bonus := GREATEST(1.0, LEAST(1.5, v_rank_bonus));

    -- Calculate contribution
    v_contribution := p_score * v_participant_mult * v_rank_bonus;

    RETURN v_contribution;
END;
$$;


--
-- Name: check_max_template_versions(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_max_template_versions() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (SELECT COUNT(*) FROM email_template_versions WHERE slug = NEW.slug) >= 5 THEN
        RAISE EXCEPTION 'Maximum 5 template versions per slug allowed';
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: create_shard_partitions(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_shard_partitions(new_shard_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    orders_partition_name TEXT;
    fills_partition_name TEXT;
    positions_partition_name TEXT;
BEGIN
    -- Validate shard_id exists in shard_config
    IF NOT EXISTS (SELECT 1 FROM shard_config WHERE shard_id = new_shard_id) THEN
        RAISE EXCEPTION 'Shard ID % does not exist in shard_config. Add it first.', new_shard_id;
    END IF;

    -- Generate partition table names
    orders_partition_name := 'orders_shard_' || new_shard_id;
    fills_partition_name := 'fills_shard_' || new_shard_id;
    positions_partition_name := 'positions_shard_' || new_shard_id;

    -- Check if partitions already exist
    IF EXISTS (SELECT 1 FROM pg_class WHERE relname = orders_partition_name) THEN
        RAISE NOTICE 'Partition % already exists, skipping orders', orders_partition_name;
    ELSE
        -- Create orders partition
        EXECUTE format(
            'CREATE TABLE %I PARTITION OF orders FOR VALUES IN (%s)',
            orders_partition_name, new_shard_id
        );

        -- Create indexes for orders partition
        EXECUTE format('CREATE INDEX idx_orders_s%s_contest ON %I(contest_id)', new_shard_id, orders_partition_name);
        EXECUTE format('CREATE INDEX idx_orders_s%s_user ON %I(user_id)', new_shard_id, orders_partition_name);
        EXECUTE format('CREATE INDEX idx_orders_s%s_symbol ON %I(symbol)', new_shard_id, orders_partition_name);
        EXECUTE format('CREATE INDEX idx_orders_s%s_status ON %I(status)', new_shard_id, orders_partition_name);
        EXECUTE format('CREATE INDEX idx_orders_s%s_created_at ON %I(created_at)', new_shard_id, orders_partition_name);
        EXECUTE format('CREATE INDEX idx_orders_s%s_contest_user ON %I(contest_id, user_id)', new_shard_id, orders_partition_name);
        EXECUTE format('CREATE INDEX idx_orders_s%s_contest_user_status ON %I(contest_id, user_id, status)', new_shard_id, orders_partition_name);
        EXECUTE format('CREATE INDEX idx_orders_s%s_contest_symbol ON %I(contest_id, symbol)', new_shard_id, orders_partition_name);
        EXECUTE format('CREATE UNIQUE INDEX idx_orders_s%s_order_id ON %I(order_id)', new_shard_id, orders_partition_name);

        RAISE NOTICE 'Created orders partition: %', orders_partition_name;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_class WHERE relname = fills_partition_name) THEN
        RAISE NOTICE 'Partition % already exists, skipping fills', fills_partition_name;
    ELSE
        -- Create fills partition
        EXECUTE format(
            'CREATE TABLE %I PARTITION OF fills FOR VALUES IN (%s)',
            fills_partition_name, new_shard_id
        );

        -- Create indexes for fills partition
        EXECUTE format('CREATE INDEX idx_fills_s%s_order ON %I(order_id)', new_shard_id, fills_partition_name);
        EXECUTE format('CREATE INDEX idx_fills_s%s_contest ON %I(contest_id)', new_shard_id, fills_partition_name);
        EXECUTE format('CREATE INDEX idx_fills_s%s_user ON %I(user_id)', new_shard_id, fills_partition_name);
        EXECUTE format('CREATE INDEX idx_fills_s%s_symbol ON %I(symbol)', new_shard_id, fills_partition_name);
        EXECUTE format('CREATE INDEX idx_fills_s%s_created_at ON %I(created_at)', new_shard_id, fills_partition_name);
        EXECUTE format('CREATE INDEX idx_fills_s%s_contest_user ON %I(contest_id, user_id)', new_shard_id, fills_partition_name);
        EXECUTE format('CREATE INDEX idx_fills_s%s_contest_symbol ON %I(contest_id, symbol)', new_shard_id, fills_partition_name);
        EXECUTE format('CREATE UNIQUE INDEX idx_fills_s%s_fill_id ON %I(fill_id)', new_shard_id, fills_partition_name);

        RAISE NOTICE 'Created fills partition: %', fills_partition_name;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_class WHERE relname = positions_partition_name) THEN
        RAISE NOTICE 'Partition % already exists, skipping positions', positions_partition_name;
    ELSE
        -- Create positions partition
        EXECUTE format(
            'CREATE TABLE %I PARTITION OF positions FOR VALUES IN (%s)',
            positions_partition_name, new_shard_id
        );

        -- Create indexes for positions partition
        EXECUTE format('CREATE INDEX idx_positions_s%s_contest ON %I(contest_id)', new_shard_id, positions_partition_name);
        EXECUTE format('CREATE INDEX idx_positions_s%s_user ON %I(user_id)', new_shard_id, positions_partition_name);
        EXECUTE format('CREATE INDEX idx_positions_s%s_symbol ON %I(symbol)', new_shard_id, positions_partition_name);
        EXECUTE format('CREATE INDEX idx_positions_s%s_opened_at ON %I(opened_at)', new_shard_id, positions_partition_name);
        EXECUTE format('CREATE INDEX idx_positions_s%s_closed_at ON %I(closed_at)', new_shard_id, positions_partition_name);
        EXECUTE format('CREATE INDEX idx_positions_s%s_contest_user ON %I(contest_id, user_id)', new_shard_id, positions_partition_name);
        EXECUTE format('CREATE INDEX idx_positions_s%s_contest_user_symbol ON %I(contest_id, user_id, symbol)', new_shard_id, positions_partition_name);
        EXECUTE format('CREATE INDEX idx_positions_s%s_open ON %I(contest_id, user_id) WHERE closed_at IS NULL', new_shard_id, positions_partition_name);
        EXECUTE format('CREATE UNIQUE INDEX idx_positions_s%s_position_id ON %I(position_id)', new_shard_id, positions_partition_name);

        RAISE NOTICE 'Created positions partition: %', positions_partition_name;
    END IF;

    RAISE NOTICE 'Successfully created all partitions for shard %', new_shard_id;
END;
$$;


--
-- Name: FUNCTION create_shard_partitions(new_shard_id integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.create_shard_partitions(new_shard_id integer) IS 'Creates new partition tables for orders, fills, and positions for a given shard_id';


--
-- Name: drop_shard_partitions(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.drop_shard_partitions(target_shard_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    orders_count BIGINT;
    fills_count BIGINT;
    positions_count BIGINT;
    orders_partition_name TEXT;
    fills_partition_name TEXT;
    positions_partition_name TEXT;
BEGIN
    -- Prevent dropping shard 0 (default shard)
    IF target_shard_id = 0 THEN
        RAISE EXCEPTION 'Cannot drop shard 0 - it is the default shard';
    END IF;

    -- Generate partition table names
    orders_partition_name := 'orders_shard_' || target_shard_id;
    fills_partition_name := 'fills_shard_' || target_shard_id;
    positions_partition_name := 'positions_shard_' || target_shard_id;

    -- Check for data in partitions
    EXECUTE format('SELECT COUNT(*) FROM %I', orders_partition_name) INTO orders_count;
    EXECUTE format('SELECT COUNT(*) FROM %I', fills_partition_name) INTO fills_count;
    EXECUTE format('SELECT COUNT(*) FROM %I', positions_partition_name) INTO positions_count;

    IF orders_count > 0 OR fills_count > 0 OR positions_count > 0 THEN
        RAISE EXCEPTION 'Shard % contains data (orders: %, fills: %, positions: %). Migrate data before dropping.',
            target_shard_id, orders_count, fills_count, positions_count;
    END IF;

    -- Drop partitions
    EXECUTE format('DROP TABLE IF EXISTS %I', orders_partition_name);
    EXECUTE format('DROP TABLE IF EXISTS %I', fills_partition_name);
    EXECUTE format('DROP TABLE IF EXISTS %I', positions_partition_name);

    RAISE NOTICE 'Successfully dropped all partitions for shard %', target_shard_id;
END;
$$;


--
-- Name: FUNCTION drop_shard_partitions(target_shard_id integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.drop_shard_partitions(target_shard_id integer) IS 'Drops empty partition tables for a given shard_id (safety check prevents dropping non-empty partitions)';


--
-- Name: generate_referral_code(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_referral_code() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_code VARCHAR(20);
    chars VARCHAR(36) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    i INT;
    code_exists BOOLEAN;
BEGIN
    LOOP
        new_code := '';
        FOR i IN 1..8 LOOP
            new_code := new_code || substr(chars, floor(random() * 36 + 1)::int, 1);
        END LOOP;

        SELECT EXISTS(SELECT 1 FROM referral_codes WHERE code = new_code) INTO code_exists;

        IF NOT code_exists THEN
            RETURN new_code;
        END IF;
    END LOOP;
END;
$$;


--
-- Name: get_shard_id_for_contest(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_shard_id_for_contest(p_contest_id uuid) RETURNS integer
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    v_shard_id INT;
BEGIN
    SELECT COALESCE(shard_id, 0) INTO v_shard_id
    FROM contests
    WHERE id = p_contest_id;

    IF v_shard_id IS NULL THEN
        RETURN 0; -- Default shard for unknown contests
    END IF;

    RETURN v_shard_id;
END;
$$;


--
-- Name: FUNCTION get_shard_id_for_contest(p_contest_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.get_shard_id_for_contest(p_contest_id uuid) IS 'Returns the shard_id for a given contest_id';


--
-- Name: migrate_contest_to_shard(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.migrate_contest_to_shard(p_contest_id uuid, p_target_shard_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    current_shard_id INT;
    order_count BIGINT;
    fill_count BIGINT;
    position_count BIGINT;
BEGIN
    -- Validate target shard exists
    IF NOT EXISTS (SELECT 1 FROM shard_config WHERE shard_id = p_target_shard_id) THEN
        RAISE EXCEPTION 'Target shard % does not exist in shard_config', p_target_shard_id;
    END IF;

    -- Get current shard_id for the contest
    SELECT COALESCE(shard_id, 0) INTO current_shard_id FROM contests WHERE id = p_contest_id;

    IF current_shard_id IS NULL THEN
        RAISE EXCEPTION 'Contest % not found', p_contest_id;
    END IF;

    IF current_shard_id = p_target_shard_id THEN
        RAISE NOTICE 'Contest % is already on shard %, no migration needed', p_contest_id, p_target_shard_id;
        RETURN;
    END IF;

    -- Count records to migrate
    SELECT COUNT(*) INTO order_count FROM orders WHERE contest_id = p_contest_id;
    SELECT COUNT(*) INTO fill_count FROM fills WHERE contest_id = p_contest_id;
    SELECT COUNT(*) INTO position_count FROM positions WHERE contest_id = p_contest_id;

    RAISE NOTICE 'Migrating contest % from shard % to shard %', p_contest_id, current_shard_id, p_target_shard_id;
    RAISE NOTICE 'Records to migrate - Orders: %, Fills: %, Positions: %', order_count, fill_count, position_count;

    -- Migrate orders (insert into new partition, then delete from old)
    INSERT INTO orders (
        order_id, shard_id, contest_id, user_id, symbol, side, type,
        qty, qty_filled, limit_price, stop_price, take_profit, stop_loss,
        status, created_at, updated_at
    )
    SELECT
        order_id, p_target_shard_id, contest_id, user_id, symbol, side, type,
        qty, qty_filled, limit_price, stop_price, take_profit, stop_loss,
        status, created_at, updated_at
    FROM orders
    WHERE contest_id = p_contest_id AND shard_id = current_shard_id;

    DELETE FROM orders WHERE contest_id = p_contest_id AND shard_id = current_shard_id;

    -- Migrate fills
    INSERT INTO fills (
        fill_id, shard_id, order_id, contest_id, user_id, symbol, side,
        qty, fill_price, created_at
    )
    SELECT
        fill_id, p_target_shard_id, order_id, contest_id, user_id, symbol, side,
        qty, fill_price, created_at
    FROM fills
    WHERE contest_id = p_contest_id AND shard_id = current_shard_id;

    DELETE FROM fills WHERE contest_id = p_contest_id AND shard_id = current_shard_id;

    -- Migrate positions
    INSERT INTO positions (
        position_id, shard_id, contest_id, user_id, symbol, side,
        qty_open, entry_price, qty_used, realized_score, opened_at, closed_at
    )
    SELECT
        position_id, p_target_shard_id, contest_id, user_id, symbol, side,
        qty_open, entry_price, qty_used, realized_score, opened_at, closed_at
    FROM positions
    WHERE contest_id = p_contest_id AND shard_id = current_shard_id;

    DELETE FROM positions WHERE contest_id = p_contest_id AND shard_id = current_shard_id;

    -- Update contest shard_id
    UPDATE contests SET shard_id = p_target_shard_id WHERE id = p_contest_id;

    -- Log the migration
    INSERT INTO shard_assignment_log (contest_id, old_shard_id, new_shard_id, reason)
    VALUES (p_contest_id, current_shard_id, p_target_shard_id, 'Data migration via migrate_contest_to_shard');

    RAISE NOTICE 'Successfully migrated contest % to shard %', p_contest_id, p_target_shard_id;
END;
$$;


--
-- Name: FUNCTION migrate_contest_to_shard(p_contest_id uuid, p_target_shard_id integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.migrate_contest_to_shard(p_contest_id uuid, p_target_shard_id integer) IS 'Migrates all data for a contest from current shard to target shard';


--
-- Name: pgbouncer_get_auth(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pgbouncer_get_auth(p_username text) RETURNS TABLE(username text, password text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        usename::TEXT,
        passwd::TEXT
    FROM pg_catalog.pg_shadow
    WHERE usename = p_username;
END;
$$;


--
-- Name: refresh_calendar_contests_mv(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.refresh_calendar_contests_mv() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY calendar_contests_mv;
END;
$$;


--
-- Name: trigger_create_referral_code(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trigger_create_referral_code() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO referral_codes (code, user_id, is_active, activation_status)
    VALUES (generate_referral_code(), NEW.id, FALSE, 'inactive');
    RETURN NEW;
END;
$$;


--
-- Name: trigger_create_wallet_for_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trigger_create_wallet_for_user() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO wallets (user_id) VALUES (NEW.id);
    RETURN NEW;
END;
$$;


--
-- Name: trigger_set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trigger_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: trigger_update_contest_participant_count(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trigger_update_contest_participant_count() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE contests
        SET current_participants = current_participants + 1
        WHERE id = NEW.contest_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE contests
        SET current_participants = GREATEST(0, current_participants - 1)
        WHERE id = OLD.contest_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;


--
-- Name: update_calendar_entries_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_calendar_entries_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: update_oauth_accounts_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_oauth_accounts_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: update_support_ticket_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_support_ticket_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: update_symbols_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_symbols_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: update_user_stats(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_user_stats() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total_contests INT;
    v_total_wins INT;
    v_total_top3 INT;
    v_total_score DECIMAL(20, 2);
    v_total_participants INT;
    v_tragge_point DECIMAL(20, 2);
    v_win_rate DECIMAL(5, 2);
    v_total_pnl DECIMAL(20, 2);
    v_total_trades BIGINT;
    v_avg_trade_duration INT;
    v_best_market VARCHAR(20);
    v_best_market_pnl DECIMAL(20, 2);
    v_best_rank INT;
BEGIN
    -- Calculate aggregates from history
    SELECT
        COUNT(*),
        SUM(CASE WHEN rank = 1 THEN 1 ELSE 0 END),
        SUM(CASE WHEN rank <= 3 THEN 1 ELSE 0 END),
        SUM(score),
        SUM(participants),
        SUM(pnl),
        SUM(trades_count),
        COALESCE(AVG(avg_trade_duration_seconds), 0),
        MIN(rank)
    INTO
        v_total_contests,
        v_total_wins,
        v_total_top3,
        v_total_score,
        v_total_participants,
        v_total_pnl,
        v_total_trades,
        v_avg_trade_duration,
        v_best_rank
    FROM user_score_history
    WHERE user_id = NEW.user_id;

    -- Calculate Tragge Point: sum of all contest contributions
    SELECT COALESCE(SUM(score_contribution), 0)
    INTO v_tragge_point
    FROM user_score_history
    WHERE user_id = NEW.user_id;

    -- Calculate win rate
    IF v_total_contests > 0 THEN
        v_win_rate := (v_total_wins::DECIMAL / v_total_contests::DECIMAL) * 100;
    ELSE
        v_win_rate := 0;
    END IF;

    -- Find best market (symbol with highest total PnL)
    SELECT top_symbol, SUM(top_symbol_pnl)
    INTO v_best_market, v_best_market_pnl
    FROM user_score_history
    WHERE user_id = NEW.user_id AND top_symbol IS NOT NULL
    GROUP BY top_symbol
    ORDER BY SUM(top_symbol_pnl) DESC
    LIMIT 1;

    -- Insert or update user_stats
    INSERT INTO user_stats (
        user_id,
        total_contests,
        total_wins,
        total_top3,
        total_score,
        total_participants,
        tragge_point,
        win_rate,
        avg_trade_duration_seconds,
        best_market,
        best_market_pnl,
        total_trades,
        total_pnl,
        updated_at
    ) VALUES (
        NEW.user_id,
        v_total_contests,
        v_total_wins,
        v_total_top3,
        v_total_score,
        v_total_participants,
        v_tragge_point,
        v_win_rate,
        v_avg_trade_duration,
        v_best_market,
        COALESCE(v_best_market_pnl, 0),
        v_total_trades,
        v_total_pnl,
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        total_contests = EXCLUDED.total_contests,
        total_wins = EXCLUDED.total_wins,
        total_top3 = EXCLUDED.total_top3,
        total_score = EXCLUDED.total_score,
        total_participants = EXCLUDED.total_participants,
        tragge_point = EXCLUDED.tragge_point,
        win_rate = EXCLUDED.win_rate,
        avg_trade_duration_seconds = EXCLUDED.avg_trade_duration_seconds,
        best_market = EXCLUDED.best_market,
        best_market_pnl = EXCLUDED.best_market_pnl,
        total_trades = EXCLUDED.total_trades,
        total_pnl = EXCLUDED.total_pnl,
        updated_at = NOW();

    RETURN NEW;
END;
$$;


--
-- Name: validate_active_days(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_active_days() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    d INT;
BEGIN
    IF NEW.active_days IS NOT NULL THEN
        IF array_length(NEW.active_days, 1) IS NULL THEN
            RAISE EXCEPTION 'active_days must not be an empty array';
        END IF;
        FOREACH d IN ARRAY NEW.active_days LOOP
            IF d < 0 OR d > 6 THEN
                RAISE EXCEPTION 'active_days values must be between 0 and 6, got %', d;
            END IF;
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin_mfa_credentials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_mfa_credentials (
    user_id uuid NOT NULL,
    secret_ciphertext text NOT NULL,
    last_totp_counter bigint,
    enabled_at timestamp with time zone NOT NULL,
    recovery_generation integer DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT admin_mfa_credentials_recovery_generation_check CHECK ((recovery_generation > 0)),
    CONSTRAINT admin_mfa_credentials_secret_ciphertext_check CHECK ((secret_ciphertext ~~ 'enc:admin-mfa:v1:%'::text))
);


--
-- Name: TABLE admin_mfa_credentials; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.admin_mfa_credentials IS 'Platform-owned Admin-only Super Admin MFA credentials; never used for User authentication.';


--
-- Name: COLUMN admin_mfa_credentials.last_totp_counter; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.admin_mfa_credentials.last_totp_counter IS 'Highest accepted RFC 6238 counter, updated atomically to prevent replay.';


--
-- Name: admin_mfa_recovery_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_mfa_recovery_codes (
    user_id uuid NOT NULL,
    generation integer NOT NULL,
    code_digest bytea NOT NULL,
    used_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT admin_mfa_recovery_codes_code_digest_check CHECK ((octet_length(code_digest) = 32)),
    CONSTRAINT admin_mfa_recovery_codes_generation_check CHECK ((generation > 0))
);


--
-- Name: TABLE admin_mfa_recovery_codes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.admin_mfa_recovery_codes IS 'Keyed digests of single-use Super Admin recovery codes; plaintext is never stored.';


--
-- Name: affiliate_commissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.affiliate_commissions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    referrer_id uuid NOT NULL,
    referred_id uuid NOT NULL,
    source_type character varying(50) NOT NULL,
    source_id uuid NOT NULL,
    gross_amount_cents bigint NOT NULL,
    commission_rate_bps integer NOT NULL,
    commission_cents bigint NOT NULL,
    status public.commission_status DEFAULT 'pending'::public.commission_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    credited_at timestamp with time zone,
    CONSTRAINT chk_commission_cents_valid CHECK ((commission_cents >= 0)),
    CONSTRAINT chk_commission_rate_valid CHECK (((commission_rate_bps >= 0) AND (commission_rate_bps <= 10000))),
    CONSTRAINT chk_gross_amount_positive CHECK ((gross_amount_cents > 0))
);


--
-- Name: referral_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.referral_codes (
    code character varying(20) NOT NULL,
    user_id uuid NOT NULL,
    commission_rate_bps integer DEFAULT 500 NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    activation_status public.affiliate_activation_status DEFAULT 'inactive'::public.affiliate_activation_status NOT NULL,
    activation_requested_at timestamp with time zone,
    activation_approved_at timestamp with time zone,
    activation_rejected_at timestamp with time zone,
    rejection_reason text,
    CONSTRAINT chk_commission_rate_valid CHECK (((commission_rate_bps >= 0) AND (commission_rate_bps <= 10000)))
);


--
-- Name: referrals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.referrals (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    referrer_id uuid NOT NULL,
    referred_id uuid NOT NULL,
    code character varying(20) NOT NULL,
    status public.referral_status DEFAULT 'pending'::public.referral_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    qualified_at timestamp with time zone,
    CONSTRAINT chk_referrer_not_referred CHECK ((referrer_id <> referred_id))
);


--
-- Name: affiliate_stats; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.affiliate_stats AS
 SELECT rc.user_id AS referrer_id,
    rc.code,
    rc.commission_rate_bps,
    rc.is_active,
    rc.activation_status,
    rc.activation_requested_at,
    rc.activation_approved_at,
    count(r.id) AS total_referrals,
    count(
        CASE
            WHEN (r.status = ANY (ARRAY['qualified'::public.referral_status, 'paid'::public.referral_status])) THEN 1
            ELSE NULL::integer
        END) AS qualified_referrals,
    COALESCE(sum(
        CASE
            WHEN (ac.status = 'credited'::public.commission_status) THEN ac.commission_cents
            ELSE (0)::bigint
        END), (0)::numeric) AS total_earned_cents,
    COALESCE(sum(
        CASE
            WHEN (ac.status = 'pending'::public.commission_status) THEN ac.commission_cents
            ELSE (0)::bigint
        END), (0)::numeric) AS pending_cents
   FROM ((public.referral_codes rc
     LEFT JOIN public.referrals r ON (((rc.code)::text = (r.code)::text)))
     LEFT JOIN public.affiliate_commissions ac ON ((rc.user_id = ac.referrer_id)))
  GROUP BY rc.user_id, rc.code, rc.commission_rate_bps, rc.is_active, rc.activation_status, rc.activation_requested_at, rc.activation_approved_at;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    actor_user_id uuid,
    action character varying(100) NOT NULL,
    target_type character varying(50) NOT NULL,
    target_id uuid,
    payload_json jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: calendar_contest_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calendar_contest_history (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    calendar_entry_id uuid NOT NULL,
    contest_id uuid NOT NULL,
    scheduled_for timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE calendar_contest_history; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.calendar_contest_history IS 'History of contests created from calendar entries';


--
-- Name: contest_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contest_participants (
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    joined_at timestamp with time zone DEFAULT now() NOT NULL,
    qty_total bigint NOT NULL,
    qty_available bigint NOT NULL,
    total_score numeric(20,8) DEFAULT 0 NOT NULL,
    final_rank integer,
    final_prize_cents integer,
    is_system boolean DEFAULT false NOT NULL,
    CONSTRAINT chk_qty_available CHECK ((qty_available >= 0)),
    CONSTRAINT chk_qty_available_lte_total CHECK ((qty_available <= qty_total)),
    CONSTRAINT chk_qty_total CHECK ((qty_total >= 0))
);


--
-- Name: COLUMN contest_participants.total_score; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contest_participants.total_score IS 'Total score with 8 decimal places precision to prevent float accumulation errors';


--
-- Name: contests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contests (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    status public.contest_status DEFAULT 'draft'::public.contest_status NOT NULL,
    entry_fee_cents integer DEFAULT 0 NOT NULL,
    platform_fee_bps integer DEFAULT 2000 NOT NULL,
    qty_total bigint DEFAULT 100000 NOT NULL,
    rules_json jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    shard_id integer DEFAULT 0,
    is_free boolean DEFAULT false NOT NULL,
    max_participants integer,
    auto_repeat boolean DEFAULT false NOT NULL,
    repeat_interval interval,
    duration_type public.contest_duration_type DEFAULT 'hourly'::public.contest_duration_type NOT NULL,
    asset_class public.asset_class DEFAULT 'mixed'::public.asset_class NOT NULL,
    duration_minutes integer,
    min_participants integer DEFAULT 2 NOT NULL,
    registration_deadline timestamp with time zone,
    auto_start boolean DEFAULT false NOT NULL,
    template_id uuid,
    commission_rate numeric(5,2) DEFAULT 20.00 NOT NULL,
    published_at timestamp with time zone,
    started_at timestamp with time zone,
    ended_at timestamp with time zone,
    settled_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    cancellation_reason text,
    current_participants integer DEFAULT 0 NOT NULL,
    auto_generated boolean DEFAULT false NOT NULL,
    type public.contest_type DEFAULT 'standard'::public.contest_type,
    starting_reminder_sent_at timestamp with time zone,
    paused_at timestamp with time zone,
    total_paused_duration interval DEFAULT '00:00:00'::interval NOT NULL,
    prizes_locked_at timestamp with time zone,
    prize_pool_net_cents bigint,
    schedule_id uuid,
    commission_amount bigint DEFAULT 0 NOT NULL,
    market_close_time timestamp with time zone,
    registration_opens_at timestamp with time zone,
    tier_id uuid,
    economics_locked_at timestamp with time zone,
    locked_entry_fee_cents bigint,
    locked_platform_fee_bps integer,
    late_join_enabled boolean DEFAULT true NOT NULL,
    schedule_idempotency_key text,
    CONSTRAINT chk_auto_repeat_requires_interval CHECK (((auto_repeat = false) OR (repeat_interval IS NOT NULL))),
    CONSTRAINT chk_commission_rate_valid CHECK (((commission_rate >= (0)::numeric) AND (commission_rate <= 50.00))),
    CONSTRAINT chk_contest_dates CHECK ((ends_at > starts_at)),
    CONSTRAINT chk_current_participants_non_negative CHECK ((current_participants >= 0)),
    CONSTRAINT chk_duration_minutes_positive CHECK (((duration_minutes IS NULL) OR (duration_minutes > 0))),
    CONSTRAINT chk_entry_fee_positive CHECK ((entry_fee_cents >= 0)),
    CONSTRAINT chk_max_participants_positive CHECK (((max_participants IS NULL) OR (max_participants > 0))),
    CONSTRAINT chk_min_participants_positive CHECK ((min_participants >= 1)),
    CONSTRAINT chk_platform_fee_valid CHECK (((platform_fee_bps >= 0) AND (platform_fee_bps <= 10000))),
    CONSTRAINT chk_registration_deadline_valid CHECK (((registration_deadline IS NULL) OR (registration_deadline <= starts_at))),
    CONSTRAINT chk_registration_opens_at_valid CHECK (((registration_opens_at IS NULL) OR (registration_opens_at <= starts_at)))
);


--
-- Name: COLUMN contests.platform_fee_bps; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.platform_fee_bps IS 'Canonical platform fee in basis points (2000 = 20%). Sole runtime fee authority.';


--
-- Name: COLUMN contests.template_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.template_id IS 'FK to tournament_templates — null for manually created contests';


--
-- Name: COLUMN contests.commission_rate; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.commission_rate IS 'DEPRECATED. Legacy percent fee; ignored when platform_fee_bps > 0. Do not write new values.';


--
-- Name: COLUMN contests.published_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.published_at IS 'Timestamp when contest transitioned from draft to scheduled';


--
-- Name: COLUMN contests.started_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.started_at IS 'Timestamp when contest actually started (transitioned to running)';


--
-- Name: COLUMN contests.ended_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.ended_at IS 'Timestamp when trading period ended (transitioned to settling)';


--
-- Name: COLUMN contests.settled_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.settled_at IS 'Timestamp when settlement completed (transitioned to completed)';


--
-- Name: COLUMN contests.cancelled_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.cancelled_at IS 'Timestamp when contest was cancelled';


--
-- Name: COLUMN contests.cancellation_reason; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.cancellation_reason IS 'Reason for cancellation, displayed to users';


--
-- Name: COLUMN contests.current_participants; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.current_participants IS 'Denormalized participant count (no upper limit, maintained by trigger)';


--
-- Name: COLUMN contests.starting_reminder_sent_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.starting_reminder_sent_at IS 'Timestamp when the 15-minute starting reminder was sent to participants';


--
-- Name: COLUMN contests.paused_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.paused_at IS 'Timestamp when the contest was paused. NULL when not paused.';


--
-- Name: COLUMN contests.total_paused_duration; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.total_paused_duration IS 'Total accumulated duration the contest has been paused.';


--
-- Name: COLUMN contests.prize_pool_net_cents; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.prize_pool_net_cents IS 'Dynamically calculated prize pool (sum of entry fees minus commission)';


--
-- Name: COLUMN contests.schedule_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.schedule_id IS 'FK to tournament_schedules — null for manually created contests';


--
-- Name: COLUMN contests.commission_amount; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.commission_amount IS 'Actual commission collected in Rials (sum of entry fees * commission rate)';


--
-- Name: COLUMN contests.market_close_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.market_close_time IS 'For forex tournaments that end before daily market reset';


--
-- Name: COLUMN contests.economics_locked_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.economics_locked_at IS 'When set, entry fee and platform_fee_bps are immutable for this contest instance.';


--
-- Name: COLUMN contests.locked_entry_fee_cents; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.locked_entry_fee_cents IS 'Frozen entry fee used for settlement after economics lock.';


--
-- Name: COLUMN contests.locked_platform_fee_bps; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.locked_platform_fee_bps IS 'Frozen platform fee bps used for settlement after economics lock.';


--
-- Name: COLUMN contests.late_join_enabled; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contests.late_join_enabled IS 'When false, paid contests reject joins after start. Free contests never allow late join.';


--
-- Name: calendar_contests_mv; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.calendar_contests_mv AS
 SELECT id,
    name,
    type,
    asset_class,
    entry_fee_cents,
    duration_minutes,
    starts_at,
    ends_at,
    status,
    is_free,
    max_participants,
    commission_rate,
    date((starts_at AT TIME ZONE 'UTC'::text)) AS contest_date,
    ( SELECT count(*) AS count
           FROM public.contest_participants cp
          WHERE (cp.contest_id = c.id)) AS participant_count,
        CASE
            WHEN is_free THEN (0)::bigint
            WHEN (commission_rate > (0)::numeric) THEN ((round((((entry_fee_cents * ( SELECT count(*) AS count
               FROM public.contest_participants cp
              WHERE (cp.contest_id = c.id))))::numeric * ((1)::numeric - (commission_rate / (100)::numeric)))))::integer)::bigint
            ELSE (entry_fee_cents * ( SELECT count(*) AS count
               FROM public.contest_participants cp
              WHERE (cp.contest_id = c.id)))
        END AS prize_pool_cents
   FROM public.contests c
  WHERE ((status = ANY (ARRAY['scheduled'::public.contest_status, 'registration_open'::public.contest_status, 'running'::public.contest_status])) AND (starts_at >= (now() - '1 day'::interval)) AND (starts_at <= (now() + '30 days'::interval)))
  WITH NO DATA;


--
-- Name: MATERIALIZED VIEW calendar_contests_mv; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON MATERIALIZED VIEW public.calendar_contests_mv IS 'Pre-computed calendar data for fast access. Refresh with refresh_calendar_contests_mv()';


--
-- Name: calendar_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calendar_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_id uuid NOT NULL,
    recurrence_pattern public.recurrence_pattern NOT NULL,
    cron_expression character varying(100),
    start_date timestamp with time zone NOT NULL,
    end_date timestamp with time zone,
    timezone character varying(50) DEFAULT 'UTC'::character varying NOT NULL,
    registration_lead_time_minutes integer DEFAULT 60 NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    status public.calendar_status DEFAULT 'active'::public.calendar_status NOT NULL,
    last_run_at timestamp with time zone,
    next_run_at timestamp with time zone,
    created_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_cron_expression_required CHECK (((recurrence_pattern <> 'custom_cron'::public.recurrence_pattern) OR (cron_expression IS NOT NULL))),
    CONSTRAINT chk_end_date_after_start CHECK (((end_date IS NULL) OR (end_date > start_date))),
    CONSTRAINT chk_registration_lead_time_positive CHECK ((registration_lead_time_minutes >= 0))
);


--
-- Name: TABLE calendar_entries; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.calendar_entries IS 'Scheduled rules for automatic tournament creation from templates';


--
-- Name: COLUMN calendar_entries.recurrence_pattern; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.calendar_entries.recurrence_pattern IS 'Pattern for recurrence: daily, weekly, biweekly, monthly, or custom_cron';


--
-- Name: COLUMN calendar_entries.cron_expression; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.calendar_entries.cron_expression IS 'Custom cron expression when recurrence_pattern is custom_cron (e.g., "0 9 * * 1-5" for weekdays at 9am)';


--
-- Name: COLUMN calendar_entries.start_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.calendar_entries.start_date IS 'When this calendar entry becomes active';


--
-- Name: COLUMN calendar_entries.end_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.calendar_entries.end_date IS 'When this calendar entry expires (NULL for indefinite)';


--
-- Name: COLUMN calendar_entries.timezone; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.calendar_entries.timezone IS 'IANA timezone for scheduling (e.g., America/New_York, Europe/London)';


--
-- Name: COLUMN calendar_entries.registration_lead_time_minutes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.calendar_entries.registration_lead_time_minutes IS 'How many minutes before contest start to open registration';


--
-- Name: COLUMN calendar_entries.next_run_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.calendar_entries.next_run_at IS 'Pre-computed timestamp for the next scheduled contest creation';


--
-- Name: candles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.candles (
    symbol character varying(20) NOT NULL,
    resolution character varying(10) NOT NULL,
    "time" bigint NOT NULL,
    open double precision NOT NULL,
    high double precision NOT NULL,
    low double precision NOT NULL,
    close double precision NOT NULL,
    volume double precision DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE candles; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.candles IS 'OHLCV candles aggregated from market data ticks';


--
-- Name: COLUMN candles.symbol; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.candles.symbol IS 'Trading symbol (e.g., AAPL, GOOGL)';


--
-- Name: COLUMN candles.resolution; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.candles.resolution IS 'Candle resolution: 1m, 5m, 15m, 30m, 1h, 4h, 1d';


--
-- Name: COLUMN candles."time"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.candles."time" IS 'Unix timestamp in seconds (start of candle window)';


--
-- Name: COLUMN candles.volume; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.candles.volume IS 'Tick count or volume proxy';


--
-- Name: chart_drawings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chart_drawings (
    user_id uuid NOT NULL,
    contest_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    drawings jsonb DEFAULT '[]'::jsonb NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE chart_drawings; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.chart_drawings IS 'User chart drawings (trend lines, fib, etc.) per contest and symbol';


--
-- Name: contest_duration_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contest_duration_configs (
    duration_type public.contest_duration_type NOT NULL,
    duration_minutes integer NOT NULL,
    default_qty_total bigint NOT NULL,
    min_entry_fee_cents integer NOT NULL,
    max_entry_fee_cents integer NOT NULL,
    display_name_en character varying(50) NOT NULL,
    display_name_fa character varying(50) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_default_qty_total_positive CHECK ((default_qty_total > 0)),
    CONSTRAINT chk_duration_minutes_positive CHECK ((duration_minutes > 0)),
    CONSTRAINT chk_entry_fee_range CHECK ((max_entry_fee_cents >= min_entry_fee_cents)),
    CONSTRAINT chk_max_entry_fee_positive CHECK ((max_entry_fee_cents >= 0)),
    CONSTRAINT chk_min_entry_fee_positive CHECK ((min_entry_fee_cents >= 0))
);


--
-- Name: contest_finalization_state; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contest_finalization_state (
    contest_id uuid NOT NULL,
    finalization_started_at timestamp with time zone DEFAULT now() NOT NULL,
    payouts_calculated boolean DEFAULT false NOT NULL,
    payouts_calculated_at timestamp with time zone,
    ranks_written boolean DEFAULT false NOT NULL,
    ranks_written_at timestamp with time zone,
    wallets_credited boolean DEFAULT false NOT NULL,
    wallets_credited_at timestamp with time zone,
    status_updated boolean DEFAULT false NOT NULL,
    status_updated_at timestamp with time zone,
    finalization_completed_at timestamp with time zone,
    error_message text,
    last_error_at timestamp with time zone,
    retry_count integer DEFAULT 0 NOT NULL,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE contest_finalization_state; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.contest_finalization_state IS 'Tracks contest finalization progress for crash recovery. Each step is recorded
atomically so the worker can resume from the last successful step after a crash.';


--
-- Name: COLUMN contest_finalization_state.payouts_calculated; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contest_finalization_state.payouts_calculated IS 'True when prize distribution has been calculated (CalculateContestPayouts completed)';


--
-- Name: COLUMN contest_finalization_state.ranks_written; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contest_finalization_state.ranks_written IS 'True when final_rank and final_prize_cents have been written to contest_participants';


--
-- Name: COLUMN contest_finalization_state.wallets_credited; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contest_finalization_state.wallets_credited IS 'True when wallet credits have been processed for all winners';


--
-- Name: COLUMN contest_finalization_state.status_updated; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contest_finalization_state.status_updated IS 'True when contest status has been updated to completed';


--
-- Name: COLUMN contest_finalization_state.retry_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contest_finalization_state.retry_count IS 'Number of times finalization has been retried after errors';


--
-- Name: COLUMN contest_finalization_state.metadata; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contest_finalization_state.metadata IS 'JSON object containing payout summary, participant count, and other audit data';


--
-- Name: contest_prize_locks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contest_prize_locks (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    contest_id uuid NOT NULL,
    total_participants integer NOT NULL,
    prize_pool_gross_cents bigint NOT NULL,
    prize_pool_net_cents bigint NOT NULL,
    platform_fee_cents bigint NOT NULL,
    commission_rate numeric(5,2) NOT NULL,
    winners_count integer NOT NULL,
    distribution_json jsonb NOT NULL,
    locked_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: contest_reminders_sent; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contest_reminders_sent (
    contest_id uuid NOT NULL,
    reminder_type character varying(20) NOT NULL,
    sent_at timestamp with time zone DEFAULT now() NOT NULL,
    recipient_count integer DEFAULT 0 NOT NULL
);


--
-- Name: TABLE contest_reminders_sent; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.contest_reminders_sent IS 'Tracks which reminder intervals have been sent for each contest';


--
-- Name: COLUMN contest_reminders_sent.reminder_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contest_reminders_sent.reminder_type IS 'Reminder tier identifier (e.g. 24h, 1h, 15m)';


--
-- Name: COLUMN contest_reminders_sent.recipient_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contest_reminders_sent.recipient_count IS 'Number of participants who received the reminder';


--
-- Name: contest_settlements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contest_settlements (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    contest_id uuid NOT NULL,
    status public.settlement_status DEFAULT 'pending'::public.settlement_status NOT NULL,
    started_at timestamp with time zone,
    positions_closed_at timestamp with time zone,
    rankings_calculated_at timestamp with time zone,
    prizes_distributed_at timestamp with time zone,
    completed_at timestamp with time zone,
    total_participants integer DEFAULT 0 NOT NULL,
    total_positions_closed integer DEFAULT 0 NOT NULL,
    total_orders_cancelled integer DEFAULT 0 NOT NULL,
    total_winners integer DEFAULT 0 NOT NULL,
    prize_pool_gross_cents bigint DEFAULT 0 NOT NULL,
    prize_pool_net_cents bigint DEFAULT 0 NOT NULL,
    total_distributed_cents bigint DEFAULT 0 NOT NULL,
    platform_fee_cents bigint DEFAULT 0 NOT NULL,
    attempt_count integer DEFAULT 0 NOT NULL,
    last_error text,
    failed_at timestamp with time zone,
    snapshot_prices jsonb,
    snapshot_taken_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: contest_status_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contest_status_history (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    contest_id uuid NOT NULL,
    from_status public.contest_status,
    to_status public.contest_status NOT NULL,
    changed_by uuid,
    reason text,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE contest_status_history; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.contest_status_history IS 'Audit trail of all contest status transitions';


--
-- Name: COLUMN contest_status_history.changed_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contest_status_history.changed_by IS 'User who triggered the transition, NULL for automatic transitions';


--
-- Name: COLUMN contest_status_history.reason; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contest_status_history.reason IS 'Optional reason or context for the transition';


--
-- Name: COLUMN contest_status_history.metadata; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contest_status_history.metadata IS 'Additional context like participant count, configuration snapshot, etc.';


--
-- Name: contest_symbols; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contest_symbols (
    contest_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    provider_symbol_twelvedata character varying(50),
    provider_symbol_massive character varying(50),
    enabled boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: email_template_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_template_versions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    slug character varying(100) NOT NULL,
    version_name character varying(200) NOT NULL,
    html_body text NOT NULL,
    css_content text DEFAULT ''::text NOT NULL,
    font_config jsonb DEFAULT '{}'::jsonb NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    created_by uuid,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE email_template_versions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.email_template_versions IS 'Multiple template versions per email type. Max 5 per slug, only 1 active.';


--
-- Name: COLUMN email_template_versions.html_body; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.email_template_versions.html_body IS 'HTML body content without <style> tags — CSS is stored separately';


--
-- Name: COLUMN email_template_versions.css_content; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.email_template_versions.css_content IS 'CSS styles, will be injected into <style> tag when rendering';


--
-- Name: COLUMN email_template_versions.font_config; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.email_template_versions.font_config IS 'Per-language font config JSON: {"en": {"family": "Inter", "url": "..."}, "fa": {"family": "Vazirmatn", "url": "..."}}';


--
-- Name: COLUMN email_template_versions.is_active; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.email_template_versions.is_active IS 'Only one version per slug can be active. Enforced by partial unique index.';


--
-- Name: email_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_templates (
    slug character varying(100) NOT NULL,
    subject character varying(500),
    html_content text,
    description character varying(500),
    variables text,
    updated_by uuid,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE email_templates; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.email_templates IS 'Custom email template overrides for admin customization';


--
-- Name: COLUMN email_templates.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.email_templates.slug IS 'Template identifier matching the embedded template name';


--
-- Name: COLUMN email_templates.subject; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.email_templates.subject IS 'Optional custom subject line for the email';


--
-- Name: COLUMN email_templates.html_content; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.email_templates.html_content IS 'Custom HTML template content. NULL or empty means use embedded default.';


--
-- Name: COLUMN email_templates.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.email_templates.description IS 'Human-readable description of when this template is used';


--
-- Name: COLUMN email_templates.variables; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.email_templates.variables IS 'Comma-separated list of Go template variables available in this template';


--
-- Name: COLUMN email_templates.updated_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.email_templates.updated_by IS 'Last admin user who modified this template';


--
-- Name: email_verification_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_verification_tokens (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    token_hash character varying(255) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    used_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    failed_attempts integer DEFAULT 0 NOT NULL
);


--
-- Name: TABLE email_verification_tokens; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.email_verification_tokens IS 'Stores email verification tokens with one-time use and expiration';


--
-- Name: COLUMN email_verification_tokens.token_hash; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.email_verification_tokens.token_hash IS 'SHA-256 hash of the 6-digit verification code';


--
-- Name: COLUMN email_verification_tokens.expires_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.email_verification_tokens.expires_at IS 'Code expires 10 minutes after creation';


--
-- Name: COLUMN email_verification_tokens.used_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.email_verification_tokens.used_at IS 'Set when token is used to verify email (prevents reuse)';


--
-- Name: COLUMN email_verification_tokens.failed_attempts; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.email_verification_tokens.failed_attempts IS 'Number of failed verification attempts. Code invalidated after 5 failures.';


--
-- Name: fills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fills (
    fill_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    shard_id integer DEFAULT 0 NOT NULL,
    order_id uuid NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    side public.order_side NOT NULL,
    qty bigint NOT NULL,
    fill_price numeric(20,8) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    realized_pnl numeric(20,8) DEFAULT 0 NOT NULL,
    CONSTRAINT chk_fills_p_price_positive CHECK ((fill_price > (0)::numeric)),
    CONSTRAINT chk_fills_p_qty_positive CHECK ((qty > 0))
)
PARTITION BY LIST (shard_id);


--
-- Name: TABLE fills; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.fills IS 'Partitioned fills table by shard_id for horizontal scaling';


--
-- Name: fills_compat; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.fills_compat AS
 SELECT fill_id,
    order_id,
    contest_id,
    user_id,
    symbol,
    side,
    qty,
    fill_price,
    created_at
   FROM public.fills;


--
-- Name: VIEW fills_compat; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.fills_compat IS 'Backward-compatible view of fills without shard_id';


--
-- Name: fills_old; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fills_old (
    fill_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    order_id uuid NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    side public.order_side NOT NULL,
    qty bigint NOT NULL,
    fill_price numeric(20,8) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_fill_price_positive CHECK ((fill_price > (0)::numeric)),
    CONSTRAINT chk_fill_qty_positive CHECK ((qty > 0))
);


--
-- Name: fills_shard_0; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fills_shard_0 (
    fill_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    shard_id integer DEFAULT 0 NOT NULL,
    order_id uuid NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    side public.order_side NOT NULL,
    qty bigint NOT NULL,
    fill_price numeric(20,8) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    realized_pnl numeric(20,8) DEFAULT 0 NOT NULL,
    CONSTRAINT chk_fills_p_price_positive CHECK ((fill_price > (0)::numeric)),
    CONSTRAINT chk_fills_p_qty_positive CHECK ((qty > 0))
);


--
-- Name: fills_shard_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fills_shard_1 (
    fill_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    shard_id integer DEFAULT 0 NOT NULL,
    order_id uuid NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    side public.order_side NOT NULL,
    qty bigint NOT NULL,
    fill_price numeric(20,8) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    realized_pnl numeric(20,8) DEFAULT 0 NOT NULL,
    CONSTRAINT chk_fills_p_price_positive CHECK ((fill_price > (0)::numeric)),
    CONSTRAINT chk_fills_p_qty_positive CHECK ((qty > 0))
);


--
-- Name: fills_shard_2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fills_shard_2 (
    fill_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    shard_id integer DEFAULT 0 NOT NULL,
    order_id uuid NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    side public.order_side NOT NULL,
    qty bigint NOT NULL,
    fill_price numeric(20,8) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    realized_pnl numeric(20,8) DEFAULT 0 NOT NULL,
    CONSTRAINT chk_fills_p_price_positive CHECK ((fill_price > (0)::numeric)),
    CONSTRAINT chk_fills_p_qty_positive CHECK ((qty > 0))
);


--
-- Name: fills_shard_3; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fills_shard_3 (
    fill_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    shard_id integer DEFAULT 0 NOT NULL,
    order_id uuid NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    side public.order_side NOT NULL,
    qty bigint NOT NULL,
    fill_price numeric(20,8) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    realized_pnl numeric(20,8) DEFAULT 0 NOT NULL,
    CONSTRAINT chk_fills_p_price_positive CHECK ((fill_price > (0)::numeric)),
    CONSTRAINT chk_fills_p_qty_positive CHECK ((qty > 0))
);


--
-- Name: final_rankings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.final_rankings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    settlement_id uuid NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    rank integer NOT NULL,
    tied_with_count integer DEFAULT 0 NOT NULL,
    final_score numeric(20,4) NOT NULL,
    realized_score numeric(20,4) DEFAULT 0 NOT NULL,
    unrealized_score numeric(20,4) DEFAULT 0 NOT NULL,
    total_trades integer DEFAULT 0 NOT NULL,
    winning_trades integer DEFAULT 0 NOT NULL,
    total_positions integer DEFAULT 0 NOT NULL,
    tragge_point_contribution numeric(20,4) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    win_rate numeric(5,2) DEFAULT 0 NOT NULL
);


--
-- Name: kyc_audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.kyc_audit_log (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    action character varying(50) NOT NULL,
    actor_id uuid,
    details jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: kyc_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.kyc_documents (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    document_type public.kyc_document_type NOT NULL,
    document_number character varying(100),
    issuing_country character varying(2),
    issue_date date,
    expiry_date date,
    front_image_url text,
    back_image_url text,
    selfie_url text,
    status public.kyc_status DEFAULT 'pending'::public.kyc_status NOT NULL,
    reviewed_at timestamp with time zone,
    reviewed_by uuid,
    review_notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    selfie_with_doc_url text
);


--
-- Name: leaderboard_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leaderboard_snapshots (
    contest_id uuid NOT NULL,
    taken_at timestamp with time zone DEFAULT now() NOT NULL,
    payload_json jsonb NOT NULL
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    type character varying(50) NOT NULL,
    title character varying(255) NOT NULL,
    message text,
    metadata jsonb,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE notifications; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.notifications IS 'In-app notifications for users';


--
-- Name: COLUMN notifications.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.notifications.type IS 'Notification type (e.g., contest_starting, contest_completed, withdrawal_approved)';


--
-- Name: COLUMN notifications.metadata; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.notifications.metadata IS 'Additional data like contest_id, amounts, etc.';


--
-- Name: COLUMN notifications.read_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.notifications.read_at IS 'When the notification was read, NULL if unread';


--
-- Name: oauth_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_accounts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    provider public.oauth_provider NOT NULL,
    provider_user_id character varying(255) NOT NULL,
    email character varying(255),
    access_token text,
    refresh_token text,
    token_expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE oauth_accounts; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.oauth_accounts IS 'OAuth provider accounts linked to users for social login';


--
-- Name: COLUMN oauth_accounts.provider; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.oauth_accounts.provider IS 'OAuth provider: google, github, facebook, apple, discord';


--
-- Name: COLUMN oauth_accounts.provider_user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.oauth_accounts.provider_user_id IS 'Unique user ID from the OAuth provider';


--
-- Name: COLUMN oauth_accounts.email; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.oauth_accounts.email IS 'Email from OAuth provider (may differ from user email)';


--
-- Name: COLUMN oauth_accounts.access_token; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.oauth_accounts.access_token IS 'OAuth access token (encrypted at rest recommended)';


--
-- Name: COLUMN oauth_accounts.refresh_token; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.oauth_accounts.refresh_token IS 'OAuth refresh token for token renewal (encrypted at rest recommended)';


--
-- Name: COLUMN oauth_accounts.token_expires_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.oauth_accounts.token_expires_at IS 'When the access token expires';


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders (
    order_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    shard_id integer DEFAULT 0 NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    side public.order_side NOT NULL,
    type public.order_type NOT NULL,
    qty bigint NOT NULL,
    qty_filled bigint DEFAULT 0 NOT NULL,
    limit_price numeric(20,8),
    stop_price numeric(20,8),
    take_profit numeric(20,8),
    stop_loss numeric(20,8),
    status public.order_status DEFAULT 'pending'::public.order_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_limit_price_for_limit CHECK (((type <> ALL (ARRAY['limit'::public.order_type, 'stop_limit'::public.order_type, 'buy_limit'::public.order_type, 'sell_limit'::public.order_type])) OR ((limit_price IS NOT NULL) AND (limit_price > (0)::numeric)))),
    CONSTRAINT chk_orders_p_limit_price_for_limit CHECK (((type <> ALL (ARRAY['limit'::public.order_type, 'stop_limit'::public.order_type])) OR ((limit_price IS NOT NULL) AND (limit_price > (0)::numeric)))),
    CONSTRAINT chk_orders_p_qty_filled CHECK (((qty_filled >= 0) AND (qty_filled <= qty))),
    CONSTRAINT chk_orders_p_qty_positive CHECK ((qty > 0)),
    CONSTRAINT chk_orders_p_stop_price_for_stop CHECK (((type <> ALL (ARRAY['stop'::public.order_type, 'stop_limit'::public.order_type])) OR ((stop_price IS NOT NULL) AND (stop_price > (0)::numeric)))),
    CONSTRAINT chk_stop_price_for_stop CHECK (((type <> ALL (ARRAY['stop'::public.order_type, 'stop_limit'::public.order_type, 'buy_stop'::public.order_type, 'sell_stop'::public.order_type])) OR ((stop_price IS NOT NULL) AND (stop_price > (0)::numeric))))
)
PARTITION BY LIST (shard_id);


--
-- Name: TABLE orders; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.orders IS 'Partitioned orders table by shard_id for horizontal scaling';


--
-- Name: orders_compat; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.orders_compat AS
 SELECT order_id,
    contest_id,
    user_id,
    symbol,
    side,
    type,
    qty,
    qty_filled,
    limit_price,
    stop_price,
    take_profit,
    stop_loss,
    status,
    created_at,
    updated_at
   FROM public.orders;


--
-- Name: VIEW orders_compat; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.orders_compat IS 'Backward-compatible view of orders without shard_id';


--
-- Name: orders_old; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders_old (
    order_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    side public.order_side NOT NULL,
    type public.order_type NOT NULL,
    qty bigint NOT NULL,
    qty_filled bigint DEFAULT 0 NOT NULL,
    limit_price numeric(20,8),
    stop_price numeric(20,8),
    take_profit numeric(20,8),
    stop_loss numeric(20,8),
    status public.order_status DEFAULT 'pending'::public.order_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_limit_price_for_limit CHECK (((type <> ALL (ARRAY['limit'::public.order_type, 'stop_limit'::public.order_type])) OR ((limit_price IS NOT NULL) AND (limit_price > (0)::numeric)))),
    CONSTRAINT chk_order_qty_filled CHECK (((qty_filled >= 0) AND (qty_filled <= qty))),
    CONSTRAINT chk_order_qty_positive CHECK ((qty > 0)),
    CONSTRAINT chk_stop_price_for_stop CHECK (((type <> ALL (ARRAY['stop'::public.order_type, 'stop_limit'::public.order_type])) OR ((stop_price IS NOT NULL) AND (stop_price > (0)::numeric))))
);


--
-- Name: orders_shard_0; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders_shard_0 (
    order_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    shard_id integer DEFAULT 0 NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    side public.order_side NOT NULL,
    type public.order_type NOT NULL,
    qty bigint NOT NULL,
    qty_filled bigint DEFAULT 0 NOT NULL,
    limit_price numeric(20,8),
    stop_price numeric(20,8),
    take_profit numeric(20,8),
    stop_loss numeric(20,8),
    status public.order_status DEFAULT 'pending'::public.order_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_limit_price_for_limit CHECK (((type <> ALL (ARRAY['limit'::public.order_type, 'stop_limit'::public.order_type, 'buy_limit'::public.order_type, 'sell_limit'::public.order_type])) OR ((limit_price IS NOT NULL) AND (limit_price > (0)::numeric)))),
    CONSTRAINT chk_orders_p_limit_price_for_limit CHECK (((type <> ALL (ARRAY['limit'::public.order_type, 'stop_limit'::public.order_type])) OR ((limit_price IS NOT NULL) AND (limit_price > (0)::numeric)))),
    CONSTRAINT chk_orders_p_qty_filled CHECK (((qty_filled >= 0) AND (qty_filled <= qty))),
    CONSTRAINT chk_orders_p_qty_positive CHECK ((qty > 0)),
    CONSTRAINT chk_orders_p_stop_price_for_stop CHECK (((type <> ALL (ARRAY['stop'::public.order_type, 'stop_limit'::public.order_type])) OR ((stop_price IS NOT NULL) AND (stop_price > (0)::numeric)))),
    CONSTRAINT chk_stop_price_for_stop CHECK (((type <> ALL (ARRAY['stop'::public.order_type, 'stop_limit'::public.order_type, 'buy_stop'::public.order_type, 'sell_stop'::public.order_type])) OR ((stop_price IS NOT NULL) AND (stop_price > (0)::numeric))))
);


--
-- Name: orders_shard_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders_shard_1 (
    order_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    shard_id integer DEFAULT 0 NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    side public.order_side NOT NULL,
    type public.order_type NOT NULL,
    qty bigint NOT NULL,
    qty_filled bigint DEFAULT 0 NOT NULL,
    limit_price numeric(20,8),
    stop_price numeric(20,8),
    take_profit numeric(20,8),
    stop_loss numeric(20,8),
    status public.order_status DEFAULT 'pending'::public.order_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_limit_price_for_limit CHECK (((type <> ALL (ARRAY['limit'::public.order_type, 'stop_limit'::public.order_type, 'buy_limit'::public.order_type, 'sell_limit'::public.order_type])) OR ((limit_price IS NOT NULL) AND (limit_price > (0)::numeric)))),
    CONSTRAINT chk_orders_p_limit_price_for_limit CHECK (((type <> ALL (ARRAY['limit'::public.order_type, 'stop_limit'::public.order_type])) OR ((limit_price IS NOT NULL) AND (limit_price > (0)::numeric)))),
    CONSTRAINT chk_orders_p_qty_filled CHECK (((qty_filled >= 0) AND (qty_filled <= qty))),
    CONSTRAINT chk_orders_p_qty_positive CHECK ((qty > 0)),
    CONSTRAINT chk_orders_p_stop_price_for_stop CHECK (((type <> ALL (ARRAY['stop'::public.order_type, 'stop_limit'::public.order_type])) OR ((stop_price IS NOT NULL) AND (stop_price > (0)::numeric)))),
    CONSTRAINT chk_stop_price_for_stop CHECK (((type <> ALL (ARRAY['stop'::public.order_type, 'stop_limit'::public.order_type, 'buy_stop'::public.order_type, 'sell_stop'::public.order_type])) OR ((stop_price IS NOT NULL) AND (stop_price > (0)::numeric))))
);


--
-- Name: orders_shard_2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders_shard_2 (
    order_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    shard_id integer DEFAULT 0 NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    side public.order_side NOT NULL,
    type public.order_type NOT NULL,
    qty bigint NOT NULL,
    qty_filled bigint DEFAULT 0 NOT NULL,
    limit_price numeric(20,8),
    stop_price numeric(20,8),
    take_profit numeric(20,8),
    stop_loss numeric(20,8),
    status public.order_status DEFAULT 'pending'::public.order_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_limit_price_for_limit CHECK (((type <> ALL (ARRAY['limit'::public.order_type, 'stop_limit'::public.order_type, 'buy_limit'::public.order_type, 'sell_limit'::public.order_type])) OR ((limit_price IS NOT NULL) AND (limit_price > (0)::numeric)))),
    CONSTRAINT chk_orders_p_limit_price_for_limit CHECK (((type <> ALL (ARRAY['limit'::public.order_type, 'stop_limit'::public.order_type])) OR ((limit_price IS NOT NULL) AND (limit_price > (0)::numeric)))),
    CONSTRAINT chk_orders_p_qty_filled CHECK (((qty_filled >= 0) AND (qty_filled <= qty))),
    CONSTRAINT chk_orders_p_qty_positive CHECK ((qty > 0)),
    CONSTRAINT chk_orders_p_stop_price_for_stop CHECK (((type <> ALL (ARRAY['stop'::public.order_type, 'stop_limit'::public.order_type])) OR ((stop_price IS NOT NULL) AND (stop_price > (0)::numeric)))),
    CONSTRAINT chk_stop_price_for_stop CHECK (((type <> ALL (ARRAY['stop'::public.order_type, 'stop_limit'::public.order_type, 'buy_stop'::public.order_type, 'sell_stop'::public.order_type])) OR ((stop_price IS NOT NULL) AND (stop_price > (0)::numeric))))
);


--
-- Name: orders_shard_3; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders_shard_3 (
    order_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    shard_id integer DEFAULT 0 NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    side public.order_side NOT NULL,
    type public.order_type NOT NULL,
    qty bigint NOT NULL,
    qty_filled bigint DEFAULT 0 NOT NULL,
    limit_price numeric(20,8),
    stop_price numeric(20,8),
    take_profit numeric(20,8),
    stop_loss numeric(20,8),
    status public.order_status DEFAULT 'pending'::public.order_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_limit_price_for_limit CHECK (((type <> ALL (ARRAY['limit'::public.order_type, 'stop_limit'::public.order_type, 'buy_limit'::public.order_type, 'sell_limit'::public.order_type])) OR ((limit_price IS NOT NULL) AND (limit_price > (0)::numeric)))),
    CONSTRAINT chk_orders_p_limit_price_for_limit CHECK (((type <> ALL (ARRAY['limit'::public.order_type, 'stop_limit'::public.order_type])) OR ((limit_price IS NOT NULL) AND (limit_price > (0)::numeric)))),
    CONSTRAINT chk_orders_p_qty_filled CHECK (((qty_filled >= 0) AND (qty_filled <= qty))),
    CONSTRAINT chk_orders_p_qty_positive CHECK ((qty > 0)),
    CONSTRAINT chk_orders_p_stop_price_for_stop CHECK (((type <> ALL (ARRAY['stop'::public.order_type, 'stop_limit'::public.order_type])) OR ((stop_price IS NOT NULL) AND (stop_price > (0)::numeric)))),
    CONSTRAINT chk_stop_price_for_stop CHECK (((type <> ALL (ARRAY['stop'::public.order_type, 'stop_limit'::public.order_type, 'buy_stop'::public.order_type, 'sell_stop'::public.order_type])) OR ((stop_price IS NOT NULL) AND (stop_price > (0)::numeric))))
);


--
-- Name: otp_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.otp_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    phone character varying(20) NOT NULL,
    sent_at timestamp with time zone DEFAULT now() NOT NULL,
    verified_at timestamp with time zone,
    ip_address character varying(45),
    user_agent text
);


--
-- Name: positions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.positions (
    position_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    shard_id integer DEFAULT 0 NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    side public.position_side NOT NULL,
    qty_open bigint DEFAULT 0 NOT NULL,
    entry_price numeric(20,8) NOT NULL,
    qty_used bigint DEFAULT 0 NOT NULL,
    realized_score numeric(20,8) DEFAULT 0 NOT NULL,
    opened_at timestamp with time zone DEFAULT now() NOT NULL,
    closed_at timestamp with time zone,
    take_profit numeric(20,8),
    stop_loss numeric(20,8),
    CONSTRAINT chk_positions_p_entry_price CHECK ((entry_price > (0)::numeric)),
    CONSTRAINT chk_positions_p_qty_open CHECK ((qty_open >= 0)),
    CONSTRAINT chk_positions_p_qty_used CHECK ((qty_used >= 0))
)
PARTITION BY LIST (shard_id);


--
-- Name: TABLE positions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.positions IS 'Partitioned positions table by shard_id for horizontal scaling';


--
-- Name: COLUMN positions.realized_score; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.positions.realized_score IS 'Realized score with 8 decimal places precision to prevent float accumulation errors';


--
-- Name: partition_stats; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.partition_stats AS
 SELECT 'orders'::text AS table_name,
    child.relname AS partition_name,
    pg_relation_size((child.oid)::regclass) AS size_bytes,
    pg_size_pretty(pg_relation_size((child.oid)::regclass)) AS size_pretty,
    ( SELECT count(*) AS count
           FROM public.orders
          WHERE (orders.shard_id = ("substring"((child.relname)::text, 'shard_(\d+)'::text))::integer)) AS row_count
   FROM ((pg_inherits
     JOIN pg_class parent ON ((pg_inherits.inhparent = parent.oid)))
     JOIN pg_class child ON ((pg_inherits.inhrelid = child.oid)))
  WHERE (parent.relname = 'orders'::name)
UNION ALL
 SELECT 'fills'::text AS table_name,
    child.relname AS partition_name,
    pg_relation_size((child.oid)::regclass) AS size_bytes,
    pg_size_pretty(pg_relation_size((child.oid)::regclass)) AS size_pretty,
    ( SELECT count(*) AS count
           FROM public.fills
          WHERE (fills.shard_id = ("substring"((child.relname)::text, 'shard_(\d+)'::text))::integer)) AS row_count
   FROM ((pg_inherits
     JOIN pg_class parent ON ((pg_inherits.inhparent = parent.oid)))
     JOIN pg_class child ON ((pg_inherits.inhrelid = child.oid)))
  WHERE (parent.relname = 'fills'::name)
UNION ALL
 SELECT 'positions'::text AS table_name,
    child.relname AS partition_name,
    pg_relation_size((child.oid)::regclass) AS size_bytes,
    pg_size_pretty(pg_relation_size((child.oid)::regclass)) AS size_pretty,
    ( SELECT count(*) AS count
           FROM public.positions
          WHERE (positions.shard_id = ("substring"((child.relname)::text, 'shard_(\d+)'::text))::integer)) AS row_count
   FROM ((pg_inherits
     JOIN pg_class parent ON ((pg_inherits.inhparent = parent.oid)))
     JOIN pg_class child ON ((pg_inherits.inhrelid = child.oid)))
  WHERE (parent.relname = 'positions'::name);


--
-- Name: VIEW partition_stats; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.partition_stats IS 'Shows size and row count statistics for each partition';


--
-- Name: password_reset_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.password_reset_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    code_hash character varying(64) NOT NULL,
    channel character varying(10) NOT NULL,
    destination character varying(255) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    used_at timestamp with time zone,
    attempts integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT password_reset_codes_channel_check CHECK (((channel)::text = ANY ((ARRAY['sms'::character varying, 'email'::character varying])::text[])))
);


--
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.password_reset_tokens (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    token_hash character varying(255) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    used_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE password_reset_tokens; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.password_reset_tokens IS 'Stores password reset tokens with one-time use and expiration';


--
-- Name: COLUMN password_reset_tokens.token_hash; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.password_reset_tokens.token_hash IS 'SHA-256 hash of the reset token (raw token is sent to user)';


--
-- Name: COLUMN password_reset_tokens.expires_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.password_reset_tokens.expires_at IS 'Token expires 1 hour after creation';


--
-- Name: COLUMN password_reset_tokens.used_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.password_reset_tokens.used_at IS 'Set when token is used to reset password (prevents reuse)';


--
-- Name: payment_intents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_intents (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    provider character varying(50) NOT NULL,
    provider_payment_id character varying(255),
    amount_cents bigint NOT NULL,
    currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
    status public.payment_intent_status DEFAULT 'pending'::public.payment_intent_status NOT NULL,
    metadata_json jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone,
    CONSTRAINT chk_payment_amount_positive CHECK ((amount_cents > 0))
);


--
-- Name: payouts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payouts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    amount_cents bigint NOT NULL,
    currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
    status public.payout_status DEFAULT 'pending'::public.payout_status NOT NULL,
    provider character varying(50),
    provider_payout_id character varying(255),
    destination_type character varying(50),
    destination_info_json jsonb,
    metadata_json jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone,
    admin_comment text,
    reviewed_by uuid,
    reviewed_at timestamp with time zone,
    idempotency_key character varying(255),
    transaction_id character varying(255),
    CONSTRAINT chk_payout_amount_positive CHECK ((amount_cents > 0))
);


--
-- Name: COLUMN payouts.admin_comment; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.payouts.admin_comment IS 'Admin notes or reason for approval/rejection';


--
-- Name: COLUMN payouts.reviewed_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.payouts.reviewed_by IS 'UUID of the admin who reviewed the withdrawal';


--
-- Name: COLUMN payouts.reviewed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.payouts.reviewed_at IS 'Timestamp when the withdrawal was reviewed';


--
-- Name: COLUMN payouts.idempotency_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.payouts.idempotency_key IS 'Client/server idempotency key for withdrawal create';


--
-- Name: COLUMN payouts.transaction_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.payouts.transaction_id IS 'Admin-recorded manual payout reference / crypto tx hash';


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permissions (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description character varying(255),
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE permissions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.permissions IS 'Granular permissions for admin panel access control';


--
-- Name: COLUMN permissions.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.permissions.name IS 'Permission identifier in format: resource.action (e.g., users.view)';


--
-- Name: COLUMN permissions.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.permissions.description IS 'Human-readable description of what the permission grants';


--
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.permissions_id_seq OWNED BY public.permissions.id;


--
-- Name: positions_compat; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.positions_compat AS
 SELECT position_id,
    contest_id,
    user_id,
    symbol,
    side,
    qty_open,
    entry_price,
    qty_used,
    realized_score,
    opened_at,
    closed_at
   FROM public.positions;


--
-- Name: positions_old; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.positions_old (
    position_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    side public.position_side NOT NULL,
    qty_open bigint DEFAULT 0 NOT NULL,
    entry_price numeric(20,8) NOT NULL,
    qty_used bigint DEFAULT 0 NOT NULL,
    realized_score numeric(20,4) DEFAULT 0 NOT NULL,
    opened_at timestamp with time zone DEFAULT now() NOT NULL,
    closed_at timestamp with time zone,
    CONSTRAINT chk_position_entry_price CHECK ((entry_price > (0)::numeric)),
    CONSTRAINT chk_position_qty_open CHECK ((qty_open >= 0)),
    CONSTRAINT chk_position_qty_used CHECK ((qty_used >= 0))
);


--
-- Name: positions_shard_0; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.positions_shard_0 (
    position_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    shard_id integer DEFAULT 0 NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    side public.position_side NOT NULL,
    qty_open bigint DEFAULT 0 NOT NULL,
    entry_price numeric(20,8) NOT NULL,
    qty_used bigint DEFAULT 0 NOT NULL,
    realized_score numeric(20,8) DEFAULT 0 NOT NULL,
    opened_at timestamp with time zone DEFAULT now() NOT NULL,
    closed_at timestamp with time zone,
    take_profit numeric(20,8),
    stop_loss numeric(20,8),
    CONSTRAINT chk_positions_p_entry_price CHECK ((entry_price > (0)::numeric)),
    CONSTRAINT chk_positions_p_qty_open CHECK ((qty_open >= 0)),
    CONSTRAINT chk_positions_p_qty_used CHECK ((qty_used >= 0))
);


--
-- Name: positions_shard_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.positions_shard_1 (
    position_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    shard_id integer DEFAULT 0 NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    side public.position_side NOT NULL,
    qty_open bigint DEFAULT 0 NOT NULL,
    entry_price numeric(20,8) NOT NULL,
    qty_used bigint DEFAULT 0 NOT NULL,
    realized_score numeric(20,8) DEFAULT 0 NOT NULL,
    opened_at timestamp with time zone DEFAULT now() NOT NULL,
    closed_at timestamp with time zone,
    take_profit numeric(20,8),
    stop_loss numeric(20,8),
    CONSTRAINT chk_positions_p_entry_price CHECK ((entry_price > (0)::numeric)),
    CONSTRAINT chk_positions_p_qty_open CHECK ((qty_open >= 0)),
    CONSTRAINT chk_positions_p_qty_used CHECK ((qty_used >= 0))
);


--
-- Name: positions_shard_2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.positions_shard_2 (
    position_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    shard_id integer DEFAULT 0 NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    side public.position_side NOT NULL,
    qty_open bigint DEFAULT 0 NOT NULL,
    entry_price numeric(20,8) NOT NULL,
    qty_used bigint DEFAULT 0 NOT NULL,
    realized_score numeric(20,8) DEFAULT 0 NOT NULL,
    opened_at timestamp with time zone DEFAULT now() NOT NULL,
    closed_at timestamp with time zone,
    take_profit numeric(20,8),
    stop_loss numeric(20,8),
    CONSTRAINT chk_positions_p_entry_price CHECK ((entry_price > (0)::numeric)),
    CONSTRAINT chk_positions_p_qty_open CHECK ((qty_open >= 0)),
    CONSTRAINT chk_positions_p_qty_used CHECK ((qty_used >= 0))
);


--
-- Name: positions_shard_3; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.positions_shard_3 (
    position_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    shard_id integer DEFAULT 0 NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    symbol character varying(20) NOT NULL,
    side public.position_side NOT NULL,
    qty_open bigint DEFAULT 0 NOT NULL,
    entry_price numeric(20,8) NOT NULL,
    qty_used bigint DEFAULT 0 NOT NULL,
    realized_score numeric(20,8) DEFAULT 0 NOT NULL,
    opened_at timestamp with time zone DEFAULT now() NOT NULL,
    closed_at timestamp with time zone,
    take_profit numeric(20,8),
    stop_loss numeric(20,8),
    CONSTRAINT chk_positions_p_entry_price CHECK ((entry_price > (0)::numeric)),
    CONSTRAINT chk_positions_p_qty_open CHECK ((qty_open >= 0)),
    CONSTRAINT chk_positions_p_qty_used CHECK ((qty_used >= 0))
);


--
-- Name: predefined_avatars; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.predefined_avatars (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    slug character varying(50) NOT NULL,
    display_name character varying(100) NOT NULL,
    category character varying(20) DEFAULT 'animal'::character varying NOT NULL,
    bg_color character varying(7) DEFAULT '#2a2a3a'::character varying NOT NULL,
    image_path character varying(500) NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT predefined_avatars_category_check CHECK (((category)::text = ANY ((ARRAY['animal'::character varying, 'character'::character varying, 'special'::character varying])::text[])))
);


--
-- Name: privilege_audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.privilege_audit_log (
    id integer NOT NULL,
    event_time timestamp with time zone DEFAULT now() NOT NULL,
    username text NOT NULL,
    action text NOT NULL,
    details jsonb
);


--
-- Name: privilege_audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.privilege_audit_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: privilege_audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.privilege_audit_log_id_seq OWNED BY public.privilege_audit_log.id;


--
-- Name: prize_distributions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prize_distributions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    settlement_id uuid NOT NULL,
    contest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    rank integer NOT NULL,
    final_score numeric(20,4) NOT NULL,
    prize_amount_cents bigint NOT NULL,
    prize_percentage numeric(10,6) NOT NULL,
    status public.prize_status DEFAULT 'pending'::public.prize_status NOT NULL,
    credited_at timestamp with time zone,
    error_message text,
    ledger_entry_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: provider_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.provider_config (
    asset_class character varying(20) NOT NULL,
    active_provider character varying(30) DEFAULT 'nobitex'::character varying NOT NULL,
    fallback_provider character varying(30),
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid
);


--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_permissions (
    role_id integer NOT NULL,
    permission_id integer NOT NULL,
    granted_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE role_permissions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.role_permissions IS 'Junction table linking roles to their granted permissions';


--
-- Name: COLUMN role_permissions.granted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.role_permissions.granted_at IS 'Timestamp when the permission was granted to the role';


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    name character varying(50) NOT NULL
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    dirty boolean NOT NULL
);


--
-- Name: security_audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.security_audit_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    event_type character varying(50) NOT NULL,
    ip_address inet,
    user_agent text,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: settlement_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settlement_events (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    settlement_id uuid NOT NULL,
    contest_id uuid NOT NULL,
    event_type character varying(50) NOT NULL,
    event_data jsonb,
    error_message text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: shard_assignment_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shard_assignment_log (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    contest_id uuid NOT NULL,
    old_shard_id integer,
    new_shard_id integer NOT NULL,
    reason character varying(255),
    assigned_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: shard_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shard_config (
    shard_id integer NOT NULL,
    name character varying(50) NOT NULL,
    status public.shard_status DEFAULT 'active'::public.shard_status NOT NULL,
    weight integer DEFAULT 100 NOT NULL,
    kafka_partition integer NOT NULL,
    address character varying(255),
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_kafka_partition_positive CHECK ((kafka_partition >= 0)),
    CONSTRAINT chk_shard_weight_positive CHECK (((weight >= 0) AND (weight <= 1000)))
);


--
-- Name: shard_distribution; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.shard_distribution AS
 SELECT s.shard_id,
    s.name AS shard_name,
    s.status,
    s.weight,
    COALESCE(c.contest_count, (0)::bigint) AS contest_count,
    COALESCE(o.order_count, (0)::bigint) AS order_count,
    COALESCE(f.fill_count, (0)::bigint) AS fill_count,
    COALESCE(p.position_count, (0)::bigint) AS position_count
   FROM ((((public.shard_config s
     LEFT JOIN ( SELECT contests.shard_id,
            count(*) AS contest_count
           FROM public.contests
          GROUP BY contests.shard_id) c ON ((s.shard_id = c.shard_id)))
     LEFT JOIN ( SELECT orders.shard_id,
            count(*) AS order_count
           FROM public.orders
          GROUP BY orders.shard_id) o ON ((s.shard_id = o.shard_id)))
     LEFT JOIN ( SELECT fills.shard_id,
            count(*) AS fill_count
           FROM public.fills
          GROUP BY fills.shard_id) f ON ((s.shard_id = f.shard_id)))
     LEFT JOIN ( SELECT positions.shard_id,
            count(*) AS position_count
           FROM public.positions
          GROUP BY positions.shard_id) p ON ((s.shard_id = p.shard_id)))
  ORDER BY s.shard_id;


--
-- Name: VIEW shard_distribution; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.shard_distribution IS 'Shows data distribution across shards';


--
-- Name: support_tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.support_tickets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    subject character varying(200) NOT NULL,
    category public.ticket_category DEFAULT 'other'::public.ticket_category NOT NULL,
    status public.ticket_status DEFAULT 'open'::public.ticket_status NOT NULL,
    priority public.ticket_priority DEFAULT 'medium'::public.ticket_priority NOT NULL,
    assigned_admin_id uuid,
    closed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: symbols; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.symbols (
    symbol character varying(20) NOT NULL,
    name character varying(100) NOT NULL,
    asset_type public.asset_type NOT NULL,
    provider_symbol_twelvedata character varying(50),
    provider_symbol_massive character varying(50),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    provider_symbol_nobitex character varying(50),
    provider_symbol_binance character varying(50),
    sort_order integer DEFAULT 999 NOT NULL,
    provider_symbol_finnhub character varying(50)
);


--
-- Name: TABLE symbols; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.symbols IS 'Master table of tradable symbols/assets that can be assigned to contests';


--
-- Name: COLUMN symbols.symbol; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.symbols.symbol IS 'Unique symbol identifier (e.g., AAPL, BTC/USD)';


--
-- Name: COLUMN symbols.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.symbols.name IS 'Human-readable name of the asset';


--
-- Name: COLUMN symbols.asset_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.symbols.asset_type IS 'Type of asset: stock, crypto, forex, or commodity';


--
-- Name: COLUMN symbols.provider_symbol_twelvedata; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.symbols.provider_symbol_twelvedata IS 'Symbol mapping for TwelveData provider';


--
-- Name: COLUMN symbols.provider_symbol_massive; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.symbols.provider_symbol_massive IS 'Symbol mapping for Massive provider';


--
-- Name: COLUMN symbols.is_active; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.symbols.is_active IS 'Whether the symbol is available for use in contests';


--
-- Name: template_entry_tiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.template_entry_tiers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    template_id uuid NOT NULL,
    entry_fee bigint DEFAULT 0 NOT NULL,
    label character varying(100),
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    is_free boolean DEFAULT false NOT NULL,
    qty_total_override bigint,
    max_participants_override integer,
    commission_rate_override numeric(5,2),
    has_prize_override boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_tier_entry_fee_non_negative CHECK ((entry_fee >= 0)),
    CONSTRAINT chk_tier_free_zero_fee CHECK (((is_free = false) OR (entry_fee = 0))),
    CONSTRAINT chk_tier_sort_order CHECK ((sort_order >= 0))
);


--
-- Name: template_prize_distributions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.template_prize_distributions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    template_id uuid NOT NULL,
    rank integer NOT NULL,
    percentage numeric(5,2) NOT NULL,
    min_participants integer DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_prize_min_participants_positive CHECK ((min_participants >= 1)),
    CONSTRAINT chk_prize_percentage_valid CHECK (((percentage > (0)::numeric) AND (percentage <= (100)::numeric))),
    CONSTRAINT chk_prize_rank_positive CHECK ((rank > 0))
);


--
-- Name: TABLE template_prize_distributions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.template_prize_distributions IS 'Defines how a tournament template''s prize pool is split among winners. Percentages for a given template should sum to 100% — enforced at the application layer.';


--
-- Name: COLUMN template_prize_distributions.rank; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.template_prize_distributions.rank IS 'Winner rank: 1 for 1st place, 2 for 2nd place, etc.';


--
-- Name: COLUMN template_prize_distributions.percentage; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.template_prize_distributions.percentage IS 'Percentage of prize pool allocated to this rank, e.g. 50.00 for 50%';


--
-- Name: COLUMN template_prize_distributions.min_participants; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.template_prize_distributions.min_participants IS 'Minimum number of participants required for this rank to be paid out';


--
-- Name: ticket_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ticket_attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    message_id uuid NOT NULL,
    file_name character varying(255) NOT NULL,
    file_size bigint NOT NULL,
    content_type character varying(100) NOT NULL,
    storage_key character varying(500) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: ticket_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ticket_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_id uuid NOT NULL,
    sender_id uuid NOT NULL,
    is_admin boolean DEFAULT false NOT NULL,
    body text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: tier_prize_distributions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tier_prize_distributions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tier_id uuid NOT NULL,
    rank integer NOT NULL,
    percentage numeric(5,2) NOT NULL,
    min_participants integer DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_tier_prize_min_participants_positive CHECK ((min_participants >= 1)),
    CONSTRAINT chk_tier_prize_percentage_valid CHECK (((percentage > (0)::numeric) AND (percentage <= (100)::numeric))),
    CONSTRAINT chk_tier_prize_rank_positive CHECK ((rank > 0))
);


--
-- Name: tournament_schedules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tournament_schedules (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    template_id uuid NOT NULL,
    cron_expression character varying(100) NOT NULL,
    start_time_utc time without time zone,
    active_days integer[],
    weekend_behavior public.weekend_behavior DEFAULT 'normal'::public.weekend_behavior NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE tournament_schedules; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.tournament_schedules IS 'Defines when tournaments are automatically created from templates';


--
-- Name: COLUMN tournament_schedules.cron_expression; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tournament_schedules.cron_expression IS 'Cron expression for recurrence, e.g. "*/10 * * * *" for every 10 minutes';


--
-- Name: COLUMN tournament_schedules.start_time_utc; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tournament_schedules.start_time_utc IS 'Base start time in UTC, nullable for cron-only schedules';


--
-- Name: COLUMN tournament_schedules.active_days; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tournament_schedules.active_days IS 'Array of weekday numbers using Iranian week: 0=Saturday, 1=Sunday, ..., 4=Wednesday, 5=Thursday, 6=Friday';


--
-- Name: COLUMN tournament_schedules.weekend_behavior; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tournament_schedules.weekend_behavior IS 'How to handle tournament creation on weekends: crypto_only, skip, or normal';


--
-- Name: tournament_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tournament_templates (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    duration_minutes integer NOT NULL,
    is_free boolean DEFAULT false NOT NULL,
    entry_fee_cents integer DEFAULT 0 NOT NULL,
    qty_total bigint DEFAULT 100000 NOT NULL,
    symbols_json jsonb NOT NULL,
    prize_distribution_json jsonb,
    max_participants integer,
    auto_create boolean DEFAULT false NOT NULL,
    create_cron character varying(50),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    asset_class public.asset_class DEFAULT 'mixed'::public.asset_class NOT NULL,
    commission_rate numeric(5,2) DEFAULT 0.20 NOT NULL,
    min_participants integer DEFAULT 2 NOT NULL,
    auto_start boolean DEFAULT false NOT NULL,
    template_key character varying(50),
    recurrence_rule text,
    next_occurrence_at timestamp with time zone,
    last_generated_at timestamp with time zone,
    type public.contest_type DEFAULT 'standard'::public.contest_type,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    market_type public.market_type,
    template_duration_type public.template_duration_type,
    entry_fee bigint DEFAULT 0 NOT NULL,
    has_prize boolean DEFAULT true NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_template_auto_create_requires_cron CHECK (((auto_create = false) OR (create_cron IS NOT NULL))),
    CONSTRAINT chk_template_commission_rate_valid CHECK (((commission_rate >= (0)::numeric) AND (commission_rate <= 50.00))),
    CONSTRAINT chk_template_duration_positive CHECK ((duration_minutes > 0)),
    CONSTRAINT chk_template_entry_fee_non_negative CHECK ((entry_fee >= 0)),
    CONSTRAINT chk_template_entry_fee_positive CHECK ((entry_fee_cents >= 0)),
    CONSTRAINT chk_template_free_no_fee CHECK (((is_free = false) OR (entry_fee_cents = 0))),
    CONSTRAINT chk_template_max_participants_positive CHECK (((max_participants IS NULL) OR (max_participants > 0))),
    CONSTRAINT chk_template_min_participants_positive CHECK ((min_participants >= 1)),
    CONSTRAINT chk_template_qty_positive CHECK ((qty_total > 0))
);


--
-- Name: COLUMN tournament_templates.recurrence_rule; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tournament_templates.recurrence_rule IS 'Recurrence pattern: HOURLY, DAILY@HH:MM, WEEKLY@DAY1,DAY2@HH:MM, MONTHLY@DD@HH:MM';


--
-- Name: COLUMN tournament_templates.next_occurrence_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tournament_templates.next_occurrence_at IS 'When the next contest should be created from this template';


--
-- Name: COLUMN tournament_templates.last_generated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tournament_templates.last_generated_at IS 'When the last contest was created from this template';


--
-- Name: COLUMN tournament_templates.market_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tournament_templates.market_type IS 'Target market type: crypto or forex';


--
-- Name: COLUMN tournament_templates.template_duration_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tournament_templates.template_duration_type IS 'Duration category: quick_30m, free_1h, four_hour, daily, weekly, special';


--
-- Name: COLUMN tournament_templates.entry_fee; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tournament_templates.entry_fee IS 'Entry fee in Rials (0 for free tournaments)';


--
-- Name: COLUMN tournament_templates.has_prize; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tournament_templates.has_prize IS 'Whether this template awards prizes to winners';


--
-- Name: COLUMN tournament_templates.is_active; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tournament_templates.is_active IS 'Whether this template is active and available for scheduling';


--
-- Name: tournaments_archive; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tournaments_archive (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    status public.contest_status NOT NULL,
    entry_fee_cents integer DEFAULT 0,
    platform_fee_bps integer DEFAULT 0,
    qty_total bigint DEFAULT 100000,
    rules_json jsonb,
    created_at timestamp with time zone DEFAULT now(),
    published_at timestamp with time zone,
    started_at timestamp with time zone,
    ended_at timestamp with time zone,
    settled_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    cancellation_reason text,
    current_participants integer DEFAULT 0,
    min_participants integer DEFAULT 2,
    max_participants integer,
    registration_deadline timestamp with time zone,
    registration_opens_at timestamp with time zone,
    auto_start boolean DEFAULT false,
    commission_rate numeric DEFAULT 0,
    paused_at timestamp with time zone,
    total_paused_duration interval DEFAULT '00:00:00'::interval,
    archived_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: user_notification_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_notification_preferences (
    user_id uuid NOT NULL,
    category character varying(30) NOT NULL,
    channel character varying(10) NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE user_notification_preferences; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.user_notification_preferences IS 'Per-user notification preferences. Missing row = default enabled.';


--
-- Name: COLUMN user_notification_preferences.category; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_notification_preferences.category IS 'Notification category: contest_reminders, contest_results, contest_activity, transactions, account';


--
-- Name: COLUMN user_notification_preferences.channel; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_notification_preferences.channel IS 'Delivery channel: in_app, email';


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_roles (
    user_id uuid NOT NULL,
    role_id integer NOT NULL,
    assigned_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: user_score_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_score_history (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    contest_id uuid NOT NULL,
    rank integer NOT NULL,
    score numeric(20,8) NOT NULL,
    participants integer NOT NULL,
    pnl numeric(20,2) DEFAULT 0 NOT NULL,
    trades_count integer DEFAULT 0 NOT NULL,
    avg_trade_duration_seconds integer DEFAULT 0 NOT NULL,
    top_symbol character varying(20),
    top_symbol_pnl numeric(20,2) DEFAULT 0,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    score_contribution numeric(20,8) DEFAULT 0 NOT NULL,
    CONSTRAINT chk_participants_positive CHECK ((participants > 0)),
    CONSTRAINT chk_rank_positive CHECK ((rank > 0))
);


--
-- Name: user_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_stats (
    user_id uuid NOT NULL,
    total_contests integer DEFAULT 0 NOT NULL,
    total_wins integer DEFAULT 0 NOT NULL,
    total_top3 integer DEFAULT 0 NOT NULL,
    total_score numeric(20,4) DEFAULT 0 NOT NULL,
    total_participants integer DEFAULT 0 NOT NULL,
    tragge_point numeric(20,8) DEFAULT 0 NOT NULL,
    win_rate numeric(5,2) DEFAULT 0 NOT NULL,
    avg_trade_duration_seconds integer DEFAULT 0 NOT NULL,
    best_market character varying(20),
    best_market_pnl numeric(20,2) DEFAULT 0,
    total_trades bigint DEFAULT 0 NOT NULL,
    total_pnl numeric(20,2) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: user_verification; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_verification (
    user_id uuid NOT NULL,
    status public.kyc_status DEFAULT 'none'::public.kyc_status NOT NULL,
    first_name character varying(100),
    last_name character varying(100),
    date_of_birth date,
    nationality character varying(2),
    address_line1 character varying(255),
    address_line2 character varying(255),
    city character varying(100),
    state character varying(100),
    postal_code character varying(100),
    country character varying(2),
    verified_at timestamp with time zone,
    verified_by uuid,
    rejection_reason text,
    expires_at timestamp with time zone,
    provider character varying(50),
    provider_verification_id character varying(255),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    national_code character varying(10),
    phone character varying(15),
    shahkar_verified boolean DEFAULT false NOT NULL,
    face_verified boolean DEFAULT false NOT NULL,
    face_match_score double precision,
    liveness_score double precision,
    liveness_result character varying(10),
    card_ocr_verified boolean DEFAULT false NOT NULL,
    card_serial_number character varying(50),
    jibit_transaction_ids jsonb DEFAULT '[]'::jsonb NOT NULL,
    national_code_manual character varying(10),
    father_name character varying(100),
    birth_certificate_number character varying(20),
    birth_certificate_serial character varying(30),
    rejection_fields jsonb DEFAULT '[]'::jsonb,
    rejection_field_messages jsonb DEFAULT '{}'::jsonb,
    admin_notes text
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email character varying(255),
    password_hash character varying(255),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    status public.user_status DEFAULT 'active'::public.user_status NOT NULL,
    email_verified boolean DEFAULT false NOT NULL,
    email_verified_at timestamp with time zone,
    username character varying(50),
    display_name character varying(100),
    avatar_url character varying(500),
    bio character varying(500),
    country character varying(2),
    phone character varying(20),
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    is_system_account boolean DEFAULT false NOT NULL,
    password_changed_at timestamp with time zone,
    totp_secret text,
    totp_enabled boolean DEFAULT false NOT NULL,
    totp_verified_at timestamp with time zone,
    backup_codes text[],
    terms_accepted_at timestamp with time zone,
    ban_expires_at timestamp with time zone,
    phone_verified boolean DEFAULT false NOT NULL,
    preferred_lang character varying(5) DEFAULT 'fa'::character varying NOT NULL,
    telegram_id bigint
);


--
-- Name: COLUMN users.email_verified; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.email_verified IS 'Whether the user has verified their email address';


--
-- Name: COLUMN users.email_verified_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.email_verified_at IS 'Timestamp when the email was verified';


--
-- Name: COLUMN users.username; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.username IS 'Unique username for display (3-30 alphanumeric + underscores)';


--
-- Name: COLUMN users.display_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.display_name IS 'Display name shown publicly (2-100 chars)';


--
-- Name: COLUMN users.avatar_url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.avatar_url IS 'URL or base64 data URI for user avatar';


--
-- Name: COLUMN users.bio; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.bio IS 'Short user biography (max 500 chars)';


--
-- Name: COLUMN users.country; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.country IS 'ISO 3166-1 alpha-2 country code (e.g., US, GB, IR)';


--
-- Name: COLUMN users.phone; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.phone IS 'Phone number in E.164 format';


--
-- Name: COLUMN users.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.updated_at IS 'Timestamp of last profile update';


--
-- Name: COLUMN users.preferred_lang; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.preferred_lang IS 'Preferred language for emails and notifications: fa (Farsi) or en (English)';


--
-- Name: COLUMN users.telegram_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.telegram_id IS 'Verified Telegram user id from Mini App initData. Never trust client-supplied telegram_id without server-side signature verification.';


--
-- Name: verification_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.verification_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    code_hash character varying(64) NOT NULL,
    method character varying(10) NOT NULL,
    destination character varying(255) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    attempts integer DEFAULT 0,
    max_attempts integer DEFAULT 5,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT verification_codes_method_check CHECK (((method)::text = ANY ((ARRAY['sms'::character varying, 'email'::character varying])::text[])))
);


--
-- Name: wallet_ledger; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wallet_ledger (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    type public.ledger_type NOT NULL,
    amount_cents bigint NOT NULL,
    balance_after_cents bigint NOT NULL,
    ref_type public.ledger_ref_type,
    ref_id uuid,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    idempotency_key character varying(255),
    reason_code character varying(50),
    CONSTRAINT chk_amount_non_zero CHECK ((amount_cents <> 0)),
    CONSTRAINT chk_balance_after_non_negative CHECK ((balance_after_cents >= 0))
);


--
-- Name: COLUMN wallet_ledger.idempotency_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wallet_ledger.idempotency_key IS 'Unique key for idempotent operations. Format for prize credits: finalization:{contest_id}:{user_id}:{rank}';


--
-- Name: COLUMN wallet_ledger.reason_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wallet_ledger.reason_code IS 'Machine-readable reason code for the transaction. Values: CONTEST_ENTRY, CONTEST_ENTRY_FREE, CONTEST_REFUND_QUORUM, CONTEST_REFUND_ADMIN, CONTEST_PRIZE, WALLET_TOPUP, WALLET_WITHDRAW';


--
-- Name: wallets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wallets (
    user_id uuid NOT NULL,
    balance_cents bigint DEFAULT 0 NOT NULL,
    currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
    status public.wallet_status DEFAULT 'active'::public.wallet_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_balance_non_negative CHECK ((balance_cents >= 0))
);


--
-- Name: withdrawal_limits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.withdrawal_limits (
    user_id uuid NOT NULL,
    daily_amount_cents bigint,
    monthly_amount_cents bigint,
    daily_count integer,
    monthly_count integer,
    notes text,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_wl_daily_amount_positive CHECK (((daily_amount_cents IS NULL) OR (daily_amount_cents > 0))),
    CONSTRAINT chk_wl_daily_count_positive CHECK (((daily_count IS NULL) OR (daily_count > 0))),
    CONSTRAINT chk_wl_monthly_amount_positive CHECK (((monthly_amount_cents IS NULL) OR (monthly_amount_cents > 0))),
    CONSTRAINT chk_wl_monthly_count_positive CHECK (((monthly_count IS NULL) OR (monthly_count > 0))),
    CONSTRAINT chk_wl_monthly_gte_daily_amount CHECK (((monthly_amount_cents IS NULL) OR (daily_amount_cents IS NULL) OR (monthly_amount_cents >= daily_amount_cents))),
    CONSTRAINT chk_wl_monthly_gte_daily_count CHECK (((monthly_count IS NULL) OR (daily_count IS NULL) OR (monthly_count >= daily_count)))
);


--
-- Name: fills_shard_0; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fills ATTACH PARTITION public.fills_shard_0 FOR VALUES IN (0);


--
-- Name: fills_shard_1; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fills ATTACH PARTITION public.fills_shard_1 FOR VALUES IN (1);


--
-- Name: fills_shard_2; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fills ATTACH PARTITION public.fills_shard_2 FOR VALUES IN (2);


--
-- Name: fills_shard_3; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fills ATTACH PARTITION public.fills_shard_3 FOR VALUES IN (3);


--
-- Name: orders_shard_0; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders ATTACH PARTITION public.orders_shard_0 FOR VALUES IN (0);


--
-- Name: orders_shard_1; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders ATTACH PARTITION public.orders_shard_1 FOR VALUES IN (1);


--
-- Name: orders_shard_2; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders ATTACH PARTITION public.orders_shard_2 FOR VALUES IN (2);


--
-- Name: orders_shard_3; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders ATTACH PARTITION public.orders_shard_3 FOR VALUES IN (3);


--
-- Name: positions_shard_0; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions ATTACH PARTITION public.positions_shard_0 FOR VALUES IN (0);


--
-- Name: positions_shard_1; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions ATTACH PARTITION public.positions_shard_1 FOR VALUES IN (1);


--
-- Name: positions_shard_2; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions ATTACH PARTITION public.positions_shard_2 FOR VALUES IN (2);


--
-- Name: positions_shard_3; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions ATTACH PARTITION public.positions_shard_3 FOR VALUES IN (3);


--
-- Name: permissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions ALTER COLUMN id SET DEFAULT nextval('public.permissions_id_seq'::regclass);


--
-- Name: privilege_audit_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.privilege_audit_log ALTER COLUMN id SET DEFAULT nextval('public.privilege_audit_log_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Data for Name: admin_mfa_credentials; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admin_mfa_credentials (user_id, secret_ciphertext, last_totp_counter, enabled_at, recovery_generation, created_at, updated_at) FROM stdin;
256cf845-d483-45bd-89d1-3d0c93c13398	enc:admin-mfa:v1:yc8dSP5tltjPzGXwLd19yVhmvCdwO2p62qgJ7NKIBKurPJFxsy9ZiV6A4c6xDnb5IUDEX4iPlgEdM+v0	59561027	2026-08-15 21:53:47.601854+00	1	2026-08-15 21:53:47.601854+00	2026-08-15 21:53:47.601854+00
\.


--
-- Data for Name: admin_mfa_recovery_codes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admin_mfa_recovery_codes (user_id, generation, code_digest, used_at, created_at) FROM stdin;
256cf845-d483-45bd-89d1-3d0c93c13398	1	\\x8bad3d36f09921ffad05c31710c3faa88b3469c75169e44dc53def91cba6d06b	\N	2026-08-15 21:53:47.601854+00
256cf845-d483-45bd-89d1-3d0c93c13398	1	\\x36246906688a59c96f7c6fc9cf5a6436914317d4f0584b52a6228265dc1a6273	\N	2026-08-15 21:53:47.601854+00
256cf845-d483-45bd-89d1-3d0c93c13398	1	\\x07c47cfe6133a679d938fed064e177b53e3f6bb0e0d652b293702237e6f5f186	\N	2026-08-15 21:53:47.601854+00
256cf845-d483-45bd-89d1-3d0c93c13398	1	\\xce614c13efdc1b98a356d17e152d0cfa7fc940ef27a7b30f16a17550478d1db6	\N	2026-08-15 21:53:47.601854+00
256cf845-d483-45bd-89d1-3d0c93c13398	1	\\xfdf7ab5da4b7cbeda2c8f40c375bb8adcc16c1671e03ad27be2c4cf8778bf2dc	\N	2026-08-15 21:53:47.601854+00
256cf845-d483-45bd-89d1-3d0c93c13398	1	\\x74d6cb151ed456505b18bbfe7dfb477c841269fc54653b14abfdc6a8330d5359	\N	2026-08-15 21:53:47.601854+00
256cf845-d483-45bd-89d1-3d0c93c13398	1	\\xeef471471bb2ba42cc5735a783d869e4e2dac8798426ee1c72f0fda525a72d93	\N	2026-08-15 21:53:47.601854+00
256cf845-d483-45bd-89d1-3d0c93c13398	1	\\xe376aeefd741cac636631c79f3f573a46765146528a24da4b7847e13b5477d92	\N	2026-08-15 21:53:47.601854+00
256cf845-d483-45bd-89d1-3d0c93c13398	1	\\x09a7bdb5210e4f9636ec2a965bd44d1120e1e121b9d44d1a267b731c14fdebb9	\N	2026-08-15 21:53:47.601854+00
256cf845-d483-45bd-89d1-3d0c93c13398	1	\\x2887deaca52cdf5d389be31384e46e818498e8d2e784fe163e79dd5edbad5bd6	\N	2026-08-15 21:53:47.601854+00
\.


--
-- Data for Name: affiliate_commissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.affiliate_commissions (id, referrer_id, referred_id, source_type, source_id, gross_amount_cents, commission_rate_bps, commission_cents, status, created_at, credited_at) FROM stdin;
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_logs (id, actor_user_id, action, target_type, target_id, payload_json, created_at) FROM stdin;
5db4abb6-79f8-4fac-a239-515c2e73fd27	256cf845-d483-45bd-89d1-3d0c93c13398	admin.login.non_admin_attempt	auth	256cf845-d483-45bd-89d1-3d0c93c13398	{"ip": "::1", "email": "admin@tragge.com", "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36"}	2026-08-15 21:37:39.027484+00
af5818e5-81f9-45bc-844e-a163c0ac48c9	256cf845-d483-45bd-89d1-3d0c93c13398	admin.login.non_admin_attempt	auth	256cf845-d483-45bd-89d1-3d0c93c13398	{"ip": "::1", "email": "admin@tragge.com", "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36"}	2026-08-15 21:37:46.360466+00
510eaa80-11c6-4aad-823f-966b9b3b0c00	256cf845-d483-45bd-89d1-3d0c93c13398	admin.login.non_admin_attempt	auth	256cf845-d483-45bd-89d1-3d0c93c13398	{"ip": "::1", "email": "admin@tragge.com", "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36"}	2026-08-15 21:40:59.809836+00
eb362093-87d9-4f68-b246-7b64dceb0c0b	256cf845-d483-45bd-89d1-3d0c93c13398	admin.login.non_admin_attempt	auth	256cf845-d483-45bd-89d1-3d0c93c13398	{"ip": "::1", "email": "admin@tragge.com", "user_agent": "curl/8.21.0"}	2026-08-15 21:45:52.152173+00
a836aedc-94c1-4466-8161-958d70bbd274	256cf845-d483-45bd-89d1-3d0c93c13398	admin.login.non_admin_attempt	auth	256cf845-d483-45bd-89d1-3d0c93c13398	{"ip": "::1", "email": "admin@tragge.com", "user_agent": "curl/8.21.0"}	2026-08-15 21:46:30.785039+00
f4da4331-0e75-472c-b66d-8a3a0f33d9d6	256cf845-d483-45bd-89d1-3d0c93c13398	admin.mfa.challenge.issued	auth	256cf845-d483-45bd-89d1-3d0c93c13398	{"stage": "enroll"}	2026-08-15 21:48:39.044226+00
5b243e3a-4913-4a67-856a-e0ff6fd9a64e	256cf845-d483-45bd-89d1-3d0c93c13398	admin.mfa.challenge.issued	auth	256cf845-d483-45bd-89d1-3d0c93c13398	{"stage": "enroll"}	2026-08-15 21:48:53.786909+00
df02efcb-97fe-47da-a9a5-e1cc6e8a3522	256cf845-d483-45bd-89d1-3d0c93c13398	admin.mfa.challenge.issued	auth	256cf845-d483-45bd-89d1-3d0c93c13398	{"stage": "enroll"}	2026-08-15 21:50:54.263386+00
3b044338-78ae-45ee-96ed-2a89d46d6bb4	256cf845-d483-45bd-89d1-3d0c93c13398	admin.mfa.enrollment.started	auth	256cf845-d483-45bd-89d1-3d0c93c13398	{"status": "pending"}	2026-08-15 21:50:54.278987+00
5e3687ae-2f57-4974-8e65-acf7b3f0fe98	256cf845-d483-45bd-89d1-3d0c93c13398	admin.mfa.challenge.issued	auth	256cf845-d483-45bd-89d1-3d0c93c13398	{"stage": "enroll"}	2026-08-15 21:52:23.002229+00
0065452b-ed96-4e1c-946a-c02a718f0ca9	256cf845-d483-45bd-89d1-3d0c93c13398	admin.mfa.enrollment.started	auth	256cf845-d483-45bd-89d1-3d0c93c13398	{"status": "pending"}	2026-08-15 21:52:23.01736+00
d8897fdf-0a26-4873-a995-fb57ae4d8503	256cf845-d483-45bd-89d1-3d0c93c13398	admin.mfa.enrollment.completed	auth	256cf845-d483-45bd-89d1-3d0c93c13398	{"assurance": "super_admin_totp_v1"}	2026-08-15 21:53:47.601854+00
\.


--
-- Data for Name: calendar_contest_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.calendar_contest_history (id, calendar_entry_id, contest_id, scheduled_for, created_at) FROM stdin;
\.


--
-- Data for Name: calendar_entries; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.calendar_entries (id, template_id, recurrence_pattern, cron_expression, start_date, end_date, timezone, registration_lead_time_minutes, enabled, status, last_run_at, next_run_at, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: candles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.candles (symbol, resolution, "time", open, high, low, close, volume, created_at) FROM stdin;
POL/USD	5m	1786825800	0.0756	0.0756	0.0756	0.0756	5	2026-08-15 20:34:58.042519+00
ADA/USD	5m	1786825800	0.178	0.178	0.178	0.178	5	2026-08-15 20:34:58.042519+00
DOGE/USD	5m	1786825800	0.06983	0.06983	0.06983	0.06983	5	2026-08-15 20:34:58.042519+00
AAVE/USD	5m	1786825800	86.34	86.34	86.34	86.34	5	2026-08-15 20:34:58.042519+00
HBAR/USD	5m	1786825800	0.0659	0.0659	0.0659	0.0659	5	2026-08-15 20:34:58.042519+00
BTC/USD	5m	1786825800	63149.84	63149.84	63149.84	63149.84	5	2026-08-15 20:34:58.042519+00
SOL/USD	5m	1786825800	75.569	75.69	75.569	75.69	5	2026-08-15 20:34:58.042519+00
BCH/USD	5m	1786825800	202.31	202.31	202.31	202.31	5	2026-08-15 20:34:58.042519+00
XLM/USD	5m	1786825800	0.1572	0.1572	0.1572	0.1572	5	2026-08-15 20:34:58.042519+00
LINK/USD	5m	1786825800	9.552	9.552	9.552	9.552	5	2026-08-15 20:34:58.042519+00
AVAX/USD	5m	1786825800	6.525	6.525	6.525	6.525	5	2026-08-15 20:34:58.042519+00
XRP/USD	5m	1786825800	1.00159	1.00159	1.00159	1.00159	5	2026-08-15 20:34:58.042519+00
LTC/USD	5m	1786825800	44.23	44.23	44.23	44.23	5	2026-08-15 20:34:58.042519+00
APT/USD	5m	1786825800	0.54	0.54	0.54	0.54	5	2026-08-15 20:34:58.042519+00
ETH/USD	5m	1786825800	1882.91	1882.91	1882.91	1882.91	5	2026-08-15 20:34:58.042519+00
NEAR/USD	5m	1786825800	1.63	1.63	1.63	1.63	5	2026-08-15 20:34:58.042519+00
DOT/USD	5m	1786825800	0.765	0.765	0.765	0.765	5	2026-08-15 20:34:58.042519+00
UNI/USD	5m	1786825800	3.234	3.234	3.234	3.234	5	2026-08-15 20:34:58.042519+00
SUI/USD	1m	1786826040	0.6824	0.6824	0.6824	0.6824	1	2026-08-15 20:34:58.042519+00
SUI/USD	5m	1786825800	0.6824	0.6824	0.6824	0.6824	6	2026-08-15 20:34:58.042519+00
ETH/USD	1m	1786826220	1882.91	1883.94	1882.91	1883.94	23	2026-08-15 20:37:56.835274+00
BTC/USD	1m	1786826220	63149.72	63149.72	63149.72	63149.72	23	2026-08-15 20:37:56.835274+00
NEAR/USD	1m	1786826220	1.63	1.63	1.63	1.63	24	2026-08-15 20:37:56.835274+00
LTC/USD	1m	1786826220	44.23	44.23	44.23	44.23	24	2026-08-15 20:37:56.835274+00
AVAX/USD	1m	1786826220	6.525	6.525	6.525	6.525	24	2026-08-15 20:37:56.835274+00
ADA/USD	1m	1786826220	0.178	0.178	0.178	0.178	24	2026-08-15 20:37:56.835274+00
SUI/USD	1m	1786826220	0.68	0.68	0.68	0.68	24	2026-08-15 20:37:56.835274+00
UNI/USD	1m	1786826220	3.234	3.234	3.234	3.234	24	2026-08-15 20:37:56.835274+00
DOGE/USD	1m	1786826220	0.0698528	0.0698528	0.0698307	0.0698307	24	2026-08-15 20:37:56.835274+00
LINK/USD	1m	1786826220	9.552	9.552	9.552	9.552	24	2026-08-15 20:37:56.835274+00
XRP/USD	1m	1786826220	1.00159	1.00159	1.00159	1.00159	24	2026-08-15 20:37:56.835274+00
SOL/USD	1m	1786826220	75.327	75.587	75.327	75.587	24	2026-08-15 20:37:56.835274+00
DOT/USD	1m	1786826220	0.765	0.765	0.765	0.765	24	2026-08-15 20:37:56.835274+00
HBAR/USD	1m	1786826220	0.06565	0.06565	0.06565	0.06565	24	2026-08-15 20:37:56.835274+00
APT/USD	1m	1786826220	0.54	0.54	0.54	0.54	24	2026-08-15 20:37:56.835274+00
XLM/USD	1m	1786826220	0.15774	0.15774	0.15774	0.15774	24	2026-08-15 20:37:56.835274+00
AAVE/USD	1m	1786826220	86.34	86.34	86.34	86.34	24	2026-08-15 20:37:56.835274+00
POL/USD	1m	1786826220	0.0756	0.0756	0.0756	0.0756	24	2026-08-15 20:37:56.835274+00
BCH/USD	1m	1786826220	203.4	203.4	203.4	203.4	24	2026-08-15 20:37:56.835274+00
BTC/USD	1m	1786826280	63149.72	63149.72	63149.72	63149.72	11	2026-08-15 20:38:56.108766+00
ETH/USD	1m	1786826280	1883.94	1883.94	1883.94	1883.94	11	2026-08-15 20:38:56.108766+00
NEAR/USD	1m	1786826280	1.63	1.63	1.63	1.63	11	2026-08-15 20:38:56.108766+00
UNI/USD	1m	1786826280	3.234	3.234	3.234	3.234	11	2026-08-15 20:38:56.108766+00
BCH/USD	1m	1786826280	203.4	203.4	203.4	203.4	11	2026-08-15 20:38:56.108766+00
XLM/USD	1m	1786826280	0.15774	0.15774	0.15774	0.15774	11	2026-08-15 20:38:56.108766+00
XRP/USD	1m	1786826280	1.00159	1.00159	1.00159	1.00159	11	2026-08-15 20:38:56.108766+00
LINK/USD	1m	1786826280	9.552	9.552	9.552	9.552	11	2026-08-15 20:38:56.108766+00
SOL/USD	1m	1786826280	75.587	75.587	75.587	75.587	11	2026-08-15 20:38:56.108766+00
APT/USD	1m	1786826280	0.54	0.54	0.54	0.54	11	2026-08-15 20:38:56.108766+00
DOGE/USD	1m	1786826280	0.0698311	0.0698311	0.0698311	0.0698311	11	2026-08-15 20:38:56.108766+00
HBAR/USD	1m	1786826280	0.06565	0.06565	0.06565	0.06565	11	2026-08-15 20:38:56.108766+00
ADA/USD	1m	1786826280	0.178	0.178	0.178	0.178	11	2026-08-15 20:38:56.108766+00
LTC/USD	1m	1786826280	44.23	44.23	44.23	44.23	11	2026-08-15 20:38:56.108766+00
POL/USD	1m	1786826280	0.0756	0.0756	0.0756	0.0756	11	2026-08-15 20:38:56.108766+00
DOT/USD	1m	1786826280	0.765	0.765	0.765	0.765	11	2026-08-15 20:38:56.108766+00
AAVE/USD	1m	1786826280	86.34	86.34	86.34	86.34	11	2026-08-15 20:38:56.108766+00
AVAX/USD	1m	1786826280	6.525	6.525	6.525	6.525	11	2026-08-15 20:38:56.108766+00
SUI/USD	1m	1786826280	0.68	0.68	0.68	0.68	12	2026-08-15 20:38:56.108766+00
AAVE/USD	1m	1786826340	86.34	86.34	86.34	86.34	30	2026-08-15 20:39:56.108938+00
AAVE/USD	5m	1786826100	86.34	86.34	86.34	86.34	66	2026-08-15 20:39:56.108938+00
SOL/USD	1m	1786826340	75.587	75.587	75.587	75.587	30	2026-08-15 20:39:56.108938+00
SOL/USD	5m	1786826100	75.327	75.587	75.327	75.587	66	2026-08-15 20:39:56.108938+00
BTC/USD	1m	1786826340	63149.72	63149.72	63054.09	63054.09	30	2026-08-15 20:39:56.108938+00
BTC/USD	5m	1786826100	63149.72	63149.72	63054.09	63054.09	66	2026-08-15 20:39:56.108938+00
AVAX/USD	1m	1786826340	6.525	6.525	6.525	6.525	30	2026-08-15 20:39:56.108938+00
AVAX/USD	5m	1786826100	6.525	6.525	6.525	6.525	66	2026-08-15 20:39:56.108938+00
SUI/USD	1m	1786826340	0.68	0.68	0.68	0.68	29	2026-08-15 20:39:56.108938+00
SUI/USD	5m	1786826100	0.68	0.68	0.68	0.68	66	2026-08-15 20:39:56.108938+00
HBAR/USD	1m	1786826340	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 20:39:56.108938+00
HBAR/USD	5m	1786826100	0.06565	0.06565	0.06565	0.06565	66	2026-08-15 20:39:56.108938+00
POL/USD	1m	1786826340	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 20:39:56.108938+00
POL/USD	5m	1786826100	0.0756	0.0756	0.0756	0.0756	66	2026-08-15 20:39:56.108938+00
LTC/USD	1m	1786826340	44.23	44.23	44.23	44.23	31	2026-08-15 20:39:56.108938+00
LTC/USD	5m	1786826100	44.23	44.23	44.23	44.23	67	2026-08-15 20:39:56.108938+00
NEAR/USD	1m	1786826340	1.63	1.63	1.63	1.63	31	2026-08-15 20:39:56.108938+00
NEAR/USD	5m	1786826100	1.63	1.63	1.63	1.63	67	2026-08-15 20:39:56.108938+00
XLM/USD	1m	1786826340	0.15774	0.15774	0.15774	0.15774	31	2026-08-15 20:39:56.108938+00
XLM/USD	5m	1786826100	0.15774	0.15774	0.15774	0.15774	67	2026-08-15 20:39:56.108938+00
DOT/USD	1m	1786826340	0.765	0.765	0.765	0.765	31	2026-08-15 20:39:56.108938+00
DOT/USD	5m	1786826100	0.765	0.765	0.765	0.765	67	2026-08-15 20:39:56.108938+00
UNI/USD	1m	1786826340	3.234	3.234	3.234	3.234	31	2026-08-15 20:39:56.108938+00
UNI/USD	5m	1786826100	3.234	3.234	3.234	3.234	67	2026-08-15 20:39:56.108938+00
ADA/USD	1m	1786826340	0.178	0.178	0.178	0.178	31	2026-08-15 20:39:56.108938+00
ADA/USD	5m	1786826100	0.178	0.178	0.178	0.178	67	2026-08-15 20:39:56.108938+00
BCH/USD	1m	1786826340	203.4	203.4	203.4	203.4	31	2026-08-15 20:39:56.108938+00
BCH/USD	5m	1786826100	203.4	203.4	203.4	203.4	67	2026-08-15 20:39:56.108938+00
DOGE/USD	1m	1786826340	0.0698311	0.0698311	0.0698311	0.0698311	31	2026-08-15 20:39:56.108938+00
DOGE/USD	5m	1786826100	0.0698528	0.0698528	0.0698307	0.0698311	67	2026-08-15 20:39:56.108938+00
ETH/USD	1m	1786826340	1883.94	1883.94	1883.94	1883.94	31	2026-08-15 20:39:56.108938+00
ETH/USD	5m	1786826100	1882.91	1883.94	1882.91	1883.94	67	2026-08-15 20:39:56.108938+00
LINK/USD	1m	1786826340	9.552	9.552	9.552	9.552	31	2026-08-15 20:39:56.108938+00
LINK/USD	5m	1786826100	9.552	9.552	9.552	9.552	67	2026-08-15 20:39:56.108938+00
APT/USD	1m	1786826340	0.54	0.54	0.54	0.54	31	2026-08-15 20:39:56.108938+00
APT/USD	5m	1786826100	0.54	0.54	0.54	0.54	67	2026-08-15 20:39:56.108938+00
XRP/USD	1m	1786826340	1.00159	1.00159	1.00159	1.00159	31	2026-08-15 20:39:56.108938+00
XRP/USD	5m	1786826100	1.00159	1.00159	1.00159	1.00159	67	2026-08-15 20:39:56.108938+00
ADA/USD	1m	1786826400	0.178	0.178	0.178	0.178	29	2026-08-15 20:40:56.109123+00
AVAX/USD	1m	1786826400	6.525	6.525	6.525	6.525	30	2026-08-15 20:40:56.109123+00
UNI/USD	1m	1786826400	3.234	3.234	3.234	3.234	29	2026-08-15 20:40:56.109123+00
XLM/USD	1m	1786826400	0.15774	0.15774	0.15774	0.15774	29	2026-08-15 20:40:56.109123+00
ETH/USD	1m	1786826400	1883.94	1883.94	1883.94	1883.94	29	2026-08-15 20:40:56.109123+00
BTC/USD	1m	1786826400	63054.09	63054.09	63054.03	63054.03	30	2026-08-15 20:40:56.109123+00
DOGE/USD	1m	1786826400	0.0698311	0.0698311	0.0698311	0.0698311	29	2026-08-15 20:40:56.109123+00
AAVE/USD	1m	1786826400	86.34	86.34	86.34	86.34	30	2026-08-15 20:40:56.109123+00
DOT/USD	1m	1786826400	0.765	0.765	0.765	0.765	29	2026-08-15 20:40:56.109123+00
LTC/USD	1m	1786826400	44.23	44.23	44.23	44.23	29	2026-08-15 20:40:56.109123+00
LINK/USD	1m	1786826400	9.552	9.555	9.55	9.555	29	2026-08-15 20:40:56.109123+00
SOL/USD	1m	1786826400	75.587	75.695	75.587	75.695	30	2026-08-15 20:40:56.109123+00
NEAR/USD	1m	1786826400	1.63	1.63	1.63	1.63	29	2026-08-15 20:40:56.109123+00
HBAR/USD	1m	1786826400	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 20:40:56.109123+00
XRP/USD	1m	1786826400	1.00159	1.00159	1.00159	1.00159	29	2026-08-15 20:40:56.109123+00
BCH/USD	1m	1786826400	203.4	203.4	203.4	203.4	29	2026-08-15 20:40:56.109123+00
POL/USD	1m	1786826400	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 20:40:56.109123+00
APT/USD	1m	1786826400	0.54	0.54	0.54	0.54	29	2026-08-15 20:40:56.109123+00
SUI/USD	1m	1786826400	0.68	0.68	0.68	0.68	31	2026-08-15 20:40:56.109123+00
LTC/USD	1m	1786826460	44.23	44.23	44.23	44.23	30	2026-08-15 20:41:56.10801+00
SOL/USD	1m	1786826460	75.695	75.695	75.695	75.695	30	2026-08-15 20:41:56.10801+00
ADA/USD	1m	1786826460	0.178	0.178	0.178	0.178	30	2026-08-15 20:41:56.10801+00
UNI/USD	1m	1786826460	3.234	3.235	3.234	3.235	30	2026-08-15 20:41:56.10801+00
XRP/USD	1m	1786826460	1.00159	1.00159	1.00159	1.00159	30	2026-08-15 20:41:56.10801+00
HBAR/USD	1m	1786826460	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 20:41:56.10801+00
XLM/USD	1m	1786826460	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 20:41:56.10801+00
BTC/USD	1m	1786826460	63054.03	63147.16	63054.03	63147.16	30	2026-08-15 20:41:56.10801+00
NEAR/USD	1m	1786826460	1.63	1.63	1.63	1.63	30	2026-08-15 20:41:56.10801+00
AVAX/USD	1m	1786826460	6.525	6.525	6.525	6.525	30	2026-08-15 20:41:56.10801+00
AAVE/USD	1m	1786826460	86.34	86.34	86.34	86.34	30	2026-08-15 20:41:56.10801+00
POL/USD	1m	1786826460	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 20:41:56.10801+00
ETH/USD	1m	1786826460	1883.94	1883.94	1883.94	1883.94	30	2026-08-15 20:41:56.10801+00
LINK/USD	1m	1786826460	9.555	9.555	9.555	9.555	30	2026-08-15 20:41:56.10801+00
DOT/USD	1m	1786826460	0.765	0.765	0.765	0.765	30	2026-08-15 20:41:56.10801+00
DOGE/USD	1m	1786826460	0.0698311	0.0698358	0.0698311	0.0698358	30	2026-08-15 20:41:56.10801+00
BCH/USD	1m	1786826460	203.4	203.4	203.4	203.4	30	2026-08-15 20:41:56.10801+00
APT/USD	1m	1786826460	0.54	0.54	0.54	0.54	30	2026-08-15 20:41:56.10801+00
SUI/USD	1m	1786826460	0.68	0.68	0.68	0.68	30	2026-08-15 20:41:56.10801+00
DOGE/USD	1m	1786826520	0.0698358	0.0698358	0.0698358	0.0698358	30	2026-08-15 20:42:56.107748+00
LINK/USD	1m	1786826520	9.555	9.555	9.555	9.555	30	2026-08-15 20:42:56.107748+00
XRP/USD	1m	1786826520	1.00159	1.00159	1.00159	1.00159	30	2026-08-15 20:42:56.107748+00
SUI/USD	1m	1786826520	0.68	0.68	0.68	0.68	29	2026-08-15 20:42:56.107748+00
AAVE/USD	1m	1786826520	86.34	86.34	86.34	86.34	30	2026-08-15 20:42:56.107748+00
ADA/USD	1m	1786826520	0.178	0.178	0.178	0.178	30	2026-08-15 20:42:56.107748+00
BTC/USD	1m	1786826520	63147.16	63147.16	63147.16	63147.16	30	2026-08-15 20:42:56.107748+00
XLM/USD	1m	1786826520	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 20:42:56.107748+00
DOT/USD	1m	1786826520	0.765	0.765	0.765	0.765	30	2026-08-15 20:42:56.107748+00
ETH/USD	1m	1786826520	1883.94	1883.94	1883.94	1883.94	30	2026-08-15 20:42:56.107748+00
UNI/USD	1m	1786826520	3.235	3.235	3.235	3.235	30	2026-08-15 20:42:56.107748+00
LTC/USD	1m	1786826520	44.23	44.23	44.23	44.23	30	2026-08-15 20:42:56.107748+00
BCH/USD	1m	1786826520	202.36	202.36	202.36	202.36	30	2026-08-15 20:42:56.107748+00
NEAR/USD	1m	1786826520	1.63	1.63	1.63	1.63	30	2026-08-15 20:42:56.107748+00
APT/USD	1m	1786826520	0.54	0.54	0.54	0.54	30	2026-08-15 20:42:56.107748+00
POL/USD	1m	1786826520	0.0756	0.0756	0.0756	0.0756	31	2026-08-15 20:42:56.107748+00
AVAX/USD	1m	1786826520	6.525	6.525	6.491	6.491	31	2026-08-15 20:42:56.107748+00
SOL/USD	1m	1786826520	75.695	75.695	75.695	75.695	31	2026-08-15 20:42:56.107748+00
HBAR/USD	1m	1786826520	0.06565	0.06565	0.06565	0.06565	31	2026-08-15 20:42:56.107748+00
DOT/USD	1m	1786826580	0.765	0.765	0.765	0.765	30	2026-08-15 20:43:56.109003+00
ETH/USD	1m	1786826580	1883.94	1884.85	1883.94	1884.85	30	2026-08-15 20:43:56.109003+00
DOGE/USD	1m	1786826580	0.0698358	0.0698358	0.0698358	0.0698358	30	2026-08-15 20:43:56.109003+00
UNI/USD	1m	1786826580	3.235	3.235	3.235	3.235	30	2026-08-15 20:43:56.109003+00
XLM/USD	1m	1786826580	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 20:43:56.109003+00
AVAX/USD	1m	1786826580	6.491	6.491	6.491	6.491	29	2026-08-15 20:43:56.109003+00
POL/USD	1m	1786826580	0.0756	0.0756	0.0756	0.0756	29	2026-08-15 20:43:56.109003+00
BCH/USD	1m	1786826580	202.36	202.36	202.36	202.36	30	2026-08-15 20:43:56.109003+00
BTC/USD	1m	1786826580	63147.16	63147.87	63147.16	63147.71	30	2026-08-15 20:43:56.109003+00
LTC/USD	1m	1786826580	44.23	44.23	44.23	44.23	30	2026-08-15 20:43:56.109003+00
APT/USD	1m	1786826580	0.54	0.54	0.54	0.54	30	2026-08-15 20:43:56.109003+00
ADA/USD	1m	1786826580	0.178	0.178	0.178	0.178	30	2026-08-15 20:43:56.109003+00
XRP/USD	1m	1786826580	1.00159	1.00159	1.00159	1.00159	30	2026-08-15 20:43:56.109003+00
HBAR/USD	1m	1786826580	0.06565	0.06565	0.06565	0.06565	29	2026-08-15 20:43:56.109003+00
NEAR/USD	1m	1786826580	1.63	1.63	1.63	1.63	30	2026-08-15 20:43:56.109003+00
SOL/USD	1m	1786826580	75.695	75.695	75.695	75.695	29	2026-08-15 20:43:56.109003+00
SUI/USD	1m	1786826580	0.68	0.68	0.68	0.68	30	2026-08-15 20:43:56.109003+00
AAVE/USD	1m	1786826580	86.34	86.34	86.34	86.34	30	2026-08-15 20:43:56.109003+00
LINK/USD	1m	1786826580	9.555	9.557	9.555	9.557	30	2026-08-15 20:43:56.109003+00
XLM/USD	1m	1786826640	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 20:44:56.108847+00
XLM/USD	5m	1786826400	0.15774	0.15774	0.15774	0.15774	149	2026-08-15 20:44:56.108847+00
XLM/USD	15m	1786825800	0.15774	0.15774	0.15774	0.15774	216	2026-08-15 20:44:56.108847+00
XRP/USD	1m	1786826640	1.00159	1.00159	1.00159	1.00159	30	2026-08-15 20:44:56.108847+00
XRP/USD	5m	1786826400	1.00159	1.00159	1.00159	1.00159	149	2026-08-15 20:44:56.108847+00
XRP/USD	15m	1786825800	1.00159	1.00159	1.00159	1.00159	216	2026-08-15 20:44:56.108847+00
SOL/USD	1m	1786826640	75.695	75.695	75.589	75.589	30	2026-08-15 20:44:56.108847+00
SOL/USD	5m	1786826400	75.587	75.695	75.587	75.589	150	2026-08-15 20:44:56.108847+00
SOL/USD	15m	1786825800	75.327	75.695	75.327	75.589	216	2026-08-15 20:44:56.108847+00
DOGE/USD	1m	1786826640	0.0698358	0.0698568	0.0698358	0.0698568	30	2026-08-15 20:44:56.108847+00
DOGE/USD	5m	1786826400	0.0698311	0.0698568	0.0698311	0.0698568	149	2026-08-15 20:44:56.108847+00
DOGE/USD	15m	1786825800	0.0698528	0.0698568	0.0698307	0.0698568	216	2026-08-15 20:44:56.108847+00
BCH/USD	1m	1786826640	202.36	202.36	202.36	202.36	30	2026-08-15 20:44:56.108847+00
BCH/USD	5m	1786826400	203.4	203.4	202.36	202.36	149	2026-08-15 20:44:56.108847+00
BCH/USD	15m	1786825800	203.4	203.4	202.36	202.36	216	2026-08-15 20:44:56.108847+00
UNI/USD	1m	1786826640	3.235	3.235	3.235	3.235	30	2026-08-15 20:44:56.108847+00
UNI/USD	5m	1786826400	3.234	3.235	3.234	3.235	149	2026-08-15 20:44:56.108847+00
UNI/USD	15m	1786825800	3.234	3.235	3.234	3.235	216	2026-08-15 20:44:56.108847+00
BTC/USD	1m	1786826640	63147.71	63147.71	63147.71	63147.71	30	2026-08-15 20:44:56.108847+00
BTC/USD	5m	1786826400	63054.09	63147.87	63054.03	63147.71	150	2026-08-15 20:44:56.108847+00
BTC/USD	15m	1786825800	63149.72	63149.72	63054.03	63147.71	216	2026-08-15 20:44:56.108847+00
DOT/USD	1m	1786826640	0.765	0.765	0.765	0.765	30	2026-08-15 20:44:56.108847+00
DOT/USD	5m	1786826400	0.765	0.765	0.765	0.765	149	2026-08-15 20:44:56.108847+00
DOT/USD	15m	1786825800	0.765	0.765	0.765	0.765	216	2026-08-15 20:44:56.108847+00
AAVE/USD	1m	1786826640	86.34	86.34	86.34	86.34	30	2026-08-15 20:44:56.108847+00
AAVE/USD	5m	1786826400	86.34	86.34	86.34	86.34	150	2026-08-15 20:44:56.108847+00
AAVE/USD	15m	1786825800	86.34	86.34	86.34	86.34	216	2026-08-15 20:44:56.108847+00
NEAR/USD	1m	1786826640	1.63	1.63	1.63	1.63	30	2026-08-15 20:44:56.108847+00
NEAR/USD	5m	1786826400	1.63	1.63	1.63	1.63	149	2026-08-15 20:44:56.108847+00
NEAR/USD	15m	1786825800	1.63	1.63	1.63	1.63	216	2026-08-15 20:44:56.108847+00
LINK/USD	1m	1786826640	9.557	9.557	9.557	9.557	30	2026-08-15 20:44:56.108847+00
LINK/USD	5m	1786826400	9.552	9.557	9.55	9.557	149	2026-08-15 20:44:56.108847+00
LINK/USD	15m	1786825800	9.552	9.557	9.55	9.557	216	2026-08-15 20:44:56.108847+00
APT/USD	1m	1786826640	0.54	0.54	0.54	0.54	30	2026-08-15 20:44:56.108847+00
APT/USD	5m	1786826400	0.54	0.54	0.54	0.54	149	2026-08-15 20:44:56.108847+00
APT/USD	15m	1786825800	0.54	0.54	0.54	0.54	216	2026-08-15 20:44:56.108847+00
AVAX/USD	1m	1786826640	6.491	6.491	6.491	6.491	30	2026-08-15 20:44:56.108847+00
AVAX/USD	5m	1786826400	6.525	6.525	6.491	6.491	150	2026-08-15 20:44:56.108847+00
AVAX/USD	15m	1786825800	6.525	6.525	6.491	6.491	216	2026-08-15 20:44:56.108847+00
ADA/USD	1m	1786826640	0.178	0.178	0.178	0.178	30	2026-08-15 20:44:56.108847+00
ADA/USD	5m	1786826400	0.178	0.178	0.178	0.178	149	2026-08-15 20:44:56.108847+00
ADA/USD	15m	1786825800	0.178	0.178	0.178	0.178	216	2026-08-15 20:44:56.108847+00
POL/USD	1m	1786826640	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 20:44:56.108847+00
POL/USD	5m	1786826400	0.0756	0.0756	0.0756	0.0756	150	2026-08-15 20:44:56.108847+00
POL/USD	15m	1786825800	0.0756	0.0756	0.0756	0.0756	216	2026-08-15 20:44:56.108847+00
LTC/USD	1m	1786826640	44.23	44.23	44.23	44.23	30	2026-08-15 20:44:56.108847+00
LTC/USD	5m	1786826400	44.23	44.23	44.23	44.23	149	2026-08-15 20:44:56.108847+00
LTC/USD	15m	1786825800	44.23	44.23	44.23	44.23	216	2026-08-15 20:44:56.108847+00
ETH/USD	1m	1786826640	1884.85	1884.85	1884.85	1884.85	30	2026-08-15 20:44:56.108847+00
ETH/USD	5m	1786826400	1883.94	1884.85	1883.94	1884.85	149	2026-08-15 20:44:56.108847+00
ETH/USD	15m	1786825800	1882.91	1884.85	1882.91	1884.85	216	2026-08-15 20:44:56.108847+00
HBAR/USD	1m	1786826640	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 20:44:56.108847+00
HBAR/USD	5m	1786826400	0.06565	0.06565	0.06565	0.06565	150	2026-08-15 20:44:56.108847+00
HBAR/USD	15m	1786825800	0.06565	0.06565	0.06565	0.06565	216	2026-08-15 20:44:56.108847+00
SUI/USD	1m	1786826640	0.68	0.68	0.68	0.68	31	2026-08-15 20:44:56.108847+00
SUI/USD	5m	1786826400	0.68	0.68	0.68	0.68	151	2026-08-15 20:44:56.108847+00
SUI/USD	15m	1786825800	0.68	0.68	0.68	0.68	217	2026-08-15 20:44:56.108847+00
DOGE/USD	1m	1786826700	0.0698568	0.0698568	0.0698568	0.0698568	30	2026-08-15 20:45:56.107533+00
APT/USD	1m	1786826700	0.54	0.54	0.54	0.54	30	2026-08-15 20:45:56.107533+00
HBAR/USD	1m	1786826700	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 20:45:56.107533+00
AVAX/USD	1m	1786826700	6.491	6.491	6.491	6.491	30	2026-08-15 20:45:56.107533+00
DOT/USD	1m	1786826700	0.765	0.765	0.765	0.765	30	2026-08-15 20:45:56.107533+00
UNI/USD	1m	1786826700	3.235	3.235	3.235	3.235	30	2026-08-15 20:45:56.107533+00
LTC/USD	1m	1786826700	44.23	44.23	44.23	44.23	30	2026-08-15 20:45:56.107533+00
ADA/USD	1m	1786826700	0.178	0.1782	0.178	0.1782	30	2026-08-15 20:45:56.107533+00
BTC/USD	1m	1786826700	63147.71	63147.71	63054.21	63054.21	30	2026-08-15 20:45:56.107533+00
XRP/USD	1m	1786826700	1.00159	1.00159	1.00159	1.00159	30	2026-08-15 20:45:56.107533+00
AAVE/USD	1m	1786826700	86.34	86.34	86.34	86.34	30	2026-08-15 20:45:56.107533+00
SOL/USD	1m	1786826700	75.589	75.697	75.589	75.697	30	2026-08-15 20:45:56.107533+00
ETH/USD	1m	1786826700	1884.85	1884.85	1882.06	1882.06	30	2026-08-15 20:45:56.107533+00
NEAR/USD	1m	1786826700	1.63	1.63	1.63	1.63	30	2026-08-15 20:45:56.107533+00
XLM/USD	1m	1786826700	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 20:45:56.107533+00
BCH/USD	1m	1786826700	202.36	202.36	202.36	202.36	30	2026-08-15 20:45:56.107533+00
SUI/USD	1m	1786826700	0.68	0.68	0.68	0.68	29	2026-08-15 20:45:56.107533+00
LINK/USD	1m	1786826700	9.557	9.557	9.557	9.557	30	2026-08-15 20:45:56.107533+00
POL/USD	1m	1786826700	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 20:45:56.107533+00
UNI/USD	1m	1786826760	3.235	3.235	3.235	3.235	30	2026-08-15 20:46:56.10745+00
NEAR/USD	1m	1786826760	1.63	1.63	1.63	1.63	30	2026-08-15 20:46:56.10745+00
LTC/USD	1m	1786826760	44.23	44.23	44.23	44.23	30	2026-08-15 20:46:56.10745+00
ETH/USD	1m	1786826760	1882.06	1882.06	1882.06	1882.06	30	2026-08-15 20:46:56.10745+00
BCH/USD	1m	1786826760	202.36	202.36	202.36	202.36	30	2026-08-15 20:46:56.10745+00
DOT/USD	1m	1786826760	0.765	0.765	0.765	0.765	30	2026-08-15 20:46:56.10745+00
XLM/USD	1m	1786826760	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 20:46:56.10745+00
HBAR/USD	1m	1786826760	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 20:46:56.10745+00
ADA/USD	1m	1786826760	0.1782	0.1782	0.1782	0.1782	30	2026-08-15 20:46:56.10745+00
APT/USD	1m	1786826760	0.54	0.54	0.54	0.54	30	2026-08-15 20:46:56.10745+00
POL/USD	1m	1786826760	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 20:46:56.10745+00
AVAX/USD	1m	1786826760	6.491	6.491	6.491	6.491	30	2026-08-15 20:46:56.10745+00
LINK/USD	1m	1786826760	9.557	9.557	9.557	9.557	30	2026-08-15 20:46:56.10745+00
AAVE/USD	1m	1786826760	86.34	86.34	86.34	86.34	30	2026-08-15 20:46:56.10745+00
XRP/USD	1m	1786826760	1.00159	1.00159	1.00159	1.00159	30	2026-08-15 20:46:56.10745+00
BTC/USD	1m	1786826760	63054.21	63054.21	63054.06	63054.06	30	2026-08-15 20:46:56.10745+00
DOGE/USD	1m	1786826760	0.0698568	0.0698568	0.0698568	0.0698568	30	2026-08-15 20:46:56.10745+00
SOL/USD	1m	1786826760	75.697	75.697	75.6	75.6	30	2026-08-15 20:46:56.10745+00
SUI/USD	1m	1786826760	0.68	0.68	0.68	0.68	31	2026-08-15 20:46:56.10745+00
POL/USD	1m	1786826820	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 20:47:56.107332+00
AVAX/USD	1m	1786826820	6.491	6.491	6.491	6.491	30	2026-08-15 20:47:56.107332+00
BTC/USD	1m	1786826820	63054.06	63054.06	63054.06	63054.06	30	2026-08-15 20:47:56.107332+00
HBAR/USD	1m	1786826820	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 20:47:56.107332+00
SUI/USD	1m	1786826820	0.68	0.68	0.68	0.68	29	2026-08-15 20:47:56.107332+00
BCH/USD	1m	1786826820	202.36	202.36	202.36	202.36	31	2026-08-15 20:47:56.107332+00
UNI/USD	1m	1786826820	3.235	3.235	3.235	3.235	31	2026-08-15 20:47:56.107332+00
DOGE/USD	1m	1786826820	0.0698568	0.0698568	0.0698568	0.0698568	31	2026-08-15 20:47:56.107332+00
AAVE/USD	1m	1786826820	86.34	86.34	86.34	86.34	31	2026-08-15 20:47:56.107332+00
ETH/USD	1m	1786826820	1882.06	1882.06	1882.06	1882.06	31	2026-08-15 20:47:56.107332+00
XLM/USD	1m	1786826820	0.15774	0.15774	0.15774	0.15774	31	2026-08-15 20:47:56.107332+00
XRP/USD	1m	1786826820	1.00159	1.00159	1.00159	1.00159	31	2026-08-15 20:47:56.107332+00
NEAR/USD	1m	1786826820	1.63	1.63	1.63	1.63	31	2026-08-15 20:47:56.107332+00
ADA/USD	1m	1786826820	0.1782	0.1782	0.1782	0.1782	31	2026-08-15 20:47:56.107332+00
APT/USD	1m	1786826820	0.54	0.54	0.54	0.54	31	2026-08-15 20:47:56.107332+00
LTC/USD	1m	1786826820	44.23	44.23	44.23	44.23	31	2026-08-15 20:47:56.107332+00
DOT/USD	1m	1786826820	0.765	0.765	0.765	0.765	31	2026-08-15 20:47:56.107332+00
LINK/USD	1m	1786826820	9.557	9.557	9.557	9.557	31	2026-08-15 20:47:56.107332+00
SOL/USD	1m	1786826820	75.6	75.6	75.6	75.6	31	2026-08-15 20:47:56.107332+00
POL/USD	1m	1786826880	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 20:48:56.117427+00
HBAR/USD	1m	1786826880	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 20:48:56.117427+00
AVAX/USD	1m	1786826880	6.491	6.491	6.491	6.491	30	2026-08-15 20:48:56.117427+00
SUI/USD	1m	1786826880	0.68	0.68	0.68	0.68	30	2026-08-15 20:48:56.117427+00
ETH/USD	1m	1786826880	1882.06	1882.06	1880	1880	29	2026-08-15 20:48:56.117427+00
BTC/USD	1m	1786826880	63054.06	63060.15	63054.06	63060.15	30	2026-08-15 20:48:56.117427+00
XRP/USD	1m	1786826880	1.00159	1.00159	1.00159	1.00159	30	2026-08-15 20:48:56.117427+00
UNI/USD	1m	1786826880	3.235	3.235	3.235	3.235	30	2026-08-15 20:48:56.117427+00
ADA/USD	1m	1786826880	0.1782	0.1782	0.1782	0.1782	30	2026-08-15 20:48:56.117427+00
SOL/USD	1m	1786826880	75.6	75.6	75.6	75.6	30	2026-08-15 20:48:56.117427+00
APT/USD	1m	1786826880	0.54	0.54	0.54	0.54	30	2026-08-15 20:48:56.117427+00
LINK/USD	1m	1786826880	9.557	9.557	9.557	9.557	30	2026-08-15 20:48:56.117427+00
AAVE/USD	1m	1786826880	86.34	86.34	86.34	86.34	30	2026-08-15 20:48:56.117427+00
LTC/USD	1m	1786826880	44.23	44.23	44.23	44.23	30	2026-08-15 20:48:56.117427+00
XLM/USD	1m	1786826880	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 20:48:56.117427+00
DOT/USD	1m	1786826880	0.765	0.765	0.765	0.765	30	2026-08-15 20:48:56.117427+00
NEAR/USD	1m	1786826880	1.63	1.63	1.63	1.63	30	2026-08-15 20:48:56.117427+00
DOGE/USD	1m	1786826880	0.0698568	0.0698568	0.0698568	0.0698568	30	2026-08-15 20:48:56.117427+00
BCH/USD	1m	1786826880	202.36	202.36	202.36	202.36	30	2026-08-15 20:48:56.117427+00
SUI/USD	1m	1786826940	0.68	0.68	0.68	0.68	30	2026-08-15 20:49:56.108687+00
SUI/USD	5m	1786826700	0.68	0.68	0.68	0.68	149	2026-08-15 20:49:56.108687+00
ETH/USD	1m	1786826940	1880	1880	1880	1880	30	2026-08-15 20:49:56.108687+00
ETH/USD	5m	1786826700	1884.85	1884.85	1880	1880	150	2026-08-15 20:49:56.108687+00
AVAX/USD	1m	1786826940	6.491	6.491	6.491	6.491	30	2026-08-15 20:49:56.108687+00
AVAX/USD	5m	1786826700	6.491	6.491	6.491	6.491	150	2026-08-15 20:49:56.108687+00
HBAR/USD	1m	1786826940	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 20:49:56.108687+00
HBAR/USD	5m	1786826700	0.06565	0.06565	0.06565	0.06565	150	2026-08-15 20:49:56.108687+00
LTC/USD	1m	1786826940	44.23	44.23	44.23	44.23	29	2026-08-15 20:49:56.108687+00
LTC/USD	5m	1786826700	44.23	44.23	44.23	44.23	150	2026-08-15 20:49:56.108687+00
BTC/USD	1m	1786826940	63060.15	63060.15	63060.15	63060.15	30	2026-08-15 20:49:56.108687+00
BTC/USD	5m	1786826700	63147.71	63147.71	63054.06	63060.15	150	2026-08-15 20:49:56.108687+00
XRP/USD	1m	1786826940	1.00159	1.00159	1.00159	1.00159	29	2026-08-15 20:49:56.108687+00
XRP/USD	5m	1786826700	1.00159	1.00159	1.00159	1.00159	150	2026-08-15 20:49:56.108687+00
APT/USD	1m	1786826940	0.54	0.54	0.54	0.54	30	2026-08-15 20:49:56.108687+00
APT/USD	5m	1786826700	0.54	0.54	0.54	0.54	151	2026-08-15 20:49:56.108687+00
NEAR/USD	1m	1786826940	1.63	1.63	1.63	1.63	30	2026-08-15 20:49:56.108687+00
NEAR/USD	5m	1786826700	1.63	1.63	1.63	1.63	151	2026-08-15 20:49:56.108687+00
LINK/USD	1m	1786826940	9.557	9.557	9.557	9.557	30	2026-08-15 20:49:56.108687+00
LINK/USD	5m	1786826700	9.557	9.557	9.557	9.557	151	2026-08-15 20:49:56.108687+00
ADA/USD	1m	1786826940	0.1782	0.1782	0.1782	0.1782	30	2026-08-15 20:49:56.108687+00
ADA/USD	5m	1786826700	0.178	0.1782	0.178	0.1782	151	2026-08-15 20:49:56.108687+00
XLM/USD	1m	1786826940	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 20:49:56.108687+00
XLM/USD	5m	1786826700	0.15774	0.15774	0.15774	0.15774	151	2026-08-15 20:49:56.108687+00
SOL/USD	1m	1786826940	75.6	75.6	75.6	75.6	30	2026-08-15 20:49:56.108687+00
SOL/USD	5m	1786826700	75.589	75.697	75.589	75.6	151	2026-08-15 20:49:56.108687+00
BCH/USD	1m	1786826940	202.36	202.36	202.36	202.36	30	2026-08-15 20:49:56.108687+00
BCH/USD	5m	1786826700	202.36	202.36	202.36	202.36	151	2026-08-15 20:49:56.108687+00
DOT/USD	1m	1786826940	0.765	0.765	0.765	0.765	30	2026-08-15 20:49:56.108687+00
DOT/USD	5m	1786826700	0.765	0.765	0.765	0.765	151	2026-08-15 20:49:56.108687+00
AAVE/USD	1m	1786826940	85.97	85.97	85.97	85.97	30	2026-08-15 20:49:56.108687+00
AAVE/USD	5m	1786826700	86.34	86.34	85.97	85.97	151	2026-08-15 20:49:56.108687+00
UNI/USD	1m	1786826940	3.235	3.244	3.235	3.244	30	2026-08-15 20:49:56.108687+00
UNI/USD	5m	1786826700	3.235	3.244	3.235	3.244	151	2026-08-15 20:49:56.108687+00
POL/USD	1m	1786826940	0.0756	0.0756	0.0756	0.0756	31	2026-08-15 20:49:56.108687+00
POL/USD	5m	1786826700	0.0756	0.0756	0.0756	0.0756	151	2026-08-15 20:49:56.108687+00
DOGE/USD	1m	1786826940	0.0698568	0.0698568	0.0698568	0.0698568	30	2026-08-15 20:49:56.108687+00
DOGE/USD	5m	1786826700	0.0698568	0.0698568	0.0698568	0.0698568	151	2026-08-15 20:49:56.108687+00
HBAR/USD	1m	1786827000	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 20:50:56.107628+00
ETH/USD	1m	1786827000	1880	1880.77	1880	1880.77	30	2026-08-15 20:50:56.107628+00
AVAX/USD	1m	1786827000	6.491	6.491	6.491	6.491	30	2026-08-15 20:50:56.107628+00
XLM/USD	1m	1786827000	0.15774	0.15774	0.15774	0.15774	29	2026-08-15 20:50:56.107628+00
LINK/USD	1m	1786827000	9.557	9.557	9.557	9.557	29	2026-08-15 20:50:56.107628+00
UNI/USD	1m	1786827000	3.244	3.244	3.244	3.244	29	2026-08-15 20:50:56.107628+00
SUI/USD	1m	1786827000	0.68	0.68	0.68	0.68	30	2026-08-15 20:50:56.107628+00
POL/USD	1m	1786827000	0.0756	0.0756	0.0756	0.0756	29	2026-08-15 20:50:56.107628+00
XRP/USD	1m	1786827000	1.00159	1.00159	1.00159	1.00159	30	2026-08-15 20:50:56.107628+00
LTC/USD	1m	1786827000	44.23	44.23	44.23	44.23	30	2026-08-15 20:50:56.107628+00
BCH/USD	1m	1786827000	202.36	202.36	202.36	202.36	29	2026-08-15 20:50:56.107628+00
BTC/USD	1m	1786827000	63060.15	63139.46	63060.03	63139.46	30	2026-08-15 20:50:56.107628+00
DOT/USD	1m	1786827000	0.765	0.765	0.765	0.765	29	2026-08-15 20:50:56.107628+00
SOL/USD	1m	1786827000	75.6	75.6	75.6	75.6	29	2026-08-15 20:50:56.107628+00
ADA/USD	1m	1786827000	0.1782	0.1782	0.1782	0.1782	29	2026-08-15 20:50:56.107628+00
NEAR/USD	1m	1786827000	1.63	1.63	1.63	1.63	29	2026-08-15 20:50:56.107628+00
AAVE/USD	1m	1786827000	85.97	85.97	85.97	85.97	29	2026-08-15 20:50:56.107628+00
APT/USD	1m	1786827000	0.54	0.54	0.54	0.54	29	2026-08-15 20:50:56.107628+00
DOGE/USD	1m	1786827000	0.0698568	0.0698568	0.0698503	0.0698503	29	2026-08-15 20:50:56.107628+00
NEAR/USD	1m	1786827060	1.63	1.63	1.63	1.63	30	2026-08-15 20:51:56.107188+00
POL/USD	1m	1786827060	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 20:51:56.107188+00
ADA/USD	1m	1786827060	0.1782	0.1782	0.1782	0.1782	30	2026-08-15 20:51:56.107188+00
UNI/USD	1m	1786827060	3.244	3.244	3.241	3.241	30	2026-08-15 20:51:56.107188+00
BCH/USD	1m	1786827060	202.36	202.36	202.36	202.36	30	2026-08-15 20:51:56.107188+00
HBAR/USD	1m	1786827060	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 20:51:56.107188+00
ETH/USD	1m	1786827060	1880.77	1880.77	1879.08	1879.08	30	2026-08-15 20:51:56.107188+00
LTC/USD	1m	1786827060	44.23	44.23	44.23	44.23	30	2026-08-15 20:51:56.107188+00
AAVE/USD	1m	1786827060	85.97	85.97	85.97	85.97	30	2026-08-15 20:51:56.107188+00
BTC/USD	1m	1786827060	63139.46	63139.46	63139.46	63139.46	30	2026-08-15 20:51:56.107188+00
APT/USD	1m	1786827060	0.54	0.54	0.54	0.54	30	2026-08-15 20:51:56.107188+00
SOL/USD	1m	1786827060	75.6	75.6	75.6	75.6	30	2026-08-15 20:51:56.107188+00
LINK/USD	1m	1786827060	9.557	9.557	9.557	9.557	30	2026-08-15 20:51:56.107188+00
DOT/USD	1m	1786827060	0.765	0.765	0.765	0.765	30	2026-08-15 20:51:56.107188+00
DOGE/USD	1m	1786827060	0.0698503	0.0698708	0.0698503	0.0698708	30	2026-08-15 20:51:56.107188+00
SUI/USD	1m	1786827060	0.68	0.68	0.68	0.68	30	2026-08-15 20:51:56.107188+00
AVAX/USD	1m	1786827060	6.491	6.491	6.491	6.491	30	2026-08-15 20:51:56.107188+00
XLM/USD	1m	1786827060	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 20:51:56.107188+00
XRP/USD	1m	1786827060	1.00159	1.00159	1.00159	1.00159	30	2026-08-15 20:51:56.107188+00
LINK/USD	1m	1786827120	9.557	9.557	9.557	9.557	30	2026-08-15 20:52:56.10805+00
DOGE/USD	1m	1786827120	0.0698708	0.0698708	0.0698708	0.0698708	30	2026-08-15 20:52:56.10805+00
XLM/USD	1m	1786827120	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 20:52:56.10805+00
BCH/USD	1m	1786827120	202.36	202.36	202.36	202.36	30	2026-08-15 20:52:56.10805+00
SOL/USD	1m	1786827120	75.6	75.6	75.375	75.375	30	2026-08-15 20:52:56.10805+00
LTC/USD	1m	1786827120	44.23	44.23	44.23	44.23	30	2026-08-15 20:52:56.10805+00
BTC/USD	1m	1786827120	63139.46	63139.46	63060.01	63060.03	30	2026-08-15 20:52:56.10805+00
AAVE/USD	1m	1786827120	85.97	85.97	85.97	85.97	30	2026-08-15 20:52:56.10805+00
ETH/USD	1m	1786827120	1884.46	1884.46	1884.46	1884.46	30	2026-08-15 20:52:56.10805+00
ADA/USD	1m	1786827120	0.1782	0.1782	0.1782	0.1782	30	2026-08-15 20:52:56.10805+00
HBAR/USD	1m	1786827120	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 20:52:56.10805+00
XRP/USD	1m	1786827120	1.00159	1.00159	1.00159	1.00159	30	2026-08-15 20:52:56.10805+00
APT/USD	1m	1786827120	0.54	0.54	0.54	0.54	30	2026-08-15 20:52:56.10805+00
SUI/USD	1m	1786827120	0.68	0.68	0.68	0.68	30	2026-08-15 20:52:56.10805+00
AVAX/USD	1m	1786827120	6.491	6.491	6.491	6.491	30	2026-08-15 20:52:56.10805+00
DOT/USD	1m	1786827120	0.765	0.765	0.765	0.765	30	2026-08-15 20:52:56.10805+00
NEAR/USD	1m	1786827120	1.63	1.63	1.63	1.63	30	2026-08-15 20:52:56.10805+00
POL/USD	1m	1786827120	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 20:52:56.10805+00
UNI/USD	1m	1786827120	3.241	3.241	3.241	3.241	30	2026-08-15 20:52:56.10805+00
DOT/USD	1m	1786827180	0.765	0.765	0.765	0.765	30	2026-08-15 20:53:56.107861+00
UNI/USD	1m	1786827180	3.241	3.241	3.241	3.241	30	2026-08-15 20:53:56.107861+00
APT/USD	1m	1786827180	0.54	0.54	0.54	0.54	30	2026-08-15 20:53:56.107861+00
POL/USD	1m	1786827180	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 20:53:56.107861+00
XLM/USD	1m	1786827180	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 20:53:56.107861+00
NEAR/USD	1m	1786827180	1.63	1.63	1.63	1.63	30	2026-08-15 20:53:56.107861+00
AVAX/USD	1m	1786827180	6.491	6.491	6.491	6.491	30	2026-08-15 20:53:56.107861+00
HBAR/USD	1m	1786827180	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 20:53:56.107861+00
LINK/USD	1m	1786827180	9.557	9.557	9.557	9.557	30	2026-08-15 20:53:56.107861+00
DOGE/USD	1m	1786827180	0.0698708	0.0698708	0.0698501	0.0698501	30	2026-08-15 20:53:56.107861+00
AAVE/USD	1m	1786827180	85.97	85.97	85.97	85.97	30	2026-08-15 20:53:56.107861+00
SUI/USD	1m	1786827180	0.68	0.68	0.68	0.68	30	2026-08-15 20:53:56.107861+00
BCH/USD	1m	1786827180	202.36	202.36	202.36	202.36	30	2026-08-15 20:53:56.107861+00
ADA/USD	1m	1786827180	0.1782	0.1782	0.1782	0.1782	30	2026-08-15 20:53:56.107861+00
SOL/USD	1m	1786827180	75.559	75.559	75.559	75.559	30	2026-08-15 20:53:56.107861+00
ETH/USD	1m	1786827180	1884.46	1884.46	1884.46	1884.46	31	2026-08-15 20:53:56.107861+00
LTC/USD	1m	1786827180	44.23	44.23	44.23	44.23	31	2026-08-15 20:53:56.107861+00
BTC/USD	1m	1786827180	63060.03	63060.03	63060.03	63060.03	31	2026-08-15 20:53:56.107861+00
XRP/USD	1m	1786827180	1.00159	1.00159	1.00159	1.00159	31	2026-08-15 20:53:56.107861+00
ADA/USD	1m	1786827240	0.1782	0.1782	0.1782	0.1782	30	2026-08-15 20:54:56.109765+00
ADA/USD	5m	1786827000	0.1782	0.1782	0.1782	0.1782	149	2026-08-15 20:54:56.109765+00
NEAR/USD	1m	1786827240	1.63	1.63	1.63	1.63	30	2026-08-15 20:54:56.109765+00
NEAR/USD	5m	1786827000	1.63	1.63	1.63	1.63	149	2026-08-15 20:54:56.109765+00
XRP/USD	1m	1786827240	1.00159	1.00159	1.00159	1.00159	29	2026-08-15 20:54:56.109765+00
XRP/USD	5m	1786827000	1.00159	1.00159	1.00159	1.00159	150	2026-08-15 20:54:56.109765+00
SOL/USD	1m	1786827240	75.559	75.559	75.559	75.559	30	2026-08-15 20:54:56.109765+00
SOL/USD	5m	1786827000	75.6	75.6	75.375	75.559	149	2026-08-15 20:54:56.109765+00
HBAR/USD	1m	1786827240	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 20:54:56.109765+00
HBAR/USD	5m	1786827000	0.06565	0.06565	0.06565	0.06565	150	2026-08-15 20:54:56.109765+00
AVAX/USD	1m	1786827240	6.491	6.491	6.491	6.491	30	2026-08-15 20:54:56.109765+00
AVAX/USD	5m	1786827000	6.491	6.491	6.491	6.491	150	2026-08-15 20:54:56.109765+00
LINK/USD	1m	1786827240	9.557	9.557	9.557	9.557	30	2026-08-15 20:54:56.109765+00
LINK/USD	5m	1786827000	9.557	9.557	9.557	9.557	149	2026-08-15 20:54:56.109765+00
DOGE/USD	1m	1786827240	0.0698501	0.0698501	0.0698501	0.0698501	30	2026-08-15 20:54:56.109765+00
DOGE/USD	5m	1786827000	0.0698568	0.0698708	0.0698501	0.0698501	149	2026-08-15 20:54:56.109765+00
BTC/USD	1m	1786827240	63060.03	63060.03	63060.03	63060.03	29	2026-08-15 20:54:56.109765+00
BTC/USD	5m	1786827000	63060.15	63139.46	63060.01	63060.03	150	2026-08-15 20:54:56.109765+00
SUI/USD	1m	1786827240	0.68	0.68	0.68	0.68	30	2026-08-15 20:54:56.109765+00
SUI/USD	5m	1786827000	0.68	0.68	0.68	0.68	150	2026-08-15 20:54:56.109765+00
UNI/USD	1m	1786827240	3.241	3.241	3.241	3.241	30	2026-08-15 20:54:56.109765+00
UNI/USD	5m	1786827000	3.244	3.244	3.241	3.241	149	2026-08-15 20:54:56.109765+00
POL/USD	1m	1786827240	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 20:54:56.109765+00
POL/USD	5m	1786827000	0.0756	0.0756	0.0756	0.0756	149	2026-08-15 20:54:56.109765+00
ETH/USD	1m	1786827240	1884.46	1884.46	1884.46	1884.46	29	2026-08-15 20:54:56.109765+00
ETH/USD	5m	1786827000	1880	1884.46	1879.08	1884.46	150	2026-08-15 20:54:56.109765+00
BCH/USD	1m	1786827240	202.36	202.36	202.36	202.36	30	2026-08-15 20:54:56.109765+00
BCH/USD	5m	1786827000	202.36	202.36	202.36	202.36	149	2026-08-15 20:54:56.109765+00
AAVE/USD	1m	1786827240	85.97	85.97	85.97	85.97	30	2026-08-15 20:54:56.109765+00
AAVE/USD	5m	1786827000	85.97	85.97	85.97	85.97	149	2026-08-15 20:54:56.109765+00
LTC/USD	1m	1786827240	44.23	44.23	44.23	44.23	29	2026-08-15 20:54:56.109765+00
LTC/USD	5m	1786827000	44.23	44.23	44.23	44.23	150	2026-08-15 20:54:56.109765+00
DOT/USD	1m	1786827240	0.765	0.765	0.765	0.765	30	2026-08-15 20:54:56.109765+00
DOT/USD	5m	1786827000	0.765	0.765	0.765	0.765	149	2026-08-15 20:54:56.109765+00
XLM/USD	1m	1786827240	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 20:54:56.109765+00
XLM/USD	5m	1786827000	0.15774	0.15774	0.15774	0.15774	149	2026-08-15 20:54:56.109765+00
APT/USD	1m	1786827240	0.54	0.54	0.54	0.54	30	2026-08-15 20:54:56.109765+00
APT/USD	5m	1786827000	0.54	0.54	0.54	0.54	149	2026-08-15 20:54:56.109765+00
ADA/USD	1m	1786827300	0.1782	0.1782	0.1782	0.1782	30	2026-08-15 20:55:56.108671+00
LINK/USD	1m	1786827300	9.557	9.557	9.557	9.557	30	2026-08-15 20:55:56.108671+00
DOGE/USD	1m	1786827300	0.0698501	0.0698501	0.0698501	0.0698501	30	2026-08-15 20:55:56.108671+00
APT/USD	1m	1786827300	0.54	0.54	0.54	0.54	30	2026-08-15 20:55:56.108671+00
XRP/USD	1m	1786827300	1.00159	1.00159	1.00159	1.00159	30	2026-08-15 20:55:56.108671+00
AVAX/USD	1m	1786827300	6.491	6.491	6.491	6.491	30	2026-08-15 20:55:56.108671+00
NEAR/USD	1m	1786827300	1.63	1.63	1.63	1.63	30	2026-08-15 20:55:56.108671+00
HBAR/USD	1m	1786827300	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 20:55:56.108671+00
POL/USD	1m	1786827300	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 20:55:56.108671+00
DOT/USD	1m	1786827300	0.765	0.765	0.765	0.765	30	2026-08-15 20:55:56.108671+00
UNI/USD	1m	1786827300	3.241	3.241	3.241	3.241	30	2026-08-15 20:55:56.108671+00
BTC/USD	1m	1786827300	63060.03	63202.66	63060.03	63202.66	30	2026-08-15 20:55:56.108671+00
LTC/USD	1m	1786827300	44.23	44.23	44.23	44.23	30	2026-08-15 20:55:56.108671+00
SUI/USD	1m	1786827300	0.68	0.68	0.68	0.68	30	2026-08-15 20:55:56.108671+00
SOL/USD	1m	1786827300	75.559	75.559	75.559	75.559	30	2026-08-15 20:55:56.108671+00
BCH/USD	1m	1786827300	202.36	202.36	202.36	202.36	30	2026-08-15 20:55:56.108671+00
XLM/USD	1m	1786827300	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 20:55:56.108671+00
AAVE/USD	1m	1786827300	85.97	85.97	85.97	85.97	30	2026-08-15 20:55:56.108671+00
ETH/USD	1m	1786827300	1884.46	1884.46	1884.46	1884.46	30	2026-08-15 20:55:56.108671+00
UNI/USD	1m	1786827360	3.241	3.241	3.241	3.241	30	2026-08-15 20:56:56.107822+00
AVAX/USD	1m	1786827360	6.491	6.491	6.491	6.491	30	2026-08-15 20:56:56.107822+00
LINK/USD	1m	1786827360	9.557	9.557	9.557	9.557	30	2026-08-15 20:56:56.107822+00
ADA/USD	1m	1786827360	0.1782	0.1782	0.1782	0.1782	30	2026-08-15 20:56:56.107822+00
AAVE/USD	1m	1786827360	85.97	85.97	85.97	85.97	30	2026-08-15 20:56:56.107822+00
XRP/USD	1m	1786827360	1.00159	1.00159	1.00159	1.00159	30	2026-08-15 20:56:56.107822+00
DOT/USD	1m	1786827360	0.765	0.765	0.765	0.765	30	2026-08-15 20:56:56.107822+00
LTC/USD	1m	1786827360	44.23	44.23	44.23	44.23	30	2026-08-15 20:56:56.107822+00
BCH/USD	1m	1786827360	202.36	202.36	202.36	202.36	30	2026-08-15 20:56:56.107822+00
DOGE/USD	1m	1786827360	0.0698501	0.0698501	0.0698501	0.0698501	30	2026-08-15 20:56:56.107822+00
POL/USD	1m	1786827360	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 20:56:56.107822+00
ETH/USD	1m	1786827360	1884.46	1884.46	1884.46	1884.46	30	2026-08-15 20:56:56.107822+00
APT/USD	1m	1786827360	0.54	0.54	0.54	0.54	30	2026-08-15 20:56:56.107822+00
SOL/USD	1m	1786827360	75.559	75.559	75.559	75.559	30	2026-08-15 20:56:56.107822+00
SUI/USD	1m	1786827360	0.68	0.68	0.68	0.68	30	2026-08-15 20:56:56.107822+00
XLM/USD	1m	1786827360	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 20:56:56.107822+00
BTC/USD	1m	1786827360	63202.66	63202.66	63202.66	63202.66	30	2026-08-15 20:56:56.107822+00
HBAR/USD	1m	1786827360	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 20:56:56.107822+00
NEAR/USD	1m	1786827360	1.63	1.63	1.63	1.63	30	2026-08-15 20:56:56.107822+00
DOT/USD	1m	1786827420	0.765	0.765	0.765	0.765	30	2026-08-15 20:57:56.107879+00
SOL/USD	1m	1786827420	75.559	75.559	75.559	75.559	30	2026-08-15 20:57:56.107879+00
UNI/USD	1m	1786827420	3.241	3.241	3.241	3.241	30	2026-08-15 20:57:56.107879+00
HBAR/USD	1m	1786827420	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 20:57:56.107879+00
SUI/USD	1m	1786827420	0.68	0.68	0.68	0.68	30	2026-08-15 20:57:56.107879+00
LINK/USD	1m	1786827420	9.557	9.557	9.557	9.557	30	2026-08-15 20:57:56.107879+00
NEAR/USD	1m	1786827420	1.63	1.63	1.63	1.63	30	2026-08-15 20:57:56.107879+00
POL/USD	1m	1786827420	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 20:57:56.107879+00
APT/USD	1m	1786827420	0.54	0.54	0.54	0.54	30	2026-08-15 20:57:56.107879+00
AAVE/USD	1m	1786827420	85.97	85.97	85.97	85.97	30	2026-08-15 20:57:56.107879+00
AVAX/USD	1m	1786827420	6.491	6.491	6.491	6.491	30	2026-08-15 20:57:56.107879+00
XLM/USD	1m	1786827420	0.15774	0.15774	0.15774	0.15774	31	2026-08-15 20:57:56.107879+00
ADA/USD	1m	1786827420	0.1782	0.1782	0.1782	0.1782	31	2026-08-15 20:57:56.107879+00
ETH/USD	1m	1786827420	1884.46	1884.46	1884.46	1884.46	31	2026-08-15 20:57:56.107879+00
BCH/USD	1m	1786827420	202.36	202.36	202.36	202.36	31	2026-08-15 20:57:56.107879+00
LTC/USD	1m	1786827420	44.23	44.23	44.23	44.23	31	2026-08-15 20:57:56.107879+00
DOGE/USD	1m	1786827420	0.0698501	0.0698501	0.0698501	0.0698501	31	2026-08-15 20:57:56.107879+00
XRP/USD	1m	1786827420	1.00159	1.00159	1.00159	1.00159	31	2026-08-15 20:57:56.107879+00
BTC/USD	1m	1786827420	63202.66	63202.66	63202.66	63202.66	31	2026-08-15 20:57:56.107879+00
XRP/USD	1m	1786827480	1.00159	1.00159	1.00159	1.00159	29	2026-08-15 20:58:56.109407+00
DOGE/USD	1m	1786827480	0.0698501	0.0698501	0.0698501	0.0698501	29	2026-08-15 20:58:56.109407+00
BTC/USD	1m	1786827480	63202.66	63202.66	63100.21	63100.21	29	2026-08-15 20:58:56.109407+00
DOT/USD	1m	1786827480	0.765	0.765	0.765	0.765	30	2026-08-15 20:58:56.109407+00
ETH/USD	1m	1786827480	1884.46	1884.46	1884.46	1884.46	29	2026-08-15 20:58:56.109407+00
LINK/USD	1m	1786827480	9.557	9.557	9.557	9.557	30	2026-08-15 20:58:56.109407+00
SUI/USD	1m	1786827480	0.68	0.68	0.68	0.68	30	2026-08-15 20:58:56.109407+00
NEAR/USD	1m	1786827480	1.63	1.63	1.63	1.63	30	2026-08-15 20:58:56.109407+00
BCH/USD	1m	1786827480	202.36	202.36	202.36	202.36	29	2026-08-15 20:58:56.109407+00
ADA/USD	1m	1786827480	0.1782	0.1782	0.1782	0.1782	29	2026-08-15 20:58:56.109407+00
LTC/USD	1m	1786827480	44.23	44.23	44.23	44.23	29	2026-08-15 20:58:56.109407+00
XLM/USD	1m	1786827480	0.15774	0.15774	0.15774	0.15774	29	2026-08-15 20:58:56.109407+00
AVAX/USD	1m	1786827480	6.491	6.491	6.491	6.491	31	2026-08-15 20:58:56.109407+00
AAVE/USD	1m	1786827480	85.97	85.97	85.97	85.97	31	2026-08-15 20:58:56.109407+00
HBAR/USD	1m	1786827480	0.06565	0.06565	0.06565	0.06565	31	2026-08-15 20:58:56.109407+00
UNI/USD	1m	1786827480	3.241	3.241	3.241	3.241	31	2026-08-15 20:58:56.109407+00
APT/USD	1m	1786827480	0.54	0.54	0.54	0.54	31	2026-08-15 20:58:56.109407+00
SOL/USD	1m	1786827480	75.559	75.559	75.559	75.559	31	2026-08-15 20:58:56.109407+00
POL/USD	1m	1786827480	0.0756	0.0756	0.0756	0.0756	31	2026-08-15 20:58:56.109407+00
AAVE/USD	1m	1786827540	85.97	85.97	85.97	85.97	29	2026-08-15 20:59:56.118445+00
AAVE/USD	5m	1786827300	85.97	85.97	85.97	85.97	150	2026-08-15 20:59:56.118445+00
AAVE/USD	15m	1786826700	86.34	86.34	85.97	85.97	450	2026-08-15 20:59:56.118445+00
AAVE/USD	30m	1786825800	86.34	86.34	85.97	85.97	666	2026-08-15 20:59:56.118445+00
AAVE/USD	1h	1786824000	86.34	86.34	85.97	85.97	666	2026-08-15 20:59:56.118445+00
DOGE/USD	1m	1786827540	0.0698501	0.0698501	0.0698501	0.0698501	30	2026-08-15 20:59:56.118445+00
DOGE/USD	5m	1786827300	0.0698501	0.0698501	0.0698501	0.0698501	150	2026-08-15 20:59:56.118445+00
DOGE/USD	15m	1786826700	0.0698568	0.0698708	0.0698501	0.0698501	450	2026-08-15 20:59:56.118445+00
DOGE/USD	30m	1786825800	0.0698528	0.0698708	0.0698307	0.0698501	666	2026-08-15 20:59:56.118445+00
DOGE/USD	1h	1786824000	0.0698528	0.0698708	0.0698307	0.0698501	666	2026-08-15 20:59:56.118445+00
BTC/USD	1m	1786827540	63100.21	63100.21	63100.21	63100.21	30	2026-08-15 20:59:56.118445+00
BTC/USD	5m	1786827300	63060.03	63202.66	63060.03	63100.21	150	2026-08-15 20:59:56.118445+00
BTC/USD	15m	1786826700	63147.71	63202.66	63054.06	63100.21	450	2026-08-15 20:59:56.118445+00
BTC/USD	30m	1786825800	63149.72	63202.66	63054.03	63100.21	666	2026-08-15 20:59:56.118445+00
BTC/USD	1h	1786824000	63149.72	63202.66	63054.03	63100.21	666	2026-08-15 20:59:56.118445+00
XLM/USD	1m	1786827540	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 20:59:56.118445+00
XLM/USD	5m	1786827300	0.15774	0.15774	0.15774	0.15774	150	2026-08-15 20:59:56.118445+00
XLM/USD	15m	1786826700	0.15774	0.15774	0.15774	0.15774	450	2026-08-15 20:59:56.118445+00
XLM/USD	30m	1786825800	0.15774	0.15774	0.15774	0.15774	666	2026-08-15 20:59:56.118445+00
XLM/USD	1h	1786824000	0.15774	0.15774	0.15774	0.15774	666	2026-08-15 20:59:56.118445+00
LINK/USD	1m	1786827540	9.557	9.557	9.543	9.543	30	2026-08-15 20:59:56.118445+00
LINK/USD	5m	1786827300	9.557	9.557	9.543	9.543	150	2026-08-15 20:59:56.118445+00
LINK/USD	15m	1786826700	9.557	9.557	9.543	9.543	450	2026-08-15 20:59:56.118445+00
LINK/USD	30m	1786825800	9.552	9.557	9.543	9.543	666	2026-08-15 20:59:56.118445+00
LINK/USD	1h	1786824000	9.552	9.557	9.543	9.543	666	2026-08-15 20:59:56.118445+00
POL/USD	1m	1786827540	0.0756	0.0756	0.0756	0.0756	29	2026-08-15 20:59:56.118445+00
POL/USD	5m	1786827300	0.0756	0.0756	0.0756	0.0756	150	2026-08-15 20:59:56.118445+00
POL/USD	15m	1786826700	0.0756	0.0756	0.0756	0.0756	450	2026-08-15 20:59:56.118445+00
POL/USD	30m	1786825800	0.0756	0.0756	0.0756	0.0756	666	2026-08-15 20:59:56.118445+00
POL/USD	1h	1786824000	0.0756	0.0756	0.0756	0.0756	666	2026-08-15 20:59:56.118445+00
SOL/USD	1m	1786827540	75.559	75.559	75.559	75.559	29	2026-08-15 20:59:56.118445+00
SOL/USD	5m	1786827300	75.559	75.559	75.559	75.559	150	2026-08-15 20:59:56.118445+00
SOL/USD	15m	1786826700	75.589	75.697	75.375	75.559	450	2026-08-15 20:59:56.118445+00
SOL/USD	30m	1786825800	75.327	75.697	75.327	75.559	666	2026-08-15 20:59:56.118445+00
SOL/USD	1h	1786824000	75.327	75.697	75.327	75.559	666	2026-08-15 20:59:56.118445+00
ADA/USD	1m	1786827540	0.1782	0.1782	0.1782	0.1782	30	2026-08-15 20:59:56.118445+00
ADA/USD	5m	1786827300	0.1782	0.1782	0.1782	0.1782	150	2026-08-15 20:59:56.118445+00
ADA/USD	15m	1786826700	0.178	0.1782	0.178	0.1782	450	2026-08-15 20:59:56.118445+00
ADA/USD	30m	1786825800	0.178	0.1782	0.178	0.1782	666	2026-08-15 20:59:56.118445+00
ADA/USD	1h	1786824000	0.178	0.1782	0.178	0.1782	666	2026-08-15 20:59:56.118445+00
AVAX/USD	1m	1786827540	6.491	6.491	6.491	6.491	29	2026-08-15 20:59:56.118445+00
AVAX/USD	5m	1786827300	6.491	6.491	6.491	6.491	150	2026-08-15 20:59:56.118445+00
AVAX/USD	15m	1786826700	6.491	6.491	6.491	6.491	450	2026-08-15 20:59:56.118445+00
AVAX/USD	30m	1786825800	6.525	6.525	6.491	6.491	666	2026-08-15 20:59:56.118445+00
AVAX/USD	1h	1786824000	6.525	6.525	6.491	6.491	666	2026-08-15 20:59:56.118445+00
BCH/USD	1m	1786827540	202.36	202.36	202.36	202.36	30	2026-08-15 20:59:56.118445+00
BCH/USD	5m	1786827300	202.36	202.36	202.36	202.36	150	2026-08-15 20:59:56.118445+00
BCH/USD	15m	1786826700	202.36	202.36	202.36	202.36	450	2026-08-15 20:59:56.118445+00
BCH/USD	30m	1786825800	203.4	203.4	202.36	202.36	666	2026-08-15 20:59:56.118445+00
BCH/USD	1h	1786824000	203.4	203.4	202.36	202.36	666	2026-08-15 20:59:56.118445+00
APT/USD	1m	1786827540	0.54	0.54	0.54	0.54	29	2026-08-15 20:59:56.118445+00
APT/USD	5m	1786827300	0.54	0.54	0.54	0.54	150	2026-08-15 20:59:56.118445+00
APT/USD	15m	1786826700	0.54	0.54	0.54	0.54	450	2026-08-15 20:59:56.118445+00
APT/USD	30m	1786825800	0.54	0.54	0.54	0.54	666	2026-08-15 20:59:56.118445+00
APT/USD	1h	1786824000	0.54	0.54	0.54	0.54	666	2026-08-15 20:59:56.118445+00
UNI/USD	1m	1786827540	3.241	3.241	3.241	3.241	29	2026-08-15 20:59:56.118445+00
UNI/USD	5m	1786827300	3.241	3.241	3.241	3.241	150	2026-08-15 20:59:56.118445+00
UNI/USD	15m	1786826700	3.235	3.244	3.235	3.241	450	2026-08-15 20:59:56.118445+00
UNI/USD	30m	1786825800	3.234	3.244	3.234	3.241	666	2026-08-15 20:59:56.118445+00
UNI/USD	1h	1786824000	3.234	3.244	3.234	3.241	666	2026-08-15 20:59:56.118445+00
DOT/USD	1m	1786827540	0.765	0.765	0.765	0.765	30	2026-08-15 20:59:56.118445+00
DOT/USD	5m	1786827300	0.765	0.765	0.765	0.765	150	2026-08-15 20:59:56.118445+00
DOT/USD	15m	1786826700	0.765	0.765	0.765	0.765	450	2026-08-15 20:59:56.118445+00
DOT/USD	30m	1786825800	0.765	0.765	0.765	0.765	666	2026-08-15 20:59:56.118445+00
DOT/USD	1h	1786824000	0.765	0.765	0.765	0.765	666	2026-08-15 20:59:56.118445+00
NEAR/USD	1m	1786827540	1.63	1.63	1.63	1.63	30	2026-08-15 20:59:56.118445+00
NEAR/USD	5m	1786827300	1.63	1.63	1.63	1.63	150	2026-08-15 20:59:56.118445+00
NEAR/USD	15m	1786826700	1.63	1.63	1.63	1.63	450	2026-08-15 20:59:56.118445+00
NEAR/USD	30m	1786825800	1.63	1.63	1.63	1.63	666	2026-08-15 20:59:56.118445+00
NEAR/USD	1h	1786824000	1.63	1.63	1.63	1.63	666	2026-08-15 20:59:56.118445+00
HBAR/USD	1m	1786827540	0.06565	0.06565	0.06565	0.06565	29	2026-08-15 20:59:56.118445+00
HBAR/USD	5m	1786827300	0.06565	0.06565	0.06565	0.06565	150	2026-08-15 20:59:56.118445+00
HBAR/USD	15m	1786826700	0.06565	0.06565	0.06565	0.06565	450	2026-08-15 20:59:56.118445+00
HBAR/USD	30m	1786825800	0.06565	0.06565	0.06565	0.06565	666	2026-08-15 20:59:56.118445+00
HBAR/USD	1h	1786824000	0.06565	0.06565	0.06565	0.06565	666	2026-08-15 20:59:56.118445+00
ETH/USD	1m	1786827540	1884.46	1884.46	1884.46	1884.46	30	2026-08-15 20:59:56.118445+00
ETH/USD	5m	1786827300	1884.46	1884.46	1884.46	1884.46	150	2026-08-15 20:59:56.118445+00
ETH/USD	15m	1786826700	1884.85	1884.85	1879.08	1884.46	450	2026-08-15 20:59:56.118445+00
ETH/USD	30m	1786825800	1882.91	1884.85	1879.08	1884.46	666	2026-08-15 20:59:56.118445+00
ETH/USD	1h	1786824000	1882.91	1884.85	1879.08	1884.46	666	2026-08-15 20:59:56.118445+00
LTC/USD	1m	1786827540	44.23	44.23	44.23	44.23	30	2026-08-15 20:59:56.118445+00
LTC/USD	5m	1786827300	44.23	44.23	44.23	44.23	150	2026-08-15 20:59:56.118445+00
LTC/USD	15m	1786826700	44.23	44.23	44.23	44.23	450	2026-08-15 20:59:56.118445+00
LTC/USD	30m	1786825800	44.23	44.23	44.23	44.23	666	2026-08-15 20:59:56.118445+00
LTC/USD	1h	1786824000	44.23	44.23	44.23	44.23	666	2026-08-15 20:59:56.118445+00
XRP/USD	1m	1786827540	1.00159	1.00159	1.00159	1.00159	30	2026-08-15 20:59:56.118445+00
XRP/USD	5m	1786827300	1.00159	1.00159	1.00159	1.00159	150	2026-08-15 20:59:56.118445+00
XRP/USD	15m	1786826700	1.00159	1.00159	1.00159	1.00159	450	2026-08-15 20:59:56.118445+00
XRP/USD	30m	1786825800	1.00159	1.00159	1.00159	1.00159	666	2026-08-15 20:59:56.118445+00
XRP/USD	1h	1786824000	1.00159	1.00159	1.00159	1.00159	666	2026-08-15 20:59:56.118445+00
SUI/USD	1m	1786827540	0.68	0.68	0.68	0.68	31	2026-08-15 20:59:56.118445+00
SUI/USD	5m	1786827300	0.68	0.68	0.68	0.68	151	2026-08-15 20:59:56.118445+00
SUI/USD	15m	1786826700	0.68	0.68	0.68	0.68	450	2026-08-15 20:59:56.118445+00
SUI/USD	30m	1786825800	0.68	0.68	0.68	0.68	667	2026-08-15 20:59:56.118445+00
SUI/USD	1h	1786824000	0.68	0.68	0.68	0.68	667	2026-08-15 20:59:56.118445+00
LTC/USD	1m	1786827600	44.23	44.23	44.23	44.23	30	2026-08-15 21:00:56.108942+00
AAVE/USD	1m	1786827600	85.97	85.97	85.97	85.97	30	2026-08-15 21:00:56.108942+00
BTC/USD	1m	1786827600	63100.21	63100.21	63100.21	63100.21	30	2026-08-15 21:00:56.108942+00
APT/USD	1m	1786827600	0.54	0.54	0.54	0.54	30	2026-08-15 21:00:56.108942+00
NEAR/USD	1m	1786827600	1.63	1.63	1.63	1.63	30	2026-08-15 21:00:56.108942+00
DOT/USD	1m	1786827600	0.765	0.765	0.765	0.765	30	2026-08-15 21:00:56.108942+00
LINK/USD	1m	1786827600	9.543	9.566	9.543	9.566	30	2026-08-15 21:00:56.108942+00
POL/USD	1m	1786827600	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:00:56.108942+00
DOGE/USD	1m	1786827600	0.0698501	0.0698501	0.0698501	0.0698501	30	2026-08-15 21:00:56.108942+00
XLM/USD	1m	1786827600	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:00:56.108942+00
AVAX/USD	1m	1786827600	6.491	6.491	6.491	6.491	30	2026-08-15 21:00:56.108942+00
ETH/USD	1m	1786827600	1884.46	1884.46	1884.46	1884.46	30	2026-08-15 21:00:56.108942+00
UNI/USD	1m	1786827600	3.241	3.241	3.241	3.241	30	2026-08-15 21:00:56.108942+00
HBAR/USD	1m	1786827600	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 21:00:56.108942+00
ADA/USD	1m	1786827600	0.1782	0.1782	0.1782	0.1782	30	2026-08-15 21:00:56.108942+00
SOL/USD	1m	1786827600	75.559	75.559	75.559	75.559	30	2026-08-15 21:00:56.108942+00
XRP/USD	1m	1786827600	1.00159	1.00159	1.00159	1.00159	30	2026-08-15 21:00:56.108942+00
BCH/USD	1m	1786827600	202.36	202.36	202.36	202.36	30	2026-08-15 21:00:56.108942+00
SUI/USD	1m	1786827600	0.68	0.68	0.68	0.68	30	2026-08-15 21:00:56.108942+00
LINK/USD	1m	1786827660	9.566	9.566	9.566	9.566	30	2026-08-15 21:01:56.108626+00
BTC/USD	1m	1786827660	63100.21	63100.21	63100.21	63100.21	30	2026-08-15 21:01:56.108626+00
BCH/USD	1m	1786827660	202.36	202.36	202.36	202.36	30	2026-08-15 21:01:56.108626+00
ETH/USD	1m	1786827660	1884.46	1884.46	1884.46	1884.46	30	2026-08-15 21:01:56.108626+00
XRP/USD	1m	1786827660	1.00159	1.00159	1.00159	1.00159	30	2026-08-15 21:01:56.108626+00
SUI/USD	1m	1786827660	0.68	0.68	0.68	0.68	29	2026-08-15 21:01:56.108626+00
NEAR/USD	1m	1786827660	1.63	1.63	1.63	1.63	30	2026-08-15 21:01:56.108626+00
LTC/USD	1m	1786827660	44.23	44.23	44.23	44.23	30	2026-08-15 21:01:56.108626+00
DOGE/USD	1m	1786827660	0.0698501	0.0698501	0.0698501	0.0698501	30	2026-08-15 21:01:56.108626+00
APT/USD	1m	1786827660	0.54	0.54	0.54	0.54	31	2026-08-15 21:01:56.108626+00
AVAX/USD	1m	1786827660	6.491	6.523	6.491	6.523	31	2026-08-15 21:01:56.108626+00
UNI/USD	1m	1786827660	3.241	3.241	3.238	3.238	31	2026-08-15 21:01:56.108626+00
XLM/USD	1m	1786827660	0.15774	0.15774	0.15774	0.15774	31	2026-08-15 21:01:56.108626+00
DOT/USD	1m	1786827660	0.765	0.765	0.765	0.765	31	2026-08-15 21:01:56.108626+00
HBAR/USD	1m	1786827660	0.06565	0.06565	0.06565	0.06565	31	2026-08-15 21:01:56.108626+00
ADA/USD	1m	1786827660	0.1782	0.1782	0.1782	0.1782	31	2026-08-15 21:01:56.108626+00
SOL/USD	1m	1786827660	75.559	75.559	75.559	75.559	31	2026-08-15 21:01:56.108626+00
POL/USD	1m	1786827660	0.0756	0.0756	0.0756	0.0756	31	2026-08-15 21:01:56.108626+00
AAVE/USD	1m	1786827660	85.97	85.97	85.97	85.97	31	2026-08-15 21:01:56.108626+00
HBAR/USD	1m	1786827720	0.06565	0.06565	0.06565	0.06565	29	2026-08-15 21:02:56.107673+00
AAVE/USD	1m	1786827720	85.97	85.97	85.97	85.97	29	2026-08-15 21:02:56.107673+00
DOT/USD	1m	1786827720	0.765	0.765	0.765	0.765	29	2026-08-15 21:02:56.107673+00
SOL/USD	1m	1786827720	75.559	75.7	75.559	75.7	29	2026-08-15 21:02:56.107673+00
APT/USD	1m	1786827720	0.54	0.54	0.54	0.54	29	2026-08-15 21:02:56.107673+00
POL/USD	1m	1786827720	0.0756	0.0756	0.0756	0.0756	29	2026-08-15 21:02:56.107673+00
SUI/USD	1m	1786827720	0.68	0.68	0.68	0.68	30	2026-08-15 21:02:56.107673+00
AVAX/USD	1m	1786827720	6.523	6.523	6.523	6.523	29	2026-08-15 21:02:56.107673+00
ADA/USD	1m	1786827720	0.1782	0.1782	0.1782	0.1782	29	2026-08-15 21:02:56.107673+00
UNI/USD	1m	1786827720	3.238	3.238	3.238	3.238	29	2026-08-15 21:02:56.107673+00
BTC/USD	1m	1786827720	63100.21	63100.21	63100.21	63100.21	31	2026-08-15 21:02:56.107673+00
XRP/USD	1m	1786827720	1.00159	1.00159	1.00159	1.00159	31	2026-08-15 21:02:56.107673+00
LTC/USD	1m	1786827720	44.23	44.23	44.23	44.23	31	2026-08-15 21:02:56.107673+00
XLM/USD	1m	1786827720	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:02:56.107673+00
NEAR/USD	1m	1786827720	1.63	1.63	1.63	1.63	31	2026-08-15 21:02:56.107673+00
BCH/USD	1m	1786827720	202.36	202.36	202.36	202.36	31	2026-08-15 21:02:56.107673+00
ETH/USD	1m	1786827720	1884.46	1884.46	1884.46	1884.46	31	2026-08-15 21:02:56.107673+00
DOGE/USD	1m	1786827720	0.0698501	0.0698501	0.0698501	0.0698501	31	2026-08-15 21:02:56.107673+00
LINK/USD	1m	1786827720	9.566	9.566	9.566	9.566	31	2026-08-15 21:02:56.107673+00
SOL/USD	1m	1786827780	75.7	75.7	75.7	75.7	30	2026-08-15 21:03:56.108524+00
POL/USD	1m	1786827780	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:03:56.108524+00
HBAR/USD	1m	1786827780	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 21:03:56.108524+00
AVAX/USD	1m	1786827780	6.523	6.523	6.523	6.523	30	2026-08-15 21:03:56.108524+00
SUI/USD	1m	1786827780	0.68	0.68	0.68	0.68	30	2026-08-15 21:03:56.108524+00
NEAR/USD	1m	1786827780	1.63	1.63	1.63	1.63	30	2026-08-15 21:03:56.108524+00
APT/USD	1m	1786827780	0.54	0.54	0.54	0.54	31	2026-08-15 21:03:56.108524+00
LINK/USD	1m	1786827780	9.566	9.566	9.566	9.566	30	2026-08-15 21:03:56.108524+00
XRP/USD	1m	1786827780	1.00159	1.00159	1.00159	1.00159	30	2026-08-15 21:03:56.108524+00
BTC/USD	1m	1786827780	63100.21	63100.21	63100.21	63100.21	30	2026-08-15 21:03:56.108524+00
DOT/USD	1m	1786827780	0.765	0.765	0.765	0.765	31	2026-08-15 21:03:56.108524+00
ADA/USD	1m	1786827780	0.1782	0.1782	0.178	0.178	31	2026-08-15 21:03:56.108524+00
ETH/USD	1m	1786827780	1884.46	1884.46	1884.46	1884.46	30	2026-08-15 21:03:56.108524+00
XLM/USD	1m	1786827780	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:03:56.108524+00
BCH/USD	1m	1786827780	202.36	202.36	202.36	202.36	30	2026-08-15 21:03:56.108524+00
LTC/USD	1m	1786827780	44.23	44.23	44.23	44.23	30	2026-08-15 21:03:56.108524+00
DOGE/USD	1m	1786827780	0.0698501	0.0698501	0.0698501	0.0698501	30	2026-08-15 21:03:56.108524+00
UNI/USD	1m	1786827780	3.238	3.238	3.238	3.238	31	2026-08-15 21:03:56.108524+00
AAVE/USD	1m	1786827780	85.97	85.97	85.97	85.97	31	2026-08-15 21:03:56.108524+00
SOL/USD	1m	1786827840	75.7	75.7	75.7	75.7	30	2026-08-15 21:04:56.109354+00
SOL/USD	5m	1786827600	75.559	75.7	75.559	75.7	150	2026-08-15 21:04:56.109354+00
DOT/USD	1m	1786827840	0.765	0.765	0.765	0.765	29	2026-08-15 21:04:56.109354+00
DOT/USD	5m	1786827600	0.765	0.765	0.765	0.765	150	2026-08-15 21:04:56.109354+00
LTC/USD	1m	1786827840	44.23	44.23	44.23	44.23	29	2026-08-15 21:04:56.109354+00
LTC/USD	5m	1786827600	44.23	44.23	44.23	44.23	150	2026-08-15 21:04:56.109354+00
APT/USD	1m	1786827840	0.54	0.54	0.54	0.54	29	2026-08-15 21:04:56.109354+00
APT/USD	5m	1786827600	0.54	0.54	0.54	0.54	150	2026-08-15 21:04:56.109354+00
ETH/USD	1m	1786827840	1884.46	1884.46	1884.46	1884.46	29	2026-08-15 21:04:56.109354+00
ETH/USD	5m	1786827600	1884.46	1884.46	1884.46	1884.46	150	2026-08-15 21:04:56.109354+00
LINK/USD	1m	1786827840	9.566	9.566	9.566	9.566	29	2026-08-15 21:04:56.109354+00
LINK/USD	5m	1786827600	9.543	9.566	9.543	9.566	150	2026-08-15 21:04:56.109354+00
XLM/USD	1m	1786827840	0.15774	0.15774	0.15774	0.15774	29	2026-08-15 21:04:56.109354+00
XLM/USD	5m	1786827600	0.15774	0.15774	0.15774	0.15774	150	2026-08-15 21:04:56.109354+00
AVAX/USD	1m	1786827840	6.523	6.523	6.523	6.523	30	2026-08-15 21:04:56.109354+00
AVAX/USD	5m	1786827600	6.491	6.523	6.491	6.523	150	2026-08-15 21:04:56.109354+00
ADA/USD	1m	1786827840	0.178	0.178	0.178	0.178	29	2026-08-15 21:04:56.109354+00
ADA/USD	5m	1786827600	0.1782	0.1782	0.178	0.178	150	2026-08-15 21:04:56.109354+00
XRP/USD	1m	1786827840	1.00159	1.00159	1.00159	1.00159	29	2026-08-15 21:04:56.109354+00
XRP/USD	5m	1786827600	1.00159	1.00159	1.00159	1.00159	150	2026-08-15 21:04:56.109354+00
DOGE/USD	1m	1786827840	0.0698501	0.0698501	0.0698501	0.0698501	29	2026-08-15 21:04:56.109354+00
DOGE/USD	5m	1786827600	0.0698501	0.0698501	0.0698501	0.0698501	150	2026-08-15 21:04:56.109354+00
POL/USD	1m	1786827840	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:04:56.109354+00
POL/USD	5m	1786827600	0.0756	0.0756	0.0756	0.0756	150	2026-08-15 21:04:56.109354+00
BCH/USD	1m	1786827840	202.36	202.36	202.36	202.36	29	2026-08-15 21:04:56.109354+00
BCH/USD	5m	1786827600	202.36	202.36	202.36	202.36	150	2026-08-15 21:04:56.109354+00
BTC/USD	1m	1786827840	63100.21	63100.21	63100.21	63100.21	29	2026-08-15 21:04:56.109354+00
BTC/USD	5m	1786827600	63100.21	63100.21	63100.21	63100.21	150	2026-08-15 21:04:56.109354+00
NEAR/USD	1m	1786827840	1.63	1.63	1.63	1.63	29	2026-08-15 21:04:56.109354+00
NEAR/USD	5m	1786827600	1.63	1.63	1.63	1.63	150	2026-08-15 21:04:56.109354+00
HBAR/USD	1m	1786827840	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 21:04:56.109354+00
HBAR/USD	5m	1786827600	0.06565	0.06565	0.06565	0.06565	150	2026-08-15 21:04:56.109354+00
AAVE/USD	1m	1786827840	85.97	86.48	85.97	86.48	29	2026-08-15 21:04:56.109354+00
AAVE/USD	5m	1786827600	85.97	86.48	85.97	86.48	150	2026-08-15 21:04:56.109354+00
UNI/USD	1m	1786827840	3.238	3.238	3.238	3.238	29	2026-08-15 21:04:56.109354+00
UNI/USD	5m	1786827600	3.241	3.241	3.238	3.238	150	2026-08-15 21:04:56.109354+00
SUI/USD	1m	1786827840	0.68	0.68	0.68	0.68	31	2026-08-15 21:04:56.109354+00
SUI/USD	5m	1786827600	0.68	0.68	0.68	0.68	150	2026-08-15 21:04:56.109354+00
HBAR/USD	1m	1786827900	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 21:05:56.109101+00
POL/USD	1m	1786827900	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:05:56.109101+00
SUI/USD	1m	1786827900	0.68	0.68	0.68	0.68	29	2026-08-15 21:05:56.109101+00
AVAX/USD	1m	1786827900	6.523	6.523	6.523	6.523	30	2026-08-15 21:05:56.109101+00
NEAR/USD	1m	1786827900	1.63	1.63	1.63	1.63	31	2026-08-15 21:05:56.109101+00
SOL/USD	1m	1786827900	75.7	75.7	75.7	75.7	31	2026-08-15 21:05:56.109101+00
LINK/USD	1m	1786827900	9.566	9.566	9.566	9.566	31	2026-08-15 21:05:56.109101+00
BTC/USD	1m	1786827900	63100.21	63100.21	63100.21	63100.21	31	2026-08-15 21:05:56.109101+00
APT/USD	1m	1786827900	0.54	0.54	0.539	0.539	31	2026-08-15 21:05:56.109101+00
LTC/USD	1m	1786827900	44.23	44.23	44.23	44.23	31	2026-08-15 21:05:56.109101+00
DOT/USD	1m	1786827900	0.765	0.765	0.765	0.765	31	2026-08-15 21:05:56.109101+00
ETH/USD	1m	1786827900	1884.46	1884.46	1884.46	1884.46	31	2026-08-15 21:05:56.109101+00
ADA/USD	1m	1786827900	0.178	0.178	0.178	0.178	31	2026-08-15 21:05:56.109101+00
XLM/USD	1m	1786827900	0.15774	0.15774	0.15774	0.15774	31	2026-08-15 21:05:56.109101+00
UNI/USD	1m	1786827900	3.238	3.238	3.238	3.238	31	2026-08-15 21:05:56.109101+00
DOGE/USD	1m	1786827900	0.0698501	0.0698501	0.0698501	0.0698501	31	2026-08-15 21:05:56.109101+00
BCH/USD	1m	1786827900	202.36	202.36	202.36	202.36	31	2026-08-15 21:05:56.109101+00
XRP/USD	1m	1786827900	1.00159	1.00159	1.00159	1.00159	31	2026-08-15 21:05:56.109101+00
AAVE/USD	1m	1786827900	86.48	86.48	86.48	86.48	31	2026-08-15 21:05:56.109101+00
HBAR/USD	1m	1786827960	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 21:06:56.108445+00
ETH/USD	1m	1786827960	1884.46	1884.46	1882.25	1882.25	29	2026-08-15 21:06:56.108445+00
BCH/USD	1m	1786827960	202.36	202.36	202.36	202.36	29	2026-08-15 21:06:56.108445+00
LINK/USD	1m	1786827960	9.566	9.566	9.566	9.566	29	2026-08-15 21:06:56.108445+00
NEAR/USD	1m	1786827960	1.63	1.63	1.63	1.63	29	2026-08-15 21:06:56.108445+00
APT/USD	1m	1786827960	0.539	0.539	0.539	0.539	29	2026-08-15 21:06:56.108445+00
POL/USD	1m	1786827960	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:06:56.108445+00
XLM/USD	1m	1786827960	0.15774	0.15774	0.15774	0.15774	29	2026-08-15 21:06:56.108445+00
SOL/USD	1m	1786827960	75.7	75.7	75.7	75.7	29	2026-08-15 21:06:56.108445+00
BTC/USD	1m	1786827960	63100.21	63100.21	63100.21	63100.21	29	2026-08-15 21:06:56.108445+00
UNI/USD	1m	1786827960	3.238	3.238	3.238	3.238	29	2026-08-15 21:06:56.108445+00
SUI/USD	1m	1786827960	0.68	0.68	0.68	0.68	30	2026-08-15 21:06:56.108445+00
DOT/USD	1m	1786827960	0.765	0.766	0.765	0.766	29	2026-08-15 21:06:56.108445+00
AAVE/USD	1m	1786827960	86.48	86.48	86.48	86.48	29	2026-08-15 21:06:56.108445+00
DOGE/USD	1m	1786827960	0.0698501	0.0698501	0.0698501	0.0698501	29	2026-08-15 21:06:56.108445+00
ADA/USD	1m	1786827960	0.178	0.178	0.178	0.178	29	2026-08-15 21:06:56.108445+00
AVAX/USD	1m	1786827960	6.523	6.523	6.523	6.523	30	2026-08-15 21:06:56.108445+00
XRP/USD	1m	1786827960	1.00159	1.00159	1.00159	1.00159	29	2026-08-15 21:06:56.108445+00
LTC/USD	1m	1786827960	44.23	44.23	44.23	44.23	29	2026-08-15 21:06:56.108445+00
XRP/USD	1m	1786828020	1.00159	1.00219	1.00159	1.00219	30	2026-08-15 21:07:56.10813+00
ADA/USD	1m	1786828020	0.178	0.178	0.178	0.178	30	2026-08-15 21:07:56.10813+00
DOT/USD	1m	1786828020	0.766	0.766	0.766	0.766	30	2026-08-15 21:07:56.10813+00
XLM/USD	1m	1786828020	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:07:56.10813+00
SUI/USD	1m	1786828020	0.68	0.68	0.68	0.68	30	2026-08-15 21:07:56.10813+00
POL/USD	1m	1786828020	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:07:56.10813+00
APT/USD	1m	1786828020	0.539	0.539	0.539	0.539	30	2026-08-15 21:07:56.10813+00
ETH/USD	1m	1786828020	1882.25	1882.25	1881.01	1881.01	30	2026-08-15 21:07:56.10813+00
BTC/USD	1m	1786828020	63100.21	63100.21	63100.21	63100.21	30	2026-08-15 21:07:56.10813+00
AVAX/USD	1m	1786828020	6.523	6.523	6.523	6.523	30	2026-08-15 21:07:56.10813+00
NEAR/USD	1m	1786828020	1.63	1.63	1.63	1.63	30	2026-08-15 21:07:56.10813+00
SOL/USD	1m	1786828020	75.7	75.7	75.7	75.7	30	2026-08-15 21:07:56.10813+00
DOGE/USD	1m	1786828020	0.0698501	0.0698501	0.0698501	0.0698501	30	2026-08-15 21:07:56.10813+00
UNI/USD	1m	1786828020	3.242	3.242	3.242	3.242	30	2026-08-15 21:07:56.10813+00
HBAR/USD	1m	1786828020	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 21:07:56.10813+00
LTC/USD	1m	1786828020	44.23	44.23	44.23	44.23	30	2026-08-15 21:07:56.10813+00
BCH/USD	1m	1786828020	202.36	202.36	202.36	202.36	30	2026-08-15 21:07:56.10813+00
LINK/USD	1m	1786828020	9.566	9.566	9.55	9.56	30	2026-08-15 21:07:56.10813+00
AAVE/USD	1m	1786828020	86.48	86.48	85.01	85.01	30	2026-08-15 21:07:56.10813+00
XRP/USD	1m	1786828080	1.00219	1.0046	1.00219	1.0046	30	2026-08-15 21:08:56.107864+00
DOGE/USD	1m	1786828080	0.0698501	0.0698501	0.0698501	0.0698501	30	2026-08-15 21:08:56.107864+00
XLM/USD	1m	1786828080	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:08:56.107864+00
SUI/USD	1m	1786828080	0.68	0.68	0.68	0.68	30	2026-08-15 21:08:56.107864+00
NEAR/USD	1m	1786828080	1.63	1.63	1.63	1.63	30	2026-08-15 21:08:56.107864+00
ETH/USD	1m	1786828080	1881.01	1881.01	1881.01	1881.01	30	2026-08-15 21:08:56.107864+00
DOT/USD	1m	1786828080	0.766	0.766	0.766	0.766	30	2026-08-15 21:08:56.107864+00
BCH/USD	1m	1786828080	202.36	202.36	202.36	202.36	30	2026-08-15 21:08:56.107864+00
SOL/USD	1m	1786828080	75.7	75.7	75.7	75.7	30	2026-08-15 21:08:56.107864+00
UNI/USD	1m	1786828080	3.242	3.242	3.239	3.239	30	2026-08-15 21:08:56.107864+00
AAVE/USD	1m	1786828080	85.01	85.01	85.01	85.01	30	2026-08-15 21:08:56.107864+00
LINK/USD	1m	1786828080	9.56	9.56	9.56	9.56	30	2026-08-15 21:08:56.107864+00
ADA/USD	1m	1786828080	0.178	0.178	0.178	0.178	30	2026-08-15 21:08:56.107864+00
BTC/USD	1m	1786828080	63100.21	63100.21	63100.21	63100.21	30	2026-08-15 21:08:56.107864+00
APT/USD	1m	1786828080	0.539	0.539	0.539	0.539	30	2026-08-15 21:08:56.107864+00
LTC/USD	1m	1786828080	44.23	44.23	44.23	44.23	30	2026-08-15 21:08:56.107864+00
HBAR/USD	1m	1786828080	0.06565	0.06565	0.06565	0.06565	31	2026-08-15 21:08:56.107864+00
AVAX/USD	1m	1786828080	6.523	6.523	6.5	6.5	31	2026-08-15 21:08:56.107864+00
POL/USD	1m	1786828080	0.0756	0.0756	0.0756	0.0756	31	2026-08-15 21:08:56.107864+00
LTC/USD	1m	1786828140	44.23	44.23	44.23	44.23	30	2026-08-15 21:09:56.10869+00
LTC/USD	5m	1786827900	44.23	44.23	44.23	44.23	150	2026-08-15 21:09:56.10869+00
SUI/USD	1m	1786828140	0.68	0.68	0.68	0.68	30	2026-08-15 21:09:56.10869+00
SUI/USD	5m	1786827900	0.68	0.68	0.68	0.68	149	2026-08-15 21:09:56.10869+00
APT/USD	1m	1786828140	0.539	0.539	0.539	0.539	30	2026-08-15 21:09:56.10869+00
APT/USD	5m	1786827900	0.54	0.54	0.539	0.539	150	2026-08-15 21:09:56.10869+00
NEAR/USD	1m	1786828140	1.63	1.63	1.63	1.63	30	2026-08-15 21:09:56.10869+00
NEAR/USD	5m	1786827900	1.63	1.63	1.63	1.63	150	2026-08-15 21:09:56.10869+00
POL/USD	1m	1786828140	0.0756	0.0756	0.0756	0.0756	29	2026-08-15 21:09:56.10869+00
POL/USD	5m	1786827900	0.0756	0.0756	0.0756	0.0756	150	2026-08-15 21:09:56.10869+00
DOT/USD	1m	1786828140	0.766	0.766	0.766	0.766	30	2026-08-15 21:09:56.10869+00
DOT/USD	5m	1786827900	0.765	0.766	0.765	0.766	150	2026-08-15 21:09:56.10869+00
BTC/USD	1m	1786828140	63100.21	63100.21	63100.21	63100.21	30	2026-08-15 21:09:56.10869+00
BTC/USD	5m	1786827900	63100.21	63100.21	63100.21	63100.21	150	2026-08-15 21:09:56.10869+00
HBAR/USD	1m	1786828140	0.06565	0.06565	0.06565	0.06565	29	2026-08-15 21:09:56.10869+00
HBAR/USD	5m	1786827900	0.06565	0.06565	0.06565	0.06565	150	2026-08-15 21:09:56.10869+00
BCH/USD	1m	1786828140	202.36	202.36	202.36	202.36	30	2026-08-15 21:09:56.10869+00
BCH/USD	5m	1786827900	202.36	202.36	202.36	202.36	150	2026-08-15 21:09:56.10869+00
AAVE/USD	1m	1786828140	85.01	86.32	85.01	86.32	30	2026-08-15 21:09:56.10869+00
AAVE/USD	5m	1786827900	86.48	86.48	85.01	86.32	150	2026-08-15 21:09:56.10869+00
AVAX/USD	1m	1786828140	6.5	6.5	6.5	6.5	29	2026-08-15 21:09:56.10869+00
AVAX/USD	5m	1786827900	6.523	6.523	6.5	6.5	150	2026-08-15 21:09:56.10869+00
XLM/USD	1m	1786828140	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:09:56.10869+00
XLM/USD	5m	1786827900	0.15774	0.15774	0.15774	0.15774	150	2026-08-15 21:09:56.10869+00
SOL/USD	1m	1786828140	75.7	75.7	75.7	75.7	30	2026-08-15 21:09:56.10869+00
SOL/USD	5m	1786827900	75.7	75.7	75.7	75.7	150	2026-08-15 21:09:56.10869+00
XRP/USD	1m	1786828140	1.0046	1.0046	1.0046	1.0046	30	2026-08-15 21:09:56.10869+00
XRP/USD	5m	1786827900	1.00159	1.0046	1.00159	1.0046	150	2026-08-15 21:09:56.10869+00
DOGE/USD	1m	1786828140	0.0698501	0.0698501	0.0698501	0.0698501	30	2026-08-15 21:09:56.10869+00
DOGE/USD	5m	1786827900	0.0698501	0.0698501	0.0698501	0.0698501	150	2026-08-15 21:09:56.10869+00
UNI/USD	1m	1786828140	3.239	3.239	3.239	3.239	30	2026-08-15 21:09:56.10869+00
UNI/USD	5m	1786827900	3.238	3.242	3.238	3.239	150	2026-08-15 21:09:56.10869+00
ADA/USD	1m	1786828140	0.178	0.178	0.178	0.178	30	2026-08-15 21:09:56.10869+00
ADA/USD	5m	1786827900	0.178	0.178	0.178	0.178	150	2026-08-15 21:09:56.10869+00
LINK/USD	1m	1786828140	9.56	9.56	9.56	9.56	30	2026-08-15 21:09:56.10869+00
LINK/USD	5m	1786827900	9.566	9.566	9.55	9.56	150	2026-08-15 21:09:56.10869+00
ETH/USD	1m	1786828140	1881.01	1881.01	1881.01	1881.01	30	2026-08-15 21:09:56.10869+00
ETH/USD	5m	1786827900	1884.46	1884.46	1881.01	1881.01	150	2026-08-15 21:09:56.10869+00
BCH/USD	1m	1786828200	202.36	202.36	202.36	202.36	30	2026-08-15 21:10:56.118541+00
UNI/USD	1m	1786828200	3.239	3.239	3.239	3.239	30	2026-08-15 21:10:56.118541+00
AAVE/USD	1m	1786828200	86.32	86.32	86.32	86.32	30	2026-08-15 21:10:56.118541+00
XLM/USD	1m	1786828200	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:10:56.118541+00
ADA/USD	1m	1786828200	0.178	0.178	0.178	0.178	30	2026-08-15 21:10:56.118541+00
DOGE/USD	1m	1786828200	0.0698501	0.0698501	0.0698501	0.0698501	30	2026-08-15 21:10:56.118541+00
HBAR/USD	1m	1786828200	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 21:10:56.118541+00
BTC/USD	1m	1786828200	63100.21	63100.21	63100.21	63100.21	30	2026-08-15 21:10:56.118541+00
XRP/USD	1m	1786828200	1.0046	1.00561	1.0046	1.00561	30	2026-08-15 21:10:56.118541+00
AVAX/USD	1m	1786828200	6.5	6.5	6.5	6.5	30	2026-08-15 21:10:56.118541+00
NEAR/USD	1m	1786828200	1.63	1.63	1.63	1.63	30	2026-08-15 21:10:56.118541+00
LINK/USD	1m	1786828200	9.56	9.56	9.56	9.56	30	2026-08-15 21:10:56.118541+00
SOL/USD	1m	1786828200	75.7	75.7	75.7	75.7	30	2026-08-15 21:10:56.118541+00
APT/USD	1m	1786828200	0.539	0.539	0.539	0.539	30	2026-08-15 21:10:56.118541+00
LTC/USD	1m	1786828200	44.23	44.23	44.23	44.23	30	2026-08-15 21:10:56.118541+00
DOT/USD	1m	1786828200	0.766	0.766	0.766	0.766	30	2026-08-15 21:10:56.118541+00
ETH/USD	1m	1786828200	1881.01	1881.01	1881.01	1881.01	30	2026-08-15 21:10:56.118541+00
SUI/USD	1m	1786828200	0.68	0.68	0.68	0.68	30	2026-08-15 21:10:56.118541+00
POL/USD	1m	1786828200	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:10:56.118541+00
XLM/USD	1m	1786828260	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:11:56.107755+00
AAVE/USD	1m	1786828260	86.32	86.32	86.32	86.32	30	2026-08-15 21:11:56.107755+00
LTC/USD	1m	1786828260	44.23	44.23	44.23	44.23	30	2026-08-15 21:11:56.107755+00
DOT/USD	1m	1786828260	0.766	0.766	0.766	0.766	30	2026-08-15 21:11:56.107755+00
BCH/USD	1m	1786828260	202.36	202.36	202.36	202.36	30	2026-08-15 21:11:56.107755+00
XRP/USD	1m	1786828260	1.00561	1.00561	1.00561	1.00561	30	2026-08-15 21:11:56.107755+00
LINK/USD	1m	1786828260	9.56	9.56	9.56	9.56	30	2026-08-15 21:11:56.107755+00
HBAR/USD	1m	1786828260	0.06565	0.06565	0.06565	0.06565	30	2026-08-15 21:11:56.107755+00
POL/USD	1m	1786828260	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:11:56.107755+00
UNI/USD	1m	1786828260	3.239	3.239	3.239	3.239	30	2026-08-15 21:11:56.107755+00
BTC/USD	1m	1786828260	63100.21	63199.78	63100.21	63199.78	30	2026-08-15 21:11:56.107755+00
ADA/USD	1m	1786828260	0.178	0.1782	0.178	0.1782	30	2026-08-15 21:11:56.107755+00
SOL/USD	1m	1786828260	75.7	75.7	75.7	75.7	30	2026-08-15 21:11:56.107755+00
NEAR/USD	1m	1786828260	1.63	1.63	1.63	1.63	30	2026-08-15 21:11:56.107755+00
APT/USD	1m	1786828260	0.539	0.539	0.539	0.539	30	2026-08-15 21:11:56.107755+00
DOGE/USD	1m	1786828260	0.0698501	0.0698501	0.0698501	0.0698501	30	2026-08-15 21:11:56.107755+00
ETH/USD	1m	1786828260	1881.01	1881.01	1881.01	1881.01	30	2026-08-15 21:11:56.107755+00
AVAX/USD	1m	1786828260	6.5	6.5	6.5	6.5	30	2026-08-15 21:11:56.107755+00
SUI/USD	1m	1786828260	0.68	0.6816	0.68	0.6816	31	2026-08-15 21:11:56.107755+00
BCH/USD	1m	1786828320	202.36	202.36	202.36	202.36	30	2026-08-15 21:12:56.108106+00
SOL/USD	1m	1786828320	75.7	75.7	75.7	75.7	30	2026-08-15 21:12:56.108106+00
ADA/USD	1m	1786828320	0.1782	0.1782	0.1782	0.1782	30	2026-08-15 21:12:56.108106+00
DOT/USD	1m	1786828320	0.766	0.766	0.766	0.766	30	2026-08-15 21:12:56.108106+00
XLM/USD	1m	1786828320	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:12:56.108106+00
LTC/USD	1m	1786828320	44.23	44.23	44.23	44.23	30	2026-08-15 21:12:56.108106+00
DOGE/USD	1m	1786828320	0.0698501	0.0698501	0.0698501	0.0698501	30	2026-08-15 21:12:56.108106+00
AAVE/USD	1m	1786828320	86.32	86.32	86.32	86.32	30	2026-08-15 21:12:56.108106+00
XRP/USD	1m	1786828320	1.00561	1.00561	1.00561	1.00561	30	2026-08-15 21:12:56.108106+00
SUI/USD	1m	1786828320	0.6816	0.6816	0.6816	0.6816	29	2026-08-15 21:12:56.108106+00
ETH/USD	1m	1786828320	1881.01	1881.01	1881.01	1881.01	30	2026-08-15 21:12:56.108106+00
LINK/USD	1m	1786828320	9.56	9.56	9.56	9.56	30	2026-08-15 21:12:56.108106+00
APT/USD	1m	1786828320	0.539	0.539	0.539	0.539	30	2026-08-15 21:12:56.108106+00
UNI/USD	1m	1786828320	3.239	3.239	3.239	3.239	30	2026-08-15 21:12:56.108106+00
NEAR/USD	1m	1786828320	1.63	1.63	1.63	1.63	30	2026-08-15 21:12:56.108106+00
BTC/USD	1m	1786828320	63199.78	63199.78	63199.78	63199.78	30	2026-08-15 21:12:56.108106+00
POL/USD	1m	1786828320	0.0756	0.0756	0.0756	0.0756	31	2026-08-15 21:12:56.108106+00
HBAR/USD	1m	1786828320	0.06565	0.06565	0.06565	0.06565	31	2026-08-15 21:12:56.108106+00
AVAX/USD	1m	1786828320	6.5	6.5	6.5	6.5	31	2026-08-15 21:12:56.108106+00
ETH/USD	1m	1786828380	1881.01	1884.66	1881.01	1884.66	30	2026-08-15 21:13:56.108293+00
APT/USD	1m	1786828380	0.539	0.539	0.539	0.539	30	2026-08-15 21:13:56.108293+00
HBAR/USD	1m	1786828380	0.06565	0.06565	0.06565	0.06565	29	2026-08-15 21:13:56.108293+00
SOL/USD	1m	1786828380	75.7	75.7	75.7	75.7	30	2026-08-15 21:13:56.108293+00
DOT/USD	1m	1786828380	0.766	0.766	0.766	0.766	30	2026-08-15 21:13:56.108293+00
LTC/USD	1m	1786828380	44.23	44.23	44.23	44.23	30	2026-08-15 21:13:56.108293+00
AAVE/USD	1m	1786828380	86.32	86.32	86.32	86.32	30	2026-08-15 21:13:56.108293+00
BCH/USD	1m	1786828380	202.36	202.36	202.36	202.36	30	2026-08-15 21:13:56.108293+00
DOGE/USD	1m	1786828380	0.0698501	0.0698501	0.0698501	0.0698501	30	2026-08-15 21:13:56.108293+00
UNI/USD	1m	1786828380	3.239	3.239	3.239	3.239	30	2026-08-15 21:13:56.108293+00
XRP/USD	1m	1786828380	1.00561	1.00561	1.00561	1.00561	30	2026-08-15 21:13:56.108293+00
POL/USD	1m	1786828380	0.0756	0.0756	0.0756	0.0756	29	2026-08-15 21:13:56.108293+00
XLM/USD	1m	1786828380	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:13:56.108293+00
AVAX/USD	1m	1786828380	6.5	6.5	6.5	6.5	29	2026-08-15 21:13:56.108293+00
NEAR/USD	1m	1786828380	1.63	1.63	1.63	1.63	30	2026-08-15 21:13:56.108293+00
ADA/USD	1m	1786828380	0.1782	0.1782	0.1782	0.1782	30	2026-08-15 21:13:56.108293+00
BTC/USD	1m	1786828380	63199.78	63199.78	63199.78	63199.78	30	2026-08-15 21:13:56.108293+00
LINK/USD	1m	1786828380	9.56	9.56	9.56	9.56	30	2026-08-15 21:13:56.108293+00
SUI/USD	1m	1786828380	0.6816	0.6816	0.6816	0.6816	31	2026-08-15 21:13:56.108293+00
SOL/USD	1m	1786828440	75.7	75.7	75.7	75.7	30	2026-08-15 21:14:56.109285+00
SOL/USD	5m	1786828200	75.7	75.7	75.7	75.7	150	2026-08-15 21:14:56.109285+00
SOL/USD	15m	1786827600	75.559	75.7	75.559	75.7	450	2026-08-15 21:14:56.109285+00
HBAR/USD	1m	1786828440	0.06565	0.06589	0.06565	0.06589	30	2026-08-15 21:14:56.109285+00
HBAR/USD	5m	1786828200	0.06565	0.06589	0.06565	0.06589	150	2026-08-15 21:14:56.109285+00
HBAR/USD	15m	1786827600	0.06565	0.06589	0.06565	0.06589	450	2026-08-15 21:14:56.109285+00
SUI/USD	1m	1786828440	0.6816	0.6816	0.6816	0.6816	29	2026-08-15 21:14:56.109285+00
SUI/USD	5m	1786828200	0.68	0.6816	0.68	0.6816	150	2026-08-15 21:14:56.109285+00
SUI/USD	15m	1786827600	0.68	0.6816	0.68	0.6816	449	2026-08-15 21:14:56.109285+00
UNI/USD	1m	1786828440	3.239	3.239	3.239	3.239	30	2026-08-15 21:14:56.109285+00
UNI/USD	5m	1786828200	3.239	3.239	3.239	3.239	150	2026-08-15 21:14:56.109285+00
UNI/USD	15m	1786827600	3.241	3.242	3.238	3.239	450	2026-08-15 21:14:56.109285+00
LINK/USD	1m	1786828440	9.56	9.56	9.56	9.56	30	2026-08-15 21:14:56.109285+00
LINK/USD	5m	1786828200	9.56	9.56	9.56	9.56	150	2026-08-15 21:14:56.109285+00
LINK/USD	15m	1786827600	9.543	9.566	9.543	9.56	450	2026-08-15 21:14:56.109285+00
XLM/USD	1m	1786828440	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:14:56.109285+00
XLM/USD	5m	1786828200	0.15774	0.15774	0.15774	0.15774	150	2026-08-15 21:14:56.109285+00
XLM/USD	15m	1786827600	0.15774	0.15774	0.15774	0.15774	450	2026-08-15 21:14:56.109285+00
POL/USD	1m	1786828440	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:14:56.109285+00
POL/USD	5m	1786828200	0.0756	0.0756	0.0756	0.0756	150	2026-08-15 21:14:56.109285+00
POL/USD	15m	1786827600	0.0756	0.0756	0.0756	0.0756	450	2026-08-15 21:14:56.109285+00
DOGE/USD	1m	1786828440	0.0698501	0.0698501	0.0698501	0.0698501	30	2026-08-15 21:14:56.109285+00
DOGE/USD	5m	1786828200	0.0698501	0.0698501	0.0698501	0.0698501	150	2026-08-15 21:14:56.109285+00
DOGE/USD	15m	1786827600	0.0698501	0.0698501	0.0698501	0.0698501	450	2026-08-15 21:14:56.109285+00
NEAR/USD	1m	1786828440	1.63	1.63	1.63	1.63	30	2026-08-15 21:14:56.109285+00
NEAR/USD	5m	1786828200	1.63	1.63	1.63	1.63	150	2026-08-15 21:14:56.109285+00
NEAR/USD	15m	1786827600	1.63	1.63	1.63	1.63	450	2026-08-15 21:14:56.109285+00
DOT/USD	1m	1786828440	0.766	0.766	0.766	0.766	30	2026-08-15 21:14:56.109285+00
DOT/USD	5m	1786828200	0.766	0.766	0.766	0.766	150	2026-08-15 21:14:56.109285+00
DOT/USD	15m	1786827600	0.765	0.766	0.765	0.766	450	2026-08-15 21:14:56.109285+00
ADA/USD	1m	1786828440	0.1782	0.1782	0.1782	0.1782	30	2026-08-15 21:14:56.109285+00
ADA/USD	5m	1786828200	0.178	0.1782	0.178	0.1782	150	2026-08-15 21:14:56.109285+00
ADA/USD	15m	1786827600	0.1782	0.1782	0.178	0.1782	450	2026-08-15 21:14:56.109285+00
AVAX/USD	1m	1786828440	6.5	6.5	6.5	6.5	30	2026-08-15 21:14:56.109285+00
AVAX/USD	5m	1786828200	6.5	6.5	6.5	6.5	150	2026-08-15 21:14:56.109285+00
AVAX/USD	15m	1786827600	6.491	6.523	6.491	6.5	450	2026-08-15 21:14:56.109285+00
AAVE/USD	1m	1786828440	86.32	86.32	86.32	86.32	30	2026-08-15 21:14:56.109285+00
AAVE/USD	5m	1786828200	86.32	86.32	86.32	86.32	150	2026-08-15 21:14:56.109285+00
AAVE/USD	15m	1786827600	85.97	86.48	85.01	86.32	450	2026-08-15 21:14:56.109285+00
APT/USD	1m	1786828440	0.539	0.539	0.539	0.539	30	2026-08-15 21:14:56.109285+00
APT/USD	5m	1786828200	0.539	0.539	0.539	0.539	150	2026-08-15 21:14:56.109285+00
APT/USD	15m	1786827600	0.54	0.54	0.539	0.539	450	2026-08-15 21:14:56.109285+00
XRP/USD	1m	1786828440	1.00561	1.00561	1.00561	1.00561	31	2026-08-15 21:14:56.109285+00
XRP/USD	5m	1786828200	1.0046	1.00561	1.0046	1.00561	151	2026-08-15 21:14:56.109285+00
XRP/USD	15m	1786827600	1.00159	1.00561	1.00159	1.00561	451	2026-08-15 21:14:56.109285+00
BCH/USD	1m	1786828440	202.36	202.36	202.36	202.36	31	2026-08-15 21:14:56.109285+00
BCH/USD	5m	1786828200	202.36	202.36	202.36	202.36	151	2026-08-15 21:14:56.109285+00
BCH/USD	15m	1786827600	202.36	202.36	202.36	202.36	451	2026-08-15 21:14:56.109285+00
LTC/USD	1m	1786828440	44.23	44.23	44.23	44.23	31	2026-08-15 21:14:56.109285+00
LTC/USD	5m	1786828200	44.23	44.23	44.23	44.23	151	2026-08-15 21:14:56.109285+00
LTC/USD	15m	1786827600	44.23	44.23	44.23	44.23	451	2026-08-15 21:14:56.109285+00
BTC/USD	1m	1786828440	63199.78	63199.78	63199.78	63199.78	31	2026-08-15 21:14:56.109285+00
BTC/USD	5m	1786828200	63100.21	63199.78	63100.21	63199.78	151	2026-08-15 21:14:56.109285+00
BTC/USD	15m	1786827600	63100.21	63199.78	63100.21	63199.78	451	2026-08-15 21:14:56.109285+00
ETH/USD	1m	1786828440	1884.66	1884.66	1884.66	1884.66	31	2026-08-15 21:14:56.109285+00
ETH/USD	5m	1786828200	1881.01	1884.66	1881.01	1884.66	151	2026-08-15 21:14:56.109285+00
ETH/USD	15m	1786827600	1884.46	1884.66	1881.01	1884.66	451	2026-08-15 21:14:56.109285+00
APT/USD	1m	1786828500	0.539	0.539	0.539	0.539	30	2026-08-15 21:15:56.108204+00
LTC/USD	1m	1786828500	44.23	44.23	44.23	44.23	29	2026-08-15 21:15:56.108204+00
ETH/USD	1m	1786828500	1884.66	1884.66	1884.66	1884.66	29	2026-08-15 21:15:56.108204+00
XRP/USD	1m	1786828500	1.00561	1.00561	1.00561	1.00561	29	2026-08-15 21:15:56.108204+00
AVAX/USD	1m	1786828500	6.5	6.5	6.5	6.5	30	2026-08-15 21:15:56.108204+00
ADA/USD	1m	1786828500	0.1782	0.1782	0.1782	0.1782	30	2026-08-15 21:15:56.108204+00
XLM/USD	1m	1786828500	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:15:56.108204+00
LINK/USD	1m	1786828500	9.56	9.56	9.56	9.56	30	2026-08-15 21:15:56.108204+00
HBAR/USD	1m	1786828500	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:15:56.108204+00
BCH/USD	1m	1786828500	202.36	202.36	202.36	202.36	29	2026-08-15 21:15:56.108204+00
UNI/USD	1m	1786828500	3.239	3.239	3.239	3.239	30	2026-08-15 21:15:56.108204+00
DOGE/USD	1m	1786828500	0.0698501	0.0698501	0.0698501	0.0698501	30	2026-08-15 21:15:56.108204+00
DOT/USD	1m	1786828500	0.766	0.766	0.766	0.766	30	2026-08-15 21:15:56.108204+00
NEAR/USD	1m	1786828500	1.63	1.63	1.63	1.63	30	2026-08-15 21:15:56.108204+00
POL/USD	1m	1786828500	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:15:56.108204+00
SOL/USD	1m	1786828500	75.7	75.7	75.7	75.7	30	2026-08-15 21:15:56.108204+00
SUI/USD	1m	1786828500	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:15:56.108204+00
AAVE/USD	1m	1786828500	86.32	86.32	86.32	86.32	30	2026-08-15 21:15:56.108204+00
BTC/USD	1m	1786828500	63199.78	63199.78	63199.78	63199.78	30	2026-08-15 21:15:56.108204+00
XRP/USD	1m	1786828560	1.00561	1.00561	1.00561	1.00561	30	2026-08-15 21:16:56.109655+00
BCH/USD	1m	1786828560	202.36	202.36	202.36	202.36	30	2026-08-15 21:16:56.109655+00
NEAR/USD	1m	1786828560	1.63	1.63	1.63	1.63	30	2026-08-15 21:16:56.109655+00
LINK/USD	1m	1786828560	9.56	9.56	9.56	9.56	30	2026-08-15 21:16:56.109655+00
ADA/USD	1m	1786828560	0.1782	0.1782	0.1782	0.1782	30	2026-08-15 21:16:56.109655+00
ETH/USD	1m	1786828560	1884.66	1884.66	1884.66	1884.66	30	2026-08-15 21:16:56.109655+00
SUI/USD	1m	1786828560	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:16:56.109655+00
LTC/USD	1m	1786828560	44.23	44.23	44.23	44.23	30	2026-08-15 21:16:56.109655+00
BTC/USD	1m	1786828560	63199.78	63199.78	63199.78	63199.78	29	2026-08-15 21:16:56.109655+00
XLM/USD	1m	1786828560	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:16:56.109655+00
DOGE/USD	1m	1786828560	0.0698501	0.0702197	0.0698501	0.0702197	30	2026-08-15 21:16:56.109655+00
SOL/USD	1m	1786828560	75.7	75.7	75.7	75.7	31	2026-08-15 21:16:56.109655+00
HBAR/USD	1m	1786828560	0.06589	0.06589	0.06589	0.06589	31	2026-08-15 21:16:56.109655+00
AVAX/USD	1m	1786828560	6.5	6.5	6.5	6.5	31	2026-08-15 21:16:56.109655+00
POL/USD	1m	1786828560	0.0756	0.0756	0.0756	0.0756	31	2026-08-15 21:16:56.109655+00
UNI/USD	1m	1786828560	3.239	3.245	3.239	3.245	31	2026-08-15 21:16:56.109655+00
DOT/USD	1m	1786828560	0.766	0.766	0.766	0.766	31	2026-08-15 21:16:56.109655+00
APT/USD	1m	1786828560	0.539	0.539	0.539	0.539	31	2026-08-15 21:16:56.109655+00
AAVE/USD	1m	1786828560	86.32	86.32	86.32	86.32	31	2026-08-15 21:16:56.109655+00
SUI/USD	1m	1786828620	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:17:56.108429+00
ADA/USD	1m	1786828620	0.1782	0.1782	0.1782	0.1782	30	2026-08-15 21:17:56.108429+00
HBAR/USD	1m	1786828620	0.06589	0.06589	0.06589	0.06589	29	2026-08-15 21:17:56.108429+00
AVAX/USD	1m	1786828620	6.5	6.5	6.5	6.5	29	2026-08-15 21:17:56.108429+00
APT/USD	1m	1786828620	0.539	0.539	0.539	0.539	29	2026-08-15 21:17:56.108429+00
SOL/USD	1m	1786828620	75.7	75.7	75.7	75.7	29	2026-08-15 21:17:56.108429+00
DOT/USD	1m	1786828620	0.766	0.766	0.766	0.766	29	2026-08-15 21:17:56.108429+00
UNI/USD	1m	1786828620	3.245	3.245	3.241	3.241	29	2026-08-15 21:17:56.108429+00
AAVE/USD	1m	1786828620	86.32	86.32	86.32	86.32	29	2026-08-15 21:17:56.108429+00
POL/USD	1m	1786828620	0.0756	0.0756	0.0756	0.0756	29	2026-08-15 21:17:56.108429+00
DOGE/USD	1m	1786828620	0.0702197	0.0702197	0.0702197	0.0702197	31	2026-08-15 21:17:56.108429+00
XRP/USD	1m	1786828620	1.00561	1.00561	1.00561	1.00561	31	2026-08-15 21:17:56.108429+00
ETH/USD	1m	1786828620	1884.66	1884.66	1884.66	1884.66	31	2026-08-15 21:17:56.108429+00
BCH/USD	1m	1786828620	202.36	203.4	202.36	203.4	31	2026-08-15 21:17:56.108429+00
XLM/USD	1m	1786828620	0.15774	0.15774	0.15774	0.15774	31	2026-08-15 21:17:56.108429+00
BTC/USD	1m	1786828620	63199.78	63199.78	63199.78	63199.78	31	2026-08-15 21:17:56.108429+00
NEAR/USD	1m	1786828620	1.63	1.63	1.63	1.63	31	2026-08-15 21:17:56.108429+00
LTC/USD	1m	1786828620	44.23	44.23	44.23	44.23	31	2026-08-15 21:17:56.108429+00
LINK/USD	1m	1786828620	9.56	9.56	9.56	9.56	31	2026-08-15 21:17:56.108429+00
ADA/USD	1m	1786828680	0.1782	0.1782	0.1782	0.1782	30	2026-08-15 21:18:56.107774+00
UNI/USD	1m	1786828680	3.241	3.241	3.241	3.241	30	2026-08-15 21:18:56.107774+00
LINK/USD	1m	1786828680	9.56	9.566	9.56	9.566	29	2026-08-15 21:18:56.107774+00
LTC/USD	1m	1786828680	44.23	44.23	44.23	44.23	29	2026-08-15 21:18:56.107774+00
BTC/USD	1m	1786828680	63199.78	63199.78	63199.78	63199.78	29	2026-08-15 21:18:56.107774+00
SUI/USD	1m	1786828680	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:18:56.107774+00
DOT/USD	1m	1786828680	0.766	0.766	0.766	0.766	30	2026-08-15 21:18:56.107774+00
NEAR/USD	1m	1786828680	1.63	1.63	1.63	1.63	29	2026-08-15 21:18:56.107774+00
AAVE/USD	1m	1786828680	86.32	86.32	86.32	86.32	30	2026-08-15 21:18:56.107774+00
SOL/USD	1m	1786828680	75.7	75.7	75.7	75.7	30	2026-08-15 21:18:56.107774+00
AVAX/USD	1m	1786828680	6.5	6.5	6.5	6.5	30	2026-08-15 21:18:56.107774+00
HBAR/USD	1m	1786828680	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:18:56.107774+00
DOGE/USD	1m	1786828680	0.0702197	0.0702197	0.0702197	0.0702197	29	2026-08-15 21:18:56.107774+00
APT/USD	1m	1786828680	0.539	0.539	0.539	0.539	30	2026-08-15 21:18:56.107774+00
ETH/USD	1m	1786828680	1884.66	1884.66	1884.66	1884.66	29	2026-08-15 21:18:56.107774+00
BCH/USD	1m	1786828680	203.4	203.4	203.4	203.4	29	2026-08-15 21:18:56.107774+00
POL/USD	1m	1786828680	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:18:56.107774+00
XLM/USD	1m	1786828680	0.15774	0.15774	0.15774	0.15774	29	2026-08-15 21:18:56.107774+00
XRP/USD	1m	1786828680	1.00561	1.00561	1.00561	1.00561	29	2026-08-15 21:18:56.107774+00
NEAR/USD	1m	1786828740	1.63	1.63	1.63	1.63	30	2026-08-15 21:19:56.109391+00
NEAR/USD	5m	1786828500	1.63	1.63	1.63	1.63	150	2026-08-15 21:19:56.109391+00
BTC/USD	1m	1786828740	63199.78	63199.78	63199.78	63199.78	30	2026-08-15 21:19:56.109391+00
BTC/USD	5m	1786828500	63199.78	63199.78	63199.78	63199.78	149	2026-08-15 21:19:56.109391+00
POL/USD	1m	1786828740	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:19:56.109391+00
POL/USD	5m	1786828500	0.0756	0.0756	0.0756	0.0756	150	2026-08-15 21:19:56.109391+00
XLM/USD	1m	1786828740	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:19:56.109391+00
XLM/USD	5m	1786828500	0.15774	0.15774	0.15774	0.15774	150	2026-08-15 21:19:56.109391+00
DOGE/USD	1m	1786828740	0.0702197	0.0702197	0.0702197	0.0702197	30	2026-08-15 21:19:56.109391+00
DOGE/USD	5m	1786828500	0.0698501	0.0702197	0.0698501	0.0702197	150	2026-08-15 21:19:56.109391+00
DOT/USD	1m	1786828740	0.766	0.766	0.766	0.766	30	2026-08-15 21:19:56.109391+00
DOT/USD	5m	1786828500	0.766	0.766	0.766	0.766	150	2026-08-15 21:19:56.109391+00
LINK/USD	1m	1786828740	9.566	9.566	9.566	9.566	30	2026-08-15 21:19:56.109391+00
LINK/USD	5m	1786828500	9.56	9.566	9.56	9.566	150	2026-08-15 21:19:56.109391+00
LTC/USD	1m	1786828740	44.23	44.23	44.23	44.23	30	2026-08-15 21:19:56.109391+00
LTC/USD	5m	1786828500	44.23	44.23	44.23	44.23	149	2026-08-15 21:19:56.109391+00
HBAR/USD	1m	1786828740	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:19:56.109391+00
HBAR/USD	5m	1786828500	0.06589	0.06589	0.06589	0.06589	150	2026-08-15 21:19:56.109391+00
XRP/USD	1m	1786828740	1.00561	1.00561	1.00561	1.00561	30	2026-08-15 21:19:56.109391+00
XRP/USD	5m	1786828500	1.00561	1.00561	1.00561	1.00561	149	2026-08-15 21:19:56.109391+00
UNI/USD	1m	1786828740	3.241	3.245	3.241	3.241	30	2026-08-15 21:19:56.109391+00
UNI/USD	5m	1786828500	3.239	3.245	3.239	3.241	150	2026-08-15 21:19:56.109391+00
AVAX/USD	1m	1786828740	6.5	6.5	6.5	6.5	30	2026-08-15 21:19:56.109391+00
AVAX/USD	5m	1786828500	6.5	6.5	6.5	6.5	150	2026-08-15 21:19:56.109391+00
AAVE/USD	1m	1786828740	86.32	86.32	86.32	86.32	30	2026-08-15 21:19:56.109391+00
AAVE/USD	5m	1786828500	86.32	86.32	86.32	86.32	150	2026-08-15 21:19:56.109391+00
SOL/USD	1m	1786828740	75.7	75.7	75.7	75.7	30	2026-08-15 21:19:56.109391+00
SOL/USD	5m	1786828500	75.7	75.7	75.7	75.7	150	2026-08-15 21:19:56.109391+00
APT/USD	1m	1786828740	0.539	0.539	0.539	0.539	30	2026-08-15 21:19:56.109391+00
APT/USD	5m	1786828500	0.539	0.539	0.539	0.539	150	2026-08-15 21:19:56.109391+00
ADA/USD	1m	1786828740	0.1782	0.1782	0.1782	0.1782	30	2026-08-15 21:19:56.109391+00
ADA/USD	5m	1786828500	0.1782	0.1782	0.1782	0.1782	150	2026-08-15 21:19:56.109391+00
ETH/USD	1m	1786828740	1884.66	1884.66	1880.72	1880.72	30	2026-08-15 21:19:56.109391+00
ETH/USD	5m	1786828500	1884.66	1884.66	1880.72	1880.72	149	2026-08-15 21:19:56.109391+00
BCH/USD	1m	1786828740	203.4	203.4	203.4	203.4	30	2026-08-15 21:19:56.109391+00
BCH/USD	5m	1786828500	202.36	203.4	202.36	203.4	149	2026-08-15 21:19:56.109391+00
SUI/USD	1m	1786828740	0.6816	0.6816	0.6816	0.6816	31	2026-08-15 21:19:56.109391+00
SUI/USD	5m	1786828500	0.6816	0.6816	0.6816	0.6816	151	2026-08-15 21:19:56.109391+00
LTC/USD	1m	1786828800	44.23	44.23	44.23	44.23	30	2026-08-15 21:20:56.106629+00
XRP/USD	1m	1786828800	1.00561	1.00561	1.00561	1.00561	30	2026-08-15 21:20:56.106629+00
AVAX/USD	1m	1786828800	6.5	6.5	6.5	6.5	30	2026-08-15 21:20:56.106629+00
BCH/USD	1m	1786828800	203.4	203.4	203.4	203.4	30	2026-08-15 21:20:56.106629+00
SUI/USD	1m	1786828800	0.6816	0.6816	0.6816	0.6816	29	2026-08-15 21:20:56.106629+00
BTC/USD	1m	1786828800	63199.78	63199.78	63160	63160	30	2026-08-15 21:20:56.106629+00
ETH/USD	1m	1786828800	1880.72	1880.72	1880.72	1880.72	30	2026-08-15 21:20:56.106629+00
XLM/USD	1m	1786828800	0.15774	0.15774	0.15774	0.15774	31	2026-08-15 21:20:56.106629+00
AAVE/USD	1m	1786828800	86.32	86.32	86.32	86.32	31	2026-08-15 21:20:56.106629+00
UNI/USD	1m	1786828800	3.241	3.241	3.241	3.241	31	2026-08-15 21:20:56.106629+00
ADA/USD	1m	1786828800	0.1782	0.1782	0.1782	0.1782	31	2026-08-15 21:20:56.106629+00
SOL/USD	1m	1786828800	75.7	75.7	75.7	75.7	31	2026-08-15 21:20:56.106629+00
APT/USD	1m	1786828800	0.539	0.539	0.539	0.539	31	2026-08-15 21:20:56.106629+00
DOGE/USD	1m	1786828800	0.0702197	0.0702197	0.0702197	0.0702197	31	2026-08-15 21:20:56.106629+00
NEAR/USD	1m	1786828800	1.63	1.63	1.63	1.63	31	2026-08-15 21:20:56.106629+00
HBAR/USD	1m	1786828800	0.06589	0.06589	0.06589	0.06589	31	2026-08-15 21:20:56.106629+00
POL/USD	1m	1786828800	0.0756	0.0756	0.0756	0.0756	31	2026-08-15 21:20:56.106629+00
LINK/USD	1m	1786828800	9.566	9.575	9.56	9.575	31	2026-08-15 21:20:56.106629+00
DOT/USD	1m	1786828800	0.766	0.766	0.766	0.766	31	2026-08-15 21:20:56.106629+00
NEAR/USD	1m	1786828860	1.63	1.63	1.63	1.63	29	2026-08-15 21:21:56.118806+00
ADA/USD	1m	1786828860	0.1782	0.1782	0.1781	0.1781	29	2026-08-15 21:21:56.118806+00
SOL/USD	1m	1786828860	75.7	75.7	75.7	75.7	29	2026-08-15 21:21:56.118806+00
AAVE/USD	1m	1786828860	86.32	86.32	86.32	86.32	29	2026-08-15 21:21:56.118806+00
HBAR/USD	1m	1786828860	0.06589	0.06589	0.06589	0.06589	29	2026-08-15 21:21:56.118806+00
DOT/USD	1m	1786828860	0.766	0.766	0.766	0.766	29	2026-08-15 21:21:56.118806+00
AVAX/USD	1m	1786828860	6.5	6.5	6.5	6.5	30	2026-08-15 21:21:56.118806+00
LINK/USD	1m	1786828860	9.575	9.575	9.575	9.575	29	2026-08-15 21:21:56.118806+00
APT/USD	1m	1786828860	0.539	0.539	0.539	0.539	29	2026-08-15 21:21:56.118806+00
UNI/USD	1m	1786828860	3.241	3.241	3.241	3.241	29	2026-08-15 21:21:56.118806+00
SUI/USD	1m	1786828860	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:21:56.118806+00
POL/USD	1m	1786828860	0.0756	0.0756	0.0756	0.0756	29	2026-08-15 21:21:56.118806+00
XLM/USD	1m	1786828860	0.15774	0.15774	0.15774	0.15774	29	2026-08-15 21:21:56.118806+00
LTC/USD	1m	1786828860	44.23	44.23	44.23	44.23	31	2026-08-15 21:21:56.118806+00
XRP/USD	1m	1786828860	1.00561	1.00561	1.0046	1.0046	31	2026-08-15 21:21:56.118806+00
DOGE/USD	1m	1786828860	0.0702197	0.0702197	0.0702197	0.0702197	30	2026-08-15 21:21:56.118806+00
BCH/USD	1m	1786828860	203.4	203.4	203.4	203.4	31	2026-08-15 21:21:56.118806+00
ETH/USD	1m	1786828860	1880.72	1880.72	1880.72	1880.72	31	2026-08-15 21:21:56.118806+00
BTC/USD	1m	1786828860	63160	63160	63160	63160	31	2026-08-15 21:21:56.118806+00
SUI/USD	1m	1786828920	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:22:56.108618+00
APT/USD	1m	1786828920	0.539	0.539	0.539	0.539	31	2026-08-15 21:22:56.108618+00
BCH/USD	1m	1786828920	203.4	203.4	203.4	203.4	30	2026-08-15 21:22:56.108618+00
LTC/USD	1m	1786828920	44.23	44.23	44.23	44.23	30	2026-08-15 21:22:56.108618+00
BTC/USD	1m	1786828920	63140	63140	63140	63140	30	2026-08-15 21:22:56.108618+00
POL/USD	1m	1786828920	0.0756	0.0756	0.0756	0.0756	31	2026-08-15 21:22:56.108618+00
AVAX/USD	1m	1786828920	6.5	6.5	6.5	6.5	31	2026-08-15 21:22:56.108618+00
HBAR/USD	1m	1786828920	0.06589	0.06589	0.06589	0.06589	31	2026-08-15 21:22:56.108618+00
AAVE/USD	1m	1786828920	86.32	86.32	86.32	86.32	31	2026-08-15 21:22:56.108618+00
DOT/USD	1m	1786828920	0.766	0.766	0.766	0.766	31	2026-08-15 21:22:56.108618+00
DOGE/USD	1m	1786828920	0.0702197	0.0702197	0.0702137	0.0702137	30	2026-08-15 21:22:56.108618+00
NEAR/USD	1m	1786828920	1.63	1.63	1.63	1.63	31	2026-08-15 21:22:56.108618+00
LINK/USD	1m	1786828920	9.575	9.575	9.575	9.575	31	2026-08-15 21:22:56.108618+00
XRP/USD	1m	1786828920	1.0046	1.0046	1.0046	1.0046	30	2026-08-15 21:22:56.108618+00
SOL/USD	1m	1786828920	75.7	75.7	75.538	75.538	31	2026-08-15 21:22:56.108618+00
XLM/USD	1m	1786828920	0.15774	0.15774	0.15774	0.15774	31	2026-08-15 21:22:56.108618+00
UNI/USD	1m	1786828920	3.241	3.245	3.241	3.245	31	2026-08-15 21:22:56.108618+00
ADA/USD	1m	1786828920	0.1781	0.1781	0.1781	0.1781	31	2026-08-15 21:22:56.108618+00
ETH/USD	1m	1786828920	1880.72	1880.72	1880.72	1880.72	30	2026-08-15 21:22:56.108618+00
ETH/USD	1m	1786828980	1880.72	1883	1880.72	1883	29	2026-08-15 21:23:56.108056+00
LTC/USD	1m	1786828980	44.23	44.23	44.23	44.23	29	2026-08-15 21:23:56.108056+00
BCH/USD	1m	1786828980	203.4	203.4	203.4	203.4	29	2026-08-15 21:23:56.108056+00
XRP/USD	1m	1786828980	1.0046	1.0046	1.00246	1.00246	29	2026-08-15 21:23:56.108056+00
AVAX/USD	1m	1786828980	6.5	6.5	6.5	6.5	29	2026-08-15 21:23:56.108056+00
SUI/USD	1m	1786828980	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:23:56.108056+00
HBAR/USD	1m	1786828980	0.06589	0.06589	0.06589	0.06589	29	2026-08-15 21:23:56.108056+00
BTC/USD	1m	1786828980	63140	63199.78	63140	63199.78	29	2026-08-15 21:23:56.108056+00
APT/USD	1m	1786828980	0.539	0.539	0.539	0.539	30	2026-08-15 21:23:56.108056+00
DOT/USD	1m	1786828980	0.766	0.766	0.766	0.766	30	2026-08-15 21:23:56.108056+00
DOGE/USD	1m	1786828980	0.0702137	0.0702169	0.0702137	0.0702152	30	2026-08-15 21:23:56.108056+00
ADA/USD	1m	1786828980	0.1781	0.1781	0.1777	0.1777	30	2026-08-15 21:23:56.108056+00
POL/USD	1m	1786828980	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:23:56.108056+00
LINK/USD	1m	1786828980	9.575	9.575	9.575	9.575	30	2026-08-15 21:23:56.108056+00
NEAR/USD	1m	1786828980	1.63	1.63	1.63	1.63	30	2026-08-15 21:23:56.108056+00
AAVE/USD	1m	1786828980	86.32	86.32	86.32	86.32	30	2026-08-15 21:23:56.108056+00
UNI/USD	1m	1786828980	3.245	3.245	3.245	3.245	30	2026-08-15 21:23:56.108056+00
SOL/USD	1m	1786828980	75.538	75.538	75.538	75.538	30	2026-08-15 21:23:56.108056+00
XLM/USD	1m	1786828980	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:23:56.108056+00
LINK/USD	1m	1786829040	9.575	9.575	9.575	9.575	29	2026-08-15 21:24:56.109326+00
LINK/USD	5m	1786828800	9.566	9.575	9.56	9.575	150	2026-08-15 21:24:56.109326+00
DOT/USD	1m	1786829040	0.766	0.766	0.766	0.766	29	2026-08-15 21:24:56.109326+00
DOT/USD	5m	1786828800	0.766	0.766	0.766	0.766	150	2026-08-15 21:24:56.109326+00
HBAR/USD	1m	1786829040	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:24:56.109326+00
HBAR/USD	5m	1786828800	0.06589	0.06589	0.06589	0.06589	150	2026-08-15 21:24:56.109326+00
POL/USD	1m	1786829040	0.0756	0.0756	0.0756	0.0756	29	2026-08-15 21:24:56.109326+00
POL/USD	5m	1786828800	0.0756	0.0756	0.0756	0.0756	150	2026-08-15 21:24:56.109326+00
UNI/USD	1m	1786829040	3.245	3.245	3.245	3.245	29	2026-08-15 21:24:56.109326+00
UNI/USD	5m	1786828800	3.241	3.245	3.241	3.245	150	2026-08-15 21:24:56.109326+00
SUI/USD	1m	1786829040	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:24:56.109326+00
SUI/USD	5m	1786828800	0.6816	0.6816	0.6816	0.6816	149	2026-08-15 21:24:56.109326+00
APT/USD	1m	1786829040	0.539	0.539	0.539	0.539	29	2026-08-15 21:24:56.109326+00
APT/USD	5m	1786828800	0.539	0.539	0.539	0.539	150	2026-08-15 21:24:56.109326+00
NEAR/USD	1m	1786829040	1.63	1.63	1.63	1.63	29	2026-08-15 21:24:56.109326+00
NEAR/USD	5m	1786828800	1.63	1.63	1.63	1.63	150	2026-08-15 21:24:56.109326+00
AAVE/USD	1m	1786829040	86.32	86.32	86.32	86.32	29	2026-08-15 21:24:56.109326+00
AAVE/USD	5m	1786828800	86.32	86.32	86.32	86.32	150	2026-08-15 21:24:56.109326+00
SOL/USD	1m	1786829040	75.538	75.538	75.538	75.538	29	2026-08-15 21:24:56.109326+00
SOL/USD	5m	1786828800	75.7	75.7	75.538	75.538	150	2026-08-15 21:24:56.109326+00
AVAX/USD	1m	1786829040	6.5	6.5	6.5	6.5	30	2026-08-15 21:24:56.109326+00
AVAX/USD	5m	1786828800	6.5	6.5	6.5	6.5	150	2026-08-15 21:24:56.109326+00
BTC/USD	1m	1786829040	63199.78	63199.78	63199.78	63199.78	31	2026-08-15 21:24:56.109326+00
BTC/USD	5m	1786828800	63199.78	63199.78	63140	63199.78	151	2026-08-15 21:24:56.109326+00
LTC/USD	1m	1786829040	44.23	44.23	44.23	44.23	31	2026-08-15 21:24:56.109326+00
LTC/USD	5m	1786828800	44.23	44.23	44.23	44.23	151	2026-08-15 21:24:56.109326+00
XLM/USD	1m	1786829040	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:24:56.109326+00
XLM/USD	5m	1786828800	0.15774	0.15774	0.15774	0.15774	151	2026-08-15 21:24:56.109326+00
BCH/USD	1m	1786829040	203.4	203.4	203.4	203.4	31	2026-08-15 21:24:56.109326+00
BCH/USD	5m	1786828800	203.4	203.4	203.4	203.4	151	2026-08-15 21:24:56.109326+00
XRP/USD	1m	1786829040	1.00246	1.00246	1.00246	1.00246	31	2026-08-15 21:24:56.109326+00
XRP/USD	5m	1786828800	1.00561	1.00561	1.00246	1.00246	151	2026-08-15 21:24:56.109326+00
DOGE/USD	1m	1786829040	0.0702152	0.0702152	0.0702152	0.0702152	30	2026-08-15 21:24:56.109326+00
DOGE/USD	5m	1786828800	0.0702197	0.0702197	0.0702137	0.0702152	151	2026-08-15 21:24:56.109326+00
ETH/USD	1m	1786829040	1883	1883	1883	1883	31	2026-08-15 21:24:56.109326+00
ETH/USD	5m	1786828800	1880.72	1883	1880.72	1883	151	2026-08-15 21:24:56.109326+00
ADA/USD	1m	1786829040	0.1777	0.1777	0.1777	0.1777	30	2026-08-15 21:24:56.109326+00
ADA/USD	5m	1786828800	0.1782	0.1782	0.1777	0.1777	151	2026-08-15 21:24:56.109326+00
SOL/USD	1m	1786829100	75.538	75.538	75.538	75.538	30	2026-08-15 21:25:56.108452+00
DOT/USD	1m	1786829100	0.766	0.766	0.766	0.766	30	2026-08-15 21:25:56.108452+00
AVAX/USD	1m	1786829100	6.5	6.5	6.5	6.5	30	2026-08-15 21:25:56.108452+00
AAVE/USD	1m	1786829100	86.32	86.32	86.32	86.32	30	2026-08-15 21:25:56.108452+00
LINK/USD	1m	1786829100	9.575	9.575	9.564	9.564	30	2026-08-15 21:25:56.108452+00
LTC/USD	1m	1786829100	44.23	44.23	44.23	44.23	29	2026-08-15 21:25:56.108452+00
BCH/USD	1m	1786829100	203.4	203.4	203.4	203.4	29	2026-08-15 21:25:56.108452+00
ADA/USD	1m	1786829100	0.1777	0.1777	0.1777	0.1777	29	2026-08-15 21:25:56.108452+00
POL/USD	1m	1786829100	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:25:56.108452+00
XRP/USD	1m	1786829100	1.00246	1.0035	1.00246	1.0035	29	2026-08-15 21:25:56.108452+00
NEAR/USD	1m	1786829100	1.63	1.63	1.63	1.63	30	2026-08-15 21:25:56.108452+00
XLM/USD	1m	1786829100	0.15774	0.15774	0.15774	0.15774	29	2026-08-15 21:25:56.108452+00
APT/USD	1m	1786829100	0.539	0.539	0.539	0.539	30	2026-08-15 21:25:56.108452+00
BTC/USD	1m	1786829100	63199.78	63199.78	63199.78	63199.78	29	2026-08-15 21:25:56.108452+00
DOGE/USD	1m	1786829100	0.0702152	0.0702152	0.0702152	0.0702152	29	2026-08-15 21:25:56.108452+00
HBAR/USD	1m	1786829100	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:25:56.108452+00
ETH/USD	1m	1786829100	1883	1883	1883	1883	29	2026-08-15 21:25:56.108452+00
UNI/USD	1m	1786829100	3.245	3.245	3.245	3.245	30	2026-08-15 21:25:56.108452+00
SUI/USD	1m	1786829100	0.6816	0.6816	0.6816	0.6816	31	2026-08-15 21:25:56.108452+00
XRP/USD	1m	1786829160	1.0035	1.0035	1.0035	1.0035	30	2026-08-15 21:26:56.108252+00
AVAX/USD	1m	1786829160	6.5	6.5	6.5	6.5	30	2026-08-15 21:26:56.108252+00
ADA/USD	1m	1786829160	0.1777	0.1777	0.1777	0.1777	30	2026-08-15 21:26:56.108252+00
POL/USD	1m	1786829160	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:26:56.108252+00
AAVE/USD	1m	1786829160	86.32	86.32	86.32	86.32	30	2026-08-15 21:26:56.108252+00
DOT/USD	1m	1786829160	0.766	0.766	0.766	0.766	30	2026-08-15 21:26:56.108252+00
UNI/USD	1m	1786829160	3.245	3.245	3.245	3.245	30	2026-08-15 21:26:56.108252+00
BCH/USD	1m	1786829160	203.4	203.4	203.4	203.4	30	2026-08-15 21:26:56.108252+00
DOGE/USD	1m	1786829160	0.0702152	0.0702152	0.0702152	0.0702152	30	2026-08-15 21:26:56.108252+00
HBAR/USD	1m	1786829160	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:26:56.108252+00
XLM/USD	1m	1786829160	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:26:56.108252+00
NEAR/USD	1m	1786829160	1.63	1.63	1.63	1.63	30	2026-08-15 21:26:56.108252+00
SOL/USD	1m	1786829160	75.538	75.538	75.538	75.538	30	2026-08-15 21:26:56.108252+00
ETH/USD	1m	1786829160	1883	1883	1883	1883	30	2026-08-15 21:26:56.108252+00
LTC/USD	1m	1786829160	44.23	44.23	44.23	44.23	30	2026-08-15 21:26:56.108252+00
APT/USD	1m	1786829160	0.539	0.539	0.539	0.539	30	2026-08-15 21:26:56.108252+00
LINK/USD	1m	1786829160	9.564	9.564	9.564	9.564	30	2026-08-15 21:26:56.108252+00
BTC/USD	1m	1786829160	63199.78	63199.78	63199.78	63199.78	30	2026-08-15 21:26:56.108252+00
SUI/USD	1m	1786829160	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:26:56.108252+00
DOGE/USD	1m	1786829220	0.0702152	0.0702152	0.0702152	0.0702152	30	2026-08-15 21:27:56.108708+00
AVAX/USD	1m	1786829220	6.5	6.5	6.5	6.5	30	2026-08-15 21:27:56.108708+00
LTC/USD	1m	1786829220	44.23	44.23	44.23	44.23	30	2026-08-15 21:27:56.108708+00
LINK/USD	1m	1786829220	9.564	9.564	9.564	9.564	30	2026-08-15 21:27:56.108708+00
BTC/USD	1m	1786829220	63199.78	63199.78	63199.78	63199.78	30	2026-08-15 21:27:56.108708+00
SOL/USD	1m	1786829220	75.538	75.538	75.538	75.538	30	2026-08-15 21:27:56.108708+00
HBAR/USD	1m	1786829220	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:27:56.108708+00
AAVE/USD	1m	1786829220	86.32	86.32	86.32	86.32	30	2026-08-15 21:27:56.108708+00
XLM/USD	1m	1786829220	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:27:56.108708+00
NEAR/USD	1m	1786829220	1.63	1.63	1.63	1.63	30	2026-08-15 21:27:56.108708+00
POL/USD	1m	1786829220	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:27:56.108708+00
XRP/USD	1m	1786829220	1.0035	1.0035	1.0035	1.0035	30	2026-08-15 21:27:56.108708+00
ADA/USD	1m	1786829220	0.1777	0.1777	0.1777	0.1777	30	2026-08-15 21:27:56.108708+00
ETH/USD	1m	1786829220	1883	1883	1883	1883	30	2026-08-15 21:27:56.108708+00
APT/USD	1m	1786829220	0.539	0.539	0.539	0.539	30	2026-08-15 21:27:56.108708+00
DOT/USD	1m	1786829220	0.766	0.766	0.766	0.766	30	2026-08-15 21:27:56.108708+00
BCH/USD	1m	1786829220	203.4	203.4	203.4	203.4	30	2026-08-15 21:27:56.108708+00
UNI/USD	1m	1786829220	3.245	3.245	3.245	3.245	30	2026-08-15 21:27:56.108708+00
SUI/USD	1m	1786829220	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:27:56.108708+00
BCH/USD	1m	1786829280	203.4	203.4	203.4	203.4	30	2026-08-15 21:28:56.108009+00
AAVE/USD	1m	1786829280	86.32	86.32	86.32	86.32	30	2026-08-15 21:28:56.108009+00
XRP/USD	1m	1786829280	1.0035	1.00558	1.0035	1.00558	30	2026-08-15 21:28:56.108009+00
LTC/USD	1m	1786829280	44.23	44.23	44.16	44.16	30	2026-08-15 21:28:56.108009+00
ETH/USD	1m	1786829280	1883	1883	1883	1883	30	2026-08-15 21:28:56.108009+00
BTC/USD	1m	1786829280	63199.78	63199.78	63199.78	63199.78	30	2026-08-15 21:28:56.108009+00
DOGE/USD	1m	1786829280	0.0702152	0.0702152	0.0702152	0.0702152	30	2026-08-15 21:28:56.108009+00
ADA/USD	1m	1786829280	0.1777	0.1777	0.1777	0.1777	30	2026-08-15 21:28:56.108009+00
DOT/USD	1m	1786829280	0.766	0.766	0.766	0.766	30	2026-08-15 21:28:56.108009+00
SUI/USD	1m	1786829280	0.6816	0.6816	0.6816	0.6816	29	2026-08-15 21:28:56.108009+00
LINK/USD	1m	1786829280	9.564	9.564	9.552	9.552	30	2026-08-15 21:28:56.108009+00
NEAR/USD	1m	1786829280	1.63	1.63	1.63	1.63	30	2026-08-15 21:28:56.108009+00
SOL/USD	1m	1786829280	75.538	75.538	75.538	75.538	30	2026-08-15 21:28:56.108009+00
UNI/USD	1m	1786829280	3.245	3.245	3.245	3.245	30	2026-08-15 21:28:56.108009+00
XLM/USD	1m	1786829280	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:28:56.108009+00
APT/USD	1m	1786829280	0.539	0.539	0.539	0.539	30	2026-08-15 21:28:56.108009+00
POL/USD	1m	1786829280	0.0756	0.0756	0.0756	0.0756	31	2026-08-15 21:28:56.108009+00
HBAR/USD	1m	1786829280	0.06589	0.06589	0.06589	0.06589	31	2026-08-15 21:28:56.108009+00
AVAX/USD	1m	1786829280	6.5	6.5	6.5	6.5	31	2026-08-15 21:28:56.108009+00
ETH/USD	1m	1786829340	1883	1883	1882	1882	30	2026-08-15 21:29:56.108853+00
ETH/USD	5m	1786829100	1883	1883	1882	1882	149	2026-08-15 21:29:56.108853+00
ETH/USD	15m	1786828500	1884.66	1884.66	1880.72	1882	449	2026-08-15 21:29:56.108853+00
ETH/USD	30m	1786827600	1884.46	1884.66	1880.72	1882	900	2026-08-15 21:29:56.108853+00
BCH/USD	1m	1786829340	203.4	203.4	203.4	203.4	30	2026-08-15 21:29:56.108853+00
BCH/USD	5m	1786829100	203.4	203.4	203.4	203.4	149	2026-08-15 21:29:56.108853+00
BCH/USD	15m	1786828500	202.36	203.4	202.36	203.4	449	2026-08-15 21:29:56.108853+00
BCH/USD	30m	1786827600	202.36	203.4	202.36	203.4	900	2026-08-15 21:29:56.108853+00
AVAX/USD	1m	1786829340	6.5	6.5	6.5	6.5	29	2026-08-15 21:29:56.108853+00
AVAX/USD	5m	1786829100	6.5	6.5	6.5	6.5	150	2026-08-15 21:29:56.108853+00
AVAX/USD	15m	1786828500	6.5	6.5	6.5	6.5	450	2026-08-15 21:29:56.108853+00
AVAX/USD	30m	1786827600	6.491	6.523	6.491	6.5	900	2026-08-15 21:29:56.108853+00
AAVE/USD	1m	1786829340	86.32	86.32	86.32	86.32	30	2026-08-15 21:29:56.108853+00
AAVE/USD	5m	1786829100	86.32	86.32	86.32	86.32	150	2026-08-15 21:29:56.108853+00
AAVE/USD	15m	1786828500	86.32	86.32	86.32	86.32	450	2026-08-15 21:29:56.108853+00
AAVE/USD	30m	1786827600	85.97	86.48	85.01	86.32	900	2026-08-15 21:29:56.108853+00
BTC/USD	1m	1786829340	63199.78	63199.78	63122.33	63122.42	30	2026-08-15 21:29:56.108853+00
BTC/USD	5m	1786829100	63199.78	63199.78	63122.33	63122.42	149	2026-08-15 21:29:56.108853+00
BTC/USD	15m	1786828500	63199.78	63199.78	63122.33	63122.42	449	2026-08-15 21:29:56.108853+00
BTC/USD	30m	1786827600	63100.21	63199.78	63100.21	63122.42	900	2026-08-15 21:29:56.108853+00
DOGE/USD	1m	1786829340	0.0702152	0.0702152	0.0702152	0.0702152	30	2026-08-15 21:29:56.108853+00
DOGE/USD	5m	1786829100	0.0702152	0.0702152	0.0702152	0.0702152	149	2026-08-15 21:29:56.108853+00
DOGE/USD	15m	1786828500	0.0698501	0.0702197	0.0698501	0.0702152	450	2026-08-15 21:29:56.108853+00
DOGE/USD	30m	1786827600	0.0698501	0.0702197	0.0698501	0.0702152	900	2026-08-15 21:29:56.108853+00
DOT/USD	1m	1786829340	0.766	0.766	0.766	0.766	30	2026-08-15 21:29:56.108853+00
DOT/USD	5m	1786829100	0.766	0.766	0.766	0.766	150	2026-08-15 21:29:56.108853+00
DOT/USD	15m	1786828500	0.766	0.766	0.766	0.766	450	2026-08-15 21:29:56.108853+00
DOT/USD	30m	1786827600	0.765	0.766	0.765	0.766	900	2026-08-15 21:29:56.108853+00
ADA/USD	1m	1786829340	0.1777	0.1777	0.1777	0.1777	30	2026-08-15 21:29:56.108853+00
ADA/USD	5m	1786829100	0.1777	0.1777	0.1777	0.1777	149	2026-08-15 21:29:56.108853+00
ADA/USD	15m	1786828500	0.1782	0.1782	0.1777	0.1777	450	2026-08-15 21:29:56.108853+00
ADA/USD	30m	1786827600	0.1782	0.1782	0.1777	0.1777	900	2026-08-15 21:29:56.108853+00
NEAR/USD	1m	1786829340	1.63	1.63	1.63	1.63	30	2026-08-15 21:29:56.108853+00
NEAR/USD	5m	1786829100	1.63	1.63	1.63	1.63	150	2026-08-15 21:29:56.108853+00
NEAR/USD	15m	1786828500	1.63	1.63	1.63	1.63	450	2026-08-15 21:29:56.108853+00
NEAR/USD	30m	1786827600	1.63	1.63	1.63	1.63	900	2026-08-15 21:29:56.108853+00
UNI/USD	1m	1786829340	3.245	3.245	3.245	3.245	30	2026-08-15 21:29:56.108853+00
UNI/USD	5m	1786829100	3.245	3.245	3.245	3.245	150	2026-08-15 21:29:56.108853+00
UNI/USD	15m	1786828500	3.239	3.245	3.239	3.245	450	2026-08-15 21:29:56.108853+00
UNI/USD	30m	1786827600	3.241	3.245	3.238	3.245	900	2026-08-15 21:29:56.108853+00
XRP/USD	1m	1786829340	1.00558	1.00558	1.00558	1.00558	30	2026-08-15 21:29:56.108853+00
XRP/USD	5m	1786829100	1.00246	1.00558	1.00246	1.00558	149	2026-08-15 21:29:56.108853+00
XRP/USD	15m	1786828500	1.00561	1.00561	1.00246	1.00558	449	2026-08-15 21:29:56.108853+00
XRP/USD	30m	1786827600	1.00159	1.00561	1.00159	1.00558	900	2026-08-15 21:29:56.108853+00
POL/USD	1m	1786829340	0.0756	0.0756	0.0756	0.0756	29	2026-08-15 21:29:56.108853+00
POL/USD	5m	1786829100	0.0756	0.0756	0.0756	0.0756	150	2026-08-15 21:29:56.108853+00
POL/USD	15m	1786828500	0.0756	0.0756	0.0756	0.0756	450	2026-08-15 21:29:56.108853+00
POL/USD	30m	1786827600	0.0756	0.0756	0.0756	0.0756	900	2026-08-15 21:29:56.108853+00
HBAR/USD	1m	1786829340	0.06589	0.06589	0.06589	0.06589	29	2026-08-15 21:29:56.108853+00
HBAR/USD	5m	1786829100	0.06589	0.06589	0.06589	0.06589	150	2026-08-15 21:29:56.108853+00
HBAR/USD	15m	1786828500	0.06589	0.06589	0.06589	0.06589	450	2026-08-15 21:29:56.108853+00
HBAR/USD	30m	1786827600	0.06565	0.06589	0.06565	0.06589	900	2026-08-15 21:29:56.108853+00
LINK/USD	1m	1786829340	9.552	9.556	9.552	9.556	30	2026-08-15 21:29:56.108853+00
LINK/USD	5m	1786829100	9.575	9.575	9.552	9.556	150	2026-08-15 21:29:56.108853+00
LINK/USD	15m	1786828500	9.56	9.575	9.552	9.556	450	2026-08-15 21:29:56.108853+00
LINK/USD	30m	1786827600	9.543	9.575	9.543	9.556	900	2026-08-15 21:29:56.108853+00
APT/USD	1m	1786829340	0.539	0.539	0.539	0.539	30	2026-08-15 21:29:56.108853+00
APT/USD	5m	1786829100	0.539	0.539	0.539	0.539	150	2026-08-15 21:29:56.108853+00
APT/USD	15m	1786828500	0.539	0.539	0.539	0.539	450	2026-08-15 21:29:56.108853+00
APT/USD	30m	1786827600	0.54	0.54	0.539	0.539	900	2026-08-15 21:29:56.108853+00
XLM/USD	1m	1786829340	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:29:56.108853+00
XLM/USD	5m	1786829100	0.15774	0.15774	0.15774	0.15774	149	2026-08-15 21:29:56.108853+00
XLM/USD	15m	1786828500	0.15774	0.15774	0.15774	0.15774	450	2026-08-15 21:29:56.108853+00
XLM/USD	30m	1786827600	0.15774	0.15774	0.15774	0.15774	900	2026-08-15 21:29:56.108853+00
SOL/USD	1m	1786829340	75.538	75.538	75.538	75.538	30	2026-08-15 21:29:56.108853+00
SOL/USD	5m	1786829100	75.538	75.538	75.538	75.538	150	2026-08-15 21:29:56.108853+00
SOL/USD	15m	1786828500	75.7	75.7	75.538	75.538	450	2026-08-15 21:29:56.108853+00
SOL/USD	30m	1786827600	75.559	75.7	75.538	75.538	900	2026-08-15 21:29:56.108853+00
SUI/USD	1m	1786829340	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:29:56.108853+00
SUI/USD	5m	1786829100	0.6816	0.6816	0.6816	0.6816	150	2026-08-15 21:29:56.108853+00
SUI/USD	15m	1786828500	0.6816	0.6816	0.6816	0.6816	450	2026-08-15 21:29:56.108853+00
SUI/USD	30m	1786827600	0.68	0.6816	0.68	0.6816	899	2026-08-15 21:29:56.108853+00
LTC/USD	1m	1786829340	44.16	44.16	44.16	44.16	30	2026-08-15 21:29:56.108853+00
LTC/USD	5m	1786829100	44.23	44.23	44.16	44.16	149	2026-08-15 21:29:56.108853+00
LTC/USD	15m	1786828500	44.23	44.23	44.16	44.16	449	2026-08-15 21:29:56.108853+00
LTC/USD	30m	1786827600	44.23	44.23	44.16	44.16	900	2026-08-15 21:29:56.108853+00
ADA/USD	1m	1786829400	0.1777	0.1777	0.1777	0.1777	30	2026-08-15 21:30:56.107766+00
AVAX/USD	1m	1786829400	6.5	6.5	6.5	6.5	30	2026-08-15 21:30:56.107766+00
XLM/USD	1m	1786829400	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:30:56.107766+00
HBAR/USD	1m	1786829400	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:30:56.107766+00
SOL/USD	1m	1786829400	75.538	75.728	75.538	75.728	30	2026-08-15 21:30:56.107766+00
ETH/USD	1m	1786829400	1882	1882	1882	1882	30	2026-08-15 21:30:56.107766+00
DOGE/USD	1m	1786829400	0.0702152	0.0702152	0.0702152	0.0702152	30	2026-08-15 21:30:56.107766+00
APT/USD	1m	1786829400	0.539	0.539	0.539	0.539	30	2026-08-15 21:30:56.107766+00
LTC/USD	1m	1786829400	44.16	44.16	44.16	44.16	30	2026-08-15 21:30:56.107766+00
AAVE/USD	1m	1786829400	86.32	86.32	86.32	86.32	30	2026-08-15 21:30:56.107766+00
UNI/USD	1m	1786829400	3.245	3.245	3.245	3.245	30	2026-08-15 21:30:56.107766+00
NEAR/USD	1m	1786829400	1.63	1.63	1.63	1.63	30	2026-08-15 21:30:56.107766+00
BTC/USD	1m	1786829400	63122.42	63122.42	63122.42	63122.42	30	2026-08-15 21:30:56.107766+00
DOT/USD	1m	1786829400	0.766	0.766	0.766	0.766	30	2026-08-15 21:30:56.107766+00
XRP/USD	1m	1786829400	1.00558	1.00558	1.00558	1.00558	30	2026-08-15 21:30:56.107766+00
BCH/USD	1m	1786829400	203.4	203.4	203.4	203.4	30	2026-08-15 21:30:56.107766+00
POL/USD	1m	1786829400	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:30:56.107766+00
LINK/USD	1m	1786829400	9.556	9.556	9.552	9.552	30	2026-08-15 21:30:56.107766+00
SUI/USD	1m	1786829400	0.6816	0.6816	0.6816	0.6816	31	2026-08-15 21:30:56.107766+00
AVAX/USD	1m	1786829460	6.5	6.5	6.5	6.5	30	2026-08-15 21:31:56.108348+00
LTC/USD	1m	1786829460	44.16	44.16	44.16	44.16	30	2026-08-15 21:31:56.108348+00
SUI/USD	1m	1786829460	0.6816	0.6816	0.6816	0.6816	29	2026-08-15 21:31:56.108348+00
ETH/USD	1m	1786829460	1882	1882	1882	1882	30	2026-08-15 21:31:56.108348+00
BTC/USD	1m	1786829460	63122.42	63122.42	63122.24	63122.24	30	2026-08-15 21:31:56.108348+00
HBAR/USD	1m	1786829460	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:31:56.108348+00
BCH/USD	1m	1786829460	203.4	203.4	203.4	203.4	30	2026-08-15 21:31:56.108348+00
XLM/USD	1m	1786829460	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:31:56.108348+00
XRP/USD	1m	1786829460	1.00558	1.00558	1.00558	1.00558	30	2026-08-15 21:31:56.108348+00
DOGE/USD	1m	1786829460	0.0702152	0.0702152	0.0702152	0.0702152	30	2026-08-15 21:31:56.108348+00
APT/USD	1m	1786829460	0.539	0.539	0.539	0.539	31	2026-08-15 21:31:56.108348+00
NEAR/USD	1m	1786829460	1.63	1.63	1.63	1.63	31	2026-08-15 21:31:56.108348+00
SOL/USD	1m	1786829460	75.728	75.75	75.728	75.75	31	2026-08-15 21:31:56.108348+00
AAVE/USD	1m	1786829460	86.32	86.32	86.32	86.32	31	2026-08-15 21:31:56.108348+00
POL/USD	1m	1786829460	0.0756	0.0756	0.0756	0.0756	31	2026-08-15 21:31:56.108348+00
UNI/USD	1m	1786829460	3.245	3.245	3.245	3.245	31	2026-08-15 21:31:56.108348+00
LINK/USD	1m	1786829460	9.552	9.552	9.552	9.552	31	2026-08-15 21:31:56.108348+00
ADA/USD	1m	1786829460	0.1777	0.1777	0.1777	0.1777	31	2026-08-15 21:31:56.108348+00
DOT/USD	1m	1786829460	0.766	0.766	0.766	0.766	31	2026-08-15 21:31:56.108348+00
DOT/USD	1m	1786829520	0.766	0.766	0.766	0.766	29	2026-08-15 21:32:56.11843+00
NEAR/USD	1m	1786829520	1.63	1.63	1.63	1.63	29	2026-08-15 21:32:56.11843+00
LTC/USD	1m	1786829520	44.16	44.16	44.16	44.16	30	2026-08-15 21:32:56.11843+00
ADA/USD	1m	1786829520	0.1777	0.1777	0.1777	0.1777	29	2026-08-15 21:32:56.11843+00
XRP/USD	1m	1786829520	1.00558	1.00558	1.00558	1.00558	30	2026-08-15 21:32:56.11843+00
LINK/USD	1m	1786829520	9.552	9.552	9.552	9.552	29	2026-08-15 21:32:56.11843+00
AAVE/USD	1m	1786829520	86.32	86.32	86.32	86.32	29	2026-08-15 21:32:56.11843+00
ETH/USD	1m	1786829520	1882	1882	1882	1882	30	2026-08-15 21:32:56.11843+00
SUI/USD	1m	1786829520	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:32:56.11843+00
SOL/USD	1m	1786829520	75.75	75.75	75.75	75.75	29	2026-08-15 21:32:56.11843+00
HBAR/USD	1m	1786829520	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:32:56.11843+00
XLM/USD	1m	1786829520	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:32:56.11843+00
APT/USD	1m	1786829520	0.539	0.539	0.539	0.539	29	2026-08-15 21:32:56.11843+00
DOGE/USD	1m	1786829520	0.0702152	0.07022	0.0702152	0.07022	30	2026-08-15 21:32:56.11843+00
BTC/USD	1m	1786829520	63122.24	63122.24	63122.24	63122.24	30	2026-08-15 21:32:56.11843+00
AVAX/USD	1m	1786829520	6.5	6.5	6.5	6.5	30	2026-08-15 21:32:56.11843+00
POL/USD	1m	1786829520	0.0756	0.0756	0.0756	0.0756	29	2026-08-15 21:32:56.11843+00
BCH/USD	1m	1786829520	203.4	203.4	203.4	203.4	30	2026-08-15 21:32:56.11843+00
UNI/USD	1m	1786829520	3.245	3.25	3.244	3.244	29	2026-08-15 21:32:56.11843+00
DOT/USD	1m	1786829580	0.766	0.766	0.766	0.766	30	2026-08-15 21:33:56.107774+00
NEAR/USD	1m	1786829580	1.63	1.63	1.63	1.63	30	2026-08-15 21:33:56.107774+00
APT/USD	1m	1786829580	0.539	0.539	0.539	0.539	30	2026-08-15 21:33:56.107774+00
SUI/USD	1m	1786829580	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:33:56.107774+00
UNI/USD	1m	1786829580	3.244	3.25	3.244	3.25	30	2026-08-15 21:33:56.107774+00
ADA/USD	1m	1786829580	0.1777	0.1777	0.1777	0.1777	30	2026-08-15 21:33:56.107774+00
AAVE/USD	1m	1786829580	86.32	86.32	86.32	86.32	30	2026-08-15 21:33:56.107774+00
SOL/USD	1m	1786829580	75.75	75.75	75.75	75.75	30	2026-08-15 21:33:56.107774+00
HBAR/USD	1m	1786829580	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:33:56.107774+00
XLM/USD	1m	1786829580	0.15774	0.15774	0.15774	0.15774	30	2026-08-15 21:33:56.107774+00
POL/USD	1m	1786829580	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:33:56.107774+00
LINK/USD	1m	1786829580	9.552	9.552	9.552	9.552	30	2026-08-15 21:33:56.107774+00
AVAX/USD	1m	1786829580	6.5	6.5	6.5	6.5	30	2026-08-15 21:33:56.107774+00
ETH/USD	1m	1786829580	1884.49	1884.49	1884.49	1884.49	31	2026-08-15 21:33:56.107774+00
DOGE/USD	1m	1786829580	0.07022	0.07022	0.07022	0.07022	31	2026-08-15 21:33:56.107774+00
LTC/USD	1m	1786829580	44.16	44.16	44.16	44.16	31	2026-08-15 21:33:56.107774+00
BCH/USD	1m	1786829580	203.4	203.4	203.4	203.4	31	2026-08-15 21:33:56.107774+00
XRP/USD	1m	1786829580	1.00558	1.00558	1.00558	1.00558	31	2026-08-15 21:33:56.107774+00
BTC/USD	1m	1786829580	63122.24	63199.77	63122.24	63199.77	31	2026-08-15 21:33:56.107774+00
SUI/USD	1m	1786829640	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:34:56.108764+00
SUI/USD	5m	1786829400	0.6816	0.6816	0.6816	0.6816	150	2026-08-15 21:34:56.108764+00
HBAR/USD	1m	1786829640	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:34:56.108764+00
HBAR/USD	5m	1786829400	0.06589	0.06589	0.06589	0.06589	150	2026-08-15 21:34:56.108764+00
APT/USD	1m	1786829640	0.539	0.539	0.539	0.539	30	2026-08-15 21:34:56.108764+00
APT/USD	5m	1786829400	0.539	0.539	0.539	0.539	150	2026-08-15 21:34:56.108764+00
AVAX/USD	1m	1786829640	6.5	6.5	6.5	6.5	30	2026-08-15 21:34:56.108764+00
AVAX/USD	5m	1786829400	6.5	6.5	6.5	6.5	150	2026-08-15 21:34:56.108764+00
POL/USD	1m	1786829640	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:34:56.108764+00
POL/USD	5m	1786829400	0.0756	0.0756	0.0756	0.0756	150	2026-08-15 21:34:56.108764+00
ADA/USD	1m	1786829640	0.1777	0.1777	0.1777	0.1777	30	2026-08-15 21:34:56.108764+00
ADA/USD	5m	1786829400	0.1777	0.1777	0.1777	0.1777	150	2026-08-15 21:34:56.108764+00
LTC/USD	1m	1786829640	44.16	44.16	44.16	44.16	30	2026-08-15 21:34:56.108764+00
LTC/USD	5m	1786829400	44.16	44.16	44.16	44.16	151	2026-08-15 21:34:56.108764+00
NEAR/USD	1m	1786829640	1.63	1.63	1.63	1.63	31	2026-08-15 21:34:56.108764+00
NEAR/USD	5m	1786829400	1.63	1.63	1.63	1.63	151	2026-08-15 21:34:56.108764+00
XRP/USD	1m	1786829640	1.00558	1.00558	1.00558	1.00558	30	2026-08-15 21:34:56.108764+00
XRP/USD	5m	1786829400	1.00558	1.00558	1.00558	1.00558	151	2026-08-15 21:34:56.108764+00
DOT/USD	1m	1786829640	0.766	0.766	0.766	0.766	31	2026-08-15 21:34:56.108764+00
DOT/USD	5m	1786829400	0.766	0.766	0.766	0.766	151	2026-08-15 21:34:56.108764+00
LINK/USD	1m	1786829640	9.552	9.552	9.552	9.552	31	2026-08-15 21:34:56.108764+00
LINK/USD	5m	1786829400	9.556	9.556	9.552	9.552	151	2026-08-15 21:34:56.108764+00
XLM/USD	1m	1786829640	0.15774	0.15774	0.15774	0.15774	31	2026-08-15 21:34:56.108764+00
XLM/USD	5m	1786829400	0.15774	0.15774	0.15774	0.15774	151	2026-08-15 21:34:56.108764+00
UNI/USD	1m	1786829640	3.25	3.25	3.25	3.25	31	2026-08-15 21:34:56.108764+00
UNI/USD	5m	1786829400	3.245	3.25	3.244	3.25	151	2026-08-15 21:34:56.108764+00
SOL/USD	1m	1786829640	75.75	75.75	75.75	75.75	31	2026-08-15 21:34:56.108764+00
SOL/USD	5m	1786829400	75.538	75.75	75.538	75.75	151	2026-08-15 21:34:56.108764+00
AAVE/USD	1m	1786829640	86.32	86.32	86.32	86.32	31	2026-08-15 21:34:56.108764+00
AAVE/USD	5m	1786829400	86.32	86.32	86.32	86.32	151	2026-08-15 21:34:56.108764+00
BCH/USD	1m	1786829640	203.4	203.4	203.4	203.4	30	2026-08-15 21:34:56.108764+00
BCH/USD	5m	1786829400	203.4	203.4	203.4	203.4	151	2026-08-15 21:34:56.108764+00
ETH/USD	1m	1786829640	1884.49	1884.49	1884.49	1884.49	30	2026-08-15 21:34:56.108764+00
ETH/USD	5m	1786829400	1882	1884.49	1882	1884.49	151	2026-08-15 21:34:56.108764+00
DOGE/USD	1m	1786829640	0.07022	0.07022	0.07022	0.07022	30	2026-08-15 21:34:56.108764+00
DOGE/USD	5m	1786829400	0.0702152	0.07022	0.0702152	0.07022	151	2026-08-15 21:34:56.108764+00
BTC/USD	1m	1786829640	63199.77	63199.77	63199.77	63199.77	30	2026-08-15 21:34:56.108764+00
BTC/USD	5m	1786829400	63122.42	63199.77	63122.24	63199.77	151	2026-08-15 21:34:56.108764+00
NEAR/USD	1m	1786829700	1.63	1.63	1.63	1.63	29	2026-08-15 21:35:56.107462+00
LINK/USD	1m	1786829700	9.552	9.552	9.55	9.55	29	2026-08-15 21:35:56.107462+00
XLM/USD	1m	1786829700	0.15774	0.15774	0.15774	0.15774	29	2026-08-15 21:35:56.107462+00
DOGE/USD	1m	1786829700	0.07022	0.07022	0.07022	0.07022	29	2026-08-15 21:35:56.107462+00
ADA/USD	1m	1786829700	0.1777	0.1777	0.1777	0.1777	30	2026-08-15 21:35:56.107462+00
DOT/USD	1m	1786829700	0.766	0.766	0.766	0.766	29	2026-08-15 21:35:56.107462+00
POL/USD	1m	1786829700	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:35:56.107462+00
XRP/USD	1m	1786829700	1.00558	1.00558	1.00558	1.00558	29	2026-08-15 21:35:56.107462+00
AAVE/USD	1m	1786829700	86.32	86.32	86.32	86.32	29	2026-08-15 21:35:56.107462+00
SUI/USD	1m	1786829700	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:35:56.107462+00
HBAR/USD	1m	1786829700	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:35:56.107462+00
SOL/USD	1m	1786829700	75.75	75.75	75.75	75.75	29	2026-08-15 21:35:56.107462+00
LTC/USD	1m	1786829700	44.16	44.16	44.16	44.16	29	2026-08-15 21:35:56.107462+00
UNI/USD	1m	1786829700	3.25	3.25	3.245	3.245	29	2026-08-15 21:35:56.107462+00
AVAX/USD	1m	1786829700	6.5	6.5	6.5	6.5	30	2026-08-15 21:35:56.107462+00
ETH/USD	1m	1786829700	1884.49	1884.49	1884.49	1884.49	29	2026-08-15 21:35:56.107462+00
BTC/USD	1m	1786829700	63199.77	63199.77	63199.77	63199.77	29	2026-08-15 21:35:56.107462+00
BCH/USD	1m	1786829700	203.4	203.4	203.4	203.4	29	2026-08-15 21:35:56.107462+00
APT/USD	1m	1786829700	0.539	0.539	0.539	0.539	30	2026-08-15 21:35:56.107462+00
POL/USD	1m	1786829760	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:36:56.107517+00
XRP/USD	1m	1786829760	1.00558	1.00558	1.00558	1.00558	30	2026-08-15 21:36:56.107517+00
SUI/USD	1m	1786829760	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:36:56.107517+00
AVAX/USD	1m	1786829760	6.5	6.5	6.5	6.5	30	2026-08-15 21:36:56.107517+00
ETH/USD	1m	1786829760	1884.49	1884.49	1884.49	1884.49	30	2026-08-15 21:36:56.107517+00
BTC/USD	1m	1786829760	63199.77	63199.77	63122.25	63122.25	30	2026-08-15 21:36:56.107517+00
LTC/USD	1m	1786829760	44.16	44.16	44.16	44.16	30	2026-08-15 21:36:56.107517+00
HBAR/USD	1m	1786829760	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:36:56.107517+00
BCH/USD	1m	1786829760	203.4	203.4	203.4	203.4	31	2026-08-15 21:36:56.107517+00
ADA/USD	1m	1786829760	0.1777	0.1777	0.1777	0.1777	31	2026-08-15 21:36:56.107517+00
UNI/USD	1m	1786829760	3.245	3.245	3.245	3.245	31	2026-08-15 21:36:56.107517+00
NEAR/USD	1m	1786829760	1.63	1.63	1.63	1.63	31	2026-08-15 21:36:56.107517+00
XLM/USD	1m	1786829760	0.15774	0.15852	0.15774	0.15852	31	2026-08-15 21:36:56.107517+00
AAVE/USD	1m	1786829760	86.32	86.32	86.32	86.32	31	2026-08-15 21:36:56.107517+00
SOL/USD	1m	1786829760	75.75	75.75	75.75	75.75	31	2026-08-15 21:36:56.107517+00
DOT/USD	1m	1786829760	0.766	0.766	0.766	0.766	31	2026-08-15 21:36:56.107517+00
APT/USD	1m	1786829760	0.539	0.539	0.539	0.539	31	2026-08-15 21:36:56.107517+00
DOGE/USD	1m	1786829760	0.07022	0.07022	0.07022	0.07022	31	2026-08-15 21:36:56.107517+00
LINK/USD	1m	1786829760	9.55	9.55	9.55	9.55	31	2026-08-15 21:36:56.107517+00
SUI/USD	1m	1786829820	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:37:56.107326+00
NEAR/USD	1m	1786829820	1.63	1.63	1.63	1.63	29	2026-08-15 21:37:56.107326+00
SOL/USD	1m	1786829820	75.75	75.75	75.75	75.75	29	2026-08-15 21:37:56.107326+00
LINK/USD	1m	1786829820	9.55	9.55	9.55	9.55	29	2026-08-15 21:37:56.107326+00
POL/USD	1m	1786829820	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:37:56.107326+00
DOT/USD	1m	1786829820	0.766	0.766	0.766	0.766	29	2026-08-15 21:37:56.107326+00
HBAR/USD	1m	1786829820	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:37:56.107326+00
ADA/USD	1m	1786829820	0.1777	0.1777	0.1777	0.1777	29	2026-08-15 21:37:56.107326+00
AAVE/USD	1m	1786829820	86.32	86.32	86.32	86.32	29	2026-08-15 21:37:56.107326+00
AVAX/USD	1m	1786829820	6.5	6.5	6.5	6.5	30	2026-08-15 21:37:56.107326+00
APT/USD	1m	1786829820	0.539	0.539	0.539	0.539	29	2026-08-15 21:37:56.107326+00
UNI/USD	1m	1786829820	3.245	3.245	3.242	3.242	29	2026-08-15 21:37:56.107326+00
XLM/USD	1m	1786829820	0.15852	0.15852	0.15852	0.15852	30	2026-08-15 21:37:56.107326+00
ETH/USD	1m	1786829820	1884.49	1884.49	1884.49	1884.49	31	2026-08-15 21:37:56.107326+00
DOGE/USD	1m	1786829820	0.07022	0.07022	0.07022	0.07022	30	2026-08-15 21:37:56.107326+00
LTC/USD	1m	1786829820	44.16	44.16	44.16	44.16	31	2026-08-15 21:37:56.107326+00
XRP/USD	1m	1786829820	1.00558	1.00558	1.00558	1.00558	31	2026-08-15 21:37:56.107326+00
BTC/USD	1m	1786829820	63122.25	63122.25	63122.25	63122.25	31	2026-08-15 21:37:56.107326+00
BCH/USD	1m	1786829820	203.4	203.4	203.4	203.4	30	2026-08-15 21:37:56.107326+00
XRP/USD	1m	1786829880	1.00558	1.00558	1.00558	1.00558	29	2026-08-15 21:38:56.109708+00
HBAR/USD	1m	1786829880	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:38:56.109708+00
POL/USD	1m	1786829880	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:38:56.109708+00
BCH/USD	1m	1786829880	203.4	203.4	203.4	203.4	29	2026-08-15 21:38:56.109708+00
AAVE/USD	1m	1786829880	86.32	86.32	86.32	86.32	30	2026-08-15 21:38:56.109708+00
XLM/USD	1m	1786829880	0.15852	0.15852	0.15852	0.15852	29	2026-08-15 21:38:56.109708+00
LTC/USD	1m	1786829880	44.16	44.16	44.16	44.16	29	2026-08-15 21:38:56.109708+00
SUI/USD	1m	1786829880	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:38:56.109708+00
UNI/USD	1m	1786829880	3.242	3.242	3.242	3.242	30	2026-08-15 21:38:56.109708+00
ADA/USD	1m	1786829880	0.1777	0.1777	0.1777	0.1777	30	2026-08-15 21:38:56.109708+00
NEAR/USD	1m	1786829880	1.63	1.631	1.63	1.631	30	2026-08-15 21:38:56.109708+00
BTC/USD	1m	1786829880	63122.25	63203	63122.25	63203	29	2026-08-15 21:38:56.109708+00
LINK/USD	1m	1786829880	9.55	9.555	9.55	9.555	30	2026-08-15 21:38:56.109708+00
SOL/USD	1m	1786829880	75.75	75.75	75.534	75.534	30	2026-08-15 21:38:56.109708+00
DOGE/USD	1m	1786829880	0.07022	0.07022	0.07022	0.07022	29	2026-08-15 21:38:56.109708+00
DOT/USD	1m	1786829880	0.766	0.766	0.766	0.766	30	2026-08-15 21:38:56.109708+00
APT/USD	1m	1786829880	0.539	0.539	0.539	0.539	30	2026-08-15 21:38:56.109708+00
ETH/USD	1m	1786829880	1884.49	1884.5	1884.49	1884.5	29	2026-08-15 21:38:56.109708+00
AVAX/USD	1m	1786829880	6.5	6.5	6.5	6.5	30	2026-08-15 21:38:56.109708+00
BTC/USD	1m	1786829940	63203	63203	63122.25	63122.25	30	2026-08-15 21:39:56.108806+00
BTC/USD	5m	1786829700	63199.77	63203	63122.25	63122.25	149	2026-08-15 21:39:56.108806+00
AVAX/USD	1m	1786829940	6.5	6.5	6.5	6.5	30	2026-08-15 21:39:56.108806+00
AVAX/USD	5m	1786829700	6.5	6.5	6.5	6.5	150	2026-08-15 21:39:56.108806+00
LTC/USD	1m	1786829940	44.16	44.16	44.16	44.16	30	2026-08-15 21:39:56.108806+00
LTC/USD	5m	1786829700	44.16	44.16	44.16	44.16	149	2026-08-15 21:39:56.108806+00
BCH/USD	1m	1786829940	203.4	203.4	203.4	203.4	30	2026-08-15 21:39:56.108806+00
BCH/USD	5m	1786829700	203.4	203.4	203.4	203.4	149	2026-08-15 21:39:56.108806+00
POL/USD	1m	1786829940	0.0756	0.0756	0.0756	0.0756	30	2026-08-15 21:39:56.108806+00
POL/USD	5m	1786829700	0.0756	0.0756	0.0756	0.0756	150	2026-08-15 21:39:56.108806+00
XRP/USD	1m	1786829940	1.00558	1.00558	1.00558	1.00558	30	2026-08-15 21:39:56.108806+00
XRP/USD	5m	1786829700	1.00558	1.00558	1.00558	1.00558	149	2026-08-15 21:39:56.108806+00
DOGE/USD	1m	1786829940	0.07022	0.07022	0.07022	0.07022	30	2026-08-15 21:39:56.108806+00
DOGE/USD	5m	1786829700	0.07022	0.07022	0.07022	0.07022	149	2026-08-15 21:39:56.108806+00
ETH/USD	1m	1786829940	1884.5	1884.5	1884.5	1884.5	30	2026-08-15 21:39:56.108806+00
ETH/USD	5m	1786829700	1884.49	1884.5	1884.49	1884.5	149	2026-08-15 21:39:56.108806+00
HBAR/USD	1m	1786829940	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:39:56.108806+00
HBAR/USD	5m	1786829700	0.06589	0.06589	0.06589	0.06589	150	2026-08-15 21:39:56.108806+00
SUI/USD	1m	1786829940	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:39:56.108806+00
SUI/USD	5m	1786829700	0.6816	0.6816	0.6816	0.6816	150	2026-08-15 21:39:56.108806+00
SOL/USD	1m	1786829940	75.534	75.534	75.534	75.534	31	2026-08-15 21:39:56.108806+00
SOL/USD	5m	1786829700	75.75	75.75	75.534	75.534	150	2026-08-15 21:39:56.108806+00
ADA/USD	1m	1786829940	0.1777	0.1777	0.1777	0.1777	31	2026-08-15 21:39:56.108806+00
ADA/USD	5m	1786829700	0.1777	0.1777	0.1777	0.1777	151	2026-08-15 21:39:56.108806+00
NEAR/USD	1m	1786829940	1.631	1.631	1.631	1.631	31	2026-08-15 21:39:56.108806+00
NEAR/USD	5m	1786829700	1.63	1.631	1.63	1.631	150	2026-08-15 21:39:56.108806+00
APT/USD	1m	1786829940	0.539	0.539	0.539	0.539	31	2026-08-15 21:39:56.108806+00
APT/USD	5m	1786829700	0.539	0.539	0.539	0.539	151	2026-08-15 21:39:56.108806+00
DOT/USD	1m	1786829940	0.766	0.766	0.766	0.766	31	2026-08-15 21:39:56.108806+00
DOT/USD	5m	1786829700	0.766	0.766	0.766	0.766	150	2026-08-15 21:39:56.108806+00
AAVE/USD	1m	1786829940	86.32	86.32	86.32	86.32	31	2026-08-15 21:39:56.108806+00
AAVE/USD	5m	1786829700	86.32	86.32	86.32	86.32	150	2026-08-15 21:39:56.108806+00
LINK/USD	1m	1786829940	9.555	9.555	9.555	9.555	31	2026-08-15 21:39:56.108806+00
LINK/USD	5m	1786829700	9.552	9.555	9.55	9.555	150	2026-08-15 21:39:56.108806+00
UNI/USD	1m	1786829940	3.242	3.242	3.242	3.242	31	2026-08-15 21:39:56.108806+00
UNI/USD	5m	1786829700	3.25	3.25	3.242	3.242	150	2026-08-15 21:39:56.108806+00
XLM/USD	1m	1786829940	0.15852	0.15852	0.15852	0.15852	31	2026-08-15 21:39:56.108806+00
XLM/USD	5m	1786829700	0.15774	0.15852	0.15774	0.15852	150	2026-08-15 21:39:56.108806+00
SUI/USD	1m	1786830000	0.6816	0.6816	0.6816	0.6816	30	2026-08-15 21:40:56.107947+00
XLM/USD	1m	1786830000	0.15852	0.15852	0.15852	0.15852	29	2026-08-15 21:40:56.107947+00
LTC/USD	1m	1786830000	44.16	44.16	44.16	44.16	30	2026-08-15 21:40:56.107947+00
HBAR/USD	1m	1786830000	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:40:56.107947+00
BTC/USD	1m	1786830000	63122.25	63122.25	63122.25	63122.25	30	2026-08-15 21:40:56.107947+00
BCH/USD	1m	1786830000	203.4	203.4	203.4	203.4	30	2026-08-15 21:40:56.107947+00
AVAX/USD	1m	1786830000	6.5	6.5	6.5	6.5	30	2026-08-15 21:40:56.107947+00
ETH/USD	1m	1786830000	1884.5	1884.5	1884.5	1884.5	30	2026-08-15 21:40:56.107947+00
XRP/USD	1m	1786830000	1.00558	1.00558	1.00558	1.00558	30	2026-08-15 21:40:56.107947+00
DOGE/USD	1m	1786830000	0.07022	0.07022	0.07022	0.07022	30	2026-08-15 21:40:56.107947+00
APT/USD	1m	1786830000	0.539	0.539	0.539	0.539	30	2026-08-15 21:40:56.107947+00
DOT/USD	1m	1786830000	0.766	0.766	0.766	0.766	30	2026-08-15 21:40:56.107947+00
POL/USD	1m	1786830000	0.0756	0.0756	0.0756	0.0756	31	2026-08-15 21:40:56.107947+00
UNI/USD	1m	1786830000	3.242	3.242	3.242	3.242	30	2026-08-15 21:40:56.107947+00
ADA/USD	1m	1786830000	0.1777	0.1777	0.1777	0.1777	30	2026-08-15 21:40:56.107947+00
SOL/USD	1m	1786830000	75.534	75.534	75.534	75.534	30	2026-08-15 21:40:56.107947+00
LINK/USD	1m	1786830000	9.555	9.555	9.555	9.555	30	2026-08-15 21:40:56.107947+00
AAVE/USD	1m	1786830000	86.32	86.32	86.32	86.32	30	2026-08-15 21:40:56.107947+00
NEAR/USD	1m	1786830000	1.631	1.631	1.631	1.631	30	2026-08-15 21:40:56.107947+00
ETH/USD	1m	1786830060	1884.5	1884.5	1884.5	1884.5	30	2026-08-15 21:41:56.107305+00
BTC/USD	1m	1786830060	63122.25	63122.25	63122.25	63122.25	30	2026-08-15 21:41:56.107305+00
HBAR/USD	1m	1786830060	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:41:56.107305+00
AVAX/USD	1m	1786830060	6.5	6.5	6.5	6.5	30	2026-08-15 21:41:56.107305+00
POL/USD	1m	1786830060	0.0756	0.0756	0.0756	0.0756	29	2026-08-15 21:41:56.107305+00
SUI/USD	1m	1786830060	0.6816	0.6816	0.6784	0.6784	30	2026-08-15 21:41:56.107305+00
XLM/USD	1m	1786830060	0.15852	0.15852	0.15852	0.15852	31	2026-08-15 21:41:56.107305+00
LINK/USD	1m	1786830060	9.555	9.555	9.555	9.555	30	2026-08-15 21:41:56.107305+00
BCH/USD	1m	1786830060	203.4	203.4	203.4	203.4	31	2026-08-15 21:41:56.107305+00
XRP/USD	1m	1786830060	1.00558	1.00558	1.00558	1.00558	31	2026-08-15 21:41:56.107305+00
DOT/USD	1m	1786830060	0.766	0.766	0.766	0.766	30	2026-08-15 21:41:56.107305+00
AAVE/USD	1m	1786830060	86.32	86.32	86.32	86.32	30	2026-08-15 21:41:56.107305+00
APT/USD	1m	1786830060	0.539	0.539	0.539	0.539	30	2026-08-15 21:41:56.107305+00
NEAR/USD	1m	1786830060	1.631	1.631	1.631	1.631	30	2026-08-15 21:41:56.107305+00
UNI/USD	1m	1786830060	3.242	3.242	3.242	3.242	30	2026-08-15 21:41:56.107305+00
DOGE/USD	1m	1786830060	0.07022	0.07022	0.0702199	0.0702199	31	2026-08-15 21:41:56.107305+00
SOL/USD	1m	1786830060	75.534	75.534	75.534	75.534	30	2026-08-15 21:41:56.107305+00
LTC/USD	1m	1786830060	44.16	44.16	44.16	44.16	31	2026-08-15 21:41:56.107305+00
ADA/USD	1m	1786830060	0.1777	0.1777	0.1777	0.1777	30	2026-08-15 21:41:56.107305+00
LINK/USD	1m	1786830120	9.555	9.555	9.555	9.555	28	2026-08-15 21:43:01.108525+00
APT/USD	1m	1786830120	0.539	0.539	0.539	0.539	28	2026-08-15 21:43:01.108525+00
AVAX/USD	1m	1786830120	6.5	6.5	6.5	6.5	29	2026-08-15 21:43:01.108525+00
POL/USD	1m	1786830120	0.0756	0.0756	0.0756	0.0756	29	2026-08-15 21:43:01.108525+00
SOL/USD	1m	1786830120	75.534	75.534	75.534	75.534	28	2026-08-15 21:43:01.108525+00
AAVE/USD	1m	1786830120	86.32	86.32	86.32	86.32	28	2026-08-15 21:43:01.108525+00
SUI/USD	1m	1786830120	0.6784	0.6784	0.6784	0.6784	29	2026-08-15 21:43:01.108525+00
BTC/USD	1m	1786830120	63122.25	63122.25	63122.25	63122.25	29	2026-08-15 21:43:01.108525+00
DOT/USD	1m	1786830120	0.766	0.766	0.766	0.766	28	2026-08-15 21:43:01.108525+00
NEAR/USD	1m	1786830120	1.631	1.631	1.631	1.631	28	2026-08-15 21:43:01.108525+00
HBAR/USD	1m	1786830120	0.06589	0.06589	0.06589	0.06589	29	2026-08-15 21:43:01.108525+00
LTC/USD	1m	1786830120	44.16	44.16	44.16	44.16	28	2026-08-15 21:43:01.108525+00
DOGE/USD	1m	1786830120	0.0702199	0.07022	0.0702199	0.07022	28	2026-08-15 21:43:01.108525+00
BCH/USD	1m	1786830120	203.4	203.4	203.4	203.4	28	2026-08-15 21:43:01.108525+00
ADA/USD	1m	1786830120	0.1777	0.1777	0.1777	0.1777	28	2026-08-15 21:43:01.108525+00
XRP/USD	1m	1786830120	1.00558	1.00558	1.00558	1.00558	28	2026-08-15 21:43:01.108525+00
ETH/USD	1m	1786830120	1884.5	1884.5	1884.5	1884.5	29	2026-08-15 21:43:01.108525+00
UNI/USD	1m	1786830120	3.242	3.242	3.242	3.242	28	2026-08-15 21:43:01.108525+00
XLM/USD	1m	1786830120	0.15852	0.15852	0.15852	0.15852	28	2026-08-15 21:43:01.108525+00
POL/USD	1m	1786830180	0.0756	0.0756	0.0756	0.0756	26	2026-08-15 21:43:56.114976+00
APT/USD	1m	1786830180	0.539	0.539	0.539	0.539	26	2026-08-15 21:43:56.114976+00
BTC/USD	1m	1786830180	63122.25	63146	63122.25	63146	26	2026-08-15 21:43:56.114976+00
BCH/USD	1m	1786830180	203.4	203.4	203.4	203.4	26	2026-08-15 21:43:56.114976+00
SOL/USD	1m	1786830180	75.534	75.534	75.534	75.534	26	2026-08-15 21:43:56.114976+00
DOT/USD	1m	1786830180	0.766	0.766	0.766	0.766	26	2026-08-15 21:43:56.114976+00
AVAX/USD	1m	1786830180	6.5	6.5	6.5	6.5	26	2026-08-15 21:43:56.114976+00
UNI/USD	1m	1786830180	3.242	3.242	3.242	3.242	26	2026-08-15 21:43:56.114976+00
LINK/USD	1m	1786830180	9.555	9.555	9.555	9.555	26	2026-08-15 21:43:56.114976+00
DOGE/USD	1m	1786830180	0.07022	0.07022	0.07022	0.07022	26	2026-08-15 21:43:56.114976+00
XRP/USD	1m	1786830180	1.00558	1.00558	1.00399	1.00399	26	2026-08-15 21:43:56.114976+00
SUI/USD	1m	1786830180	0.6784	0.6784	0.6784	0.6784	26	2026-08-15 21:43:56.114976+00
NEAR/USD	1m	1786830180	1.631	1.631	1.631	1.631	26	2026-08-15 21:43:56.114976+00
HBAR/USD	1m	1786830180	0.06589	0.06589	0.06589	0.06589	26	2026-08-15 21:43:56.114976+00
XLM/USD	1m	1786830180	0.15852	0.15852	0.15852	0.15852	26	2026-08-15 21:43:56.114976+00
ADA/USD	1m	1786830180	0.1777	0.1777	0.1777	0.1777	26	2026-08-15 21:43:56.114976+00
ETH/USD	1m	1786830180	1884.5	1884.5	1884.5	1884.5	26	2026-08-15 21:43:56.114976+00
LTC/USD	1m	1786830180	44.16	44.16	44.16	44.16	26	2026-08-15 21:43:56.114976+00
AAVE/USD	1m	1786830180	86.32	86.32	86.32	86.32	26	2026-08-15 21:43:56.114976+00
APT/USD	1m	1786830240	0.539	0.539	0.539	0.539	29	2026-08-15 21:45:01.108981+00
APT/USD	5m	1786830000	0.539	0.539	0.539	0.539	143	2026-08-15 21:45:01.108981+00
APT/USD	15m	1786829400	0.539	0.539	0.539	0.539	444	2026-08-15 21:45:01.108981+00
BCH/USD	1m	1786830240	203.4	203.4	203.4	203.4	29	2026-08-15 21:45:01.108981+00
BCH/USD	5m	1786830000	203.4	203.4	203.4	203.4	144	2026-08-15 21:45:01.108981+00
BCH/USD	15m	1786829400	203.4	203.4	203.4	203.4	444	2026-08-15 21:45:01.108981+00
BTC/USD	1m	1786830240	63146	63219.99	63146	63219.99	29	2026-08-15 21:45:01.108981+00
BTC/USD	5m	1786830000	63122.25	63219.99	63122.25	63219.99	144	2026-08-15 21:45:01.108981+00
BTC/USD	15m	1786829400	63122.42	63219.99	63122.24	63219.99	444	2026-08-15 21:45:01.108981+00
AVAX/USD	1m	1786830240	6.5	6.5	6.5	6.5	29	2026-08-15 21:45:01.108981+00
AVAX/USD	5m	1786830000	6.5	6.5	6.5	6.5	144	2026-08-15 21:45:01.108981+00
AVAX/USD	15m	1786829400	6.5	6.5	6.5	6.5	444	2026-08-15 21:45:01.108981+00
HBAR/USD	1m	1786830240	0.06589	0.06589	0.06589	0.06589	29	2026-08-15 21:45:01.108981+00
HBAR/USD	5m	1786830000	0.06589	0.06589	0.06589	0.06589	144	2026-08-15 21:45:01.108981+00
HBAR/USD	15m	1786829400	0.06589	0.06589	0.06589	0.06589	444	2026-08-15 21:45:01.108981+00
AAVE/USD	1m	1786830240	86.32	86.32	86.32	86.32	29	2026-08-15 21:45:01.108981+00
AAVE/USD	5m	1786830000	86.32	86.32	86.32	86.32	143	2026-08-15 21:45:01.108981+00
AAVE/USD	15m	1786829400	86.32	86.32	86.32	86.32	444	2026-08-15 21:45:01.108981+00
ADA/USD	1m	1786830240	0.1777	0.1777	0.1777	0.1777	29	2026-08-15 21:45:01.108981+00
ADA/USD	5m	1786830000	0.1777	0.1777	0.1777	0.1777	143	2026-08-15 21:45:01.108981+00
ADA/USD	15m	1786829400	0.1777	0.1777	0.1777	0.1777	444	2026-08-15 21:45:01.108981+00
XLM/USD	1m	1786830240	0.15852	0.15852	0.15852	0.15852	29	2026-08-15 21:45:01.108981+00
XLM/USD	5m	1786830000	0.15852	0.15852	0.15852	0.15852	143	2026-08-15 21:45:01.108981+00
XLM/USD	15m	1786829400	0.15774	0.15852	0.15774	0.15852	444	2026-08-15 21:45:01.108981+00
DOGE/USD	1m	1786830240	0.07022	0.07022	0.07022	0.07022	29	2026-08-15 21:45:01.108981+00
DOGE/USD	5m	1786830000	0.07022	0.07022	0.0702199	0.07022	144	2026-08-15 21:45:01.108981+00
DOGE/USD	15m	1786829400	0.0702152	0.07022	0.0702152	0.07022	444	2026-08-15 21:45:01.108981+00
LTC/USD	1m	1786830240	44.16	44.16	44.16	44.16	29	2026-08-15 21:45:01.108981+00
LTC/USD	5m	1786830000	44.16	44.16	44.16	44.16	144	2026-08-15 21:45:01.108981+00
LTC/USD	15m	1786829400	44.16	44.16	44.16	44.16	444	2026-08-15 21:45:01.108981+00
ETH/USD	1m	1786830240	1884.5	1884.5	1884.5	1884.5	29	2026-08-15 21:45:01.108981+00
ETH/USD	5m	1786830000	1884.5	1884.5	1884.5	1884.5	144	2026-08-15 21:45:01.108981+00
ETH/USD	15m	1786829400	1882	1884.5	1882	1884.5	444	2026-08-15 21:45:01.108981+00
DOT/USD	1m	1786830240	0.766	0.766	0.766	0.766	29	2026-08-15 21:45:01.108981+00
DOT/USD	5m	1786830000	0.766	0.766	0.766	0.766	143	2026-08-15 21:45:01.108981+00
DOT/USD	15m	1786829400	0.766	0.766	0.766	0.766	444	2026-08-15 21:45:01.108981+00
NEAR/USD	1m	1786830240	1.631	1.631	1.631	1.631	29	2026-08-15 21:45:01.108981+00
NEAR/USD	5m	1786830000	1.631	1.631	1.631	1.631	143	2026-08-15 21:45:01.108981+00
NEAR/USD	15m	1786829400	1.63	1.631	1.63	1.631	444	2026-08-15 21:45:01.108981+00
POL/USD	1m	1786830240	0.0756	0.0756	0.0756	0.0756	29	2026-08-15 21:45:01.108981+00
POL/USD	5m	1786830000	0.0756	0.0756	0.0756	0.0756	144	2026-08-15 21:45:01.108981+00
POL/USD	15m	1786829400	0.0756	0.0756	0.0756	0.0756	444	2026-08-15 21:45:01.108981+00
SUI/USD	1m	1786830240	0.6784	0.6784	0.6784	0.6784	29	2026-08-15 21:45:01.108981+00
SUI/USD	5m	1786830000	0.6816	0.6816	0.6784	0.6784	144	2026-08-15 21:45:01.108981+00
SUI/USD	15m	1786829400	0.6816	0.6816	0.6784	0.6784	444	2026-08-15 21:45:01.108981+00
XRP/USD	1m	1786830240	1.00399	1.00399	1.00399	1.00399	29	2026-08-15 21:45:01.108981+00
XRP/USD	5m	1786830000	1.00558	1.00558	1.00399	1.00399	144	2026-08-15 21:45:01.108981+00
XRP/USD	15m	1786829400	1.00558	1.00558	1.00399	1.00399	444	2026-08-15 21:45:01.108981+00
UNI/USD	1m	1786830240	3.242	3.249	3.242	3.249	29	2026-08-15 21:45:01.108981+00
UNI/USD	5m	1786830000	3.242	3.249	3.242	3.249	143	2026-08-15 21:45:01.108981+00
UNI/USD	15m	1786829400	3.245	3.25	3.242	3.249	444	2026-08-15 21:45:01.108981+00
LINK/USD	1m	1786830240	9.555	9.555	9.555	9.555	29	2026-08-15 21:45:01.108981+00
LINK/USD	5m	1786830000	9.555	9.555	9.555	9.555	143	2026-08-15 21:45:01.108981+00
LINK/USD	15m	1786829400	9.556	9.556	9.55	9.555	444	2026-08-15 21:45:01.108981+00
SOL/USD	1m	1786830240	75.534	75.85	75.534	75.85	29	2026-08-15 21:45:01.108981+00
SOL/USD	5m	1786830000	75.534	75.85	75.534	75.85	143	2026-08-15 21:45:01.108981+00
SOL/USD	15m	1786829400	75.538	75.85	75.534	75.85	444	2026-08-15 21:45:01.108981+00
UNI/USD	1m	1786830300	3.249	3.249	3.245	3.245	28	2026-08-15 21:46:01.108461+00
LTC/USD	1m	1786830300	44.16	44.16	44.16	44.16	28	2026-08-15 21:46:01.108461+00
AVAX/USD	1m	1786830300	6.5	6.5	6.5	6.5	28	2026-08-15 21:46:01.108461+00
XLM/USD	1m	1786830300	0.15852	0.15852	0.15852	0.15852	28	2026-08-15 21:46:01.108461+00
POL/USD	1m	1786830300	0.0756	0.0756	0.0756	0.0756	28	2026-08-15 21:46:01.108461+00
HBAR/USD	1m	1786830300	0.06589	0.06589	0.06589	0.06589	28	2026-08-15 21:46:01.108461+00
DOT/USD	1m	1786830300	0.766	0.766	0.766	0.766	28	2026-08-15 21:46:01.108461+00
NEAR/USD	1m	1786830300	1.631	1.631	1.631	1.631	28	2026-08-15 21:46:01.108461+00
LINK/USD	1m	1786830300	9.555	9.555	9.555	9.555	28	2026-08-15 21:46:01.108461+00
BTC/USD	1m	1786830300	63219.99	63219.99	63219.99	63219.99	28	2026-08-15 21:46:01.108461+00
AAVE/USD	1m	1786830300	86.32	86.32	86.32	86.32	28	2026-08-15 21:46:01.108461+00
APT/USD	1m	1786830300	0.539	0.539	0.539	0.539	28	2026-08-15 21:46:01.108461+00
BCH/USD	1m	1786830300	203.4	203.4	203.4	203.4	28	2026-08-15 21:46:01.108461+00
ADA/USD	1m	1786830300	0.1777	0.1777	0.1777	0.1777	28	2026-08-15 21:46:01.108461+00
SOL/USD	1m	1786830300	75.85	75.85	75.85	75.85	28	2026-08-15 21:46:01.108461+00
DOGE/USD	1m	1786830300	0.07022	0.07022	0.07022	0.07022	28	2026-08-15 21:46:01.108461+00
ETH/USD	1m	1786830300	1884.5	1884.5	1884.5	1884.5	28	2026-08-15 21:46:01.108461+00
XRP/USD	1m	1786830300	1.00399	1.00399	1.00399	1.00399	28	2026-08-15 21:46:01.108461+00
SUI/USD	1m	1786830300	0.6784	0.6784	0.6784	0.6784	28	2026-08-15 21:46:01.108461+00
ETH/USD	1m	1786830360	1884.5	1884.5	1884.5	1884.5	26	2026-08-15 21:46:56.107646+00
AAVE/USD	1m	1786830360	86.32	86.32	86.32	86.32	26	2026-08-15 21:46:56.107646+00
ADA/USD	1m	1786830360	0.1777	0.1781	0.1777	0.1781	26	2026-08-15 21:46:56.107646+00
POL/USD	1m	1786830360	0.0756	0.0756	0.0756	0.0756	26	2026-08-15 21:46:56.107646+00
AVAX/USD	1m	1786830360	6.5	6.5	6.5	6.5	26	2026-08-15 21:46:56.107646+00
LTC/USD	1m	1786830360	44.16	44.16	44.16	44.16	26	2026-08-15 21:46:56.107646+00
SOL/USD	1m	1786830360	75.85	75.85	75.85	75.85	26	2026-08-15 21:46:56.107646+00
XLM/USD	1m	1786830360	0.15852	0.15884	0.15852	0.15884	26	2026-08-15 21:46:56.107646+00
NEAR/USD	1m	1786830360	1.631	1.631	1.631	1.631	26	2026-08-15 21:46:56.107646+00
APT/USD	1m	1786830360	0.539	0.539	0.539	0.539	26	2026-08-15 21:46:56.107646+00
BCH/USD	1m	1786830360	203.4	203.4	203.4	203.4	26	2026-08-15 21:46:56.107646+00
UNI/USD	1m	1786830360	3.243	3.243	3.243	3.243	26	2026-08-15 21:46:56.107646+00
DOT/USD	1m	1786830360	0.766	0.766	0.766	0.766	26	2026-08-15 21:46:56.107646+00
HBAR/USD	1m	1786830360	0.06589	0.06589	0.06589	0.06589	26	2026-08-15 21:46:56.107646+00
DOGE/USD	1m	1786830360	0.07022	0.07022	0.07022	0.07022	26	2026-08-15 21:46:56.107646+00
SUI/USD	1m	1786830360	0.6784	0.6784	0.6784	0.6784	26	2026-08-15 21:46:56.107646+00
LINK/USD	1m	1786830360	9.555	9.555	9.555	9.555	26	2026-08-15 21:46:56.107646+00
BTC/USD	1m	1786830360	63219.99	63219.99	63219.99	63219.99	26	2026-08-15 21:46:56.107646+00
XRP/USD	1m	1786830360	1.00399	1.00399	1.00399	1.00399	26	2026-08-15 21:46:56.107646+00
NEAR/USD	1m	1786830420	1.631	1.631	1.631	1.631	26	2026-08-15 21:47:56.108028+00
AVAX/USD	1m	1786830420	6.5	6.5	6.5	6.5	26	2026-08-15 21:47:56.108028+00
SOL/USD	1m	1786830420	75.85	75.85	75.85	75.85	26	2026-08-15 21:47:56.108028+00
BTC/USD	1m	1786830420	63219.99	63219.99	63219.99	63219.99	26	2026-08-15 21:47:56.108028+00
ADA/USD	1m	1786830420	0.1781	0.1781	0.1781	0.1781	26	2026-08-15 21:47:56.108028+00
APT/USD	1m	1786830420	0.539	0.539	0.539	0.539	26	2026-08-15 21:47:56.108028+00
LINK/USD	1m	1786830420	9.555	9.555	9.555	9.555	26	2026-08-15 21:47:56.108028+00
XRP/USD	1m	1786830420	1.00399	1.00399	1.00399	1.00399	26	2026-08-15 21:47:56.108028+00
AAVE/USD	1m	1786830420	86.32	86.32	86.32	86.32	26	2026-08-15 21:47:56.108028+00
DOGE/USD	1m	1786830420	0.07022	0.07022	0.07022	0.07022	26	2026-08-15 21:47:56.108028+00
HBAR/USD	1m	1786830420	0.06589	0.06589	0.06589	0.06589	26	2026-08-15 21:47:56.108028+00
ETH/USD	1m	1786830420	1884.5	1884.5	1883.5	1883.5	26	2026-08-15 21:47:56.108028+00
LTC/USD	1m	1786830420	44.16	44.16	44.16	44.16	26	2026-08-15 21:47:56.108028+00
XLM/USD	1m	1786830420	0.15884	0.15884	0.15884	0.15884	26	2026-08-15 21:47:56.108028+00
UNI/USD	1m	1786830420	3.243	3.243	3.243	3.243	26	2026-08-15 21:47:56.108028+00
DOT/USD	1m	1786830420	0.766	0.766	0.766	0.766	26	2026-08-15 21:47:56.108028+00
POL/USD	1m	1786830420	0.0756	0.0756	0.0756	0.0756	26	2026-08-15 21:47:56.108028+00
BCH/USD	1m	1786830420	203.4	203.4	203.4	203.4	26	2026-08-15 21:47:56.108028+00
SUI/USD	1m	1786830420	0.6784	0.6784	0.6784	0.6784	27	2026-08-15 21:47:56.108028+00
HBAR/USD	1m	1786830480	0.06589	0.06589	0.06589	0.06589	28	2026-08-15 21:48:56.107824+00
XRP/USD	1m	1786830480	1.00399	1.00399	1.00399	1.00399	28	2026-08-15 21:48:56.107824+00
LTC/USD	1m	1786830480	44.16	44.16	44.16	44.16	28	2026-08-15 21:48:56.107824+00
AVAX/USD	1m	1786830480	6.5	6.5	6.5	6.5	28	2026-08-15 21:48:56.107824+00
SUI/USD	1m	1786830480	0.6784	0.6784	0.6784	0.6784	27	2026-08-15 21:48:56.107824+00
BCH/USD	1m	1786830480	203.4	203.4	203.4	203.4	28	2026-08-15 21:48:56.107824+00
ETH/USD	1m	1786830480	1883.5	1883.5	1883.5	1883.5	28	2026-08-15 21:48:56.107824+00
BTC/USD	1m	1786830480	63219.99	63219.99	63219.99	63219.99	28	2026-08-15 21:48:56.107824+00
POL/USD	1m	1786830480	0.0756	0.0756	0.0756	0.0756	28	2026-08-15 21:48:56.107824+00
NEAR/USD	1m	1786830480	1.631	1.631	1.631	1.631	29	2026-08-15 21:49:01.11855+00
XLM/USD	1m	1786830480	0.15884	0.15884	0.15884	0.15884	29	2026-08-15 21:49:01.11855+00
APT/USD	1m	1786830480	0.539	0.539	0.539	0.539	29	2026-08-15 21:49:01.11855+00
LINK/USD	1m	1786830480	9.555	9.555	9.555	9.555	29	2026-08-15 21:49:01.11855+00
DOGE/USD	1m	1786830480	0.07022	0.07022	0.07022	0.07022	29	2026-08-15 21:49:01.11855+00
DOT/USD	1m	1786830480	0.766	0.766	0.766	0.766	29	2026-08-15 21:49:01.11855+00
ADA/USD	1m	1786830480	0.1781	0.1781	0.1781	0.1781	29	2026-08-15 21:49:01.11855+00
AAVE/USD	1m	1786830480	86.32	86.32	86.04	86.04	29	2026-08-15 21:49:01.11855+00
SOL/USD	1m	1786830480	75.85	75.85	75.85	75.85	29	2026-08-15 21:49:01.11855+00
UNI/USD	1m	1786830480	3.243	3.243	3.243	3.243	29	2026-08-15 21:49:01.11855+00
AVAX/USD	1m	1786830540	6.5	6.5	6.5	6.5	25	2026-08-15 21:49:56.10844+00
AVAX/USD	5m	1786830300	6.5	6.5	6.5	6.5	133	2026-08-15 21:49:56.10844+00
ADA/USD	1m	1786830540	0.1781	0.1781	0.1781	0.1781	24	2026-08-15 21:49:56.10844+00
ADA/USD	5m	1786830300	0.1777	0.1781	0.1777	0.1781	133	2026-08-15 21:49:56.10844+00
BTC/USD	1m	1786830540	63219.99	63219.99	63219.99	63219.99	25	2026-08-15 21:49:56.10844+00
BTC/USD	5m	1786830300	63219.99	63219.99	63219.99	63219.99	133	2026-08-15 21:49:56.10844+00
DOT/USD	1m	1786830540	0.766	0.766	0.766	0.766	24	2026-08-15 21:49:56.10844+00
DOT/USD	5m	1786830300	0.766	0.766	0.766	0.766	133	2026-08-15 21:49:56.10844+00
LTC/USD	1m	1786830540	44.16	44.16	44.16	44.16	25	2026-08-15 21:49:56.10844+00
LTC/USD	5m	1786830300	44.16	44.16	44.16	44.16	133	2026-08-15 21:49:56.10844+00
XLM/USD	1m	1786830540	0.15884	0.15884	0.15884	0.15884	24	2026-08-15 21:49:56.10844+00
XLM/USD	5m	1786830300	0.15852	0.15884	0.15852	0.15884	133	2026-08-15 21:49:56.10844+00
BCH/USD	1m	1786830540	203.4	203.4	203.4	203.4	25	2026-08-15 21:49:56.10844+00
BCH/USD	5m	1786830300	203.4	203.4	203.4	203.4	133	2026-08-15 21:49:56.10844+00
APT/USD	1m	1786830540	0.539	0.539	0.539	0.539	24	2026-08-15 21:49:56.10844+00
APT/USD	5m	1786830300	0.539	0.539	0.539	0.539	133	2026-08-15 21:49:56.10844+00
HBAR/USD	1m	1786830540	0.06589	0.06589	0.06589	0.06589	25	2026-08-15 21:49:56.10844+00
HBAR/USD	5m	1786830300	0.06589	0.06589	0.06589	0.06589	133	2026-08-15 21:49:56.10844+00
ETH/USD	1m	1786830540	1883.5	1883.5	1883.5	1883.5	25	2026-08-15 21:49:56.10844+00
ETH/USD	5m	1786830300	1884.5	1884.5	1883.5	1883.5	133	2026-08-15 21:49:56.10844+00
POL/USD	1m	1786830540	0.0756	0.0761	0.0756	0.0761	25	2026-08-15 21:49:56.10844+00
POL/USD	5m	1786830300	0.0756	0.0761	0.0756	0.0761	133	2026-08-15 21:49:56.10844+00
AAVE/USD	1m	1786830540	86.04	86.04	86.04	86.04	24	2026-08-15 21:49:56.10844+00
AAVE/USD	5m	1786830300	86.32	86.32	86.04	86.04	133	2026-08-15 21:49:56.10844+00
UNI/USD	1m	1786830540	3.243	3.243	3.243	3.243	24	2026-08-15 21:49:56.10844+00
UNI/USD	5m	1786830300	3.249	3.249	3.243	3.243	133	2026-08-15 21:49:56.10844+00
SUI/USD	1m	1786830540	0.6784	0.6784	0.6784	0.6784	25	2026-08-15 21:49:56.10844+00
SUI/USD	5m	1786830300	0.6784	0.6784	0.6784	0.6784	133	2026-08-15 21:49:56.10844+00
NEAR/USD	1m	1786830540	1.631	1.631	1.631	1.631	24	2026-08-15 21:49:56.10844+00
NEAR/USD	5m	1786830300	1.631	1.631	1.631	1.631	133	2026-08-15 21:49:56.10844+00
SOL/USD	1m	1786830540	75.85	75.85	75.85	75.85	24	2026-08-15 21:49:56.10844+00
SOL/USD	5m	1786830300	75.85	75.85	75.85	75.85	133	2026-08-15 21:49:56.10844+00
XRP/USD	1m	1786830540	1.00399	1.00399	1.00399	1.00399	25	2026-08-15 21:49:56.10844+00
XRP/USD	5m	1786830300	1.00399	1.00399	1.00399	1.00399	133	2026-08-15 21:49:56.10844+00
DOGE/USD	1m	1786830540	0.07022	0.07022	0.07022	0.07022	24	2026-08-15 21:49:56.10844+00
DOGE/USD	5m	1786830300	0.07022	0.07022	0.07022	0.07022	133	2026-08-15 21:49:56.10844+00
LINK/USD	1m	1786830540	9.555	9.555	9.555	9.555	24	2026-08-15 21:49:56.10844+00
LINK/USD	5m	1786830300	9.555	9.555	9.555	9.555	133	2026-08-15 21:49:56.10844+00
ADA/USD	1m	1786830600	0.1781	0.1781	0.1781	0.1781	30	2026-08-15 21:50:56.108501+00
BCH/USD	1m	1786830600	203.4	203.4	203.4	203.4	30	2026-08-15 21:50:56.108501+00
SUI/USD	1m	1786830600	0.6784	0.6784	0.6784	0.6784	30	2026-08-15 21:50:56.108501+00
XRP/USD	1m	1786830600	1.00399	1.00399	1.00399	1.00399	30	2026-08-15 21:50:56.108501+00
NEAR/USD	1m	1786830600	1.631	1.631	1.631	1.631	30	2026-08-15 21:50:56.108501+00
XLM/USD	1m	1786830600	0.15884	0.15884	0.15884	0.15884	30	2026-08-15 21:50:56.108501+00
BTC/USD	1m	1786830600	63219.99	63219.99	63146	63146	30	2026-08-15 21:50:56.108501+00
DOT/USD	1m	1786830600	0.766	0.766	0.766	0.766	30	2026-08-15 21:50:56.108501+00
LINK/USD	1m	1786830600	9.555	9.555	9.555	9.555	30	2026-08-15 21:50:56.108501+00
DOGE/USD	1m	1786830600	0.07022	0.07022	0.07022	0.07022	30	2026-08-15 21:50:56.108501+00
LTC/USD	1m	1786830600	44.16	44.16	44.16	44.16	30	2026-08-15 21:50:56.108501+00
UNI/USD	1m	1786830600	3.243	3.243	3.243	3.243	30	2026-08-15 21:50:56.108501+00
AAVE/USD	1m	1786830600	86.04	86.04	86.04	86.04	30	2026-08-15 21:50:56.108501+00
APT/USD	1m	1786830600	0.539	0.539	0.539	0.539	30	2026-08-15 21:50:56.108501+00
ETH/USD	1m	1786830600	1883.5	1883.5	1883.5	1883.5	30	2026-08-15 21:50:56.108501+00
AVAX/USD	1m	1786830600	6.5	6.5	6.5	6.5	31	2026-08-15 21:50:56.108501+00
SOL/USD	1m	1786830600	75.85	75.85	75.85	75.85	31	2026-08-15 21:50:56.108501+00
POL/USD	1m	1786830600	0.0761	0.0761	0.0755	0.0755	31	2026-08-15 21:50:56.108501+00
HBAR/USD	1m	1786830600	0.06589	0.06589	0.06589	0.06589	31	2026-08-15 21:50:56.108501+00
AVAX/USD	1m	1786830660	6.5	6.5	6.5	6.5	30	2026-08-15 21:51:56.10801+00
XLM/USD	1m	1786830660	0.15884	0.15884	0.15884	0.15884	31	2026-08-15 21:51:56.10801+00
SUI/USD	1m	1786830660	0.6784	0.6784	0.6784	0.6784	31	2026-08-15 21:51:56.10801+00
APT/USD	1m	1786830660	0.539	0.539	0.539	0.539	31	2026-08-15 21:51:56.10801+00
UNI/USD	1m	1786830660	3.243	3.243	3.243	3.243	31	2026-08-15 21:51:56.10801+00
LTC/USD	1m	1786830660	44.16	44.16	44.16	44.16	31	2026-08-15 21:51:56.10801+00
DOGE/USD	1m	1786830660	0.07022	0.07022	0.07022	0.07022	31	2026-08-15 21:51:56.10801+00
ADA/USD	1m	1786830660	0.1781	0.1781	0.1781	0.1781	31	2026-08-15 21:51:56.10801+00
BCH/USD	1m	1786830660	203.4	203.4	203.4	203.4	31	2026-08-15 21:51:56.10801+00
AAVE/USD	1m	1786830660	86.04	86.04	86.04	86.04	31	2026-08-15 21:51:56.10801+00
SOL/USD	1m	1786830660	75.85	75.856	75.85	75.856	30	2026-08-15 21:51:56.10801+00
LINK/USD	1m	1786830660	9.555	9.555	9.555	9.555	31	2026-08-15 21:51:56.10801+00
HBAR/USD	1m	1786830660	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:51:56.10801+00
XRP/USD	1m	1786830660	1.00399	1.00399	1.00399	1.00399	31	2026-08-15 21:51:56.10801+00
POL/USD	1m	1786830660	0.0755	0.0755	0.0755	0.0755	30	2026-08-15 21:51:56.10801+00
NEAR/USD	1m	1786830660	1.631	1.631	1.631	1.631	31	2026-08-15 21:51:56.10801+00
DOT/USD	1m	1786830660	0.766	0.766	0.766	0.766	31	2026-08-15 21:51:56.10801+00
ETH/USD	1m	1786830660	1883.5	1884.5	1883.5	1884.5	31	2026-08-15 21:51:56.10801+00
BTC/USD	1m	1786830660	63146	63146	63146	63146	31	2026-08-15 21:51:56.10801+00
BTC/USD	1m	1786830720	63146	63146	63146	63146	29	2026-08-15 21:52:56.107926+00
LTC/USD	1m	1786830720	44.16	44.16	44.16	44.16	29	2026-08-15 21:52:56.107926+00
XLM/USD	1m	1786830720	0.15884	0.15884	0.15884	0.15884	29	2026-08-15 21:52:56.107926+00
XRP/USD	1m	1786830720	1.00399	1.00399	1.00399	1.00399	29	2026-08-15 21:52:56.107926+00
DOGE/USD	1m	1786830720	0.07022	0.07022	0.07022	0.07022	29	2026-08-15 21:52:56.107926+00
ETH/USD	1m	1786830720	1884.5	1884.5	1884.5	1884.5	29	2026-08-15 21:52:56.107926+00
BCH/USD	1m	1786830720	203.4	203.4	203.4	203.4	29	2026-08-15 21:52:56.107926+00
SUI/USD	1m	1786830720	0.6784	0.6784	0.6784	0.6784	29	2026-08-15 21:52:56.107926+00
ADA/USD	1m	1786830720	0.1781	0.1781	0.1781	0.1781	30	2026-08-15 21:52:56.107926+00
POL/USD	1m	1786830720	0.0755	0.0755	0.0755	0.0755	30	2026-08-15 21:52:56.107926+00
NEAR/USD	1m	1786830720	1.631	1.631	1.631	1.631	30	2026-08-15 21:52:56.107926+00
AAVE/USD	1m	1786830720	86.04	86.04	86.04	86.04	30	2026-08-15 21:52:56.107926+00
APT/USD	1m	1786830720	0.539	0.539	0.539	0.539	30	2026-08-15 21:52:56.107926+00
DOT/USD	1m	1786830720	0.766	0.766	0.766	0.766	30	2026-08-15 21:52:56.107926+00
SOL/USD	1m	1786830720	75.856	75.856	75.85	75.85	30	2026-08-15 21:52:56.107926+00
AVAX/USD	1m	1786830720	6.5	6.5	6.5	6.5	30	2026-08-15 21:52:56.107926+00
LINK/USD	1m	1786830720	9.555	9.555	9.555	9.555	30	2026-08-15 21:52:56.107926+00
UNI/USD	1m	1786830720	3.243	3.243	3.243	3.243	30	2026-08-15 21:52:56.107926+00
HBAR/USD	1m	1786830720	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:52:56.107926+00
AAVE/USD	1m	1786830780	86.04	86.04	86.04	86.04	29	2026-08-15 21:53:56.10753+00
POL/USD	1m	1786830780	0.0755	0.0755	0.0755	0.0755	29	2026-08-15 21:53:56.10753+00
DOGE/USD	1m	1786830780	0.07022	0.07022	0.07011	0.07011	30	2026-08-15 21:53:56.10753+00
LINK/USD	1m	1786830780	9.555	9.555	9.555	9.555	29	2026-08-15 21:53:56.10753+00
SUI/USD	1m	1786830780	0.6784	0.6784	0.6784	0.6784	30	2026-08-15 21:53:56.10753+00
DOT/USD	1m	1786830780	0.766	0.766	0.766	0.766	29	2026-08-15 21:53:56.10753+00
BCH/USD	1m	1786830780	203.4	203.4	203.4	203.4	30	2026-08-15 21:53:56.10753+00
SOL/USD	1m	1786830780	75.85	75.85	75.85	75.85	29	2026-08-15 21:53:56.10753+00
XLM/USD	1m	1786830780	0.15884	0.15884	0.15807	0.15807	30	2026-08-15 21:53:56.10753+00
NEAR/USD	1m	1786830780	1.631	1.631	1.631	1.631	29	2026-08-15 21:53:56.10753+00
ADA/USD	1m	1786830780	0.1781	0.1781	0.1781	0.1781	29	2026-08-15 21:53:56.10753+00
HBAR/USD	1m	1786830780	0.06589	0.06589	0.06589	0.06589	29	2026-08-15 21:53:56.10753+00
APT/USD	1m	1786830780	0.539	0.539	0.539	0.539	29	2026-08-15 21:53:56.10753+00
AVAX/USD	1m	1786830780	6.5	6.5	6.5	6.5	29	2026-08-15 21:53:56.10753+00
UNI/USD	1m	1786830780	3.243	3.243	3.243	3.243	29	2026-08-15 21:53:56.10753+00
BTC/USD	1m	1786830780	63146	63146	63146	63146	31	2026-08-15 21:53:56.10753+00
ETH/USD	1m	1786830780	1884.5	1884.5	1884.5	1884.5	31	2026-08-15 21:53:56.10753+00
LTC/USD	1m	1786830780	44.16	44.16	44.16	44.16	31	2026-08-15 21:53:56.10753+00
XRP/USD	1m	1786830780	1.00399	1.00399	1.00399	1.00399	31	2026-08-15 21:53:56.10753+00
AVAX/USD	1m	1786830840	6.5	6.5	6.5	6.5	30	2026-08-15 21:54:56.1085+00
AVAX/USD	5m	1786830600	6.5	6.5	6.5	6.5	150	2026-08-15 21:54:56.1085+00
BCH/USD	1m	1786830840	203.4	203.4	203.4	203.4	30	2026-08-15 21:54:56.1085+00
BCH/USD	5m	1786830600	203.4	203.4	203.4	203.4	150	2026-08-15 21:54:56.1085+00
DOT/USD	1m	1786830840	0.766	0.766	0.766	0.766	30	2026-08-15 21:54:56.1085+00
DOT/USD	5m	1786830600	0.766	0.766	0.766	0.766	150	2026-08-15 21:54:56.1085+00
XLM/USD	1m	1786830840	0.15807	0.15807	0.15807	0.15807	30	2026-08-15 21:54:56.1085+00
XLM/USD	5m	1786830600	0.15884	0.15884	0.15807	0.15807	150	2026-08-15 21:54:56.1085+00
SOL/USD	1m	1786830840	75.85	75.85	75.85	75.85	30	2026-08-15 21:54:56.1085+00
SOL/USD	5m	1786830600	75.85	75.856	75.85	75.85	150	2026-08-15 21:54:56.1085+00
ADA/USD	1m	1786830840	0.1781	0.1781	0.1781	0.1781	30	2026-08-15 21:54:56.1085+00
ADA/USD	5m	1786830600	0.1781	0.1781	0.1781	0.1781	150	2026-08-15 21:54:56.1085+00
LINK/USD	1m	1786830840	9.555	9.555	9.555	9.555	30	2026-08-15 21:54:56.1085+00
LINK/USD	5m	1786830600	9.555	9.555	9.555	9.555	150	2026-08-15 21:54:56.1085+00
SUI/USD	1m	1786830840	0.6784	0.6784	0.6784	0.6784	30	2026-08-15 21:54:56.1085+00
SUI/USD	5m	1786830600	0.6784	0.6784	0.6784	0.6784	150	2026-08-15 21:54:56.1085+00
HBAR/USD	1m	1786830840	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:54:56.1085+00
HBAR/USD	5m	1786830600	0.06589	0.06589	0.06589	0.06589	150	2026-08-15 21:54:56.1085+00
APT/USD	1m	1786830840	0.539	0.539	0.539	0.539	30	2026-08-15 21:54:56.1085+00
APT/USD	5m	1786830600	0.539	0.539	0.539	0.539	150	2026-08-15 21:54:56.1085+00
DOGE/USD	1m	1786830840	0.07011	0.07011	0.07011	0.07011	30	2026-08-15 21:54:56.1085+00
DOGE/USD	5m	1786830600	0.07022	0.07022	0.07011	0.07011	150	2026-08-15 21:54:56.1085+00
NEAR/USD	1m	1786830840	1.631	1.631	1.631	1.631	30	2026-08-15 21:54:56.1085+00
NEAR/USD	5m	1786830600	1.631	1.631	1.631	1.631	150	2026-08-15 21:54:56.1085+00
POL/USD	1m	1786830840	0.0755	0.0755	0.0755	0.0755	30	2026-08-15 21:54:56.1085+00
POL/USD	5m	1786830600	0.0761	0.0761	0.0755	0.0755	150	2026-08-15 21:54:56.1085+00
UNI/USD	1m	1786830840	3.243	3.243	3.243	3.243	30	2026-08-15 21:54:56.1085+00
UNI/USD	5m	1786830600	3.243	3.243	3.243	3.243	150	2026-08-15 21:54:56.1085+00
AAVE/USD	1m	1786830840	86.04	86.04	86.04	86.04	30	2026-08-15 21:54:56.1085+00
AAVE/USD	5m	1786830600	86.04	86.04	86.04	86.04	150	2026-08-15 21:54:56.1085+00
ETH/USD	1m	1786830840	1884.5	1884.5	1884.5	1884.5	30	2026-08-15 21:54:56.1085+00
ETH/USD	5m	1786830600	1883.5	1884.5	1883.5	1884.5	151	2026-08-15 21:54:56.1085+00
XRP/USD	1m	1786830840	1.00399	1.00399	1.00399	1.00399	30	2026-08-15 21:54:56.1085+00
XRP/USD	5m	1786830600	1.00399	1.00399	1.00399	1.00399	151	2026-08-15 21:54:56.1085+00
BTC/USD	1m	1786830840	63146	63146	63146	63146	30	2026-08-15 21:54:56.1085+00
BTC/USD	5m	1786830600	63219.99	63219.99	63146	63146	151	2026-08-15 21:54:56.1085+00
LTC/USD	1m	1786830840	44.16	44.16	44.16	44.16	30	2026-08-15 21:54:56.1085+00
LTC/USD	5m	1786830600	44.16	44.16	44.16	44.16	151	2026-08-15 21:54:56.1085+00
HBAR/USD	1m	1786830900	0.06589	0.06589	0.06589	0.06589	29	2026-08-15 21:55:56.10824+00
APT/USD	1m	1786830900	0.539	0.539	0.539	0.539	29	2026-08-15 21:55:56.10824+00
AAVE/USD	1m	1786830900	86.04	86.04	86.04	86.04	29	2026-08-15 21:55:56.10824+00
DOT/USD	1m	1786830900	0.766	0.766	0.766	0.766	29	2026-08-15 21:55:56.10824+00
UNI/USD	1m	1786830900	3.243	3.243	3.243	3.243	29	2026-08-15 21:55:56.10824+00
XLM/USD	1m	1786830900	0.15807	0.15807	0.15807	0.15807	29	2026-08-15 21:55:56.10824+00
LINK/USD	1m	1786830900	9.555	9.555	9.555	9.555	29	2026-08-15 21:55:56.10824+00
NEAR/USD	1m	1786830900	1.631	1.631	1.631	1.631	29	2026-08-15 21:55:56.10824+00
SOL/USD	1m	1786830900	75.85	75.85	75.85	75.85	29	2026-08-15 21:55:56.10824+00
BTC/USD	1m	1786830900	63146	63146	63146	63146	28	2026-08-15 21:55:56.10824+00
XRP/USD	1m	1786830900	1.00399	1.00399	1.00399	1.00399	28	2026-08-15 21:55:56.10824+00
POL/USD	1m	1786830900	0.0755	0.0755	0.0755	0.0755	29	2026-08-15 21:55:56.10824+00
BCH/USD	1m	1786830900	203.4	203.4	203.4	203.4	29	2026-08-15 21:55:56.10824+00
ETH/USD	1m	1786830900	1884.5	1884.5	1884.5	1884.5	28	2026-08-15 21:55:56.10824+00
ADA/USD	1m	1786830900	0.1781	0.1781	0.1781	0.1781	29	2026-08-15 21:55:56.10824+00
LTC/USD	1m	1786830900	44.16	44.16	44.16	44.16	28	2026-08-15 21:55:56.10824+00
SUI/USD	1m	1786830900	0.6784	0.6784	0.6784	0.6784	29	2026-08-15 21:55:56.10824+00
DOGE/USD	1m	1786830900	0.07011	0.07011	0.0701	0.0701	29	2026-08-15 21:55:56.10824+00
AVAX/USD	1m	1786830900	6.5	6.5	6.5	6.5	29	2026-08-15 21:55:56.10824+00
XLM/USD	1m	1786830960	0.15807	0.15807	0.15807	0.15807	30	2026-08-15 21:56:56.107732+00
LTC/USD	1m	1786830960	44.16	44.16	44.16	44.16	30	2026-08-15 21:56:56.107732+00
POL/USD	1m	1786830960	0.0755	0.0755	0.0755	0.0755	30	2026-08-15 21:56:56.107732+00
AAVE/USD	1m	1786830960	86.04	86.04	86.04	86.04	30	2026-08-15 21:56:56.107732+00
APT/USD	1m	1786830960	0.539	0.539	0.539	0.539	30	2026-08-15 21:56:56.107732+00
ETH/USD	1m	1786830960	1884.5	1884.5	1884.5	1884.5	30	2026-08-15 21:56:56.107732+00
SOL/USD	1m	1786830960	75.85	75.85	75.85	75.85	30	2026-08-15 21:56:56.107732+00
HBAR/USD	1m	1786830960	0.06589	0.06589	0.06589	0.06589	30	2026-08-15 21:56:56.107732+00
UNI/USD	1m	1786830960	3.243	3.243	3.243	3.243	30	2026-08-15 21:56:56.107732+00
BTC/USD	1m	1786830960	63146	63146	63146	63146	30	2026-08-15 21:56:56.107732+00
LINK/USD	1m	1786830960	9.555	9.555	9.555	9.555	30	2026-08-15 21:56:56.107732+00
ADA/USD	1m	1786830960	0.1781	0.1781	0.1781	0.1781	30	2026-08-15 21:56:56.107732+00
DOT/USD	1m	1786830960	0.766	0.766	0.766	0.766	30	2026-08-15 21:56:56.107732+00
AVAX/USD	1m	1786830960	6.5	6.5	6.5	6.5	30	2026-08-15 21:56:56.107732+00
NEAR/USD	1m	1786830960	1.631	1.631	1.631	1.631	30	2026-08-15 21:56:56.107732+00
DOGE/USD	1m	1786830960	0.0701	0.0701	0.0701	0.0701	30	2026-08-15 21:56:56.107732+00
BCH/USD	1m	1786830960	203.4	203.4	203.4	203.4	30	2026-08-15 21:56:56.107732+00
XRP/USD	1m	1786830960	1.00399	1.00399	1.00399	1.00399	30	2026-08-15 21:56:56.107732+00
SUI/USD	1m	1786830960	0.6784	0.6784	0.6784	0.6784	31	2026-08-15 21:56:56.107732+00
UNI/USD	1m	1786831020	3.243	3.243	3.243	3.243	30	2026-08-15 21:57:56.107477+00
SUI/USD	1m	1786831020	0.6784	0.6784	0.6784	0.6784	29	2026-08-15 21:57:56.107477+00
ADA/USD	1m	1786831020	0.1781	0.1781	0.1781	0.1781	30	2026-08-15 21:57:56.107477+00
DOGE/USD	1m	1786831020	0.0701	0.0701	0.0701	0.0701	30	2026-08-15 21:57:56.107477+00
LINK/USD	1m	1786831020	9.555	9.555	9.555	9.555	30	2026-08-15 21:57:56.107477+00
DOT/USD	1m	1786831020	0.766	0.766	0.766	0.766	30	2026-08-15 21:57:56.107477+00
SOL/USD	1m	1786831020	75.85	75.85	75.85	75.85	30	2026-08-15 21:57:56.107477+00
AAVE/USD	1m	1786831020	86.04	86.04	86.04	86.04	30	2026-08-15 21:57:56.107477+00
LTC/USD	1m	1786831020	44.16	44.16	44.16	44.16	30	2026-08-15 21:57:56.107477+00
BTC/USD	1m	1786831020	63146	63146	63146	63146	30	2026-08-15 21:57:56.107477+00
ETH/USD	1m	1786831020	1884.5	1884.5	1884.5	1884.5	30	2026-08-15 21:57:56.107477+00
XLM/USD	1m	1786831020	0.15807	0.15807	0.15807	0.15807	30	2026-08-15 21:57:56.107477+00
XRP/USD	1m	1786831020	1.00399	1.00399	1.00399	1.00399	30	2026-08-15 21:57:56.107477+00
NEAR/USD	1m	1786831020	1.631	1.631	1.631	1.631	30	2026-08-15 21:57:56.107477+00
BCH/USD	1m	1786831020	203.4	203.4	203.4	203.4	30	2026-08-15 21:57:56.107477+00
APT/USD	1m	1786831020	0.539	0.539	0.539	0.539	30	2026-08-15 21:57:56.107477+00
HBAR/USD	1m	1786831020	0.06589	0.06589	0.06589	0.06589	31	2026-08-15 21:57:56.107477+00
AVAX/USD	1m	1786831020	6.5	6.5	6.5	6.5	31	2026-08-15 21:57:56.107477+00
POL/USD	1m	1786831020	0.0755	0.0755	0.0755	0.0755	31	2026-08-15 21:57:56.107477+00
HBAR/USD	1m	1786831080	0.06589	0.06589	0.06589	0.06589	29	2026-08-15 21:58:56.108465+00
XRP/USD	1m	1786831080	1.00399	1.00399	1.00399	1.00399	30	2026-08-15 21:58:56.108465+00
ADA/USD	1m	1786831080	0.1781	0.1781	0.1781	0.1781	30	2026-08-15 21:58:56.108465+00
AAVE/USD	1m	1786831080	86.04	86.04	86.04	86.04	30	2026-08-15 21:58:56.108465+00
AVAX/USD	1m	1786831080	6.5	6.5	6.5	6.5	29	2026-08-15 21:58:56.108465+00
BCH/USD	1m	1786831080	203.4	203.4	203.4	203.4	30	2026-08-15 21:58:56.108465+00
ETH/USD	1m	1786831080	1884.5	1884.5	1884.5	1884.5	30	2026-08-15 21:58:56.108465+00
XLM/USD	1m	1786831080	0.15807	0.15807	0.15807	0.15807	30	2026-08-15 21:58:56.108465+00
SUI/USD	1m	1786831080	0.6784	0.6784	0.6784	0.6784	30	2026-08-15 21:58:56.108465+00
BTC/USD	1m	1786831080	63146	63249.86	63146	63249.86	30	2026-08-15 21:58:56.108465+00
DOGE/USD	1m	1786831080	0.0701	0.0701	0.0701	0.0701	30	2026-08-15 21:58:56.108465+00
APT/USD	1m	1786831080	0.539	0.539	0.539	0.539	30	2026-08-15 21:58:56.108465+00
POL/USD	1m	1786831080	0.0755	0.0755	0.0755	0.0755	29	2026-08-15 21:58:56.108465+00
LINK/USD	1m	1786831080	9.555	9.555	9.555	9.555	30	2026-08-15 21:58:56.108465+00
UNI/USD	1m	1786831080	3.243	3.243	3.242	3.242	30	2026-08-15 21:58:56.108465+00
NEAR/USD	1m	1786831080	1.631	1.631	1.631	1.631	30	2026-08-15 21:58:56.108465+00
SOL/USD	1m	1786831080	75.85	75.85	75.85	75.85	30	2026-08-15 21:58:56.108465+00
DOT/USD	1m	1786831080	0.766	0.766	0.766	0.766	30	2026-08-15 21:58:56.108465+00
LTC/USD	1m	1786831080	44.16	44.16	44.16	44.16	31	2026-08-15 21:59:01.108965+00
SUI/USD	1m	1786847580	0.676	0.676	0.676	0.676	23	2026-08-16 02:33:57.144434+00
AAVE/USD	1m	1786847580	86.23	86.23	86.23	86.23	24	2026-08-16 02:33:57.144434+00
BTC/USD	1m	1786847580	63172.75	63172.75	63172.75	63172.75	24	2026-08-16 02:33:57.144434+00
AVAX/USD	1m	1786847580	6.34	6.34	6.34	6.34	24	2026-08-16 02:33:57.144434+00
XRP/USD	1m	1786847580	1.00089	1.00089	1.00089	1.00089	24	2026-08-16 02:33:57.144434+00
ETH/USD	1m	1786847580	1884.66	1884.66	1884.66	1884.66	24	2026-08-16 02:33:57.144434+00
DOGE/USD	1m	1786847580	0.0696705	0.0696705	0.0696705	0.0696705	24	2026-08-16 02:33:57.144434+00
NEAR/USD	1m	1786847580	1.612	1.612	1.612	1.612	24	2026-08-16 02:33:57.144434+00
APT/USD	1m	1786847580	0.5344	0.5344	0.5344	0.5344	24	2026-08-16 02:33:57.144434+00
DOT/USD	1m	1786847580	0.757	0.757	0.757	0.757	24	2026-08-16 02:33:57.144434+00
LTC/USD	1m	1786847580	44.29	44.29	44.29	44.29	24	2026-08-16 02:33:57.144434+00
UNI/USD	1m	1786847580	3.235	3.235	3.235	3.235	24	2026-08-16 02:33:57.144434+00
SOL/USD	1m	1786847580	75.562	75.562	75.562	75.562	24	2026-08-16 02:33:57.144434+00
XLM/USD	1m	1786847580	0.15656	0.15656	0.15656	0.15656	24	2026-08-16 02:33:57.144434+00
ADA/USD	1m	1786847580	0.1766	0.1766	0.1766	0.1766	24	2026-08-16 02:33:57.144434+00
POL/USD	1m	1786847580	0.075	0.075	0.075	0.075	24	2026-08-16 02:33:57.144434+00
LINK/USD	1m	1786847580	9.482	9.482	9.482	9.482	24	2026-08-16 02:33:57.144434+00
AAVE/USD	1m	1786847640	86.23	86.23	86.23	86.23	29	2026-08-16 02:34:57.141038+00
AAVE/USD	5m	1786847400	86.23	86.23	86.23	86.23	53	2026-08-16 02:34:57.141038+00
LINK/USD	1m	1786847640	9.482	9.482	9.482	9.482	29	2026-08-16 02:34:57.141038+00
LINK/USD	5m	1786847400	9.482	9.482	9.482	9.482	53	2026-08-16 02:34:57.141038+00
BTC/USD	1m	1786847640	63172.75	63172.75	63172.75	63172.75	29	2026-08-16 02:34:57.141038+00
BTC/USD	5m	1786847400	63172.75	63172.75	63172.75	63172.75	53	2026-08-16 02:34:57.141038+00
ADA/USD	1m	1786847640	0.1766	0.1766	0.1766	0.1766	29	2026-08-16 02:34:57.141038+00
ADA/USD	5m	1786847400	0.1766	0.1766	0.1766	0.1766	53	2026-08-16 02:34:57.141038+00
NEAR/USD	1m	1786847640	1.612	1.612	1.612	1.612	29	2026-08-16 02:34:57.141038+00
NEAR/USD	5m	1786847400	1.612	1.612	1.612	1.612	53	2026-08-16 02:34:57.141038+00
POL/USD	1m	1786847640	0.075	0.075	0.075	0.075	29	2026-08-16 02:34:57.141038+00
POL/USD	5m	1786847400	0.075	0.075	0.075	0.075	53	2026-08-16 02:34:57.141038+00
ETH/USD	1m	1786847640	1884.66	1884.66	1884.66	1884.66	29	2026-08-16 02:34:57.141038+00
ETH/USD	5m	1786847400	1884.66	1884.66	1884.66	1884.66	53	2026-08-16 02:34:57.141038+00
DOT/USD	1m	1786847640	0.757	0.757	0.757	0.757	29	2026-08-16 02:34:57.141038+00
DOT/USD	5m	1786847400	0.757	0.757	0.757	0.757	53	2026-08-16 02:34:57.141038+00
DOGE/USD	1m	1786847640	0.0696705	0.0696705	0.0696705	0.0696705	29	2026-08-16 02:34:57.141038+00
DOGE/USD	5m	1786847400	0.0696705	0.0696705	0.0696705	0.0696705	53	2026-08-16 02:34:57.141038+00
SOL/USD	1m	1786847640	75.562	75.562	75.562	75.562	29	2026-08-16 02:34:57.141038+00
SOL/USD	5m	1786847400	75.562	75.562	75.562	75.562	53	2026-08-16 02:34:57.141038+00
SUI/USD	1m	1786847640	0.676	0.676	0.676	0.676	30	2026-08-16 02:34:57.141038+00
SUI/USD	5m	1786847400	0.676	0.676	0.676	0.676	53	2026-08-16 02:34:57.141038+00
LTC/USD	1m	1786847640	44.29	44.29	44.29	44.29	29	2026-08-16 02:34:57.141038+00
LTC/USD	5m	1786847400	44.29	44.29	44.29	44.29	53	2026-08-16 02:34:57.141038+00
XRP/USD	1m	1786847640	1.00089	1.00089	1.00089	1.00089	29	2026-08-16 02:34:57.141038+00
XRP/USD	5m	1786847400	1.00089	1.00089	1.00089	1.00089	53	2026-08-16 02:34:57.141038+00
APT/USD	1m	1786847640	0.5344	0.5344	0.5344	0.5344	29	2026-08-16 02:34:57.141038+00
APT/USD	5m	1786847400	0.5344	0.5344	0.5344	0.5344	53	2026-08-16 02:34:57.141038+00
UNI/USD	1m	1786847640	3.235	3.235	3.235	3.235	29	2026-08-16 02:34:57.141038+00
UNI/USD	5m	1786847400	3.235	3.235	3.235	3.235	53	2026-08-16 02:34:57.141038+00
XLM/USD	1m	1786847640	0.15656	0.15656	0.15656	0.15656	29	2026-08-16 02:34:57.141038+00
XLM/USD	5m	1786847400	0.15656	0.15656	0.15656	0.15656	53	2026-08-16 02:34:57.141038+00
AVAX/USD	1m	1786847640	6.34	6.34	6.34	6.34	29	2026-08-16 02:34:57.141038+00
AVAX/USD	5m	1786847400	6.34	6.34	6.34	6.34	53	2026-08-16 02:34:57.141038+00
ETH/USD	1m	1786847700	1884.66	1884.66	1884.66	1884.66	30	2026-08-16 02:35:57.137225+00
SUI/USD	1m	1786847700	0.676	0.676	0.676	0.676	30	2026-08-16 02:35:57.137225+00
LINK/USD	1m	1786847700	9.482	9.482	9.482	9.482	30	2026-08-16 02:35:57.137225+00
BTC/USD	1m	1786847700	63172.75	63172.75	63172.75	63172.75	30	2026-08-16 02:35:57.137225+00
DOT/USD	1m	1786847700	0.757	0.757	0.757	0.757	30	2026-08-16 02:35:57.137225+00
POL/USD	1m	1786847700	0.075	0.075	0.075	0.075	30	2026-08-16 02:35:57.137225+00
XLM/USD	1m	1786847700	0.15656	0.15656	0.15656	0.15656	30	2026-08-16 02:35:57.137225+00
APT/USD	1m	1786847700	0.5344	0.5344	0.5344	0.5344	30	2026-08-16 02:35:57.137225+00
UNI/USD	1m	1786847700	3.235	3.235	3.235	3.235	30	2026-08-16 02:35:57.137225+00
LTC/USD	1m	1786847700	44.29	44.29	44.29	44.29	30	2026-08-16 02:35:57.137225+00
SOL/USD	1m	1786847700	75.562	75.562	75.562	75.562	30	2026-08-16 02:35:57.137225+00
NEAR/USD	1m	1786847700	1.612	1.612	1.612	1.612	30	2026-08-16 02:35:57.137225+00
ADA/USD	1m	1786847700	0.1766	0.1766	0.1766	0.1766	30	2026-08-16 02:35:57.137225+00
XRP/USD	1m	1786847700	1.00089	1.00089	1.00089	1.00089	30	2026-08-16 02:35:57.137225+00
AVAX/USD	1m	1786847700	6.34	6.34	6.34	6.34	30	2026-08-16 02:35:57.137225+00
AAVE/USD	1m	1786847700	86.23	86.23	86.23	86.23	30	2026-08-16 02:35:57.137225+00
DOGE/USD	1m	1786847700	0.0696705	0.0696705	0.0696705	0.0696705	31	2026-08-16 02:35:57.137225+00
APT/USD	1m	1786847760	0.5344	0.5344	0.5344	0.5344	30	2026-08-16 02:36:57.134419+00
LINK/USD	1m	1786847760	9.482	9.482	9.482	9.482	30	2026-08-16 02:36:57.134419+00
BTC/USD	1m	1786847760	63172.75	63172.75	63172.75	63172.75	30	2026-08-16 02:36:57.134419+00
DOGE/USD	1m	1786847760	0.0696705	0.0696705	0.0696705	0.0696705	29	2026-08-16 02:36:57.134419+00
DOT/USD	1m	1786847760	0.757	0.757	0.757	0.757	30	2026-08-16 02:36:57.134419+00
SOL/USD	1m	1786847760	75.562	75.562	75.562	75.562	30	2026-08-16 02:36:57.134419+00
ADA/USD	1m	1786847760	0.1766	0.1766	0.1766	0.1766	30	2026-08-16 02:36:57.134419+00
AVAX/USD	1m	1786847760	6.34	6.34	6.34	6.34	30	2026-08-16 02:36:57.134419+00
XRP/USD	1m	1786847760	1.00089	1.00089	1.00089	1.00089	30	2026-08-16 02:36:57.134419+00
XLM/USD	1m	1786847760	0.15656	0.15656	0.15656	0.15656	30	2026-08-16 02:36:57.134419+00
SUI/USD	1m	1786847760	0.676	0.676	0.676	0.676	30	2026-08-16 02:36:57.134419+00
NEAR/USD	1m	1786847760	1.612	1.612	1.612	1.612	30	2026-08-16 02:36:57.134419+00
POL/USD	1m	1786847760	0.075	0.075	0.075	0.075	30	2026-08-16 02:36:57.134419+00
UNI/USD	1m	1786847760	3.235	3.235	3.235	3.235	30	2026-08-16 02:36:57.134419+00
AAVE/USD	1m	1786847760	86.23	86.23	86.23	86.23	30	2026-08-16 02:36:57.134419+00
ETH/USD	1m	1786847760	1884.66	1884.66	1884.66	1884.66	30	2026-08-16 02:36:57.134419+00
LTC/USD	1m	1786847760	44.29	44.29	44.29	44.29	30	2026-08-16 02:36:57.134419+00
APT/USD	1m	1786847820	0.5344	0.5344	0.5344	0.5344	30	2026-08-16 02:37:57.131234+00
DOGE/USD	1m	1786847820	0.0696705	0.0696705	0.0696705	0.0696705	30	2026-08-16 02:37:57.131234+00
POL/USD	1m	1786847820	0.075	0.075	0.075	0.075	30	2026-08-16 02:37:57.131234+00
SOL/USD	1m	1786847820	75.562	75.562	75.562	75.562	30	2026-08-16 02:37:57.131234+00
SUI/USD	1m	1786847820	0.676	0.676	0.676	0.676	30	2026-08-16 02:37:57.131234+00
NEAR/USD	1m	1786847820	1.612	1.612	1.612	1.612	30	2026-08-16 02:37:57.131234+00
BTC/USD	1m	1786847820	63172.75	63172.75	63172.75	63172.75	30	2026-08-16 02:37:57.131234+00
XLM/USD	1m	1786847820	0.15656	0.15656	0.15656	0.15656	30	2026-08-16 02:37:57.131234+00
LINK/USD	1m	1786847820	9.482	9.482	9.482	9.482	30	2026-08-16 02:37:57.131234+00
ADA/USD	1m	1786847820	0.1766	0.1766	0.1766	0.1766	30	2026-08-16 02:37:57.131234+00
AVAX/USD	1m	1786847820	6.34	6.34	6.34	6.34	30	2026-08-16 02:37:57.131234+00
DOT/USD	1m	1786847820	0.757	0.757	0.757	0.757	30	2026-08-16 02:37:57.131234+00
AAVE/USD	1m	1786847820	86.23	86.23	86.23	86.23	30	2026-08-16 02:37:57.131234+00
ETH/USD	1m	1786847820	1884.66	1884.66	1884.66	1884.66	30	2026-08-16 02:37:57.131234+00
XRP/USD	1m	1786847820	1.00089	1.00089	1.00089	1.00089	30	2026-08-16 02:37:57.131234+00
UNI/USD	1m	1786847820	3.235	3.235	3.235	3.235	30	2026-08-16 02:37:57.131234+00
LTC/USD	1m	1786847820	44.29	44.29	44.29	44.29	31	2026-08-16 02:37:57.131234+00
BTC/USD	1m	1786847880	63172.75	63172.75	63172.75	63172.75	30	2026-08-16 02:38:57.129384+00
UNI/USD	1m	1786847880	3.235	3.235	3.235	3.235	30	2026-08-16 02:38:57.129384+00
SOL/USD	1m	1786847880	75.562	75.562	75.562	75.562	30	2026-08-16 02:38:57.129384+00
ETH/USD	1m	1786847880	1884.66	1884.66	1884.66	1884.66	30	2026-08-16 02:38:57.129384+00
XRP/USD	1m	1786847880	1.00089	1.00089	1.00089	1.00089	30	2026-08-16 02:38:57.129384+00
ADA/USD	1m	1786847880	0.1766	0.1766	0.1766	0.1766	30	2026-08-16 02:38:57.129384+00
SUI/USD	1m	1786847880	0.676	0.676	0.676	0.676	30	2026-08-16 02:38:57.129384+00
AAVE/USD	1m	1786847880	86.23	86.23	86.23	86.23	30	2026-08-16 02:38:57.129384+00
NEAR/USD	1m	1786847880	1.612	1.612	1.612	1.612	30	2026-08-16 02:38:57.129384+00
XLM/USD	1m	1786847880	0.15656	0.15656	0.15656	0.15656	30	2026-08-16 02:38:57.129384+00
APT/USD	1m	1786847880	0.5344	0.5344	0.5344	0.5344	30	2026-08-16 02:38:57.129384+00
DOT/USD	1m	1786847880	0.757	0.757	0.757	0.757	30	2026-08-16 02:38:57.129384+00
DOGE/USD	1m	1786847880	0.0696705	0.0696705	0.0696705	0.0696705	30	2026-08-16 02:38:57.129384+00
LINK/USD	1m	1786847880	9.482	9.482	9.482	9.482	30	2026-08-16 02:38:57.129384+00
AVAX/USD	1m	1786847880	6.34	6.34	6.34	6.34	30	2026-08-16 02:38:57.129384+00
POL/USD	1m	1786847880	0.075	0.075	0.075	0.075	30	2026-08-16 02:38:57.129384+00
LTC/USD	1m	1786847880	44.29	44.29	44.29	44.29	29	2026-08-16 02:38:57.129384+00
XLM/USD	1m	1786847940	0.15656	0.15656	0.15656	0.15656	30	2026-08-16 02:39:57.126758+00
XLM/USD	5m	1786847700	0.15656	0.15656	0.15656	0.15656	150	2026-08-16 02:39:57.126758+00
ADA/USD	1m	1786847940	0.1766	0.1766	0.1766	0.1766	30	2026-08-16 02:39:57.126758+00
ADA/USD	5m	1786847700	0.1766	0.1766	0.1766	0.1766	150	2026-08-16 02:39:57.126758+00
AAVE/USD	1m	1786847940	86.23	86.23	86.23	86.23	30	2026-08-16 02:39:57.126758+00
AAVE/USD	5m	1786847700	86.23	86.23	86.23	86.23	150	2026-08-16 02:39:57.126758+00
BTC/USD	1m	1786847940	63172.75	63172.75	63172.75	63172.75	30	2026-08-16 02:39:57.126758+00
BTC/USD	5m	1786847700	63172.75	63172.75	63172.75	63172.75	150	2026-08-16 02:39:57.126758+00
SOL/USD	1m	1786847940	75.562	75.562	75.562	75.562	30	2026-08-16 02:39:57.126758+00
SOL/USD	5m	1786847700	75.562	75.562	75.562	75.562	150	2026-08-16 02:39:57.126758+00
ETH/USD	1m	1786847940	1884.66	1884.66	1884.66	1884.66	30	2026-08-16 02:39:57.126758+00
ETH/USD	5m	1786847700	1884.66	1884.66	1884.66	1884.66	150	2026-08-16 02:39:57.126758+00
UNI/USD	1m	1786847940	3.235	3.235	3.235	3.235	30	2026-08-16 02:39:57.126758+00
UNI/USD	5m	1786847700	3.235	3.235	3.235	3.235	150	2026-08-16 02:39:57.126758+00
LINK/USD	1m	1786847940	9.482	9.482	9.482	9.482	30	2026-08-16 02:39:57.126758+00
LINK/USD	5m	1786847700	9.482	9.482	9.482	9.482	150	2026-08-16 02:39:57.126758+00
XRP/USD	1m	1786847940	1.00089	1.00089	1.00089	1.00089	30	2026-08-16 02:39:57.126758+00
XRP/USD	5m	1786847700	1.00089	1.00089	1.00089	1.00089	150	2026-08-16 02:39:57.126758+00
APT/USD	1m	1786847940	0.5344	0.5344	0.5344	0.5344	30	2026-08-16 02:39:57.126758+00
APT/USD	5m	1786847700	0.5344	0.5344	0.5344	0.5344	150	2026-08-16 02:39:57.126758+00
POL/USD	1m	1786847940	0.075	0.075	0.075	0.075	30	2026-08-16 02:39:57.126758+00
POL/USD	5m	1786847700	0.075	0.075	0.075	0.075	150	2026-08-16 02:39:57.126758+00
SUI/USD	1m	1786847940	0.676	0.676	0.676	0.676	30	2026-08-16 02:39:57.126758+00
SUI/USD	5m	1786847700	0.676	0.676	0.676	0.676	150	2026-08-16 02:39:57.126758+00
NEAR/USD	1m	1786847940	1.612	1.612	1.612	1.612	30	2026-08-16 02:39:57.126758+00
NEAR/USD	5m	1786847700	1.612	1.612	1.612	1.612	150	2026-08-16 02:39:57.126758+00
AVAX/USD	1m	1786847940	6.34	6.34	6.34	6.34	30	2026-08-16 02:39:57.126758+00
AVAX/USD	5m	1786847700	6.34	6.34	6.34	6.34	150	2026-08-16 02:39:57.126758+00
LTC/USD	1m	1786847940	44.29	44.29	44.29	44.29	30	2026-08-16 02:39:57.126758+00
LTC/USD	5m	1786847700	44.29	44.29	44.29	44.29	150	2026-08-16 02:39:57.126758+00
DOGE/USD	1m	1786847940	0.0696705	0.0696705	0.0696705	0.0696705	30	2026-08-16 02:39:57.126758+00
DOGE/USD	5m	1786847700	0.0696705	0.0696705	0.0696705	0.0696705	150	2026-08-16 02:39:57.126758+00
DOT/USD	1m	1786847940	0.757	0.757	0.757	0.757	30	2026-08-16 02:39:57.126758+00
DOT/USD	5m	1786847700	0.757	0.757	0.757	0.757	150	2026-08-16 02:39:57.126758+00
BTC/USD	1m	1786848000	63172.75	63172.75	63172.75	63172.75	24	2026-08-16 02:40:53.834288+00
XRP/USD	1m	1786848000	1.00089	1.00089	1.00089	1.00089	24	2026-08-16 02:40:53.834288+00
SUI/USD	1m	1786848000	0.676	0.676	0.676	0.676	24	2026-08-16 02:40:53.834288+00
ADA/USD	1m	1786848000	0.1766	0.177	0.1766	0.177	24	2026-08-16 02:40:53.834288+00
DOGE/USD	1m	1786848000	0.0696705	0.0696705	0.0696705	0.0696705	24	2026-08-16 02:40:53.834288+00
NEAR/USD	1m	1786848000	1.612	1.612	1.612	1.612	24	2026-08-16 02:40:53.834288+00
LTC/USD	1m	1786848000	44.29	44.29	44.29	44.29	24	2026-08-16 02:40:53.834288+00
ETH/USD	1m	1786848000	1884.66	1884.66	1884.66	1884.66	24	2026-08-16 02:40:53.834288+00
XLM/USD	1m	1786848000	0.15656	0.15656	0.15656	0.15656	24	2026-08-16 02:40:53.834288+00
LINK/USD	1m	1786848000	9.482	9.482	9.482	9.482	24	2026-08-16 02:40:53.834288+00
SOL/USD	1m	1786848000	75.562	75.562	75.562	75.562	25	2026-08-16 02:40:58.834174+00
AVAX/USD	1m	1786848000	6.34	6.34	6.34	6.34	25	2026-08-16 02:40:58.834174+00
DOT/USD	1m	1786848000	0.757	0.757	0.757	0.757	25	2026-08-16 02:40:58.834174+00
POL/USD	1m	1786848000	0.075	0.075	0.075	0.075	25	2026-08-16 02:40:58.834174+00
UNI/USD	1m	1786848000	3.235	3.235	3.235	3.235	25	2026-08-16 02:40:58.834174+00
AAVE/USD	1m	1786848000	86.23	86.23	86.23	86.23	25	2026-08-16 02:40:58.834174+00
APT/USD	1m	1786848000	0.5344	0.5344	0.5344	0.5344	25	2026-08-16 02:40:58.834174+00
AAVE/USD	1m	1786848060	86.23	86.23	86.23	86.23	24	2026-08-16 02:41:54.581963+00
POL/USD	1m	1786848060	0.075	0.075	0.075	0.075	24	2026-08-16 02:41:54.581963+00
DOGE/USD	1m	1786848060	0.0696705	0.0696705	0.0696705	0.0696705	25	2026-08-16 02:41:54.581963+00
XLM/USD	1m	1786848060	0.15656	0.15656	0.15656	0.15656	25	2026-08-16 02:41:54.581963+00
BTC/USD	1m	1786848060	63172.75	63172.75	63172.75	63172.75	25	2026-08-16 02:41:54.581963+00
ADA/USD	1m	1786848060	0.177	0.177	0.177	0.177	25	2026-08-16 02:41:54.581963+00
LINK/USD	1m	1786848060	9.482	9.482	9.482	9.482	25	2026-08-16 02:41:54.581963+00
DOT/USD	1m	1786848060	0.757	0.757	0.757	0.757	24	2026-08-16 02:41:54.581963+00
XRP/USD	1m	1786848060	1.00089	1.00089	1.00089	1.00089	25	2026-08-16 02:41:54.581963+00
APT/USD	1m	1786848060	0.5344	0.5344	0.5344	0.5344	24	2026-08-16 02:41:54.581963+00
NEAR/USD	1m	1786848060	1.612	1.612	1.612	1.612	25	2026-08-16 02:41:54.581963+00
AVAX/USD	1m	1786848060	6.34	6.34	6.34	6.34	24	2026-08-16 02:41:54.581963+00
LTC/USD	1m	1786848060	44.29	44.29	44.29	44.29	25	2026-08-16 02:41:54.581963+00
SUI/USD	1m	1786848060	0.676	0.676	0.676	0.676	25	2026-08-16 02:41:54.581963+00
SOL/USD	1m	1786848060	75.562	75.562	75.562	75.562	24	2026-08-16 02:41:54.581963+00
ETH/USD	1m	1786848060	1884.66	1884.66	1884.66	1884.66	25	2026-08-16 02:41:54.581963+00
UNI/USD	1m	1786848060	3.235	3.235	3.233	3.233	24	2026-08-16 02:41:54.581963+00
XRP/USD	1m	1786848120	1.00089	1.00089	1.00089	1.00089	30	2026-08-16 02:42:54.577984+00
XLM/USD	1m	1786848120	0.15656	0.15656	0.15656	0.15656	30	2026-08-16 02:42:54.577984+00
NEAR/USD	1m	1786848120	1.612	1.612	1.612	1.612	30	2026-08-16 02:42:54.577984+00
LTC/USD	1m	1786848120	44.29	44.29	44.29	44.29	30	2026-08-16 02:42:54.577984+00
SOL/USD	1m	1786848120	75.562	75.562	75.562	75.562	30	2026-08-16 02:42:54.577984+00
AVAX/USD	1m	1786848120	6.34	6.34	6.34	6.34	30	2026-08-16 02:42:54.577984+00
LINK/USD	1m	1786848120	9.482	9.482	9.482	9.482	30	2026-08-16 02:42:54.577984+00
AAVE/USD	1m	1786848120	86.23	86.23	86.23	86.23	30	2026-08-16 02:42:54.577984+00
ADA/USD	1m	1786848120	0.177	0.177	0.177	0.177	30	2026-08-16 02:42:54.577984+00
BTC/USD	1m	1786848120	63172.75	63172.75	63172.75	63172.75	30	2026-08-16 02:42:54.577984+00
APT/USD	1m	1786848120	0.5344	0.5344	0.5344	0.5344	30	2026-08-16 02:42:54.577984+00
POL/USD	1m	1786848120	0.075	0.075	0.075	0.075	30	2026-08-16 02:42:54.577984+00
SUI/USD	1m	1786848120	0.676	0.676	0.676	0.676	30	2026-08-16 02:42:54.577984+00
DOGE/USD	1m	1786848120	0.0696705	0.0696705	0.0696705	0.0696705	30	2026-08-16 02:42:54.577984+00
DOT/USD	1m	1786848120	0.757	0.757	0.757	0.757	30	2026-08-16 02:42:54.577984+00
UNI/USD	1m	1786848120	3.233	3.233	3.233	3.233	30	2026-08-16 02:42:54.577984+00
ETH/USD	1m	1786848120	1884.66	1884.66	1884.66	1884.66	30	2026-08-16 02:42:54.577984+00
LINK/USD	1m	1786848180	9.482	9.482	9.482	9.482	30	2026-08-16 02:43:54.574997+00
DOT/USD	1m	1786848180	0.757	0.757	0.757	0.757	30	2026-08-16 02:43:54.574997+00
APT/USD	1m	1786848180	0.5344	0.5344	0.5344	0.5344	30	2026-08-16 02:43:54.574997+00
AVAX/USD	1m	1786848180	6.34	6.34	6.34	6.34	30	2026-08-16 02:43:54.574997+00
AAVE/USD	1m	1786848180	86.23	86.23	86.23	86.23	30	2026-08-16 02:43:54.574997+00
ADA/USD	1m	1786848180	0.177	0.177	0.177	0.177	30	2026-08-16 02:43:54.574997+00
POL/USD	1m	1786848180	0.075	0.075	0.075	0.075	30	2026-08-16 02:43:54.574997+00
BTC/USD	1m	1786848180	63172.75	63172.75	63172.75	63172.75	30	2026-08-16 02:43:54.574997+00
XLM/USD	1m	1786848180	0.15656	0.15656	0.15656	0.15656	30	2026-08-16 02:43:54.574997+00
UNI/USD	1m	1786848180	3.233	3.233	3.233	3.233	30	2026-08-16 02:43:54.574997+00
ETH/USD	1m	1786848180	1884.66	1884.66	1884.66	1884.66	30	2026-08-16 02:43:54.574997+00
LTC/USD	1m	1786848180	44.29	44.29	44.29	44.29	30	2026-08-16 02:43:54.574997+00
SUI/USD	1m	1786848180	0.676	0.676	0.676	0.676	30	2026-08-16 02:43:54.574997+00
XRP/USD	1m	1786848180	1.00089	1.00089	1.00089	1.00089	30	2026-08-16 02:43:54.574997+00
SOL/USD	1m	1786848180	75.562	75.562	75.562	75.562	30	2026-08-16 02:43:54.574997+00
NEAR/USD	1m	1786848180	1.612	1.612	1.612	1.612	30	2026-08-16 02:43:54.574997+00
DOGE/USD	1m	1786848180	0.0696705	0.0696705	0.0696705	0.0696705	30	2026-08-16 02:43:54.574997+00
UNI/USD	1m	1786848240	3.233	3.233	3.233	3.233	30	2026-08-16 02:44:54.636506+00
UNI/USD	5m	1786848000	3.235	3.235	3.233	3.233	139	2026-08-16 02:44:54.636506+00
UNI/USD	15m	1786847400	3.235	3.235	3.233	3.233	342	2026-08-16 02:44:54.636506+00
APT/USD	1m	1786848240	0.5344	0.5344	0.5344	0.5344	30	2026-08-16 02:44:54.636506+00
APT/USD	5m	1786848000	0.5344	0.5344	0.5344	0.5344	139	2026-08-16 02:44:54.636506+00
APT/USD	15m	1786847400	0.5344	0.5344	0.5344	0.5344	342	2026-08-16 02:44:54.636506+00
BTC/USD	1m	1786848240	63172.75	63172.75	63172.75	63172.75	30	2026-08-16 02:44:54.636506+00
BTC/USD	5m	1786848000	63172.75	63172.75	63172.75	63172.75	139	2026-08-16 02:44:54.636506+00
BTC/USD	15m	1786847400	63172.75	63172.75	63172.75	63172.75	342	2026-08-16 02:44:54.636506+00
ADA/USD	1m	1786848240	0.177	0.177	0.177	0.177	30	2026-08-16 02:44:54.636506+00
ADA/USD	5m	1786848000	0.1766	0.177	0.1766	0.177	139	2026-08-16 02:44:54.636506+00
ADA/USD	15m	1786847400	0.1766	0.177	0.1766	0.177	342	2026-08-16 02:44:54.636506+00
ETH/USD	1m	1786848240	1884.66	1884.66	1884.66	1884.66	30	2026-08-16 02:44:54.636506+00
ETH/USD	5m	1786848000	1884.66	1884.66	1884.66	1884.66	139	2026-08-16 02:44:54.636506+00
ETH/USD	15m	1786847400	1884.66	1884.66	1884.66	1884.66	342	2026-08-16 02:44:54.636506+00
AVAX/USD	1m	1786848240	6.34	6.34	6.34	6.34	30	2026-08-16 02:44:54.636506+00
AVAX/USD	5m	1786848000	6.34	6.34	6.34	6.34	139	2026-08-16 02:44:54.636506+00
AVAX/USD	15m	1786847400	6.34	6.34	6.34	6.34	342	2026-08-16 02:44:54.636506+00
SUI/USD	1m	1786848240	0.676	0.676	0.676	0.676	30	2026-08-16 02:44:54.636506+00
SUI/USD	5m	1786848000	0.676	0.676	0.676	0.676	139	2026-08-16 02:44:54.636506+00
SUI/USD	15m	1786847400	0.676	0.676	0.676	0.676	342	2026-08-16 02:44:54.636506+00
SOL/USD	1m	1786848240	75.562	75.562	75.562	75.562	30	2026-08-16 02:44:54.636506+00
SOL/USD	5m	1786848000	75.562	75.562	75.562	75.562	139	2026-08-16 02:44:54.636506+00
SOL/USD	15m	1786847400	75.562	75.562	75.562	75.562	342	2026-08-16 02:44:54.636506+00
LTC/USD	1m	1786848240	44.29	44.29	44.29	44.29	30	2026-08-16 02:44:54.636506+00
LTC/USD	5m	1786848000	44.29	44.29	44.29	44.29	139	2026-08-16 02:44:54.636506+00
LTC/USD	15m	1786847400	44.29	44.29	44.29	44.29	342	2026-08-16 02:44:54.636506+00
NEAR/USD	1m	1786848240	1.612	1.612	1.612	1.612	30	2026-08-16 02:44:54.636506+00
NEAR/USD	5m	1786848000	1.612	1.612	1.612	1.612	139	2026-08-16 02:44:54.636506+00
NEAR/USD	15m	1786847400	1.612	1.612	1.612	1.612	342	2026-08-16 02:44:54.636506+00
LINK/USD	1m	1786848240	9.482	9.482	9.482	9.482	30	2026-08-16 02:44:54.636506+00
LINK/USD	5m	1786848000	9.482	9.482	9.482	9.482	139	2026-08-16 02:44:54.636506+00
LINK/USD	15m	1786847400	9.482	9.482	9.482	9.482	342	2026-08-16 02:44:54.636506+00
POL/USD	1m	1786848240	0.075	0.075	0.075	0.075	30	2026-08-16 02:44:54.636506+00
POL/USD	5m	1786848000	0.075	0.075	0.075	0.075	139	2026-08-16 02:44:54.636506+00
POL/USD	15m	1786847400	0.075	0.075	0.075	0.075	342	2026-08-16 02:44:54.636506+00
AAVE/USD	1m	1786848240	86.23	86.23	86.23	86.23	30	2026-08-16 02:44:54.636506+00
AAVE/USD	5m	1786848000	86.23	86.23	86.23	86.23	139	2026-08-16 02:44:54.636506+00
AAVE/USD	15m	1786847400	86.23	86.23	86.23	86.23	342	2026-08-16 02:44:54.636506+00
DOT/USD	1m	1786848240	0.757	0.757	0.757	0.757	30	2026-08-16 02:44:54.636506+00
DOT/USD	5m	1786848000	0.757	0.757	0.757	0.757	139	2026-08-16 02:44:54.636506+00
DOT/USD	15m	1786847400	0.757	0.757	0.757	0.757	342	2026-08-16 02:44:54.636506+00
DOGE/USD	1m	1786848240	0.0696705	0.0696705	0.0696705	0.0696705	30	2026-08-16 02:44:54.636506+00
DOGE/USD	5m	1786848000	0.0696705	0.0696705	0.0696705	0.0696705	139	2026-08-16 02:44:54.636506+00
DOGE/USD	15m	1786847400	0.0696705	0.0696705	0.0696705	0.0696705	342	2026-08-16 02:44:54.636506+00
XRP/USD	1m	1786848240	1.00089	1.00089	1.00089	1.00089	30	2026-08-16 02:44:54.636506+00
XRP/USD	5m	1786848000	1.00089	1.00089	1.00089	1.00089	139	2026-08-16 02:44:54.636506+00
XRP/USD	15m	1786847400	1.00089	1.00089	1.00089	1.00089	342	2026-08-16 02:44:54.636506+00
XLM/USD	1m	1786848240	0.15656	0.15656	0.15656	0.15656	30	2026-08-16 02:44:54.636506+00
XLM/USD	5m	1786848000	0.15656	0.15656	0.15656	0.15656	139	2026-08-16 02:44:54.636506+00
XLM/USD	15m	1786847400	0.15656	0.15656	0.15656	0.15656	342	2026-08-16 02:44:54.636506+00
AVAX/USD	1m	1786848300	6.34	6.34	6.34	6.34	30	2026-08-16 02:45:54.569914+00
UNI/USD	1m	1786848300	3.233	3.233	3.233	3.233	30	2026-08-16 02:45:54.569914+00
XLM/USD	1m	1786848300	0.15656	0.15656	0.15656	0.15656	30	2026-08-16 02:45:54.569914+00
APT/USD	1m	1786848300	0.5344	0.5344	0.5344	0.5344	30	2026-08-16 02:45:54.569914+00
POL/USD	1m	1786848300	0.075	0.075	0.075	0.075	30	2026-08-16 02:45:54.569914+00
ADA/USD	1m	1786848300	0.177	0.177	0.177	0.177	30	2026-08-16 02:45:54.569914+00
LTC/USD	1m	1786848300	44.29	44.29	44.29	44.29	30	2026-08-16 02:45:54.569914+00
BTC/USD	1m	1786848300	63172.75	63172.75	63172.75	63172.75	30	2026-08-16 02:45:54.569914+00
SUI/USD	1m	1786848300	0.676	0.676	0.676	0.676	30	2026-08-16 02:45:54.569914+00
ETH/USD	1m	1786848300	1884.66	1884.66	1884.66	1884.66	30	2026-08-16 02:45:54.569914+00
SOL/USD	1m	1786848300	75.562	75.562	75.562	75.562	30	2026-08-16 02:45:54.569914+00
DOT/USD	1m	1786848300	0.757	0.757	0.757	0.757	30	2026-08-16 02:45:54.569914+00
XRP/USD	1m	1786848300	1.00089	1.00089	1.00089	1.00089	30	2026-08-16 02:45:54.569914+00
DOGE/USD	1m	1786848300	0.0696705	0.0696705	0.0696705	0.0696705	30	2026-08-16 02:45:54.569914+00
NEAR/USD	1m	1786848300	1.612	1.612	1.612	1.612	30	2026-08-16 02:45:54.569914+00
AAVE/USD	1m	1786848300	86.23	86.23	86.23	86.23	30	2026-08-16 02:45:54.569914+00
LINK/USD	1m	1786848300	9.482	9.482	9.482	9.482	30	2026-08-16 02:45:54.569914+00
POL/USD	1m	1786848360	0.075	0.075	0.075	0.075	30	2026-08-16 02:46:54.566712+00
ADA/USD	1m	1786848360	0.177	0.177	0.177	0.177	30	2026-08-16 02:46:54.566712+00
XLM/USD	1m	1786848360	0.15656	0.15656	0.15656	0.15656	30	2026-08-16 02:46:54.566712+00
SOL/USD	1m	1786848360	75.562	75.562	75.562	75.562	30	2026-08-16 02:46:54.566712+00
DOT/USD	1m	1786848360	0.757	0.757	0.757	0.757	30	2026-08-16 02:46:54.566712+00
SUI/USD	1m	1786848360	0.676	0.676	0.676	0.676	30	2026-08-16 02:46:54.566712+00
DOGE/USD	1m	1786848360	0.0696705	0.0696705	0.0696705	0.0696705	30	2026-08-16 02:46:54.566712+00
ETH/USD	1m	1786848360	1884.66	1884.66	1884.66	1884.66	30	2026-08-16 02:46:54.566712+00
UNI/USD	1m	1786848360	3.233	3.233	3.233	3.233	30	2026-08-16 02:46:54.566712+00
LINK/USD	1m	1786848360	9.482	9.482	9.482	9.482	30	2026-08-16 02:46:54.566712+00
APT/USD	1m	1786848360	0.5344	0.5344	0.5344	0.5344	30	2026-08-16 02:46:54.566712+00
AAVE/USD	1m	1786848360	86.23	86.23	86.23	86.23	30	2026-08-16 02:46:54.566712+00
NEAR/USD	1m	1786848360	1.612	1.612	1.612	1.612	30	2026-08-16 02:46:54.566712+00
BTC/USD	1m	1786848360	63172.75	63172.75	63172.75	63172.75	30	2026-08-16 02:46:54.566712+00
LTC/USD	1m	1786848360	44.29	44.29	44.29	44.29	30	2026-08-16 02:46:54.566712+00
XRP/USD	1m	1786848360	1.00089	1.00089	1.00089	1.00089	30	2026-08-16 02:46:54.566712+00
AVAX/USD	1m	1786848360	6.34	6.34	6.34	6.34	30	2026-08-16 02:46:54.566712+00
SOL/USD	1m	1786848420	75.562	75.562	75.562	75.562	30	2026-08-16 02:47:54.563781+00
AAVE/USD	1m	1786848420	86.23	86.23	86.23	86.23	30	2026-08-16 02:47:54.563781+00
AVAX/USD	1m	1786848420	6.34	6.34	6.34	6.34	30	2026-08-16 02:47:54.563781+00
ADA/USD	1m	1786848420	0.177	0.177	0.177	0.177	30	2026-08-16 02:47:54.563781+00
POL/USD	1m	1786848420	0.075	0.075	0.075	0.075	30	2026-08-16 02:47:54.563781+00
DOT/USD	1m	1786848420	0.757	0.757	0.757	0.757	30	2026-08-16 02:47:54.563781+00
ETH/USD	1m	1786848420	1884.66	1884.66	1884.66	1884.66	30	2026-08-16 02:47:54.563781+00
LTC/USD	1m	1786848420	44.29	44.29	44.29	44.29	30	2026-08-16 02:47:54.563781+00
XLM/USD	1m	1786848420	0.15656	0.15656	0.15656	0.15656	30	2026-08-16 02:47:54.563781+00
NEAR/USD	1m	1786848420	1.612	1.612	1.612	1.612	30	2026-08-16 02:47:54.563781+00
DOGE/USD	1m	1786848420	0.0696705	0.0696705	0.0696705	0.0696705	30	2026-08-16 02:47:54.563781+00
XRP/USD	1m	1786848420	1.00089	1.00089	1.00089	1.00089	30	2026-08-16 02:47:54.563781+00
UNI/USD	1m	1786848420	3.233	3.233	3.233	3.233	30	2026-08-16 02:47:54.563781+00
APT/USD	1m	1786848420	0.5344	0.5344	0.5344	0.5344	30	2026-08-16 02:47:54.563781+00
BTC/USD	1m	1786848420	63172.75	63172.75	63172.75	63172.75	30	2026-08-16 02:47:54.563781+00
LINK/USD	1m	1786848420	9.482	9.482	9.482	9.482	30	2026-08-16 02:47:54.563781+00
SUI/USD	1m	1786848420	0.676	0.676	0.676	0.676	30	2026-08-16 02:47:54.563781+00
LINK/USD	1m	1786848480	9.482	9.482	9.482	9.482	30	2026-08-16 02:48:54.560911+00
ADA/USD	1m	1786848480	0.177	0.177	0.177	0.177	30	2026-08-16 02:48:54.560911+00
ETH/USD	1m	1786848480	1884.66	1884.66	1884.66	1884.66	30	2026-08-16 02:48:54.560911+00
XRP/USD	1m	1786848480	1.00089	1.00089	1.00089	1.00089	30	2026-08-16 02:48:54.560911+00
NEAR/USD	1m	1786848480	1.612	1.612	1.612	1.612	30	2026-08-16 02:48:54.560911+00
AAVE/USD	1m	1786848480	86.23	86.23	86.23	86.23	30	2026-08-16 02:48:54.560911+00
APT/USD	1m	1786848480	0.5344	0.5344	0.5344	0.5344	30	2026-08-16 02:48:54.560911+00
SUI/USD	1m	1786848480	0.676	0.676	0.676	0.676	30	2026-08-16 02:48:54.560911+00
SOL/USD	1m	1786848480	75.562	75.562	75.562	75.562	30	2026-08-16 02:48:54.560911+00
POL/USD	1m	1786848480	0.075	0.075	0.075	0.075	30	2026-08-16 02:48:54.560911+00
DOGE/USD	1m	1786848480	0.0696705	0.0696705	0.0696705	0.0696705	30	2026-08-16 02:48:54.560911+00
AVAX/USD	1m	1786848480	6.34	6.34	6.34	6.34	30	2026-08-16 02:48:54.560911+00
BTC/USD	1m	1786848480	63172.75	63172.75	63172.75	63172.75	30	2026-08-16 02:48:54.560911+00
DOT/USD	1m	1786848480	0.757	0.757	0.757	0.757	30	2026-08-16 02:48:54.560911+00
XLM/USD	1m	1786848480	0.15656	0.15656	0.15656	0.15656	30	2026-08-16 02:48:54.560911+00
UNI/USD	1m	1786848480	3.233	3.233	3.233	3.233	30	2026-08-16 02:48:54.560911+00
LTC/USD	1m	1786848480	44.29	44.29	44.29	44.29	30	2026-08-16 02:48:54.560911+00
APT/USD	1m	1786848540	0.5344	0.5344	0.5344	0.5344	23	2026-08-16 02:49:59.462877+00
APT/USD	5m	1786848300	0.5344	0.5344	0.5344	0.5344	143	2026-08-16 02:49:59.462877+00
SUI/USD	1m	1786848540	0.676	0.676	0.676	0.676	23	2026-08-16 02:49:59.462877+00
SUI/USD	5m	1786848300	0.676	0.676	0.676	0.676	143	2026-08-16 02:49:59.462877+00
NEAR/USD	1m	1786848540	1.612	1.612	1.612	1.612	23	2026-08-16 02:49:59.462877+00
NEAR/USD	5m	1786848300	1.612	1.612	1.612	1.612	143	2026-08-16 02:49:59.462877+00
BTC/USD	1m	1786848540	63172.75	63172.75	63172.75	63172.75	23	2026-08-16 02:49:59.462877+00
BTC/USD	5m	1786848300	63172.75	63172.75	63172.75	63172.75	143	2026-08-16 02:49:59.462877+00
SOL/USD	1m	1786848540	75.562	75.562	75.562	75.562	23	2026-08-16 02:49:59.462877+00
SOL/USD	5m	1786848300	75.562	75.562	75.562	75.562	143	2026-08-16 02:49:59.462877+00
AAVE/USD	1m	1786848540	86.23	86.23	86.23	86.23	23	2026-08-16 02:49:59.462877+00
AAVE/USD	5m	1786848300	86.23	86.23	86.23	86.23	143	2026-08-16 02:49:59.462877+00
POL/USD	1m	1786848540	0.075	0.075	0.075	0.075	23	2026-08-16 02:49:59.462877+00
POL/USD	5m	1786848300	0.075	0.075	0.075	0.075	143	2026-08-16 02:49:59.462877+00
UNI/USD	1m	1786848540	3.233	3.233	3.233	3.233	23	2026-08-16 02:49:59.462877+00
UNI/USD	5m	1786848300	3.233	3.233	3.233	3.233	143	2026-08-16 02:49:59.462877+00
XRP/USD	1m	1786848540	1.00089	1.00089	1.00089	1.00089	23	2026-08-16 02:49:59.462877+00
XRP/USD	5m	1786848300	1.00089	1.00089	1.00089	1.00089	143	2026-08-16 02:49:59.462877+00
XLM/USD	1m	1786848540	0.15656	0.15656	0.15656	0.15656	23	2026-08-16 02:49:59.462877+00
XLM/USD	5m	1786848300	0.15656	0.15656	0.15656	0.15656	143	2026-08-16 02:49:59.462877+00
ADA/USD	1m	1786848540	0.177	0.177	0.177	0.177	23	2026-08-16 02:49:59.462877+00
ADA/USD	5m	1786848300	0.177	0.177	0.177	0.177	143	2026-08-16 02:49:59.462877+00
DOGE/USD	1m	1786848540	0.0696705	0.0696705	0.0696705	0.0696705	23	2026-08-16 02:49:59.462877+00
DOGE/USD	5m	1786848300	0.0696705	0.0696705	0.0696705	0.0696705	143	2026-08-16 02:49:59.462877+00
LINK/USD	1m	1786848540	9.482	9.482	9.482	9.482	23	2026-08-16 02:49:59.462877+00
LINK/USD	5m	1786848300	9.482	9.482	9.482	9.482	143	2026-08-16 02:49:59.462877+00
LTC/USD	1m	1786848540	44.29	44.29	44.29	44.29	23	2026-08-16 02:49:59.462877+00
LTC/USD	5m	1786848300	44.29	44.29	44.29	44.29	143	2026-08-16 02:49:59.462877+00
AVAX/USD	1m	1786848540	6.34	6.34	6.34	6.34	23	2026-08-16 02:49:59.462877+00
AVAX/USD	5m	1786848300	6.34	6.34	6.34	6.34	143	2026-08-16 02:49:59.462877+00
ETH/USD	1m	1786848540	1884.66	1884.66	1882.37	1882.37	23	2026-08-16 02:49:59.462877+00
ETH/USD	5m	1786848300	1884.66	1884.66	1882.37	1882.37	143	2026-08-16 02:49:59.462877+00
DOT/USD	1m	1786848540	0.757	0.757	0.757	0.757	23	2026-08-16 02:49:59.462877+00
DOT/USD	5m	1786848300	0.757	0.757	0.757	0.757	143	2026-08-16 02:49:59.462877+00
BTC/USD	1m	1786848600	63172.75	63172.75	63172.75	63172.75	30	2026-08-16 02:50:59.459121+00
UNI/USD	1m	1786848600	3.233	3.233	3.233	3.233	30	2026-08-16 02:50:59.459121+00
APT/USD	1m	1786848600	0.5344	0.5344	0.5344	0.5344	30	2026-08-16 02:50:59.459121+00
ETH/USD	1m	1786848600	1882.37	1882.37	1882.37	1882.37	30	2026-08-16 02:50:59.459121+00
DOGE/USD	1m	1786848600	0.0696705	0.0696705	0.0696705	0.0696705	30	2026-08-16 02:50:59.459121+00
DOT/USD	1m	1786848600	0.757	0.757	0.757	0.757	30	2026-08-16 02:50:59.459121+00
XRP/USD	1m	1786848600	1.00089	1.00089	1.00089	1.00089	30	2026-08-16 02:50:59.459121+00
POL/USD	1m	1786848600	0.075	0.075	0.075	0.075	30	2026-08-16 02:50:59.459121+00
AAVE/USD	1m	1786848600	86.23	86.23	86.23	86.23	30	2026-08-16 02:50:59.459121+00
SUI/USD	1m	1786848600	0.676	0.676	0.676	0.676	30	2026-08-16 02:50:59.459121+00
AVAX/USD	1m	1786848600	6.34	6.34	6.34	6.34	30	2026-08-16 02:50:59.459121+00
SOL/USD	1m	1786848600	75.562	75.562	75.562	75.562	30	2026-08-16 02:50:59.459121+00
XLM/USD	1m	1786848600	0.15656	0.15656	0.15656	0.15656	30	2026-08-16 02:50:59.459121+00
NEAR/USD	1m	1786848600	1.612	1.612	1.612	1.612	30	2026-08-16 02:50:59.459121+00
LINK/USD	1m	1786848600	9.482	9.482	9.482	9.482	30	2026-08-16 02:50:59.459121+00
LTC/USD	1m	1786848600	44.29	44.29	44.29	44.29	30	2026-08-16 02:50:59.459121+00
ADA/USD	1m	1786848600	0.177	0.177	0.177	0.177	30	2026-08-16 02:50:59.459121+00
XRP/USD	1m	1786848660	1.00089	1.00089	1.00089	1.00089	25	2026-08-16 02:52:01.075382+00
SUI/USD	1m	1786848660	0.676	0.676	0.676	0.676	25	2026-08-16 02:52:01.075382+00
APT/USD	1m	1786848660	0.5344	0.5344	0.5344	0.5344	25	2026-08-16 02:52:01.075382+00
AVAX/USD	1m	1786848660	6.34	6.34	6.34	6.34	25	2026-08-16 02:52:01.075382+00
NEAR/USD	1m	1786848660	1.612	1.612	1.612	1.612	25	2026-08-16 02:52:01.075382+00
BTC/USD	1m	1786848660	63172.75	63172.75	63172.75	63172.75	25	2026-08-16 02:52:01.075382+00
DOGE/USD	1m	1786848660	0.0696705	0.0696705	0.0696705	0.0696705	25	2026-08-16 02:52:01.075382+00
LINK/USD	1m	1786848660	9.482	9.482	9.482	9.482	25	2026-08-16 02:52:01.075382+00
UNI/USD	1m	1786848660	3.233	3.233	3.233	3.233	25	2026-08-16 02:52:01.075382+00
AAVE/USD	1m	1786848660	86.23	86.23	86.23	86.23	25	2026-08-16 02:52:01.075382+00
ETH/USD	1m	1786848660	1882.37	1882.37	1882.37	1882.37	25	2026-08-16 02:52:01.075382+00
XLM/USD	1m	1786848660	0.15656	0.15656	0.15656	0.15656	25	2026-08-16 02:52:01.075382+00
DOT/USD	1m	1786848660	0.757	0.757	0.757	0.757	25	2026-08-16 02:52:01.075382+00
ADA/USD	1m	1786848660	0.177	0.177	0.177	0.177	25	2026-08-16 02:52:01.075382+00
SOL/USD	1m	1786848660	75.562	75.562	75.562	75.562	25	2026-08-16 02:52:01.075382+00
LTC/USD	1m	1786848660	44.29	44.29	44.29	44.29	25	2026-08-16 02:52:01.075382+00
POL/USD	1m	1786848660	0.075	0.075	0.075	0.075	25	2026-08-16 02:52:01.075382+00
AVAX/USD	1m	1786848720	6.34	6.34	6.34	6.34	29	2026-08-16 02:52:56.071523+00
DOGE/USD	1m	1786848720	0.0696705	0.0696705	0.0696705	0.0696705	29	2026-08-16 02:52:56.071523+00
POL/USD	1m	1786848720	0.075	0.0753	0.075	0.0753	29	2026-08-16 02:52:56.071523+00
ADA/USD	1m	1786848720	0.177	0.177	0.177	0.177	29	2026-08-16 02:52:56.071523+00
XLM/USD	1m	1786848720	0.15656	0.15656	0.15656	0.15656	29	2026-08-16 02:52:56.071523+00
NEAR/USD	1m	1786848720	1.612	1.612	1.612	1.612	29	2026-08-16 02:52:56.071523+00
LTC/USD	1m	1786848720	44.29	44.29	44.29	44.29	29	2026-08-16 02:52:56.071523+00
UNI/USD	1m	1786848720	3.233	3.233	3.233	3.233	29	2026-08-16 02:52:56.071523+00
LINK/USD	1m	1786848720	9.482	9.482	9.482	9.482	29	2026-08-16 02:52:56.071523+00
APT/USD	1m	1786848720	0.5344	0.5344	0.5344	0.5344	29	2026-08-16 02:52:56.071523+00
AAVE/USD	1m	1786848720	86.23	86.23	86.23	86.23	29	2026-08-16 02:52:56.071523+00
BTC/USD	1m	1786848720	63172.75	63172.75	63172.75	63172.75	29	2026-08-16 02:52:56.071523+00
ETH/USD	1m	1786848720	1882.37	1882.37	1882.37	1882.37	29	2026-08-16 02:52:56.071523+00
DOT/USD	1m	1786848720	0.757	0.757	0.757	0.757	29	2026-08-16 02:52:56.071523+00
XRP/USD	1m	1786848720	1.00089	1.00089	1.00089	1.00089	29	2026-08-16 02:52:56.071523+00
SOL/USD	1m	1786848720	75.562	75.562	75.562	75.562	29	2026-08-16 02:52:56.071523+00
SUI/USD	1m	1786848720	0.676	0.676	0.676	0.676	29	2026-08-16 02:52:56.071523+00
NEAR/USD	1m	1786848780	1.612	1.612	1.612	1.612	30	2026-08-16 02:53:56.068444+00
SOL/USD	1m	1786848780	75.562	75.562	75.562	75.562	30	2026-08-16 02:53:56.068444+00
UNI/USD	1m	1786848780	3.233	3.233	3.233	3.233	30	2026-08-16 02:53:56.068444+00
XRP/USD	1m	1786848780	1.00089	1.00089	1.00089	1.00089	30	2026-08-16 02:53:56.068444+00
ADA/USD	1m	1786848780	0.177	0.177	0.177	0.177	30	2026-08-16 02:53:56.068444+00
ETH/USD	1m	1786848780	1882.37	1882.37	1882.37	1882.37	30	2026-08-16 02:53:56.068444+00
SUI/USD	1m	1786848780	0.676	0.676	0.676	0.676	30	2026-08-16 02:53:56.068444+00
APT/USD	1m	1786848780	0.5344	0.5344	0.5344	0.5344	30	2026-08-16 02:53:56.068444+00
XLM/USD	1m	1786848780	0.15656	0.15656	0.15656	0.15656	30	2026-08-16 02:53:56.068444+00
POL/USD	1m	1786848780	0.0753	0.0753	0.0753	0.0753	30	2026-08-16 02:53:56.068444+00
AVAX/USD	1m	1786848780	6.34	6.34	6.34	6.34	30	2026-08-16 02:53:56.068444+00
AAVE/USD	1m	1786848780	86.23	86.23	86.23	86.23	30	2026-08-16 02:53:56.068444+00
LINK/USD	1m	1786848780	9.482	9.482	9.482	9.482	30	2026-08-16 02:53:56.068444+00
BTC/USD	1m	1786848780	63172.75	63172.75	63172.75	63172.75	30	2026-08-16 02:53:56.068444+00
DOT/USD	1m	1786848780	0.757	0.757	0.757	0.757	30	2026-08-16 02:53:56.068444+00
DOGE/USD	1m	1786848780	0.0696705	0.0696705	0.0696705	0.0696705	30	2026-08-16 02:53:56.068444+00
LTC/USD	1m	1786848780	44.29	44.29	44.29	44.29	30	2026-08-16 02:53:56.068444+00
XLM/USD	1m	1786848840	0.15656	0.15656	0.15656	0.15656	30	2026-08-16 02:54:56.06624+00
XLM/USD	5m	1786848600	0.15656	0.15656	0.15656	0.15656	144	2026-08-16 02:54:56.06624+00
LINK/USD	1m	1786848840	9.482	9.482	9.482	9.482	30	2026-08-16 02:54:56.06624+00
LINK/USD	5m	1786848600	9.482	9.482	9.482	9.482	144	2026-08-16 02:54:56.06624+00
AAVE/USD	1m	1786848840	86.23	86.23	86.23	86.23	30	2026-08-16 02:54:56.06624+00
AAVE/USD	5m	1786848600	86.23	86.23	86.23	86.23	144	2026-08-16 02:54:56.06624+00
XRP/USD	1m	1786848840	1.00089	1.00089	1.00089	1.00089	30	2026-08-16 02:54:56.06624+00
XRP/USD	5m	1786848600	1.00089	1.00089	1.00089	1.00089	144	2026-08-16 02:54:56.06624+00
APT/USD	1m	1786848840	0.5344	0.5344	0.5344	0.5344	30	2026-08-16 02:54:56.06624+00
APT/USD	5m	1786848600	0.5344	0.5344	0.5344	0.5344	144	2026-08-16 02:54:56.06624+00
AVAX/USD	1m	1786848840	6.34	6.34	6.34	6.34	30	2026-08-16 02:54:56.06624+00
AVAX/USD	5m	1786848600	6.34	6.34	6.34	6.34	144	2026-08-16 02:54:56.06624+00
SUI/USD	1m	1786848840	0.676	0.676	0.676	0.676	30	2026-08-16 02:54:56.06624+00
SUI/USD	5m	1786848600	0.676	0.676	0.676	0.676	144	2026-08-16 02:54:56.06624+00
UNI/USD	1m	1786848840	3.233	3.233	3.233	3.233	30	2026-08-16 02:54:56.06624+00
UNI/USD	5m	1786848600	3.233	3.233	3.233	3.233	144	2026-08-16 02:54:56.06624+00
SOL/USD	1m	1786848840	75.562	75.562	75.562	75.562	30	2026-08-16 02:54:56.06624+00
SOL/USD	5m	1786848600	75.562	75.562	75.562	75.562	144	2026-08-16 02:54:56.06624+00
DOGE/USD	1m	1786848840	0.0696705	0.0696705	0.0696705	0.0696705	30	2026-08-16 02:54:56.06624+00
DOGE/USD	5m	1786848600	0.0696705	0.0696705	0.0696705	0.0696705	144	2026-08-16 02:54:56.06624+00
LTC/USD	1m	1786848840	44.29	44.29	44.29	44.29	30	2026-08-16 02:54:56.06624+00
LTC/USD	5m	1786848600	44.29	44.29	44.29	44.29	144	2026-08-16 02:54:56.06624+00
NEAR/USD	1m	1786848840	1.612	1.612	1.612	1.612	30	2026-08-16 02:54:56.06624+00
NEAR/USD	5m	1786848600	1.612	1.612	1.612	1.612	144	2026-08-16 02:54:56.06624+00
ETH/USD	1m	1786848840	1882.37	1882.37	1882.37	1882.37	30	2026-08-16 02:54:56.06624+00
ETH/USD	5m	1786848600	1882.37	1882.37	1882.37	1882.37	144	2026-08-16 02:54:56.06624+00
POL/USD	1m	1786848840	0.0753	0.0753	0.0753	0.0753	30	2026-08-16 02:54:56.06624+00
POL/USD	5m	1786848600	0.075	0.0753	0.075	0.0753	144	2026-08-16 02:54:56.06624+00
BTC/USD	1m	1786848840	63172.75	63172.75	63172.75	63172.75	30	2026-08-16 02:54:56.06624+00
BTC/USD	5m	1786848600	63172.75	63172.75	63172.75	63172.75	144	2026-08-16 02:54:56.06624+00
DOT/USD	1m	1786848840	0.757	0.757	0.757	0.757	30	2026-08-16 02:54:56.06624+00
DOT/USD	5m	1786848600	0.757	0.757	0.757	0.757	144	2026-08-16 02:54:56.06624+00
ADA/USD	1m	1786848840	0.177	0.177	0.177	0.177	30	2026-08-16 02:54:56.06624+00
ADA/USD	5m	1786848600	0.177	0.177	0.177	0.177	144	2026-08-16 02:54:56.06624+00
UNI/USD	1m	1786848900	3.233	3.233	3.233	3.233	30	2026-08-16 02:55:56.062398+00
XLM/USD	1m	1786848900	0.15656	0.15656	0.15656	0.15656	30	2026-08-16 02:55:56.062398+00
SUI/USD	1m	1786848900	0.676	0.676	0.676	0.676	30	2026-08-16 02:55:56.062398+00
LINK/USD	1m	1786848900	9.482	9.482	9.482	9.482	30	2026-08-16 02:55:56.062398+00
XRP/USD	1m	1786848900	1.00089	1.00089	1.00089	1.00089	30	2026-08-16 02:55:56.062398+00
ETH/USD	1m	1786848900	1882.37	1882.37	1882.37	1882.37	30	2026-08-16 02:55:56.062398+00
SOL/USD	1m	1786848900	75.562	75.562	75.562	75.562	30	2026-08-16 02:55:56.062398+00
AAVE/USD	1m	1786848900	86.23	86.23	86.23	86.23	30	2026-08-16 02:55:56.062398+00
BTC/USD	1m	1786848900	63172.75	63172.75	63172.75	63172.75	30	2026-08-16 02:55:56.062398+00
DOT/USD	1m	1786848900	0.757	0.757	0.757	0.757	30	2026-08-16 02:55:56.062398+00
DOGE/USD	1m	1786848900	0.0696705	0.0696705	0.0696705	0.0696705	30	2026-08-16 02:55:56.062398+00
NEAR/USD	1m	1786848900	1.612	1.612	1.612	1.612	30	2026-08-16 02:55:56.062398+00
ADA/USD	1m	1786848900	0.177	0.177	0.177	0.177	30	2026-08-16 02:55:56.062398+00
LTC/USD	1m	1786848900	44.29	44.29	44.29	44.29	30	2026-08-16 02:55:56.062398+00
APT/USD	1m	1786848900	0.5344	0.5344	0.5344	0.5344	30	2026-08-16 02:55:56.062398+00
AVAX/USD	1m	1786848900	6.34	6.34	6.34	6.34	30	2026-08-16 02:55:56.062398+00
POL/USD	1m	1786848900	0.0753	0.0753	0.0753	0.0753	30	2026-08-16 02:55:56.062398+00
\.


--
-- Data for Name: chart_drawings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.chart_drawings (user_id, contest_id, symbol, drawings, updated_at) FROM stdin;
\.


--
-- Data for Name: contest_duration_configs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contest_duration_configs (duration_type, duration_minutes, default_qty_total, min_entry_fee_cents, max_entry_fee_cents, display_name_en, display_name_fa, created_at, updated_at) FROM stdin;
rush_30min	30	50000	100	1000	30-Min Rush	رقابت ۳۰ دقیقه‌ای	2026-08-15 20:31:58.22328+00	2026-08-15 20:31:58.22328+00
hourly	60	100000	200	2000	Hourly	ساعتی	2026-08-15 20:31:58.22328+00	2026-08-15 20:31:58.22328+00
four_hour	240	200000	500	5000	4-Hour	چهار ساعته	2026-08-15 20:31:58.22328+00	2026-08-15 20:31:58.22328+00
daily	1440	500000	1000	10000	Daily	روزانه	2026-08-15 20:31:58.22328+00	2026-08-15 20:31:58.22328+00
weekly	10080	1000000	2000	50000	Weekly	هفتگی	2026-08-15 20:31:58.22328+00	2026-08-15 20:31:58.22328+00
\.


--
-- Data for Name: contest_finalization_state; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contest_finalization_state (contest_id, finalization_started_at, payouts_calculated, payouts_calculated_at, ranks_written, ranks_written_at, wallets_credited, wallets_credited_at, status_updated, status_updated_at, finalization_completed_at, error_message, last_error_at, retry_count, metadata, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: contest_participants; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contest_participants (contest_id, user_id, joined_at, qty_total, qty_available, total_score, final_rank, final_prize_cents, is_system) FROM stdin;
c864b259-2c96-4b65-8864-b2592c96cb65	c864b259-2c96-4b65-8864-b2592c96cb65	2026-08-16 00:34:27.217954+00	10	10	2000.00000000	\N	\N	f
68b45a2d-96cb-45f2-a8b4-5a2d96cbe5f2	68b45a2d-96cb-45f2-a8b4-5a2d96cbe5f2	2026-08-16 01:54:27.476379+00	10	10	2000.00000000	\N	\N	f
90c864b2-592c-464b-90c8-64b2592c964b	90c864b2-592c-464b-90c8-64b2592c964b	2026-08-16 00:34:56.125502+00	10	10	2000.00000000	\N	\N	f
9d147ba4-3d0a-492e-b867-19a222c7afbc	7d16b1c9-fa10-4721-9ab1-f9c6dfd7f7c0	2026-08-16 01:05:27.731891+00	100000	100000	0.00000000	\N	\N	f
9d147ba4-3d0a-492e-b867-19a222c7afbc	73724a7a-cc59-4aeb-86b5-bc997598c1ec	2026-08-16 01:05:27.744762+00	100000	100000	0.00000000	\N	\N	f
7c77ff2b-bc98-46cc-aa96-95b6e9eb3070	912bce1a-5da1-473c-b7cf-832f0ff39bb4	2026-08-16 01:05:44.46615+00	100000	100000	0.00000000	\N	\N	f
7c77ff2b-bc98-46cc-aa96-95b6e9eb3070	3a6ad88d-a188-4bf0-be1d-bf2706cdbe2a	2026-08-16 01:05:44.453187+00	100000	99000	0.00000000	\N	\N	f
9ea30eb8-6065-4457-96ba-52ac5334e0ee	5d597832-fd0c-4be5-b1bb-ed1f03c10399	2026-08-16 01:06:51.320469+00	100000	100000	0.00000000	\N	\N	f
9ea30eb8-6065-4457-96ba-52ac5334e0ee	863bc837-1fa3-4374-91df-3fe92a7a8694	2026-08-16 01:06:51.308133+00	100000	99000	0.00000000	\N	\N	f
1088c4e2-7138-4c4e-9088-c4e271389c4e	1088c4e2-7138-4c4e-9088-c4e271389c4e	2026-08-16 01:26:55.580638+00	10	10	2000.00000000	\N	\N	f
0da7c9af-faf3-4477-8843-69936d6a47fb	81741f96-07b2-4e40-801d-470e79ffac94	2026-08-16 01:06:51.444334+00	100000	99000	0.00000000	\N	\N	f
734d42df-4077-471f-9f96-2b4143ab43df	8ff79fc3-3043-4a7c-a959-4f2ba6e5e265	2026-08-16 01:06:51.61869+00	100000	100000	0.00000000	\N	\N	f
4263505f-6b0f-49d7-9c49-5f1008a557ea	bf942846-2dc6-41a2-afb0-35efd5403110	2026-08-16 01:07:18.596+00	100000	100000	0.00000000	\N	\N	f
4263505f-6b0f-49d7-9c49-5f1008a557ea	15e34f4d-da6c-4d3f-83c8-17bd2ddb4226	2026-08-16 01:07:18.580931+00	100000	99000	0.00000000	\N	\N	f
ae1aa700-2f09-497d-877c-15679fdec5f5	4af61bbb-6031-4996-9c0f-f27b00b90fb8	2026-08-16 01:07:18.709801+00	100000	99000	0.00000000	\N	\N	f
daf27c0c-5e6d-411e-ae0d-1df1120ffdf3	d9da59d4-8084-49bd-ae23-cb99bb061a10	2026-08-16 01:07:18.862138+00	100000	100000	0.00000000	\N	\N	f
40a0d068-341a-4d86-80a0-d068341a0d86	40a0d068-341a-4d86-80a0-d068341a0d86	2026-08-16 01:54:58.381906+00	10	10	2000.00000000	\N	\N	f
1c0e8743-2190-48e4-9c0e-87432190c8e4	1c0e8743-2190-48e4-9c0e-87432190c8e4	2026-08-16 01:07:20.351307+00	10	10	2000.00000000	\N	\N	f
8f7ba104-b9d7-47e5-b624-199c1bc385c2	96329156-5841-49fb-81a3-2312b7525188	2026-08-16 01:08:00.144143+00	100000	100000	0.00000000	\N	\N	f
8f7ba104-b9d7-47e5-b624-199c1bc385c2	7dc77ed4-d996-4eeb-a881-1f208a54c12f	2026-08-16 01:08:00.132618+00	100000	99000	0.00000000	\N	\N	f
b96d7bd9-99e5-402e-bc3f-645a7251acbf	43efcc9b-7d09-41c4-a72c-5235ca0b3307	2026-08-16 01:08:00.266634+00	100000	99000	0.00000000	\N	\N	f
5db97139-a45c-4de8-9c5c-02f65ae18683	5c74f65f-c1f0-496a-9ad8-6a33bda83d30	2026-08-16 01:08:00.430784+00	100000	100000	0.00000000	\N	\N	f
1cfa0925-3e82-4e33-a8a7-08897bff8995	f97bf032-eeaa-483a-badb-00e6d886c526	2026-08-16 01:25:58.706497+00	100000	100000	0.00000000	\N	\N	f
1cfa0925-3e82-4e33-a8a7-08897bff8995	ab70e441-0b8e-4ed0-9762-13a8ac5e7c7d	2026-08-16 01:25:58.693526+00	100000	99000	0.00000000	\N	\N	f
7ed8ef63-9fe8-450b-b6f4-ba33e7a3cef8	9e60eafe-d7b5-4ba8-9622-8a7e881717d2	2026-08-16 01:27:11.250735+00	100000	99000	0.00000000	\N	\N	f
a9e9ee08-e9c7-4796-b17c-8251365602b4	2625aa74-47bf-4793-a803-29bb9e477aed	2026-08-16 01:25:58.832168+00	100000	99000	0.00000000	\N	\N	f
213e9258-cb82-4f26-9db2-b7d57f8bd0f8	e36a81e6-3639-4a93-b9c3-2f841d04211b	2026-08-16 01:25:58.983902+00	100000	100000	0.00000000	\N	\N	f
c8e4f279-3c1e-4f87-88e4-f2793c1e0f87	c8e4f279-3c1e-4f87-88e4-f2793c1e0f87	2026-08-16 02:00:06.259334+00	10	10	2000.00000000	\N	\N	f
60b0d86c-369b-4da6-a0b0-d86c369b4da6	60b0d86c-369b-4da6-a0b0-d86c369b4da6	2026-08-16 01:26:01.964182+00	10	10	2000.00000000	\N	\N	f
3098cc66-b359-4c56-b098-cc66b359ac56	3098cc66-b359-4c56-b098-cc66b359ac56	2026-08-16 02:27:08.331249+00	10	10	2000.00000000	\N	\N	f
7ee13a8f-4022-43c6-a084-fbe10763ac10	452e07e0-e8eb-4f0f-98f2-f8875cd88831	2026-08-16 02:27:10.417339+00	100000	100000	0.00000000	\N	\N	f
08048241-a050-48d4-8804-8241a050a8d4	08048241-a050-48d4-8804-8241a050a8d4	2026-08-16 01:26:30.053253+00	10	10	2000.00000000	\N	\N	f
2f80ce1a-329d-4e78-bc49-fe62ede53b7f	c3a16226-aa66-4239-9f5b-228e8eb92f5b	2026-08-16 01:26:54.061297+00	100000	100000	0.00000000	\N	\N	f
2f80ce1a-329d-4e78-bc49-fe62ede53b7f	4f4153e9-0d17-4a1e-92ef-ce9e7958beb2	2026-08-16 01:26:54.049392+00	100000	99000	0.00000000	\N	\N	f
377995fd-6611-49f1-a4f8-99d9fb83e856	f6e59b39-9e32-439a-879f-6b7683774265	2026-08-16 01:27:11.414103+00	100000	100000	0.00000000	\N	\N	f
45e3a795-edf5-4541-b89e-51cf2c71da49	eb0cfe73-a65e-405a-8e76-0717293c8143	2026-08-16 01:26:54.173698+00	100000	99000	0.00000000	\N	\N	f
7ee13a8f-4022-43c6-a084-fbe10763ac10	2669d7fa-c10f-4128-9395-ada433d4631e	2026-08-16 02:27:10.402903+00	100000	99000	0.00000000	\N	\N	f
1883b591-7d1a-4f42-9325-9507c69f7df8	653652cd-820e-4692-a7bb-1bb90a20936a	2026-08-16 02:27:10.547512+00	100000	99000	0.00000000	\N	\N	f
3c9e4fa7-d3e9-44ba-bc9e-4fa7d3e974ba	3c9e4fa7-d3e9-44ba-bc9e-4fa7d3e974ba	2026-08-16 02:43:00.2092+00	10	10	2000.00000000	\N	\N	f
e0f0783c-9e4f-47d3-a0f0-783c9e4fa7d3	e0f0783c-9e4f-47d3-a0f0-783c9e4fa7d3	2026-08-16 01:27:13.545208+00	10	10	2000.00000000	\N	\N	f
44bfb9c9-0453-4707-ad78-b1f69903b962	e8a771e3-92db-4a30-9bb0-c4b84125187f	2026-08-16 02:43:02.735804+00	100000	100000	0.00000000	\N	\N	f
44bfb9c9-0453-4707-ad78-b1f69903b962	c9e259ce-38b0-4b00-a3a3-9b5771d9b6de	2026-08-16 02:43:02.724037+00	100000	99000	0.00000000	\N	\N	f
e88ecf13-0a84-4631-a816-aec1d3405c03	f6491f08-63d2-476f-873f-db5cf69c0122	2026-08-16 02:44:05.833016+00	100000	99000	0.00000000	\N	\N	f
1b87adda-e572-4a9e-9243-8c861bfcb234	d8bacc11-7441-48e2-9f65-7d387dd9ea26	2026-08-16 02:43:02.840554+00	100000	99000	0.00000000	\N	\N	f
40a0d0e8-f4fa-4dfe-80a0-d0e8f4fafdfe	40a0d0e8-f4fa-4dfe-80a0-d0e8f4fafdfe	2026-08-16 01:27:16.201145+00	10	10	2000.00000000	\N	\N	f
6cb6dbed-76bb-4d2e-acb6-dbed76bb5d2e	6cb6dbed-76bb-4d2e-acb6-dbed76bb5d2e	2026-08-16 01:29:16.042356+00	10	10	2000.00000000	\N	\N	f
241289c4-6231-48cc-a412-89c4623198cc	241289c4-6231-48cc-a412-89c4623198cc	2026-08-16 02:44:00.171901+00	10	10	2000.00000000	\N	\N	f
c4c0f294-68d1-4e7b-af65-0a2410c03088	d00ce5cc-0dc6-4078-935c-2a75b2349ba2	2026-08-16 02:44:02.015362+00	100000	100000	0.00000000	\N	\N	f
c4c0f294-68d1-4e7b-af65-0a2410c03088	76ada4f6-10d5-4219-a405-f8d5e5b32b78	2026-08-16 02:44:02.002579+00	100000	99000	0.00000000	\N	\N	f
3c9e4f27-1309-4402-bc9e-4f2713090402	3c9e4f27-1309-4402-bc9e-4f2713090402	2026-08-16 01:29:20.399879+00	10	10	2000.00000000	\N	\N	f
a90814e3-b698-406b-b1c7-350edfb7109a	540d0a22-62a4-45f1-a0ab-2f2092014abb	2026-08-16 01:29:20.716252+00	100000	100000	0.00000000	\N	\N	f
a90814e3-b698-406b-b1c7-350edfb7109a	792c3ecb-0a51-4b66-b78f-411903e74aa3	2026-08-16 01:29:20.702336+00	100000	99000	0.00000000	\N	\N	f
0acab9a9-ee24-4ff4-8587-fe642f0c3320	ffb61316-7d0b-4e05-a80f-d634f1b9391d	2026-08-16 01:29:20.914369+00	100000	99000	0.00000000	\N	\N	f
a4da580b-6aa3-4a5e-b7ef-79468cf4cf1b	633e7e4b-d5a2-41c7-9a17-af7e54fd4c6c	2026-08-16 01:29:21.118704+00	100000	100000	0.00000000	\N	\N	f
251dba09-bdf8-4e44-9d96-ab9f984dd99d	0499cba2-41b1-4fd3-b4f7-07d7e77bd094	2026-08-16 02:44:02.129779+00	100000	99000	0.00000000	\N	\N	f
e88ecf13-0a84-4631-a816-aec1d3405c03	302640fe-27ce-4abe-b59a-5ec4dc69944c	2026-08-16 02:44:05.850045+00	100000	100000	0.00000000	\N	\N	f
a452a954-aa55-4a55-a452-a954aa55aa55	a452a954-aa55-4a55-a452-a954aa55aa55	2026-08-16 01:54:02.00923+00	10	10	2000.00000000	\N	\N	f
984c2613-89c4-42f1-984c-261389c4e2f1	984c2613-89c4-42f1-984c-261389c4e2f1	2026-08-16 02:44:06.957941+00	10	10	2000.00000000	\N	\N	f
74ba5dae-d7eb-453a-b4ba-5daed7eb753a	74ba5dae-d7eb-453a-b4ba-5daed7eb753a	2026-08-16 01:54:04.779897+00	10	10	2000.00000000	\N	\N	f
f78b4135-f060-4447-a994-080db7058160	b479eb08-1b65-411d-964c-028ed616a70d	2026-08-16 02:44:08.578885+00	100000	100000	0.00000000	\N	\N	f
f78b4135-f060-4447-a994-080db7058160	218b00a6-dd31-4954-8850-989f8454cb72	2026-08-16 02:44:08.565654+00	100000	99000	0.00000000	\N	\N	f
694d8dc8-1ae8-4377-aa82-3e811b7fdb90	646173e1-c3cb-42b3-8252-1f9a45adf2d5	2026-08-16 02:44:11.089713+00	100000	100000	0.00000000	\N	\N	f
694d8dc8-1ae8-4377-aa82-3e811b7fdb90	c66062f8-5699-49a8-a1bb-05a591ab9f22	2026-08-16 02:44:11.078145+00	100000	99000	0.00000000	\N	\N	f
582c160b-8542-4150-982c-160b8542a150	582c160b-8542-4150-982c-160b8542a150	2026-08-16 02:44:36.048969+00	10	10	2000.00000000	\N	\N	f
b85c2e97-4b25-4209-b85c-2e974b251209	b85c2e97-4b25-4209-b85c-2e974b251209	2026-08-16 02:44:37.148143+00	10	10	2000.00000000	\N	\N	f
80402090-48a4-4269-8040-209048a4d269	80402090-48a4-4269-8040-209048a4d269	2026-08-16 02:44:38.414932+00	10	10	2000.00000000	\N	\N	f
b8dc6e37-9bcd-4633-b8dc-6e379bcd6633	b8dc6e37-9bcd-4633-b8dc-6e379bcd6633	2026-08-16 02:44:55.627817+00	10	10	2000.00000000	\N	\N	f
743a1d0e-0783-41e0-b43a-1d0e0783c1e0	743a1d0e-0783-41e0-b43a-1d0e0783c1e0	2026-08-16 02:45:57.310998+00	10	10	2000.00000000	\N	\N	f
c71ff9b5-d220-42f2-9f5f-053fcc08e9b4	426be798-f942-40a8-8609-cd231f5ebb08	2026-08-16 02:45:59.09986+00	100000	100000	0.00000000	\N	\N	f
c71ff9b5-d220-42f2-9f5f-053fcc08e9b4	0d4fd196-fc76-49cf-a78c-ce25c8a03022	2026-08-16 02:45:59.088035+00	100000	99000	0.00000000	\N	\N	f
0cd34720-b787-4e6f-acae-2c5df8a43def	cdf8aaad-4a4f-4dc9-a592-79fe503633f7	2026-08-16 02:45:59.208292+00	100000	99000	0.00000000	\N	\N	f
a8542a95-4aa5-4229-a854-2a954aa55229	a8542a95-4aa5-4229-a854-2a954aa55229	2026-08-16 02:48:32.631208+00	10	10	2000.00000000	\N	\N	f
52a2a329-50dc-4684-a7b0-5c090616c56d	a3d7c5f3-40e0-4c2f-933a-f95a98ab57f3	2026-08-16 02:48:34.388691+00	100000	100000	0.00000000	\N	\N	f
52a2a329-50dc-4684-a7b0-5c090616c56d	1b5063b8-9733-4563-beef-2c787c3365a9	2026-08-16 02:48:34.377308+00	100000	99000	0.00000000	\N	\N	f
05e6381b-9834-46cb-acfb-5d58cdd36755	ddeff84e-1027-4038-8102-7ce08c9e5a94	2026-08-16 02:48:34.501071+00	100000	99000	0.00000000	\N	\N	f
b45aad56-abd5-4a75-b45a-ad56abd5ea75	b45aad56-abd5-4a75-b45a-ad56abd5ea75	2026-08-16 02:49:04.739164+00	10	10	2000.00000000	\N	\N	f
fb496cf5-0c1c-4296-a861-6bff97a86dfb	071d2be9-9431-4ae5-afbb-9a195b33db15	2026-08-16 02:49:06.349341+00	100000	100000	0.00000000	\N	\N	f
fb496cf5-0c1c-4296-a861-6bff97a86dfb	f92e8766-b7d0-4dca-add5-9718456d5657	2026-08-16 02:49:06.336157+00	100000	99000	0.00000000	\N	\N	f
2090c8e4-f279-4cde-a090-c8e4f279bcde	2090c8e4-f279-4cde-a090-c8e4f279bcde	2026-08-16 02:52:01.916479+00	10	10	2000.00000000	\N	\N	f
2fdd5606-80c0-4948-aca1-c3c4fedc8c87	f41fb589-ceb8-47da-9ec4-4c1bb1f0e79d	2026-08-16 02:49:07.86568+00	100000	99000	0.00000000	\N	\N	f
5a7ab285-61fc-4613-8a83-de2bc5a44006	ed2e8329-c2c7-4ed0-b3ea-ed9b6e2abfda	2026-08-16 02:49:30.859329+00	100000	100000	0.00000000	\N	\N	f
5a7ab285-61fc-4613-8a83-de2bc5a44006	2cf63582-501f-451b-8595-587b82b2f40a	2026-08-16 02:49:30.847373+00	100000	99000	0.00000000	\N	\N	f
28140a85-c2e1-40b8-a814-0a85c2e170b8	28140a85-c2e1-40b8-a814-0a85c2e170b8	2026-08-16 02:49:31.954607+00	10	10	2000.00000000	\N	\N	f
bc5e2f97-cb65-4219-bc5e-2f97cb653219	bc5e2f97-cb65-4219-bc5e-2f97cb653219	2026-08-16 02:51:29.119708+00	10	10	2000.00000000	\N	\N	f
98cd06fc-fec9-4572-ba77-5952478dd4e7	5d4db3df-ec04-4d3f-a4b7-758b932bdeab	2026-08-16 02:51:30.871257+00	100000	100000	0.00000000	\N	\N	f
98cd06fc-fec9-4572-ba77-5952478dd4e7	6c6f8218-0e00-4731-9e59-e8b8d4d61b5d	2026-08-16 02:51:30.858572+00	100000	99000	0.00000000	\N	\N	f
78f2167d-3ba6-4186-bbec-d7e2cde10fe9	5a5b8479-6d2f-4e8c-8064-84afe7c56e72	2026-08-16 02:51:30.983982+00	100000	99000	0.00000000	\N	\N	f
a0d068b4-5aad-46eb-a0d0-68b45aadd6eb	a0d068b4-5aad-46eb-a0d0-68b45aadd6eb	2026-08-16 02:51:41.106395+00	10	10	2000.00000000	\N	\N	f
7cdecf3d-7746-40f8-87a2-77b6c3125787	0f108d2e-d94b-4cd8-b88f-504e9d68134a	2026-08-16 02:51:42.82851+00	100000	100000	0.00000000	\N	\N	f
7cdecf3d-7746-40f8-87a2-77b6c3125787	3f0e5a46-bb93-4f07-a561-60662dd5541a	2026-08-16 02:51:42.816668+00	100000	99000	0.00000000	\N	\N	f
0880d355-0836-48b8-a96b-0caa72d00fce	bee05777-76fe-4703-a9cd-9d3dc737900d	2026-08-16 02:52:15.409782+00	100000	100000	0.00000000	\N	\N	f
8abf2843-da75-453c-93ee-e0e6334a2f2f	515fbee7-3bb0-4b6d-b431-22282d623cd7	2026-08-16 02:51:42.935371+00	100000	99000	0.00000000	\N	\N	f
9ccee7f3-f97c-4edf-9cce-e7f3f97cbedf	9ccee7f3-f97c-4edf-9cce-e7f3f97cbedf	2026-08-16 02:51:46.096007+00	10	10	2000.00000000	\N	\N	f
20ff9240-3690-452c-9b6b-fb0e1b8cf307	de4588c4-c14b-4f0c-9908-2e0689f907fe	2026-08-16 02:51:47.707742+00	100000	100000	0.00000000	\N	\N	f
20ff9240-3690-452c-9b6b-fb0e1b8cf307	a14dbc0e-1b40-4539-825b-5bad255f153d	2026-08-16 02:51:47.69577+00	100000	99000	0.00000000	\N	\N	f
0880d355-0836-48b8-a96b-0caa72d00fce	649329c0-8d36-409a-b7c5-b38404828556	2026-08-16 02:52:15.397841+00	100000	99000	0.00000000	\N	\N	f
0c9f7448-9b40-4a79-a194-39934e364f6d	5f124107-5c83-432a-80fd-8899e94f9845	2026-08-16 02:51:49.285035+00	100000	99000	0.00000000	\N	\N	f
3781f153-e2ca-41ec-8738-eb7e0feb7cab	92b04625-4ad6-4bea-94ef-2795bd4c5fa1	2026-08-16 02:51:57.577316+00	100000	100000	0.00000000	\N	\N	f
3781f153-e2ca-41ec-8738-eb7e0feb7cab	e19c7724-0cba-4667-8e36-c469962a9f0e	2026-08-16 02:51:57.564744+00	100000	99000	0.00000000	\N	\N	f
f4fa7dbe-5faf-476b-b4fa-7dbe5fafd76b	f4fa7dbe-5faf-476b-b4fa-7dbe5fafd76b	2026-08-16 02:51:58.738203+00	10	10	2000.00000000	\N	\N	f
944aa552-a954-4a95-944a-a552a9542a95	944aa552-a954-4a95-944a-a552a9542a95	2026-08-16 02:51:59.841232+00	10	10	2000.00000000	\N	\N	f
24120984-c261-40d8-a412-0984c261b0d8	24120984-c261-40d8-a412-0984c261b0d8	2026-08-16 02:52:19.390169+00	10	10	2000.00000000	\N	\N	f
128fc769-902f-4980-946f-6c5c67b714ff	d27fb682-c775-422a-9b7d-45eb2e8bc3c5	2026-08-16 02:52:34.843393+00	100000	100000	0.00000000	\N	\N	f
128fc769-902f-4980-946f-6c5c67b714ff	f48d5513-b821-4152-a295-5efeb81d84a8	2026-08-16 02:52:34.832173+00	100000	99000	0.00000000	\N	\N	f
27612d1c-8ad2-48a2-8bdb-8f9677daa150	9990da57-187a-42b2-8bda-059add25d3e1	2026-08-16 02:52:34.946737+00	100000	99000	0.00000000	\N	\N	f
84c261b0-d8ec-46bb-84c2-61b0d8ec76bb	84c261b0-d8ec-46bb-84c2-61b0d8ec76bb	2026-08-16 02:53:23.243761+00	10	10	2000.00000000	\N	\N	f
36f55d6a-ca8c-42a1-be22-0187104fef3c	55ff18a7-c140-4f37-b027-cfff7e1a6e85	2026-08-16 02:53:24.978214+00	100000	100000	0.00000000	\N	\N	f
36f55d6a-ca8c-42a1-be22-0187104fef3c	6791b01d-b944-4e99-b143-fb30f4f67872	2026-08-16 02:53:24.965783+00	100000	99000	0.00000000	\N	\N	f
aff98c1c-3a6f-4c7c-87fc-eed863265c7e	fb2b1558-5440-43ec-ba87-73bc2a27ceb7	2026-08-16 02:53:25.09517+00	100000	99000	0.00000000	\N	\N	f
5fde67db-081b-4b1d-9f3b-10e45a520fb2	3878c3c1-f900-4194-b8f7-ca2538111eb4	2026-08-16 02:55:26.361436+00	10	10	3000.00000000	\N	\N	f
5fde67db-081b-4b1d-9f3b-10e45a520fb2	98207b42-c805-42cd-aafa-46f30cf1ac8c	2026-08-16 02:55:26.361436+00	10	10	2500.00000000	\N	\N	f
5fde67db-081b-4b1d-9f3b-10e45a520fb2	ca833cd8-e3ab-4d3a-9ad5-a33a88aa3843	2026-08-16 02:55:26.361436+00	10	10	2000.00000000	\N	\N	f
\.


--
-- Data for Name: contest_prize_locks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contest_prize_locks (id, contest_id, total_participants, prize_pool_gross_cents, prize_pool_net_cents, platform_fee_cents, commission_rate, winners_count, distribution_json, locked_at) FROM stdin;
\.


--
-- Data for Name: contest_reminders_sent; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contest_reminders_sent (contest_id, reminder_type, sent_at, recipient_count) FROM stdin;
9d147ba4-3d0a-492e-b867-19a222c7afbc	end_15m	2026-08-16 02:46:27.400193+00	2
7c77ff2b-bc98-46cc-aa96-95b6e9eb3070	end_15m	2026-08-16 02:46:27.406246+00	2
0da7c9af-faf3-4477-8843-69936d6a47fb	end_15m	2026-08-16 02:47:27.386406+00	1
ae1aa700-2f09-497d-877c-15679fdec5f5	end_15m	2026-08-16 02:47:27.394477+00	1
b96d7bd9-99e5-402e-bc3f-645a7251acbf	end_15m	2026-08-16 02:48:27.384259+00	1
\.


--
-- Data for Name: contest_settlements; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contest_settlements (id, contest_id, status, started_at, positions_closed_at, rankings_calculated_at, prizes_distributed_at, completed_at, total_participants, total_positions_closed, total_orders_cancelled, total_winners, prize_pool_gross_cents, prize_pool_net_cents, total_distributed_cents, platform_fee_cents, attempt_count, last_error, failed_at, snapshot_prices, snapshot_taken_at, created_at, updated_at) FROM stdin;
b9818612-ae2e-4ef1-bbd4-c2fffb63301b	c864b259-2c96-4b65-8864-b2592c96cb65	completed	2026-08-16 00:34:27.259225+00	\N	\N	\N	2026-08-16 00:34:27.259225+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 00:34:27.259225+00	2026-08-16 00:34:27.309278+00
ad735111-eb6a-4e0f-9141-f29202a007aa	90c864b2-592c-464b-90c8-64b2592c964b	completed	2026-08-16 00:34:56.188987+00	\N	\N	\N	2026-08-16 00:34:56.188987+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 00:34:56.188987+00	2026-08-16 00:34:56.304143+00
75e23ef5-1c06-4fd3-ab15-b29177f3c3bb	9ea30eb8-6065-4457-96ba-52ac5334e0ee	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 01:06:51.383623+00	2026-08-16 01:06:51.383623+00
bdd6ea97-93f6-48ab-8613-9607169de680	4263505f-6b0f-49d7-9c49-5f1008a557ea	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 01:07:18.659702+00	2026-08-16 01:07:18.659702+00
5a15e625-6836-4903-9e70-b2a7f071589e	1c0e8743-2190-48e4-9c0e-87432190c8e4	completed	2026-08-16 01:07:20.388886+00	\N	\N	\N	2026-08-16 01:07:20.388886+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 01:07:20.388886+00	2026-08-16 01:07:20.431651+00
5c8d919e-33d5-4376-a587-62b26d429d06	8f7ba104-b9d7-47e5-b624-199c1bc385c2	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 01:08:00.219033+00	2026-08-16 01:08:00.219033+00
edc4dbb5-b559-4a1b-889e-7099f57b479b	1cfa0925-3e82-4e33-a8a7-08897bff8995	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 01:25:58.768047+00	2026-08-16 01:25:58.768047+00
8a06c07c-4321-4055-9117-e31902013cec	60b0d86c-369b-4da6-a0b0-d86c369b4da6	completed	2026-08-16 01:26:02.003734+00	\N	\N	\N	2026-08-16 01:26:02.003734+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 01:26:02.003734+00	2026-08-16 01:26:02.122322+00
0d852718-df60-4dc3-b28d-71089dd77161	08048241-a050-48d4-8804-8241a050a8d4	completed	2026-08-16 01:26:30.091087+00	\N	\N	\N	2026-08-16 01:26:30.091087+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 01:26:30.091087+00	2026-08-16 01:26:30.132687+00
55d27873-1200-4dd8-bc28-4a960de130e6	2f80ce1a-329d-4e78-bc49-fe62ede53b7f	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 01:26:54.12392+00	2026-08-16 01:26:54.12392+00
afe86aa2-240a-4b74-8a40-50fa759b1e2d	1088c4e2-7138-4c4e-9088-c4e271389c4e	completed	2026-08-16 01:26:55.618159+00	\N	\N	\N	2026-08-16 01:26:55.618159+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 01:26:55.618159+00	2026-08-16 01:26:55.65768+00
9edd708b-c1e7-4139-8720-e75d66cb6aa1	e0f0783c-9e4f-47d3-a0f0-783c9e4fa7d3	completed	2026-08-16 01:27:13.582551+00	\N	\N	\N	2026-08-16 01:27:13.582551+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 01:27:13.582551+00	2026-08-16 01:27:13.621448+00
4e805dc6-9f24-475c-8530-c2ddda7b143f	40a0d0e8-f4fa-4dfe-80a0-d0e8f4fafdfe	completed	2026-08-16 01:27:16.239206+00	\N	\N	\N	2026-08-16 01:27:16.239206+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 01:27:16.239206+00	2026-08-16 01:27:16.27961+00
4c3f1f84-cf09-4e87-86d2-fc9964e6cc36	6cb6dbed-76bb-4d2e-acb6-dbed76bb5d2e	completed	2026-08-16 01:29:16.080826+00	\N	\N	\N	2026-08-16 01:29:16.080826+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 01:29:16.080826+00	2026-08-16 01:29:16.123602+00
10334341-08e6-4f2c-9245-b883cf4b4131	3c9e4f27-1309-4402-bc9e-4f2713090402	completed	2026-08-16 01:29:20.439752+00	\N	\N	\N	2026-08-16 01:29:20.439752+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 01:29:20.439752+00	2026-08-16 01:29:20.503398+00
5858ceb5-384e-4868-a068-d608890213c4	a90814e3-b698-406b-b1c7-350edfb7109a	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 01:29:20.832353+00	2026-08-16 01:29:20.832353+00
56139a83-2c9d-4c2a-9c47-c1f6c3b1ad63	a452a954-aa55-4a55-a452-a954aa55aa55	completed	2026-08-16 01:54:02.047072+00	\N	\N	\N	2026-08-16 01:54:02.047072+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 01:54:02.047072+00	2026-08-16 01:54:02.119874+00
5a8d340b-0ecd-4034-b3e6-7232b5f2edda	74ba5dae-d7eb-453a-b4ba-5daed7eb753a	completed	2026-08-16 01:54:04.817729+00	\N	\N	\N	2026-08-16 01:54:04.817729+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 01:54:04.817729+00	2026-08-16 01:54:04.858572+00
4a0c80cf-9067-473a-92a6-ac99c1d31beb	68b45a2d-96cb-45f2-a8b4-5a2d96cbe5f2	completed	2026-08-16 01:54:27.514401+00	\N	\N	\N	2026-08-16 01:54:27.514401+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 01:54:27.514401+00	2026-08-16 01:54:27.555528+00
1e69ae02-e8ba-401e-8610-862273bb7892	40a0d068-341a-4d86-80a0-d068341a0d86	completed	2026-08-16 01:54:58.419764+00	\N	\N	\N	2026-08-16 01:54:58.419764+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 01:54:58.419764+00	2026-08-16 01:54:58.460473+00
4755c9ac-e922-4a9e-be6b-5e9a9214f26d	c8e4f279-3c1e-4f87-88e4-f2793c1e0f87	completed	2026-08-16 02:00:06.299036+00	\N	\N	\N	2026-08-16 02:00:06.299036+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:00:06.299036+00	2026-08-16 02:00:06.340131+00
191ba49f-e55b-4128-b657-85db30e547a7	3098cc66-b359-4c56-b098-cc66b359ac56	completed	2026-08-16 02:27:08.404991+00	\N	\N	\N	2026-08-16 02:27:08.404991+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:27:08.404991+00	2026-08-16 02:27:08.452576+00
7201b19b-cbc2-4160-88c9-37b27ee596b1	7ee13a8f-4022-43c6-a084-fbe10763ac10	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 02:27:10.490121+00	2026-08-16 02:27:10.490121+00
dcfb7fb2-315f-4942-8fef-ad5595ab0933	3c9e4fa7-d3e9-44ba-bc9e-4fa7d3e974ba	completed	2026-08-16 02:43:00.254236+00	\N	\N	\N	2026-08-16 02:43:00.254236+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:43:00.254236+00	2026-08-16 02:43:00.314446+00
ad4bf7f5-0498-4f88-813d-adef9bbc1fa0	44bfb9c9-0453-4707-ad78-b1f69903b962	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 02:43:02.792157+00	2026-08-16 02:43:02.792157+00
6919c80d-7962-4374-a994-89a303ebc40f	241289c4-6231-48cc-a412-89c4623198cc	completed	2026-08-16 02:44:00.209959+00	\N	\N	\N	2026-08-16 02:44:00.209959+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:44:00.209959+00	2026-08-16 02:44:00.300482+00
722c0a4f-1a6d-4003-bc8e-7edfdb854e59	c4c0f294-68d1-4e7b-af65-0a2410c03088	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 02:44:02.07872+00	2026-08-16 02:44:02.07872+00
4c9fae0b-99b1-4181-b3e4-0207c4168eff	e88ecf13-0a84-4631-a816-aec1d3405c03	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 02:44:05.929174+00	2026-08-16 02:44:05.929174+00
6e7f9c8d-6eb5-477d-82f5-8e6d58ce6f78	984c2613-89c4-42f1-984c-261389c4e2f1	completed	2026-08-16 02:44:06.994606+00	\N	\N	\N	2026-08-16 02:44:06.994606+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:44:06.994606+00	2026-08-16 02:44:07.034516+00
e40b3dc6-e773-40f0-b948-7fff227518b7	f78b4135-f060-4447-a994-080db7058160	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 02:44:08.636891+00	2026-08-16 02:44:08.636891+00
7df10876-170c-409d-b537-35be382f527d	694d8dc8-1ae8-4377-aa82-3e811b7fdb90	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 02:44:11.149417+00	2026-08-16 02:44:11.149417+00
2e8e4108-75e6-4a3b-968a-e22cbca711ef	582c160b-8542-4150-982c-160b8542a150	completed	2026-08-16 02:44:36.088556+00	\N	\N	\N	2026-08-16 02:44:36.088556+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:44:36.088556+00	2026-08-16 02:44:36.12911+00
7a8e45c8-3d6a-43dd-a2fe-91025f1ea90c	b85c2e97-4b25-4209-b85c-2e974b251209	completed	2026-08-16 02:44:37.187221+00	\N	\N	\N	2026-08-16 02:44:37.187221+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:44:37.187221+00	2026-08-16 02:44:37.298239+00
3590ae92-d9f2-48b6-b3b6-6f61c4e12380	80402090-48a4-4269-8040-209048a4d269	completed	2026-08-16 02:44:38.466159+00	\N	\N	\N	2026-08-16 02:44:38.466159+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:44:38.466159+00	2026-08-16 02:44:38.520407+00
58c23bf2-f489-46c4-94f3-229b8b8aad82	b8dc6e37-9bcd-4633-b8dc-6e379bcd6633	completed	2026-08-16 02:44:55.682753+00	\N	\N	\N	2026-08-16 02:44:55.682753+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:44:55.682753+00	2026-08-16 02:44:55.745937+00
19ed553d-ae21-458c-9188-b166a0e00049	743a1d0e-0783-41e0-b43a-1d0e0783c1e0	completed	2026-08-16 02:45:57.349924+00	\N	\N	\N	2026-08-16 02:45:57.349924+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:45:57.349924+00	2026-08-16 02:45:57.390775+00
ad668613-19ee-498d-83f7-1e7912c4891a	c71ff9b5-d220-42f2-9f5f-053fcc08e9b4	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 02:45:59.159835+00	2026-08-16 02:45:59.159835+00
e65d1753-e922-47d2-91ef-257ed88f7f64	a8542a95-4aa5-4229-a854-2a954aa55229	completed	2026-08-16 02:48:32.669428+00	\N	\N	\N	2026-08-16 02:48:32.669428+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:48:32.669428+00	2026-08-16 02:48:32.725831+00
dca684e9-7942-417d-b1a9-beea71773f42	52a2a329-50dc-4684-a7b0-5c090616c56d	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 02:48:34.448928+00	2026-08-16 02:48:34.448928+00
f1965fb5-12f0-458c-b8c3-5f572e392ce4	b45aad56-abd5-4a75-b45a-ad56abd5ea75	completed	2026-08-16 02:49:04.778256+00	\N	\N	\N	2026-08-16 02:49:04.778256+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:49:04.778256+00	2026-08-16 02:49:04.827523+00
0d4fbd36-5915-4d5b-8688-1ccf0a93397b	fb496cf5-0c1c-4296-a861-6bff97a86dfb	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 02:49:06.407403+00	2026-08-16 02:49:06.407403+00
4558bf14-cd03-4953-986b-cf8de04d4032	5a7ab285-61fc-4613-8a83-de2bc5a44006	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 02:49:30.920041+00	2026-08-16 02:49:30.920041+00
f0e96709-7131-496e-8b2d-83c69920ff92	28140a85-c2e1-40b8-a814-0a85c2e170b8	completed	2026-08-16 02:49:31.992205+00	\N	\N	\N	2026-08-16 02:49:31.992205+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:49:31.992205+00	2026-08-16 02:49:32.032402+00
f9245868-8ab0-42c2-a781-32263241d396	bc5e2f97-cb65-4219-bc5e-2f97cb653219	completed	2026-08-16 02:51:29.157025+00	\N	\N	\N	2026-08-16 02:51:29.157025+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:51:29.157025+00	2026-08-16 02:51:29.216669+00
3aa1864f-edbe-4191-b0a8-82b834d5e859	98cd06fc-fec9-4572-ba77-5952478dd4e7	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 02:51:30.936731+00	2026-08-16 02:51:30.936731+00
6246ad3a-1127-4f2f-8893-d8efa911fa2d	a0d068b4-5aad-46eb-a0d0-68b45aadd6eb	completed	2026-08-16 02:51:41.142902+00	\N	\N	\N	2026-08-16 02:51:41.142902+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:51:41.142902+00	2026-08-16 02:51:41.215787+00
4c0a41a8-7a6b-46e0-880b-1919399cea05	7cdecf3d-7746-40f8-87a2-77b6c3125787	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 02:51:42.885725+00	2026-08-16 02:51:42.885725+00
65fea9bf-23c9-4915-9dce-0d5b53f10a48	9ccee7f3-f97c-4edf-9cce-e7f3f97cbedf	completed	2026-08-16 02:51:46.133264+00	\N	\N	\N	2026-08-16 02:51:46.133264+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:51:46.133264+00	2026-08-16 02:51:46.209205+00
3f89506a-c0f5-43a3-8977-f9e3025c945a	20ff9240-3690-452c-9b6b-fb0e1b8cf307	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 02:51:47.767213+00	2026-08-16 02:51:47.767213+00
073a1864-1485-4c31-8d0f-e92935874bf3	3781f153-e2ca-41ec-8738-eb7e0feb7cab	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 02:51:57.6411+00	2026-08-16 02:51:57.6411+00
6d1672ef-8daf-4842-9fb7-2f33bb89fb24	f4fa7dbe-5faf-476b-b4fa-7dbe5fafd76b	completed	2026-08-16 02:51:58.775069+00	\N	\N	\N	2026-08-16 02:51:58.775069+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:51:58.775069+00	2026-08-16 02:51:58.815671+00
5639651b-def9-459b-8460-5c8ee6a84c35	944aa552-a954-4a95-944a-a552a9542a95	completed	2026-08-16 02:51:59.877038+00	\N	\N	\N	2026-08-16 02:51:59.877038+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:51:59.877038+00	2026-08-16 02:51:59.923454+00
3df9a817-d791-4231-8e6c-fb02485dd592	2090c8e4-f279-4cde-a090-c8e4f279bcde	completed	2026-08-16 02:52:01.953078+00	\N	\N	\N	2026-08-16 02:52:01.953078+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:52:01.953078+00	2026-08-16 02:52:02.022053+00
12cd2b4b-502c-4209-aa36-c0f109ff9c94	0880d355-0836-48b8-a96b-0caa72d00fce	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 02:52:15.46737+00	2026-08-16 02:52:15.46737+00
00ba5a33-4212-4b0d-a23b-5e7f78c0cc43	24120984-c261-40d8-a412-0984c261b0d8	completed	2026-08-16 02:52:19.449367+00	\N	\N	\N	2026-08-16 02:52:19.449367+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:52:19.449367+00	2026-08-16 02:52:19.50835+00
c0d73f54-c6b7-4004-bef9-7657d298c072	128fc769-902f-4980-946f-6c5c67b714ff	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 02:52:34.899898+00	2026-08-16 02:52:34.899898+00
a57950d7-ac9c-4578-b656-44e88e6439ec	84c261b0-d8ec-46bb-84c2-61b0d8ec76bb	completed	2026-08-16 02:53:23.280735+00	\N	\N	\N	2026-08-16 02:53:23.280735+00	3	0	0	1	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:53:23.280735+00	2026-08-16 02:53:23.32095+00
485b6aa5-2988-424d-bda6-d996d92bf167	36f55d6a-ca8c-42a1-be22-0187104fef3c	completed	\N	\N	\N	\N	\N	0	0	0	0	0	0	0	0	0	\N	\N	\N	\N	2026-08-16 02:53:25.03928+00	2026-08-16 02:53:25.03928+00
df9c95b5-199a-4355-9b40-cee05056bbb9	5fde67db-081b-4b1d-9f3b-10e45a520fb2	completed	2026-08-16 02:55:26.361436+00	\N	\N	\N	2026-08-16 02:55:26.361436+00	3	0	0	3	30000	24000	24000	6000	0	\N	\N	\N	\N	2026-08-16 02:55:26.361436+00	2026-08-16 02:55:26.361436+00
\.


--
-- Data for Name: contest_status_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contest_status_history (id, contest_id, from_status, to_status, changed_by, reason, metadata, created_at) FROM stdin;
\.


--
-- Data for Name: contest_symbols; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contest_symbols (contest_id, symbol, provider_symbol_twelvedata, provider_symbol_massive, enabled, created_at) FROM stdin;
9d147ba4-3d0a-492e-b867-19a222c7afbc	BTC/USD	\N	\N	t	2026-08-16 01:05:27.726719+00
7c77ff2b-bc98-46cc-aa96-95b6e9eb3070	BTC/USD	\N	\N	t	2026-08-16 01:05:44.449795+00
9ea30eb8-6065-4457-96ba-52ac5334e0ee	BTC/USD	\N	\N	t	2026-08-16 01:06:51.304787+00
0da7c9af-faf3-4477-8843-69936d6a47fb	BTC/USD	\N	\N	t	2026-08-16 01:06:51.43476+00
734d42df-4077-471f-9f96-2b4143ab43df	BTC/USD	\N	\N	t	2026-08-16 01:06:51.614842+00
4263505f-6b0f-49d7-9c49-5f1008a557ea	BTC/USD	\N	\N	t	2026-08-16 01:07:18.577177+00
ae1aa700-2f09-497d-877c-15679fdec5f5	BTC/USD	\N	\N	t	2026-08-16 01:07:18.706678+00
daf27c0c-5e6d-411e-ae0d-1df1120ffdf3	BTC/USD	\N	\N	t	2026-08-16 01:07:18.859167+00
8f7ba104-b9d7-47e5-b624-199c1bc385c2	BTC/USD	\N	\N	t	2026-08-16 01:08:00.129144+00
b96d7bd9-99e5-402e-bc3f-645a7251acbf	BTC/USD	\N	\N	t	2026-08-16 01:08:00.263607+00
5db97139-a45c-4de8-9c5c-02f65ae18683	BTC/USD	\N	\N	t	2026-08-16 01:08:00.42731+00
1cfa0925-3e82-4e33-a8a7-08897bff8995	BTC/USD	\N	\N	t	2026-08-16 01:25:58.69064+00
a9e9ee08-e9c7-4796-b17c-8251365602b4	BTC/USD	\N	\N	t	2026-08-16 01:25:58.829648+00
213e9258-cb82-4f26-9db2-b7d57f8bd0f8	BTC/USD	\N	\N	t	2026-08-16 01:25:58.981198+00
2f80ce1a-329d-4e78-bc49-fe62ede53b7f	BTC/USD	\N	\N	t	2026-08-16 01:26:54.04674+00
45e3a795-edf5-4541-b89e-51cf2c71da49	BTC/USD	\N	\N	t	2026-08-16 01:26:54.170881+00
7ed8ef63-9fe8-450b-b6f4-ba33e7a3cef8	BTC/USD	\N	\N	t	2026-08-16 01:27:11.248018+00
377995fd-6611-49f1-a4f8-99d9fb83e856	BTC/USD	\N	\N	t	2026-08-16 01:27:11.411214+00
a90814e3-b698-406b-b1c7-350edfb7109a	BTC/USD	\N	\N	t	2026-08-16 01:29:20.638372+00
0acab9a9-ee24-4ff4-8587-fe642f0c3320	BTC/USD	\N	\N	t	2026-08-16 01:29:20.910925+00
a4da580b-6aa3-4a5e-b7ef-79468cf4cf1b	BTC/USD	\N	\N	t	2026-08-16 01:29:21.114815+00
7ee13a8f-4022-43c6-a084-fbe10763ac10	BTC/USD	\N	\N	t	2026-08-16 02:27:10.394906+00
1883b591-7d1a-4f42-9325-9507c69f7df8	BTC/USD	\N	\N	t	2026-08-16 02:27:10.544358+00
44bfb9c9-0453-4707-ad78-b1f69903b962	BTC/USD	\N	\N	t	2026-08-16 02:43:02.719946+00
1b87adda-e572-4a9e-9243-8c861bfcb234	BTC/USD	\N	\N	t	2026-08-16 02:43:02.838112+00
c4c0f294-68d1-4e7b-af65-0a2410c03088	BTC/USD	\N	\N	t	2026-08-16 02:44:02.00022+00
251dba09-bdf8-4e44-9d96-ab9f984dd99d	BTC/USD	\N	\N	t	2026-08-16 02:44:02.126958+00
e88ecf13-0a84-4631-a816-aec1d3405c03	BTC/USD	\N	\N	t	2026-08-16 02:44:05.830027+00
f78b4135-f060-4447-a994-080db7058160	BTC/USD	\N	\N	t	2026-08-16 02:44:08.562405+00
694d8dc8-1ae8-4377-aa82-3e811b7fdb90	BTC/USD	\N	\N	t	2026-08-16 02:44:11.07566+00
c71ff9b5-d220-42f2-9f5f-053fcc08e9b4	BTC/USD	\N	\N	t	2026-08-16 02:45:59.085102+00
0cd34720-b787-4e6f-acae-2c5df8a43def	BTC/USD	\N	\N	t	2026-08-16 02:45:59.205992+00
52a2a329-50dc-4684-a7b0-5c090616c56d	BTC/USD	\N	\N	t	2026-08-16 02:48:34.376076+00
05e6381b-9834-46cb-acfb-5d58cdd36755	BTC/USD	\N	\N	t	2026-08-16 02:48:34.498651+00
fb496cf5-0c1c-4296-a861-6bff97a86dfb	BTC/USD	\N	\N	t	2026-08-16 02:49:06.333462+00
2fdd5606-80c0-4948-aca1-c3c4fedc8c87	BTC/USD	\N	\N	t	2026-08-16 02:49:07.86323+00
5a7ab285-61fc-4613-8a83-de2bc5a44006	BTC/USD	\N	\N	t	2026-08-16 02:49:30.845046+00
98cd06fc-fec9-4572-ba77-5952478dd4e7	BTC/USD	\N	\N	t	2026-08-16 02:51:30.856091+00
78f2167d-3ba6-4186-bbec-d7e2cde10fe9	BTC/USD	\N	\N	t	2026-08-16 02:51:30.981472+00
7cdecf3d-7746-40f8-87a2-77b6c3125787	BTC/USD	\N	\N	t	2026-08-16 02:51:42.814241+00
8abf2843-da75-453c-93ee-e0e6334a2f2f	BTC/USD	\N	\N	t	2026-08-16 02:51:42.932174+00
20ff9240-3690-452c-9b6b-fb0e1b8cf307	BTC/USD	\N	\N	t	2026-08-16 02:51:47.69318+00
0c9f7448-9b40-4a79-a194-39934e364f6d	BTC/USD	\N	\N	t	2026-08-16 02:51:49.282218+00
3781f153-e2ca-41ec-8738-eb7e0feb7cab	BTC/USD	\N	\N	t	2026-08-16 02:51:57.562271+00
0880d355-0836-48b8-a96b-0caa72d00fce	BTC/USD	\N	\N	t	2026-08-16 02:52:15.395333+00
128fc769-902f-4980-946f-6c5c67b714ff	BTC/USD	\N	\N	t	2026-08-16 02:52:34.828954+00
27612d1c-8ad2-48a2-8bdb-8f9677daa150	BTC/USD	\N	\N	t	2026-08-16 02:52:34.94444+00
36f55d6a-ca8c-42a1-be22-0187104fef3c	BTC/USD	\N	\N	t	2026-08-16 02:53:24.963311+00
aff98c1c-3a6f-4c7c-87fc-eed863265c7e	BTC/USD	\N	\N	t	2026-08-16 02:53:25.092327+00
\.


--
-- Data for Name: contests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contests (id, name, description, starts_at, ends_at, status, entry_fee_cents, platform_fee_bps, qty_total, rules_json, created_at, shard_id, is_free, max_participants, auto_repeat, repeat_interval, duration_type, asset_class, duration_minutes, min_participants, registration_deadline, auto_start, template_id, commission_rate, published_at, started_at, ended_at, settled_at, cancelled_at, cancellation_reason, current_participants, auto_generated, type, starting_reminder_sent_at, paused_at, total_paused_duration, prizes_locked_at, prize_pool_net_cents, schedule_id, commission_amount, market_close_time, registration_opens_at, tier_id, economics_locked_at, locked_entry_fee_cents, locked_platform_fee_bps, late_join_enabled, schedule_idempotency_key) FROM stdin;
cc66b3d9-6cb6-4b6d-8c66-b3d96cb6db6d	lock-test	\N	2026-08-16 00:33:43.35886+00	2026-08-16 01:33:43.35886+00	completed	10000	5000	10	\N	2026-08-16 00:33:43.35886+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 00:33:43.35886+00	10000	1500	t	\N
44221188-4422-4188-8422-118844221188	lock-test	\N	2026-08-16 00:34:07.702048+00	2026-08-16 01:34:07.702048+00	completed	10000	5000	10	\N	2026-08-16 00:34:07.702048+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 00:34:07.702048+00	10000	1500	t	\N
734d42df-4077-471f-9f96-2b4143ab43df	phase2-e2e	\N	2026-08-16 00:06:51.59635+00	2026-08-16 03:06:51.59635+00	settling	10000	2000	100000	\N	2026-08-16 01:06:51.609021+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 01:06:51.609021+00	10000	2000	t	\N
c864b259-2c96-4b65-8864-b2592c96cb65	phase11-e2e	\N	2026-08-15 23:34:27.210428+00	2026-08-16 01:34:27.210428+00	registration_open	1	5000	10	\N	2026-08-16 00:34:27.212578+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 00:34:27.212578+00	10000	2000	t	\N
fc7ebfdf-6f37-4b0d-bc7e-bfdf6f371b0d	lock-test	\N	2026-08-16 00:34:27.330744+00	2026-08-16 01:34:27.330744+00	completed	10000	5000	10	\N	2026-08-16 00:34:27.330744+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 00:34:27.330744+00	10000	1500	t	\N
a9e9ee08-e9c7-4796-b17c-8251365602b4	phase2-e2e	\N	2026-08-16 00:25:58.797091+00	2026-08-16 03:25:58.797091+00	running	10000	2000	100000	\N	2026-08-16 01:25:58.823521+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 01:25:58.823521+00	10000	2000	t	\N
8f7ba104-b9d7-47e5-b624-199c1bc385c2	phase2-e2e	\N	2026-08-16 00:08:00.109403+00	2026-08-16 03:08:00.109403+00	settling	10000	2000	100000	\N	2026-08-16 01:08:00.123384+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 01:08:00.123384+00	10000	2000	t	\N
90c864b2-592c-464b-90c8-64b2592c964b	phase11-e2e	\N	2026-08-15 23:34:56.114216+00	2026-08-16 01:34:56.114216+00	registration_open	1	5000	10	\N	2026-08-16 00:34:56.117562+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 00:34:56.117562+00	10000	2000	t	\N
e8f47abd-5eaf-47ab-a8f4-7abd5eaf57ab	lock-test	\N	2026-08-16 00:34:56.337834+00	2026-08-16 01:34:56.337834+00	completed	10000	5000	10	\N	2026-08-16 00:34:56.337834+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 00:34:56.337834+00	10000	1500	t	\N
4263505f-6b0f-49d7-9c49-5f1008a557ea	phase2-e2e	\N	2026-08-16 00:07:18.552735+00	2026-08-16 03:07:18.552735+00	settling	10000	2000	100000	\N	2026-08-16 01:07:18.570249+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 01:07:18.570249+00	10000	2000	t	\N
9d147ba4-3d0a-492e-b867-19a222c7afbc	phase2-e2e	\N	2026-08-16 00:05:27.701972+00	2026-08-16 03:05:27.701972+00	running	10000	2000	100000	\N	2026-08-16 01:05:27.719901+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 01:05:27.719901+00	10000	2000	t	\N
2f80ce1a-329d-4e78-bc49-fe62ede53b7f	phase2-e2e	\N	2026-08-16 00:26:54.023736+00	2026-08-16 03:26:54.023736+00	settling	10000	2000	100000	\N	2026-08-16 01:26:54.040754+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 01:26:54.040754+00	10000	2000	t	\N
ae1aa700-2f09-497d-877c-15679fdec5f5	phase2-e2e	\N	2026-08-16 00:07:18.688929+00	2026-08-16 03:07:18.688929+00	running	10000	2000	100000	\N	2026-08-16 01:07:18.701065+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 01:07:18.701065+00	10000	2000	t	\N
7c77ff2b-bc98-46cc-aa96-95b6e9eb3070	phase2-e2e	\N	2026-08-16 00:05:44.426898+00	2026-08-16 03:05:44.426898+00	running	10000	2000	100000	\N	2026-08-16 01:05:44.443339+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 01:05:44.443339+00	10000	2000	t	\N
b96d7bd9-99e5-402e-bc3f-645a7251acbf	phase2-e2e	\N	2026-08-16 00:08:00.248991+00	2026-08-16 03:08:00.248991+00	running	10000	2000	100000	\N	2026-08-16 01:08:00.257986+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 01:08:00.257986+00	10000	2000	t	\N
daf27c0c-5e6d-411e-ae0d-1df1120ffdf3	phase2-e2e	\N	2026-08-16 00:07:18.840867+00	2026-08-16 03:07:18.840867+00	settling	10000	2000	100000	\N	2026-08-16 01:07:18.85349+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 01:07:18.85349+00	10000	2000	t	\N
9ea30eb8-6065-4457-96ba-52ac5334e0ee	phase2-e2e	\N	2026-08-16 00:06:51.281601+00	2026-08-16 03:06:51.281601+00	settling	10000	2000	100000	\N	2026-08-16 01:06:51.297935+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 01:06:51.297935+00	10000	2000	t	\N
0da7c9af-faf3-4477-8843-69936d6a47fb	phase2-e2e	\N	2026-08-16 00:06:51.415319+00	2026-08-16 03:06:51.415319+00	running	10000	2000	100000	\N	2026-08-16 01:06:51.428514+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 01:06:51.428514+00	10000	2000	t	\N
213e9258-cb82-4f26-9db2-b7d57f8bd0f8	phase2-e2e	\N	2026-08-16 00:25:58.961258+00	2026-08-16 03:25:58.961258+00	settling	10000	2000	100000	\N	2026-08-16 01:25:58.975106+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 01:25:58.975106+00	10000	2000	t	\N
5db97139-a45c-4de8-9c5c-02f65ae18683	phase2-e2e	\N	2026-08-16 00:08:00.411067+00	2026-08-16 03:08:00.411067+00	settling	10000	2000	100000	\N	2026-08-16 01:08:00.420964+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 01:08:00.420964+00	10000	2000	t	\N
1c0e8743-2190-48e4-9c0e-87432190c8e4	phase11-e2e	\N	2026-08-16 00:07:20.344259+00	2026-08-16 02:07:20.344259+00	registration_open	1	5000	10	\N	2026-08-16 01:07:20.346091+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 01:07:20.346091+00	10000	2000	t	\N
98cce6f3-793c-4ecf-98cc-e6f3793c9ecf	lock-test	\N	2026-08-16 01:07:20.506995+00	2026-08-16 02:07:20.506995+00	completed	10000	5000	10	\N	2026-08-16 01:07:20.506995+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 01:07:20.506995+00	10000	1500	t	\N
e0f0783c-9e4f-47d3-a0f0-783c9e4fa7d3	phase11-e2e	\N	2026-08-16 00:27:13.538527+00	2026-08-16 02:27:13.538527+00	registration_open	1	5000	10	\N	2026-08-16 01:27:13.539987+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 01:27:13.539987+00	10000	2000	t	\N
08048241-a050-48d4-8804-8241a050a8d4	phase11-e2e	\N	2026-08-16 00:26:30.045003+00	2026-08-16 02:26:30.045003+00	registration_open	1	5000	10	\N	2026-08-16 01:26:30.047957+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 01:26:30.047957+00	10000	2000	t	\N
f8fc7ebf-5faf-47ab-b8fc-7ebf5faf57ab	lock-test	\N	2026-08-16 01:26:30.156864+00	2026-08-16 02:26:30.156864+00	completed	10000	5000	10	\N	2026-08-16 01:26:30.156864+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 01:26:30.156864+00	10000	1500	t	\N
1cfa0925-3e82-4e33-a8a7-08897bff8995	phase2-e2e	\N	2026-08-16 00:25:58.663294+00	2026-08-16 03:25:58.663294+00	settling	10000	2000	100000	\N	2026-08-16 01:25:58.684227+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 01:25:58.684227+00	10000	2000	t	\N
60b0d86c-369b-4da6-a0b0-d86c369b4da6	phase11-e2e	\N	2026-08-16 00:26:01.95557+00	2026-08-16 02:26:01.95557+00	registration_open	1	5000	10	\N	2026-08-16 01:26:01.958644+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 01:26:01.958644+00	10000	2000	t	\N
60b058ac-56ab-456a-a0b0-58ac56abd56a	lock-test	\N	2026-08-16 01:26:02.146599+00	2026-08-16 02:26:02.146599+00	completed	10000	5000	10	\N	2026-08-16 01:26:02.146599+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 01:26:02.146599+00	10000	1500	t	\N
45e3a795-edf5-4541-b89e-51cf2c71da49	phase2-e2e	\N	2026-08-16 00:26:54.151412+00	2026-08-16 03:26:54.151412+00	running	10000	2000	100000	\N	2026-08-16 01:26:54.164669+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 01:26:54.164669+00	10000	2000	t	\N
7ed8ef63-9fe8-450b-b6f4-ba33e7a3cef8	phase2-e2e	\N	2026-08-16 00:27:11.221713+00	2026-08-16 03:27:11.221713+00	running	10000	2000	100000	\N	2026-08-16 01:27:11.241501+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 01:27:11.241501+00	10000	2000	t	\N
1088c4e2-7138-4c4e-9088-c4e271389c4e	phase11-e2e	\N	2026-08-16 00:26:55.572815+00	2026-08-16 02:26:55.572815+00	registration_open	1	5000	10	\N	2026-08-16 01:26:55.575421+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 01:26:55.575421+00	10000	2000	t	\N
f4fa7dbe-5faf-472b-b4fa-7dbe5faf572b	lock-test	\N	2026-08-16 01:26:55.725998+00	2026-08-16 02:26:55.725998+00	completed	10000	5000	10	\N	2026-08-16 01:26:55.725998+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 01:26:55.725998+00	10000	1500	t	\N
377995fd-6611-49f1-a4f8-99d9fb83e856	phase2-e2e	\N	2026-08-16 00:27:11.378644+00	2026-08-16 03:27:11.378644+00	settling	10000	2000	100000	\N	2026-08-16 01:27:11.403998+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 01:27:11.403998+00	10000	2000	t	\N
c8643299-4ca6-43a9-8864-32994ca653a9	lock-test	\N	2026-08-16 01:27:13.642772+00	2026-08-16 02:27:13.642772+00	completed	10000	5000	10	\N	2026-08-16 01:27:13.642772+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 01:27:13.642772+00	10000	1500	t	\N
40a0d0e8-f4fa-4dfe-80a0-d0e8f4fafdfe	phase11-e2e	\N	2026-08-16 00:27:16.194369+00	2026-08-16 02:27:16.194369+00	registration_open	1	5000	10	\N	2026-08-16 01:27:16.19609+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 01:27:16.19609+00	10000	2000	t	\N
8cc66331-188c-46a3-8cc6-6331188c46a3	lock-test	\N	2026-08-16 01:27:16.322669+00	2026-08-16 02:27:16.322669+00	completed	10000	5000	10	\N	2026-08-16 01:27:16.322669+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 01:27:16.322669+00	10000	1500	t	\N
84c261b0-d8ec-46bb-84c2-61b0d8ec76bb	phase11-e2e	\N	2026-08-16 01:53:23.236403+00	2026-08-16 03:53:23.236403+00	registration_open	1	5000	10	\N	2026-08-16 02:53:23.238176+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:53:23.238176+00	10000	2000	t	\N
251dba09-bdf8-4e44-9d96-ab9f984dd99d	phase2-e2e	\N	2026-08-16 01:44:02.105735+00	2026-08-16 04:44:02.105735+00	running	10000	2000	100000	\N	2026-08-16 02:44:02.119104+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 02:44:02.119104+00	10000	2000	t	\N
6cb6dbed-76bb-4d2e-acb6-dbed76bb5d2e	phase11-e2e	\N	2026-08-16 00:29:16.035002+00	2026-08-16 02:29:16.035002+00	registration_open	1	5000	10	\N	2026-08-16 01:29:16.036893+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 01:29:16.036893+00	10000	2000	t	\N
b058acd6-ebf5-4abd-b058-acd6ebf57abd	lock-test	\N	2026-08-16 01:29:16.202122+00	2026-08-16 02:29:16.202122+00	completed	10000	5000	10	\N	2026-08-16 01:29:16.202122+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 01:29:16.202122+00	10000	1500	t	\N
74ba5dae-d7eb-453a-b4ba-5daed7eb753a	phase11-e2e	\N	2026-08-16 00:54:04.773768+00	2026-08-16 02:54:04.773768+00	registration_open	1	5000	10	\N	2026-08-16 01:54:04.774843+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 01:54:04.774843+00	10000	2000	t	\N
10884422-1108-44c2-9088-4422110884c2	lock-test	\N	2026-08-16 01:54:04.924965+00	2026-08-16 02:54:04.924965+00	completed	10000	5000	10	\N	2026-08-16 01:54:04.924965+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 01:54:04.924965+00	10000	1500	t	\N
1b87adda-e572-4a9e-9243-8c861bfcb234	phase2-e2e	\N	2026-08-16 01:43:02.819485+00	2026-08-16 04:43:02.819485+00	running	10000	2000	100000	\N	2026-08-16 02:43:02.832194+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 02:43:02.832194+00	10000	2000	t	\N
3c9e4f27-1309-4402-bc9e-4f2713090402	phase11-e2e	\N	2026-08-16 00:29:20.390626+00	2026-08-16 02:29:20.390626+00	registration_open	1	5000	10	\N	2026-08-16 01:29:20.393482+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 01:29:20.393482+00	10000	2000	t	\N
5028148a-c562-4118-9028-148ac5623118	lock-test	\N	2026-08-16 01:29:20.526526+00	2026-08-16 02:29:20.526526+00	completed	10000	5000	10	\N	2026-08-16 01:29:20.526526+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 01:29:20.526526+00	10000	1500	t	\N
3c9e4fa7-d3e9-44ba-bc9e-4fa7d3e974ba	phase11-e2e	\N	2026-08-16 01:43:00.201045+00	2026-08-16 03:43:00.201045+00	registration_open	1	5000	10	\N	2026-08-16 02:43:00.202854+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:43:00.202854+00	10000	2000	t	\N
3098cc66-b359-4c56-b098-cc66b359ac56	phase11-e2e	\N	2026-08-16 01:27:08.298679+00	2026-08-16 03:27:08.298679+00	registration_open	1	5000	10	\N	2026-08-16 02:27:08.306976+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:27:08.306976+00	10000	2000	t	\N
68b45a2d-96cb-45f2-a8b4-5a2d96cbe5f2	phase11-e2e	\N	2026-08-16 00:54:27.46858+00	2026-08-16 02:54:27.46858+00	registration_open	1	5000	10	\N	2026-08-16 01:54:27.471037+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 01:54:27.471037+00	10000	2000	t	\N
a90814e3-b698-406b-b1c7-350edfb7109a	phase2-e2e	\N	2026-08-16 00:29:20.615442+00	2026-08-16 03:29:20.615442+00	settling	10000	2000	100000	\N	2026-08-16 01:29:20.631941+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 01:29:20.631941+00	10000	2000	t	\N
643299cc-66b3-492c-a432-99cc66b3592c	lock-test	\N	2026-08-16 01:54:27.627942+00	2026-08-16 02:54:27.627942+00	completed	10000	5000	10	\N	2026-08-16 01:54:27.627942+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 01:54:27.627942+00	10000	1500	t	\N
0acab9a9-ee24-4ff4-8587-fe642f0c3320	phase2-e2e	\N	2026-08-16 00:29:20.864133+00	2026-08-16 03:29:20.864133+00	running	10000	2000	100000	\N	2026-08-16 01:29:20.903531+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 01:29:20.903531+00	10000	2000	t	\N
98cce673-b95c-4ed7-98cc-e673b95caed7	lock-test	\N	2026-08-16 02:27:08.474579+00	2026-08-16 03:27:08.474579+00	completed	10000	5000	10	\N	2026-08-16 02:27:08.474579+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 02:27:08.474579+00	10000	1500	t	\N
a4da580b-6aa3-4a5e-b7ef-79468cf4cf1b	phase2-e2e	\N	2026-08-16 00:29:21.076887+00	2026-08-16 03:29:21.076887+00	settling	10000	2000	100000	\N	2026-08-16 01:29:21.10648+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 01:29:21.10648+00	10000	2000	t	\N
5caed7eb-f5fa-4dfe-9cae-d7ebf5fafdfe	lock-test	\N	2026-08-16 02:43:00.39997+00	2026-08-16 03:43:00.39997+00	completed	10000	5000	10	\N	2026-08-16 02:43:00.39997+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 02:43:00.39997+00	10000	1500	t	\N
40a0d068-341a-4d86-80a0-d068341a0d86	phase11-e2e	\N	2026-08-16 00:54:58.374574+00	2026-08-16 02:54:58.374574+00	registration_open	1	5000	10	\N	2026-08-16 01:54:58.376475+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 01:54:58.376475+00	10000	2000	t	\N
a452a954-aa55-4a55-a452-a954aa55aa55	phase11-e2e	\N	2026-08-16 00:54:02.000932+00	2026-08-16 02:54:02.000932+00	registration_open	1	5000	10	\N	2026-08-16 01:54:02.003746+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 01:54:02.003746+00	10000	2000	t	\N
a4d2e9f4-7abd-4e6f-a4d2-e9f47abdde6f	lock-test	\N	2026-08-16 01:54:02.141893+00	2026-08-16 02:54:02.141893+00	completed	10000	5000	10	\N	2026-08-16 01:54:02.141893+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 01:54:02.141893+00	10000	1500	t	\N
cc66b359-acd6-4b75-8c66-b359acd6eb75	lock-test	\N	2026-08-16 01:54:58.52119+00	2026-08-16 02:54:58.52119+00	completed	10000	5000	10	\N	2026-08-16 01:54:58.52119+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 01:54:58.52119+00	10000	1500	t	\N
349a4da6-5329-444a-b49a-4da65329944a	lock-test	\N	2026-08-16 02:44:04.370111+00	2026-08-16 03:44:04.370111+00	completed	10000	5000	10	\N	2026-08-16 02:44:04.370111+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 02:44:04.370111+00	10000	1500	t	\N
7ee13a8f-4022-43c6-a084-fbe10763ac10	phase2-e2e	\N	2026-08-16 01:27:10.36804+00	2026-08-16 04:27:10.36804+00	settling	10000	2000	100000	\N	2026-08-16 02:27:10.387937+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 02:27:10.387937+00	10000	2000	t	\N
c8e4f279-3c1e-4f87-88e4-f2793c1e0f87	phase11-e2e	\N	2026-08-16 01:00:06.252855+00	2026-08-16 03:00:06.252855+00	registration_open	1	5000	10	\N	2026-08-16 02:00:06.253578+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:00:06.253578+00	10000	2000	t	\N
d4ea75ba-5dae-472b-94ea-75ba5dae572b	lock-test	\N	2026-08-16 02:00:06.409304+00	2026-08-16 03:00:06.409304+00	completed	10000	5000	10	\N	2026-08-16 02:00:06.409304+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 02:00:06.409304+00	10000	1500	t	\N
1883b591-7d1a-4f42-9325-9507c69f7df8	phase2-e2e	\N	2026-08-16 01:27:10.521862+00	2026-08-16 04:27:10.521862+00	running	10000	2000	100000	\N	2026-08-16 02:27:10.534989+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 02:27:10.534989+00	10000	2000	t	\N
c4c0f294-68d1-4e7b-af65-0a2410c03088	phase2-e2e	\N	2026-08-16 01:44:01.978305+00	2026-08-16 04:44:01.978305+00	settling	10000	2000	100000	\N	2026-08-16 02:44:01.994401+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 02:44:01.994401+00	10000	2000	t	\N
241289c4-6231-48cc-a412-89c4623198cc	phase11-e2e	\N	2026-08-16 01:44:00.164257+00	2026-08-16 03:44:00.164257+00	registration_open	1	5000	10	\N	2026-08-16 02:44:00.166617+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:44:00.166617+00	10000	2000	t	\N
44bfb9c9-0453-4707-ad78-b1f69903b962	phase2-e2e	\N	2026-08-16 01:43:02.696248+00	2026-08-16 04:43:02.696248+00	settling	10000	2000	100000	\N	2026-08-16 02:43:02.713859+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 02:43:02.713859+00	10000	2000	t	\N
c0e07038-1c8e-4723-80e0-70381c8e4723	lock-test	\N	2026-08-16 02:44:00.322281+00	2026-08-16 03:44:00.322281+00	completed	10000	5000	10	\N	2026-08-16 02:44:00.322281+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 02:44:00.322281+00	10000	1500	t	\N
984c2613-89c4-42f1-984c-261389c4e2f1	phase11-e2e	\N	2026-08-16 01:44:06.95215+00	2026-08-16 03:44:06.95215+00	registration_open	1	5000	10	\N	2026-08-16 02:44:06.95281+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:44:06.95281+00	10000	2000	t	\N
f78b4135-f060-4447-a994-080db7058160	phase2-e2e	\N	2026-08-16 01:44:08.540261+00	2026-08-16 04:44:08.540261+00	settling	10000	2000	100000	\N	2026-08-16 02:44:08.554904+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 02:44:08.554904+00	10000	2000	t	\N
e88ecf13-0a84-4631-a816-aec1d3405c03	phase2-e2e	\N	2026-08-16 01:44:05.808171+00	2026-08-16 04:44:05.808171+00	settling	10000	2000	100000	\N	2026-08-16 02:44:05.82325+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 02:44:05.82325+00	10000	2000	t	\N
542a95ca-e5f2-49fc-942a-95cae5f2f9fc	lock-test	\N	2026-08-16 02:44:07.103591+00	2026-08-16 03:44:07.103591+00	completed	10000	5000	10	\N	2026-08-16 02:44:07.103591+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 02:44:07.103591+00	10000	1500	t	\N
fcfe7fbf-df6f-47db-bcfe-7fbfdf6fb7db	lock-test	\N	2026-08-16 02:44:09.664871+00	2026-08-16 03:44:09.664871+00	completed	10000	5000	10	\N	2026-08-16 02:44:09.664871+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 02:44:09.664871+00	10000	1500	t	\N
694d8dc8-1ae8-4377-aa82-3e811b7fdb90	phase2-e2e	\N	2026-08-16 01:44:11.054363+00	2026-08-16 04:44:11.054363+00	settling	10000	2000	100000	\N	2026-08-16 02:44:11.069678+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 02:44:11.069678+00	10000	2000	t	\N
fc7e3f1f-0f07-4381-bc7e-3f1f0f070381	lock-test	\N	2026-08-16 02:53:23.379123+00	2026-08-16 03:53:23.379123+00	completed	10000	5000	10	\N	2026-08-16 02:53:23.379123+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 02:53:23.379123+00	10000	1500	t	\N
c71ff9b5-d220-42f2-9f5f-053fcc08e9b4	phase2-e2e	\N	2026-08-16 01:45:59.063042+00	2026-08-16 04:45:59.063042+00	settling	10000	2000	100000	\N	2026-08-16 02:45:59.079047+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 02:45:59.079047+00	10000	2000	t	\N
582c160b-8542-4150-982c-160b8542a150	phase11-e2e	\N	2026-08-16 01:44:36.042698+00	2026-08-16 03:44:36.042698+00	registration_open	1	5000	10	\N	2026-08-16 02:44:36.043686+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:44:36.043686+00	10000	2000	t	\N
aff98c1c-3a6f-4c7c-87fc-eed863265c7e	phase2-e2e	\N	2026-08-16 01:53:25.068466+00	2026-08-16 04:53:25.068466+00	running	10000	2000	100000	\N	2026-08-16 02:53:25.080406+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 02:53:25.080406+00	10000	2000	t	\N
0cd34720-b787-4e6f-acae-2c5df8a43def	phase2-e2e	\N	2026-08-16 01:45:59.187356+00	2026-08-16 04:45:59.187356+00	running	10000	2000	100000	\N	2026-08-16 02:45:59.200132+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 02:45:59.200132+00	10000	2000	t	\N
b85c2e97-4b25-4209-b85c-2e974b251209	phase11-e2e	\N	2026-08-16 01:44:37.141917+00	2026-08-16 03:44:37.141917+00	registration_open	1	5000	10	\N	2026-08-16 02:44:37.142638+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:44:37.142638+00	10000	2000	t	\N
0c9f7448-9b40-4a79-a194-39934e364f6d	phase2-e2e	\N	2026-08-16 01:51:49.248773+00	2026-08-16 04:51:49.248773+00	running	10000	2000	100000	\N	2026-08-16 02:51:49.275915+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 02:51:49.275915+00	10000	2000	t	\N
8abf2843-da75-453c-93ee-e0e6334a2f2f	phase2-e2e	\N	2026-08-16 01:51:42.914167+00	2026-08-16 04:51:42.914167+00	running	10000	2000	100000	\N	2026-08-16 02:51:42.926182+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 02:51:42.926182+00	10000	2000	t	\N
fb496cf5-0c1c-4296-a861-6bff97a86dfb	phase2-e2e	\N	2026-08-16 01:49:06.312035+00	2026-08-16 04:49:06.312035+00	settling	10000	2000	100000	\N	2026-08-16 02:49:06.327725+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 02:49:06.327725+00	10000	2000	t	\N
a8542a95-4aa5-4229-a854-2a954aa55229	phase11-e2e	\N	2026-08-16 01:48:32.623681+00	2026-08-16 03:48:32.623681+00	registration_open	1	5000	10	\N	2026-08-16 02:48:32.625977+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:48:32.625977+00	10000	2000	t	\N
80402090-48a4-4269-8040-209048a4d269	phase11-e2e	\N	2026-08-16 01:44:38.407062+00	2026-08-16 03:44:38.407062+00	registration_open	1	5000	10	\N	2026-08-16 02:44:38.408495+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:44:38.408495+00	10000	2000	t	\N
90c8e4f2-793c-4e0f-90c8-e4f2793c1e0f	lock-test	\N	2026-08-16 02:48:32.748047+00	2026-08-16 03:48:32.748047+00	completed	10000	5000	10	\N	2026-08-16 02:48:32.748047+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 02:48:32.748047+00	10000	1500	t	\N
b8dc6e37-9bcd-4633-b8dc-6e379bcd6633	phase11-e2e	\N	2026-08-16 01:44:55.608726+00	2026-08-16 03:44:55.608726+00	registration_open	1	5000	10	\N	2026-08-16 02:44:55.614067+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:44:55.614067+00	10000	2000	t	\N
f078bc5e-2f97-4b25-b078-bc5e2f974b25	lock-test	\N	2026-08-16 02:44:55.768423+00	2026-08-16 03:44:55.768423+00	completed	10000	5000	10	\N	2026-08-16 02:44:55.768423+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 02:44:55.768423+00	10000	1500	t	\N
2fdd5606-80c0-4948-aca1-c3c4fedc8c87	phase2-e2e	\N	2026-08-16 01:49:07.844483+00	2026-08-16 04:49:07.844483+00	running	10000	2000	100000	\N	2026-08-16 02:49:07.857291+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 02:49:07.857291+00	10000	2000	t	\N
52a2a329-50dc-4684-a7b0-5c090616c56d	phase2-e2e	\N	2026-08-16 01:48:34.353777+00	2026-08-16 04:48:34.353777+00	settling	10000	2000	100000	\N	2026-08-16 02:48:34.370078+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 02:48:34.370078+00	10000	2000	t	\N
743a1d0e-0783-41e0-b43a-1d0e0783c1e0	phase11-e2e	\N	2026-08-16 01:45:57.302735+00	2026-08-16 03:45:57.302735+00	registration_open	1	5000	10	\N	2026-08-16 02:45:57.304757+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:45:57.304757+00	10000	2000	t	\N
70b85cae-d76b-45da-b0b8-5caed76bb5da	lock-test	\N	2026-08-16 02:45:57.438115+00	2026-08-16 03:45:57.438115+00	completed	10000	5000	10	\N	2026-08-16 02:45:57.438115+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 02:45:57.438115+00	10000	1500	t	\N
bc5e2f97-cb65-4219-bc5e-2f97cb653219	phase11-e2e	\N	2026-08-16 01:51:29.112188+00	2026-08-16 03:51:29.112188+00	registration_open	1	5000	10	\N	2026-08-16 02:51:29.114452+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:51:29.114452+00	10000	2000	t	\N
05e6381b-9834-46cb-acfb-5d58cdd36755	phase2-e2e	\N	2026-08-16 01:48:34.480874+00	2026-08-16 04:48:34.480874+00	running	10000	2000	100000	\N	2026-08-16 02:48:34.492977+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 02:48:34.492977+00	10000	2000	t	\N
3098cce6-f3f9-4cfe-b098-cce6f3f9fcfe	lock-test	\N	2026-08-16 02:51:29.238053+00	2026-08-16 03:51:29.238053+00	completed	10000	5000	10	\N	2026-08-16 02:51:29.238053+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 02:51:29.238053+00	10000	1500	t	\N
a0d068b4-5aad-46eb-a0d0-68b45aadd6eb	phase11-e2e	\N	2026-08-16 01:51:41.100314+00	2026-08-16 03:51:41.100314+00	registration_open	1	5000	10	\N	2026-08-16 02:51:41.101224+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:51:41.101224+00	10000	2000	t	\N
5a7ab285-61fc-4613-8a83-de2bc5a44006	phase2-e2e	\N	2026-08-16 01:49:30.822768+00	2026-08-16 04:49:30.822768+00	settling	10000	2000	100000	\N	2026-08-16 02:49:30.839424+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 02:49:30.839424+00	10000	2000	t	\N
b45aad56-abd5-4a75-b45a-ad56abd5ea75	phase11-e2e	\N	2026-08-16 01:49:04.733315+00	2026-08-16 03:49:04.733315+00	registration_open	1	5000	10	\N	2026-08-16 02:49:04.733873+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:49:04.733873+00	10000	2000	t	\N
d068349a-4d26-4309-9068-349a4d261309	lock-test	\N	2026-08-16 02:51:41.239376+00	2026-08-16 03:51:41.239376+00	completed	10000	5000	10	\N	2026-08-16 02:51:41.239376+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 02:51:41.239376+00	10000	1500	t	\N
98cd06fc-fec9-4572-ba77-5952478dd4e7	phase2-e2e	\N	2026-08-16 01:51:30.834326+00	2026-08-16 04:51:30.834326+00	settling	10000	2000	100000	\N	2026-08-16 02:51:30.850445+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 02:51:30.850445+00	10000	2000	t	\N
28140a85-c2e1-40b8-a814-0a85c2e170b8	phase11-e2e	\N	2026-08-16 01:49:31.947736+00	2026-08-16 03:49:31.947736+00	registration_open	1	5000	10	\N	2026-08-16 02:49:31.949537+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:49:31.949537+00	10000	2000	t	\N
f4fa7dbe-5faf-476b-b4fa-7dbe5fafd76b	phase11-e2e	\N	2026-08-16 01:51:58.73112+00	2026-08-16 03:51:58.73112+00	registration_open	1	5000	10	\N	2026-08-16 02:51:58.732934+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:51:58.732934+00	10000	2000	t	\N
78f2167d-3ba6-4186-bbec-d7e2cde10fe9	phase2-e2e	\N	2026-08-16 01:51:30.963327+00	2026-08-16 04:51:30.963327+00	running	10000	2000	100000	\N	2026-08-16 02:51:30.975759+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 02:51:30.975759+00	10000	2000	t	\N
20ff9240-3690-452c-9b6b-fb0e1b8cf307	phase2-e2e	\N	2026-08-16 01:51:47.657997+00	2026-08-16 04:51:47.657997+00	settling	10000	2000	100000	\N	2026-08-16 02:51:47.687439+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 02:51:47.687439+00	10000	2000	t	\N
7cdecf3d-7746-40f8-87a2-77b6c3125787	phase2-e2e	\N	2026-08-16 01:51:42.791923+00	2026-08-16 04:51:42.791923+00	settling	10000	2000	100000	\N	2026-08-16 02:51:42.807845+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 02:51:42.807845+00	10000	2000	t	\N
9ccee7f3-f97c-4edf-9cce-e7f3f97cbedf	phase11-e2e	\N	2026-08-16 01:51:46.089605+00	2026-08-16 03:51:46.089605+00	registration_open	1	5000	10	\N	2026-08-16 02:51:46.090699+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:51:46.090699+00	10000	2000	t	\N
3781f153-e2ca-41ec-8738-eb7e0feb7cab	phase2-e2e	\N	2026-08-16 01:51:57.523982+00	2026-08-16 04:51:57.523982+00	settling	10000	2000	100000	\N	2026-08-16 02:51:57.556098+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 02:51:57.556098+00	10000	2000	t	\N
2090c8e4-f279-4cde-a090-c8e4f279bcde	phase11-e2e	\N	2026-08-16 01:52:01.909584+00	2026-08-16 03:52:01.909584+00	registration_open	1	5000	10	\N	2026-08-16 02:52:01.91131+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:52:01.91131+00	10000	2000	t	\N
341a8d46-2391-48e4-b41a-8d462391c8e4	lock-test	\N	2026-08-16 02:52:02.043994+00	2026-08-16 03:52:02.043994+00	completed	10000	5000	10	\N	2026-08-16 02:52:02.043994+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 02:52:02.043994+00	10000	1500	t	\N
944aa552-a954-4a95-944a-a552a9542a95	phase11-e2e	\N	2026-08-16 01:51:59.834308+00	2026-08-16 03:51:59.834308+00	registration_open	1	5000	10	\N	2026-08-16 02:51:59.83611+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:51:59.83611+00	10000	2000	t	\N
0880d355-0836-48b8-a96b-0caa72d00fce	phase2-e2e	\N	2026-08-16 01:52:15.374697+00	2026-08-16 04:52:15.374697+00	settling	10000	2000	100000	\N	2026-08-16 02:52:15.389466+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 02:52:15.389466+00	10000	2000	t	\N
24120984-c261-40d8-a412-0984c261b0d8	phase11-e2e	\N	2026-08-16 01:52:19.373018+00	2026-08-16 03:52:19.373018+00	registration_open	1	5000	10	\N	2026-08-16 02:52:19.37744+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	50.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:52:19.37744+00	10000	2000	t	\N
ecf67b3d-9e4f-4793-acf6-7b3d9e4f2793	lock-test	\N	2026-08-16 02:52:33.239036+00	2026-08-16 03:52:33.239036+00	completed	10000	5000	10	\N	2026-08-16 02:52:33.239036+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	3	f	standard	\N	\N	00:00:00	\N	25500	\N	0	\N	\N	\N	2026-08-16 02:52:33.239036+00	10000	1500	t	\N
36f55d6a-ca8c-42a1-be22-0187104fef3c	phase2-e2e	\N	2026-08-16 01:53:24.940811+00	2026-08-16 04:53:24.940811+00	settling	10000	2000	100000	\N	2026-08-16 02:53:24.957559+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 02:53:24.957559+00	10000	2000	t	\N
128fc769-902f-4980-946f-6c5c67b714ff	phase2-e2e	\N	2026-08-16 01:52:34.808158+00	2026-08-16 04:52:34.808158+00	settling	10000	2000	100000	\N	2026-08-16 02:52:34.823225+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	4	f	standard	\N	\N	00:00:00	\N	16000	\N	4000	\N	\N	\N	2026-08-16 02:52:34.823225+00	10000	2000	t	\N
27612d1c-8ad2-48a2-8bdb-8f9677daa150	phase2-e2e	\N	2026-08-16 01:52:34.928086+00	2026-08-16 04:52:34.928086+00	running	10000	2000	100000	\N	2026-08-16 02:52:34.938712+00	0	f	\N	f	\N	hourly	crypto	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	2	f	standard	\N	\N	00:00:00	\N	8000	\N	2000	\N	\N	\N	2026-08-16 02:52:34.938712+00	10000	2000	t	\N
5fde67db-081b-4b1d-9f3b-10e45a520fb2	phase41lite-durable	\N	2026-08-16 01:55:26.361436+00	2026-08-16 03:55:26.361436+00	completed	10000	2000	10	\N	2026-08-16 02:55:26.361436+00	0	f	\N	f	\N	hourly	mixed	\N	2	\N	f	\N	20.00	\N	\N	\N	\N	\N	\N	6	f	standard	\N	\N	00:00:00	\N	24000	\N	6000	\N	\N	\N	2026-08-16 02:55:26.361436+00	10000	2000	t	\N
\.


--
-- Data for Name: email_template_versions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.email_template_versions (id, slug, version_name, html_body, css_content, font_config, is_active, created_by, updated_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: email_templates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.email_templates (slug, subject, html_content, description, variables, updated_by, updated_at, created_at) FROM stdin;
welcome	\N	\N	Welcome email sent after registration	UserEmail, VerificationURL, DashboardURL, Lang	\N	2026-08-15 20:31:58.924962+00	2026-08-15 20:31:58.924962+00
email_verification	\N	\N	Email verification link	UserName, VerificationURL	\N	2026-08-15 20:31:58.924962+00	2026-08-15 20:31:58.924962+00
password_reset	\N	\N	Password reset link	UserName, ResetURL	\N	2026-08-15 20:31:58.924962+00	2026-08-15 20:31:58.924962+00
kyc_approved	\N	\N	KYC approval notification	UserName, ExpiresAt, DashboardURL	\N	2026-08-15 20:31:58.924962+00	2026-08-15 20:31:58.924962+00
kyc_rejected	\N	\N	KYC rejection notification	UserName, Reason, VerificationURL	\N	2026-08-15 20:31:58.924962+00	2026-08-15 20:31:58.924962+00
kyc_info_request	\N	\N	KYC additional info request	UserName, Message, VerificationURL	\N	2026-08-15 20:31:58.924962+00	2026-08-15 20:31:58.924962+00
deposit_confirmed	\N	\N	Deposit confirmation	UserName, Amount, NewBalance, Date, TransactionID, WalletURL	\N	2026-08-15 20:31:58.924962+00	2026-08-15 20:31:58.924962+00
withdrawal_approved	\N	\N	Withdrawal approved	UserName, Amount, AdminComment, DashboardURL	\N	2026-08-15 20:31:58.924962+00	2026-08-15 20:31:58.924962+00
withdrawal_rejected	\N	\N	Withdrawal rejected	UserName, Amount, Reason, DashboardURL	\N	2026-08-15 20:31:58.924962+00	2026-08-15 20:31:58.924962+00
withdrawal_processing	\N	\N	Withdrawal processing	UserName, Amount, DashboardURL	\N	2026-08-15 20:31:58.924962+00	2026-08-15 20:31:58.924962+00
withdrawal_completed	\N	\N	Withdrawal completed	UserName, Amount, DashboardURL	\N	2026-08-15 20:31:58.924962+00	2026-08-15 20:31:58.924962+00
contest_starting	\N	\N	Contest starting reminder	ContestID, ContestName, StartTime, EndTime, Duration, TimeUntilStart, StartingBalance, ParticipantCount, Symbols, TradingURL	\N	2026-08-15 20:31:58.924962+00	2026-08-15 20:31:58.924962+00
contest_cancelled	\N	\N	Contest cancellation notice	UserName, ContestID, ContestName, Reason, ScheduledStart, RefundAmount, NewBalance, ContestsURL	\N	2026-08-15 20:31:58.924962+00	2026-08-15 20:31:58.924962+00
contest_summary	\N	\N	Contest results summary	ContestID, ContestName, Status, StartDate, EndDate, TotalParticipants, TotalTrades, TotalVolume, PrizePool, Winners, Statistics, TopSymbols, GeneratedAt	\N	2026-08-15 20:31:58.924962+00	2026-08-15 20:31:58.924962+00
prize_won	\N	\N	Prize winning notification	UserName, ContestID, ContestName, FinalRank, TotalParticipants, PrizeAmount, FinalPnL, TralentScoreGain, ResultsURL	\N	2026-08-15 20:31:58.924962+00	2026-08-15 20:31:58.924962+00
daily_digest	\N	\N	Daily platform digest	Date, TotalAlerts, CriticalCount, ResolvedCount, Services, Alerts, TopErrors, GeneratedAt	\N	2026-08-15 20:31:58.924962+00	2026-08-15 20:31:58.924962+00
bug_report	\N	\N	Bug report email	Title, Message, Severity, SeverityColor, Service, Timestamp, TraceID, SpanID, StackTrace, Metadata	\N	2026-08-15 20:31:58.924962+00	2026-08-15 20:31:58.924962+00
contest_started	\N	\N	Contest started notification sent to all participants when a contest goes live	ContestName, ContestID, TradeURL, EndsAt	\N	2026-08-15 20:31:59.396339+00	2026-08-15 20:31:59.396339+00
contest_ending	\N	\N	Contest ending reminder sent to participants before a running contest ends	ContestID, ContestName, EndTime, TimeUntilEnd, Duration, StartingBalance, ParticipantCount, Symbols, TradingURL	\N	2026-08-15 20:31:59.408089+00	2026-08-15 20:31:59.408089+00
\.


--
-- Data for Name: email_verification_tokens; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.email_verification_tokens (id, user_id, token_hash, expires_at, used_at, created_at, failed_attempts) FROM stdin;
\.


--
-- Data for Name: fills_old; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.fills_old (fill_id, order_id, contest_id, user_id, symbol, side, qty, fill_price, created_at) FROM stdin;
\.


--
-- Data for Name: fills_shard_0; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.fills_shard_0 (fill_id, shard_id, order_id, contest_id, user_id, symbol, side, qty, fill_price, created_at, realized_pnl) FROM stdin;
31e70d20-8ed3-59a6-a436-b600b7ff1e10	0	11343ca0-02a5-45ff-80fd-47bed324a217	7c77ff2b-bc98-46cc-aa96-95b6e9eb3070	3a6ad88d-a188-4bf0-be1d-bf2706cdbe2a	BTC/USD	buy	1000	50050.00000000	2026-08-16 01:05:44.51583+00	0.00000000
a871b03f-2f1b-5962-9316-8b37e979789f	0	dc8fefef-4aee-42f0-a487-3ef216e375c0	9ea30eb8-6065-4457-96ba-52ac5334e0ee	863bc837-1fa3-4374-91df-3fe92a7a8694	BTC/USD	buy	1000	50050.00000000	2026-08-16 01:06:51.347673+00	0.00000000
c715132b-6fcc-5500-9277-000097a930a3	0	7fe11029-52d4-4ff7-8327-cca047f8b50b	0da7c9af-faf3-4477-8843-69936d6a47fb	81741f96-07b2-4e40-801d-470e79ffac94	BTC/USD	buy	500	42042.00000000	2026-08-16 01:06:51.498419+00	0.00000000
84331622-ef66-5ea1-a836-a767923c0d99	0	648f40ad-55ed-432e-9005-adab05f9f038	0da7c9af-faf3-4477-8843-69936d6a47fb	81741f96-07b2-4e40-801d-470e79ffac94	BTC/USD	buy	500	42142.10000000	2026-08-16 01:06:51.530579+00	0.00000000
ebb53695-dbfa-5a9f-bb5b-5b38b7e1c413	0	7c7bca2a-282f-4f27-ba2d-18e94477e5df	4263505f-6b0f-49d7-9c49-5f1008a557ea	15e34f4d-da6c-4d3f-83c8-17bd2ddb4226	BTC/USD	buy	1000	50050.00000000	2026-08-16 01:07:18.626487+00	0.00000000
ab4fc5b9-a79b-5779-bf95-7798371c48f5	0	027b96fc-c92f-4ea5-833c-6a6fc7431885	ae1aa700-2f09-497d-877c-15679fdec5f5	4af61bbb-6031-4996-9c0f-f27b00b90fb8	BTC/USD	buy	500	42042.00000000	2026-08-16 01:07:18.745968+00	0.00000000
d1593dfd-69d1-519d-9c9c-3d90d99eb5fe	0	963b5086-e930-4d4b-b04f-809b43f8dc06	ae1aa700-2f09-497d-877c-15679fdec5f5	4af61bbb-6031-4996-9c0f-f27b00b90fb8	BTC/USD	buy	500	42142.10000000	2026-08-16 01:07:18.776655+00	0.00000000
280e0092-fc9a-5f6f-a1df-c36a2d454830	0	60269b12-6f14-48b3-8336-b6a036df3fc7	8f7ba104-b9d7-47e5-b624-199c1bc385c2	7dc77ed4-d996-4eeb-a881-1f208a54c12f	BTC/USD	buy	1000	50050.00000000	2026-08-16 01:08:00.174129+00	0.00000000
4ec721b2-2564-5e65-a897-b7f8f3f987a4	0	683dfecf-20f4-484f-9cc6-27641418baa7	b96d7bd9-99e5-402e-bc3f-645a7251acbf	43efcc9b-7d09-41c4-a72c-5235ca0b3307	BTC/USD	buy	500	42042.00000000	2026-08-16 01:08:00.31506+00	0.00000000
43f3ffd2-82de-56a3-ba28-905d204881c1	0	736fac55-2c9c-4fd8-9a29-16a73261d038	b96d7bd9-99e5-402e-bc3f-645a7251acbf	43efcc9b-7d09-41c4-a72c-5235ca0b3307	BTC/USD	buy	500	42142.10000000	2026-08-16 01:08:00.343469+00	0.00000000
d87bef16-8c63-540f-8681-dd116b7df5c8	0	644974f7-1bd4-4514-9bfd-b8ba5023b171	1cfa0925-3e82-4e33-a8a7-08897bff8995	ab70e441-0b8e-4ed0-9762-13a8ac5e7c7d	BTC/USD	buy	1000	50050.00000000	2026-08-16 01:25:58.736785+00	0.00000000
2f891780-7e90-58f8-9dfa-6dac3fcd412e	0	d799e0da-9e20-4f56-a897-e80492523a97	a9e9ee08-e9c7-4796-b17c-8251365602b4	2625aa74-47bf-4793-a803-29bb9e477aed	BTC/USD	buy	500	42042.00000000	2026-08-16 01:25:58.867696+00	0.00000000
62c335d1-25ed-5725-9ca2-ba214c1945d5	0	82c8a09a-17da-472c-b689-7f40e862f050	a9e9ee08-e9c7-4796-b17c-8251365602b4	2625aa74-47bf-4793-a803-29bb9e477aed	BTC/USD	buy	500	42142.10000000	2026-08-16 01:25:58.897175+00	0.00000000
43c35750-a7b1-5a7c-8055-442255f8445b	0	ccf1d659-4dd2-49b9-bc8a-d4ff588e86ae	2f80ce1a-329d-4e78-bc49-fe62ede53b7f	4f4153e9-0d17-4a1e-92ef-ce9e7958beb2	BTC/USD	buy	1000	50050.00000000	2026-08-16 01:26:54.089498+00	0.00000000
343f5a85-e5b4-5178-8d16-2fc5b1001dbe	0	aac52c64-4bfd-40bf-b538-87ea8fc96b8e	45e3a795-edf5-4541-b89e-51cf2c71da49	eb0cfe73-a65e-405a-8e76-0717293c8143	BTC/USD	buy	500	42042.00000000	2026-08-16 01:26:54.225555+00	0.00000000
7de900b7-6215-514d-b462-c7251b8b4c83	0	09e92444-0c78-4bde-846f-dae6db5b9d0e	45e3a795-edf5-4541-b89e-51cf2c71da49	eb0cfe73-a65e-405a-8e76-0717293c8143	BTC/USD	buy	500	42142.10000000	2026-08-16 01:26:54.254719+00	0.00000000
aa3949e7-cad1-5ccf-ae1d-4a11e594342e	0	37fdd808-8afd-485d-8f89-0e7298a15a29	7ed8ef63-9fe8-450b-b6f4-ba33e7a3cef8	9e60eafe-d7b5-4ba8-9622-8a7e881717d2	BTC/USD	buy	500	42042.00000000	2026-08-16 01:27:11.286625+00	0.00000000
d5160984-2f02-556a-b7f3-bcc5c8ce527e	0	a5d88caf-ae9d-415c-b179-7ae954947eec	7ed8ef63-9fe8-450b-b6f4-ba33e7a3cef8	9e60eafe-d7b5-4ba8-9622-8a7e881717d2	BTC/USD	buy	500	42142.10000000	2026-08-16 01:27:11.315876+00	0.00000000
71700c20-37ba-5388-a028-acc87f54c359	0	6816db88-1c9b-4f63-b314-807c790aa761	a90814e3-b698-406b-b1c7-350edfb7109a	792c3ecb-0a51-4b66-b78f-411903e74aa3	BTC/USD	buy	1000	50050.00000000	2026-08-16 01:29:20.744019+00	0.00000000
a0713864-8168-59fb-88f1-73012fef5347	0	06e5a050-56ea-4bf0-aed5-2bc6700716ea	0acab9a9-ee24-4ff4-8587-fe642f0c3320	ffb61316-7d0b-4e05-a80f-d634f1b9391d	BTC/USD	buy	500	42042.00000000	2026-08-16 01:29:20.955285+00	0.00000000
4c49b756-d336-5f26-ad3a-85a939626d11	0	4582b611-914b-42ff-9f18-000c4a62449f	0acab9a9-ee24-4ff4-8587-fe642f0c3320	ffb61316-7d0b-4e05-a80f-d634f1b9391d	BTC/USD	buy	500	42142.10000000	2026-08-16 01:29:20.992939+00	0.00000000
fdb3de79-4ecc-5214-913d-3ae45c980cea	0	3daa1743-4e7a-424d-83f9-ffeb4ce5bfb8	7ee13a8f-4022-43c6-a084-fbe10763ac10	2669d7fa-c10f-4128-9395-ada433d4631e	BTC/USD	buy	1000	50050.00000000	2026-08-16 02:27:10.453168+00	0.00000000
0fe8ea96-c4c3-5df2-908f-2a2d789b7dfd	0	6a28a30d-9ab0-47a6-9023-64fbe6104d8b	1883b591-7d1a-4f42-9325-9507c69f7df8	653652cd-820e-4692-a7bb-1bb90a20936a	BTC/USD	buy	500	42042.00000000	2026-08-16 02:27:10.586589+00	0.00000000
3a1464d1-14ce-5dea-a5b9-2cd3bce2fe95	0	94efbb6f-d121-44c9-b669-3d58dcbc5472	1883b591-7d1a-4f42-9325-9507c69f7df8	653652cd-820e-4692-a7bb-1bb90a20936a	BTC/USD	buy	500	42142.10000000	2026-08-16 02:27:10.62138+00	0.00000000
0b08db5f-dcb1-58c1-b6e8-75c42705d1fa	0	9dd2fe5b-62f4-4767-97a2-530d00253783	44bfb9c9-0453-4707-ad78-b1f69903b962	c9e259ce-38b0-4b00-a3a3-9b5771d9b6de	BTC/USD	buy	1000	50050.00000000	2026-08-16 02:43:02.76229+00	0.00000000
8add37c9-201a-5e69-87d1-993383f40464	0	1f47ee42-39da-494f-8620-fe3b2192c136	1b87adda-e572-4a9e-9243-8c861bfcb234	d8bacc11-7441-48e2-9f65-7d387dd9ea26	BTC/USD	buy	500	42042.00000000	2026-08-16 02:43:02.873646+00	0.00000000
c1a51b2b-a9ae-5001-873d-15ffc5a0ceae	0	9a9ee451-85b8-4755-aae2-f535628b91e8	1b87adda-e572-4a9e-9243-8c861bfcb234	d8bacc11-7441-48e2-9f65-7d387dd9ea26	BTC/USD	buy	500	42142.10000000	2026-08-16 02:43:02.920674+00	0.00000000
dab76d46-927f-5156-98eb-3c3a9b27b8b7	0	9f05be63-80f4-462c-aa64-8faac347d024	c4c0f294-68d1-4e7b-af65-0a2410c03088	76ada4f6-10d5-4219-a405-f8d5e5b32b78	BTC/USD	buy	1000	50050.00000000	2026-08-16 02:44:02.04751+00	0.00000000
db2e3625-eef7-56ae-92c3-a9fb5260da0a	0	ef7eebd1-f75b-461e-ad32-91526c628c27	251dba09-bdf8-4e44-9d96-ab9f984dd99d	0499cba2-41b1-4fd3-b4f7-07d7e77bd094	BTC/USD	buy	500	42042.00000000	2026-08-16 02:44:02.167363+00	0.00000000
e6dcaca3-c7a9-549d-bafc-e5aa853c0340	0	b605f2c1-acc8-4555-b104-9ca7fceba08a	251dba09-bdf8-4e44-9d96-ab9f984dd99d	0499cba2-41b1-4fd3-b4f7-07d7e77bd094	BTC/USD	buy	500	42142.10000000	2026-08-16 02:44:02.222986+00	0.00000000
e5f83be1-bfbf-5a11-9a0c-3b1ccfb504ec	0	94855ff7-f59e-4b40-885c-edba575b8635	e88ecf13-0a84-4631-a816-aec1d3405c03	f6491f08-63d2-476f-873f-db5cf69c0122	BTC/USD	buy	1000	50050.00000000	2026-08-16 02:44:05.896159+00	0.00000000
91ab524e-cf3b-5746-b5eb-55e2605e37de	0	56457f76-da29-4b1d-ae0d-dfc2835c84d5	f78b4135-f060-4447-a994-080db7058160	218b00a6-dd31-4954-8850-989f8454cb72	BTC/USD	buy	1000	50050.00000000	2026-08-16 02:44:08.608357+00	0.00000000
8668f5c6-8327-5657-9a38-fe63bbf6adad	0	60fbf0a0-7267-43cc-ab18-a88a4a8f983e	694d8dc8-1ae8-4377-aa82-3e811b7fdb90	c66062f8-5699-49a8-a1bb-05a591ab9f22	BTC/USD	buy	1000	50050.00000000	2026-08-16 02:44:11.119363+00	0.00000000
041b18ae-f380-5a3a-80b8-6d6fa3162d0e	0	abd26135-2cb9-4643-8326-0c66d57db63c	c71ff9b5-d220-42f2-9f5f-053fcc08e9b4	0d4fd196-fc76-49cf-a78c-ce25c8a03022	BTC/USD	buy	1000	50050.00000000	2026-08-16 02:45:59.129215+00	0.00000000
c9506a1b-d249-5f92-8036-8acfd58e272c	0	1ce7199f-85c5-4b53-a558-49351de014ab	0cd34720-b787-4e6f-acae-2c5df8a43def	cdf8aaad-4a4f-4dc9-a592-79fe503633f7	BTC/USD	buy	500	42042.00000000	2026-08-16 02:45:59.242604+00	0.00000000
09068841-283b-5f7d-8280-a93b13071d40	0	96e90e11-03c3-46ca-a5c7-1cd0d1a005ac	0cd34720-b787-4e6f-acae-2c5df8a43def	cdf8aaad-4a4f-4dc9-a592-79fe503633f7	BTC/USD	buy	500	42142.10000000	2026-08-16 02:45:59.269825+00	0.00000000
8033ab24-adcf-5f5f-80cf-c5114098cc21	0	7888b1b3-73b6-4c35-92c7-4d8a9f279313	52a2a329-50dc-4684-a7b0-5c090616c56d	1b5063b8-9733-4563-beef-2c787c3365a9	BTC/USD	buy	1000	50050.00000000	2026-08-16 02:48:34.416649+00	0.00000000
5b9ca868-cdde-5ea7-8a64-fab20ad37623	0	f737425d-e004-4589-a190-324433fb4961	05e6381b-9834-46cb-acfb-5d58cdd36755	ddeff84e-1027-4038-8102-7ce08c9e5a94	BTC/USD	buy	500	42042.00000000	2026-08-16 02:48:34.537319+00	0.00000000
d6bc5dbb-fab7-5b57-b3e2-1cf4e7c472fb	0	c81e21a3-57c1-421d-a766-c97302a4b0e2	05e6381b-9834-46cb-acfb-5d58cdd36755	ddeff84e-1027-4038-8102-7ce08c9e5a94	BTC/USD	buy	500	42142.10000000	2026-08-16 02:48:34.566516+00	0.00000000
74d9d3cd-608b-5f41-9c3b-0e2843015c20	0	f5dca4b8-e4ed-4dd5-962d-93ef65fd9fca	fb496cf5-0c1c-4296-a861-6bff97a86dfb	f92e8766-b7d0-4dca-add5-9718456d5657	BTC/USD	buy	1000	50050.00000000	2026-08-16 02:49:06.377078+00	0.00000000
4faf1178-181f-5267-9681-e2d9eac5fcd3	0	cdbd1067-3b49-4cd5-9fe2-a704c4e3076f	2fdd5606-80c0-4948-aca1-c3c4fedc8c87	f41fb589-ceb8-47da-9ec4-4c1bb1f0e79d	BTC/USD	buy	500	42042.00000000	2026-08-16 02:49:07.900157+00	0.00000000
9ca3e004-b9c0-5e90-bdeb-1e1a6117a65c	0	a0c86708-45b1-4a2b-8f58-ecdaf23c516e	2fdd5606-80c0-4948-aca1-c3c4fedc8c87	f41fb589-ceb8-47da-9ec4-4c1bb1f0e79d	BTC/USD	buy	500	42142.10000000	2026-08-16 02:49:07.930855+00	0.00000000
eeb43b2d-d1ae-55b2-a7a1-ab7f047c6b61	0	0b269c54-8ac4-40c6-8b2a-514e6bebdf07	5a7ab285-61fc-4613-8a83-de2bc5a44006	2cf63582-501f-451b-8595-587b82b2f40a	BTC/USD	buy	1000	50050.00000000	2026-08-16 02:49:30.889505+00	0.00000000
87d85910-77bd-5667-aeec-a7595bc51a99	0	eac5e075-37ec-48e9-bc0e-4aad548001bd	98cd06fc-fec9-4572-ba77-5952478dd4e7	6c6f8218-0e00-4731-9e59-e8b8d4d61b5d	BTC/USD	buy	1000	50050.00000000	2026-08-16 02:51:30.899407+00	0.00000000
bb9860e1-65bc-51c9-a948-3f20347aba28	0	6aa21e19-ba33-4e19-bc81-f71b3452c07a	78f2167d-3ba6-4186-bbec-d7e2cde10fe9	5a5b8479-6d2f-4e8c-8064-84afe7c56e72	BTC/USD	buy	500	42042.00000000	2026-08-16 02:51:31.023591+00	0.00000000
1471b433-913c-5e02-b886-1879315c0008	0	8c245147-9cc3-485b-9aa4-ab989c7d2526	78f2167d-3ba6-4186-bbec-d7e2cde10fe9	5a5b8479-6d2f-4e8c-8064-84afe7c56e72	BTC/USD	buy	500	42142.10000000	2026-08-16 02:51:31.053029+00	0.00000000
cb5fb846-35d6-5596-8c1a-14f8fc304f17	0	6c9a7a51-c853-4bd1-9b22-dfca6b647784	7cdecf3d-7746-40f8-87a2-77b6c3125787	3f0e5a46-bb93-4f07-a561-60662dd5541a	BTC/USD	buy	1000	50050.00000000	2026-08-16 02:51:42.856071+00	0.00000000
ba43d81d-3a13-5f17-a7ac-3590ee9d3682	0	32e6123a-8a72-4166-89cf-0595db9e9574	8abf2843-da75-453c-93ee-e0e6334a2f2f	515fbee7-3bb0-4b6d-b431-22282d623cd7	BTC/USD	buy	500	42042.00000000	2026-08-16 02:51:42.96913+00	0.00000000
557604c9-a21d-5889-a182-b33bff8f56bd	0	bbce0cee-c444-4aeb-b7c8-bd56a7fffebd	8abf2843-da75-453c-93ee-e0e6334a2f2f	515fbee7-3bb0-4b6d-b431-22282d623cd7	BTC/USD	buy	500	42142.10000000	2026-08-16 02:51:42.997395+00	0.00000000
8f87c0d7-cec1-54f4-b67b-89355d6771b2	0	9c4ac926-66d7-4349-9403-c2c2a7bb5104	20ff9240-3690-452c-9b6b-fb0e1b8cf307	a14dbc0e-1b40-4539-825b-5bad255f153d	BTC/USD	buy	1000	50050.00000000	2026-08-16 02:51:47.736251+00	0.00000000
9067b67c-efc2-5f0c-85f2-9cdb3e855ece	0	025293a9-d741-483f-91ca-378c782df43b	0c9f7448-9b40-4a79-a194-39934e364f6d	5f124107-5c83-432a-80fd-8899e94f9845	BTC/USD	buy	500	42042.00000000	2026-08-16 02:51:49.320216+00	0.00000000
51ccced5-8a9c-59f4-bcc6-db43c5baa706	0	60628247-c0aa-485c-8b39-1fe5a194b725	0c9f7448-9b40-4a79-a194-39934e364f6d	5f124107-5c83-432a-80fd-8899e94f9845	BTC/USD	buy	500	42142.10000000	2026-08-16 02:51:49.350555+00	0.00000000
cc6c11a2-3b11-5b1f-a22e-7a7b108166cf	0	2d5ae6cf-6931-46af-9dd4-08c85bc35121	3781f153-e2ca-41ec-8738-eb7e0feb7cab	e19c7724-0cba-4667-8e36-c469962a9f0e	BTC/USD	buy	1000	50050.00000000	2026-08-16 02:51:57.609889+00	0.00000000
72eea78b-20a1-5878-89ca-95c69a404e48	0	9eebe24a-0d40-4afc-b8c7-6ca9d0f76e36	0880d355-0836-48b8-a96b-0caa72d00fce	649329c0-8d36-409a-b7c5-b38404828556	BTC/USD	buy	1000	50050.00000000	2026-08-16 02:52:15.436501+00	0.00000000
2c9f0132-1f41-5493-b031-7687551d9535	0	a806496a-ea83-4941-bcfc-83d72dda5b1b	128fc769-902f-4980-946f-6c5c67b714ff	f48d5513-b821-4152-a295-5efeb81d84a8	BTC/USD	buy	1000	50050.00000000	2026-08-16 02:52:34.870156+00	0.00000000
cb6854a7-81a4-57d6-b7dd-b49d3901ed7f	0	3dc0024a-8e49-496b-93ba-8d5c7e073ea6	27612d1c-8ad2-48a2-8bdb-8f9677daa150	9990da57-187a-42b2-8bda-059add25d3e1	BTC/USD	buy	500	42042.00000000	2026-08-16 02:52:34.985825+00	0.00000000
198067e2-d2c8-5f65-8f58-532a1ba7a32a	0	00559a60-6ea7-4242-862b-50b914a8f8f7	27612d1c-8ad2-48a2-8bdb-8f9677daa150	9990da57-187a-42b2-8bda-059add25d3e1	BTC/USD	buy	500	42142.10000000	2026-08-16 02:52:35.013039+00	0.00000000
a814a8d2-4a75-5237-b109-5843fd556e71	0	61284b81-0292-4291-99c6-899cf64e9cbe	36f55d6a-ca8c-42a1-be22-0187104fef3c	6791b01d-b944-4e99-b143-fb30f4f67872	BTC/USD	buy	1000	50050.00000000	2026-08-16 02:53:25.008069+00	0.00000000
6f08bab1-b5fa-51ae-87ca-7f925442ec26	0	38b6d98a-1bce-47c7-8640-8cccc58497c8	aff98c1c-3a6f-4c7c-87fc-eed863265c7e	fb2b1558-5440-43ec-ba87-73bc2a27ceb7	BTC/USD	buy	500	42042.00000000	2026-08-16 02:53:25.134466+00	0.00000000
39019589-4966-5d27-823c-9d8020221747	0	a99ed326-0af2-4640-9e94-d70d0e8e862d	aff98c1c-3a6f-4c7c-87fc-eed863265c7e	fb2b1558-5440-43ec-ba87-73bc2a27ceb7	BTC/USD	buy	500	42142.10000000	2026-08-16 02:53:25.16414+00	0.00000000
\.


--
-- Data for Name: fills_shard_1; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.fills_shard_1 (fill_id, shard_id, order_id, contest_id, user_id, symbol, side, qty, fill_price, created_at, realized_pnl) FROM stdin;
\.


--
-- Data for Name: fills_shard_2; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.fills_shard_2 (fill_id, shard_id, order_id, contest_id, user_id, symbol, side, qty, fill_price, created_at, realized_pnl) FROM stdin;
\.


--
-- Data for Name: fills_shard_3; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.fills_shard_3 (fill_id, shard_id, order_id, contest_id, user_id, symbol, side, qty, fill_price, created_at, realized_pnl) FROM stdin;
\.


--
-- Data for Name: final_rankings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.final_rankings (id, settlement_id, contest_id, user_id, rank, tied_with_count, final_score, realized_score, unrealized_score, total_trades, winning_trades, total_positions, tragge_point_contribution, created_at, win_rate) FROM stdin;
\.


--
-- Data for Name: kyc_audit_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.kyc_audit_log (id, user_id, action, actor_id, details, created_at) FROM stdin;
\.


--
-- Data for Name: kyc_documents; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.kyc_documents (id, user_id, document_type, document_number, issuing_country, issue_date, expiry_date, front_image_url, back_image_url, selfie_url, status, reviewed_at, reviewed_by, review_notes, created_at, selfie_with_doc_url) FROM stdin;
\.


--
-- Data for Name: leaderboard_snapshots; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.leaderboard_snapshots (contest_id, taken_at, payload_json) FROM stdin;
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notifications (id, user_id, type, title, message, metadata, read_at, created_at) FROM stdin;
a69bdd22-757c-46d6-bd8f-726f84c52af4	7d16b1c9-fa10-4721-9ab1-f9c6dfd7f7c0	contest_ending	Contest "phase2-e2e" ends soon!	Your contest ends in approximately 19 minutes. Close your positions before the contest ends!	{"ends_at": "2026-08-16T03:05:27Z", "contest_id": "9d147ba4-3d0a-492e-b867-19a222c7afbc", "contest_name": "phase2-e2e"}	\N	2026-08-16 02:46:27.394239+00
0eb7510b-bc64-4343-b7c1-0f9fb7b6e0d6	73724a7a-cc59-4aeb-86b5-bc997598c1ec	contest_ending	Contest "phase2-e2e" ends soon!	Your contest ends in approximately 19 minutes. Close your positions before the contest ends!	{"ends_at": "2026-08-16T03:05:27Z", "contest_id": "9d147ba4-3d0a-492e-b867-19a222c7afbc", "contest_name": "phase2-e2e"}	\N	2026-08-16 02:46:27.394239+00
530c52da-d373-456c-b8ed-b7082fb2408a	3a6ad88d-a188-4bf0-be1d-bf2706cdbe2a	contest_ending	Contest "phase2-e2e" ends soon!	Your contest ends in approximately 19 minutes. Close your positions before the contest ends!	{"ends_at": "2026-08-16T03:05:44Z", "contest_id": "7c77ff2b-bc98-46cc-aa96-95b6e9eb3070", "contest_name": "phase2-e2e"}	\N	2026-08-16 02:46:27.404535+00
d4ab6ea0-25f3-4f9a-9729-4319d66c575a	912bce1a-5da1-473c-b7cf-832f0ff39bb4	contest_ending	Contest "phase2-e2e" ends soon!	Your contest ends in approximately 19 minutes. Close your positions before the contest ends!	{"ends_at": "2026-08-16T03:05:44Z", "contest_id": "7c77ff2b-bc98-46cc-aa96-95b6e9eb3070", "contest_name": "phase2-e2e"}	\N	2026-08-16 02:46:27.404535+00
1d5f2038-5cef-484a-93de-94c6d6acfdeb	81741f96-07b2-4e40-801d-470e79ffac94	contest_ending	Contest "phase2-e2e" ends soon!	Your contest ends in approximately 19 minutes. Close your positions before the contest ends!	{"ends_at": "2026-08-16T03:06:51Z", "contest_id": "0da7c9af-faf3-4477-8843-69936d6a47fb", "contest_name": "phase2-e2e"}	\N	2026-08-16 02:47:27.384544+00
003ab40a-9518-4d70-b987-0e7596de1f09	4af61bbb-6031-4996-9c0f-f27b00b90fb8	contest_ending	Contest "phase2-e2e" ends soon!	Your contest ends in approximately 20 minutes. Close your positions before the contest ends!	{"ends_at": "2026-08-16T03:07:18Z", "contest_id": "ae1aa700-2f09-497d-877c-15679fdec5f5", "contest_name": "phase2-e2e"}	\N	2026-08-16 02:47:27.390945+00
eed1b267-d2f6-4a38-b588-5bc5aae68b9b	43efcc9b-7d09-41c4-a72c-5235ca0b3307	contest_ending	Contest "phase2-e2e" ends soon!	Your contest ends in approximately 20 minutes. Close your positions before the contest ends!	{"ends_at": "2026-08-16T03:08:00Z", "contest_id": "b96d7bd9-99e5-402e-bc3f-645a7251acbf", "contest_name": "phase2-e2e"}	\N	2026-08-16 02:48:27.382358+00
\.


--
-- Data for Name: oauth_accounts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.oauth_accounts (id, user_id, provider, provider_user_id, email, access_token, refresh_token, token_expires_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: orders_old; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.orders_old (order_id, contest_id, user_id, symbol, side, type, qty, qty_filled, limit_price, stop_price, take_profit, stop_loss, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: orders_shard_0; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.orders_shard_0 (order_id, shard_id, contest_id, user_id, symbol, side, type, qty, qty_filled, limit_price, stop_price, take_profit, stop_loss, status, created_at, updated_at) FROM stdin;
11343ca0-02a5-45ff-80fd-47bed324a217	0	7c77ff2b-bc98-46cc-aa96-95b6e9eb3070	3a6ad88d-a188-4bf0-be1d-bf2706cdbe2a	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 01:05:44.496645+00	2026-08-16 01:05:44.51583+00
dc8fefef-4aee-42f0-a487-3ef216e375c0	0	9ea30eb8-6065-4457-96ba-52ac5334e0ee	863bc837-1fa3-4374-91df-3fe92a7a8694	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 01:06:51.338388+00	2026-08-16 01:06:51.347673+00
7fe11029-52d4-4ff7-8327-cca047f8b50b	0	0da7c9af-faf3-4477-8843-69936d6a47fb	81741f96-07b2-4e40-801d-470e79ffac94	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 01:06:51.471485+00	2026-08-16 01:06:51.498419+00
648f40ad-55ed-432e-9005-adab05f9f038	0	0da7c9af-faf3-4477-8843-69936d6a47fb	81741f96-07b2-4e40-801d-470e79ffac94	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 01:06:51.52706+00	2026-08-16 01:06:51.530579+00
56bf9905-e1f0-46d8-890e-220b15945656	0	734d42df-4077-471f-9f96-2b4143ab43df	8ff79fc3-3043-4a7c-a959-4f2ba6e5e265	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:06:51.794871+00	2026-08-16 01:06:52.09477+00
7c7bca2a-282f-4f27-ba2d-18e94477e5df	0	4263505f-6b0f-49d7-9c49-5f1008a557ea	15e34f4d-da6c-4d3f-83c8-17bd2ddb4226	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 01:07:18.616291+00	2026-08-16 01:07:18.626487+00
027b96fc-c92f-4ea5-833c-6a6fc7431885	0	ae1aa700-2f09-497d-877c-15679fdec5f5	4af61bbb-6031-4996-9c0f-f27b00b90fb8	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 01:07:18.735154+00	2026-08-16 01:07:18.745968+00
963b5086-e930-4d4b-b04f-809b43f8dc06	0	ae1aa700-2f09-497d-877c-15679fdec5f5	4af61bbb-6031-4996-9c0f-f27b00b90fb8	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 01:07:18.773049+00	2026-08-16 01:07:18.776655+00
a26ca86d-0c6b-40db-be63-2e40223cb07b	0	daf27c0c-5e6d-411e-ae0d-1df1120ffdf3	d9da59d4-8084-49bd-ae23-cb99bb061a10	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:07:18.904548+00	2026-08-16 01:07:18.997005+00
60269b12-6f14-48b3-8336-b6a036df3fc7	0	8f7ba104-b9d7-47e5-b624-199c1bc385c2	7dc77ed4-d996-4eeb-a881-1f208a54c12f	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 01:08:00.163637+00	2026-08-16 01:08:00.174129+00
683dfecf-20f4-484f-9cc6-27641418baa7	0	b96d7bd9-99e5-402e-bc3f-645a7251acbf	43efcc9b-7d09-41c4-a72c-5235ca0b3307	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 01:08:00.304794+00	2026-08-16 01:08:00.31506+00
736fac55-2c9c-4fd8-9a29-16a73261d038	0	b96d7bd9-99e5-402e-bc3f-645a7251acbf	43efcc9b-7d09-41c4-a72c-5235ca0b3307	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 01:08:00.34019+00	2026-08-16 01:08:00.343469+00
f23cb788-e906-404f-9da3-aa8529a152b4	0	5db97139-a45c-4de8-9c5c-02f65ae18683	5c74f65f-c1f0-496a-9ad8-6a33bda83d30	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:08:00.891081+00	2026-08-16 01:08:01.092697+00
5fcb60cc-fa6e-4db4-aeb3-f02884191a2a	0	5db97139-a45c-4de8-9c5c-02f65ae18683	5c74f65f-c1f0-496a-9ad8-6a33bda83d30	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:08:00.891081+00	2026-08-16 01:08:01.188285+00
fb26fe0d-9283-474f-99f3-7074c8617b60	0	5db97139-a45c-4de8-9c5c-02f65ae18683	5c74f65f-c1f0-496a-9ad8-6a33bda83d30	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:08:00.895506+00	2026-08-16 01:08:01.19533+00
6616cf50-bc0f-41cc-bece-ca3e7da68898	0	5db97139-a45c-4de8-9c5c-02f65ae18683	5c74f65f-c1f0-496a-9ad8-6a33bda83d30	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:08:00.98893+00	2026-08-16 01:08:01.294047+00
9cdbd7cd-d5cc-45af-b472-8db68aeb5a9b	0	5db97139-a45c-4de8-9c5c-02f65ae18683	5c74f65f-c1f0-496a-9ad8-6a33bda83d30	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:08:00.991748+00	2026-08-16 01:08:01.298047+00
041d24ba-d700-46da-8bb6-79b5eccb8e03	0	5db97139-a45c-4de8-9c5c-02f65ae18683	5c74f65f-c1f0-496a-9ad8-6a33bda83d30	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:08:00.991149+00	2026-08-16 01:08:01.300904+00
644974f7-1bd4-4514-9bfd-b8ba5023b171	0	1cfa0925-3e82-4e33-a8a7-08897bff8995	ab70e441-0b8e-4ed0-9762-13a8ac5e7c7d	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 01:25:58.726243+00	2026-08-16 01:25:58.736785+00
d799e0da-9e20-4f56-a897-e80492523a97	0	a9e9ee08-e9c7-4796-b17c-8251365602b4	2625aa74-47bf-4793-a803-29bb9e477aed	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 01:25:58.857569+00	2026-08-16 01:25:58.867696+00
82c8a09a-17da-472c-b689-7f40e862f050	0	a9e9ee08-e9c7-4796-b17c-8251365602b4	2625aa74-47bf-4793-a803-29bb9e477aed	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 01:25:58.893853+00	2026-08-16 01:25:58.897175+00
2ef8e11b-7b76-434f-b81c-ade0d2870886	0	213e9258-cb82-4f26-9db2-b7d57f8bd0f8	e36a81e6-3639-4a93-b9c3-2f841d04211b	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:25:59.322988+00	2026-08-16 01:25:59.618192+00
86413775-46ed-4b4f-9334-e67a781c0386	0	213e9258-cb82-4f26-9db2-b7d57f8bd0f8	e36a81e6-3639-4a93-b9c3-2f841d04211b	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:25:59.42212+00	2026-08-16 01:25:59.720284+00
b3e07d97-d261-4cc0-9da7-081e0348223c	0	213e9258-cb82-4f26-9db2-b7d57f8bd0f8	e36a81e6-3639-4a93-b9c3-2f841d04211b	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:25:59.417065+00	2026-08-16 01:25:59.725543+00
c26d000d-5ae1-46fc-9964-8c725fcf7926	0	213e9258-cb82-4f26-9db2-b7d57f8bd0f8	e36a81e6-3639-4a93-b9c3-2f841d04211b	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:25:59.420413+00	2026-08-16 01:25:59.735657+00
712e6c5a-9f38-4e36-8f6a-3d2a525c184c	0	213e9258-cb82-4f26-9db2-b7d57f8bd0f8	e36a81e6-3639-4a93-b9c3-2f841d04211b	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:25:59.42211+00	2026-08-16 01:25:59.738371+00
f93ce5b1-ab79-4e28-87b5-071b5a2e471c	0	213e9258-cb82-4f26-9db2-b7d57f8bd0f8	e36a81e6-3639-4a93-b9c3-2f841d04211b	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:25:59.423938+00	2026-08-16 01:25:59.740958+00
ccf1d659-4dd2-49b9-bc8a-d4ff588e86ae	0	2f80ce1a-329d-4e78-bc49-fe62ede53b7f	4f4153e9-0d17-4a1e-92ef-ce9e7958beb2	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 01:26:54.079638+00	2026-08-16 01:26:54.089498+00
aac52c64-4bfd-40bf-b538-87ea8fc96b8e	0	45e3a795-edf5-4541-b89e-51cf2c71da49	eb0cfe73-a65e-405a-8e76-0717293c8143	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 01:26:54.216029+00	2026-08-16 01:26:54.225555+00
09e92444-0c78-4bde-846f-dae6db5b9d0e	0	45e3a795-edf5-4541-b89e-51cf2c71da49	eb0cfe73-a65e-405a-8e76-0717293c8143	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 01:26:54.25122+00	2026-08-16 01:26:54.254719+00
37fdd808-8afd-485d-8f89-0e7298a15a29	0	7ed8ef63-9fe8-450b-b6f4-ba33e7a3cef8	9e60eafe-d7b5-4ba8-9622-8a7e881717d2	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 01:27:11.276141+00	2026-08-16 01:27:11.286625+00
a5d88caf-ae9d-415c-b179-7ae954947eec	0	7ed8ef63-9fe8-450b-b6f4-ba33e7a3cef8	9e60eafe-d7b5-4ba8-9622-8a7e881717d2	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 01:27:11.312514+00	2026-08-16 01:27:11.315876+00
9a905beb-9250-4603-a260-d5b5d8aae392	0	377995fd-6611-49f1-a4f8-99d9fb83e856	f6e59b39-9e32-439a-879f-6b7683774265	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:27:11.609357+00	2026-08-16 01:27:12.114412+00
3cbbee0f-27f8-4aef-954b-ff153bf5f924	0	377995fd-6611-49f1-a4f8-99d9fb83e856	f6e59b39-9e32-439a-879f-6b7683774265	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:27:11.914135+00	2026-08-16 01:27:12.318823+00
c0acf442-f46b-4036-98b6-fa5aeb9e8b06	0	377995fd-6611-49f1-a4f8-99d9fb83e856	f6e59b39-9e32-439a-879f-6b7683774265	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:27:12.011344+00	2026-08-16 01:27:12.330189+00
8a606c5d-da79-4033-9896-0822969db108	0	377995fd-6611-49f1-a4f8-99d9fb83e856	f6e59b39-9e32-439a-879f-6b7683774265	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:27:11.920986+00	2026-08-16 01:27:12.412808+00
6816db88-1c9b-4f63-b314-807c790aa761	0	a90814e3-b698-406b-b1c7-350edfb7109a	792c3ecb-0a51-4b66-b78f-411903e74aa3	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 01:29:20.734688+00	2026-08-16 01:29:20.744019+00
06e5a050-56ea-4bf0-aed5-2bc6700716ea	0	0acab9a9-ee24-4ff4-8587-fe642f0c3320	ffb61316-7d0b-4e05-a80f-d634f1b9391d	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 01:29:20.944317+00	2026-08-16 01:29:20.955285+00
4582b611-914b-42ff-9f18-000c4a62449f	0	0acab9a9-ee24-4ff4-8587-fe642f0c3320	ffb61316-7d0b-4e05-a80f-d634f1b9391d	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 01:29:20.987445+00	2026-08-16 01:29:20.992939+00
189dbf98-fe41-44ce-979d-e9859e1bc0b7	0	a4da580b-6aa3-4a5e-b7ef-79468cf4cf1b	633e7e4b-d5a2-41c7-9a17-af7e54fd4c6c	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:29:21.499792+00	2026-08-16 01:29:21.701966+00
d2797238-5a29-4ee4-b066-eac0775ad5f9	0	a4da580b-6aa3-4a5e-b7ef-79468cf4cf1b	633e7e4b-d5a2-41c7-9a17-af7e54fd4c6c	BTC/USD	buy	market	100	0	\N	\N	\N	\N	rejected	2026-08-16 01:29:21.603589+00	2026-08-16 01:29:21.709302+00
3daa1743-4e7a-424d-83f9-ffeb4ce5bfb8	0	7ee13a8f-4022-43c6-a084-fbe10763ac10	2669d7fa-c10f-4128-9395-ada433d4631e	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 02:27:10.441582+00	2026-08-16 02:27:10.453168+00
6a28a30d-9ab0-47a6-9023-64fbe6104d8b	0	1883b591-7d1a-4f42-9325-9507c69f7df8	653652cd-820e-4692-a7bb-1bb90a20936a	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:27:10.575741+00	2026-08-16 02:27:10.586589+00
94efbb6f-d121-44c9-b669-3d58dcbc5472	0	1883b591-7d1a-4f42-9325-9507c69f7df8	653652cd-820e-4692-a7bb-1bb90a20936a	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:27:10.61687+00	2026-08-16 02:27:10.62138+00
9dd2fe5b-62f4-4767-97a2-530d00253783	0	44bfb9c9-0453-4707-ad78-b1f69903b962	c9e259ce-38b0-4b00-a3a3-9b5771d9b6de	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 02:43:02.752829+00	2026-08-16 02:43:02.76229+00
1f47ee42-39da-494f-8620-fe3b2192c136	0	1b87adda-e572-4a9e-9243-8c861bfcb234	d8bacc11-7441-48e2-9f65-7d387dd9ea26	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:43:02.864261+00	2026-08-16 02:43:02.873646+00
9a9ee451-85b8-4755-aae2-f535628b91e8	0	1b87adda-e572-4a9e-9243-8c861bfcb234	d8bacc11-7441-48e2-9f65-7d387dd9ea26	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:43:02.917138+00	2026-08-16 02:43:02.920674+00
9f05be63-80f4-462c-aa64-8faac347d024	0	c4c0f294-68d1-4e7b-af65-0a2410c03088	76ada4f6-10d5-4219-a405-f8d5e5b32b78	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 02:44:02.036537+00	2026-08-16 02:44:02.04751+00
ef7eebd1-f75b-461e-ad32-91526c628c27	0	251dba09-bdf8-4e44-9d96-ab9f984dd99d	0499cba2-41b1-4fd3-b4f7-07d7e77bd094	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:44:02.157323+00	2026-08-16 02:44:02.167363+00
b605f2c1-acc8-4555-b104-9ca7fceba08a	0	251dba09-bdf8-4e44-9d96-ab9f984dd99d	0499cba2-41b1-4fd3-b4f7-07d7e77bd094	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:44:02.219284+00	2026-08-16 02:44:02.222986+00
94855ff7-f59e-4b40-885c-edba575b8635	0	e88ecf13-0a84-4631-a816-aec1d3405c03	f6491f08-63d2-476f-873f-db5cf69c0122	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 02:44:05.873351+00	2026-08-16 02:44:05.896159+00
56457f76-da29-4b1d-ae0d-dfc2835c84d5	0	f78b4135-f060-4447-a994-080db7058160	218b00a6-dd31-4954-8850-989f8454cb72	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 02:44:08.599038+00	2026-08-16 02:44:08.608357+00
60fbf0a0-7267-43cc-ab18-a88a4a8f983e	0	694d8dc8-1ae8-4377-aa82-3e811b7fdb90	c66062f8-5699-49a8-a1bb-05a591ab9f22	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 02:44:11.109517+00	2026-08-16 02:44:11.119363+00
7888b1b3-73b6-4c35-92c7-4d8a9f279313	0	52a2a329-50dc-4684-a7b0-5c090616c56d	1b5063b8-9733-4563-beef-2c787c3365a9	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 02:48:34.407303+00	2026-08-16 02:48:34.416649+00
abd26135-2cb9-4643-8326-0c66d57db63c	0	c71ff9b5-d220-42f2-9f5f-053fcc08e9b4	0d4fd196-fc76-49cf-a78c-ce25c8a03022	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 02:45:59.118759+00	2026-08-16 02:45:59.129215+00
1ce7199f-85c5-4b53-a558-49351de014ab	0	0cd34720-b787-4e6f-acae-2c5df8a43def	cdf8aaad-4a4f-4dc9-a592-79fe503633f7	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:45:59.233558+00	2026-08-16 02:45:59.242604+00
f737425d-e004-4589-a190-324433fb4961	0	05e6381b-9834-46cb-acfb-5d58cdd36755	ddeff84e-1027-4038-8102-7ce08c9e5a94	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:48:34.527115+00	2026-08-16 02:48:34.537319+00
96e90e11-03c3-46ca-a5c7-1cd0d1a005ac	0	0cd34720-b787-4e6f-acae-2c5df8a43def	cdf8aaad-4a4f-4dc9-a592-79fe503633f7	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:45:59.266378+00	2026-08-16 02:45:59.269825+00
c81e21a3-57c1-421d-a766-c97302a4b0e2	0	05e6381b-9834-46cb-acfb-5d58cdd36755	ddeff84e-1027-4038-8102-7ce08c9e5a94	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:48:34.563126+00	2026-08-16 02:48:34.566516+00
f5dca4b8-e4ed-4dd5-962d-93ef65fd9fca	0	fb496cf5-0c1c-4296-a861-6bff97a86dfb	f92e8766-b7d0-4dca-add5-9718456d5657	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 02:49:06.367692+00	2026-08-16 02:49:06.377078+00
cdbd1067-3b49-4cd5-9fe2-a704c4e3076f	0	2fdd5606-80c0-4948-aca1-c3c4fedc8c87	f41fb589-ceb8-47da-9ec4-4c1bb1f0e79d	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:49:07.890739+00	2026-08-16 02:49:07.900157+00
a0c86708-45b1-4a2b-8f58-ecdaf23c516e	0	2fdd5606-80c0-4948-aca1-c3c4fedc8c87	f41fb589-ceb8-47da-9ec4-4c1bb1f0e79d	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:49:07.927175+00	2026-08-16 02:49:07.930855+00
0b269c54-8ac4-40c6-8b2a-514e6bebdf07	0	5a7ab285-61fc-4613-8a83-de2bc5a44006	2cf63582-501f-451b-8595-587b82b2f40a	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 02:49:30.878321+00	2026-08-16 02:49:30.889505+00
eac5e075-37ec-48e9-bc0e-4aad548001bd	0	98cd06fc-fec9-4572-ba77-5952478dd4e7	6c6f8218-0e00-4731-9e59-e8b8d4d61b5d	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 02:51:30.88956+00	2026-08-16 02:51:30.899407+00
6aa21e19-ba33-4e19-bc81-f71b3452c07a	0	78f2167d-3ba6-4186-bbec-d7e2cde10fe9	5a5b8479-6d2f-4e8c-8064-84afe7c56e72	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:51:31.013891+00	2026-08-16 02:51:31.023591+00
8c245147-9cc3-485b-9aa4-ab989c7d2526	0	78f2167d-3ba6-4186-bbec-d7e2cde10fe9	5a5b8479-6d2f-4e8c-8064-84afe7c56e72	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:51:31.049544+00	2026-08-16 02:51:31.053029+00
6c9a7a51-c853-4bd1-9b22-dfca6b647784	0	7cdecf3d-7746-40f8-87a2-77b6c3125787	3f0e5a46-bb93-4f07-a561-60662dd5541a	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 02:51:42.847129+00	2026-08-16 02:51:42.856071+00
32e6123a-8a72-4166-89cf-0595db9e9574	0	8abf2843-da75-453c-93ee-e0e6334a2f2f	515fbee7-3bb0-4b6d-b431-22282d623cd7	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:51:42.960041+00	2026-08-16 02:51:42.96913+00
bbce0cee-c444-4aeb-b7c8-bd56a7fffebd	0	8abf2843-da75-453c-93ee-e0e6334a2f2f	515fbee7-3bb0-4b6d-b431-22282d623cd7	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:51:42.994027+00	2026-08-16 02:51:42.997395+00
9c4ac926-66d7-4349-9403-c2c2a7bb5104	0	20ff9240-3690-452c-9b6b-fb0e1b8cf307	a14dbc0e-1b40-4539-825b-5bad255f153d	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 02:51:47.725981+00	2026-08-16 02:51:47.736251+00
025293a9-d741-483f-91ca-378c782df43b	0	0c9f7448-9b40-4a79-a194-39934e364f6d	5f124107-5c83-432a-80fd-8899e94f9845	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:51:49.310853+00	2026-08-16 02:51:49.320216+00
60628247-c0aa-485c-8b39-1fe5a194b725	0	0c9f7448-9b40-4a79-a194-39934e364f6d	5f124107-5c83-432a-80fd-8899e94f9845	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:51:49.347157+00	2026-08-16 02:51:49.350555+00
2d5ae6cf-6931-46af-9dd4-08c85bc35121	0	3781f153-e2ca-41ec-8738-eb7e0feb7cab	e19c7724-0cba-4667-8e36-c469962a9f0e	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 02:51:57.598296+00	2026-08-16 02:51:57.609889+00
9eebe24a-0d40-4afc-b8c7-6ca9d0f76e36	0	0880d355-0836-48b8-a96b-0caa72d00fce	649329c0-8d36-409a-b7c5-b38404828556	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 02:52:15.427376+00	2026-08-16 02:52:15.436501+00
a806496a-ea83-4941-bcfc-83d72dda5b1b	0	128fc769-902f-4980-946f-6c5c67b714ff	f48d5513-b821-4152-a295-5efeb81d84a8	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 02:52:34.860719+00	2026-08-16 02:52:34.870156+00
3dc0024a-8e49-496b-93ba-8d5c7e073ea6	0	27612d1c-8ad2-48a2-8bdb-8f9677daa150	9990da57-187a-42b2-8bda-059add25d3e1	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:52:34.976644+00	2026-08-16 02:52:34.985825+00
00559a60-6ea7-4242-862b-50b914a8f8f7	0	27612d1c-8ad2-48a2-8bdb-8f9677daa150	9990da57-187a-42b2-8bda-059add25d3e1	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:52:35.00931+00	2026-08-16 02:52:35.013039+00
61284b81-0292-4291-99c6-899cf64e9cbe	0	36f55d6a-ca8c-42a1-be22-0187104fef3c	6791b01d-b944-4e99-b143-fb30f4f67872	BTC/USD	buy	market	1000	1000	\N	\N	\N	\N	filled	2026-08-16 02:53:24.995615+00	2026-08-16 02:53:25.008069+00
38b6d98a-1bce-47c7-8640-8cccc58497c8	0	aff98c1c-3a6f-4c7c-87fc-eed863265c7e	fb2b1558-5440-43ec-ba87-73bc2a27ceb7	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:53:25.123744+00	2026-08-16 02:53:25.134466+00
a99ed326-0af2-4640-9e94-d70d0e8e862d	0	aff98c1c-3a6f-4c7c-87fc-eed863265c7e	fb2b1558-5440-43ec-ba87-73bc2a27ceb7	BTC/USD	buy	market	500	500	\N	\N	\N	\N	filled	2026-08-16 02:53:25.160513+00	2026-08-16 02:53:25.16414+00
\.


--
-- Data for Name: orders_shard_1; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.orders_shard_1 (order_id, shard_id, contest_id, user_id, symbol, side, type, qty, qty_filled, limit_price, stop_price, take_profit, stop_loss, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: orders_shard_2; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.orders_shard_2 (order_id, shard_id, contest_id, user_id, symbol, side, type, qty, qty_filled, limit_price, stop_price, take_profit, stop_loss, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: orders_shard_3; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.orders_shard_3 (order_id, shard_id, contest_id, user_id, symbol, side, type, qty, qty_filled, limit_price, stop_price, take_profit, stop_loss, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: otp_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.otp_logs (id, phone, sent_at, verified_at, ip_address, user_agent) FROM stdin;
\.


--
-- Data for Name: password_reset_codes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.password_reset_codes (id, user_id, code_hash, channel, destination, expires_at, used_at, attempts, created_at) FROM stdin;
\.


--
-- Data for Name: password_reset_tokens; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.password_reset_tokens (id, user_id, token_hash, expires_at, used_at, created_at) FROM stdin;
\.


--
-- Data for Name: payment_intents; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.payment_intents (id, user_id, provider, provider_payment_id, amount_cents, currency, status, metadata_json, created_at, updated_at, completed_at) FROM stdin;
\.


--
-- Data for Name: payouts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.payouts (id, user_id, amount_cents, currency, status, provider, provider_payout_id, destination_type, destination_info_json, metadata_json, created_at, updated_at, completed_at, admin_comment, reviewed_by, reviewed_at, idempotency_key, transaction_id) FROM stdin;
\.


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.permissions (id, name, description, created_at) FROM stdin;
1	users.view	View user list and details	2026-08-15 20:31:58.806397+00
2	users.edit	Edit user profiles and status	2026-08-15 20:31:58.806397+00
3	users.wallet.charge	Charge user wallets	2026-08-15 20:31:58.806397+00
4	contests.view	View contests	2026-08-15 20:31:58.806397+00
5	contests.create	Create and edit contests	2026-08-15 20:31:58.806397+00
6	contests.manage	Start, stop, cancel contests	2026-08-15 20:31:58.806397+00
7	kyc.view	View KYC submissions	2026-08-15 20:31:58.806397+00
8	kyc.review	Approve/reject KYC	2026-08-15 20:31:58.806397+00
9	withdrawals.view	View withdrawal requests	2026-08-15 20:31:58.806397+00
10	withdrawals.manage	Approve/reject withdrawals	2026-08-15 20:31:58.806397+00
11	audit.view	View audit logs	2026-08-15 20:31:58.806397+00
12	shards.view	View shard status	2026-08-15 20:31:58.806397+00
13	settings.manage	Manage system settings	2026-08-15 20:31:58.806397+00
14	affiliate.manage	Manage affiliate program	2026-08-15 20:31:58.806397+00
15	financial.view	View financial reports	2026-08-15 20:31:58.806397+00
16	symbols.view	View symbol list and details	2026-08-15 20:31:58.866375+00
17	symbols.manage	Create, edit, and manage symbols	2026-08-15 20:31:58.866375+00
\.


--
-- Data for Name: positions_old; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.positions_old (position_id, contest_id, user_id, symbol, side, qty_open, entry_price, qty_used, realized_score, opened_at, closed_at) FROM stdin;
\.


--
-- Data for Name: positions_shard_0; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.positions_shard_0 (position_id, shard_id, contest_id, user_id, symbol, side, qty_open, entry_price, qty_used, realized_score, opened_at, closed_at, take_profit, stop_loss) FROM stdin;
d226c0ad-9910-4174-a8e7-d3cc1cfaba3a	0	7c77ff2b-bc98-46cc-aa96-95b6e9eb3070	3a6ad88d-a188-4bf0-be1d-bf2706cdbe2a	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 01:05:44.51583+00	\N	\N	\N
fd638d91-b2f4-4f56-b411-d19ea571df4e	0	9ea30eb8-6065-4457-96ba-52ac5334e0ee	863bc837-1fa3-4374-91df-3fe92a7a8694	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 01:06:51.347673+00	2026-08-16 01:06:51.379355+00	\N	\N
062bf40c-6e4f-4412-b004-b72e56e8b0a0	0	0da7c9af-faf3-4477-8843-69936d6a47fb	81741f96-07b2-4e40-801d-470e79ffac94	BTC/USD	long	1000	42092.05000000	1000	0.00000000	2026-08-16 01:06:51.498419+00	\N	\N	\N
bdb92ebc-afe2-4328-a700-e973c01c7f89	0	4263505f-6b0f-49d7-9c49-5f1008a557ea	15e34f4d-da6c-4d3f-83c8-17bd2ddb4226	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 01:07:18.626487+00	2026-08-16 01:07:18.655041+00	\N	\N
19a9dd47-c09e-482a-9154-46da6425b01a	0	ae1aa700-2f09-497d-877c-15679fdec5f5	4af61bbb-6031-4996-9c0f-f27b00b90fb8	BTC/USD	long	1000	42092.05000000	1000	0.00000000	2026-08-16 01:07:18.745968+00	\N	\N	\N
06352e84-8684-4e8a-a0d8-355b68600d30	0	8f7ba104-b9d7-47e5-b624-199c1bc385c2	7dc77ed4-d996-4eeb-a881-1f208a54c12f	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 01:08:00.174129+00	2026-08-16 01:08:00.214744+00	\N	\N
37073efd-ac55-4609-929b-210effcad735	0	b96d7bd9-99e5-402e-bc3f-645a7251acbf	43efcc9b-7d09-41c4-a72c-5235ca0b3307	BTC/USD	long	1000	42092.05000000	1000	0.00000000	2026-08-16 01:08:00.31506+00	\N	\N	\N
4e35676d-b022-481c-9219-16f113baadab	0	1cfa0925-3e82-4e33-a8a7-08897bff8995	ab70e441-0b8e-4ed0-9762-13a8ac5e7c7d	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 01:25:58.736785+00	2026-08-16 01:25:58.763859+00	\N	\N
b4148271-cc3c-4b25-b8a7-1638b73b1358	0	a9e9ee08-e9c7-4796-b17c-8251365602b4	2625aa74-47bf-4793-a803-29bb9e477aed	BTC/USD	long	1000	42092.05000000	1000	0.00000000	2026-08-16 01:25:58.867696+00	\N	\N	\N
ad4cc990-597c-46bc-8903-c72092954419	0	2f80ce1a-329d-4e78-bc49-fe62ede53b7f	4f4153e9-0d17-4a1e-92ef-ce9e7958beb2	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 01:26:54.089498+00	2026-08-16 01:26:54.11936+00	\N	\N
db4f091f-12ca-486c-84e4-aa7897254a91	0	45e3a795-edf5-4541-b89e-51cf2c71da49	eb0cfe73-a65e-405a-8e76-0717293c8143	BTC/USD	long	1000	42092.05000000	1000	0.00000000	2026-08-16 01:26:54.225555+00	\N	\N	\N
5b5fd2f5-0b99-447e-bede-cf7006a48fbd	0	7ed8ef63-9fe8-450b-b6f4-ba33e7a3cef8	9e60eafe-d7b5-4ba8-9622-8a7e881717d2	BTC/USD	long	1000	42092.05000000	1000	0.00000000	2026-08-16 01:27:11.286625+00	\N	\N	\N
e5295adc-a2b1-467d-8584-101615257bd3	0	a90814e3-b698-406b-b1c7-350edfb7109a	792c3ecb-0a51-4b66-b78f-411903e74aa3	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 01:29:20.744019+00	2026-08-16 01:29:20.827283+00	\N	\N
1bf39518-62ca-4bee-adeb-38f53252c154	0	0acab9a9-ee24-4ff4-8587-fe642f0c3320	ffb61316-7d0b-4e05-a80f-d634f1b9391d	BTC/USD	long	1000	42092.05000000	1000	0.00000000	2026-08-16 01:29:20.955285+00	\N	\N	\N
17acaf78-4f90-4a9a-ad03-87dbd7d6c8e5	0	7ee13a8f-4022-43c6-a084-fbe10763ac10	2669d7fa-c10f-4128-9395-ada433d4631e	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 02:27:10.453168+00	2026-08-16 02:27:10.483727+00	\N	\N
4fd3d73a-3ce8-444b-8367-ee18264b38b2	0	1883b591-7d1a-4f42-9325-9507c69f7df8	653652cd-820e-4692-a7bb-1bb90a20936a	BTC/USD	long	1000	42092.05000000	1000	0.00000000	2026-08-16 02:27:10.586589+00	\N	\N	\N
a914b48b-3ae3-4e13-bbfc-3fb4f08a0009	0	44bfb9c9-0453-4707-ad78-b1f69903b962	c9e259ce-38b0-4b00-a3a3-9b5771d9b6de	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 02:43:02.76229+00	2026-08-16 02:43:02.788059+00	\N	\N
a7e6e96f-0509-4243-b162-591dff5418bb	0	1b87adda-e572-4a9e-9243-8c861bfcb234	d8bacc11-7441-48e2-9f65-7d387dd9ea26	BTC/USD	long	1000	42092.05000000	1000	0.00000000	2026-08-16 02:43:02.873646+00	\N	\N	\N
0b695e08-6177-403f-98db-e99d28eefe04	0	c4c0f294-68d1-4e7b-af65-0a2410c03088	76ada4f6-10d5-4219-a405-f8d5e5b32b78	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 02:44:02.04751+00	2026-08-16 02:44:02.074581+00	\N	\N
7d2e6ff5-ccdd-423f-8de3-ad789c9785ec	0	251dba09-bdf8-4e44-9d96-ab9f984dd99d	0499cba2-41b1-4fd3-b4f7-07d7e77bd094	BTC/USD	long	1000	42092.05000000	1000	0.00000000	2026-08-16 02:44:02.167363+00	\N	\N	\N
d1627555-35eb-425f-8041-620b6fa9f3eb	0	e88ecf13-0a84-4631-a816-aec1d3405c03	f6491f08-63d2-476f-873f-db5cf69c0122	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 02:44:05.896159+00	2026-08-16 02:44:05.923469+00	\N	\N
98cbe43b-ca81-4a45-a3e7-b9bf1859ed7b	0	f78b4135-f060-4447-a994-080db7058160	218b00a6-dd31-4954-8850-989f8454cb72	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 02:44:08.608357+00	2026-08-16 02:44:08.632947+00	\N	\N
88831ec2-587a-4dde-95c9-18d99ba3faa9	0	694d8dc8-1ae8-4377-aa82-3e811b7fdb90	c66062f8-5699-49a8-a1bb-05a591ab9f22	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 02:44:11.119363+00	2026-08-16 02:44:11.145274+00	\N	\N
5f4fd9b6-c0ce-48c5-8882-9f980713ab27	0	c71ff9b5-d220-42f2-9f5f-053fcc08e9b4	0d4fd196-fc76-49cf-a78c-ce25c8a03022	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 02:45:59.129215+00	2026-08-16 02:45:59.155893+00	\N	\N
7de73de5-b910-4d2e-a156-a0c5da649112	0	0cd34720-b787-4e6f-acae-2c5df8a43def	cdf8aaad-4a4f-4dc9-a592-79fe503633f7	BTC/USD	long	1000	42092.05000000	1000	0.00000000	2026-08-16 02:45:59.242604+00	\N	\N	\N
24bc8136-26a3-4818-a42e-1c8c9b4ef450	0	52a2a329-50dc-4684-a7b0-5c090616c56d	1b5063b8-9733-4563-beef-2c787c3365a9	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 02:48:34.416649+00	2026-08-16 02:48:34.443316+00	\N	\N
0440b2d5-a517-4d3f-9cc9-c805c0de0fb7	0	05e6381b-9834-46cb-acfb-5d58cdd36755	ddeff84e-1027-4038-8102-7ce08c9e5a94	BTC/USD	long	1000	42092.05000000	1000	0.00000000	2026-08-16 02:48:34.537319+00	\N	\N	\N
9850a7d6-3ea2-4205-af6b-ba9660f45788	0	fb496cf5-0c1c-4296-a861-6bff97a86dfb	f92e8766-b7d0-4dca-add5-9718456d5657	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 02:49:06.377078+00	2026-08-16 02:49:06.4036+00	\N	\N
6d05a668-aa9e-4ce0-85f8-b86ec2f5f9a6	0	2fdd5606-80c0-4948-aca1-c3c4fedc8c87	f41fb589-ceb8-47da-9ec4-4c1bb1f0e79d	BTC/USD	long	1000	42092.05000000	1000	0.00000000	2026-08-16 02:49:07.900157+00	\N	\N	\N
0d4727a6-3b07-4dfe-a5db-a0a132d38f9b	0	5a7ab285-61fc-4613-8a83-de2bc5a44006	2cf63582-501f-451b-8595-587b82b2f40a	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 02:49:30.889505+00	2026-08-16 02:49:30.91591+00	\N	\N
a1975004-90dc-432c-9bc5-795305c1c137	0	98cd06fc-fec9-4572-ba77-5952478dd4e7	6c6f8218-0e00-4731-9e59-e8b8d4d61b5d	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 02:51:30.899407+00	2026-08-16 02:51:30.932884+00	\N	\N
dd5e7382-f2da-48ee-abe1-e2a05fbc1057	0	78f2167d-3ba6-4186-bbec-d7e2cde10fe9	5a5b8479-6d2f-4e8c-8064-84afe7c56e72	BTC/USD	long	1000	42092.05000000	1000	0.00000000	2026-08-16 02:51:31.023591+00	\N	\N	\N
0cabdaf4-be2b-42b7-b00d-df20ddfb5546	0	7cdecf3d-7746-40f8-87a2-77b6c3125787	3f0e5a46-bb93-4f07-a561-60662dd5541a	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 02:51:42.856071+00	2026-08-16 02:51:42.881876+00	\N	\N
1a44eaa5-36a1-484d-93fd-f46b8f961f98	0	8abf2843-da75-453c-93ee-e0e6334a2f2f	515fbee7-3bb0-4b6d-b431-22282d623cd7	BTC/USD	long	1000	42092.05000000	1000	0.00000000	2026-08-16 02:51:42.96913+00	\N	\N	\N
93f08619-e663-4047-807b-d525939b38ef	0	20ff9240-3690-452c-9b6b-fb0e1b8cf307	a14dbc0e-1b40-4539-825b-5bad255f153d	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 02:51:47.736251+00	2026-08-16 02:51:47.763174+00	\N	\N
becd03ee-c9fe-47ad-b72b-12fa9055df1c	0	0c9f7448-9b40-4a79-a194-39934e364f6d	5f124107-5c83-432a-80fd-8899e94f9845	BTC/USD	long	1000	42092.05000000	1000	0.00000000	2026-08-16 02:51:49.320216+00	\N	\N	\N
4fe9f9f2-d1bf-42ef-849a-ad50c8c834eb	0	3781f153-e2ca-41ec-8738-eb7e0feb7cab	e19c7724-0cba-4667-8e36-c469962a9f0e	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 02:51:57.609889+00	2026-08-16 02:51:57.637158+00	\N	\N
ff2673c7-0e57-4e95-9980-feefbca3654c	0	0880d355-0836-48b8-a96b-0caa72d00fce	649329c0-8d36-409a-b7c5-b38404828556	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 02:52:15.436501+00	2026-08-16 02:52:15.463184+00	\N	\N
4a907727-08e3-4f4c-a44e-8d05fe6b3376	0	128fc769-902f-4980-946f-6c5c67b714ff	f48d5513-b821-4152-a295-5efeb81d84a8	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 02:52:34.870156+00	2026-08-16 02:52:34.896067+00	\N	\N
59931e26-8783-43b6-87b1-6387880f80f1	0	27612d1c-8ad2-48a2-8bdb-8f9677daa150	9990da57-187a-42b2-8bda-059add25d3e1	BTC/USD	long	1000	42092.05000000	1000	0.00000000	2026-08-16 02:52:34.985825+00	\N	\N	\N
1257bb6f-9b2e-47e3-b112-a1a7c6548b42	0	36f55d6a-ca8c-42a1-be22-0187104fef3c	6791b01d-b944-4e99-b143-fb30f4f67872	BTC/USD	long	1000	50050.00000000	1000	0.00000000	2026-08-16 02:53:25.008069+00	2026-08-16 02:53:25.035353+00	\N	\N
31354d11-94bf-426f-9bf5-e7604041c512	0	aff98c1c-3a6f-4c7c-87fc-eed863265c7e	fb2b1558-5440-43ec-ba87-73bc2a27ceb7	BTC/USD	long	1000	42092.05000000	1000	0.00000000	2026-08-16 02:53:25.134466+00	\N	\N	\N
\.


--
-- Data for Name: positions_shard_1; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.positions_shard_1 (position_id, shard_id, contest_id, user_id, symbol, side, qty_open, entry_price, qty_used, realized_score, opened_at, closed_at, take_profit, stop_loss) FROM stdin;
\.


--
-- Data for Name: positions_shard_2; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.positions_shard_2 (position_id, shard_id, contest_id, user_id, symbol, side, qty_open, entry_price, qty_used, realized_score, opened_at, closed_at, take_profit, stop_loss) FROM stdin;
\.


--
-- Data for Name: positions_shard_3; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.positions_shard_3 (position_id, shard_id, contest_id, user_id, symbol, side, qty_open, entry_price, qty_used, realized_score, opened_at, closed_at, take_profit, stop_loss) FROM stdin;
\.


--
-- Data for Name: predefined_avatars; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.predefined_avatars (id, slug, display_name, category, bg_color, image_path, sort_order, is_active, created_at, updated_at) FROM stdin;
1e2f3e50-3690-4e79-b7dd-e73110f83327	shark	Business Shark	animal	#1e3a5f	/avatars/shark.png	1	t	2026-08-15 20:32:00.080993+00	2026-08-15 20:32:00.080993+00
8731fd93-e59a-484f-b6a2-b42a95e9f926	monkey	Diamond Monkey	animal	#4a3728	/avatars/monkey.png	2	t	2026-08-15 20:32:00.080993+00	2026-08-15 20:32:00.080993+00
448e67d7-d834-4147-a426-803449ea4e96	snake	Viper	animal	#2d4a2d	/avatars/snake.png	3	t	2026-08-15 20:32:00.080993+00	2026-08-15 20:32:00.080993+00
8ae1fc76-46ae-45f3-97af-431cc3be8103	lion	King Lion	animal	#8b6914	/avatars/lion.png	4	t	2026-08-15 20:32:00.080993+00	2026-08-15 20:32:00.080993+00
7429dc5b-fff2-4556-81f9-8fd678c32252	dragon	Dragon	animal	#4a1a1a	/avatars/dragon.png	5	t	2026-08-15 20:32:00.080993+00	2026-08-15 20:32:00.080993+00
2378b0e5-ef63-481e-892a-edcc56ed7ea2	panda	Tech Panda	animal	#2d2d2d	/avatars/panda.png	6	t	2026-08-15 20:32:00.080993+00	2026-08-15 20:32:00.080993+00
d6cb42db-9857-4b14-b34a-b740eb9a4124	eagle	Cyber Eagle	animal	#1a1a3a	/avatars/eagle.png	7	t	2026-08-15 20:32:00.080993+00	2026-08-15 20:32:00.080993+00
8696893a-f265-45aa-80d3-bb9bb5b1b320	phoenix	Phoenix	special	#4a2a0a	/avatars/phoenix.png	8	t	2026-08-15 20:32:00.080993+00	2026-08-15 20:32:00.080993+00
85028502-fa82-4c08-874a-b0e57a634f11	wolf	Shadow Wolf	animal	#2a2a3a	/avatars/wolf.png	9	t	2026-08-15 20:32:00.080993+00	2026-08-15 20:32:00.080993+00
877a3f64-1cab-4e8d-b265-39260b338fbf	samurai	Samurai	character	#3a1a1a	/avatars/samurai.png	10	t	2026-08-15 20:32:00.080993+00	2026-08-15 20:32:00.080993+00
2fc82658-a020-4adc-9c6c-65b9f1231cb1	bull	Bull	animal	#3a2a1a	/avatars/bull.png	11	t	2026-08-15 20:32:00.080993+00	2026-08-15 20:32:00.080993+00
66b6da0d-b37c-4177-acf4-fee4ea2d77a8	cat	VR Cat	animal	#2a3a4a	/avatars/cat.png	12	t	2026-08-15 20:32:00.080993+00	2026-08-15 20:32:00.080993+00
16b85a7a-0bee-4eda-bdc8-dad9344312ca	bear	Bear	animal	#4a3a2a	/avatars/bear.png	13	t	2026-08-15 20:32:00.080993+00	2026-08-15 20:32:00.080993+00
a9fb48c0-f775-4f22-832d-95ea6ca688ac	fox	Smart Fox	animal	#5a3a1a	/avatars/fox.png	14	t	2026-08-15 20:32:00.080993+00	2026-08-15 20:32:00.080993+00
de9f20a6-ec43-433c-b854-82ce07617e75	owl	Night Owl	animal	#1a2a3a	/avatars/owl.png	15	t	2026-08-15 20:32:00.080993+00	2026-08-15 20:32:00.080993+00
57bb294e-ce1f-41db-965c-362cec60b512	robot	Trading Bot	special	#2a3a4a	/avatars/robot.png	16	t	2026-08-15 20:32:00.080993+00	2026-08-15 20:32:00.080993+00
\.


--
-- Data for Name: privilege_audit_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.privilege_audit_log (id, event_time, username, action, details) FROM stdin;
\.


--
-- Data for Name: prize_distributions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.prize_distributions (id, settlement_id, contest_id, user_id, rank, final_score, prize_amount_cents, prize_percentage, status, credited_at, error_message, ledger_entry_id, created_at) FROM stdin;
876472ac-d50b-4034-b368-6aca9a54929f	b9818612-ae2e-4ef1-bbd4-c2fffb63301b	c864b259-2c96-4b65-8864-b2592c96cb65	c864b259-2c96-4b65-8864-b2592c96cb65	1	0.0000	24000	0.000000	credited	2026-08-16 00:34:27.268789+00	\N	\N	2026-08-16 00:34:27.268789+00
f6f35ec1-9dc4-4883-a5c7-bf4f3a69140b	ad735111-eb6a-4e0f-9141-f29202a007aa	90c864b2-592c-464b-90c8-64b2592c964b	90c864b2-592c-464b-90c8-64b2592c964b	1	0.0000	24000	0.000000	credited	2026-08-16 00:34:56.200286+00	\N	\N	2026-08-16 00:34:56.200286+00
48688af2-9265-4c46-b0dc-5d442bbbc6a7	5a15e625-6836-4903-9e70-b2a7f071589e	1c0e8743-2190-48e4-9c0e-87432190c8e4	1c0e8743-2190-48e4-9c0e-87432190c8e4	1	0.0000	24000	0.000000	credited	2026-08-16 01:07:20.396669+00	\N	\N	2026-08-16 01:07:20.396669+00
f9ccf6da-7df6-46b9-81d8-a0b28b8e448a	8a06c07c-4321-4055-9117-e31902013cec	60b0d86c-369b-4da6-a0b0-d86c369b4da6	60b0d86c-369b-4da6-a0b0-d86c369b4da6	1	0.0000	24000	0.000000	credited	2026-08-16 01:26:02.012587+00	\N	\N	2026-08-16 01:26:02.012587+00
75c0bb1d-29a9-4d17-b6b9-dfc35e657c44	0d852718-df60-4dc3-b28d-71089dd77161	08048241-a050-48d4-8804-8241a050a8d4	08048241-a050-48d4-8804-8241a050a8d4	1	0.0000	24000	0.000000	credited	2026-08-16 01:26:30.098262+00	\N	\N	2026-08-16 01:26:30.098262+00
d255d5fc-a3cf-41c0-9c74-9520aa58df09	afe86aa2-240a-4b74-8a40-50fa759b1e2d	1088c4e2-7138-4c4e-9088-c4e271389c4e	1088c4e2-7138-4c4e-9088-c4e271389c4e	1	0.0000	24000	0.000000	credited	2026-08-16 01:26:55.625528+00	\N	\N	2026-08-16 01:26:55.625528+00
efe9831d-b43c-4339-a69f-2cf4299be736	9edd708b-c1e7-4139-8720-e75d66cb6aa1	e0f0783c-9e4f-47d3-a0f0-783c9e4fa7d3	e0f0783c-9e4f-47d3-a0f0-783c9e4fa7d3	1	0.0000	24000	0.000000	credited	2026-08-16 01:27:13.590058+00	\N	\N	2026-08-16 01:27:13.590058+00
672db770-0117-484b-90a8-803eae72243b	4e805dc6-9f24-475c-8530-c2ddda7b143f	40a0d0e8-f4fa-4dfe-80a0-d0e8f4fafdfe	40a0d0e8-f4fa-4dfe-80a0-d0e8f4fafdfe	1	0.0000	24000	0.000000	credited	2026-08-16 01:27:16.247681+00	\N	\N	2026-08-16 01:27:16.247681+00
d7c094d7-f8aa-4a36-ac8e-5d6d532e5ee3	4c3f1f84-cf09-4e87-86d2-fc9964e6cc36	6cb6dbed-76bb-4d2e-acb6-dbed76bb5d2e	6cb6dbed-76bb-4d2e-acb6-dbed76bb5d2e	1	0.0000	24000	0.000000	credited	2026-08-16 01:29:16.090044+00	\N	\N	2026-08-16 01:29:16.090044+00
0e48d69e-a095-40d7-a493-4cf1b0e651b9	10334341-08e6-4f2c-9245-b883cf4b4131	3c9e4f27-1309-4402-bc9e-4f2713090402	3c9e4f27-1309-4402-bc9e-4f2713090402	1	0.0000	24000	0.000000	credited	2026-08-16 01:29:20.448079+00	\N	\N	2026-08-16 01:29:20.448079+00
2db4cc21-443d-4174-8bb0-132513702383	56139a83-2c9d-4c2a-9c47-c1f6c3b1ad63	a452a954-aa55-4a55-a452-a954aa55aa55	a452a954-aa55-4a55-a452-a954aa55aa55	1	0.0000	24000	0.000000	credited	2026-08-16 01:54:02.055639+00	\N	\N	2026-08-16 01:54:02.055639+00
dd0b02ef-7fe0-408b-8568-5ad8072d0db0	5a8d340b-0ecd-4034-b3e6-7232b5f2edda	74ba5dae-d7eb-453a-b4ba-5daed7eb753a	74ba5dae-d7eb-453a-b4ba-5daed7eb753a	1	0.0000	24000	0.000000	credited	2026-08-16 01:54:04.825185+00	\N	\N	2026-08-16 01:54:04.825185+00
e9afd2ae-e2a9-480d-a30d-020b44ea8ea5	4a0c80cf-9067-473a-92a6-ac99c1d31beb	68b45a2d-96cb-45f2-a8b4-5a2d96cbe5f2	68b45a2d-96cb-45f2-a8b4-5a2d96cbe5f2	1	0.0000	24000	0.000000	credited	2026-08-16 01:54:27.522319+00	\N	\N	2026-08-16 01:54:27.522319+00
a013568f-1b88-491a-9158-929243011ef6	1e69ae02-e8ba-401e-8610-862273bb7892	40a0d068-341a-4d86-80a0-d068341a0d86	40a0d068-341a-4d86-80a0-d068341a0d86	1	0.0000	24000	0.000000	credited	2026-08-16 01:54:58.427708+00	\N	\N	2026-08-16 01:54:58.427708+00
e0fa473c-a482-481b-8a97-98cbc0ec456f	4755c9ac-e922-4a9e-be6b-5e9a9214f26d	c8e4f279-3c1e-4f87-88e4-f2793c1e0f87	c8e4f279-3c1e-4f87-88e4-f2793c1e0f87	1	0.0000	24000	0.000000	credited	2026-08-16 02:00:06.306726+00	\N	\N	2026-08-16 02:00:06.306726+00
4650aef2-c099-416d-86d9-c0f3d37d3726	191ba49f-e55b-4128-b657-85db30e547a7	3098cc66-b359-4c56-b098-cc66b359ac56	3098cc66-b359-4c56-b098-cc66b359ac56	1	0.0000	24000	0.000000	credited	2026-08-16 02:27:08.415318+00	\N	\N	2026-08-16 02:27:08.415318+00
fe8ff10b-46dd-456e-9faa-6f2cf79be6c3	dcfb7fb2-315f-4942-8fef-ad5595ab0933	3c9e4fa7-d3e9-44ba-bc9e-4fa7d3e974ba	3c9e4fa7-d3e9-44ba-bc9e-4fa7d3e974ba	1	0.0000	24000	0.000000	credited	2026-08-16 02:43:00.263325+00	\N	\N	2026-08-16 02:43:00.263325+00
687f1b61-e5d2-467b-8e01-fbf5e46b7414	6919c80d-7962-4374-a994-89a303ebc40f	241289c4-6231-48cc-a412-89c4623198cc	241289c4-6231-48cc-a412-89c4623198cc	1	0.0000	24000	0.000000	credited	2026-08-16 02:44:00.218037+00	\N	\N	2026-08-16 02:44:00.218037+00
d6232613-b67b-48bd-9423-af77ae5fd537	6e7f9c8d-6eb5-477d-82f5-8e6d58ce6f78	984c2613-89c4-42f1-984c-261389c4e2f1	984c2613-89c4-42f1-984c-261389c4e2f1	1	0.0000	24000	0.000000	credited	2026-08-16 02:44:07.002067+00	\N	\N	2026-08-16 02:44:07.002067+00
4247a79f-b421-4c00-981a-fc274ca0e576	2e8e4108-75e6-4a3b-968a-e22cbca711ef	582c160b-8542-4150-982c-160b8542a150	582c160b-8542-4150-982c-160b8542a150	1	0.0000	24000	0.000000	credited	2026-08-16 02:44:36.096184+00	\N	\N	2026-08-16 02:44:36.096184+00
9f02f8be-0678-4ac8-a307-b064be0b4828	7a8e45c8-3d6a-43dd-a2fe-91025f1ea90c	b85c2e97-4b25-4209-b85c-2e974b251209	b85c2e97-4b25-4209-b85c-2e974b251209	1	0.0000	24000	0.000000	credited	2026-08-16 02:44:37.196311+00	\N	\N	2026-08-16 02:44:37.196311+00
1e233ca9-186a-4403-add9-5f33e6b0a91f	3590ae92-d9f2-48b6-b3b6-6f61c4e12380	80402090-48a4-4269-8040-209048a4d269	80402090-48a4-4269-8040-209048a4d269	1	0.0000	24000	0.000000	credited	2026-08-16 02:44:38.476018+00	\N	\N	2026-08-16 02:44:38.476018+00
fc3a5228-0859-480c-9114-d3a55784b8e2	58c23bf2-f489-46c4-94f3-229b8b8aad82	b8dc6e37-9bcd-4633-b8dc-6e379bcd6633	b8dc6e37-9bcd-4633-b8dc-6e379bcd6633	1	0.0000	24000	0.000000	credited	2026-08-16 02:44:55.692847+00	\N	\N	2026-08-16 02:44:55.692847+00
9b666d5d-e4ec-4963-b92d-1bbcc667ee6f	19ed553d-ae21-458c-9188-b166a0e00049	743a1d0e-0783-41e0-b43a-1d0e0783c1e0	743a1d0e-0783-41e0-b43a-1d0e0783c1e0	1	0.0000	24000	0.000000	credited	2026-08-16 02:45:57.358368+00	\N	\N	2026-08-16 02:45:57.358368+00
51df664b-1ef8-4e49-b22a-8e049f9832f7	e65d1753-e922-47d2-91ef-257ed88f7f64	a8542a95-4aa5-4229-a854-2a954aa55229	a8542a95-4aa5-4229-a854-2a954aa55229	1	0.0000	24000	0.000000	credited	2026-08-16 02:48:32.677143+00	\N	\N	2026-08-16 02:48:32.677143+00
bbb9f328-5b89-43b4-9316-e1687ad89e2e	f1965fb5-12f0-458c-b8c3-5f572e392ce4	b45aad56-abd5-4a75-b45a-ad56abd5ea75	b45aad56-abd5-4a75-b45a-ad56abd5ea75	1	0.0000	24000	0.000000	credited	2026-08-16 02:49:04.786662+00	\N	\N	2026-08-16 02:49:04.786662+00
39eec7ab-80ee-429f-85d9-7fe2fa61b617	f0e96709-7131-496e-8b2d-83c69920ff92	28140a85-c2e1-40b8-a814-0a85c2e170b8	28140a85-c2e1-40b8-a814-0a85c2e170b8	1	0.0000	24000	0.000000	credited	2026-08-16 02:49:32.000004+00	\N	\N	2026-08-16 02:49:32.000004+00
b9cd8717-317b-4f16-bd59-97c1799f692a	f9245868-8ab0-42c2-a781-32263241d396	bc5e2f97-cb65-4219-bc5e-2f97cb653219	bc5e2f97-cb65-4219-bc5e-2f97cb653219	1	0.0000	24000	0.000000	credited	2026-08-16 02:51:29.165936+00	\N	\N	2026-08-16 02:51:29.165936+00
ddba45ec-2b24-4623-88f1-929ef07ce584	6246ad3a-1127-4f2f-8893-d8efa911fa2d	a0d068b4-5aad-46eb-a0d0-68b45aadd6eb	a0d068b4-5aad-46eb-a0d0-68b45aadd6eb	1	0.0000	24000	0.000000	credited	2026-08-16 02:51:41.150622+00	\N	\N	2026-08-16 02:51:41.150622+00
3eb7c71d-ddc8-4bec-8a2f-aebc65e01d8e	65fea9bf-23c9-4915-9dce-0d5b53f10a48	9ccee7f3-f97c-4edf-9cce-e7f3f97cbedf	9ccee7f3-f97c-4edf-9cce-e7f3f97cbedf	1	0.0000	24000	0.000000	credited	2026-08-16 02:51:46.141377+00	\N	\N	2026-08-16 02:51:46.141377+00
2edc940c-2365-4a87-b377-32e0a9e7c707	6d1672ef-8daf-4842-9fb7-2f33bb89fb24	f4fa7dbe-5faf-476b-b4fa-7dbe5fafd76b	f4fa7dbe-5faf-476b-b4fa-7dbe5fafd76b	1	0.0000	24000	0.000000	credited	2026-08-16 02:51:58.782923+00	\N	\N	2026-08-16 02:51:58.782923+00
b9323f36-99c4-4c89-a3da-9b80e8f9530f	5639651b-def9-459b-8460-5c8ee6a84c35	944aa552-a954-4a95-944a-a552a9542a95	944aa552-a954-4a95-944a-a552a9542a95	1	0.0000	24000	0.000000	credited	2026-08-16 02:51:59.884453+00	\N	\N	2026-08-16 02:51:59.884453+00
52f34656-a4c5-49eb-a208-29f9bc89c90f	3df9a817-d791-4231-8e6c-fb02485dd592	2090c8e4-f279-4cde-a090-c8e4f279bcde	2090c8e4-f279-4cde-a090-c8e4f279bcde	1	0.0000	24000	0.000000	credited	2026-08-16 02:52:01.960708+00	\N	\N	2026-08-16 02:52:01.960708+00
42140e8d-d88d-4c06-8a71-dca0f110f56a	00ba5a33-4212-4b0d-a23b-5e7f78c0cc43	24120984-c261-40d8-a412-0984c261b0d8	24120984-c261-40d8-a412-0984c261b0d8	1	0.0000	24000	0.000000	credited	2026-08-16 02:52:19.466281+00	\N	\N	2026-08-16 02:52:19.466281+00
042c842b-1cd5-48de-8c81-1321f1de1348	a57950d7-ac9c-4578-b656-44e88e6439ec	84c261b0-d8ec-46bb-84c2-61b0d8ec76bb	84c261b0-d8ec-46bb-84c2-61b0d8ec76bb	1	0.0000	24000	0.000000	credited	2026-08-16 02:53:23.289438+00	\N	\N	2026-08-16 02:53:23.289438+00
83df2bbf-397d-469b-8001-56acd4a0fa7f	df9c95b5-199a-4355-9b40-cee05056bbb9	5fde67db-081b-4b1d-9f3b-10e45a520fb2	3878c3c1-f900-4194-b8f7-ca2538111eb4	1	3000.0000	12000	50.000000	credited	2026-08-16 02:55:26.361436+00	\N	\N	2026-08-16 02:55:26.361436+00
62e9bd18-4d6b-4a4f-bf5b-85ddd7fe10d7	df9c95b5-199a-4355-9b40-cee05056bbb9	5fde67db-081b-4b1d-9f3b-10e45a520fb2	98207b42-c805-42cd-aafa-46f30cf1ac8c	2	2500.0000	7200	30.000000	credited	2026-08-16 02:55:26.361436+00	\N	\N	2026-08-16 02:55:26.361436+00
a57f1de7-835c-43bb-83e0-d6fbfb14e3aa	df9c95b5-199a-4355-9b40-cee05056bbb9	5fde67db-081b-4b1d-9f3b-10e45a520fb2	ca833cd8-e3ab-4d3a-9ad5-a33a88aa3843	3	2000.0000	4800	20.000000	credited	2026-08-16 02:55:26.361436+00	\N	\N	2026-08-16 02:55:26.361436+00
\.


--
-- Data for Name: provider_config; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.provider_config (asset_class, active_provider, fallback_provider, updated_at, updated_by) FROM stdin;
crypto	nobitex	binance	2026-08-15 20:32:00.001805+00	\N
forex	massive	twelvedata	2026-08-15 20:32:00.001805+00	\N
\.


--
-- Data for Name: referral_codes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.referral_codes (code, user_id, commission_rate_bps, is_active, created_at, activation_status, activation_requested_at, activation_approved_at, activation_rejected_at, rejection_reason) FROM stdin;
VDO1EWDL	00000000-0000-0000-0000-000000000001	500	f	2026-08-15 20:31:59.435518+00	inactive	\N	\N	\N	\N
JNA7140J	256cf845-d483-45bd-89d1-3d0c93c13398	500	f	2026-08-15 20:33:04.249648+00	inactive	\N	\N	\N	\N
6J43NAYG	4f8aa018-e087-40b3-a12a-15d13ce62eed	500	f	2026-08-15 20:33:04.438679+00	inactive	\N	\N	\N	\N
E58LJKSQ	54aa552a-150a-4502-94aa-552a150a0502	500	f	2026-08-16 00:33:43.295885+00	inactive	\N	\N	\N	\N
LXY7BYMV	502894ca-e572-491c-9028-94cae572391c	500	f	2026-08-16 00:34:07.664347+00	inactive	\N	\N	\N	\N
5OHTHKNR	c864b259-2c96-4b65-8864-b2592c96cb65	500	f	2026-08-16 00:34:27.196967+00	inactive	\N	\N	\N	\N
DNY6TE01	90c864b2-592c-464b-90c8-64b2592c964b	500	f	2026-08-16 00:34:56.091444+00	inactive	\N	\N	\N	\N
XJFBYWDV	30b7a5b7-62b1-4416-85b0-44824b338226	500	f	2026-08-16 01:05:06.957153+00	inactive	\N	\N	\N	\N
PV7LB9C5	7d16b1c9-fa10-4721-9ab1-f9c6dfd7f7c0	500	f	2026-08-16 01:05:27.704544+00	inactive	\N	\N	\N	\N
SL5YGYJ3	73724a7a-cc59-4aeb-86b5-bc997598c1ec	500	f	2026-08-16 01:05:27.715497+00	inactive	\N	\N	\N	\N
AZT0M095	3a6ad88d-a188-4bf0-be1d-bf2706cdbe2a	500	f	2026-08-16 01:05:44.428559+00	inactive	\N	\N	\N	\N
Z8Q32MLI	912bce1a-5da1-473c-b7cf-832f0ff39bb4	500	f	2026-08-16 01:05:44.439232+00	inactive	\N	\N	\N	\N
LSQ2PG10	863bc837-1fa3-4374-91df-3fe92a7a8694	500	f	2026-08-16 01:06:51.283815+00	inactive	\N	\N	\N	\N
QYMLZQD3	5d597832-fd0c-4be5-b1bb-ed1f03c10399	500	f	2026-08-16 01:06:51.293645+00	inactive	\N	\N	\N	\N
JXAA0Z38	81741f96-07b2-4e40-801d-470e79ffac94	500	f	2026-08-16 01:06:51.417229+00	inactive	\N	\N	\N	\N
Y0CWUMVA	8ff79fc3-3043-4a7c-a959-4f2ba6e5e265	500	f	2026-08-16 01:06:51.59817+00	inactive	\N	\N	\N	\N
I3U2OL3R	15e34f4d-da6c-4d3f-83c8-17bd2ddb4226	500	f	2026-08-16 01:07:18.554706+00	inactive	\N	\N	\N	\N
6RO47SGY	bf942846-2dc6-41a2-afb0-35efd5403110	500	f	2026-08-16 01:07:18.565593+00	inactive	\N	\N	\N	\N
1XIW7JU7	4af61bbb-6031-4996-9c0f-f27b00b90fb8	500	f	2026-08-16 01:07:18.690487+00	inactive	\N	\N	\N	\N
JTIOPOQO	d9da59d4-8084-49bd-ae23-cb99bb061a10	500	f	2026-08-16 01:07:18.842743+00	inactive	\N	\N	\N	\N
Z0BQN3JR	1c0e8743-2190-48e4-9c0e-87432190c8e4	500	f	2026-08-16 01:07:20.331157+00	inactive	\N	\N	\N	\N
08JZ4G61	7dc77ed4-d996-4eeb-a881-1f208a54c12f	500	f	2026-08-16 01:08:00.108095+00	inactive	\N	\N	\N	\N
QAMVQOWF	96329156-5841-49fb-81a3-2312b7525188	500	f	2026-08-16 01:08:00.118919+00	inactive	\N	\N	\N	\N
KR31P1F6	43efcc9b-7d09-41c4-a72c-5235ca0b3307	500	f	2026-08-16 01:08:00.247711+00	inactive	\N	\N	\N	\N
SKODETUJ	5c74f65f-c1f0-496a-9ad8-6a33bda83d30	500	f	2026-08-16 01:08:00.410037+00	inactive	\N	\N	\N	\N
N9ETXCLD	ab70e441-0b8e-4ed0-9762-13a8ac5e7c7d	500	f	2026-08-16 01:25:58.667111+00	inactive	\N	\N	\N	\N
NFBVWLDD	f97bf032-eeaa-483a-badb-00e6d886c526	500	f	2026-08-16 01:25:58.679767+00	inactive	\N	\N	\N	\N
8BMIFQHU	2625aa74-47bf-4793-a803-29bb9e477aed	500	f	2026-08-16 01:25:58.799775+00	inactive	\N	\N	\N	\N
5U2GLU68	e36a81e6-3639-4a93-b9c3-2f841d04211b	500	f	2026-08-16 01:25:58.964197+00	inactive	\N	\N	\N	\N
ZV5ZF6GM	60b0d86c-369b-4da6-a0b0-d86c369b4da6	500	f	2026-08-16 01:26:01.943303+00	inactive	\N	\N	\N	\N
1W4ZZU0Q	08048241-a050-48d4-8804-8241a050a8d4	500	f	2026-08-16 01:26:30.032427+00	inactive	\N	\N	\N	\N
2EKGZJCK	4f4153e9-0d17-4a1e-92ef-ce9e7958beb2	500	f	2026-08-16 01:26:54.026309+00	inactive	\N	\N	\N	\N
N6DG6S8U	c3a16226-aa66-4239-9f5b-228e8eb92f5b	500	f	2026-08-16 01:26:54.036025+00	inactive	\N	\N	\N	\N
F0NW8P3D	eb0cfe73-a65e-405a-8e76-0717293c8143	500	f	2026-08-16 01:26:54.15374+00	inactive	\N	\N	\N	\N
LG7ZUBQM	1088c4e2-7138-4c4e-9088-c4e271389c4e	500	f	2026-08-16 01:26:55.560293+00	inactive	\N	\N	\N	\N
7VT3KUYG	9e60eafe-d7b5-4ba8-9622-8a7e881717d2	500	f	2026-08-16 01:27:11.222946+00	inactive	\N	\N	\N	\N
JPXS8N17	f6e59b39-9e32-439a-879f-6b7683774265	500	f	2026-08-16 01:27:11.379997+00	inactive	\N	\N	\N	\N
8OR34VMO	e0f0783c-9e4f-47d3-a0f0-783c9e4fa7d3	500	f	2026-08-16 01:27:13.511254+00	inactive	\N	\N	\N	\N
WGZF78T9	40a0d0e8-f4fa-4dfe-80a0-d0e8f4fafdfe	500	f	2026-08-16 01:27:16.166495+00	inactive	\N	\N	\N	\N
FMFJYDOG	6cb6dbed-76bb-4d2e-acb6-dbed76bb5d2e	500	f	2026-08-16 01:29:16.019412+00	inactive	\N	\N	\N	\N
9NP2I5VI	3c9e4f27-1309-4402-bc9e-4f2713090402	500	f	2026-08-16 01:29:20.374373+00	inactive	\N	\N	\N	\N
8IC6NBRG	792c3ecb-0a51-4b66-b78f-411903e74aa3	500	f	2026-08-16 01:29:20.618003+00	inactive	\N	\N	\N	\N
PD34PP87	540d0a22-62a4-45f1-a0ab-2f2092014abb	500	f	2026-08-16 01:29:20.62736+00	inactive	\N	\N	\N	\N
AKDP422P	ffb61316-7d0b-4e05-a80f-d634f1b9391d	500	f	2026-08-16 01:29:20.866788+00	inactive	\N	\N	\N	\N
ZBFTJC0A	633e7e4b-d5a2-41c7-9a17-af7e54fd4c6c	500	f	2026-08-16 01:29:21.080269+00	inactive	\N	\N	\N	\N
E3TOFLUK	a452a954-aa55-4a55-a452-a954aa55aa55	500	f	2026-08-16 01:54:01.98505+00	inactive	\N	\N	\N	\N
L3GA0Y3A	74ba5dae-d7eb-453a-b4ba-5daed7eb753a	500	f	2026-08-16 01:54:04.76027+00	inactive	\N	\N	\N	\N
L4MDWHZ6	68b45a2d-96cb-45f2-a8b4-5a2d96cbe5f2	500	f	2026-08-16 01:54:27.455327+00	inactive	\N	\N	\N	\N
OOO4CESM	40a0d068-341a-4d86-80a0-d068341a0d86	500	f	2026-08-16 01:54:58.361931+00	inactive	\N	\N	\N	\N
OPJJMBJI	c8e4f279-3c1e-4f87-88e4-f2793c1e0f87	500	f	2026-08-16 02:00:06.237431+00	inactive	\N	\N	\N	\N
S0UHBNN0	3098cc66-b359-4c56-b098-cc66b359ac56	500	f	2026-08-16 02:27:08.230328+00	inactive	\N	\N	\N	\N
WNHEHOLF	2669d7fa-c10f-4128-9395-ada433d4631e	500	f	2026-08-16 02:27:10.369635+00	inactive	\N	\N	\N	\N
JD2IIZFB	452e07e0-e8eb-4f0f-98f2-f8875cd88831	500	f	2026-08-16 02:27:10.383152+00	inactive	\N	\N	\N	\N
Z5YRPGTD	653652cd-820e-4692-a7bb-1bb90a20936a	500	f	2026-08-16 02:27:10.522941+00	inactive	\N	\N	\N	\N
N6VGK5ZF	3c9e4fa7-d3e9-44ba-bc9e-4fa7d3e974ba	500	f	2026-08-16 02:43:00.185939+00	inactive	\N	\N	\N	\N
KRV7AY4V	c9e259ce-38b0-4b00-a3a3-9b5771d9b6de	500	f	2026-08-16 02:43:02.698585+00	inactive	\N	\N	\N	\N
DG3JLWFJ	e8a771e3-92db-4a30-9bb0-c4b84125187f	500	f	2026-08-16 02:43:02.709242+00	inactive	\N	\N	\N	\N
XVLT97BA	d8bacc11-7441-48e2-9f65-7d387dd9ea26	500	f	2026-08-16 02:43:02.82178+00	inactive	\N	\N	\N	\N
MO6SJDR0	241289c4-6231-48cc-a412-89c4623198cc	500	f	2026-08-16 02:44:00.149325+00	inactive	\N	\N	\N	\N
GGO6NU48	76ada4f6-10d5-4219-a405-f8d5e5b32b78	500	f	2026-08-16 02:44:01.980764+00	inactive	\N	\N	\N	\N
XCU8LKYS	d00ce5cc-0dc6-4078-935c-2a75b2349ba2	500	f	2026-08-16 02:44:01.990249+00	inactive	\N	\N	\N	\N
LJB3HPEX	0499cba2-41b1-4fd3-b4f7-07d7e77bd094	500	f	2026-08-16 02:44:02.107825+00	inactive	\N	\N	\N	\N
O9ILHFG7	f6491f08-63d2-476f-873f-db5cf69c0122	500	f	2026-08-16 02:44:05.80883+00	inactive	\N	\N	\N	\N
PE1NHCEO	302640fe-27ce-4abe-b59a-5ec4dc69944c	500	f	2026-08-16 02:44:05.818991+00	inactive	\N	\N	\N	\N
4DIAORTW	984c2613-89c4-42f1-984c-261389c4e2f1	500	f	2026-08-16 02:44:06.938424+00	inactive	\N	\N	\N	\N
3FCFO1S6	218b00a6-dd31-4954-8850-989f8454cb72	500	f	2026-08-16 02:44:08.540847+00	inactive	\N	\N	\N	\N
QQQLWKDL	b479eb08-1b65-411d-964c-028ed616a70d	500	f	2026-08-16 02:44:08.550628+00	inactive	\N	\N	\N	\N
T3T30GN1	c66062f8-5699-49a8-a1bb-05a591ab9f22	500	f	2026-08-16 02:44:11.055506+00	inactive	\N	\N	\N	\N
06VG6C1K	646173e1-c3cb-42b3-8252-1f9a45adf2d5	500	f	2026-08-16 02:44:11.065333+00	inactive	\N	\N	\N	\N
EDE7N8A7	582c160b-8542-4150-982c-160b8542a150	500	f	2026-08-16 02:44:36.02955+00	inactive	\N	\N	\N	\N
1PIECSK4	b85c2e97-4b25-4209-b85c-2e974b251209	500	f	2026-08-16 02:44:37.128009+00	inactive	\N	\N	\N	\N
K5I7YPJO	80402090-48a4-4269-8040-209048a4d269	500	f	2026-08-16 02:44:38.390061+00	inactive	\N	\N	\N	\N
O1D106O3	b8dc6e37-9bcd-4633-b8dc-6e379bcd6633	500	f	2026-08-16 02:44:55.576875+00	inactive	\N	\N	\N	\N
SKFRQPIL	743a1d0e-0783-41e0-b43a-1d0e0783c1e0	500	f	2026-08-16 02:45:57.288054+00	inactive	\N	\N	\N	\N
JFOO8NPS	0d4fd196-fc76-49cf-a78c-ce25c8a03022	500	f	2026-08-16 02:45:59.065355+00	inactive	\N	\N	\N	\N
N0S70U1F	426be798-f942-40a8-8609-cd231f5ebb08	500	f	2026-08-16 02:45:59.074736+00	inactive	\N	\N	\N	\N
2APLUIWN	cdf8aaad-4a4f-4dc9-a592-79fe503633f7	500	f	2026-08-16 02:45:59.189454+00	inactive	\N	\N	\N	\N
O4B87BUB	a8542a95-4aa5-4229-a854-2a954aa55229	500	f	2026-08-16 02:48:32.611695+00	inactive	\N	\N	\N	\N
I5J3GITO	1b5063b8-9733-4563-beef-2c787c3365a9	500	f	2026-08-16 02:48:34.35622+00	inactive	\N	\N	\N	\N
7GRVYZVY	a3d7c5f3-40e0-4c2f-933a-f95a98ab57f3	500	f	2026-08-16 02:48:34.36559+00	inactive	\N	\N	\N	\N
IACR3BZM	ddeff84e-1027-4038-8102-7ce08c9e5a94	500	f	2026-08-16 02:48:34.482315+00	inactive	\N	\N	\N	\N
HPXDENEF	b45aad56-abd5-4a75-b45a-ad56abd5ea75	500	f	2026-08-16 02:49:04.718947+00	inactive	\N	\N	\N	\N
JEPFIDS7	f92e8766-b7d0-4dca-add5-9718456d5657	500	f	2026-08-16 02:49:06.313218+00	inactive	\N	\N	\N	\N
AXNQG3F5	071d2be9-9431-4ae5-afbb-9a195b33db15	500	f	2026-08-16 02:49:06.323616+00	inactive	\N	\N	\N	\N
QG2BMTLH	f41fb589-ceb8-47da-9ec4-4c1bb1f0e79d	500	f	2026-08-16 02:49:07.845918+00	inactive	\N	\N	\N	\N
QWI9Q0SU	2cf63582-501f-451b-8595-587b82b2f40a	500	f	2026-08-16 02:49:30.825098+00	inactive	\N	\N	\N	\N
FDD0310V	ed2e8329-c2c7-4ed0-b3ea-ed9b6e2abfda	500	f	2026-08-16 02:49:30.835249+00	inactive	\N	\N	\N	\N
W15586AQ	28140a85-c2e1-40b8-a814-0a85c2e170b8	500	f	2026-08-16 02:49:31.934335+00	inactive	\N	\N	\N	\N
UY98YQ81	bc5e2f97-cb65-4219-bc5e-2f97cb653219	500	f	2026-08-16 02:51:29.097954+00	inactive	\N	\N	\N	\N
NR84GYNN	6c6f8218-0e00-4731-9e59-e8b8d4d61b5d	500	f	2026-08-16 02:51:30.836555+00	inactive	\N	\N	\N	\N
QKVE03D3	5d4db3df-ec04-4d3f-a4b7-758b932bdeab	500	f	2026-08-16 02:51:30.846111+00	inactive	\N	\N	\N	\N
A0LO2CMQ	5a5b8479-6d2f-4e8c-8064-84afe7c56e72	500	f	2026-08-16 02:51:30.965398+00	inactive	\N	\N	\N	\N
TQ31C3I1	a0d068b4-5aad-46eb-a0d0-68b45aadd6eb	500	f	2026-08-16 02:51:41.086546+00	inactive	\N	\N	\N	\N
SLLADMG7	3f0e5a46-bb93-4f07-a561-60662dd5541a	500	f	2026-08-16 02:51:42.792895+00	inactive	\N	\N	\N	\N
282DJIZO	0f108d2e-d94b-4cd8-b88f-504e9d68134a	500	f	2026-08-16 02:51:42.803287+00	inactive	\N	\N	\N	\N
KTD1P6ZK	515fbee7-3bb0-4b6d-b431-22282d623cd7	500	f	2026-08-16 02:51:42.915207+00	inactive	\N	\N	\N	\N
HUULY6MT	9ccee7f3-f97c-4edf-9cce-e7f3f97cbedf	500	f	2026-08-16 02:51:46.075347+00	inactive	\N	\N	\N	\N
HL91V30A	a14dbc0e-1b40-4539-825b-5bad255f153d	500	f	2026-08-16 02:51:47.659314+00	inactive	\N	\N	\N	\N
A4IRMN7D	de4588c4-c14b-4f0c-9908-2e0689f907fe	500	f	2026-08-16 02:51:47.682698+00	inactive	\N	\N	\N	\N
BKFQCS2G	5f124107-5c83-432a-80fd-8899e94f9845	500	f	2026-08-16 02:51:49.250329+00	inactive	\N	\N	\N	\N
P0RGCPLS	e19c7724-0cba-4667-8e36-c469962a9f0e	500	f	2026-08-16 02:51:57.526095+00	inactive	\N	\N	\N	\N
BGMWVDPC	92b04625-4ad6-4bea-94ef-2795bd4c5fa1	500	f	2026-08-16 02:51:57.550655+00	inactive	\N	\N	\N	\N
29U6CONQ	f4fa7dbe-5faf-476b-b4fa-7dbe5fafd76b	500	f	2026-08-16 02:51:58.706037+00	inactive	\N	\N	\N	\N
ZTDG0PHU	944aa552-a954-4a95-944a-a552a9542a95	500	f	2026-08-16 02:51:59.821883+00	inactive	\N	\N	\N	\N
Y9D8BWM5	2090c8e4-f279-4cde-a090-c8e4f279bcde	500	f	2026-08-16 02:52:01.896373+00	inactive	\N	\N	\N	\N
RAQ9FHJ1	649329c0-8d36-409a-b7c5-b38404828556	500	f	2026-08-16 02:52:15.375873+00	inactive	\N	\N	\N	\N
M57LQKCE	bee05777-76fe-4703-a9cd-9d3dc737900d	500	f	2026-08-16 02:52:15.385108+00	inactive	\N	\N	\N	\N
YYZXRGXG	24120984-c261-40d8-a412-0984c261b0d8	500	f	2026-08-16 02:52:19.34147+00	inactive	\N	\N	\N	\N
TQ9L4Z2B	f48d5513-b821-4152-a295-5efeb81d84a8	500	f	2026-08-16 02:52:34.808765+00	inactive	\N	\N	\N	\N
52I8OUO9	d27fb682-c775-422a-9b7d-45eb2e8bc3c5	500	f	2026-08-16 02:52:34.818942+00	inactive	\N	\N	\N	\N
8DC0BVHK	9990da57-187a-42b2-8bda-059add25d3e1	500	f	2026-08-16 02:52:34.928516+00	inactive	\N	\N	\N	\N
J4DT025M	84c261b0-d8ec-46bb-84c2-61b0d8ec76bb	500	f	2026-08-16 02:53:23.223275+00	inactive	\N	\N	\N	\N
FU48PVF0	6791b01d-b944-4e99-b143-fb30f4f67872	500	f	2026-08-16 02:53:24.943162+00	inactive	\N	\N	\N	\N
A2CWZN4U	55ff18a7-c140-4f37-b027-cfff7e1a6e85	500	f	2026-08-16 02:53:24.953263+00	inactive	\N	\N	\N	\N
7L2IQBOR	fb2b1558-5440-43ec-ba87-73bc2a27ceb7	500	f	2026-08-16 02:53:25.070202+00	inactive	\N	\N	\N	\N
GL9FXE6D	3878c3c1-f900-4194-b8f7-ca2538111eb4	500	f	2026-08-16 02:55:26.361436+00	inactive	\N	\N	\N	\N
UN6LS578	98207b42-c805-42cd-aafa-46f30cf1ac8c	500	f	2026-08-16 02:55:26.361436+00	inactive	\N	\N	\N	\N
K87HI4EJ	ca833cd8-e3ab-4d3a-9ad5-a33a88aa3843	500	f	2026-08-16 02:55:26.361436+00	inactive	\N	\N	\N	\N
\.


--
-- Data for Name: referrals; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.referrals (id, referrer_id, referred_id, code, status, created_at, qualified_at) FROM stdin;
\.


--
-- Data for Name: role_permissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.role_permissions (role_id, permission_id, granted_at) FROM stdin;
4	1	2026-08-15 20:31:58.806397+00
4	4	2026-08-15 20:31:58.806397+00
4	7	2026-08-15 20:31:58.806397+00
4	9	2026-08-15 20:31:58.806397+00
4	11	2026-08-15 20:31:58.806397+00
4	12	2026-08-15 20:31:58.806397+00
4	15	2026-08-15 20:31:58.806397+00
2	1	2026-08-15 20:31:58.806397+00
2	4	2026-08-15 20:31:58.806397+00
2	7	2026-08-15 20:31:58.806397+00
2	9	2026-08-15 20:31:58.806397+00
2	11	2026-08-15 20:31:58.806397+00
2	12	2026-08-15 20:31:58.806397+00
2	15	2026-08-15 20:31:58.806397+00
2	2	2026-08-15 20:31:58.806397+00
2	5	2026-08-15 20:31:58.806397+00
2	6	2026-08-15 20:31:58.806397+00
2	8	2026-08-15 20:31:58.806397+00
2	10	2026-08-15 20:31:58.806397+00
2	14	2026-08-15 20:31:58.806397+00
5	1	2026-08-15 20:31:58.806397+00
5	2	2026-08-15 20:31:58.806397+00
5	3	2026-08-15 20:31:58.806397+00
5	4	2026-08-15 20:31:58.806397+00
5	5	2026-08-15 20:31:58.806397+00
5	6	2026-08-15 20:31:58.806397+00
5	7	2026-08-15 20:31:58.806397+00
5	8	2026-08-15 20:31:58.806397+00
5	9	2026-08-15 20:31:58.806397+00
5	10	2026-08-15 20:31:58.806397+00
5	11	2026-08-15 20:31:58.806397+00
5	12	2026-08-15 20:31:58.806397+00
5	13	2026-08-15 20:31:58.806397+00
5	14	2026-08-15 20:31:58.806397+00
5	15	2026-08-15 20:31:58.806397+00
4	16	2026-08-15 20:31:58.866375+00
2	16	2026-08-15 20:31:58.866375+00
2	17	2026-08-15 20:31:58.866375+00
5	16	2026-08-15 20:31:58.866375+00
5	17	2026-08-15 20:31:58.866375+00
6	7	2026-08-15 20:32:00.471755+00
6	8	2026-08-15 20:32:00.471755+00
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.roles (id, name) FROM stdin;
1	user
2	admin
3	moderator
4	viewer
5	super_admin
6	support_admin
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.schema_migrations (version, dirty) FROM stdin;
103	f
\.


--
-- Data for Name: security_audit_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.security_audit_log (id, user_id, event_type, ip_address, user_agent, metadata, created_at) FROM stdin;
ee1c66b9-ad71-44e6-8c4c-e6f533b3e21f	4f8aa018-e087-40b3-a12a-15d13ce62eed	LOGIN	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	{"email": "[REDACTED]"}	2026-08-15 21:38:12.061235+00
\.


--
-- Data for Name: settlement_events; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.settlement_events (id, settlement_id, contest_id, event_type, event_data, error_message, created_at) FROM stdin;
\.


--
-- Data for Name: shard_assignment_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.shard_assignment_log (id, contest_id, old_shard_id, new_shard_id, reason, assigned_by, created_at) FROM stdin;
\.


--
-- Data for Name: shard_config; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.shard_config (shard_id, name, status, weight, kafka_partition, address, metadata, created_at, updated_at) FROM stdin;
0	default	active	100	0	\N	{}	2026-08-15 20:31:57.549835+00	2026-08-15 20:31:57.549835+00
1	shard-1	active	100	1	\N	{}	2026-08-15 20:31:57.605857+00	2026-08-15 20:31:57.605857+00
2	shard-2	active	100	2	\N	{}	2026-08-15 20:31:57.605857+00	2026-08-15 20:31:57.605857+00
3	shard-3	active	100	3	\N	{}	2026-08-15 20:31:57.605857+00	2026-08-15 20:31:57.605857+00
\.


--
-- Data for Name: support_tickets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.support_tickets (id, user_id, subject, category, status, priority, assigned_admin_id, closed_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: symbols; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.symbols (symbol, name, asset_type, provider_symbol_twelvedata, provider_symbol_massive, is_active, created_at, updated_at, provider_symbol_nobitex, provider_symbol_binance, sort_order, provider_symbol_finnhub) FROM stdin;
AAPL	Apple Inc.	stock	AAPL	AAPL	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:31:58.866375+00	\N	\N	999	\N
MSFT	Microsoft Corporation	stock	MSFT	MSFT	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:31:58.866375+00	\N	\N	999	\N
GOOGL	Alphabet Inc.	stock	GOOGL	GOOGL	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:31:58.866375+00	\N	\N	999	\N
AMZN	Amazon.com Inc.	stock	AMZN	AMZN	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:31:58.866375+00	\N	\N	999	\N
TSLA	Tesla Inc.	stock	TSLA	TSLA	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:31:58.866375+00	\N	\N	999	\N
META	Meta Platforms Inc.	stock	META	META	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:31:58.866375+00	\N	\N	999	\N
NVDA	NVIDIA Corporation	stock	NVDA	NVDA	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:31:58.866375+00	\N	\N	999	\N
JPM	JPMorgan Chase & Co.	stock	JPM	JPM	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:31:58.866375+00	\N	\N	999	\N
V	Visa Inc.	stock	V	V	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:31:58.866375+00	\N	\N	999	\N
JNJ	Johnson & Johnson	stock	JNJ	JNJ	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:31:58.866375+00	\N	\N	999	\N
ETC/USD	Ethereum Classic	crypto	\N	ETC-USD	f	2026-08-15 20:31:59.567768+00	2026-08-15 20:31:59.986995+00	ETCUSDT	\N	999	\N
EUR/USD	Euro / US Dollar	forex	EUR/USD	EUR-USD	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:32:00.406941+00	\N	\N	1	OANDA:EUR_USD
GBP/USD	British Pound / US Dollar	forex	GBP/USD	GBP-USD	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:32:00.406941+00	\N	\N	2	OANDA:GBP_USD
USD/JPY	US Dollar / Japanese Yen	forex	USD/JPY	USD-JPY	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:32:00.406941+00	\N	\N	3	OANDA:USD_JPY
USD/CHF	US Dollar / Swiss Franc	forex	USD/CHF	USD-CHF	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:32:00.406941+00	\N	\N	4	OANDA:USD_CHF
BRENT	Brent Crude Oil	commodity	BRENT	\N	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:31:59.467559+00	\N	\N	999	\N
WTI	WTI Crude Oil	commodity	WTI	\N	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:31:59.467559+00	\N	\N	999	\N
USD/CNY	US Dollar/Chinese Yuan	forex	USD/CNY	USD-CNY	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:31:59.479804+00	\N	\N	999	\N
USD/KRW	US Dollar/Korean Won	forex	USD/KRW	USD-KRW	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:31:59.479804+00	\N	\N	999	\N
USD/INR	US Dollar/Indian Rupee	forex	USD/INR	USD-INR	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:31:59.479804+00	\N	\N	999	\N
USD/BRL	US Dollar/Brazilian Real	forex	USD/BRL	USD-BRL	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:31:59.479804+00	\N	\N	999	\N
USOIL	US Oil (WTI Crude)	commodity	USOIL	\N	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:31:59.479804+00	\N	\N	999	\N
BTC/USD	Bitcoin	crypto	BTC/USD	BTC-USD	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:32:00.025726+00	BTCUSDT	BTCUSDT	1	\N
ETH/USD	Ethereum	crypto	ETH/USD	ETH-USD	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:32:00.025726+00	ETHUSDT	ETHUSDT	2	\N
SOL/USD	Solana	crypto	SOL/USD	SOL-USD	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:32:00.025726+00	SOLUSDT	SOLUSDT	3	\N
XRP/USD	Ripple	crypto	XRP/USD	XRP-USD	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:32:00.025726+00	XRPUSDT	XRPUSDT	4	\N
DOGE/USD	Dogecoin	crypto	DOGE/USD	DOGE-USD	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:32:00.025726+00	DOGEUSDT	DOGEUSDT	5	\N
ADA/USD	Cardano	crypto	ADA/USD	ADA-USD	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:32:00.025726+00	ADAUSDT	ADAUSDT	6	\N
AVAX/USD	Avalanche	crypto	AVAX/USD	AVAX-USD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.025726+00	AVAXUSDT	AVAXUSDT	7	\N
LINK/USD	Chainlink	crypto	LINK/USD	LINK-USD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.025726+00	LINKUSDT	LINKUSDT	8	\N
DOT/USD	Polkadot	crypto	DOT/USD	DOT-USD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.025726+00	DOTUSDT	DOTUSDT	9	\N
LTC/USD	Litecoin	crypto	LTC/USD	LTC-USD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.025726+00	LTCUSDT	LTCUSDT	10	\N
POL/USD	Polygon	crypto	POL/USD	POL-USD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.025726+00	POLUSDT	POLUSDT	12	\N
SHIB/USD	Shiba Inu	crypto	SHIB/USD	SHIB-USD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.025726+00	SHIBUSDT	SHIBUSDT	13	\N
UNI/USD	Uniswap	crypto	UNI/USD	UNI-USD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.025726+00	UNIUSDT	UNIUSDT	14	\N
XLM/USD	Stellar	crypto	XLM/USD	XLM-USD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.025726+00	XLMUSDT	XLMUSDT	15	\N
NEAR/USD	NEAR Protocol	crypto	NEAR/USD	NEAR-USD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.025726+00	NEARUSDT	NEARUSDT	16	\N
AAVE/USD	Aave	crypto	AAVE/USD	AAVE-USD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.025726+00	AAVEUSDT	AAVEUSDT	17	\N
SUI/USD	Sui	crypto	SUI/USD	SUI-USD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.025726+00	SUIUSDT	SUIUSDT	18	\N
ARB/USD	Arbitrum	crypto	\N	ARB-USD	f	2026-08-15 20:31:59.567768+00	2026-08-15 20:31:59.986995+00	ARBUSDT	\N	999	\N
OP/USD	Optimism	crypto	\N	OP-USD	f	2026-08-15 20:31:59.567768+00	2026-08-15 20:31:59.986995+00	OPUSDT	\N	999	\N
INJ/USD	Injective	crypto	\N	INJ-USD	f	2026-08-15 20:31:59.567768+00	2026-08-15 20:31:59.986995+00	INJUSDT	\N	999	\N
RENDER/USD	Render	crypto	\N	RENDER-USD	f	2026-08-15 20:31:59.567768+00	2026-08-15 20:31:59.986995+00	RENDERUSDT	\N	999	\N
USD/MXN	US Dollar / Mexican Peso	forex	USD/MXN	USD-MXN	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:USD_MXN
USD/ZAR	US Dollar / South African Rand	forex	USD/ZAR	USD-ZAR	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:USD_ZAR
USD/SGD	US Dollar / Singapore Dollar	forex	USD/SGD	USD-SGD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:USD_SGD
USD/HKD	US Dollar / Hong Kong Dollar	forex	USD/HKD	USD-HKD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:USD_HKD
USD/NOK	US Dollar / Norwegian Krone	forex	USD/NOK	USD-NOK	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:USD_NOK
USD/SEK	US Dollar / Swedish Krona	forex	USD/SEK	USD-SEK	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:USD_SEK
USD/PLN	US Dollar / Polish Zloty	forex	USD/PLN	USD-PLN	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:USD_PLN
BCH/USD	Bitcoin Cash	crypto	BCH/USD	BCH-USD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.025726+00	BCHUSDT	BCHUSDT	11	\N
PEPE/USD	Pepe	crypto	PEPE/USD	PEPE-USD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.025726+00	PEPEUSDT	PEPEUSDT	19	\N
APT/USD	Aptos	crypto	APT/USD	APT-USD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.025726+00	APTUSDT	APTUSDT	20	\N
HBAR/USD	Hedera	crypto	HBAR/USD	HBAR-USD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.025726+00	HBARUSDT	HBARUSDT	21	\N
ICP/USD	Internet Computer	crypto	ICP/USD	ICP-USD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.025726+00	ICPUSDT	ICPUSDT	22	\N
VET/USD	VeChain	crypto	VET/USD	VET-USD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.025726+00	VETUSDT	VETUSDT	23	\N
CRO/USD	Cronos	crypto	CRO/USD	CRO-USD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.025726+00	CROUSDT	CROUSDT	24	\N
XAU/USD	Gold	commodity	XAU/USD	XAU-USD	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:32:00.272523+00	\N	\N	1	OANDA:XAU_USD
XAG/USD	Silver	commodity	XAG/USD	XAG-USD	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:32:00.272523+00	\N	\N	2	OANDA:XAG_USD
AUD/USD	Australian Dollar / US Dollar	forex	AUD/USD	AUD-USD	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:32:00.406941+00	\N	\N	5	OANDA:AUD_USD
USD/CAD	US Dollar / Canadian Dollar	forex	USD/CAD	USD-CAD	t	2026-08-15 20:31:58.866375+00	2026-08-15 20:32:00.406941+00	\N	\N	7	OANDA:USD_CAD
NZD/USD	New Zealand Dollar / US Dollar	forex	NZD/USD	NZD-USD	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.406941+00	\N	\N	6	OANDA:NZD_USD
EUR/GBP	Euro / British Pound	forex	EUR/GBP	EUR-GBP	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.406941+00	\N	\N	8	OANDA:EUR_GBP
EUR/JPY	Euro / Japanese Yen	forex	EUR/JPY	EUR-JPY	t	2026-08-15 20:31:59.479804+00	2026-08-15 20:32:00.406941+00	\N	\N	9	OANDA:EUR_JPY
EUR/CHF	Euro / Swiss Franc	forex	EUR/CHF	EUR-CHF	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:EUR_CHF
EUR/AUD	Euro / Australian Dollar	forex	EUR/AUD	EUR-AUD	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:EUR_AUD
EUR/CAD	Euro / Canadian Dollar	forex	EUR/CAD	EUR-CAD	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:EUR_CAD
EUR/NZD	Euro / New Zealand Dollar	forex	EUR/NZD	EUR-NZD	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:EUR_NZD
GBP/JPY	British Pound / Japanese Yen	forex	GBP/JPY	GBP-JPY	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:GBP_JPY
GBP/CHF	British Pound / Swiss Franc	forex	GBP/CHF	GBP-CHF	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:GBP_CHF
GBP/AUD	British Pound / Australian Dollar	forex	GBP/AUD	GBP-AUD	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:GBP_AUD
GBP/CAD	British Pound / Canadian Dollar	forex	GBP/CAD	GBP-CAD	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:GBP_CAD
GBP/NZD	British Pound / New Zealand Dollar	forex	GBP/NZD	GBP-NZD	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:GBP_NZD
AUD/JPY	Australian Dollar / Japanese Yen	forex	AUD/JPY	AUD-JPY	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:AUD_JPY
AUD/CHF	Australian Dollar / Swiss Franc	forex	AUD/CHF	AUD-CHF	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:AUD_CHF
AUD/CAD	Australian Dollar / Canadian Dollar	forex	AUD/CAD	AUD-CAD	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:AUD_CAD
AUD/NZD	Australian Dollar / New Zealand Dollar	forex	AUD/NZD	AUD-NZD	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:AUD_NZD
CAD/JPY	Canadian Dollar / Japanese Yen	forex	CAD/JPY	CAD-JPY	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:CAD_JPY
CAD/CHF	Canadian Dollar / Swiss Franc	forex	CAD/CHF	CAD-CHF	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:CAD_CHF
CHF/JPY	Swiss Franc / Japanese Yen	forex	CHF/JPY	CHF-JPY	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:CHF_JPY
NZD/JPY	New Zealand Dollar / Japanese Yen	forex	NZD/JPY	NZD-JPY	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:NZD_JPY
NZD/CHF	New Zealand Dollar / Swiss Franc	forex	NZD/CHF	NZD-CHF	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:NZD_CHF
NZD/CAD	New Zealand Dollar / Canadian Dollar	forex	NZD/CAD	NZD-CAD	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:NZD_CAD
USD/TRY	US Dollar / Turkish Lira	forex	USD/TRY	USD-TRY	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:USD_TRY
USD/DKK	US Dollar / Danish Krone	forex	USD/DKK	USD-DKK	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:USD_DKK
USD/CZK	US Dollar / Czech Koruna	forex	USD/CZK	USD-CZK	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:USD_CZK
USD/HUF	US Dollar / Hungarian Forint	forex	USD/HUF	USD-HUF	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:USD_HUF
EUR/TRY	Euro / Turkish Lira	forex	EUR/TRY	EUR-TRY	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:EUR_TRY
EUR/SEK	Euro / Swedish Krona	forex	EUR/SEK	EUR-SEK	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:EUR_SEK
EUR/NOK	Euro / Norwegian Krone	forex	EUR/NOK	EUR-NOK	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:EUR_NOK
EUR/PLN	Euro / Polish Zloty	forex	EUR/PLN	EUR-PLN	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:EUR_PLN
GBP/TRY	British Pound / Turkish Lira	forex	GBP/TRY	GBP-TRY	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:GBP_TRY
US30/USD	Dow Jones Industrial Average	commodity	DJ30	US30-USD	t	2026-08-15 20:32:00.406941+00	2026-08-15 20:32:00.406941+00	\N	\N	999	OANDA:US30_USD
\.


--
-- Data for Name: template_entry_tiers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.template_entry_tiers (id, template_id, entry_fee, label, sort_order, is_active, is_free, qty_total_override, max_participants_override, commission_rate_override, has_prize_override, created_at, updated_at) FROM stdin;
a8a74170-9030-4e24-a21e-e43c3ee0a3df	b267a919-d2e9-42c8-8a2b-4266951f325e	2500000	250000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
1a13fac5-c02b-440a-b161-d6146cf989dd	8351bfc9-a09a-4ed2-9616-3fb2e83ba7be	10000000	1000000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
ce0d43ab-a542-41d0-b996-ca25b85fa5c3	785af236-6a0c-4864-8fb9-380328df1c8b	50000	5000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
bea70a27-12f6-471a-b8e1-fbd3470cc134	db9ec1a2-41f5-4bda-b7fe-98daf35c9d27	100000	10000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
ff193ba7-d923-4518-bffa-f0edfa93d159	2348f35a-e3d2-4565-b8b9-8b4e67556985	200000	20000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
6d5889e9-3582-4993-8bc6-486b74a99174	87ca7de1-10eb-4acd-b9a7-8750787e488b	10000	1000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
b04fa962-43a1-40dd-af82-f9447f83870e	ef1146ce-7959-4836-aa51-009f44b76035	0	Free	0	t	t	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
14f35811-99ea-436e-bace-8d2c40ef924a	08f9816f-f704-470c-836e-5478e45e35d2	100000	10000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
cf5c7966-edb8-4c49-99f0-7549a13fbb34	e0b892c9-3519-4027-b979-9cf6c5560d64	10000	1000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
fb1b8eff-6dee-4c8a-bedd-05ba9e727c79	eba90188-f7ff-4a81-bfe8-fc096d8088e1	50000	5000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
6e934828-5cad-444e-aead-1dd98182a8ec	0fcf9803-b3fe-443d-9b4c-a61b4d5288b4	1000	100 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
f137f099-a5ec-4f45-889d-9061582707bd	604bd3d7-4aa6-4e9e-93ef-ce10a70b5ac5	0	Free	0	t	t	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
78fedd20-e110-40dd-972f-02762ac3acbb	a56aa614-e426-4c74-a06f-d37651ca211f	50000	5000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
0de8edc0-e11f-44d4-9951-ffd2638798e5	7813e966-37bd-4a81-8c76-5df7ad74071c	50000000	5000000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
c6f30e8b-47da-4fdb-919f-59b44669369f	41aec9d1-c1cb-4ba9-bca7-36aaa2c934a4	5000	500 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
4596f8ec-db96-4d5d-ac37-3def3cd91e50	54b73492-5037-4a14-b3b5-83918b8d7e82	5000	500 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
85035a22-1798-43b9-b49d-78f9dbc5e10e	41324aa6-7cc0-4f27-af4d-a2ac78d1db70	0	Free	0	t	t	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
f5a05db9-1f5b-4aea-9bd2-8f5a3b248f23	459a8be1-1fd0-4c3b-91d1-73d0ed21ccf3	500000	50000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
f4f6793a-89f0-45b7-8a1d-0d4f7680458f	8d96e9c9-f3b0-4b36-8839-aaeaf393490c	200000	20000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
d63923b2-9906-4a13-b168-6c648b962b21	11133e82-fe5a-4c63-8b33-806a55e09e51	10000000	1000000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
f8d80cf7-79c1-42e8-8573-43a7f41de345	68db9037-e36a-4802-aed3-d40fe401c98b	1500000	150000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
1f03a508-fac5-453c-badd-74401d357ba4	46a7dc3e-2adc-46bb-8bb8-939d8fcbd28b	0	Free	0	t	t	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
bc58fc49-12dd-4492-bed0-60296d5fae04	479c8ee8-fb05-4896-a7ae-de63fb88b9b7	500	50 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
04e27efb-af29-4eda-bfab-fb61f7a998d5	757557fe-1fc3-4116-9652-8793a64b6e94	0	Free	0	t	t	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
8840c13a-f65c-4801-b7ba-f7b5c94eba6a	1933747d-a9cd-4fe1-8b74-1f14585a8c67	0	Free	0	t	t	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
c0fbd0ef-7c24-499b-9f4d-ad0d9a1ccd7f	b39dad6f-e3a8-4274-ae37-b1b6a64040fc	0	Free	0	t	t	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
c3c7d507-774b-4e63-8f75-deb4c77f78d2	eb879db6-c526-4003-8bec-e8f07ac3cdc8	10000	1000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
b0bae230-e719-420c-8c46-39e75ab04356	39aaa16f-c3f6-4cdb-93c7-1d4876a6631d	500	50 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
fb052282-4d40-451b-984a-9503fff1833c	eb00de78-77b9-4837-a825-5e59b025ac15	2500	250 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
8c40fce8-39bf-4179-ac40-aba391788a0a	0018538d-5baf-4aab-b3ad-df923d206e99	1000000	100000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
138ce95c-b095-4792-963c-6f0ecaaa2716	585e733a-aecd-4fe4-9135-80fcd86ae971	5000000	500000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
2b9b8652-2a8c-49c1-b011-816bf31fd3db	657dc12a-392f-4b4c-a5db-2a0838afc9e2	50000	5000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
2f77a685-e977-4826-be62-ff470f3c7536	188a926f-d2f9-4e4c-a36e-189f474a9c4a	200000	20000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
649bd3a3-ce56-4bc0-a6d2-a0e8d56f9779	76a86ae2-ba9f-4227-8cbb-4829624f218d	5000	500 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
2bc474e0-9a74-40ff-bbf7-4e528d1050a8	3a7c7fb7-7652-412a-996b-5dd4066136dd	200000	20000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
cbccbaf2-70c8-4c7e-8738-ecce6b277a8d	9f133b0f-6c76-45f2-addb-7225d8250cbe	1000	100 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
400def08-0db6-4ae7-b11d-8d130fdce194	81628caf-5edc-47b0-9bb0-9e6e06b3c7ed	5000000	500000 Toman	0	t	f	\N	\N	\N	f	2026-08-15 20:32:00.039159+00	2026-08-15 20:32:00.039159+00
\.


--
-- Data for Name: template_prize_distributions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.template_prize_distributions (id, template_id, rank, percentage, min_participants, created_at) FROM stdin;
263b1f5d-4bcf-46be-a9b8-011a1104de10	785af236-6a0c-4864-8fb9-380328df1c8b	1	50.00	2	2026-08-15 20:31:59.809037+00
bd8a26e8-d38c-4cab-b9be-1d6f0320df0a	db9ec1a2-41f5-4bda-b7fe-98daf35c9d27	1	50.00	2	2026-08-15 20:31:59.809037+00
c34c9f92-2165-41bb-a500-28de4a6821f5	188a926f-d2f9-4e4c-a36e-189f474a9c4a	1	50.00	2	2026-08-15 20:31:59.809037+00
c4f222ab-4f5b-4b25-aaa6-2de26254bf74	eba90188-f7ff-4a81-bfe8-fc096d8088e1	1	50.00	2	2026-08-15 20:31:59.809037+00
947d4f96-32d1-43e4-b4ac-9051a88953d8	08f9816f-f704-470c-836e-5478e45e35d2	1	50.00	2	2026-08-15 20:31:59.809037+00
62025b24-ce59-4343-8761-68953cd050e8	8d96e9c9-f3b0-4b36-8839-aaeaf393490c	1	50.00	2	2026-08-15 20:31:59.809037+00
a0ee430e-deaf-4f5e-9e12-df652243a075	a56aa614-e426-4c74-a06f-d37651ca211f	1	50.00	2	2026-08-15 20:31:59.809037+00
b230f2c9-835d-4b19-b37f-7a5cbb65afba	3a7c7fb7-7652-412a-996b-5dd4066136dd	1	50.00	2	2026-08-15 20:31:59.809037+00
5e71a18b-1a6e-47c1-8496-41ab172cf226	657dc12a-392f-4b4c-a5db-2a0838afc9e2	1	50.00	2	2026-08-15 20:31:59.809037+00
22667a97-829f-4f71-bc43-187e7b42587f	2348f35a-e3d2-4565-b8b9-8b4e67556985	1	50.00	2	2026-08-15 20:31:59.809037+00
72d0ddfc-4bb5-49a3-bdc5-3a4081673204	0018538d-5baf-4aab-b3ad-df923d206e99	1	50.00	2	2026-08-15 20:31:59.809037+00
f5ac6102-ce11-4ed0-8234-6c6b68c8b256	459a8be1-1fd0-4c3b-91d1-73d0ed21ccf3	1	50.00	2	2026-08-15 20:31:59.809037+00
b0262666-becb-49d8-a7cc-bc051707d6e1	68db9037-e36a-4802-aed3-d40fe401c98b	1	50.00	2	2026-08-15 20:31:59.809037+00
0fbb2799-07ce-416e-831d-45581593097a	b267a919-d2e9-42c8-8a2b-4266951f325e	1	50.00	2	2026-08-15 20:31:59.809037+00
f45f8437-6f0b-4e0d-bef6-e886322d4fb3	585e733a-aecd-4fe4-9135-80fcd86ae971	1	50.00	2	2026-08-15 20:31:59.809037+00
2480dcce-db00-4343-90ec-aaac62a15c45	8351bfc9-a09a-4ed2-9616-3fb2e83ba7be	1	50.00	2	2026-08-15 20:31:59.809037+00
70e98307-7c05-47c3-bc7e-903bf3aaa864	81628caf-5edc-47b0-9bb0-9e6e06b3c7ed	1	50.00	2	2026-08-15 20:31:59.809037+00
5f6656a5-11c1-4518-a3dc-7a4d0d57bb91	11133e82-fe5a-4c63-8b33-806a55e09e51	1	50.00	2	2026-08-15 20:31:59.809037+00
e3da5a3c-4cfc-4830-ab81-b1dd2c6211da	7813e966-37bd-4a81-8c76-5df7ad74071c	1	50.00	2	2026-08-15 20:31:59.809037+00
863f29ba-2b6a-4433-9123-f8aca67b1e76	785af236-6a0c-4864-8fb9-380328df1c8b	2	30.00	5	2026-08-15 20:31:59.809037+00
7126b82e-d7fa-4174-9938-79d452f6a9eb	db9ec1a2-41f5-4bda-b7fe-98daf35c9d27	2	30.00	5	2026-08-15 20:31:59.809037+00
95ba9fea-679a-4a39-9867-41d193efeeb0	188a926f-d2f9-4e4c-a36e-189f474a9c4a	2	30.00	5	2026-08-15 20:31:59.809037+00
1f325f00-a447-4440-8251-2e4b95551070	eba90188-f7ff-4a81-bfe8-fc096d8088e1	2	30.00	5	2026-08-15 20:31:59.809037+00
11802a89-fa74-4f66-add0-9b68c192fb29	08f9816f-f704-470c-836e-5478e45e35d2	2	30.00	5	2026-08-15 20:31:59.809037+00
48a37843-4cca-4700-9e4e-2af574a4f52b	8d96e9c9-f3b0-4b36-8839-aaeaf393490c	2	30.00	5	2026-08-15 20:31:59.809037+00
0f41c32d-a025-4133-a1af-3039fd8840ce	a56aa614-e426-4c74-a06f-d37651ca211f	2	30.00	5	2026-08-15 20:31:59.809037+00
779c2eea-7735-4424-a5aa-0abb88b8aaa6	3a7c7fb7-7652-412a-996b-5dd4066136dd	2	30.00	5	2026-08-15 20:31:59.809037+00
139efad9-e118-441f-a940-ffa83cc02f66	657dc12a-392f-4b4c-a5db-2a0838afc9e2	2	30.00	5	2026-08-15 20:31:59.809037+00
1fcdcdf8-3862-4920-aca3-528663602f36	2348f35a-e3d2-4565-b8b9-8b4e67556985	2	30.00	5	2026-08-15 20:31:59.809037+00
aaa8750f-7f4b-4c9d-9b6a-7f2a66bfe7d2	0018538d-5baf-4aab-b3ad-df923d206e99	2	30.00	5	2026-08-15 20:31:59.809037+00
e06d8e3f-3b09-4d11-b46f-6dc84fb68c8b	459a8be1-1fd0-4c3b-91d1-73d0ed21ccf3	2	30.00	5	2026-08-15 20:31:59.809037+00
87ece1f2-dfa5-48fa-81cc-d2d3c5a0ce22	68db9037-e36a-4802-aed3-d40fe401c98b	2	30.00	5	2026-08-15 20:31:59.809037+00
b3cfb1ea-88bf-4caa-9a64-8e9fb9969c3a	b267a919-d2e9-42c8-8a2b-4266951f325e	2	30.00	5	2026-08-15 20:31:59.809037+00
d0bbbca1-43f3-4e09-91af-877e1eb5b992	585e733a-aecd-4fe4-9135-80fcd86ae971	2	30.00	5	2026-08-15 20:31:59.809037+00
3b55f9cb-259b-49a5-ab40-11c0cd036a52	8351bfc9-a09a-4ed2-9616-3fb2e83ba7be	2	30.00	5	2026-08-15 20:31:59.809037+00
8493f202-b66a-4f27-8378-08095836b8a8	81628caf-5edc-47b0-9bb0-9e6e06b3c7ed	2	30.00	5	2026-08-15 20:31:59.809037+00
20f6049f-bbc7-47fa-8a6d-d39260cc55d8	11133e82-fe5a-4c63-8b33-806a55e09e51	2	30.00	5	2026-08-15 20:31:59.809037+00
2b5c0345-9821-4d5d-96f3-b73260b69b4b	7813e966-37bd-4a81-8c76-5df7ad74071c	2	30.00	5	2026-08-15 20:31:59.809037+00
812f73b8-2062-40b1-9618-4b7644e30774	785af236-6a0c-4864-8fb9-380328df1c8b	3	20.00	10	2026-08-15 20:31:59.809037+00
cdce0110-5602-4e11-9d4d-9b8dfa728c03	db9ec1a2-41f5-4bda-b7fe-98daf35c9d27	3	20.00	10	2026-08-15 20:31:59.809037+00
47e12624-5c99-403a-aaec-1ac441cb8081	188a926f-d2f9-4e4c-a36e-189f474a9c4a	3	20.00	10	2026-08-15 20:31:59.809037+00
cd609f2c-3788-4c46-bd21-f71fe841e0d3	eba90188-f7ff-4a81-bfe8-fc096d8088e1	3	20.00	10	2026-08-15 20:31:59.809037+00
55d77f65-be7f-44e6-9464-7baea3b4d9b2	08f9816f-f704-470c-836e-5478e45e35d2	3	20.00	10	2026-08-15 20:31:59.809037+00
974e3656-fdcd-4ff2-818e-e7800817edb6	8d96e9c9-f3b0-4b36-8839-aaeaf393490c	3	20.00	10	2026-08-15 20:31:59.809037+00
121d812a-84c5-4c70-90fd-67eb5ac71f49	a56aa614-e426-4c74-a06f-d37651ca211f	3	20.00	10	2026-08-15 20:31:59.809037+00
622e5113-969b-4dbd-a5d1-12963151088c	3a7c7fb7-7652-412a-996b-5dd4066136dd	3	20.00	10	2026-08-15 20:31:59.809037+00
7b8135c8-582a-4bd0-9ab8-e3b4a8001c91	657dc12a-392f-4b4c-a5db-2a0838afc9e2	3	20.00	10	2026-08-15 20:31:59.809037+00
999c51a9-d59c-4d51-ba21-de98c3ea2635	2348f35a-e3d2-4565-b8b9-8b4e67556985	3	20.00	10	2026-08-15 20:31:59.809037+00
f061aa64-1dc9-46e9-ad1c-52460b8a1db9	0018538d-5baf-4aab-b3ad-df923d206e99	3	20.00	10	2026-08-15 20:31:59.809037+00
df4dfe44-1129-4d95-bd50-b21e62c66bfb	459a8be1-1fd0-4c3b-91d1-73d0ed21ccf3	3	20.00	10	2026-08-15 20:31:59.809037+00
f589cff5-3a6f-4a4b-be6f-85cd1c42c578	68db9037-e36a-4802-aed3-d40fe401c98b	3	20.00	10	2026-08-15 20:31:59.809037+00
64e29e06-595c-43d2-a62b-2d0801afe01f	b267a919-d2e9-42c8-8a2b-4266951f325e	3	20.00	10	2026-08-15 20:31:59.809037+00
5aaa6fc1-2aba-4e46-be4e-aac054b97dfa	585e733a-aecd-4fe4-9135-80fcd86ae971	3	20.00	10	2026-08-15 20:31:59.809037+00
793e855a-e238-4a90-a578-bc6a1108a5ef	8351bfc9-a09a-4ed2-9616-3fb2e83ba7be	3	20.00	10	2026-08-15 20:31:59.809037+00
477ffa9a-043c-4e7c-9491-92a88a34ac02	81628caf-5edc-47b0-9bb0-9e6e06b3c7ed	3	20.00	10	2026-08-15 20:31:59.809037+00
d403ba10-6485-41e4-8485-986aab04924c	11133e82-fe5a-4c63-8b33-806a55e09e51	3	20.00	10	2026-08-15 20:31:59.809037+00
918573f9-9ec9-4ead-8a7d-51f3597b54b8	7813e966-37bd-4a81-8c76-5df7ad74071c	3	20.00	10	2026-08-15 20:31:59.809037+00
d3c3a5dc-0295-4187-9c53-0f915274de3a	757557fe-1fc3-4116-9652-8793a64b6e94	1	100.00	2	2026-08-15 20:31:59.809037+00
a3040518-ef14-429e-90f1-c800b1870029	1933747d-a9cd-4fe1-8b74-1f14585a8c67	1	100.00	2	2026-08-15 20:31:59.809037+00
\.


--
-- Data for Name: ticket_attachments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ticket_attachments (id, message_id, file_name, file_size, content_type, storage_key, created_at) FROM stdin;
\.


--
-- Data for Name: ticket_messages; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ticket_messages (id, ticket_id, sender_id, is_admin, body, created_at) FROM stdin;
\.


--
-- Data for Name: tier_prize_distributions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tier_prize_distributions (id, tier_id, rank, percentage, min_participants, created_at) FROM stdin;
\.


--
-- Data for Name: tournament_schedules; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tournament_schedules (id, template_id, cron_expression, start_time_utc, active_days, weekend_behavior, is_active, created_at, updated_at) FROM stdin;
ab903416-bd92-4007-8edc-1b9d22d99f69	785af236-6a0c-4864-8fb9-380328df1c8b	*/10 * * * *	\N	{0,1,2,3,4,5,6}	crypto_only	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
16805ae0-9e1f-4918-af03-fffb77ce5502	db9ec1a2-41f5-4bda-b7fe-98daf35c9d27	*/10 * * * *	\N	{0,1,2,3,4,5,6}	crypto_only	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
bffdfa0f-e4e1-472c-a821-073ac54f7241	188a926f-d2f9-4e4c-a36e-189f474a9c4a	*/10 * * * *	\N	{0,1,2,3,4,5,6}	crypto_only	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
ca3d1c88-bbfb-49b5-add4-7f293cfea80a	eba90188-f7ff-4a81-bfe8-fc096d8088e1	*/10 * * * *	\N	{0,1,2,3,4,5,6}	crypto_only	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
8b801fc6-f02f-4642-809c-dd4c65e0fe10	08f9816f-f704-470c-836e-5478e45e35d2	*/10 * * * *	\N	{0,1,2,3,4,5,6}	crypto_only	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
909a40e1-2ec0-4c3a-beb7-c873f2af9a87	8d96e9c9-f3b0-4b36-8839-aaeaf393490c	*/10 * * * *	\N	{0,1,2,3,4,5,6}	crypto_only	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
69cdc262-bb3b-4125-9117-c89ec3999b71	41324aa6-7cc0-4f27-af4d-a2ac78d1db70	0 */1 * * *	\N	{0,1,2,3,4,5,6}	crypto_only	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
1e07a636-d6d6-4bfa-a939-d5109560a39a	46a7dc3e-2adc-46bb-8bb8-939d8fcbd28b	0 */1 * * *	\N	{0,1,2,3,4,5,6}	crypto_only	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
45b8422b-1daa-43f7-8cc7-23386dd71f17	757557fe-1fc3-4116-9652-8793a64b6e94	30 13,17 * * *	\N	{0,1,2,3,4,5,6}	crypto_only	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
822a1b67-ae25-4ecf-9b76-099213f503de	1933747d-a9cd-4fe1-8b74-1f14585a8c67	30 13,17 * * *	\N	{0,1,2,3,4,5,6}	crypto_only	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
f8bff769-fb76-44b0-9304-3b3c88929158	a56aa614-e426-4c74-a06f-d37651ca211f	30 20,0,4,8,12,16 * * *	\N	{0,1,2,3,4,5,6}	crypto_only	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
0c81561a-a233-413c-a664-fe4eba530fc5	3a7c7fb7-7652-412a-996b-5dd4066136dd	30 20,0,4,8,12,16 * * *	\N	{0,1,2,3,4,5,6}	crypto_only	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
98a6019d-553f-4e3b-9273-4fc65e07fef1	657dc12a-392f-4b4c-a5db-2a0838afc9e2	30 20,0,4,8,12,16 * * *	\N	{0,1,2,3,4,5,6}	crypto_only	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
bce1b4dd-a530-4bc4-9d43-d235fb52da1c	2348f35a-e3d2-4565-b8b9-8b4e67556985	30 20,0,4,8,12,16 * * *	\N	{0,1,2,3,4,5,6}	crypto_only	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
7109eea4-767a-495c-8ccd-8f61e2bd9726	0018538d-5baf-4aab-b3ad-df923d206e99	30 20 * * *	\N	{0,1,2,3,4,5,6}	normal	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
ecbd267e-7070-416f-a237-d7a96d6fc47d	459a8be1-1fd0-4c3b-91d1-73d0ed21ccf3	30 20 * * *	\N	{2,3,4,5,6}	skip	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
7ff00973-b244-4345-89af-cc9b21ccbb1f	68db9037-e36a-4802-aed3-d40fe401c98b	30 20 * * *	\N	{2,3,4,5,6}	skip	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
5745c0ea-3f16-4ad4-a211-dffface9d725	b267a919-d2e9-42c8-8a2b-4266951f325e	30 20 * * 6	\N	{0,1,2,3,4,5,6}	normal	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
434a6355-878d-4f50-b2d8-90f13d4d542b	585e733a-aecd-4fe4-9135-80fcd86ae971	30 20 * * 6	\N	{0,1,2,3,4,5,6}	normal	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
efd19905-2463-4637-9ef4-041e57700292	8351bfc9-a09a-4ed2-9616-3fb2e83ba7be	30 20 * * 6	\N	{0,1,2,3,4,5,6}	normal	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
9f6d9eb5-1dfb-4dfc-8195-34d5e283eaf7	81628caf-5edc-47b0-9bb0-9e6e06b3c7ed	30 20 * * 6	\N	{0,1,2,3,4,5,6}	normal	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
6b6defed-d0f5-4fa7-90b8-0ec63ddfdec5	11133e82-fe5a-4c63-8b33-806a55e09e51	30 20 * * 6	\N	{0,1,2,3,4,5,6}	normal	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
3428e31e-e275-40c2-b773-7ba7b3a5f142	7813e966-37bd-4a81-8c76-5df7ad74071c	30 20 * * 6	\N	{0,1,2,3,4,5,6}	normal	t	2026-08-15 20:31:59.829512+00	2026-08-15 20:31:59.829512+00
\.


--
-- Data for Name: tournament_templates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tournament_templates (id, name, description, duration_minutes, is_free, entry_fee_cents, qty_total, symbols_json, prize_distribution_json, max_participants, auto_create, create_cron, created_at, asset_class, commission_rate, min_participants, auto_start, template_key, recurrence_rule, next_occurrence_at, last_generated_at, type, updated_at, market_type, template_duration_type, entry_fee, has_prize, is_active) FROM stdin;
604bd3d7-4aa6-4e9e-93ef-ce10a70b5ac5	Hourly Practice	Free practice tournament that runs every hour. Perfect for honing your trading skills without any risk. Compete against other traders using virtual currency.	60	t	0	100000	["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA"]	\N	1000	t	0 * * * *	2026-08-15 20:31:58.187627+00	mixed	17.00	2	f	\N	\N	\N	\N	practice	2026-08-15 20:31:59.716354+00	crypto	free_1h	0	t	t
39aaa16f-c3f6-4cdb-93c7-1d4876a6631d	Crypto Rush 30min	Fast-paced 30-minute crypto trading competition. Trade popular cryptocurrencies with quick results.	30	f	500	50000	["BTC/USD", "ETH/USD", "SOL/USD", "DOGE/USD", "XRP/USD"]	\N	100	f	\N	2026-08-15 20:31:58.472897+00	crypto	17.00	2	f	crypto_rush_30m	\N	\N	\N	rush	2026-08-15 20:31:59.716354+00	crypto	quick_30m	500	t	t
b39dad6f-e3a8-4274-ae37-b1b6a64040fc	Free Crypto Practice	Free practice tournament to learn crypto trading. No entry fee, just compete for fun!	60	t	0	100000	["BTC/USD", "ETH/USD", "SOL/USD", "DOGE/USD", "XRP/USD"]	\N	1000	f	\N	2026-08-15 20:31:58.472897+00	crypto	0.00	2	t	crypto_free_practice	\N	\N	\N	practice	2026-08-15 20:31:59.716354+00	crypto	free_1h	0	t	t
ef1146ce-7959-4836-aa51-009f44b76035	Free Forex Practice	Free practice tournament to learn forex trading. No entry fee, learn risk-free!	60	t	0	100000	["EUR/USD", "GBP/USD", "USD/JPY", "AUD/USD", "USD/CAD"]	\N	1000	f	\N	2026-08-15 20:31:58.472897+00	forex	0.00	2	t	forex_free_practice	\N	\N	\N	practice	2026-08-15 20:31:59.716354+00	forex	free_1h	0	t	t
0fcf9803-b3fe-443d-9b4c-a61b4d5288b4	Crypto Hourly	One-hour crypto trading tournament. More time to analyze and trade major cryptocurrencies.	60	f	1000	100000	["BTC/USD", "ETH/USD", "SOL/USD", "DOGE/USD", "XRP/USD", "ADA/USD", "AVAX/USD", "LINK/USD"]	\N	200	f	\N	2026-08-15 20:31:58.472897+00	crypto	17.00	2	f	crypto_hourly	\N	\N	\N	standard	2026-08-15 20:31:59.716354+00	crypto	free_1h	1000	t	t
76a86ae2-ba9f-4227-8cbb-4829624f218d	Crypto Daily Challenge	Full-day crypto trading competition with 20 QTY allocation. Test your skills over 24 hours.	1440	f	5000	200000	["BTC/USD", "ETH/USD", "SOL/USD", "DOGE/USD", "XRP/USD", "ADA/USD", "AVAX/USD", "LINK/USD", "DOT/USD", "MATIC/USD", "SHIB/USD", "LTC/USD"]	\N	500	f	\N	2026-08-15 20:31:58.472897+00	crypto	17.00	5	f	crypto_daily	\N	\N	\N	standard	2026-08-15 20:31:59.716354+00	crypto	daily	5000	t	t
479c8ee8-fb05-4896-a7ae-de63fb88b9b7	Forex Rush 30min	Quick 30-minute forex trading competition. Trade major currency pairs with rapid execution.	30	f	500	50000	["EUR/USD", "GBP/USD", "USD/JPY", "USD/CHF", "AUD/USD"]	\N	100	f	\N	2026-08-15 20:31:58.472897+00	forex	17.00	2	f	forex_rush_30m	\N	\N	\N	rush	2026-08-15 20:31:59.716354+00	forex	quick_30m	500	t	t
9f133b0f-6c76-45f2-addb-7225d8250cbe	Forex Hourly	One-hour forex trading tournament. Trade 15+ major currency pairs.	60	f	1000	100000	["EUR/USD", "GBP/USD", "USD/JPY", "USD/CHF", "AUD/USD", "NZD/USD", "USD/CAD", "EUR/GBP", "EUR/JPY", "GBP/JPY", "AUD/JPY", "CHF/JPY", "EUR/AUD", "GBP/AUD", "EUR/CAD"]	\N	200	f	\N	2026-08-15 20:31:58.472897+00	forex	17.00	2	f	forex_hourly	\N	\N	\N	standard	2026-08-15 20:31:59.716354+00	forex	free_1h	1000	t	t
eb00de78-77b9-4837-a825-5e59b025ac15	Forex 4-Hour Tournament	Extended 4-hour forex competition with comprehensive currency pair coverage.	240	f	2500	150000	["EUR/USD", "GBP/USD", "USD/JPY", "USD/CHF", "AUD/USD", "NZD/USD", "USD/CAD", "EUR/GBP", "EUR/JPY", "GBP/JPY", "AUD/JPY", "CHF/JPY", "EUR/AUD", "GBP/AUD", "EUR/CAD", "AUD/NZD", "CAD/JPY", "NZD/JPY", "EUR/CHF", "GBP/CHF"]	\N	300	f	\N	2026-08-15 20:31:58.472897+00	forex	17.00	3	f	forex_4hour	\N	\N	\N	standard	2026-08-15 20:31:59.716354+00	forex	four_hour	2500	t	t
41aec9d1-c1cb-4ba9-bca7-36aaa2c934a4	Forex Daily Championship	24-hour forex trading championship with 33+ currency pairs. Full trading day experience.	1440	f	5000	200000	["EUR/USD", "GBP/USD", "USD/JPY", "USD/CHF", "AUD/USD", "NZD/USD", "USD/CAD", "EUR/GBP", "EUR/JPY", "GBP/JPY", "AUD/JPY", "CHF/JPY", "EUR/AUD", "GBP/AUD", "EUR/CAD", "AUD/NZD", "CAD/JPY", "NZD/JPY", "EUR/CHF", "GBP/CHF", "EUR/NZD", "GBP/NZD", "AUD/CAD", "NZD/CAD", "SGD/JPY", "USD/SGD", "USD/HKD", "USD/MXN", "USD/ZAR", "EUR/PLN", "EUR/TRY", "USD/TRY", "GBP/CAD"]	\N	500	f	\N	2026-08-15 20:31:58.472897+00	forex	17.00	5	f	forex_daily	\N	\N	\N	standard	2026-08-15 20:31:59.716354+00	forex	daily	5000	t	t
54b73492-5037-4a14-b3b5-83918b8d7e82	US Stocks Daily	Daily competition trading top 30 US equities. Market hours only.	1440	f	5000	200000	["AAPL", "MSFT", "GOOGL", "AMZN", "TSLA", "META", "NVDA", "BRK.B", "JPM", "JNJ", "V", "PG", "UNH", "HD", "MA", "DIS", "ADBE", "NFLX", "CRM", "PYPL", "INTC", "CSCO", "VZ", "KO", "PFE", "MRK", "ABT", "WMT", "NKE", "XOM"]	\N	500	f	\N	2026-08-15 20:31:58.472897+00	stocks	17.00	5	f	stocks_daily	\N	\N	\N	standard	2026-08-15 20:31:59.716354+00	crypto	daily	5000	t	t
87ca7de1-10eb-4acd-b9a7-8750787e488b	Forex Weekly Grand Prix	Week-long forex competition for serious traders. Maximum strategy time with full pair coverage.	10080	f	10000	500000	["EUR/USD", "GBP/USD", "USD/JPY", "USD/CHF", "AUD/USD", "NZD/USD", "USD/CAD", "EUR/GBP", "EUR/JPY", "GBP/JPY", "AUD/JPY", "CHF/JPY", "EUR/AUD", "GBP/AUD", "EUR/CAD", "AUD/NZD", "CAD/JPY", "NZD/JPY", "EUR/CHF", "GBP/CHF", "EUR/NZD", "GBP/NZD", "AUD/CAD", "NZD/CAD", "SGD/JPY", "USD/SGD", "USD/HKD", "USD/MXN", "USD/ZAR", "EUR/PLN", "EUR/TRY", "USD/TRY", "GBP/CAD"]	\N	1000	f	\N	2026-08-15 20:31:58.472897+00	forex	17.00	10	f	forex_weekly	\N	\N	\N	championship	2026-08-15 20:31:59.716354+00	forex	weekly	10000	t	t
e0b892c9-3519-4027-b979-9cf6c5560d64	High Stakes Crypto	Professional-level crypto trading competition with $100 entry. High risk, high reward.	240	f	10000	200000	["BTC/USD", "ETH/USD", "SOL/USD", "DOGE/USD", "XRP/USD", "ADA/USD", "AVAX/USD", "LINK/USD", "DOT/USD", "MATIC/USD", "SHIB/USD", "LTC/USD"]	\N	50	f	\N	2026-08-15 20:31:58.472897+00	crypto	17.00	5	f	crypto_high_stakes	\N	\N	\N	standard	2026-08-15 20:31:59.716354+00	crypto	four_hour	10000	t	t
eb879db6-c526-4003-8bec-e8f07ac3cdc8	High Stakes Forex	Professional-level forex trading competition with $100 entry. For experienced traders.	240	f	10000	200000	["EUR/USD", "GBP/USD", "USD/JPY", "USD/CHF", "AUD/USD", "NZD/USD", "USD/CAD", "EUR/GBP", "EUR/JPY", "GBP/JPY", "AUD/JPY", "CHF/JPY", "EUR/AUD", "GBP/AUD", "EUR/CAD", "AUD/NZD", "CAD/JPY", "NZD/JPY", "EUR/CHF", "GBP/CHF"]	\N	50	f	\N	2026-08-15 20:31:58.472897+00	forex	17.00	5	f	forex_high_stakes	\N	\N	\N	standard	2026-08-15 20:31:59.716354+00	forex	four_hour	10000	t	t
785af236-6a0c-4864-8fb9-380328df1c8b	Crypto Quick 50K	Fast 30-minute crypto tournament with 50,000 Rial entry. Trade top cryptocurrencies for quick results.	30	f	0	50000	["BTC/USD", "ETH/USD", "SOL/USD", "DOGE/USD", "XRP/USD"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	crypto	0.20	2	f	crypto_quick_50k	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	crypto	quick_30m	50000	f	t
db9ec1a2-41f5-4bda-b7fe-98daf35c9d27	Crypto Quick 100K	Fast 30-minute crypto tournament with 100,000 Rial entry. Trade top cryptocurrencies for quick results.	30	f	0	50000	["BTC/USD", "ETH/USD", "SOL/USD", "DOGE/USD", "XRP/USD"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	crypto	0.20	2	f	crypto_quick_100k	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	crypto	quick_30m	100000	f	t
188a926f-d2f9-4e4c-a36e-189f474a9c4a	Crypto Quick 200K	Fast 30-minute crypto tournament with 200,000 Rial entry. Trade top cryptocurrencies for quick results.	30	f	0	50000	["BTC/USD", "ETH/USD", "SOL/USD", "DOGE/USD", "XRP/USD"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	crypto	0.20	2	f	crypto_quick_200k	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	crypto	quick_30m	200000	f	t
eba90188-f7ff-4a81-bfe8-fc096d8088e1	Forex Quick 50K	Fast 30-minute forex tournament with 50,000 Rial entry. Trade major currency pairs for quick results.	30	f	0	50000	["EUR/USD", "GBP/USD", "USD/JPY", "USD/CHF", "AUD/USD"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	forex	0.20	2	f	forex_quick_50k	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	forex	quick_30m	50000	f	t
08f9816f-f704-470c-836e-5478e45e35d2	Forex Quick 100K	Fast 30-minute forex tournament with 100,000 Rial entry. Trade major currency pairs for quick results.	30	f	0	50000	["EUR/USD", "GBP/USD", "USD/JPY", "USD/CHF", "AUD/USD"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	forex	0.20	2	f	forex_quick_100k	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	forex	quick_30m	100000	f	t
8d96e9c9-f3b0-4b36-8839-aaeaf393490c	Forex Quick 200K	Fast 30-minute forex tournament with 200,000 Rial entry. Trade major currency pairs for quick results.	30	f	0	50000	["EUR/USD", "GBP/USD", "USD/JPY", "USD/CHF", "AUD/USD"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	forex	0.20	2	f	forex_quick_200k	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	forex	quick_30m	200000	f	t
41324aa6-7cc0-4f27-af4d-a2ac78d1db70	Crypto Free	Free 1-hour crypto practice tournament. No entry fee — compete for fun and experience!	60	t	0	100000	["BTC/USD", "ETH/USD", "SOL/USD", "DOGE/USD", "XRP/USD"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	crypto	0.00	2	f	crypto_free_1h	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	crypto	free_1h	0	f	t
46a7dc3e-2adc-46bb-8bb8-939d8fcbd28b	Forex Free	Free 1-hour forex practice tournament. No entry fee — learn risk-free!	60	t	0	100000	["EUR/USD", "GBP/USD", "USD/JPY", "USD/CHF", "AUD/USD"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	forex	0.00	2	f	forex_free_1h	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	forex	free_1h	0	f	t
757557fe-1fc3-4116-9652-8793a64b6e94	Crypto Free Featured	Featured free 1-hour crypto tournament with a platform-funded prize. Win real prizes at no cost!	60	t	0	100000	["BTC/USD", "ETH/USD", "SOL/USD", "DOGE/USD", "XRP/USD"]	[{"rank": 1, "type": "fixed", "amount_rials": 100000}]	\N	f	\N	2026-08-15 20:31:59.809037+00	crypto	0.00	2	f	crypto_free_featured_1h	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	crypto	free_1h	0	t	t
1933747d-a9cd-4fe1-8b74-1f14585a8c67	Forex Free Featured	Featured free 1-hour forex tournament with a platform-funded prize. Win real prizes at no cost!	60	t	0	100000	["EUR/USD", "GBP/USD", "USD/JPY", "USD/CHF", "AUD/USD"]	[{"rank": 1, "type": "fixed", "amount_rials": 100000}]	\N	f	\N	2026-08-15 20:31:59.809037+00	forex	0.00	2	f	forex_free_featured_1h	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	forex	free_1h	0	t	t
a56aa614-e426-4c74-a06f-d37651ca211f	Crypto 4-Hour 50K	4-hour crypto trading tournament with 50,000 Rial entry. Extended time for deeper analysis.	240	f	0	150000	["BTC/USD", "ETH/USD", "SOL/USD", "DOGE/USD", "XRP/USD", "ADA/USD", "AVAX/USD", "LINK/USD", "DOT/USD", "MATIC/USD", "SHIB/USD", "LTC/USD"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	crypto	0.20	2	f	crypto_4h_50k	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	crypto	four_hour	50000	t	t
3a7c7fb7-7652-412a-996b-5dd4066136dd	Crypto 4-Hour 200K	4-hour crypto trading tournament with 200,000 Rial entry. Higher stakes, bigger prizes.	240	f	0	150000	["BTC/USD", "ETH/USD", "SOL/USD", "DOGE/USD", "XRP/USD", "ADA/USD", "AVAX/USD", "LINK/USD", "DOT/USD", "MATIC/USD", "SHIB/USD", "LTC/USD"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	crypto	0.20	2	f	crypto_4h_200k	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	crypto	four_hour	200000	t	t
657dc12a-392f-4b4c-a5db-2a0838afc9e2	Forex 4-Hour 50K	4-hour forex trading tournament with 50,000 Rial entry. Trade 20 currency pairs.	240	f	0	150000	["EUR/USD", "GBP/USD", "USD/JPY", "USD/CHF", "AUD/USD", "NZD/USD", "USD/CAD", "EUR/GBP", "EUR/JPY", "GBP/JPY", "AUD/JPY", "CHF/JPY", "EUR/AUD", "GBP/AUD", "EUR/CAD", "AUD/NZD", "CAD/JPY", "NZD/JPY", "EUR/CHF", "GBP/CHF"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	forex	0.20	2	f	forex_4h_50k	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	forex	four_hour	50000	t	t
2348f35a-e3d2-4565-b8b9-8b4e67556985	Forex 4-Hour 200K	4-hour forex trading tournament with 200,000 Rial entry. Higher stakes with 20 currency pairs.	240	f	0	150000	["EUR/USD", "GBP/USD", "USD/JPY", "USD/CHF", "AUD/USD", "NZD/USD", "USD/CAD", "EUR/GBP", "EUR/JPY", "GBP/JPY", "AUD/JPY", "CHF/JPY", "EUR/AUD", "GBP/AUD", "EUR/CAD", "AUD/NZD", "CAD/JPY", "NZD/JPY", "EUR/CHF", "GBP/CHF"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	forex	0.20	2	f	forex_4h_200k	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	forex	four_hour	200000	t	t
0018538d-5baf-4aab-b3ad-df923d206e99	Crypto Daily 1M	Full-day 24-hour crypto tournament with 1,000,000 Rial entry. Test your skills with 12 major coins.	1440	f	0	200000	["BTC/USD", "ETH/USD", "SOL/USD", "DOGE/USD", "XRP/USD", "ADA/USD", "AVAX/USD", "LINK/USD", "DOT/USD", "MATIC/USD", "SHIB/USD", "LTC/USD"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	crypto	0.20	2	f	crypto_daily_1m	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	crypto	daily	1000000	t	t
459a8be1-1fd0-4c3b-91d1-73d0ed21ccf3	Forex Daily 500K	22-hour forex tournament with 500,000 Rial entry. Ends at 22:00 IRST (forex market close). 33 currency pairs.	1320	f	0	200000	["EUR/USD", "GBP/USD", "USD/JPY", "USD/CHF", "AUD/USD", "NZD/USD", "USD/CAD", "EUR/GBP", "EUR/JPY", "GBP/JPY", "AUD/JPY", "CHF/JPY", "EUR/AUD", "GBP/AUD", "EUR/CAD", "AUD/NZD", "CAD/JPY", "NZD/JPY", "EUR/CHF", "GBP/CHF", "EUR/NZD", "GBP/NZD", "AUD/CAD", "NZD/CAD", "SGD/JPY", "USD/SGD", "USD/HKD", "USD/MXN", "USD/ZAR", "EUR/PLN", "EUR/TRY", "USD/TRY", "GBP/CAD"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	forex	0.20	2	f	forex_daily_500k	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	forex	daily	500000	t	t
68db9037-e36a-4802-aed3-d40fe401c98b	Forex Daily 1.5M	22-hour forex tournament with 1,500,000 Rial entry. Ends at 22:00 IRST (forex market close). 33 currency pairs.	1320	f	0	200000	["EUR/USD", "GBP/USD", "USD/JPY", "USD/CHF", "AUD/USD", "NZD/USD", "USD/CAD", "EUR/GBP", "EUR/JPY", "GBP/JPY", "AUD/JPY", "CHF/JPY", "EUR/AUD", "GBP/AUD", "EUR/CAD", "AUD/NZD", "CAD/JPY", "NZD/JPY", "EUR/CHF", "GBP/CHF", "EUR/NZD", "GBP/NZD", "AUD/CAD", "NZD/CAD", "SGD/JPY", "USD/SGD", "USD/HKD", "USD/MXN", "USD/ZAR", "EUR/PLN", "EUR/TRY", "USD/TRY", "GBP/CAD"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	forex	0.20	2	f	forex_daily_1500k	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	forex	daily	1500000	t	t
b267a919-d2e9-42c8-8a2b-4266951f325e	Crypto Weekly 2.5M	Week-long crypto tournament (Saturday to Saturday IRST) with 2,500,000 Rial entry. 12 major coins.	10080	f	0	500000	["BTC/USD", "ETH/USD", "SOL/USD", "DOGE/USD", "XRP/USD", "ADA/USD", "AVAX/USD", "LINK/USD", "DOT/USD", "MATIC/USD", "SHIB/USD", "LTC/USD"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	crypto	0.20	2	f	crypto_weekly_2500k	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	crypto	weekly	2500000	t	t
585e733a-aecd-4fe4-9135-80fcd86ae971	Crypto Weekly 5M	Week-long crypto tournament (Saturday to Saturday IRST) with 5,000,000 Rial entry. 12 major coins.	10080	f	0	500000	["BTC/USD", "ETH/USD", "SOL/USD", "DOGE/USD", "XRP/USD", "ADA/USD", "AVAX/USD", "LINK/USD", "DOT/USD", "MATIC/USD", "SHIB/USD", "LTC/USD"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	crypto	0.20	2	f	crypto_weekly_5m	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	crypto	weekly	5000000	t	t
8351bfc9-a09a-4ed2-9616-3fb2e83ba7be	Crypto Weekly 10M	Week-long crypto tournament (Saturday to Saturday IRST) with 10,000,000 Rial entry. 12 major coins.	10080	f	0	500000	["BTC/USD", "ETH/USD", "SOL/USD", "DOGE/USD", "XRP/USD", "ADA/USD", "AVAX/USD", "LINK/USD", "DOT/USD", "MATIC/USD", "SHIB/USD", "LTC/USD"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	crypto	0.20	2	f	crypto_weekly_10m	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	crypto	weekly	10000000	t	t
81628caf-5edc-47b0-9bb0-9e6e06b3c7ed	Forex Weekly 5M	Forex weekly tournament (Saturday to Wednesday 22:00 IRST) with 5,000,000 Rial entry. 33 currency pairs.	7320	f	0	500000	["EUR/USD", "GBP/USD", "USD/JPY", "USD/CHF", "AUD/USD", "NZD/USD", "USD/CAD", "EUR/GBP", "EUR/JPY", "GBP/JPY", "AUD/JPY", "CHF/JPY", "EUR/AUD", "GBP/AUD", "EUR/CAD", "AUD/NZD", "CAD/JPY", "NZD/JPY", "EUR/CHF", "GBP/CHF", "EUR/NZD", "GBP/NZD", "AUD/CAD", "NZD/CAD", "SGD/JPY", "USD/SGD", "USD/HKD", "USD/MXN", "USD/ZAR", "EUR/PLN", "EUR/TRY", "USD/TRY", "GBP/CAD"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	forex	0.20	2	f	forex_weekly_5m	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	forex	weekly	5000000	t	t
11133e82-fe5a-4c63-8b33-806a55e09e51	Forex Weekly 10M	Forex weekly tournament (Saturday to Wednesday 22:00 IRST) with 10,000,000 Rial entry. 33 currency pairs.	7320	f	0	500000	["EUR/USD", "GBP/USD", "USD/JPY", "USD/CHF", "AUD/USD", "NZD/USD", "USD/CAD", "EUR/GBP", "EUR/JPY", "GBP/JPY", "AUD/JPY", "CHF/JPY", "EUR/AUD", "GBP/AUD", "EUR/CAD", "AUD/NZD", "CAD/JPY", "NZD/JPY", "EUR/CHF", "GBP/CHF", "EUR/NZD", "GBP/NZD", "AUD/CAD", "NZD/CAD", "SGD/JPY", "USD/SGD", "USD/HKD", "USD/MXN", "USD/ZAR", "EUR/PLN", "EUR/TRY", "USD/TRY", "GBP/CAD"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	forex	0.20	2	f	forex_weekly_10m	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	forex	weekly	10000000	t	t
7813e966-37bd-4a81-8c76-5df7ad74071c	Forex Weekly 50M	Forex weekly tournament (Saturday to Wednesday 22:00 IRST) with 50,000,000 Rial entry. Premium tier with 33 currency pairs.	7320	f	0	500000	["EUR/USD", "GBP/USD", "USD/JPY", "USD/CHF", "AUD/USD", "NZD/USD", "USD/CAD", "EUR/GBP", "EUR/JPY", "GBP/JPY", "AUD/JPY", "CHF/JPY", "EUR/AUD", "GBP/AUD", "EUR/CAD", "AUD/NZD", "CAD/JPY", "NZD/JPY", "EUR/CHF", "GBP/CHF", "EUR/NZD", "GBP/NZD", "AUD/CAD", "NZD/CAD", "SGD/JPY", "USD/SGD", "USD/HKD", "USD/MXN", "USD/ZAR", "EUR/PLN", "EUR/TRY", "USD/TRY", "GBP/CAD"]	\N	\N	f	\N	2026-08-15 20:31:59.809037+00	forex	0.20	2	f	forex_weekly_50m	\N	\N	\N	standard	2026-08-15 20:31:59.809037+00	forex	weekly	50000000	t	t
\.


--
-- Data for Name: tournaments_archive; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tournaments_archive (id, name, description, starts_at, ends_at, status, entry_fee_cents, platform_fee_bps, qty_total, rules_json, created_at, published_at, started_at, ended_at, settled_at, cancelled_at, cancellation_reason, current_participants, min_participants, max_participants, registration_deadline, registration_opens_at, auto_start, commission_rate, paused_at, total_paused_duration, archived_at) FROM stdin;
\.


--
-- Data for Name: user_notification_preferences; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_notification_preferences (user_id, category, channel, enabled, updated_at) FROM stdin;
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_roles (user_id, role_id, assigned_at) FROM stdin;
256cf845-d483-45bd-89d1-3d0c93c13398	5	2026-08-15 20:33:04.249648+00
4f8aa018-e087-40b3-a12a-15d13ce62eed	1	2026-08-15 20:33:04.438679+00
\.


--
-- Data for Name: user_score_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_score_history (id, user_id, contest_id, rank, score, participants, pnl, trades_count, avg_trade_duration_seconds, top_symbol, top_symbol_pnl, created_at, score_contribution) FROM stdin;
\.


--
-- Data for Name: user_stats; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_stats (user_id, total_contests, total_wins, total_top3, total_score, total_participants, tragge_point, win_rate, avg_trade_duration_seconds, best_market, best_market_pnl, total_trades, total_pnl, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: user_verification; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_verification (user_id, status, first_name, last_name, date_of_birth, nationality, address_line1, address_line2, city, state, postal_code, country, verified_at, verified_by, rejection_reason, expires_at, provider, provider_verification_id, created_at, updated_at, national_code, phone, shahkar_verified, face_verified, face_match_score, liveness_score, liveness_result, card_ocr_verified, card_serial_number, jibit_transaction_ids, national_code_manual, father_name, birth_certificate_number, birth_certificate_serial, rejection_fields, rejection_field_messages, admin_notes) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, email, password_hash, created_at, status, email_verified, email_verified_at, username, display_name, avatar_url, bio, country, phone, updated_at, is_system_account, password_changed_at, totp_secret, totp_enabled, totp_verified_at, backup_codes, terms_accepted_at, ban_expires_at, phone_verified, preferred_lang, telegram_id) FROM stdin;
00000000-0000-0000-0000-000000000001	tbot@tragge.internal	SYSTEM_ACCOUNT_NO_LOGIN	2026-08-15 20:31:59.435518+00	active	f	\N	t-bot	T-bot	\N	\N	\N	\N	2026-08-15 20:32:00.184868+00	t	\N	\N	f	\N	\N	\N	\N	f	fa	\N
4f8aa018-e087-40b3-a12a-15d13ce62eed	user@tragge.com	$argon2id$v=19$m=65536,t=3,p=2$/3JyXlT/RiwbArxb5lsaDA$76aoN+AS6FUI2d7M7SJjsFqKJ4H0gHOev0E9cFfpE5Y	2026-08-15 20:33:04.438679+00	active	t	2026-08-15 20:33:04.438679+00	user	Test User	\N	\N	\N	\N	2026-08-15 20:33:04.438679+00	f	\N	\N	f	\N	\N	2026-08-15 20:33:04.438679+00	\N	f	fa	\N
256cf845-d483-45bd-89d1-3d0c93c13398	admin@tragge.com	$argon2id$v=19$m=65536,t=3,p=2$+PUdIhQCrf6VOxuF9MKshg$O8hBgrDNIspk0tm+RFgWLgQZ/FNQpFp6rA+91FYE4w8	2026-08-15 20:33:04.249648+00	active	t	2026-08-15 20:33:04.249648+00	admin	Super Admin	\N	\N	\N	\N	2026-08-15 21:46:30.567879+00	f	\N	\N	f	\N	\N	2026-08-15 20:33:04.249648+00	\N	f	fa	\N
54aa552a-150a-4502-94aa-552a150a0502	p11-0-54aa552a@example.com	x	2026-08-16 00:33:43.295885+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 00:33:43.295885+00	f	\N	\N	f	\N	\N	2026-08-16 00:33:43.295885+00	\N	f	fa	\N
502894ca-e572-491c-9028-94cae572391c	p11-0-502894ca@example.com	x	2026-08-16 00:34:07.664347+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 00:34:07.664347+00	f	\N	\N	f	\N	\N	2026-08-16 00:34:07.664347+00	\N	f	fa	\N
c864b259-2c96-4b65-8864-b2592c96cb65	p11-0-c864b259@example.com	x	2026-08-16 00:34:27.196967+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 00:34:27.196967+00	f	\N	\N	f	\N	\N	2026-08-16 00:34:27.196967+00	\N	f	fa	\N
90c864b2-592c-464b-90c8-64b2592c964b	p11-0-90c864b2@example.com	x	2026-08-16 00:34:56.091444+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 00:34:56.091444+00	f	\N	\N	f	\N	\N	2026-08-16 00:34:56.091444+00	\N	f	fa	\N
30b7a5b7-62b1-4416-85b0-44824b338226	p2-0-30b7a5b7@example.com	x	2026-08-16 01:05:06.957153+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:05:06.957153+00	f	\N	\N	f	\N	\N	2026-08-16 01:05:06.957153+00	\N	f	fa	\N
7d16b1c9-fa10-4721-9ab1-f9c6dfd7f7c0	p2-0-7d16b1c9@example.com	x	2026-08-16 01:05:27.704544+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:05:27.704544+00	f	\N	\N	f	\N	\N	2026-08-16 01:05:27.704544+00	\N	f	fa	\N
73724a7a-cc59-4aeb-86b5-bc997598c1ec	p2-1-73724a7a@example.com	x	2026-08-16 01:05:27.715497+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:05:27.715497+00	f	\N	\N	f	\N	\N	2026-08-16 01:05:27.715497+00	\N	f	fa	\N
3a6ad88d-a188-4bf0-be1d-bf2706cdbe2a	p2-0-3a6ad88d@example.com	x	2026-08-16 01:05:44.428559+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:05:44.428559+00	f	\N	\N	f	\N	\N	2026-08-16 01:05:44.428559+00	\N	f	fa	\N
912bce1a-5da1-473c-b7cf-832f0ff39bb4	p2-1-912bce1a@example.com	x	2026-08-16 01:05:44.439232+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:05:44.439232+00	f	\N	\N	f	\N	\N	2026-08-16 01:05:44.439232+00	\N	f	fa	\N
863bc837-1fa3-4374-91df-3fe92a7a8694	p2-0-863bc837@example.com	x	2026-08-16 01:06:51.283815+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:06:51.283815+00	f	\N	\N	f	\N	\N	2026-08-16 01:06:51.283815+00	\N	f	fa	\N
5d597832-fd0c-4be5-b1bb-ed1f03c10399	p2-1-5d597832@example.com	x	2026-08-16 01:06:51.293645+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:06:51.293645+00	f	\N	\N	f	\N	\N	2026-08-16 01:06:51.293645+00	\N	f	fa	\N
81741f96-07b2-4e40-801d-470e79ffac94	p2-0-81741f96@example.com	x	2026-08-16 01:06:51.417229+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:06:51.417229+00	f	\N	\N	f	\N	\N	2026-08-16 01:06:51.417229+00	\N	f	fa	\N
8ff79fc3-3043-4a7c-a959-4f2ba6e5e265	p2-0-8ff79fc3@example.com	x	2026-08-16 01:06:51.59817+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:06:51.59817+00	f	\N	\N	f	\N	\N	2026-08-16 01:06:51.59817+00	\N	f	fa	\N
15e34f4d-da6c-4d3f-83c8-17bd2ddb4226	p2-0-15e34f4d@example.com	x	2026-08-16 01:07:18.554706+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:07:18.554706+00	f	\N	\N	f	\N	\N	2026-08-16 01:07:18.554706+00	\N	f	fa	\N
bf942846-2dc6-41a2-afb0-35efd5403110	p2-1-bf942846@example.com	x	2026-08-16 01:07:18.565593+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:07:18.565593+00	f	\N	\N	f	\N	\N	2026-08-16 01:07:18.565593+00	\N	f	fa	\N
4af61bbb-6031-4996-9c0f-f27b00b90fb8	p2-0-4af61bbb@example.com	x	2026-08-16 01:07:18.690487+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:07:18.690487+00	f	\N	\N	f	\N	\N	2026-08-16 01:07:18.690487+00	\N	f	fa	\N
d9da59d4-8084-49bd-ae23-cb99bb061a10	p2-0-d9da59d4@example.com	x	2026-08-16 01:07:18.842743+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:07:18.842743+00	f	\N	\N	f	\N	\N	2026-08-16 01:07:18.842743+00	\N	f	fa	\N
1c0e8743-2190-48e4-9c0e-87432190c8e4	p11-0-1c0e8743@example.com	x	2026-08-16 01:07:20.331157+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:07:20.331157+00	f	\N	\N	f	\N	\N	2026-08-16 01:07:20.331157+00	\N	f	fa	\N
7dc77ed4-d996-4eeb-a881-1f208a54c12f	p2-0-7dc77ed4@example.com	x	2026-08-16 01:08:00.108095+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:08:00.108095+00	f	\N	\N	f	\N	\N	2026-08-16 01:08:00.108095+00	\N	f	fa	\N
96329156-5841-49fb-81a3-2312b7525188	p2-1-96329156@example.com	x	2026-08-16 01:08:00.118919+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:08:00.118919+00	f	\N	\N	f	\N	\N	2026-08-16 01:08:00.118919+00	\N	f	fa	\N
43efcc9b-7d09-41c4-a72c-5235ca0b3307	p2-0-43efcc9b@example.com	x	2026-08-16 01:08:00.247711+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:08:00.247711+00	f	\N	\N	f	\N	\N	2026-08-16 01:08:00.247711+00	\N	f	fa	\N
5c74f65f-c1f0-496a-9ad8-6a33bda83d30	p2-0-5c74f65f@example.com	x	2026-08-16 01:08:00.410037+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:08:00.410037+00	f	\N	\N	f	\N	\N	2026-08-16 01:08:00.410037+00	\N	f	fa	\N
ab70e441-0b8e-4ed0-9762-13a8ac5e7c7d	p2-0-ab70e441@example.com	x	2026-08-16 01:25:58.667111+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:25:58.667111+00	f	\N	\N	f	\N	\N	2026-08-16 01:25:58.667111+00	\N	f	fa	\N
f97bf032-eeaa-483a-badb-00e6d886c526	p2-1-f97bf032@example.com	x	2026-08-16 01:25:58.679767+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:25:58.679767+00	f	\N	\N	f	\N	\N	2026-08-16 01:25:58.679767+00	\N	f	fa	\N
2625aa74-47bf-4793-a803-29bb9e477aed	p2-0-2625aa74@example.com	x	2026-08-16 01:25:58.799775+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:25:58.799775+00	f	\N	\N	f	\N	\N	2026-08-16 01:25:58.799775+00	\N	f	fa	\N
e36a81e6-3639-4a93-b9c3-2f841d04211b	p2-0-e36a81e6@example.com	x	2026-08-16 01:25:58.964197+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:25:58.964197+00	f	\N	\N	f	\N	\N	2026-08-16 01:25:58.964197+00	\N	f	fa	\N
60b0d86c-369b-4da6-a0b0-d86c369b4da6	p11-0-60b0d86c@example.com	x	2026-08-16 01:26:01.943303+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:26:01.943303+00	f	\N	\N	f	\N	\N	2026-08-16 01:26:01.943303+00	\N	f	fa	\N
08048241-a050-48d4-8804-8241a050a8d4	p11-0-08048241@example.com	x	2026-08-16 01:26:30.032427+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:26:30.032427+00	f	\N	\N	f	\N	\N	2026-08-16 01:26:30.032427+00	\N	f	fa	\N
4f4153e9-0d17-4a1e-92ef-ce9e7958beb2	p2-0-4f4153e9@example.com	x	2026-08-16 01:26:54.026309+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:26:54.026309+00	f	\N	\N	f	\N	\N	2026-08-16 01:26:54.026309+00	\N	f	fa	\N
c3a16226-aa66-4239-9f5b-228e8eb92f5b	p2-1-c3a16226@example.com	x	2026-08-16 01:26:54.036025+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:26:54.036025+00	f	\N	\N	f	\N	\N	2026-08-16 01:26:54.036025+00	\N	f	fa	\N
eb0cfe73-a65e-405a-8e76-0717293c8143	p2-0-eb0cfe73@example.com	x	2026-08-16 01:26:54.15374+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:26:54.15374+00	f	\N	\N	f	\N	\N	2026-08-16 01:26:54.15374+00	\N	f	fa	\N
1088c4e2-7138-4c4e-9088-c4e271389c4e	p11-0-1088c4e2@example.com	x	2026-08-16 01:26:55.560293+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:26:55.560293+00	f	\N	\N	f	\N	\N	2026-08-16 01:26:55.560293+00	\N	f	fa	\N
9e60eafe-d7b5-4ba8-9622-8a7e881717d2	p2-0-9e60eafe@example.com	x	2026-08-16 01:27:11.222946+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:27:11.222946+00	f	\N	\N	f	\N	\N	2026-08-16 01:27:11.222946+00	\N	f	fa	\N
f6e59b39-9e32-439a-879f-6b7683774265	p2-0-f6e59b39@example.com	x	2026-08-16 01:27:11.379997+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:27:11.379997+00	f	\N	\N	f	\N	\N	2026-08-16 01:27:11.379997+00	\N	f	fa	\N
e0f0783c-9e4f-47d3-a0f0-783c9e4fa7d3	p11-0-e0f0783c@example.com	x	2026-08-16 01:27:13.511254+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:27:13.511254+00	f	\N	\N	f	\N	\N	2026-08-16 01:27:13.511254+00	\N	f	fa	\N
40a0d0e8-f4fa-4dfe-80a0-d0e8f4fafdfe	p11-0-40a0d0e8@example.com	x	2026-08-16 01:27:16.166495+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:27:16.166495+00	f	\N	\N	f	\N	\N	2026-08-16 01:27:16.166495+00	\N	f	fa	\N
6cb6dbed-76bb-4d2e-acb6-dbed76bb5d2e	p11-0-6cb6dbed@example.com	x	2026-08-16 01:29:16.019412+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:29:16.019412+00	f	\N	\N	f	\N	\N	2026-08-16 01:29:16.019412+00	\N	f	fa	\N
3c9e4f27-1309-4402-bc9e-4f2713090402	p11-0-3c9e4f27@example.com	x	2026-08-16 01:29:20.374373+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:29:20.374373+00	f	\N	\N	f	\N	\N	2026-08-16 01:29:20.374373+00	\N	f	fa	\N
792c3ecb-0a51-4b66-b78f-411903e74aa3	p2-0-792c3ecb@example.com	x	2026-08-16 01:29:20.618003+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:29:20.618003+00	f	\N	\N	f	\N	\N	2026-08-16 01:29:20.618003+00	\N	f	fa	\N
540d0a22-62a4-45f1-a0ab-2f2092014abb	p2-1-540d0a22@example.com	x	2026-08-16 01:29:20.62736+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:29:20.62736+00	f	\N	\N	f	\N	\N	2026-08-16 01:29:20.62736+00	\N	f	fa	\N
ffb61316-7d0b-4e05-a80f-d634f1b9391d	p2-0-ffb61316@example.com	x	2026-08-16 01:29:20.866788+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:29:20.866788+00	f	\N	\N	f	\N	\N	2026-08-16 01:29:20.866788+00	\N	f	fa	\N
633e7e4b-d5a2-41c7-9a17-af7e54fd4c6c	p2-0-633e7e4b@example.com	x	2026-08-16 01:29:21.080269+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:29:21.080269+00	f	\N	\N	f	\N	\N	2026-08-16 01:29:21.080269+00	\N	f	fa	\N
a452a954-aa55-4a55-a452-a954aa55aa55	p11-0-a452a954@example.com	x	2026-08-16 01:54:01.98505+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:54:01.98505+00	f	\N	\N	f	\N	\N	2026-08-16 01:54:01.98505+00	\N	f	fa	\N
74ba5dae-d7eb-453a-b4ba-5daed7eb753a	p11-0-74ba5dae@example.com	x	2026-08-16 01:54:04.76027+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:54:04.76027+00	f	\N	\N	f	\N	\N	2026-08-16 01:54:04.76027+00	\N	f	fa	\N
68b45a2d-96cb-45f2-a8b4-5a2d96cbe5f2	p11-0-68b45a2d@example.com	x	2026-08-16 01:54:27.455327+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:54:27.455327+00	f	\N	\N	f	\N	\N	2026-08-16 01:54:27.455327+00	\N	f	fa	\N
40a0d068-341a-4d86-80a0-d068341a0d86	p11-0-40a0d068@example.com	x	2026-08-16 01:54:58.361931+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 01:54:58.361931+00	f	\N	\N	f	\N	\N	2026-08-16 01:54:58.361931+00	\N	f	fa	\N
c8e4f279-3c1e-4f87-88e4-f2793c1e0f87	p11-0-c8e4f279@example.com	x	2026-08-16 02:00:06.237431+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:00:06.237431+00	f	\N	\N	f	\N	\N	2026-08-16 02:00:06.237431+00	\N	f	fa	\N
3098cc66-b359-4c56-b098-cc66b359ac56	p11-0-3098cc66@example.com	x	2026-08-16 02:27:08.230328+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:27:08.230328+00	f	\N	\N	f	\N	\N	2026-08-16 02:27:08.230328+00	\N	f	fa	\N
2669d7fa-c10f-4128-9395-ada433d4631e	p2-0-2669d7fa@example.com	x	2026-08-16 02:27:10.369635+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:27:10.369635+00	f	\N	\N	f	\N	\N	2026-08-16 02:27:10.369635+00	\N	f	fa	\N
452e07e0-e8eb-4f0f-98f2-f8875cd88831	p2-1-452e07e0@example.com	x	2026-08-16 02:27:10.383152+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:27:10.383152+00	f	\N	\N	f	\N	\N	2026-08-16 02:27:10.383152+00	\N	f	fa	\N
653652cd-820e-4692-a7bb-1bb90a20936a	p2-0-653652cd@example.com	x	2026-08-16 02:27:10.522941+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:27:10.522941+00	f	\N	\N	f	\N	\N	2026-08-16 02:27:10.522941+00	\N	f	fa	\N
3c9e4fa7-d3e9-44ba-bc9e-4fa7d3e974ba	p11-0-3c9e4fa7@example.com	x	2026-08-16 02:43:00.185939+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:43:00.185939+00	f	\N	\N	f	\N	\N	2026-08-16 02:43:00.185939+00	\N	f	fa	\N
c9e259ce-38b0-4b00-a3a3-9b5771d9b6de	p2-0-c9e259ce@example.com	x	2026-08-16 02:43:02.698585+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:43:02.698585+00	f	\N	\N	f	\N	\N	2026-08-16 02:43:02.698585+00	\N	f	fa	\N
e8a771e3-92db-4a30-9bb0-c4b84125187f	p2-1-e8a771e3@example.com	x	2026-08-16 02:43:02.709242+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:43:02.709242+00	f	\N	\N	f	\N	\N	2026-08-16 02:43:02.709242+00	\N	f	fa	\N
d8bacc11-7441-48e2-9f65-7d387dd9ea26	p2-0-d8bacc11@example.com	x	2026-08-16 02:43:02.82178+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:43:02.82178+00	f	\N	\N	f	\N	\N	2026-08-16 02:43:02.82178+00	\N	f	fa	\N
241289c4-6231-48cc-a412-89c4623198cc	p11-0-241289c4@example.com	x	2026-08-16 02:44:00.149325+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:44:00.149325+00	f	\N	\N	f	\N	\N	2026-08-16 02:44:00.149325+00	\N	f	fa	\N
76ada4f6-10d5-4219-a405-f8d5e5b32b78	p2-0-76ada4f6@example.com	x	2026-08-16 02:44:01.980764+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:44:01.980764+00	f	\N	\N	f	\N	\N	2026-08-16 02:44:01.980764+00	\N	f	fa	\N
d00ce5cc-0dc6-4078-935c-2a75b2349ba2	p2-1-d00ce5cc@example.com	x	2026-08-16 02:44:01.990249+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:44:01.990249+00	f	\N	\N	f	\N	\N	2026-08-16 02:44:01.990249+00	\N	f	fa	\N
0499cba2-41b1-4fd3-b4f7-07d7e77bd094	p2-0-0499cba2@example.com	x	2026-08-16 02:44:02.107825+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:44:02.107825+00	f	\N	\N	f	\N	\N	2026-08-16 02:44:02.107825+00	\N	f	fa	\N
f6491f08-63d2-476f-873f-db5cf69c0122	p2-0-f6491f08@example.com	x	2026-08-16 02:44:05.80883+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:44:05.80883+00	f	\N	\N	f	\N	\N	2026-08-16 02:44:05.80883+00	\N	f	fa	\N
302640fe-27ce-4abe-b59a-5ec4dc69944c	p2-1-302640fe@example.com	x	2026-08-16 02:44:05.818991+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:44:05.818991+00	f	\N	\N	f	\N	\N	2026-08-16 02:44:05.818991+00	\N	f	fa	\N
984c2613-89c4-42f1-984c-261389c4e2f1	p11-0-984c2613@example.com	x	2026-08-16 02:44:06.938424+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:44:06.938424+00	f	\N	\N	f	\N	\N	2026-08-16 02:44:06.938424+00	\N	f	fa	\N
218b00a6-dd31-4954-8850-989f8454cb72	p2-0-218b00a6@example.com	x	2026-08-16 02:44:08.540847+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:44:08.540847+00	f	\N	\N	f	\N	\N	2026-08-16 02:44:08.540847+00	\N	f	fa	\N
b479eb08-1b65-411d-964c-028ed616a70d	p2-1-b479eb08@example.com	x	2026-08-16 02:44:08.550628+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:44:08.550628+00	f	\N	\N	f	\N	\N	2026-08-16 02:44:08.550628+00	\N	f	fa	\N
c66062f8-5699-49a8-a1bb-05a591ab9f22	p2-0-c66062f8@example.com	x	2026-08-16 02:44:11.055506+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:44:11.055506+00	f	\N	\N	f	\N	\N	2026-08-16 02:44:11.055506+00	\N	f	fa	\N
646173e1-c3cb-42b3-8252-1f9a45adf2d5	p2-1-646173e1@example.com	x	2026-08-16 02:44:11.065333+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:44:11.065333+00	f	\N	\N	f	\N	\N	2026-08-16 02:44:11.065333+00	\N	f	fa	\N
582c160b-8542-4150-982c-160b8542a150	p11-0-582c160b@example.com	x	2026-08-16 02:44:36.02955+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:44:36.02955+00	f	\N	\N	f	\N	\N	2026-08-16 02:44:36.02955+00	\N	f	fa	\N
b85c2e97-4b25-4209-b85c-2e974b251209	p11-0-b85c2e97@example.com	x	2026-08-16 02:44:37.128009+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:44:37.128009+00	f	\N	\N	f	\N	\N	2026-08-16 02:44:37.128009+00	\N	f	fa	\N
80402090-48a4-4269-8040-209048a4d269	p11-0-80402090@example.com	x	2026-08-16 02:44:38.390061+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:44:38.390061+00	f	\N	\N	f	\N	\N	2026-08-16 02:44:38.390061+00	\N	f	fa	\N
b8dc6e37-9bcd-4633-b8dc-6e379bcd6633	p11-0-b8dc6e37@example.com	x	2026-08-16 02:44:55.576875+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:44:55.576875+00	f	\N	\N	f	\N	\N	2026-08-16 02:44:55.576875+00	\N	f	fa	\N
743a1d0e-0783-41e0-b43a-1d0e0783c1e0	p11-0-743a1d0e@example.com	x	2026-08-16 02:45:57.288054+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:45:57.288054+00	f	\N	\N	f	\N	\N	2026-08-16 02:45:57.288054+00	\N	f	fa	\N
0d4fd196-fc76-49cf-a78c-ce25c8a03022	p2-0-0d4fd196@example.com	x	2026-08-16 02:45:59.065355+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:45:59.065355+00	f	\N	\N	f	\N	\N	2026-08-16 02:45:59.065355+00	\N	f	fa	\N
426be798-f942-40a8-8609-cd231f5ebb08	p2-1-426be798@example.com	x	2026-08-16 02:45:59.074736+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:45:59.074736+00	f	\N	\N	f	\N	\N	2026-08-16 02:45:59.074736+00	\N	f	fa	\N
cdf8aaad-4a4f-4dc9-a592-79fe503633f7	p2-0-cdf8aaad@example.com	x	2026-08-16 02:45:59.189454+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:45:59.189454+00	f	\N	\N	f	\N	\N	2026-08-16 02:45:59.189454+00	\N	f	fa	\N
a8542a95-4aa5-4229-a854-2a954aa55229	p11-0-a8542a95@example.com	x	2026-08-16 02:48:32.611695+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:48:32.611695+00	f	\N	\N	f	\N	\N	2026-08-16 02:48:32.611695+00	\N	f	fa	\N
1b5063b8-9733-4563-beef-2c787c3365a9	p2-0-1b5063b8@example.com	x	2026-08-16 02:48:34.35622+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:48:34.35622+00	f	\N	\N	f	\N	\N	2026-08-16 02:48:34.35622+00	\N	f	fa	\N
a3d7c5f3-40e0-4c2f-933a-f95a98ab57f3	p2-1-a3d7c5f3@example.com	x	2026-08-16 02:48:34.36559+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:48:34.36559+00	f	\N	\N	f	\N	\N	2026-08-16 02:48:34.36559+00	\N	f	fa	\N
ddeff84e-1027-4038-8102-7ce08c9e5a94	p2-0-ddeff84e@example.com	x	2026-08-16 02:48:34.482315+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:48:34.482315+00	f	\N	\N	f	\N	\N	2026-08-16 02:48:34.482315+00	\N	f	fa	\N
b45aad56-abd5-4a75-b45a-ad56abd5ea75	p11-0-b45aad56@example.com	x	2026-08-16 02:49:04.718947+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:49:04.718947+00	f	\N	\N	f	\N	\N	2026-08-16 02:49:04.718947+00	\N	f	fa	\N
f92e8766-b7d0-4dca-add5-9718456d5657	p2-0-f92e8766@example.com	x	2026-08-16 02:49:06.313218+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:49:06.313218+00	f	\N	\N	f	\N	\N	2026-08-16 02:49:06.313218+00	\N	f	fa	\N
071d2be9-9431-4ae5-afbb-9a195b33db15	p2-1-071d2be9@example.com	x	2026-08-16 02:49:06.323616+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:49:06.323616+00	f	\N	\N	f	\N	\N	2026-08-16 02:49:06.323616+00	\N	f	fa	\N
f41fb589-ceb8-47da-9ec4-4c1bb1f0e79d	p2-0-f41fb589@example.com	x	2026-08-16 02:49:07.845918+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:49:07.845918+00	f	\N	\N	f	\N	\N	2026-08-16 02:49:07.845918+00	\N	f	fa	\N
2cf63582-501f-451b-8595-587b82b2f40a	p2-0-2cf63582@example.com	x	2026-08-16 02:49:30.825098+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:49:30.825098+00	f	\N	\N	f	\N	\N	2026-08-16 02:49:30.825098+00	\N	f	fa	\N
ed2e8329-c2c7-4ed0-b3ea-ed9b6e2abfda	p2-1-ed2e8329@example.com	x	2026-08-16 02:49:30.835249+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:49:30.835249+00	f	\N	\N	f	\N	\N	2026-08-16 02:49:30.835249+00	\N	f	fa	\N
28140a85-c2e1-40b8-a814-0a85c2e170b8	p11-0-28140a85@example.com	x	2026-08-16 02:49:31.934335+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:49:31.934335+00	f	\N	\N	f	\N	\N	2026-08-16 02:49:31.934335+00	\N	f	fa	\N
bc5e2f97-cb65-4219-bc5e-2f97cb653219	p11-0-bc5e2f97@example.com	x	2026-08-16 02:51:29.097954+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:51:29.097954+00	f	\N	\N	f	\N	\N	2026-08-16 02:51:29.097954+00	\N	f	fa	\N
6c6f8218-0e00-4731-9e59-e8b8d4d61b5d	p2-0-6c6f8218@example.com	x	2026-08-16 02:51:30.836555+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:51:30.836555+00	f	\N	\N	f	\N	\N	2026-08-16 02:51:30.836555+00	\N	f	fa	\N
5d4db3df-ec04-4d3f-a4b7-758b932bdeab	p2-1-5d4db3df@example.com	x	2026-08-16 02:51:30.846111+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:51:30.846111+00	f	\N	\N	f	\N	\N	2026-08-16 02:51:30.846111+00	\N	f	fa	\N
5a5b8479-6d2f-4e8c-8064-84afe7c56e72	p2-0-5a5b8479@example.com	x	2026-08-16 02:51:30.965398+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:51:30.965398+00	f	\N	\N	f	\N	\N	2026-08-16 02:51:30.965398+00	\N	f	fa	\N
a0d068b4-5aad-46eb-a0d0-68b45aadd6eb	p11-0-a0d068b4@example.com	x	2026-08-16 02:51:41.086546+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:51:41.086546+00	f	\N	\N	f	\N	\N	2026-08-16 02:51:41.086546+00	\N	f	fa	\N
3f0e5a46-bb93-4f07-a561-60662dd5541a	p2-0-3f0e5a46@example.com	x	2026-08-16 02:51:42.792895+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:51:42.792895+00	f	\N	\N	f	\N	\N	2026-08-16 02:51:42.792895+00	\N	f	fa	\N
0f108d2e-d94b-4cd8-b88f-504e9d68134a	p2-1-0f108d2e@example.com	x	2026-08-16 02:51:42.803287+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:51:42.803287+00	f	\N	\N	f	\N	\N	2026-08-16 02:51:42.803287+00	\N	f	fa	\N
515fbee7-3bb0-4b6d-b431-22282d623cd7	p2-0-515fbee7@example.com	x	2026-08-16 02:51:42.915207+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:51:42.915207+00	f	\N	\N	f	\N	\N	2026-08-16 02:51:42.915207+00	\N	f	fa	\N
9ccee7f3-f97c-4edf-9cce-e7f3f97cbedf	p11-0-9ccee7f3@example.com	x	2026-08-16 02:51:46.075347+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:51:46.075347+00	f	\N	\N	f	\N	\N	2026-08-16 02:51:46.075347+00	\N	f	fa	\N
a14dbc0e-1b40-4539-825b-5bad255f153d	p2-0-a14dbc0e@example.com	x	2026-08-16 02:51:47.659314+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:51:47.659314+00	f	\N	\N	f	\N	\N	2026-08-16 02:51:47.659314+00	\N	f	fa	\N
de4588c4-c14b-4f0c-9908-2e0689f907fe	p2-1-de4588c4@example.com	x	2026-08-16 02:51:47.682698+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:51:47.682698+00	f	\N	\N	f	\N	\N	2026-08-16 02:51:47.682698+00	\N	f	fa	\N
5f124107-5c83-432a-80fd-8899e94f9845	p2-0-5f124107@example.com	x	2026-08-16 02:51:49.250329+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:51:49.250329+00	f	\N	\N	f	\N	\N	2026-08-16 02:51:49.250329+00	\N	f	fa	\N
e19c7724-0cba-4667-8e36-c469962a9f0e	p2-0-e19c7724@example.com	x	2026-08-16 02:51:57.526095+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:51:57.526095+00	f	\N	\N	f	\N	\N	2026-08-16 02:51:57.526095+00	\N	f	fa	\N
92b04625-4ad6-4bea-94ef-2795bd4c5fa1	p2-1-92b04625@example.com	x	2026-08-16 02:51:57.550655+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:51:57.550655+00	f	\N	\N	f	\N	\N	2026-08-16 02:51:57.550655+00	\N	f	fa	\N
f4fa7dbe-5faf-476b-b4fa-7dbe5fafd76b	p11-0-f4fa7dbe@example.com	x	2026-08-16 02:51:58.706037+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:51:58.706037+00	f	\N	\N	f	\N	\N	2026-08-16 02:51:58.706037+00	\N	f	fa	\N
944aa552-a954-4a95-944a-a552a9542a95	p11-0-944aa552@example.com	x	2026-08-16 02:51:59.821883+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:51:59.821883+00	f	\N	\N	f	\N	\N	2026-08-16 02:51:59.821883+00	\N	f	fa	\N
2090c8e4-f279-4cde-a090-c8e4f279bcde	p11-0-2090c8e4@example.com	x	2026-08-16 02:52:01.896373+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:52:01.896373+00	f	\N	\N	f	\N	\N	2026-08-16 02:52:01.896373+00	\N	f	fa	\N
649329c0-8d36-409a-b7c5-b38404828556	p2-0-649329c0@example.com	x	2026-08-16 02:52:15.375873+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:52:15.375873+00	f	\N	\N	f	\N	\N	2026-08-16 02:52:15.375873+00	\N	f	fa	\N
bee05777-76fe-4703-a9cd-9d3dc737900d	p2-1-bee05777@example.com	x	2026-08-16 02:52:15.385108+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:52:15.385108+00	f	\N	\N	f	\N	\N	2026-08-16 02:52:15.385108+00	\N	f	fa	\N
24120984-c261-40d8-a412-0984c261b0d8	p11-0-24120984@example.com	x	2026-08-16 02:52:19.34147+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:52:19.34147+00	f	\N	\N	f	\N	\N	2026-08-16 02:52:19.34147+00	\N	f	fa	\N
f48d5513-b821-4152-a295-5efeb81d84a8	p2-0-f48d5513@example.com	x	2026-08-16 02:52:34.808765+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:52:34.808765+00	f	\N	\N	f	\N	\N	2026-08-16 02:52:34.808765+00	\N	f	fa	\N
d27fb682-c775-422a-9b7d-45eb2e8bc3c5	p2-1-d27fb682@example.com	x	2026-08-16 02:52:34.818942+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:52:34.818942+00	f	\N	\N	f	\N	\N	2026-08-16 02:52:34.818942+00	\N	f	fa	\N
9990da57-187a-42b2-8bda-059add25d3e1	p2-0-9990da57@example.com	x	2026-08-16 02:52:34.928516+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:52:34.928516+00	f	\N	\N	f	\N	\N	2026-08-16 02:52:34.928516+00	\N	f	fa	\N
84c261b0-d8ec-46bb-84c2-61b0d8ec76bb	p11-0-84c261b0@example.com	x	2026-08-16 02:53:23.223275+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:53:23.223275+00	f	\N	\N	f	\N	\N	2026-08-16 02:53:23.223275+00	\N	f	fa	\N
6791b01d-b944-4e99-b143-fb30f4f67872	p2-0-6791b01d@example.com	x	2026-08-16 02:53:24.943162+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:53:24.943162+00	f	\N	\N	f	\N	\N	2026-08-16 02:53:24.943162+00	\N	f	fa	\N
55ff18a7-c140-4f37-b027-cfff7e1a6e85	p2-1-55ff18a7@example.com	x	2026-08-16 02:53:24.953263+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:53:24.953263+00	f	\N	\N	f	\N	\N	2026-08-16 02:53:24.953263+00	\N	f	fa	\N
fb2b1558-5440-43ec-ba87-73bc2a27ceb7	p2-0-fb2b1558@example.com	x	2026-08-16 02:53:25.070202+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:53:25.070202+00	f	\N	\N	f	\N	\N	2026-08-16 02:53:25.070202+00	\N	f	fa	\N
3878c3c1-f900-4194-b8f7-ca2538111eb4	p41lite-0-3878c3c1@example.com	x	2026-08-16 02:55:26.361436+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:55:26.361436+00	f	\N	\N	f	\N	\N	2026-08-16 02:55:26.361436+00	\N	f	fa	\N
98207b42-c805-42cd-aafa-46f30cf1ac8c	p41lite-1-98207b42@example.com	x	2026-08-16 02:55:26.361436+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:55:26.361436+00	f	\N	\N	f	\N	\N	2026-08-16 02:55:26.361436+00	\N	f	fa	\N
ca833cd8-e3ab-4d3a-9ad5-a33a88aa3843	p41lite-2-ca833cd8@example.com	x	2026-08-16 02:55:26.361436+00	active	t	\N	\N	\N	\N	\N	\N	\N	2026-08-16 02:55:26.361436+00	f	\N	\N	f	\N	\N	2026-08-16 02:55:26.361436+00	\N	f	fa	\N
\.


--
-- Data for Name: verification_codes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.verification_codes (id, user_id, code_hash, method, destination, expires_at, verified_at, attempts, max_attempts, created_at) FROM stdin;
\.


--
-- Data for Name: wallet_ledger; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.wallet_ledger (id, user_id, type, amount_cents, balance_after_cents, ref_type, ref_id, description, created_at, idempotency_key, reason_code) FROM stdin;
fbfe1885-16db-40bf-b733-4a2c0cb046ea	c864b259-2c96-4b65-8864-b2592c96cb65	contest_entry	-10000	40000	contest	c864b259-2c96-4b65-8864-b2592c96cb65	Entry fee for contest phase11-e2e (ID: c864b259-2c96-4b65-8864-b2592c96cb65)	2026-08-16 00:34:27.217954+00	contest_entry:c864b259-2c96-4b65-8864-b2592c96cb65:c864b259-2c96-4b65-8864-b2592c96cb65	CONTEST_ENTRY
885fed77-acc6-4bb5-b3b3-44441e8618e5	c864b259-2c96-4b65-8864-b2592c96cb65	prize_credit	24000	64000	contest	c864b259-2c96-4b65-8864-b2592c96cb65	Prize for contest c864b259-2c96-4b65-8864-b2592c96cb65 (rank 1)	2026-08-16 00:34:27.263638+00	finalization:c864b259-2c96-4b65-8864-b2592c96cb65:c864b259-2c96-4b65-8864-b2592c96cb65:1	CONTEST_PRIZE
2681440f-1327-4a41-ab1e-7b6fd561cf4a	90c864b2-592c-464b-90c8-64b2592c964b	contest_entry	-10000	40000	contest	90c864b2-592c-464b-90c8-64b2592c964b	Entry fee for contest phase11-e2e (ID: 90c864b2-592c-464b-90c8-64b2592c964b)	2026-08-16 00:34:56.125502+00	contest_entry:90c864b2-592c-464b-90c8-64b2592c964b:90c864b2-592c-464b-90c8-64b2592c964b	CONTEST_ENTRY
cdc214c4-128e-4b81-8c15-9fa7110d36a9	90c864b2-592c-464b-90c8-64b2592c964b	prize_credit	24000	64000	contest	90c864b2-592c-464b-90c8-64b2592c964b	Prize for contest 90c864b2-592c-464b-90c8-64b2592c964b (rank 1)	2026-08-16 00:34:56.192493+00	finalization:90c864b2-592c-464b-90c8-64b2592c964b:90c864b2-592c-464b-90c8-64b2592c964b:1	CONTEST_PRIZE
c750016d-d527-4cc5-889f-be857986167b	7d16b1c9-fa10-4721-9ab1-f9c6dfd7f7c0	contest_entry	-10000	90000	contest	9d147ba4-3d0a-492e-b867-19a222c7afbc	Entry fee for contest phase2-e2e (ID: 9d147ba4-3d0a-492e-b867-19a222c7afbc)	2026-08-16 01:05:27.731891+00	contest_entry:9d147ba4-3d0a-492e-b867-19a222c7afbc:7d16b1c9-fa10-4721-9ab1-f9c6dfd7f7c0	CONTEST_ENTRY
122e2ecb-47e3-4eff-88f8-adb6753ce50b	73724a7a-cc59-4aeb-86b5-bc997598c1ec	contest_entry	-10000	90000	contest	9d147ba4-3d0a-492e-b867-19a222c7afbc	Entry fee for contest phase2-e2e (ID: 9d147ba4-3d0a-492e-b867-19a222c7afbc)	2026-08-16 01:05:27.744762+00	contest_entry:9d147ba4-3d0a-492e-b867-19a222c7afbc:73724a7a-cc59-4aeb-86b5-bc997598c1ec	CONTEST_ENTRY
2ad46494-3fa7-47a6-b5ff-d1c9e0e574a6	3a6ad88d-a188-4bf0-be1d-bf2706cdbe2a	contest_entry	-10000	90000	contest	7c77ff2b-bc98-46cc-aa96-95b6e9eb3070	Entry fee for contest phase2-e2e (ID: 7c77ff2b-bc98-46cc-aa96-95b6e9eb3070)	2026-08-16 01:05:44.453187+00	contest_entry:7c77ff2b-bc98-46cc-aa96-95b6e9eb3070:3a6ad88d-a188-4bf0-be1d-bf2706cdbe2a	CONTEST_ENTRY
a649713a-4c8a-444a-9531-0447ddcb6947	912bce1a-5da1-473c-b7cf-832f0ff39bb4	contest_entry	-10000	90000	contest	7c77ff2b-bc98-46cc-aa96-95b6e9eb3070	Entry fee for contest phase2-e2e (ID: 7c77ff2b-bc98-46cc-aa96-95b6e9eb3070)	2026-08-16 01:05:44.46615+00	contest_entry:7c77ff2b-bc98-46cc-aa96-95b6e9eb3070:912bce1a-5da1-473c-b7cf-832f0ff39bb4	CONTEST_ENTRY
6b324691-f6f1-42c2-abf7-2875da8e08ce	863bc837-1fa3-4374-91df-3fe92a7a8694	contest_entry	-10000	90000	contest	9ea30eb8-6065-4457-96ba-52ac5334e0ee	Entry fee for contest phase2-e2e (ID: 9ea30eb8-6065-4457-96ba-52ac5334e0ee)	2026-08-16 01:06:51.308133+00	contest_entry:9ea30eb8-6065-4457-96ba-52ac5334e0ee:863bc837-1fa3-4374-91df-3fe92a7a8694	CONTEST_ENTRY
9f82a153-d079-482a-b491-44704f1f6fa8	5d597832-fd0c-4be5-b1bb-ed1f03c10399	contest_entry	-10000	90000	contest	9ea30eb8-6065-4457-96ba-52ac5334e0ee	Entry fee for contest phase2-e2e (ID: 9ea30eb8-6065-4457-96ba-52ac5334e0ee)	2026-08-16 01:06:51.320469+00	contest_entry:9ea30eb8-6065-4457-96ba-52ac5334e0ee:5d597832-fd0c-4be5-b1bb-ed1f03c10399	CONTEST_ENTRY
99408482-5431-4025-b5bb-b53cdceda1be	863bc837-1fa3-4374-91df-3fe92a7a8694	prize_credit	1000	91000	contest	9ea30eb8-6065-4457-96ba-52ac5334e0ee	Prize for contest 9ea30eb8-6065-4457-96ba-52ac5334e0ee (rank 1)	2026-08-16 01:06:51.386991+00	finalization:9ea30eb8-6065-4457-96ba-52ac5334e0ee:863bc837-1fa3-4374-91df-3fe92a7a8694:1	CONTEST_PRIZE
733d2537-ce8a-45ca-969a-fb461fdf0f1f	81741f96-07b2-4e40-801d-470e79ffac94	contest_entry	-10000	90000	contest	0da7c9af-faf3-4477-8843-69936d6a47fb	Entry fee for contest phase2-e2e (ID: 0da7c9af-faf3-4477-8843-69936d6a47fb)	2026-08-16 01:06:51.444334+00	contest_entry:0da7c9af-faf3-4477-8843-69936d6a47fb:81741f96-07b2-4e40-801d-470e79ffac94	CONTEST_ENTRY
59a4cb9a-c8cb-4b4a-b3ab-8d264f8953e9	8ff79fc3-3043-4a7c-a959-4f2ba6e5e265	contest_entry	-10000	90000	contest	734d42df-4077-471f-9f96-2b4143ab43df	Entry fee for contest phase2-e2e (ID: 734d42df-4077-471f-9f96-2b4143ab43df)	2026-08-16 01:06:51.61869+00	contest_entry:734d42df-4077-471f-9f96-2b4143ab43df:8ff79fc3-3043-4a7c-a959-4f2ba6e5e265	CONTEST_ENTRY
da1b5cd3-b183-4149-ad6c-e93fbc324a9b	15e34f4d-da6c-4d3f-83c8-17bd2ddb4226	contest_entry	-10000	90000	contest	4263505f-6b0f-49d7-9c49-5f1008a557ea	Entry fee for contest phase2-e2e (ID: 4263505f-6b0f-49d7-9c49-5f1008a557ea)	2026-08-16 01:07:18.580931+00	contest_entry:4263505f-6b0f-49d7-9c49-5f1008a557ea:15e34f4d-da6c-4d3f-83c8-17bd2ddb4226	CONTEST_ENTRY
4670c0be-4841-43c0-afdf-a917474cc20d	bf942846-2dc6-41a2-afb0-35efd5403110	contest_entry	-10000	90000	contest	4263505f-6b0f-49d7-9c49-5f1008a557ea	Entry fee for contest phase2-e2e (ID: 4263505f-6b0f-49d7-9c49-5f1008a557ea)	2026-08-16 01:07:18.596+00	contest_entry:4263505f-6b0f-49d7-9c49-5f1008a557ea:bf942846-2dc6-41a2-afb0-35efd5403110	CONTEST_ENTRY
8517ea6c-587b-479e-8d29-385a8a57593e	15e34f4d-da6c-4d3f-83c8-17bd2ddb4226	prize_credit	1000	91000	contest	4263505f-6b0f-49d7-9c49-5f1008a557ea	Prize for contest 4263505f-6b0f-49d7-9c49-5f1008a557ea (rank 1)	2026-08-16 01:07:18.662323+00	finalization:4263505f-6b0f-49d7-9c49-5f1008a557ea:15e34f4d-da6c-4d3f-83c8-17bd2ddb4226:1	CONTEST_PRIZE
22cbff08-6c1a-45b7-beeb-cb7b2b4e4cb5	4af61bbb-6031-4996-9c0f-f27b00b90fb8	contest_entry	-10000	90000	contest	ae1aa700-2f09-497d-877c-15679fdec5f5	Entry fee for contest phase2-e2e (ID: ae1aa700-2f09-497d-877c-15679fdec5f5)	2026-08-16 01:07:18.709801+00	contest_entry:ae1aa700-2f09-497d-877c-15679fdec5f5:4af61bbb-6031-4996-9c0f-f27b00b90fb8	CONTEST_ENTRY
5b5f041e-0979-439e-b646-a0a27e668c44	d9da59d4-8084-49bd-ae23-cb99bb061a10	contest_entry	-10000	90000	contest	daf27c0c-5e6d-411e-ae0d-1df1120ffdf3	Entry fee for contest phase2-e2e (ID: daf27c0c-5e6d-411e-ae0d-1df1120ffdf3)	2026-08-16 01:07:18.862138+00	contest_entry:daf27c0c-5e6d-411e-ae0d-1df1120ffdf3:d9da59d4-8084-49bd-ae23-cb99bb061a10	CONTEST_ENTRY
679cdf74-9c95-493f-aff9-009c6972737e	1c0e8743-2190-48e4-9c0e-87432190c8e4	contest_entry	-10000	40000	contest	1c0e8743-2190-48e4-9c0e-87432190c8e4	Entry fee for contest phase11-e2e (ID: 1c0e8743-2190-48e4-9c0e-87432190c8e4)	2026-08-16 01:07:20.351307+00	contest_entry:1c0e8743-2190-48e4-9c0e-87432190c8e4:1c0e8743-2190-48e4-9c0e-87432190c8e4	CONTEST_ENTRY
1abf943d-424b-47ec-8290-39e4e8c9d950	1c0e8743-2190-48e4-9c0e-87432190c8e4	prize_credit	24000	64000	contest	1c0e8743-2190-48e4-9c0e-87432190c8e4	Prize for contest 1c0e8743-2190-48e4-9c0e-87432190c8e4 (rank 1)	2026-08-16 01:07:20.391209+00	finalization:1c0e8743-2190-48e4-9c0e-87432190c8e4:1c0e8743-2190-48e4-9c0e-87432190c8e4:1	CONTEST_PRIZE
32e7c58c-6da7-4ae6-9e9b-cad8af5f506d	7dc77ed4-d996-4eeb-a881-1f208a54c12f	contest_entry	-10000	90000	contest	8f7ba104-b9d7-47e5-b624-199c1bc385c2	Entry fee for contest phase2-e2e (ID: 8f7ba104-b9d7-47e5-b624-199c1bc385c2)	2026-08-16 01:08:00.132618+00	contest_entry:8f7ba104-b9d7-47e5-b624-199c1bc385c2:7dc77ed4-d996-4eeb-a881-1f208a54c12f	CONTEST_ENTRY
28aaecc8-1da9-48ea-a973-28922da0110d	96329156-5841-49fb-81a3-2312b7525188	contest_entry	-10000	90000	contest	8f7ba104-b9d7-47e5-b624-199c1bc385c2	Entry fee for contest phase2-e2e (ID: 8f7ba104-b9d7-47e5-b624-199c1bc385c2)	2026-08-16 01:08:00.144143+00	contest_entry:8f7ba104-b9d7-47e5-b624-199c1bc385c2:96329156-5841-49fb-81a3-2312b7525188	CONTEST_ENTRY
c21f042a-465f-49be-a4c9-47a3848bdbd0	7dc77ed4-d996-4eeb-a881-1f208a54c12f	prize_credit	1000	91000	contest	8f7ba104-b9d7-47e5-b624-199c1bc385c2	Prize for contest 8f7ba104-b9d7-47e5-b624-199c1bc385c2 (rank 1)	2026-08-16 01:08:00.221264+00	finalization:8f7ba104-b9d7-47e5-b624-199c1bc385c2:7dc77ed4-d996-4eeb-a881-1f208a54c12f:1	CONTEST_PRIZE
81224512-6d54-4b9d-9a80-30889c78996d	43efcc9b-7d09-41c4-a72c-5235ca0b3307	contest_entry	-10000	90000	contest	b96d7bd9-99e5-402e-bc3f-645a7251acbf	Entry fee for contest phase2-e2e (ID: b96d7bd9-99e5-402e-bc3f-645a7251acbf)	2026-08-16 01:08:00.266634+00	contest_entry:b96d7bd9-99e5-402e-bc3f-645a7251acbf:43efcc9b-7d09-41c4-a72c-5235ca0b3307	CONTEST_ENTRY
c98d5290-4bae-44f1-8215-01136341eac2	5c74f65f-c1f0-496a-9ad8-6a33bda83d30	contest_entry	-10000	90000	contest	5db97139-a45c-4de8-9c5c-02f65ae18683	Entry fee for contest phase2-e2e (ID: 5db97139-a45c-4de8-9c5c-02f65ae18683)	2026-08-16 01:08:00.430784+00	contest_entry:5db97139-a45c-4de8-9c5c-02f65ae18683:5c74f65f-c1f0-496a-9ad8-6a33bda83d30	CONTEST_ENTRY
8d210163-77b1-4086-b23b-0206f990aa52	ab70e441-0b8e-4ed0-9762-13a8ac5e7c7d	contest_entry	-10000	90000	contest	1cfa0925-3e82-4e33-a8a7-08897bff8995	Entry fee for contest phase2-e2e (ID: 1cfa0925-3e82-4e33-a8a7-08897bff8995)	2026-08-16 01:25:58.693526+00	contest_entry:1cfa0925-3e82-4e33-a8a7-08897bff8995:ab70e441-0b8e-4ed0-9762-13a8ac5e7c7d	CONTEST_ENTRY
c6eff7f7-a9ea-4dec-ad38-1e01a83dd8f1	f97bf032-eeaa-483a-badb-00e6d886c526	contest_entry	-10000	90000	contest	1cfa0925-3e82-4e33-a8a7-08897bff8995	Entry fee for contest phase2-e2e (ID: 1cfa0925-3e82-4e33-a8a7-08897bff8995)	2026-08-16 01:25:58.706497+00	contest_entry:1cfa0925-3e82-4e33-a8a7-08897bff8995:f97bf032-eeaa-483a-badb-00e6d886c526	CONTEST_ENTRY
eb4dba9d-c448-495c-b636-27073fd3a220	ab70e441-0b8e-4ed0-9762-13a8ac5e7c7d	prize_credit	1000	91000	contest	1cfa0925-3e82-4e33-a8a7-08897bff8995	Prize for contest 1cfa0925-3e82-4e33-a8a7-08897bff8995 (rank 1)	2026-08-16 01:25:58.771601+00	finalization:1cfa0925-3e82-4e33-a8a7-08897bff8995:ab70e441-0b8e-4ed0-9762-13a8ac5e7c7d:1	CONTEST_PRIZE
0e6e7f8b-a066-4993-833d-6c5b4f58037b	2625aa74-47bf-4793-a803-29bb9e477aed	contest_entry	-10000	90000	contest	a9e9ee08-e9c7-4796-b17c-8251365602b4	Entry fee for contest phase2-e2e (ID: a9e9ee08-e9c7-4796-b17c-8251365602b4)	2026-08-16 01:25:58.832168+00	contest_entry:a9e9ee08-e9c7-4796-b17c-8251365602b4:2625aa74-47bf-4793-a803-29bb9e477aed	CONTEST_ENTRY
4006c2fb-5e8a-4f61-a43e-7267cbb254a1	e36a81e6-3639-4a93-b9c3-2f841d04211b	contest_entry	-10000	90000	contest	213e9258-cb82-4f26-9db2-b7d57f8bd0f8	Entry fee for contest phase2-e2e (ID: 213e9258-cb82-4f26-9db2-b7d57f8bd0f8)	2026-08-16 01:25:58.983902+00	contest_entry:213e9258-cb82-4f26-9db2-b7d57f8bd0f8:e36a81e6-3639-4a93-b9c3-2f841d04211b	CONTEST_ENTRY
99257edb-e663-449c-980e-f50b0d8ea245	60b0d86c-369b-4da6-a0b0-d86c369b4da6	contest_entry	-10000	40000	contest	60b0d86c-369b-4da6-a0b0-d86c369b4da6	Entry fee for contest phase11-e2e (ID: 60b0d86c-369b-4da6-a0b0-d86c369b4da6)	2026-08-16 01:26:01.964182+00	contest_entry:60b0d86c-369b-4da6-a0b0-d86c369b4da6:60b0d86c-369b-4da6-a0b0-d86c369b4da6	CONTEST_ENTRY
2897e29f-8da0-4a01-a035-700cead64112	60b0d86c-369b-4da6-a0b0-d86c369b4da6	prize_credit	24000	64000	contest	60b0d86c-369b-4da6-a0b0-d86c369b4da6	Prize for contest 60b0d86c-369b-4da6-a0b0-d86c369b4da6 (rank 1)	2026-08-16 01:26:02.0064+00	finalization:60b0d86c-369b-4da6-a0b0-d86c369b4da6:60b0d86c-369b-4da6-a0b0-d86c369b4da6:1	CONTEST_PRIZE
69ba5676-cf74-40a2-aa26-ae0e9acc824d	08048241-a050-48d4-8804-8241a050a8d4	contest_entry	-10000	40000	contest	08048241-a050-48d4-8804-8241a050a8d4	Entry fee for contest phase11-e2e (ID: 08048241-a050-48d4-8804-8241a050a8d4)	2026-08-16 01:26:30.053253+00	contest_entry:08048241-a050-48d4-8804-8241a050a8d4:08048241-a050-48d4-8804-8241a050a8d4	CONTEST_ENTRY
aae90036-76ae-4fc8-9516-e4385159a668	08048241-a050-48d4-8804-8241a050a8d4	prize_credit	24000	64000	contest	08048241-a050-48d4-8804-8241a050a8d4	Prize for contest 08048241-a050-48d4-8804-8241a050a8d4 (rank 1)	2026-08-16 01:26:30.093329+00	finalization:08048241-a050-48d4-8804-8241a050a8d4:08048241-a050-48d4-8804-8241a050a8d4:1	CONTEST_PRIZE
98cfddf1-55cf-4d29-8ab3-c46790e8963e	4f4153e9-0d17-4a1e-92ef-ce9e7958beb2	contest_entry	-10000	90000	contest	2f80ce1a-329d-4e78-bc49-fe62ede53b7f	Entry fee for contest phase2-e2e (ID: 2f80ce1a-329d-4e78-bc49-fe62ede53b7f)	2026-08-16 01:26:54.049392+00	contest_entry:2f80ce1a-329d-4e78-bc49-fe62ede53b7f:4f4153e9-0d17-4a1e-92ef-ce9e7958beb2	CONTEST_ENTRY
6a6d2495-6d0d-4b3b-bb43-2f6b5c72cfce	c3a16226-aa66-4239-9f5b-228e8eb92f5b	contest_entry	-10000	90000	contest	2f80ce1a-329d-4e78-bc49-fe62ede53b7f	Entry fee for contest phase2-e2e (ID: 2f80ce1a-329d-4e78-bc49-fe62ede53b7f)	2026-08-16 01:26:54.061297+00	contest_entry:2f80ce1a-329d-4e78-bc49-fe62ede53b7f:c3a16226-aa66-4239-9f5b-228e8eb92f5b	CONTEST_ENTRY
44ada70e-f957-4cac-b44a-cbab1190b5f2	4f4153e9-0d17-4a1e-92ef-ce9e7958beb2	prize_credit	1000	91000	contest	2f80ce1a-329d-4e78-bc49-fe62ede53b7f	Prize for contest 2f80ce1a-329d-4e78-bc49-fe62ede53b7f (rank 1)	2026-08-16 01:26:54.126205+00	finalization:2f80ce1a-329d-4e78-bc49-fe62ede53b7f:4f4153e9-0d17-4a1e-92ef-ce9e7958beb2:1	CONTEST_PRIZE
b28abaf2-ddb9-44d1-8724-7dc8ce788cb3	eb0cfe73-a65e-405a-8e76-0717293c8143	contest_entry	-10000	90000	contest	45e3a795-edf5-4541-b89e-51cf2c71da49	Entry fee for contest phase2-e2e (ID: 45e3a795-edf5-4541-b89e-51cf2c71da49)	2026-08-16 01:26:54.173698+00	contest_entry:45e3a795-edf5-4541-b89e-51cf2c71da49:eb0cfe73-a65e-405a-8e76-0717293c8143	CONTEST_ENTRY
712eb469-db98-4c96-8bc6-6b45bc1d8bd8	1088c4e2-7138-4c4e-9088-c4e271389c4e	contest_entry	-10000	40000	contest	1088c4e2-7138-4c4e-9088-c4e271389c4e	Entry fee for contest phase11-e2e (ID: 1088c4e2-7138-4c4e-9088-c4e271389c4e)	2026-08-16 01:26:55.580638+00	contest_entry:1088c4e2-7138-4c4e-9088-c4e271389c4e:1088c4e2-7138-4c4e-9088-c4e271389c4e	CONTEST_ENTRY
f450e9cb-9fe5-4866-87ae-9eb3e1cb4c06	1088c4e2-7138-4c4e-9088-c4e271389c4e	prize_credit	24000	64000	contest	1088c4e2-7138-4c4e-9088-c4e271389c4e	Prize for contest 1088c4e2-7138-4c4e-9088-c4e271389c4e (rank 1)	2026-08-16 01:26:55.620444+00	finalization:1088c4e2-7138-4c4e-9088-c4e271389c4e:1088c4e2-7138-4c4e-9088-c4e271389c4e:1	CONTEST_PRIZE
23a4481a-14b2-4c80-9de7-5f1431d4cdb5	9e60eafe-d7b5-4ba8-9622-8a7e881717d2	contest_entry	-10000	90000	contest	7ed8ef63-9fe8-450b-b6f4-ba33e7a3cef8	Entry fee for contest phase2-e2e (ID: 7ed8ef63-9fe8-450b-b6f4-ba33e7a3cef8)	2026-08-16 01:27:11.250735+00	contest_entry:7ed8ef63-9fe8-450b-b6f4-ba33e7a3cef8:9e60eafe-d7b5-4ba8-9622-8a7e881717d2	CONTEST_ENTRY
cc6a40f9-ffac-4107-8c54-00c24481c85f	f6e59b39-9e32-439a-879f-6b7683774265	contest_entry	-10000	90000	contest	377995fd-6611-49f1-a4f8-99d9fb83e856	Entry fee for contest phase2-e2e (ID: 377995fd-6611-49f1-a4f8-99d9fb83e856)	2026-08-16 01:27:11.414103+00	contest_entry:377995fd-6611-49f1-a4f8-99d9fb83e856:f6e59b39-9e32-439a-879f-6b7683774265	CONTEST_ENTRY
3bc06db0-5c00-488e-a8e2-232c5738435b	e0f0783c-9e4f-47d3-a0f0-783c9e4fa7d3	contest_entry	-10000	40000	contest	e0f0783c-9e4f-47d3-a0f0-783c9e4fa7d3	Entry fee for contest phase11-e2e (ID: e0f0783c-9e4f-47d3-a0f0-783c9e4fa7d3)	2026-08-16 01:27:13.545208+00	contest_entry:e0f0783c-9e4f-47d3-a0f0-783c9e4fa7d3:e0f0783c-9e4f-47d3-a0f0-783c9e4fa7d3	CONTEST_ENTRY
386fda2e-216c-4ffb-823e-5cd405cfb126	e0f0783c-9e4f-47d3-a0f0-783c9e4fa7d3	prize_credit	24000	64000	contest	e0f0783c-9e4f-47d3-a0f0-783c9e4fa7d3	Prize for contest e0f0783c-9e4f-47d3-a0f0-783c9e4fa7d3 (rank 1)	2026-08-16 01:27:13.585031+00	finalization:e0f0783c-9e4f-47d3-a0f0-783c9e4fa7d3:e0f0783c-9e4f-47d3-a0f0-783c9e4fa7d3:1	CONTEST_PRIZE
7cb16bd8-ee25-47e9-a571-7fb70b1462bc	40a0d0e8-f4fa-4dfe-80a0-d0e8f4fafdfe	contest_entry	-10000	40000	contest	40a0d0e8-f4fa-4dfe-80a0-d0e8f4fafdfe	Entry fee for contest phase11-e2e (ID: 40a0d0e8-f4fa-4dfe-80a0-d0e8f4fafdfe)	2026-08-16 01:27:16.201145+00	contest_entry:40a0d0e8-f4fa-4dfe-80a0-d0e8f4fafdfe:40a0d0e8-f4fa-4dfe-80a0-d0e8f4fafdfe	CONTEST_ENTRY
0fb579b5-5a14-4072-a558-fe72b1a9c49d	40a0d0e8-f4fa-4dfe-80a0-d0e8f4fafdfe	prize_credit	24000	64000	contest	40a0d0e8-f4fa-4dfe-80a0-d0e8f4fafdfe	Prize for contest 40a0d0e8-f4fa-4dfe-80a0-d0e8f4fafdfe (rank 1)	2026-08-16 01:27:16.241836+00	finalization:40a0d0e8-f4fa-4dfe-80a0-d0e8f4fafdfe:40a0d0e8-f4fa-4dfe-80a0-d0e8f4fafdfe:1	CONTEST_PRIZE
12e0b1a1-f1b1-472d-8700-5df9e9db6355	6cb6dbed-76bb-4d2e-acb6-dbed76bb5d2e	contest_entry	-10000	40000	contest	6cb6dbed-76bb-4d2e-acb6-dbed76bb5d2e	Entry fee for contest phase11-e2e (ID: 6cb6dbed-76bb-4d2e-acb6-dbed76bb5d2e)	2026-08-16 01:29:16.042356+00	contest_entry:6cb6dbed-76bb-4d2e-acb6-dbed76bb5d2e:6cb6dbed-76bb-4d2e-acb6-dbed76bb5d2e	CONTEST_ENTRY
9ab6f4ef-2c89-49cf-91a4-895cd1901461	6cb6dbed-76bb-4d2e-acb6-dbed76bb5d2e	prize_credit	24000	64000	contest	6cb6dbed-76bb-4d2e-acb6-dbed76bb5d2e	Prize for contest 6cb6dbed-76bb-4d2e-acb6-dbed76bb5d2e (rank 1)	2026-08-16 01:29:16.084938+00	finalization:6cb6dbed-76bb-4d2e-acb6-dbed76bb5d2e:6cb6dbed-76bb-4d2e-acb6-dbed76bb5d2e:1	CONTEST_PRIZE
e315abbd-9a28-4d03-b1f9-a5f4812dc4bc	3c9e4f27-1309-4402-bc9e-4f2713090402	contest_entry	-10000	40000	contest	3c9e4f27-1309-4402-bc9e-4f2713090402	Entry fee for contest phase11-e2e (ID: 3c9e4f27-1309-4402-bc9e-4f2713090402)	2026-08-16 01:29:20.399879+00	contest_entry:3c9e4f27-1309-4402-bc9e-4f2713090402:3c9e4f27-1309-4402-bc9e-4f2713090402	CONTEST_ENTRY
357d6c66-e899-4403-9ed0-4e6655642c25	3c9e4f27-1309-4402-bc9e-4f2713090402	prize_credit	24000	64000	contest	3c9e4f27-1309-4402-bc9e-4f2713090402	Prize for contest 3c9e4f27-1309-4402-bc9e-4f2713090402 (rank 1)	2026-08-16 01:29:20.442616+00	finalization:3c9e4f27-1309-4402-bc9e-4f2713090402:3c9e4f27-1309-4402-bc9e-4f2713090402:1	CONTEST_PRIZE
a399812f-859f-4fea-990b-3eacba448ad8	792c3ecb-0a51-4b66-b78f-411903e74aa3	contest_entry	-10000	90000	contest	a90814e3-b698-406b-b1c7-350edfb7109a	Entry fee for contest phase2-e2e (ID: a90814e3-b698-406b-b1c7-350edfb7109a)	2026-08-16 01:29:20.702336+00	contest_entry:a90814e3-b698-406b-b1c7-350edfb7109a:792c3ecb-0a51-4b66-b78f-411903e74aa3	CONTEST_ENTRY
b891e79a-978b-47fa-8d2e-56d2ce832aae	540d0a22-62a4-45f1-a0ab-2f2092014abb	contest_entry	-10000	90000	contest	a90814e3-b698-406b-b1c7-350edfb7109a	Entry fee for contest phase2-e2e (ID: a90814e3-b698-406b-b1c7-350edfb7109a)	2026-08-16 01:29:20.716252+00	contest_entry:a90814e3-b698-406b-b1c7-350edfb7109a:540d0a22-62a4-45f1-a0ab-2f2092014abb	CONTEST_ENTRY
948bb83e-d19e-466e-a498-8e7f7fd1574b	792c3ecb-0a51-4b66-b78f-411903e74aa3	prize_credit	1000	91000	contest	a90814e3-b698-406b-b1c7-350edfb7109a	Prize for contest a90814e3-b698-406b-b1c7-350edfb7109a (rank 1)	2026-08-16 01:29:20.835286+00	finalization:a90814e3-b698-406b-b1c7-350edfb7109a:792c3ecb-0a51-4b66-b78f-411903e74aa3:1	CONTEST_PRIZE
a5a14e20-4507-4388-bdb0-e0461b7b5607	ffb61316-7d0b-4e05-a80f-d634f1b9391d	contest_entry	-10000	90000	contest	0acab9a9-ee24-4ff4-8587-fe642f0c3320	Entry fee for contest phase2-e2e (ID: 0acab9a9-ee24-4ff4-8587-fe642f0c3320)	2026-08-16 01:29:20.914369+00	contest_entry:0acab9a9-ee24-4ff4-8587-fe642f0c3320:ffb61316-7d0b-4e05-a80f-d634f1b9391d	CONTEST_ENTRY
247b862e-c2d6-4f1c-b5ee-12b91fae5e68	633e7e4b-d5a2-41c7-9a17-af7e54fd4c6c	contest_entry	-10000	90000	contest	a4da580b-6aa3-4a5e-b7ef-79468cf4cf1b	Entry fee for contest phase2-e2e (ID: a4da580b-6aa3-4a5e-b7ef-79468cf4cf1b)	2026-08-16 01:29:21.118704+00	contest_entry:a4da580b-6aa3-4a5e-b7ef-79468cf4cf1b:633e7e4b-d5a2-41c7-9a17-af7e54fd4c6c	CONTEST_ENTRY
91bf0d6f-ce9f-45e4-8dce-34303d9f623b	a452a954-aa55-4a55-a452-a954aa55aa55	contest_entry	-10000	40000	contest	a452a954-aa55-4a55-a452-a954aa55aa55	Entry fee for contest phase11-e2e (ID: a452a954-aa55-4a55-a452-a954aa55aa55)	2026-08-16 01:54:02.00923+00	contest_entry:a452a954-aa55-4a55-a452-a954aa55aa55:a452a954-aa55-4a55-a452-a954aa55aa55	CONTEST_ENTRY
5186b594-b788-4c91-8160-7cfbd47241d1	a452a954-aa55-4a55-a452-a954aa55aa55	prize_credit	24000	64000	contest	a452a954-aa55-4a55-a452-a954aa55aa55	Prize for contest a452a954-aa55-4a55-a452-a954aa55aa55 (rank 1)	2026-08-16 01:54:02.050486+00	finalization:a452a954-aa55-4a55-a452-a954aa55aa55:a452a954-aa55-4a55-a452-a954aa55aa55:1	CONTEST_PRIZE
51b3a6ca-436e-4fda-9769-24470ca81096	74ba5dae-d7eb-453a-b4ba-5daed7eb753a	contest_entry	-10000	40000	contest	74ba5dae-d7eb-453a-b4ba-5daed7eb753a	Entry fee for contest phase11-e2e (ID: 74ba5dae-d7eb-453a-b4ba-5daed7eb753a)	2026-08-16 01:54:04.779897+00	contest_entry:74ba5dae-d7eb-453a-b4ba-5daed7eb753a:74ba5dae-d7eb-453a-b4ba-5daed7eb753a	CONTEST_ENTRY
42fa1765-0ee2-4320-908d-a33c4710273b	74ba5dae-d7eb-453a-b4ba-5daed7eb753a	prize_credit	24000	64000	contest	74ba5dae-d7eb-453a-b4ba-5daed7eb753a	Prize for contest 74ba5dae-d7eb-453a-b4ba-5daed7eb753a (rank 1)	2026-08-16 01:54:04.820027+00	finalization:74ba5dae-d7eb-453a-b4ba-5daed7eb753a:74ba5dae-d7eb-453a-b4ba-5daed7eb753a:1	CONTEST_PRIZE
884c4ca6-0072-4eed-96e9-dec650905b88	68b45a2d-96cb-45f2-a8b4-5a2d96cbe5f2	contest_entry	-10000	40000	contest	68b45a2d-96cb-45f2-a8b4-5a2d96cbe5f2	Entry fee for contest phase11-e2e (ID: 68b45a2d-96cb-45f2-a8b4-5a2d96cbe5f2)	2026-08-16 01:54:27.476379+00	contest_entry:68b45a2d-96cb-45f2-a8b4-5a2d96cbe5f2:68b45a2d-96cb-45f2-a8b4-5a2d96cbe5f2	CONTEST_ENTRY
75eecc3c-3445-4f23-a36d-eddfac810f57	68b45a2d-96cb-45f2-a8b4-5a2d96cbe5f2	prize_credit	24000	64000	contest	68b45a2d-96cb-45f2-a8b4-5a2d96cbe5f2	Prize for contest 68b45a2d-96cb-45f2-a8b4-5a2d96cbe5f2 (rank 1)	2026-08-16 01:54:27.516939+00	finalization:68b45a2d-96cb-45f2-a8b4-5a2d96cbe5f2:68b45a2d-96cb-45f2-a8b4-5a2d96cbe5f2:1	CONTEST_PRIZE
f8d4299d-e1fd-4f7e-83e3-cbbdbeca8681	40a0d068-341a-4d86-80a0-d068341a0d86	contest_entry	-10000	40000	contest	40a0d068-341a-4d86-80a0-d068341a0d86	Entry fee for contest phase11-e2e (ID: 40a0d068-341a-4d86-80a0-d068341a0d86)	2026-08-16 01:54:58.381906+00	contest_entry:40a0d068-341a-4d86-80a0-d068341a0d86:40a0d068-341a-4d86-80a0-d068341a0d86	CONTEST_ENTRY
9bab4c5c-f3eb-4ee6-a3e5-5716cb2e22f7	40a0d068-341a-4d86-80a0-d068341a0d86	prize_credit	24000	64000	contest	40a0d068-341a-4d86-80a0-d068341a0d86	Prize for contest 40a0d068-341a-4d86-80a0-d068341a0d86 (rank 1)	2026-08-16 01:54:58.422328+00	finalization:40a0d068-341a-4d86-80a0-d068341a0d86:40a0d068-341a-4d86-80a0-d068341a0d86:1	CONTEST_PRIZE
f8c5eb07-8f25-4c3d-bb9d-b6a011b3678c	c8e4f279-3c1e-4f87-88e4-f2793c1e0f87	contest_entry	-10000	40000	contest	c8e4f279-3c1e-4f87-88e4-f2793c1e0f87	Entry fee for contest phase11-e2e (ID: c8e4f279-3c1e-4f87-88e4-f2793c1e0f87)	2026-08-16 02:00:06.259334+00	contest_entry:c8e4f279-3c1e-4f87-88e4-f2793c1e0f87:c8e4f279-3c1e-4f87-88e4-f2793c1e0f87	CONTEST_ENTRY
c749f887-d5c8-4d81-b080-67873a765be8	c8e4f279-3c1e-4f87-88e4-f2793c1e0f87	prize_credit	24000	64000	contest	c8e4f279-3c1e-4f87-88e4-f2793c1e0f87	Prize for contest c8e4f279-3c1e-4f87-88e4-f2793c1e0f87 (rank 1)	2026-08-16 02:00:06.301425+00	finalization:c8e4f279-3c1e-4f87-88e4-f2793c1e0f87:c8e4f279-3c1e-4f87-88e4-f2793c1e0f87:1	CONTEST_PRIZE
af8bad2b-a351-463a-8a19-f8f8d1433d69	3098cc66-b359-4c56-b098-cc66b359ac56	contest_entry	-10000	40000	contest	3098cc66-b359-4c56-b098-cc66b359ac56	Entry fee for contest phase11-e2e (ID: 3098cc66-b359-4c56-b098-cc66b359ac56)	2026-08-16 02:27:08.331249+00	contest_entry:3098cc66-b359-4c56-b098-cc66b359ac56:3098cc66-b359-4c56-b098-cc66b359ac56	CONTEST_ENTRY
85b4c5d5-665b-4d19-b122-68ec887efe34	3098cc66-b359-4c56-b098-cc66b359ac56	prize_credit	24000	64000	contest	3098cc66-b359-4c56-b098-cc66b359ac56	Prize for contest 3098cc66-b359-4c56-b098-cc66b359ac56 (rank 1)	2026-08-16 02:27:08.409682+00	finalization:3098cc66-b359-4c56-b098-cc66b359ac56:3098cc66-b359-4c56-b098-cc66b359ac56:1	CONTEST_PRIZE
8008d13e-e4ce-4072-8ccf-ed9a19f84452	2669d7fa-c10f-4128-9395-ada433d4631e	contest_entry	-10000	90000	contest	7ee13a8f-4022-43c6-a084-fbe10763ac10	Entry fee for contest phase2-e2e (ID: 7ee13a8f-4022-43c6-a084-fbe10763ac10)	2026-08-16 02:27:10.402903+00	contest_entry:7ee13a8f-4022-43c6-a084-fbe10763ac10:2669d7fa-c10f-4128-9395-ada433d4631e	CONTEST_ENTRY
33cd820d-bb20-434a-8ffa-7926779ca4c8	452e07e0-e8eb-4f0f-98f2-f8875cd88831	contest_entry	-10000	90000	contest	7ee13a8f-4022-43c6-a084-fbe10763ac10	Entry fee for contest phase2-e2e (ID: 7ee13a8f-4022-43c6-a084-fbe10763ac10)	2026-08-16 02:27:10.417339+00	contest_entry:7ee13a8f-4022-43c6-a084-fbe10763ac10:452e07e0-e8eb-4f0f-98f2-f8875cd88831	CONTEST_ENTRY
891dbbae-0a6b-4504-95f7-f9003eac3826	2669d7fa-c10f-4128-9395-ada433d4631e	prize_credit	1000	91000	contest	7ee13a8f-4022-43c6-a084-fbe10763ac10	Prize for contest 7ee13a8f-4022-43c6-a084-fbe10763ac10 (rank 1)	2026-08-16 02:27:10.494021+00	finalization:7ee13a8f-4022-43c6-a084-fbe10763ac10:2669d7fa-c10f-4128-9395-ada433d4631e:1	CONTEST_PRIZE
06100df0-2380-4098-a57b-8abe501f5392	653652cd-820e-4692-a7bb-1bb90a20936a	contest_entry	-10000	90000	contest	1883b591-7d1a-4f42-9325-9507c69f7df8	Entry fee for contest phase2-e2e (ID: 1883b591-7d1a-4f42-9325-9507c69f7df8)	2026-08-16 02:27:10.547512+00	contest_entry:1883b591-7d1a-4f42-9325-9507c69f7df8:653652cd-820e-4692-a7bb-1bb90a20936a	CONTEST_ENTRY
7b686518-91bd-4614-b14e-433adff8c51e	3c9e4fa7-d3e9-44ba-bc9e-4fa7d3e974ba	contest_entry	-10000	40000	contest	3c9e4fa7-d3e9-44ba-bc9e-4fa7d3e974ba	Entry fee for contest phase11-e2e (ID: 3c9e4fa7-d3e9-44ba-bc9e-4fa7d3e974ba)	2026-08-16 02:43:00.2092+00	contest_entry:3c9e4fa7-d3e9-44ba-bc9e-4fa7d3e974ba:3c9e4fa7-d3e9-44ba-bc9e-4fa7d3e974ba	CONTEST_ENTRY
fecde8ef-4a63-4671-bd30-3f0c8606c16a	3c9e4fa7-d3e9-44ba-bc9e-4fa7d3e974ba	prize_credit	24000	64000	contest	3c9e4fa7-d3e9-44ba-bc9e-4fa7d3e974ba	Prize for contest 3c9e4fa7-d3e9-44ba-bc9e-4fa7d3e974ba (rank 1)	2026-08-16 02:43:00.257328+00	finalization:3c9e4fa7-d3e9-44ba-bc9e-4fa7d3e974ba:3c9e4fa7-d3e9-44ba-bc9e-4fa7d3e974ba:1	CONTEST_PRIZE
e615978c-150c-48cf-af36-5adb6aba6354	c9e259ce-38b0-4b00-a3a3-9b5771d9b6de	contest_entry	-10000	90000	contest	44bfb9c9-0453-4707-ad78-b1f69903b962	Entry fee for contest phase2-e2e (ID: 44bfb9c9-0453-4707-ad78-b1f69903b962)	2026-08-16 02:43:02.724037+00	contest_entry:44bfb9c9-0453-4707-ad78-b1f69903b962:c9e259ce-38b0-4b00-a3a3-9b5771d9b6de	CONTEST_ENTRY
8e590feb-8154-49af-be8d-c3dd564ada13	e8a771e3-92db-4a30-9bb0-c4b84125187f	contest_entry	-10000	90000	contest	44bfb9c9-0453-4707-ad78-b1f69903b962	Entry fee for contest phase2-e2e (ID: 44bfb9c9-0453-4707-ad78-b1f69903b962)	2026-08-16 02:43:02.735804+00	contest_entry:44bfb9c9-0453-4707-ad78-b1f69903b962:e8a771e3-92db-4a30-9bb0-c4b84125187f	CONTEST_ENTRY
b5f9d8b5-f2e8-405e-9b8a-fb707b5453cb	c9e259ce-38b0-4b00-a3a3-9b5771d9b6de	prize_credit	1000	91000	contest	44bfb9c9-0453-4707-ad78-b1f69903b962	Prize for contest 44bfb9c9-0453-4707-ad78-b1f69903b962 (rank 1)	2026-08-16 02:43:02.79464+00	finalization:44bfb9c9-0453-4707-ad78-b1f69903b962:c9e259ce-38b0-4b00-a3a3-9b5771d9b6de:1	CONTEST_PRIZE
8dee2157-899d-4037-81f7-7ec603524215	d8bacc11-7441-48e2-9f65-7d387dd9ea26	contest_entry	-10000	90000	contest	1b87adda-e572-4a9e-9243-8c861bfcb234	Entry fee for contest phase2-e2e (ID: 1b87adda-e572-4a9e-9243-8c861bfcb234)	2026-08-16 02:43:02.840554+00	contest_entry:1b87adda-e572-4a9e-9243-8c861bfcb234:d8bacc11-7441-48e2-9f65-7d387dd9ea26	CONTEST_ENTRY
2120fc06-772b-4ad1-ac25-0ebf1616ce83	241289c4-6231-48cc-a412-89c4623198cc	contest_entry	-10000	40000	contest	241289c4-6231-48cc-a412-89c4623198cc	Entry fee for contest phase11-e2e (ID: 241289c4-6231-48cc-a412-89c4623198cc)	2026-08-16 02:44:00.171901+00	contest_entry:241289c4-6231-48cc-a412-89c4623198cc:241289c4-6231-48cc-a412-89c4623198cc	CONTEST_ENTRY
cf57dca5-4f19-4b1d-b5a2-40be335855a4	241289c4-6231-48cc-a412-89c4623198cc	prize_credit	24000	64000	contest	241289c4-6231-48cc-a412-89c4623198cc	Prize for contest 241289c4-6231-48cc-a412-89c4623198cc (rank 1)	2026-08-16 02:44:00.213236+00	finalization:241289c4-6231-48cc-a412-89c4623198cc:241289c4-6231-48cc-a412-89c4623198cc:1	CONTEST_PRIZE
e5f0be7b-ca9f-4a31-97ea-2588444d73a2	76ada4f6-10d5-4219-a405-f8d5e5b32b78	contest_entry	-10000	90000	contest	c4c0f294-68d1-4e7b-af65-0a2410c03088	Entry fee for contest phase2-e2e (ID: c4c0f294-68d1-4e7b-af65-0a2410c03088)	2026-08-16 02:44:02.002579+00	contest_entry:c4c0f294-68d1-4e7b-af65-0a2410c03088:76ada4f6-10d5-4219-a405-f8d5e5b32b78	CONTEST_ENTRY
c4b73aeb-b8e6-4a79-8538-e4c893768e9e	d00ce5cc-0dc6-4078-935c-2a75b2349ba2	contest_entry	-10000	90000	contest	c4c0f294-68d1-4e7b-af65-0a2410c03088	Entry fee for contest phase2-e2e (ID: c4c0f294-68d1-4e7b-af65-0a2410c03088)	2026-08-16 02:44:02.015362+00	contest_entry:c4c0f294-68d1-4e7b-af65-0a2410c03088:d00ce5cc-0dc6-4078-935c-2a75b2349ba2	CONTEST_ENTRY
0e2f18e1-c3a3-41ab-a672-d8e1c439f791	76ada4f6-10d5-4219-a405-f8d5e5b32b78	prize_credit	1000	91000	contest	c4c0f294-68d1-4e7b-af65-0a2410c03088	Prize for contest c4c0f294-68d1-4e7b-af65-0a2410c03088 (rank 1)	2026-08-16 02:44:02.081126+00	finalization:c4c0f294-68d1-4e7b-af65-0a2410c03088:76ada4f6-10d5-4219-a405-f8d5e5b32b78:1	CONTEST_PRIZE
5fcffe38-3286-47fb-9351-cb009dd6276a	0499cba2-41b1-4fd3-b4f7-07d7e77bd094	contest_entry	-10000	90000	contest	251dba09-bdf8-4e44-9d96-ab9f984dd99d	Entry fee for contest phase2-e2e (ID: 251dba09-bdf8-4e44-9d96-ab9f984dd99d)	2026-08-16 02:44:02.129779+00	contest_entry:251dba09-bdf8-4e44-9d96-ab9f984dd99d:0499cba2-41b1-4fd3-b4f7-07d7e77bd094	CONTEST_ENTRY
8a846b50-6639-4b08-93e0-168bf22f5670	f6491f08-63d2-476f-873f-db5cf69c0122	contest_entry	-10000	90000	contest	e88ecf13-0a84-4631-a816-aec1d3405c03	Entry fee for contest phase2-e2e (ID: e88ecf13-0a84-4631-a816-aec1d3405c03)	2026-08-16 02:44:05.833016+00	contest_entry:e88ecf13-0a84-4631-a816-aec1d3405c03:f6491f08-63d2-476f-873f-db5cf69c0122	CONTEST_ENTRY
44f26857-1b44-4b44-8f17-1a50ee721d19	302640fe-27ce-4abe-b59a-5ec4dc69944c	contest_entry	-10000	90000	contest	e88ecf13-0a84-4631-a816-aec1d3405c03	Entry fee for contest phase2-e2e (ID: e88ecf13-0a84-4631-a816-aec1d3405c03)	2026-08-16 02:44:05.850045+00	contest_entry:e88ecf13-0a84-4631-a816-aec1d3405c03:302640fe-27ce-4abe-b59a-5ec4dc69944c	CONTEST_ENTRY
fcae234a-1cb9-485a-9ba6-214610b7d5eb	f6491f08-63d2-476f-873f-db5cf69c0122	prize_credit	1000	91000	contest	e88ecf13-0a84-4631-a816-aec1d3405c03	Prize for contest e88ecf13-0a84-4631-a816-aec1d3405c03 (rank 1)	2026-08-16 02:44:05.931941+00	finalization:e88ecf13-0a84-4631-a816-aec1d3405c03:f6491f08-63d2-476f-873f-db5cf69c0122:1	CONTEST_PRIZE
d07ca632-20a6-459e-9a0a-e19648af4670	984c2613-89c4-42f1-984c-261389c4e2f1	contest_entry	-10000	40000	contest	984c2613-89c4-42f1-984c-261389c4e2f1	Entry fee for contest phase11-e2e (ID: 984c2613-89c4-42f1-984c-261389c4e2f1)	2026-08-16 02:44:06.957941+00	contest_entry:984c2613-89c4-42f1-984c-261389c4e2f1:984c2613-89c4-42f1-984c-261389c4e2f1	CONTEST_ENTRY
9d9bf072-7b5a-4dc5-a665-a10ee904d3b5	984c2613-89c4-42f1-984c-261389c4e2f1	prize_credit	24000	64000	contest	984c2613-89c4-42f1-984c-261389c4e2f1	Prize for contest 984c2613-89c4-42f1-984c-261389c4e2f1 (rank 1)	2026-08-16 02:44:06.996996+00	finalization:984c2613-89c4-42f1-984c-261389c4e2f1:984c2613-89c4-42f1-984c-261389c4e2f1:1	CONTEST_PRIZE
b93d2f10-8fa0-4b9f-936d-7813fe0882eb	218b00a6-dd31-4954-8850-989f8454cb72	contest_entry	-10000	90000	contest	f78b4135-f060-4447-a994-080db7058160	Entry fee for contest phase2-e2e (ID: f78b4135-f060-4447-a994-080db7058160)	2026-08-16 02:44:08.565654+00	contest_entry:f78b4135-f060-4447-a994-080db7058160:218b00a6-dd31-4954-8850-989f8454cb72	CONTEST_ENTRY
c79b3f89-a1f7-45b8-b5a4-0628e0fa2388	b479eb08-1b65-411d-964c-028ed616a70d	contest_entry	-10000	90000	contest	f78b4135-f060-4447-a994-080db7058160	Entry fee for contest phase2-e2e (ID: f78b4135-f060-4447-a994-080db7058160)	2026-08-16 02:44:08.578885+00	contest_entry:f78b4135-f060-4447-a994-080db7058160:b479eb08-1b65-411d-964c-028ed616a70d	CONTEST_ENTRY
330f84f2-0a3d-45ab-98f4-e3cadb5c4b71	218b00a6-dd31-4954-8850-989f8454cb72	prize_credit	1000	91000	contest	f78b4135-f060-4447-a994-080db7058160	Prize for contest f78b4135-f060-4447-a994-080db7058160 (rank 1)	2026-08-16 02:44:08.639058+00	finalization:f78b4135-f060-4447-a994-080db7058160:218b00a6-dd31-4954-8850-989f8454cb72:1	CONTEST_PRIZE
ea1c4171-4b60-4671-a9f2-1bfeea6ff38c	c66062f8-5699-49a8-a1bb-05a591ab9f22	contest_entry	-10000	90000	contest	694d8dc8-1ae8-4377-aa82-3e811b7fdb90	Entry fee for contest phase2-e2e (ID: 694d8dc8-1ae8-4377-aa82-3e811b7fdb90)	2026-08-16 02:44:11.078145+00	contest_entry:694d8dc8-1ae8-4377-aa82-3e811b7fdb90:c66062f8-5699-49a8-a1bb-05a591ab9f22	CONTEST_ENTRY
3b8fc4e3-9de3-4d87-9138-7adf32aba8c3	646173e1-c3cb-42b3-8252-1f9a45adf2d5	contest_entry	-10000	90000	contest	694d8dc8-1ae8-4377-aa82-3e811b7fdb90	Entry fee for contest phase2-e2e (ID: 694d8dc8-1ae8-4377-aa82-3e811b7fdb90)	2026-08-16 02:44:11.089713+00	contest_entry:694d8dc8-1ae8-4377-aa82-3e811b7fdb90:646173e1-c3cb-42b3-8252-1f9a45adf2d5	CONTEST_ENTRY
477065a2-3516-48ad-801e-1da59cad3322	c66062f8-5699-49a8-a1bb-05a591ab9f22	prize_credit	1000	91000	contest	694d8dc8-1ae8-4377-aa82-3e811b7fdb90	Prize for contest 694d8dc8-1ae8-4377-aa82-3e811b7fdb90 (rank 1)	2026-08-16 02:44:11.151954+00	finalization:694d8dc8-1ae8-4377-aa82-3e811b7fdb90:c66062f8-5699-49a8-a1bb-05a591ab9f22:1	CONTEST_PRIZE
7eb18608-3f8e-46ac-ab6d-2391a7efb36c	582c160b-8542-4150-982c-160b8542a150	contest_entry	-10000	40000	contest	582c160b-8542-4150-982c-160b8542a150	Entry fee for contest phase11-e2e (ID: 582c160b-8542-4150-982c-160b8542a150)	2026-08-16 02:44:36.048969+00	contest_entry:582c160b-8542-4150-982c-160b8542a150:582c160b-8542-4150-982c-160b8542a150	CONTEST_ENTRY
b5852cef-8709-4402-9160-90946fe8aa7f	582c160b-8542-4150-982c-160b8542a150	prize_credit	24000	64000	contest	582c160b-8542-4150-982c-160b8542a150	Prize for contest 582c160b-8542-4150-982c-160b8542a150 (rank 1)	2026-08-16 02:44:36.090925+00	finalization:582c160b-8542-4150-982c-160b8542a150:582c160b-8542-4150-982c-160b8542a150:1	CONTEST_PRIZE
de213ae3-7c17-4d85-984e-ee35183fd7be	b85c2e97-4b25-4209-b85c-2e974b251209	contest_entry	-10000	40000	contest	b85c2e97-4b25-4209-b85c-2e974b251209	Entry fee for contest phase11-e2e (ID: b85c2e97-4b25-4209-b85c-2e974b251209)	2026-08-16 02:44:37.148143+00	contest_entry:b85c2e97-4b25-4209-b85c-2e974b251209:b85c2e97-4b25-4209-b85c-2e974b251209	CONTEST_ENTRY
0282ff5e-75b3-45c8-a8e8-919fa22e5ec6	b85c2e97-4b25-4209-b85c-2e974b251209	prize_credit	24000	64000	contest	b85c2e97-4b25-4209-b85c-2e974b251209	Prize for contest b85c2e97-4b25-4209-b85c-2e974b251209 (rank 1)	2026-08-16 02:44:37.189908+00	finalization:b85c2e97-4b25-4209-b85c-2e974b251209:b85c2e97-4b25-4209-b85c-2e974b251209:1	CONTEST_PRIZE
ef9e44fc-f1e1-4cad-b2c3-7e5ff0d94aa7	80402090-48a4-4269-8040-209048a4d269	contest_entry	-10000	40000	contest	80402090-48a4-4269-8040-209048a4d269	Entry fee for contest phase11-e2e (ID: 80402090-48a4-4269-8040-209048a4d269)	2026-08-16 02:44:38.414932+00	contest_entry:80402090-48a4-4269-8040-209048a4d269:80402090-48a4-4269-8040-209048a4d269	CONTEST_ENTRY
c1352238-8956-477e-bc94-07d96020e10f	80402090-48a4-4269-8040-209048a4d269	prize_credit	24000	64000	contest	80402090-48a4-4269-8040-209048a4d269	Prize for contest 80402090-48a4-4269-8040-209048a4d269 (rank 1)	2026-08-16 02:44:38.469138+00	finalization:80402090-48a4-4269-8040-209048a4d269:80402090-48a4-4269-8040-209048a4d269:1	CONTEST_PRIZE
f4aa1fa4-924e-4db5-929d-4ca9a3365478	b8dc6e37-9bcd-4633-b8dc-6e379bcd6633	contest_entry	-10000	40000	contest	b8dc6e37-9bcd-4633-b8dc-6e379bcd6633	Entry fee for contest phase11-e2e (ID: b8dc6e37-9bcd-4633-b8dc-6e379bcd6633)	2026-08-16 02:44:55.627817+00	contest_entry:b8dc6e37-9bcd-4633-b8dc-6e379bcd6633:b8dc6e37-9bcd-4633-b8dc-6e379bcd6633	CONTEST_ENTRY
f93274dc-1b17-4f6e-8a32-dc2a8cc67597	b8dc6e37-9bcd-4633-b8dc-6e379bcd6633	prize_credit	24000	64000	contest	b8dc6e37-9bcd-4633-b8dc-6e379bcd6633	Prize for contest b8dc6e37-9bcd-4633-b8dc-6e379bcd6633 (rank 1)	2026-08-16 02:44:55.68707+00	finalization:b8dc6e37-9bcd-4633-b8dc-6e379bcd6633:b8dc6e37-9bcd-4633-b8dc-6e379bcd6633:1	CONTEST_PRIZE
7ca91857-f1c3-4d5b-83ed-9c2feee60d10	743a1d0e-0783-41e0-b43a-1d0e0783c1e0	contest_entry	-10000	40000	contest	743a1d0e-0783-41e0-b43a-1d0e0783c1e0	Entry fee for contest phase11-e2e (ID: 743a1d0e-0783-41e0-b43a-1d0e0783c1e0)	2026-08-16 02:45:57.310998+00	contest_entry:743a1d0e-0783-41e0-b43a-1d0e0783c1e0:743a1d0e-0783-41e0-b43a-1d0e0783c1e0	CONTEST_ENTRY
843506f3-1309-484a-97a5-157788271590	743a1d0e-0783-41e0-b43a-1d0e0783c1e0	prize_credit	24000	64000	contest	743a1d0e-0783-41e0-b43a-1d0e0783c1e0	Prize for contest 743a1d0e-0783-41e0-b43a-1d0e0783c1e0 (rank 1)	2026-08-16 02:45:57.353092+00	finalization:743a1d0e-0783-41e0-b43a-1d0e0783c1e0:743a1d0e-0783-41e0-b43a-1d0e0783c1e0:1	CONTEST_PRIZE
952a4798-dd8a-46ac-8f03-c153513ef0e1	0d4fd196-fc76-49cf-a78c-ce25c8a03022	contest_entry	-10000	90000	contest	c71ff9b5-d220-42f2-9f5f-053fcc08e9b4	Entry fee for contest phase2-e2e (ID: c71ff9b5-d220-42f2-9f5f-053fcc08e9b4)	2026-08-16 02:45:59.088035+00	contest_entry:c71ff9b5-d220-42f2-9f5f-053fcc08e9b4:0d4fd196-fc76-49cf-a78c-ce25c8a03022	CONTEST_ENTRY
0e64df6f-7445-4e21-a7de-ba9c8a4fcdb7	426be798-f942-40a8-8609-cd231f5ebb08	contest_entry	-10000	90000	contest	c71ff9b5-d220-42f2-9f5f-053fcc08e9b4	Entry fee for contest phase2-e2e (ID: c71ff9b5-d220-42f2-9f5f-053fcc08e9b4)	2026-08-16 02:45:59.09986+00	contest_entry:c71ff9b5-d220-42f2-9f5f-053fcc08e9b4:426be798-f942-40a8-8609-cd231f5ebb08	CONTEST_ENTRY
7472af6f-a17c-4e86-b7cf-295e2e3c6c3c	0d4fd196-fc76-49cf-a78c-ce25c8a03022	prize_credit	1000	91000	contest	c71ff9b5-d220-42f2-9f5f-053fcc08e9b4	Prize for contest c71ff9b5-d220-42f2-9f5f-053fcc08e9b4 (rank 1)	2026-08-16 02:45:59.162149+00	finalization:c71ff9b5-d220-42f2-9f5f-053fcc08e9b4:0d4fd196-fc76-49cf-a78c-ce25c8a03022:1	CONTEST_PRIZE
abf1526b-4e9b-4ca7-b179-e44f6eea3006	cdf8aaad-4a4f-4dc9-a592-79fe503633f7	contest_entry	-10000	90000	contest	0cd34720-b787-4e6f-acae-2c5df8a43def	Entry fee for contest phase2-e2e (ID: 0cd34720-b787-4e6f-acae-2c5df8a43def)	2026-08-16 02:45:59.208292+00	contest_entry:0cd34720-b787-4e6f-acae-2c5df8a43def:cdf8aaad-4a4f-4dc9-a592-79fe503633f7	CONTEST_ENTRY
1e5f01ca-1fb4-493f-9ef5-7250f4cc498a	a8542a95-4aa5-4229-a854-2a954aa55229	contest_entry	-10000	40000	contest	a8542a95-4aa5-4229-a854-2a954aa55229	Entry fee for contest phase11-e2e (ID: a8542a95-4aa5-4229-a854-2a954aa55229)	2026-08-16 02:48:32.631208+00	contest_entry:a8542a95-4aa5-4229-a854-2a954aa55229:a8542a95-4aa5-4229-a854-2a954aa55229	CONTEST_ENTRY
2ee4a3c5-1109-4436-a4fe-1caa5b4088dc	a8542a95-4aa5-4229-a854-2a954aa55229	prize_credit	24000	64000	contest	a8542a95-4aa5-4229-a854-2a954aa55229	Prize for contest a8542a95-4aa5-4229-a854-2a954aa55229 (rank 1)	2026-08-16 02:48:32.671785+00	finalization:a8542a95-4aa5-4229-a854-2a954aa55229:a8542a95-4aa5-4229-a854-2a954aa55229:1	CONTEST_PRIZE
1973f163-9ccb-43c0-8f7a-8898a5eeb8b2	1b5063b8-9733-4563-beef-2c787c3365a9	contest_entry	-10000	90000	contest	52a2a329-50dc-4684-a7b0-5c090616c56d	Entry fee for contest phase2-e2e (ID: 52a2a329-50dc-4684-a7b0-5c090616c56d)	2026-08-16 02:48:34.377308+00	contest_entry:52a2a329-50dc-4684-a7b0-5c090616c56d:1b5063b8-9733-4563-beef-2c787c3365a9	CONTEST_ENTRY
624841b7-6423-4bd0-ba4f-af9861f570eb	a3d7c5f3-40e0-4c2f-933a-f95a98ab57f3	contest_entry	-10000	90000	contest	52a2a329-50dc-4684-a7b0-5c090616c56d	Entry fee for contest phase2-e2e (ID: 52a2a329-50dc-4684-a7b0-5c090616c56d)	2026-08-16 02:48:34.388691+00	contest_entry:52a2a329-50dc-4684-a7b0-5c090616c56d:a3d7c5f3-40e0-4c2f-933a-f95a98ab57f3	CONTEST_ENTRY
352a3a48-51d4-4adb-9dd7-382059e382c3	1b5063b8-9733-4563-beef-2c787c3365a9	prize_credit	1000	91000	contest	52a2a329-50dc-4684-a7b0-5c090616c56d	Prize for contest 52a2a329-50dc-4684-a7b0-5c090616c56d (rank 1)	2026-08-16 02:48:34.451916+00	finalization:52a2a329-50dc-4684-a7b0-5c090616c56d:1b5063b8-9733-4563-beef-2c787c3365a9:1	CONTEST_PRIZE
fe454273-1784-42b9-abb3-ace833299472	ddeff84e-1027-4038-8102-7ce08c9e5a94	contest_entry	-10000	90000	contest	05e6381b-9834-46cb-acfb-5d58cdd36755	Entry fee for contest phase2-e2e (ID: 05e6381b-9834-46cb-acfb-5d58cdd36755)	2026-08-16 02:48:34.501071+00	contest_entry:05e6381b-9834-46cb-acfb-5d58cdd36755:ddeff84e-1027-4038-8102-7ce08c9e5a94	CONTEST_ENTRY
a7ee5158-0504-4b9b-a797-100d9f9cf3f3	b45aad56-abd5-4a75-b45a-ad56abd5ea75	contest_entry	-10000	40000	contest	b45aad56-abd5-4a75-b45a-ad56abd5ea75	Entry fee for contest phase11-e2e (ID: b45aad56-abd5-4a75-b45a-ad56abd5ea75)	2026-08-16 02:49:04.739164+00	contest_entry:b45aad56-abd5-4a75-b45a-ad56abd5ea75:b45aad56-abd5-4a75-b45a-ad56abd5ea75	CONTEST_ENTRY
5abbe9b1-5f5a-492a-9b63-dad2bb70b4d1	b45aad56-abd5-4a75-b45a-ad56abd5ea75	prize_credit	24000	64000	contest	b45aad56-abd5-4a75-b45a-ad56abd5ea75	Prize for contest b45aad56-abd5-4a75-b45a-ad56abd5ea75 (rank 1)	2026-08-16 02:49:04.780828+00	finalization:b45aad56-abd5-4a75-b45a-ad56abd5ea75:b45aad56-abd5-4a75-b45a-ad56abd5ea75:1	CONTEST_PRIZE
e53d7e14-fd0c-4861-b178-a6170d00d593	f92e8766-b7d0-4dca-add5-9718456d5657	contest_entry	-10000	90000	contest	fb496cf5-0c1c-4296-a861-6bff97a86dfb	Entry fee for contest phase2-e2e (ID: fb496cf5-0c1c-4296-a861-6bff97a86dfb)	2026-08-16 02:49:06.336157+00	contest_entry:fb496cf5-0c1c-4296-a861-6bff97a86dfb:f92e8766-b7d0-4dca-add5-9718456d5657	CONTEST_ENTRY
308c0c9b-c614-403f-9d57-472e945e51c4	071d2be9-9431-4ae5-afbb-9a195b33db15	contest_entry	-10000	90000	contest	fb496cf5-0c1c-4296-a861-6bff97a86dfb	Entry fee for contest phase2-e2e (ID: fb496cf5-0c1c-4296-a861-6bff97a86dfb)	2026-08-16 02:49:06.349341+00	contest_entry:fb496cf5-0c1c-4296-a861-6bff97a86dfb:071d2be9-9431-4ae5-afbb-9a195b33db15	CONTEST_ENTRY
947e1442-b2d6-4989-a01f-7a50339332e3	f92e8766-b7d0-4dca-add5-9718456d5657	prize_credit	1000	91000	contest	fb496cf5-0c1c-4296-a861-6bff97a86dfb	Prize for contest fb496cf5-0c1c-4296-a861-6bff97a86dfb (rank 1)	2026-08-16 02:49:06.409591+00	finalization:fb496cf5-0c1c-4296-a861-6bff97a86dfb:f92e8766-b7d0-4dca-add5-9718456d5657:1	CONTEST_PRIZE
99714d76-a0c1-4e66-9135-fb466c105697	f41fb589-ceb8-47da-9ec4-4c1bb1f0e79d	contest_entry	-10000	90000	contest	2fdd5606-80c0-4948-aca1-c3c4fedc8c87	Entry fee for contest phase2-e2e (ID: 2fdd5606-80c0-4948-aca1-c3c4fedc8c87)	2026-08-16 02:49:07.86568+00	contest_entry:2fdd5606-80c0-4948-aca1-c3c4fedc8c87:f41fb589-ceb8-47da-9ec4-4c1bb1f0e79d	CONTEST_ENTRY
c01933aa-653c-4726-ab7e-66dd15bc1592	2cf63582-501f-451b-8595-587b82b2f40a	contest_entry	-10000	90000	contest	5a7ab285-61fc-4613-8a83-de2bc5a44006	Entry fee for contest phase2-e2e (ID: 5a7ab285-61fc-4613-8a83-de2bc5a44006)	2026-08-16 02:49:30.847373+00	contest_entry:5a7ab285-61fc-4613-8a83-de2bc5a44006:2cf63582-501f-451b-8595-587b82b2f40a	CONTEST_ENTRY
46225b4a-89ba-4874-8afb-30f54a7d11b2	ed2e8329-c2c7-4ed0-b3ea-ed9b6e2abfda	contest_entry	-10000	90000	contest	5a7ab285-61fc-4613-8a83-de2bc5a44006	Entry fee for contest phase2-e2e (ID: 5a7ab285-61fc-4613-8a83-de2bc5a44006)	2026-08-16 02:49:30.859329+00	contest_entry:5a7ab285-61fc-4613-8a83-de2bc5a44006:ed2e8329-c2c7-4ed0-b3ea-ed9b6e2abfda	CONTEST_ENTRY
d11a4de5-24fd-466b-8ce7-fb008cd2d07a	2cf63582-501f-451b-8595-587b82b2f40a	prize_credit	1000	91000	contest	5a7ab285-61fc-4613-8a83-de2bc5a44006	Prize for contest 5a7ab285-61fc-4613-8a83-de2bc5a44006 (rank 1)	2026-08-16 02:49:30.922216+00	finalization:5a7ab285-61fc-4613-8a83-de2bc5a44006:2cf63582-501f-451b-8595-587b82b2f40a:1	CONTEST_PRIZE
2e885862-e03f-4339-a7e8-cdd758d0855d	28140a85-c2e1-40b8-a814-0a85c2e170b8	contest_entry	-10000	40000	contest	28140a85-c2e1-40b8-a814-0a85c2e170b8	Entry fee for contest phase11-e2e (ID: 28140a85-c2e1-40b8-a814-0a85c2e170b8)	2026-08-16 02:49:31.954607+00	contest_entry:28140a85-c2e1-40b8-a814-0a85c2e170b8:28140a85-c2e1-40b8-a814-0a85c2e170b8	CONTEST_ENTRY
f6fd9af0-cfcb-4090-84ca-0abdb05d8593	28140a85-c2e1-40b8-a814-0a85c2e170b8	prize_credit	24000	64000	contest	28140a85-c2e1-40b8-a814-0a85c2e170b8	Prize for contest 28140a85-c2e1-40b8-a814-0a85c2e170b8 (rank 1)	2026-08-16 02:49:31.994592+00	finalization:28140a85-c2e1-40b8-a814-0a85c2e170b8:28140a85-c2e1-40b8-a814-0a85c2e170b8:1	CONTEST_PRIZE
cbca3dfe-2925-4c7a-994b-37965ce7a915	bc5e2f97-cb65-4219-bc5e-2f97cb653219	contest_entry	-10000	40000	contest	bc5e2f97-cb65-4219-bc5e-2f97cb653219	Entry fee for contest phase11-e2e (ID: bc5e2f97-cb65-4219-bc5e-2f97cb653219)	2026-08-16 02:51:29.119708+00	contest_entry:bc5e2f97-cb65-4219-bc5e-2f97cb653219:bc5e2f97-cb65-4219-bc5e-2f97cb653219	CONTEST_ENTRY
1e9130ed-5e8c-4a3d-b8cd-1c4959d7fdf0	bc5e2f97-cb65-4219-bc5e-2f97cb653219	prize_credit	24000	64000	contest	bc5e2f97-cb65-4219-bc5e-2f97cb653219	Prize for contest bc5e2f97-cb65-4219-bc5e-2f97cb653219 (rank 1)	2026-08-16 02:51:29.160541+00	finalization:bc5e2f97-cb65-4219-bc5e-2f97cb653219:bc5e2f97-cb65-4219-bc5e-2f97cb653219:1	CONTEST_PRIZE
a628f35f-5e59-482e-a8a8-f09e3e3dc913	6c6f8218-0e00-4731-9e59-e8b8d4d61b5d	contest_entry	-10000	90000	contest	98cd06fc-fec9-4572-ba77-5952478dd4e7	Entry fee for contest phase2-e2e (ID: 98cd06fc-fec9-4572-ba77-5952478dd4e7)	2026-08-16 02:51:30.858572+00	contest_entry:98cd06fc-fec9-4572-ba77-5952478dd4e7:6c6f8218-0e00-4731-9e59-e8b8d4d61b5d	CONTEST_ENTRY
7b19598c-721d-41ca-82b8-25aed14fd0ad	5d4db3df-ec04-4d3f-a4b7-758b932bdeab	contest_entry	-10000	90000	contest	98cd06fc-fec9-4572-ba77-5952478dd4e7	Entry fee for contest phase2-e2e (ID: 98cd06fc-fec9-4572-ba77-5952478dd4e7)	2026-08-16 02:51:30.871257+00	contest_entry:98cd06fc-fec9-4572-ba77-5952478dd4e7:5d4db3df-ec04-4d3f-a4b7-758b932bdeab	CONTEST_ENTRY
70be62fc-bbb6-44f2-a6cd-aaed0a24c7f6	6c6f8218-0e00-4731-9e59-e8b8d4d61b5d	prize_credit	1000	91000	contest	98cd06fc-fec9-4572-ba77-5952478dd4e7	Prize for contest 98cd06fc-fec9-4572-ba77-5952478dd4e7 (rank 1)	2026-08-16 02:51:30.938952+00	finalization:98cd06fc-fec9-4572-ba77-5952478dd4e7:6c6f8218-0e00-4731-9e59-e8b8d4d61b5d:1	CONTEST_PRIZE
3a24b6dd-f39c-47c1-87eb-1549647fe297	5a5b8479-6d2f-4e8c-8064-84afe7c56e72	contest_entry	-10000	90000	contest	78f2167d-3ba6-4186-bbec-d7e2cde10fe9	Entry fee for contest phase2-e2e (ID: 78f2167d-3ba6-4186-bbec-d7e2cde10fe9)	2026-08-16 02:51:30.983982+00	contest_entry:78f2167d-3ba6-4186-bbec-d7e2cde10fe9:5a5b8479-6d2f-4e8c-8064-84afe7c56e72	CONTEST_ENTRY
ba8e8602-9b23-4f38-89c6-f97f39f1c43f	a0d068b4-5aad-46eb-a0d0-68b45aadd6eb	contest_entry	-10000	40000	contest	a0d068b4-5aad-46eb-a0d0-68b45aadd6eb	Entry fee for contest phase11-e2e (ID: a0d068b4-5aad-46eb-a0d0-68b45aadd6eb)	2026-08-16 02:51:41.106395+00	contest_entry:a0d068b4-5aad-46eb-a0d0-68b45aadd6eb:a0d068b4-5aad-46eb-a0d0-68b45aadd6eb	CONTEST_ENTRY
75ea41e7-c79e-40cc-a72b-ec01a9edc9b6	a0d068b4-5aad-46eb-a0d0-68b45aadd6eb	prize_credit	24000	64000	contest	a0d068b4-5aad-46eb-a0d0-68b45aadd6eb	Prize for contest a0d068b4-5aad-46eb-a0d0-68b45aadd6eb (rank 1)	2026-08-16 02:51:41.145299+00	finalization:a0d068b4-5aad-46eb-a0d0-68b45aadd6eb:a0d068b4-5aad-46eb-a0d0-68b45aadd6eb:1	CONTEST_PRIZE
34c38606-757f-4474-b6c1-343600e1a07a	3f0e5a46-bb93-4f07-a561-60662dd5541a	contest_entry	-10000	90000	contest	7cdecf3d-7746-40f8-87a2-77b6c3125787	Entry fee for contest phase2-e2e (ID: 7cdecf3d-7746-40f8-87a2-77b6c3125787)	2026-08-16 02:51:42.816668+00	contest_entry:7cdecf3d-7746-40f8-87a2-77b6c3125787:3f0e5a46-bb93-4f07-a561-60662dd5541a	CONTEST_ENTRY
4f7c9c84-cb6c-43a2-82e5-cdb35380f8dd	0f108d2e-d94b-4cd8-b88f-504e9d68134a	contest_entry	-10000	90000	contest	7cdecf3d-7746-40f8-87a2-77b6c3125787	Entry fee for contest phase2-e2e (ID: 7cdecf3d-7746-40f8-87a2-77b6c3125787)	2026-08-16 02:51:42.82851+00	contest_entry:7cdecf3d-7746-40f8-87a2-77b6c3125787:0f108d2e-d94b-4cd8-b88f-504e9d68134a	CONTEST_ENTRY
0335989a-d842-40aa-9580-d70e3b2dcc7c	3f0e5a46-bb93-4f07-a561-60662dd5541a	prize_credit	1000	91000	contest	7cdecf3d-7746-40f8-87a2-77b6c3125787	Prize for contest 7cdecf3d-7746-40f8-87a2-77b6c3125787 (rank 1)	2026-08-16 02:51:42.888026+00	finalization:7cdecf3d-7746-40f8-87a2-77b6c3125787:3f0e5a46-bb93-4f07-a561-60662dd5541a:1	CONTEST_PRIZE
09860e2a-3eff-4699-b78e-152dd4ddf84c	515fbee7-3bb0-4b6d-b431-22282d623cd7	contest_entry	-10000	90000	contest	8abf2843-da75-453c-93ee-e0e6334a2f2f	Entry fee for contest phase2-e2e (ID: 8abf2843-da75-453c-93ee-e0e6334a2f2f)	2026-08-16 02:51:42.935371+00	contest_entry:8abf2843-da75-453c-93ee-e0e6334a2f2f:515fbee7-3bb0-4b6d-b431-22282d623cd7	CONTEST_ENTRY
7ac33efa-2cfd-46a7-bfc8-a38725b9e208	9ccee7f3-f97c-4edf-9cce-e7f3f97cbedf	contest_entry	-10000	40000	contest	9ccee7f3-f97c-4edf-9cce-e7f3f97cbedf	Entry fee for contest phase11-e2e (ID: 9ccee7f3-f97c-4edf-9cce-e7f3f97cbedf)	2026-08-16 02:51:46.096007+00	contest_entry:9ccee7f3-f97c-4edf-9cce-e7f3f97cbedf:9ccee7f3-f97c-4edf-9cce-e7f3f97cbedf	CONTEST_ENTRY
b0924567-13d9-4087-a016-b9e0b3cc1e98	9ccee7f3-f97c-4edf-9cce-e7f3f97cbedf	prize_credit	24000	64000	contest	9ccee7f3-f97c-4edf-9cce-e7f3f97cbedf	Prize for contest 9ccee7f3-f97c-4edf-9cce-e7f3f97cbedf (rank 1)	2026-08-16 02:51:46.135682+00	finalization:9ccee7f3-f97c-4edf-9cce-e7f3f97cbedf:9ccee7f3-f97c-4edf-9cce-e7f3f97cbedf:1	CONTEST_PRIZE
51aa1fb1-44fd-4404-ad75-279aec44313f	a14dbc0e-1b40-4539-825b-5bad255f153d	contest_entry	-10000	90000	contest	20ff9240-3690-452c-9b6b-fb0e1b8cf307	Entry fee for contest phase2-e2e (ID: 20ff9240-3690-452c-9b6b-fb0e1b8cf307)	2026-08-16 02:51:47.69577+00	contest_entry:20ff9240-3690-452c-9b6b-fb0e1b8cf307:a14dbc0e-1b40-4539-825b-5bad255f153d	CONTEST_ENTRY
60f45109-2297-4b14-8264-fb5c60b7f9ff	de4588c4-c14b-4f0c-9908-2e0689f907fe	contest_entry	-10000	90000	contest	20ff9240-3690-452c-9b6b-fb0e1b8cf307	Entry fee for contest phase2-e2e (ID: 20ff9240-3690-452c-9b6b-fb0e1b8cf307)	2026-08-16 02:51:47.707742+00	contest_entry:20ff9240-3690-452c-9b6b-fb0e1b8cf307:de4588c4-c14b-4f0c-9908-2e0689f907fe	CONTEST_ENTRY
450077fd-e1be-46fc-a54e-ed724ceab5b0	a14dbc0e-1b40-4539-825b-5bad255f153d	prize_credit	1000	91000	contest	20ff9240-3690-452c-9b6b-fb0e1b8cf307	Prize for contest 20ff9240-3690-452c-9b6b-fb0e1b8cf307 (rank 1)	2026-08-16 02:51:47.769582+00	finalization:20ff9240-3690-452c-9b6b-fb0e1b8cf307:a14dbc0e-1b40-4539-825b-5bad255f153d:1	CONTEST_PRIZE
1903403f-9746-4b6f-9c2d-9e6788970822	5f124107-5c83-432a-80fd-8899e94f9845	contest_entry	-10000	90000	contest	0c9f7448-9b40-4a79-a194-39934e364f6d	Entry fee for contest phase2-e2e (ID: 0c9f7448-9b40-4a79-a194-39934e364f6d)	2026-08-16 02:51:49.285035+00	contest_entry:0c9f7448-9b40-4a79-a194-39934e364f6d:5f124107-5c83-432a-80fd-8899e94f9845	CONTEST_ENTRY
1348893a-8923-488d-abe0-e5cd7cebdad5	e19c7724-0cba-4667-8e36-c469962a9f0e	contest_entry	-10000	90000	contest	3781f153-e2ca-41ec-8738-eb7e0feb7cab	Entry fee for contest phase2-e2e (ID: 3781f153-e2ca-41ec-8738-eb7e0feb7cab)	2026-08-16 02:51:57.564744+00	contest_entry:3781f153-e2ca-41ec-8738-eb7e0feb7cab:e19c7724-0cba-4667-8e36-c469962a9f0e	CONTEST_ENTRY
a3ba0727-063d-4cd2-bc36-ed473e321198	92b04625-4ad6-4bea-94ef-2795bd4c5fa1	contest_entry	-10000	90000	contest	3781f153-e2ca-41ec-8738-eb7e0feb7cab	Entry fee for contest phase2-e2e (ID: 3781f153-e2ca-41ec-8738-eb7e0feb7cab)	2026-08-16 02:51:57.577316+00	contest_entry:3781f153-e2ca-41ec-8738-eb7e0feb7cab:92b04625-4ad6-4bea-94ef-2795bd4c5fa1	CONTEST_ENTRY
c364286f-9279-4215-805d-52a34385af97	e19c7724-0cba-4667-8e36-c469962a9f0e	prize_credit	1000	91000	contest	3781f153-e2ca-41ec-8738-eb7e0feb7cab	Prize for contest 3781f153-e2ca-41ec-8738-eb7e0feb7cab (rank 1)	2026-08-16 02:51:57.643473+00	finalization:3781f153-e2ca-41ec-8738-eb7e0feb7cab:e19c7724-0cba-4667-8e36-c469962a9f0e:1	CONTEST_PRIZE
11d64aaa-e10a-4035-9276-e27ab758d7a9	f4fa7dbe-5faf-476b-b4fa-7dbe5fafd76b	contest_entry	-10000	40000	contest	f4fa7dbe-5faf-476b-b4fa-7dbe5fafd76b	Entry fee for contest phase11-e2e (ID: f4fa7dbe-5faf-476b-b4fa-7dbe5fafd76b)	2026-08-16 02:51:58.738203+00	contest_entry:f4fa7dbe-5faf-476b-b4fa-7dbe5fafd76b:f4fa7dbe-5faf-476b-b4fa-7dbe5fafd76b	CONTEST_ENTRY
7c9d3b65-7a5a-4645-a93c-dfdb8531b4f4	f4fa7dbe-5faf-476b-b4fa-7dbe5fafd76b	prize_credit	24000	64000	contest	f4fa7dbe-5faf-476b-b4fa-7dbe5fafd76b	Prize for contest f4fa7dbe-5faf-476b-b4fa-7dbe5fafd76b (rank 1)	2026-08-16 02:51:58.777617+00	finalization:f4fa7dbe-5faf-476b-b4fa-7dbe5fafd76b:f4fa7dbe-5faf-476b-b4fa-7dbe5fafd76b:1	CONTEST_PRIZE
d8195483-d935-4c91-aaeb-3dc339c23903	944aa552-a954-4a95-944a-a552a9542a95	contest_entry	-10000	40000	contest	944aa552-a954-4a95-944a-a552a9542a95	Entry fee for contest phase11-e2e (ID: 944aa552-a954-4a95-944a-a552a9542a95)	2026-08-16 02:51:59.841232+00	contest_entry:944aa552-a954-4a95-944a-a552a9542a95:944aa552-a954-4a95-944a-a552a9542a95	CONTEST_ENTRY
6b88d816-6b96-4be7-89e9-1693172dfce0	944aa552-a954-4a95-944a-a552a9542a95	prize_credit	24000	64000	contest	944aa552-a954-4a95-944a-a552a9542a95	Prize for contest 944aa552-a954-4a95-944a-a552a9542a95 (rank 1)	2026-08-16 02:51:59.879459+00	finalization:944aa552-a954-4a95-944a-a552a9542a95:944aa552-a954-4a95-944a-a552a9542a95:1	CONTEST_PRIZE
cf528b2b-bc19-47cd-a3f6-4740f0c99543	2090c8e4-f279-4cde-a090-c8e4f279bcde	contest_entry	-10000	40000	contest	2090c8e4-f279-4cde-a090-c8e4f279bcde	Entry fee for contest phase11-e2e (ID: 2090c8e4-f279-4cde-a090-c8e4f279bcde)	2026-08-16 02:52:01.916479+00	contest_entry:2090c8e4-f279-4cde-a090-c8e4f279bcde:2090c8e4-f279-4cde-a090-c8e4f279bcde	CONTEST_ENTRY
e0215fdb-7428-459d-a464-cfd166e4f031	2090c8e4-f279-4cde-a090-c8e4f279bcde	prize_credit	24000	64000	contest	2090c8e4-f279-4cde-a090-c8e4f279bcde	Prize for contest 2090c8e4-f279-4cde-a090-c8e4f279bcde (rank 1)	2026-08-16 02:52:01.955541+00	finalization:2090c8e4-f279-4cde-a090-c8e4f279bcde:2090c8e4-f279-4cde-a090-c8e4f279bcde:1	CONTEST_PRIZE
e286be38-338e-4591-8a99-2fbaf570d0d6	649329c0-8d36-409a-b7c5-b38404828556	contest_entry	-10000	90000	contest	0880d355-0836-48b8-a96b-0caa72d00fce	Entry fee for contest phase2-e2e (ID: 0880d355-0836-48b8-a96b-0caa72d00fce)	2026-08-16 02:52:15.397841+00	contest_entry:0880d355-0836-48b8-a96b-0caa72d00fce:649329c0-8d36-409a-b7c5-b38404828556	CONTEST_ENTRY
a1f845f3-d971-4c2a-84af-cce45040016e	bee05777-76fe-4703-a9cd-9d3dc737900d	contest_entry	-10000	90000	contest	0880d355-0836-48b8-a96b-0caa72d00fce	Entry fee for contest phase2-e2e (ID: 0880d355-0836-48b8-a96b-0caa72d00fce)	2026-08-16 02:52:15.409782+00	contest_entry:0880d355-0836-48b8-a96b-0caa72d00fce:bee05777-76fe-4703-a9cd-9d3dc737900d	CONTEST_ENTRY
aa6845a0-946e-4467-ab27-6f1d43431784	649329c0-8d36-409a-b7c5-b38404828556	prize_credit	1000	91000	contest	0880d355-0836-48b8-a96b-0caa72d00fce	Prize for contest 0880d355-0836-48b8-a96b-0caa72d00fce (rank 1)	2026-08-16 02:52:15.469575+00	finalization:0880d355-0836-48b8-a96b-0caa72d00fce:649329c0-8d36-409a-b7c5-b38404828556:1	CONTEST_PRIZE
c7e46374-dec9-40ad-b029-82950fbed85b	24120984-c261-40d8-a412-0984c261b0d8	contest_entry	-10000	40000	contest	24120984-c261-40d8-a412-0984c261b0d8	Entry fee for contest phase11-e2e (ID: 24120984-c261-40d8-a412-0984c261b0d8)	2026-08-16 02:52:19.390169+00	contest_entry:24120984-c261-40d8-a412-0984c261b0d8:24120984-c261-40d8-a412-0984c261b0d8	CONTEST_ENTRY
12f671d3-f5ce-4109-a534-312dbbba3222	24120984-c261-40d8-a412-0984c261b0d8	prize_credit	24000	64000	contest	24120984-c261-40d8-a412-0984c261b0d8	Prize for contest 24120984-c261-40d8-a412-0984c261b0d8 (rank 1)	2026-08-16 02:52:19.45999+00	finalization:24120984-c261-40d8-a412-0984c261b0d8:24120984-c261-40d8-a412-0984c261b0d8:1	CONTEST_PRIZE
77e0be47-aad7-4199-95a6-4d34dce76868	f48d5513-b821-4152-a295-5efeb81d84a8	contest_entry	-10000	90000	contest	128fc769-902f-4980-946f-6c5c67b714ff	Entry fee for contest phase2-e2e (ID: 128fc769-902f-4980-946f-6c5c67b714ff)	2026-08-16 02:52:34.832173+00	contest_entry:128fc769-902f-4980-946f-6c5c67b714ff:f48d5513-b821-4152-a295-5efeb81d84a8	CONTEST_ENTRY
a9f5fb9b-a46c-4a10-b83c-72c43c4caa21	d27fb682-c775-422a-9b7d-45eb2e8bc3c5	contest_entry	-10000	90000	contest	128fc769-902f-4980-946f-6c5c67b714ff	Entry fee for contest phase2-e2e (ID: 128fc769-902f-4980-946f-6c5c67b714ff)	2026-08-16 02:52:34.843393+00	contest_entry:128fc769-902f-4980-946f-6c5c67b714ff:d27fb682-c775-422a-9b7d-45eb2e8bc3c5	CONTEST_ENTRY
c3d3b137-eac1-4b76-9154-60b23796dfa8	f48d5513-b821-4152-a295-5efeb81d84a8	prize_credit	1000	91000	contest	128fc769-902f-4980-946f-6c5c67b714ff	Prize for contest 128fc769-902f-4980-946f-6c5c67b714ff (rank 1)	2026-08-16 02:52:34.9022+00	finalization:128fc769-902f-4980-946f-6c5c67b714ff:f48d5513-b821-4152-a295-5efeb81d84a8:1	CONTEST_PRIZE
df187f72-d718-4d84-925b-cdb86070db52	9990da57-187a-42b2-8bda-059add25d3e1	contest_entry	-10000	90000	contest	27612d1c-8ad2-48a2-8bdb-8f9677daa150	Entry fee for contest phase2-e2e (ID: 27612d1c-8ad2-48a2-8bdb-8f9677daa150)	2026-08-16 02:52:34.946737+00	contest_entry:27612d1c-8ad2-48a2-8bdb-8f9677daa150:9990da57-187a-42b2-8bda-059add25d3e1	CONTEST_ENTRY
f2020508-a6d2-4b89-a125-b8b241e95c8a	84c261b0-d8ec-46bb-84c2-61b0d8ec76bb	contest_entry	-10000	40000	contest	84c261b0-d8ec-46bb-84c2-61b0d8ec76bb	Entry fee for contest phase11-e2e (ID: 84c261b0-d8ec-46bb-84c2-61b0d8ec76bb)	2026-08-16 02:53:23.243761+00	contest_entry:84c261b0-d8ec-46bb-84c2-61b0d8ec76bb:84c261b0-d8ec-46bb-84c2-61b0d8ec76bb	CONTEST_ENTRY
4c85884b-f263-42e9-b864-22b1ad07688a	84c261b0-d8ec-46bb-84c2-61b0d8ec76bb	prize_credit	24000	64000	contest	84c261b0-d8ec-46bb-84c2-61b0d8ec76bb	Prize for contest 84c261b0-d8ec-46bb-84c2-61b0d8ec76bb (rank 1)	2026-08-16 02:53:23.283476+00	finalization:84c261b0-d8ec-46bb-84c2-61b0d8ec76bb:84c261b0-d8ec-46bb-84c2-61b0d8ec76bb:1	CONTEST_PRIZE
3b070616-e9a0-4970-aaa3-20b7c307980e	6791b01d-b944-4e99-b143-fb30f4f67872	contest_entry	-10000	90000	contest	36f55d6a-ca8c-42a1-be22-0187104fef3c	Entry fee for contest phase2-e2e (ID: 36f55d6a-ca8c-42a1-be22-0187104fef3c)	2026-08-16 02:53:24.965783+00	contest_entry:36f55d6a-ca8c-42a1-be22-0187104fef3c:6791b01d-b944-4e99-b143-fb30f4f67872	CONTEST_ENTRY
55c5986a-8c26-4643-84e0-fa8a4edd6938	55ff18a7-c140-4f37-b027-cfff7e1a6e85	contest_entry	-10000	90000	contest	36f55d6a-ca8c-42a1-be22-0187104fef3c	Entry fee for contest phase2-e2e (ID: 36f55d6a-ca8c-42a1-be22-0187104fef3c)	2026-08-16 02:53:24.978214+00	contest_entry:36f55d6a-ca8c-42a1-be22-0187104fef3c:55ff18a7-c140-4f37-b027-cfff7e1a6e85	CONTEST_ENTRY
56f4dd0b-8e82-47e8-bf94-30c3622a0ebf	6791b01d-b944-4e99-b143-fb30f4f67872	prize_credit	1000	91000	contest	36f55d6a-ca8c-42a1-be22-0187104fef3c	Prize for contest 36f55d6a-ca8c-42a1-be22-0187104fef3c (rank 1)	2026-08-16 02:53:25.041464+00	finalization:36f55d6a-ca8c-42a1-be22-0187104fef3c:6791b01d-b944-4e99-b143-fb30f4f67872:1	CONTEST_PRIZE
2595c7b9-2f12-4f58-82f1-99359379a15d	fb2b1558-5440-43ec-ba87-73bc2a27ceb7	contest_entry	-10000	90000	contest	aff98c1c-3a6f-4c7c-87fc-eed863265c7e	Entry fee for contest phase2-e2e (ID: aff98c1c-3a6f-4c7c-87fc-eed863265c7e)	2026-08-16 02:53:25.09517+00	contest_entry:aff98c1c-3a6f-4c7c-87fc-eed863265c7e:fb2b1558-5440-43ec-ba87-73bc2a27ceb7	CONTEST_ENTRY
39147910-cebc-43e6-8345-9a1c1a69c62c	3878c3c1-f900-4194-b8f7-ca2538111eb4	contest_entry	-10000	40000	contest	5fde67db-081b-4b1d-9f3b-10e45a520fb2	phase41lite entry 5fde67db-081b-4b1d-9f3b-10e45a520fb2	2026-08-16 02:55:26.361436+00	contest_entry:5fde67db-081b-4b1d-9f3b-10e45a520fb2:3878c3c1-f900-4194-b8f7-ca2538111eb4	\N
1048996d-4978-4523-b654-3d16b8d49d77	98207b42-c805-42cd-aafa-46f30cf1ac8c	contest_entry	-10000	40000	contest	5fde67db-081b-4b1d-9f3b-10e45a520fb2	phase41lite entry 5fde67db-081b-4b1d-9f3b-10e45a520fb2	2026-08-16 02:55:26.361436+00	contest_entry:5fde67db-081b-4b1d-9f3b-10e45a520fb2:98207b42-c805-42cd-aafa-46f30cf1ac8c	\N
b20bf599-8fdd-4676-b23f-c4e8b7d95041	ca833cd8-e3ab-4d3a-9ad5-a33a88aa3843	contest_entry	-10000	40000	contest	5fde67db-081b-4b1d-9f3b-10e45a520fb2	phase41lite entry 5fde67db-081b-4b1d-9f3b-10e45a520fb2	2026-08-16 02:55:26.361436+00	contest_entry:5fde67db-081b-4b1d-9f3b-10e45a520fb2:ca833cd8-e3ab-4d3a-9ad5-a33a88aa3843	\N
637f0548-367c-43f4-917b-cf17e7ddb308	3878c3c1-f900-4194-b8f7-ca2538111eb4	prize_credit	12000	52000	contest	5fde67db-081b-4b1d-9f3b-10e45a520fb2	phase41lite prize 5fde67db-081b-4b1d-9f3b-10e45a520fb2	2026-08-16 02:55:26.361436+00	finalization:5fde67db-081b-4b1d-9f3b-10e45a520fb2:3878c3c1-f900-4194-b8f7-ca2538111eb4:1	\N
06d6d631-0e1b-4e91-a5d6-65ecd63a67ea	98207b42-c805-42cd-aafa-46f30cf1ac8c	prize_credit	7200	47200	contest	5fde67db-081b-4b1d-9f3b-10e45a520fb2	phase41lite prize 5fde67db-081b-4b1d-9f3b-10e45a520fb2	2026-08-16 02:55:26.361436+00	finalization:5fde67db-081b-4b1d-9f3b-10e45a520fb2:98207b42-c805-42cd-aafa-46f30cf1ac8c:2	\N
7b4f6bce-506e-4b76-8010-88e37cd3601b	ca833cd8-e3ab-4d3a-9ad5-a33a88aa3843	prize_credit	4800	44800	contest	5fde67db-081b-4b1d-9f3b-10e45a520fb2	phase41lite prize 5fde67db-081b-4b1d-9f3b-10e45a520fb2	2026-08-16 02:55:26.361436+00	finalization:5fde67db-081b-4b1d-9f3b-10e45a520fb2:ca833cd8-e3ab-4d3a-9ad5-a33a88aa3843:3	\N
\.


--
-- Data for Name: wallets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.wallets (user_id, balance_cents, currency, status, created_at, updated_at) FROM stdin;
00000000-0000-0000-0000-000000000001	0	USD	active	2026-08-15 20:31:59.435518+00	2026-08-15 20:31:59.435518+00
256cf845-d483-45bd-89d1-3d0c93c13398	0	USD	active	2026-08-15 20:33:04.249648+00	2026-08-15 20:33:04.249648+00
4f8aa018-e087-40b3-a12a-15d13ce62eed	0	USD	active	2026-08-15 20:33:04.438679+00	2026-08-15 20:33:04.438679+00
54aa552a-150a-4502-94aa-552a150a0502	50000	USD	active	2026-08-16 00:33:43.295885+00	2026-08-16 00:33:43.328616+00
452e07e0-e8eb-4f0f-98f2-f8875cd88831	90000	USD	active	2026-08-16 02:27:10.383152+00	2026-08-16 02:27:10.417339+00
502894ca-e572-491c-9028-94cae572391c	50000	USD	active	2026-08-16 00:34:07.664347+00	2026-08-16 00:34:07.677794+00
f97bf032-eeaa-483a-badb-00e6d886c526	90000	USD	active	2026-08-16 01:25:58.679767+00	2026-08-16 01:25:58.706497+00
ab70e441-0b8e-4ed0-9762-13a8ac5e7c7d	91000	USD	active	2026-08-16 01:25:58.667111+00	2026-08-16 01:25:58.771601+00
c864b259-2c96-4b65-8864-b2592c96cb65	64000	USD	active	2026-08-16 00:34:27.196967+00	2026-08-16 00:34:27.263638+00
2669d7fa-c10f-4128-9395-ada433d4631e	91000	USD	active	2026-08-16 02:27:10.369635+00	2026-08-16 02:27:10.494021+00
2625aa74-47bf-4793-a803-29bb9e477aed	90000	USD	active	2026-08-16 01:25:58.799775+00	2026-08-16 01:25:58.832168+00
90c864b2-592c-464b-90c8-64b2592c964b	64000	USD	active	2026-08-16 00:34:56.091444+00	2026-08-16 00:34:56.192493+00
30b7a5b7-62b1-4416-85b0-44824b338226	100000	USD	active	2026-08-16 01:05:06.957153+00	2026-08-16 01:05:06.969825+00
e36a81e6-3639-4a93-b9c3-2f841d04211b	90000	USD	active	2026-08-16 01:25:58.964197+00	2026-08-16 01:25:58.983902+00
7d16b1c9-fa10-4721-9ab1-f9c6dfd7f7c0	90000	USD	active	2026-08-16 01:05:27.704544+00	2026-08-16 01:05:27.731891+00
73724a7a-cc59-4aeb-86b5-bc997598c1ec	90000	USD	active	2026-08-16 01:05:27.715497+00	2026-08-16 01:05:27.744762+00
540d0a22-62a4-45f1-a0ab-2f2092014abb	90000	USD	active	2026-08-16 01:29:20.62736+00	2026-08-16 01:29:20.716252+00
792c3ecb-0a51-4b66-b78f-411903e74aa3	91000	USD	active	2026-08-16 01:29:20.618003+00	2026-08-16 01:29:20.835286+00
3a6ad88d-a188-4bf0-be1d-bf2706cdbe2a	90000	USD	active	2026-08-16 01:05:44.428559+00	2026-08-16 01:05:44.453187+00
912bce1a-5da1-473c-b7cf-832f0ff39bb4	90000	USD	active	2026-08-16 01:05:44.439232+00	2026-08-16 01:05:44.46615+00
60b0d86c-369b-4da6-a0b0-d86c369b4da6	64000	USD	active	2026-08-16 01:26:01.943303+00	2026-08-16 01:26:02.0064+00
5d597832-fd0c-4be5-b1bb-ed1f03c10399	90000	USD	active	2026-08-16 01:06:51.293645+00	2026-08-16 01:06:51.320469+00
863bc837-1fa3-4374-91df-3fe92a7a8694	91000	USD	active	2026-08-16 01:06:51.283815+00	2026-08-16 01:06:51.386991+00
81741f96-07b2-4e40-801d-470e79ffac94	90000	USD	active	2026-08-16 01:06:51.417229+00	2026-08-16 01:06:51.444334+00
ffb61316-7d0b-4e05-a80f-d634f1b9391d	90000	USD	active	2026-08-16 01:29:20.866788+00	2026-08-16 01:29:20.914369+00
8ff79fc3-3043-4a7c-a959-4f2ba6e5e265	90000	USD	active	2026-08-16 01:06:51.59817+00	2026-08-16 01:06:51.61869+00
653652cd-820e-4692-a7bb-1bb90a20936a	90000	USD	active	2026-08-16 02:27:10.522941+00	2026-08-16 02:27:10.547512+00
633e7e4b-d5a2-41c7-9a17-af7e54fd4c6c	90000	USD	active	2026-08-16 01:29:21.080269+00	2026-08-16 01:29:21.118704+00
bf942846-2dc6-41a2-afb0-35efd5403110	90000	USD	active	2026-08-16 01:07:18.565593+00	2026-08-16 01:07:18.596+00
15e34f4d-da6c-4d3f-83c8-17bd2ddb4226	91000	USD	active	2026-08-16 01:07:18.554706+00	2026-08-16 01:07:18.662323+00
08048241-a050-48d4-8804-8241a050a8d4	64000	USD	active	2026-08-16 01:26:30.032427+00	2026-08-16 01:26:30.093329+00
4af61bbb-6031-4996-9c0f-f27b00b90fb8	90000	USD	active	2026-08-16 01:07:18.690487+00	2026-08-16 01:07:18.709801+00
d9da59d4-8084-49bd-ae23-cb99bb061a10	90000	USD	active	2026-08-16 01:07:18.842743+00	2026-08-16 01:07:18.862138+00
302640fe-27ce-4abe-b59a-5ec4dc69944c	90000	USD	active	2026-08-16 02:44:05.818991+00	2026-08-16 02:44:05.850045+00
1c0e8743-2190-48e4-9c0e-87432190c8e4	64000	USD	active	2026-08-16 01:07:20.331157+00	2026-08-16 01:07:20.391209+00
c3a16226-aa66-4239-9f5b-228e8eb92f5b	90000	USD	active	2026-08-16 01:26:54.036025+00	2026-08-16 01:26:54.061297+00
4f4153e9-0d17-4a1e-92ef-ce9e7958beb2	91000	USD	active	2026-08-16 01:26:54.026309+00	2026-08-16 01:26:54.126205+00
96329156-5841-49fb-81a3-2312b7525188	90000	USD	active	2026-08-16 01:08:00.118919+00	2026-08-16 01:08:00.144143+00
7dc77ed4-d996-4eeb-a881-1f208a54c12f	91000	USD	active	2026-08-16 01:08:00.108095+00	2026-08-16 01:08:00.221264+00
f6491f08-63d2-476f-873f-db5cf69c0122	91000	USD	active	2026-08-16 02:44:05.80883+00	2026-08-16 02:44:05.931941+00
43efcc9b-7d09-41c4-a72c-5235ca0b3307	90000	USD	active	2026-08-16 01:08:00.247711+00	2026-08-16 01:08:00.266634+00
eb0cfe73-a65e-405a-8e76-0717293c8143	90000	USD	active	2026-08-16 01:26:54.15374+00	2026-08-16 01:26:54.173698+00
5c74f65f-c1f0-496a-9ad8-6a33bda83d30	90000	USD	active	2026-08-16 01:08:00.410037+00	2026-08-16 01:08:00.430784+00
a452a954-aa55-4a55-a452-a954aa55aa55	64000	USD	active	2026-08-16 01:54:01.98505+00	2026-08-16 01:54:02.050486+00
1088c4e2-7138-4c4e-9088-c4e271389c4e	64000	USD	active	2026-08-16 01:26:55.560293+00	2026-08-16 01:26:55.620444+00
3c9e4fa7-d3e9-44ba-bc9e-4fa7d3e974ba	64000	USD	active	2026-08-16 02:43:00.185939+00	2026-08-16 02:43:00.257328+00
9e60eafe-d7b5-4ba8-9622-8a7e881717d2	90000	USD	active	2026-08-16 01:27:11.222946+00	2026-08-16 01:27:11.250735+00
f6e59b39-9e32-439a-879f-6b7683774265	90000	USD	active	2026-08-16 01:27:11.379997+00	2026-08-16 01:27:11.414103+00
74ba5dae-d7eb-453a-b4ba-5daed7eb753a	64000	USD	active	2026-08-16 01:54:04.76027+00	2026-08-16 01:54:04.820027+00
e0f0783c-9e4f-47d3-a0f0-783c9e4fa7d3	64000	USD	active	2026-08-16 01:27:13.511254+00	2026-08-16 01:27:13.585031+00
e8a771e3-92db-4a30-9bb0-c4b84125187f	90000	USD	active	2026-08-16 02:43:02.709242+00	2026-08-16 02:43:02.735804+00
68b45a2d-96cb-45f2-a8b4-5a2d96cbe5f2	64000	USD	active	2026-08-16 01:54:27.455327+00	2026-08-16 01:54:27.516939+00
40a0d0e8-f4fa-4dfe-80a0-d0e8f4fafdfe	64000	USD	active	2026-08-16 01:27:16.166495+00	2026-08-16 01:27:16.241836+00
c9e259ce-38b0-4b00-a3a3-9b5771d9b6de	91000	USD	active	2026-08-16 02:43:02.698585+00	2026-08-16 02:43:02.79464+00
984c2613-89c4-42f1-984c-261389c4e2f1	64000	USD	active	2026-08-16 02:44:06.938424+00	2026-08-16 02:44:06.996996+00
6cb6dbed-76bb-4d2e-acb6-dbed76bb5d2e	64000	USD	active	2026-08-16 01:29:16.019412+00	2026-08-16 01:29:16.084938+00
d8bacc11-7441-48e2-9f65-7d387dd9ea26	90000	USD	active	2026-08-16 02:43:02.82178+00	2026-08-16 02:43:02.840554+00
40a0d068-341a-4d86-80a0-d068341a0d86	64000	USD	active	2026-08-16 01:54:58.361931+00	2026-08-16 01:54:58.422328+00
3c9e4f27-1309-4402-bc9e-4f2713090402	64000	USD	active	2026-08-16 01:29:20.374373+00	2026-08-16 01:29:20.442616+00
b85c2e97-4b25-4209-b85c-2e974b251209	64000	USD	active	2026-08-16 02:44:37.128009+00	2026-08-16 02:44:37.189908+00
c8e4f279-3c1e-4f87-88e4-f2793c1e0f87	64000	USD	active	2026-08-16 02:00:06.237431+00	2026-08-16 02:00:06.301425+00
241289c4-6231-48cc-a412-89c4623198cc	64000	USD	active	2026-08-16 02:44:00.149325+00	2026-08-16 02:44:00.213236+00
a3d7c5f3-40e0-4c2f-933a-f95a98ab57f3	90000	USD	active	2026-08-16 02:48:34.36559+00	2026-08-16 02:48:34.388691+00
3098cc66-b359-4c56-b098-cc66b359ac56	64000	USD	active	2026-08-16 02:27:08.230328+00	2026-08-16 02:27:08.409682+00
b479eb08-1b65-411d-964c-028ed616a70d	90000	USD	active	2026-08-16 02:44:08.550628+00	2026-08-16 02:44:08.578885+00
218b00a6-dd31-4954-8850-989f8454cb72	91000	USD	active	2026-08-16 02:44:08.540847+00	2026-08-16 02:44:08.639058+00
d00ce5cc-0dc6-4078-935c-2a75b2349ba2	90000	USD	active	2026-08-16 02:44:01.990249+00	2026-08-16 02:44:02.015362+00
76ada4f6-10d5-4219-a405-f8d5e5b32b78	91000	USD	active	2026-08-16 02:44:01.980764+00	2026-08-16 02:44:02.081126+00
426be798-f942-40a8-8609-cd231f5ebb08	90000	USD	active	2026-08-16 02:45:59.074736+00	2026-08-16 02:45:59.09986+00
0499cba2-41b1-4fd3-b4f7-07d7e77bd094	90000	USD	active	2026-08-16 02:44:02.107825+00	2026-08-16 02:44:02.129779+00
0d4fd196-fc76-49cf-a78c-ce25c8a03022	91000	USD	active	2026-08-16 02:45:59.065355+00	2026-08-16 02:45:59.162149+00
80402090-48a4-4269-8040-209048a4d269	64000	USD	active	2026-08-16 02:44:38.390061+00	2026-08-16 02:44:38.469138+00
646173e1-c3cb-42b3-8252-1f9a45adf2d5	90000	USD	active	2026-08-16 02:44:11.065333+00	2026-08-16 02:44:11.089713+00
c66062f8-5699-49a8-a1bb-05a591ab9f22	91000	USD	active	2026-08-16 02:44:11.055506+00	2026-08-16 02:44:11.151954+00
1b5063b8-9733-4563-beef-2c787c3365a9	91000	USD	active	2026-08-16 02:48:34.35622+00	2026-08-16 02:48:34.451916+00
cdf8aaad-4a4f-4dc9-a592-79fe503633f7	90000	USD	active	2026-08-16 02:45:59.189454+00	2026-08-16 02:45:59.208292+00
582c160b-8542-4150-982c-160b8542a150	64000	USD	active	2026-08-16 02:44:36.02955+00	2026-08-16 02:44:36.090925+00
b8dc6e37-9bcd-4633-b8dc-6e379bcd6633	64000	USD	active	2026-08-16 02:44:55.576875+00	2026-08-16 02:44:55.68707+00
ddeff84e-1027-4038-8102-7ce08c9e5a94	90000	USD	active	2026-08-16 02:48:34.482315+00	2026-08-16 02:48:34.501071+00
a8542a95-4aa5-4229-a854-2a954aa55229	64000	USD	active	2026-08-16 02:48:32.611695+00	2026-08-16 02:48:32.671785+00
743a1d0e-0783-41e0-b43a-1d0e0783c1e0	64000	USD	active	2026-08-16 02:45:57.288054+00	2026-08-16 02:45:57.353092+00
bc5e2f97-cb65-4219-bc5e-2f97cb653219	64000	USD	active	2026-08-16 02:51:29.097954+00	2026-08-16 02:51:29.160541+00
071d2be9-9431-4ae5-afbb-9a195b33db15	90000	USD	active	2026-08-16 02:49:06.323616+00	2026-08-16 02:49:06.349341+00
f92e8766-b7d0-4dca-add5-9718456d5657	91000	USD	active	2026-08-16 02:49:06.313218+00	2026-08-16 02:49:06.409591+00
b45aad56-abd5-4a75-b45a-ad56abd5ea75	64000	USD	active	2026-08-16 02:49:04.718947+00	2026-08-16 02:49:04.780828+00
f41fb589-ceb8-47da-9ec4-4c1bb1f0e79d	90000	USD	active	2026-08-16 02:49:07.845918+00	2026-08-16 02:49:07.86568+00
ed2e8329-c2c7-4ed0-b3ea-ed9b6e2abfda	90000	USD	active	2026-08-16 02:49:30.835249+00	2026-08-16 02:49:30.859329+00
2cf63582-501f-451b-8595-587b82b2f40a	91000	USD	active	2026-08-16 02:49:30.825098+00	2026-08-16 02:49:30.922216+00
5d4db3df-ec04-4d3f-a4b7-758b932bdeab	90000	USD	active	2026-08-16 02:51:30.846111+00	2026-08-16 02:51:30.871257+00
28140a85-c2e1-40b8-a814-0a85c2e170b8	64000	USD	active	2026-08-16 02:49:31.934335+00	2026-08-16 02:49:31.994592+00
6c6f8218-0e00-4731-9e59-e8b8d4d61b5d	91000	USD	active	2026-08-16 02:51:30.836555+00	2026-08-16 02:51:30.938952+00
a0d068b4-5aad-46eb-a0d0-68b45aadd6eb	64000	USD	active	2026-08-16 02:51:41.086546+00	2026-08-16 02:51:41.145299+00
5a5b8479-6d2f-4e8c-8064-84afe7c56e72	90000	USD	active	2026-08-16 02:51:30.965398+00	2026-08-16 02:51:30.983982+00
0f108d2e-d94b-4cd8-b88f-504e9d68134a	90000	USD	active	2026-08-16 02:51:42.803287+00	2026-08-16 02:51:42.82851+00
3f0e5a46-bb93-4f07-a561-60662dd5541a	91000	USD	active	2026-08-16 02:51:42.792895+00	2026-08-16 02:51:42.888026+00
9ccee7f3-f97c-4edf-9cce-e7f3f97cbedf	64000	USD	active	2026-08-16 02:51:46.075347+00	2026-08-16 02:51:46.135682+00
515fbee7-3bb0-4b6d-b431-22282d623cd7	90000	USD	active	2026-08-16 02:51:42.915207+00	2026-08-16 02:51:42.935371+00
de4588c4-c14b-4f0c-9908-2e0689f907fe	90000	USD	active	2026-08-16 02:51:47.682698+00	2026-08-16 02:51:47.707742+00
a14dbc0e-1b40-4539-825b-5bad255f153d	91000	USD	active	2026-08-16 02:51:47.659314+00	2026-08-16 02:51:47.769582+00
e19c7724-0cba-4667-8e36-c469962a9f0e	91000	USD	active	2026-08-16 02:51:57.526095+00	2026-08-16 02:51:57.643473+00
5f124107-5c83-432a-80fd-8899e94f9845	90000	USD	active	2026-08-16 02:51:49.250329+00	2026-08-16 02:51:49.285035+00
92b04625-4ad6-4bea-94ef-2795bd4c5fa1	90000	USD	active	2026-08-16 02:51:57.550655+00	2026-08-16 02:51:57.577316+00
f4fa7dbe-5faf-476b-b4fa-7dbe5fafd76b	64000	USD	active	2026-08-16 02:51:58.706037+00	2026-08-16 02:51:58.777617+00
944aa552-a954-4a95-944a-a552a9542a95	64000	USD	active	2026-08-16 02:51:59.821883+00	2026-08-16 02:51:59.879459+00
2090c8e4-f279-4cde-a090-c8e4f279bcde	64000	USD	active	2026-08-16 02:52:01.896373+00	2026-08-16 02:52:01.955541+00
bee05777-76fe-4703-a9cd-9d3dc737900d	90000	USD	active	2026-08-16 02:52:15.385108+00	2026-08-16 02:52:15.409782+00
649329c0-8d36-409a-b7c5-b38404828556	91000	USD	active	2026-08-16 02:52:15.375873+00	2026-08-16 02:52:15.469575+00
24120984-c261-40d8-a412-0984c261b0d8	64000	USD	active	2026-08-16 02:52:19.34147+00	2026-08-16 02:52:19.45999+00
d27fb682-c775-422a-9b7d-45eb2e8bc3c5	90000	USD	active	2026-08-16 02:52:34.818942+00	2026-08-16 02:52:34.843393+00
f48d5513-b821-4152-a295-5efeb81d84a8	91000	USD	active	2026-08-16 02:52:34.808765+00	2026-08-16 02:52:34.9022+00
9990da57-187a-42b2-8bda-059add25d3e1	90000	USD	active	2026-08-16 02:52:34.928516+00	2026-08-16 02:52:34.946737+00
84c261b0-d8ec-46bb-84c2-61b0d8ec76bb	64000	USD	active	2026-08-16 02:53:23.223275+00	2026-08-16 02:53:23.283476+00
55ff18a7-c140-4f37-b027-cfff7e1a6e85	90000	USD	active	2026-08-16 02:53:24.953263+00	2026-08-16 02:53:24.978214+00
6791b01d-b944-4e99-b143-fb30f4f67872	91000	USD	active	2026-08-16 02:53:24.943162+00	2026-08-16 02:53:25.041464+00
fb2b1558-5440-43ec-ba87-73bc2a27ceb7	90000	USD	active	2026-08-16 02:53:25.070202+00	2026-08-16 02:53:25.09517+00
3878c3c1-f900-4194-b8f7-ca2538111eb4	52000	USD	active	2026-08-16 02:55:26.361436+00	2026-08-16 02:55:26.361436+00
98207b42-c805-42cd-aafa-46f30cf1ac8c	47200	USD	active	2026-08-16 02:55:26.361436+00	2026-08-16 02:55:26.361436+00
ca833cd8-e3ab-4d3a-9ad5-a33a88aa3843	44800	USD	active	2026-08-16 02:55:26.361436+00	2026-08-16 02:55:26.361436+00
\.


--
-- Data for Name: withdrawal_limits; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.withdrawal_limits (user_id, daily_amount_cents, monthly_amount_cents, daily_count, monthly_count, notes, updated_by, created_at, updated_at) FROM stdin;
\.


--
-- Name: permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.permissions_id_seq', 17, true);


--
-- Name: privilege_audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.privilege_audit_log_id_seq', 1, false);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.roles_id_seq', 6, true);


--
-- Name: admin_mfa_credentials admin_mfa_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_mfa_credentials
    ADD CONSTRAINT admin_mfa_credentials_pkey PRIMARY KEY (user_id);


--
-- Name: admin_mfa_recovery_codes admin_mfa_recovery_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_mfa_recovery_codes
    ADD CONSTRAINT admin_mfa_recovery_codes_pkey PRIMARY KEY (user_id, generation, code_digest);


--
-- Name: affiliate_commissions affiliate_commissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.affiliate_commissions
    ADD CONSTRAINT affiliate_commissions_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: calendar_contest_history calendar_contest_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_contest_history
    ADD CONSTRAINT calendar_contest_history_pkey PRIMARY KEY (id);


--
-- Name: calendar_entries calendar_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_entries
    ADD CONSTRAINT calendar_entries_pkey PRIMARY KEY (id);


--
-- Name: candles candles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candles
    ADD CONSTRAINT candles_pkey PRIMARY KEY (symbol, resolution, "time");


--
-- Name: chart_drawings chart_drawings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chart_drawings
    ADD CONSTRAINT chart_drawings_pkey PRIMARY KEY (user_id, contest_id, symbol);


--
-- Name: contest_duration_configs contest_duration_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contest_duration_configs
    ADD CONSTRAINT contest_duration_configs_pkey PRIMARY KEY (duration_type);


--
-- Name: contest_finalization_state contest_finalization_state_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contest_finalization_state
    ADD CONSTRAINT contest_finalization_state_pkey PRIMARY KEY (contest_id);


--
-- Name: contest_participants contest_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contest_participants
    ADD CONSTRAINT contest_participants_pkey PRIMARY KEY (contest_id, user_id);


--
-- Name: contest_prize_locks contest_prize_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contest_prize_locks
    ADD CONSTRAINT contest_prize_locks_pkey PRIMARY KEY (id);


--
-- Name: contest_reminders_sent contest_reminders_sent_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contest_reminders_sent
    ADD CONSTRAINT contest_reminders_sent_pkey PRIMARY KEY (contest_id, reminder_type);


--
-- Name: contest_settlements contest_settlements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contest_settlements
    ADD CONSTRAINT contest_settlements_pkey PRIMARY KEY (id);


--
-- Name: contest_status_history contest_status_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contest_status_history
    ADD CONSTRAINT contest_status_history_pkey PRIMARY KEY (id);


--
-- Name: contest_symbols contest_symbols_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contest_symbols
    ADD CONSTRAINT contest_symbols_pkey PRIMARY KEY (contest_id, symbol);


--
-- Name: contests contests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contests
    ADD CONSTRAINT contests_pkey PRIMARY KEY (id);


--
-- Name: email_template_versions email_template_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_template_versions
    ADD CONSTRAINT email_template_versions_pkey PRIMARY KEY (id);


--
-- Name: email_templates email_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_templates
    ADD CONSTRAINT email_templates_pkey PRIMARY KEY (slug);


--
-- Name: email_verification_tokens email_verification_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_verification_tokens
    ADD CONSTRAINT email_verification_tokens_pkey PRIMARY KEY (id);


--
-- Name: fills fills_partitioned_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fills
    ADD CONSTRAINT fills_partitioned_pkey PRIMARY KEY (shard_id, fill_id);


--
-- Name: fills_old fills_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fills_old
    ADD CONSTRAINT fills_pkey PRIMARY KEY (fill_id);


--
-- Name: fills_shard_0 fills_shard_0_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fills_shard_0
    ADD CONSTRAINT fills_shard_0_pkey PRIMARY KEY (shard_id, fill_id);


--
-- Name: fills_shard_1 fills_shard_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fills_shard_1
    ADD CONSTRAINT fills_shard_1_pkey PRIMARY KEY (shard_id, fill_id);


--
-- Name: fills_shard_2 fills_shard_2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fills_shard_2
    ADD CONSTRAINT fills_shard_2_pkey PRIMARY KEY (shard_id, fill_id);


--
-- Name: fills_shard_3 fills_shard_3_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fills_shard_3
    ADD CONSTRAINT fills_shard_3_pkey PRIMARY KEY (shard_id, fill_id);


--
-- Name: final_rankings final_rankings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.final_rankings
    ADD CONSTRAINT final_rankings_pkey PRIMARY KEY (id);


--
-- Name: kyc_audit_log kyc_audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kyc_audit_log
    ADD CONSTRAINT kyc_audit_log_pkey PRIMARY KEY (id);


--
-- Name: kyc_documents kyc_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kyc_documents
    ADD CONSTRAINT kyc_documents_pkey PRIMARY KEY (id);


--
-- Name: leaderboard_snapshots leaderboard_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leaderboard_snapshots
    ADD CONSTRAINT leaderboard_snapshots_pkey PRIMARY KEY (contest_id, taken_at);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: oauth_accounts oauth_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_accounts
    ADD CONSTRAINT oauth_accounts_pkey PRIMARY KEY (id);


--
-- Name: orders orders_partitioned_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_partitioned_pkey PRIMARY KEY (shard_id, order_id);


--
-- Name: orders_old orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders_old
    ADD CONSTRAINT orders_pkey PRIMARY KEY (order_id);


--
-- Name: orders_shard_0 orders_shard_0_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders_shard_0
    ADD CONSTRAINT orders_shard_0_pkey PRIMARY KEY (shard_id, order_id);


--
-- Name: orders_shard_1 orders_shard_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders_shard_1
    ADD CONSTRAINT orders_shard_1_pkey PRIMARY KEY (shard_id, order_id);


--
-- Name: orders_shard_2 orders_shard_2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders_shard_2
    ADD CONSTRAINT orders_shard_2_pkey PRIMARY KEY (shard_id, order_id);


--
-- Name: orders_shard_3 orders_shard_3_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders_shard_3
    ADD CONSTRAINT orders_shard_3_pkey PRIMARY KEY (shard_id, order_id);


--
-- Name: otp_logs otp_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.otp_logs
    ADD CONSTRAINT otp_logs_pkey PRIMARY KEY (id);


--
-- Name: password_reset_codes password_reset_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_codes
    ADD CONSTRAINT password_reset_codes_pkey PRIMARY KEY (id);


--
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (id);


--
-- Name: payment_intents payment_intents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_intents
    ADD CONSTRAINT payment_intents_pkey PRIMARY KEY (id);


--
-- Name: payouts payouts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payouts
    ADD CONSTRAINT payouts_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_name_key UNIQUE (name);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: positions positions_partitioned_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_partitioned_pkey PRIMARY KEY (shard_id, position_id);


--
-- Name: positions_old positions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions_old
    ADD CONSTRAINT positions_pkey PRIMARY KEY (position_id);


--
-- Name: positions_shard_0 positions_shard_0_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions_shard_0
    ADD CONSTRAINT positions_shard_0_pkey PRIMARY KEY (shard_id, position_id);


--
-- Name: positions_shard_1 positions_shard_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions_shard_1
    ADD CONSTRAINT positions_shard_1_pkey PRIMARY KEY (shard_id, position_id);


--
-- Name: positions_shard_2 positions_shard_2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions_shard_2
    ADD CONSTRAINT positions_shard_2_pkey PRIMARY KEY (shard_id, position_id);


--
-- Name: positions_shard_3 positions_shard_3_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions_shard_3
    ADD CONSTRAINT positions_shard_3_pkey PRIMARY KEY (shard_id, position_id);


--
-- Name: predefined_avatars predefined_avatars_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.predefined_avatars
    ADD CONSTRAINT predefined_avatars_pkey PRIMARY KEY (id);


--
-- Name: predefined_avatars predefined_avatars_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.predefined_avatars
    ADD CONSTRAINT predefined_avatars_slug_key UNIQUE (slug);


--
-- Name: privilege_audit_log privilege_audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.privilege_audit_log
    ADD CONSTRAINT privilege_audit_log_pkey PRIMARY KEY (id);


--
-- Name: prize_distributions prize_distributions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prize_distributions
    ADD CONSTRAINT prize_distributions_pkey PRIMARY KEY (id);


--
-- Name: provider_config provider_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provider_config
    ADD CONSTRAINT provider_config_pkey PRIMARY KEY (asset_class);


--
-- Name: referral_codes referral_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_codes
    ADD CONSTRAINT referral_codes_pkey PRIMARY KEY (code);


--
-- Name: referrals referrals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (role_id, permission_id);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: security_audit_log security_audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_audit_log
    ADD CONSTRAINT security_audit_log_pkey PRIMARY KEY (id);


--
-- Name: settlement_events settlement_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settlement_events
    ADD CONSTRAINT settlement_events_pkey PRIMARY KEY (id);


--
-- Name: shard_assignment_log shard_assignment_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shard_assignment_log
    ADD CONSTRAINT shard_assignment_log_pkey PRIMARY KEY (id);


--
-- Name: shard_config shard_config_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shard_config
    ADD CONSTRAINT shard_config_name_key UNIQUE (name);


--
-- Name: shard_config shard_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shard_config
    ADD CONSTRAINT shard_config_pkey PRIMARY KEY (shard_id);


--
-- Name: support_tickets support_tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_pkey PRIMARY KEY (id);


--
-- Name: symbols symbols_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.symbols
    ADD CONSTRAINT symbols_pkey PRIMARY KEY (symbol);


--
-- Name: template_entry_tiers template_entry_tiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.template_entry_tiers
    ADD CONSTRAINT template_entry_tiers_pkey PRIMARY KEY (id);


--
-- Name: template_prize_distributions template_prize_distributions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.template_prize_distributions
    ADD CONSTRAINT template_prize_distributions_pkey PRIMARY KEY (id);


--
-- Name: ticket_attachments ticket_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_attachments
    ADD CONSTRAINT ticket_attachments_pkey PRIMARY KEY (id);


--
-- Name: ticket_messages ticket_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_messages
    ADD CONSTRAINT ticket_messages_pkey PRIMARY KEY (id);


--
-- Name: tier_prize_distributions tier_prize_distributions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tier_prize_distributions
    ADD CONSTRAINT tier_prize_distributions_pkey PRIMARY KEY (id);


--
-- Name: tournament_schedules tournament_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournament_schedules
    ADD CONSTRAINT tournament_schedules_pkey PRIMARY KEY (id);


--
-- Name: tournament_templates tournament_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournament_templates
    ADD CONSTRAINT tournament_templates_pkey PRIMARY KEY (id);


--
-- Name: tournaments_archive tournaments_archive_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournaments_archive
    ADD CONSTRAINT tournaments_archive_pkey PRIMARY KEY (id);


--
-- Name: contest_prize_locks uq_contest_prize_locks; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contest_prize_locks
    ADD CONSTRAINT uq_contest_prize_locks UNIQUE (contest_id);


--
-- Name: contest_settlements uq_contest_settlements_contest_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contest_settlements
    ADD CONSTRAINT uq_contest_settlements_contest_id UNIQUE (contest_id);


--
-- Name: final_rankings uq_final_rankings_contest_user; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.final_rankings
    ADD CONSTRAINT uq_final_rankings_contest_user UNIQUE (contest_id, user_id);


--
-- Name: oauth_accounts uq_oauth_provider_user_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_accounts
    ADD CONSTRAINT uq_oauth_provider_user_id UNIQUE (provider, provider_user_id);


--
-- Name: prize_distributions uq_prize_distributions_contest_user; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prize_distributions
    ADD CONSTRAINT uq_prize_distributions_contest_user UNIQUE (contest_id, user_id);


--
-- Name: referral_codes uq_referral_codes_user_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_codes
    ADD CONSTRAINT uq_referral_codes_user_id UNIQUE (user_id);


--
-- Name: referrals uq_referrals_referred_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT uq_referrals_referred_id UNIQUE (referred_id);


--
-- Name: template_prize_distributions uq_template_prize_dist_rank; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.template_prize_distributions
    ADD CONSTRAINT uq_template_prize_dist_rank UNIQUE (template_id, rank);


--
-- Name: template_entry_tiers uq_template_tier_entry_fee; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.template_entry_tiers
    ADD CONSTRAINT uq_template_tier_entry_fee UNIQUE (template_id, entry_fee);


--
-- Name: tier_prize_distributions uq_tier_prize_dist_rank; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tier_prize_distributions
    ADD CONSTRAINT uq_tier_prize_dist_rank UNIQUE (tier_id, rank);


--
-- Name: tournament_templates uq_tournament_templates_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournament_templates
    ADD CONSTRAINT uq_tournament_templates_key UNIQUE (template_key);


--
-- Name: user_notification_preferences user_notification_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notification_preferences
    ADD CONSTRAINT user_notification_preferences_pkey PRIMARY KEY (user_id, category, channel);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: user_score_history user_score_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_score_history
    ADD CONSTRAINT user_score_history_pkey PRIMARY KEY (id);


--
-- Name: user_score_history user_score_history_user_id_contest_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_score_history
    ADD CONSTRAINT user_score_history_user_id_contest_id_key UNIQUE (user_id, contest_id);


--
-- Name: user_stats user_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_stats
    ADD CONSTRAINT user_stats_pkey PRIMARY KEY (user_id);


--
-- Name: user_verification user_verification_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_verification
    ADD CONSTRAINT user_verification_pkey PRIMARY KEY (user_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: verification_codes verification_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verification_codes
    ADD CONSTRAINT verification_codes_pkey PRIMARY KEY (id);


--
-- Name: wallet_ledger wallet_ledger_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallet_ledger
    ADD CONSTRAINT wallet_ledger_pkey PRIMARY KEY (id);


--
-- Name: wallets wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_pkey PRIMARY KEY (user_id);


--
-- Name: withdrawal_limits withdrawal_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdrawal_limits
    ADD CONSTRAINT withdrawal_limits_pkey PRIMARY KEY (user_id);


--
-- Name: idx_admin_mfa_recovery_codes_unused; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_admin_mfa_recovery_codes_unused ON public.admin_mfa_recovery_codes USING btree (user_id, generation) WHERE (used_at IS NULL);


--
-- Name: idx_affiliate_commissions_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_affiliate_commissions_created_at ON public.affiliate_commissions USING btree (created_at);


--
-- Name: idx_affiliate_commissions_credited_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_affiliate_commissions_credited_at ON public.affiliate_commissions USING btree (credited_at);


--
-- Name: idx_affiliate_commissions_referred_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_affiliate_commissions_referred_id ON public.affiliate_commissions USING btree (referred_id);


--
-- Name: idx_affiliate_commissions_referrer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_affiliate_commissions_referrer_id ON public.affiliate_commissions USING btree (referrer_id);


--
-- Name: idx_affiliate_commissions_referrer_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_affiliate_commissions_referrer_status ON public.affiliate_commissions USING btree (referrer_id, status);


--
-- Name: idx_affiliate_commissions_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_affiliate_commissions_source ON public.affiliate_commissions USING btree (source_type, source_id);


--
-- Name: idx_affiliate_commissions_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_affiliate_commissions_source_id ON public.affiliate_commissions USING btree (source_id);


--
-- Name: idx_affiliate_commissions_source_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_affiliate_commissions_source_type ON public.affiliate_commissions USING btree (source_type);


--
-- Name: idx_affiliate_commissions_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_affiliate_commissions_status ON public.affiliate_commissions USING btree (status);


--
-- Name: idx_audit_logs_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_action ON public.audit_logs USING btree (action);


--
-- Name: idx_audit_logs_actor_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_actor_user_id ON public.audit_logs USING btree (actor_user_id);


--
-- Name: idx_audit_logs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_created_at ON public.audit_logs USING btree (created_at);


--
-- Name: idx_audit_logs_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_target ON public.audit_logs USING btree (target_type, target_id);


--
-- Name: idx_audit_logs_target_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_target_id ON public.audit_logs USING btree (target_id);


--
-- Name: idx_audit_logs_target_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_target_type ON public.audit_logs USING btree (target_type);


--
-- Name: idx_calendar_contest_history_contest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_contest_history_contest ON public.calendar_contest_history USING btree (contest_id);


--
-- Name: idx_calendar_contest_history_entry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_contest_history_entry ON public.calendar_contest_history USING btree (calendar_entry_id, created_at DESC);


--
-- Name: idx_calendar_contests_mv_asset; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_contests_mv_asset ON public.calendar_contests_mv USING btree (asset_class, contest_date);


--
-- Name: idx_calendar_contests_mv_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_contests_mv_date ON public.calendar_contests_mv USING btree (contest_date);


--
-- Name: idx_calendar_contests_mv_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_contests_mv_type ON public.calendar_contests_mv USING btree (type, contest_date);


--
-- Name: idx_calendar_entries_enabled_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_entries_enabled_status ON public.calendar_entries USING btree (enabled, status) WHERE (enabled = true);


--
-- Name: idx_calendar_entries_next_run; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_entries_next_run ON public.calendar_entries USING btree (next_run_at) WHERE ((enabled = true) AND (status = 'active'::public.calendar_status));


--
-- Name: idx_calendar_entries_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_entries_template_id ON public.calendar_entries USING btree (template_id);


--
-- Name: idx_candles_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_candles_lookup ON public.candles USING btree (symbol, resolution) INCLUDE ("time", open, high, low, close, volume);


--
-- Name: idx_candles_symbol_resolution_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_candles_symbol_resolution_time ON public.candles USING btree (symbol, resolution, "time" DESC);


--
-- Name: idx_candles_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_candles_time ON public.candles USING btree ("time" DESC);


--
-- Name: idx_chart_drawings_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_chart_drawings_user ON public.chart_drawings USING btree (user_id);


--
-- Name: idx_contest_participants_contest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contest_participants_contest_id ON public.contest_participants USING btree (contest_id);


--
-- Name: idx_contest_participants_final_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contest_participants_final_rank ON public.contest_participants USING btree (contest_id, final_rank);


--
-- Name: idx_contest_participants_joined_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contest_participants_joined_at ON public.contest_participants USING btree (joined_at);


--
-- Name: idx_contest_participants_system; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contest_participants_system ON public.contest_participants USING btree (contest_id) WHERE (is_system = true);


--
-- Name: idx_contest_participants_total_score; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contest_participants_total_score ON public.contest_participants USING btree (contest_id, total_score DESC);


--
-- Name: idx_contest_participants_user_history; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contest_participants_user_history ON public.contest_participants USING btree (user_id, joined_at DESC);


--
-- Name: idx_contest_participants_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contest_participants_user_id ON public.contest_participants USING btree (user_id);


--
-- Name: idx_contest_reminders_sent_contest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contest_reminders_sent_contest ON public.contest_reminders_sent USING btree (contest_id);


--
-- Name: idx_contest_settlements_contest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contest_settlements_contest_id ON public.contest_settlements USING btree (contest_id);


--
-- Name: idx_contest_settlements_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contest_settlements_created_at ON public.contest_settlements USING btree (created_at);


--
-- Name: idx_contest_settlements_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contest_settlements_status ON public.contest_settlements USING btree (status);


--
-- Name: idx_contest_status_history_changed_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contest_status_history_changed_by ON public.contest_status_history USING btree (changed_by) WHERE (changed_by IS NOT NULL);


--
-- Name: idx_contest_status_history_contest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contest_status_history_contest_id ON public.contest_status_history USING btree (contest_id);


--
-- Name: idx_contest_status_history_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contest_status_history_created_at ON public.contest_status_history USING btree (created_at);


--
-- Name: idx_contest_status_history_to_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contest_status_history_to_status ON public.contest_status_history USING btree (to_status);


--
-- Name: idx_contest_symbols_contest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contest_symbols_contest_id ON public.contest_symbols USING btree (contest_id);


--
-- Name: idx_contest_symbols_enabled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contest_symbols_enabled ON public.contest_symbols USING btree (contest_id, enabled);


--
-- Name: idx_contest_symbols_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contest_symbols_symbol ON public.contest_symbols USING btree (symbol);


--
-- Name: idx_contests_asset_class; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_asset_class ON public.contests USING btree (asset_class);


--
-- Name: idx_contests_asset_class_starts_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_asset_class_starts_at ON public.contests USING btree (asset_class, starts_at) WHERE (status = ANY (ARRAY['scheduled'::public.contest_status, 'registration_open'::public.contest_status, 'running'::public.contest_status]));


--
-- Name: idx_contests_auto_generated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_auto_generated ON public.contests USING btree (auto_generated) WHERE (auto_generated = true);


--
-- Name: idx_contests_auto_generated_cleanup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_auto_generated_cleanup ON public.contests USING btree (auto_generated, is_free, status, ended_at) WHERE ((auto_generated = true) AND (is_free = true));


--
-- Name: idx_contests_auto_repeat; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_auto_repeat ON public.contests USING btree (auto_repeat) WHERE (auto_repeat = true);


--
-- Name: idx_contests_auto_start_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_auto_start_pending ON public.contests USING btree (starts_at) WHERE ((status = ANY (ARRAY['scheduled'::public.contest_status, 'registration_open'::public.contest_status])) AND (auto_start = true));


--
-- Name: idx_contests_calendar; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_calendar ON public.contests USING btree (starts_at, status, asset_class, entry_fee_cents);


--
-- Name: idx_contests_calendar_range; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_calendar_range ON public.contests USING btree (starts_at, ends_at, status) WHERE (status = ANY (ARRAY['scheduled'::public.contest_status, 'registration_open'::public.contest_status, 'running'::public.contest_status]));


--
-- Name: idx_contests_cancelled_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_cancelled_at ON public.contests USING btree (cancelled_at) WHERE (status = 'cancelled'::public.contest_status);


--
-- Name: idx_contests_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_created_at ON public.contests USING btree (created_at);


--
-- Name: idx_contests_duration_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_duration_type ON public.contests USING btree (duration_type);


--
-- Name: idx_contests_duration_type_starts_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_duration_type_starts_at ON public.contests USING btree (duration_type, starts_at) WHERE (status = ANY (ARRAY['scheduled'::public.contest_status, 'registration_open'::public.contest_status, 'running'::public.contest_status]));


--
-- Name: idx_contests_ends_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_ends_at ON public.contests USING btree (ends_at);


--
-- Name: idx_contests_free_auto_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_contests_free_auto_unique ON public.contests USING btree (asset_class, starts_at) WHERE ((is_free = true) AND (auto_generated = true));


--
-- Name: idx_contests_free_open; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_free_open ON public.contests USING btree (is_free, status, starts_at) WHERE (is_free = true);


--
-- Name: idx_contests_is_free; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_is_free ON public.contests USING btree (is_free);


--
-- Name: idx_contests_paused_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_paused_at ON public.contests USING btree (paused_at) WHERE (paused_at IS NOT NULL);


--
-- Name: idx_contests_ready_for_settlement; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_ready_for_settlement ON public.contests USING btree (ends_at) WHERE (status = 'running'::public.contest_status);


--
-- Name: idx_contests_registration_deadline; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_registration_deadline ON public.contests USING btree (registration_deadline) WHERE (status = ANY (ARRAY['scheduled'::public.contest_status, 'registration_open'::public.contest_status]));


--
-- Name: idx_contests_registration_opens_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_registration_opens_at ON public.contests USING btree (registration_opens_at) WHERE ((status = 'scheduled'::public.contest_status) AND (registration_opens_at IS NOT NULL));


--
-- Name: idx_contests_schedule_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_schedule_id ON public.contests USING btree (schedule_id) WHERE (schedule_id IS NOT NULL);


--
-- Name: idx_contests_schedule_start_dedup; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_contests_schedule_start_dedup ON public.contests USING btree (schedule_id, starts_at) WHERE (schedule_id IS NOT NULL);


--
-- Name: INDEX idx_contests_schedule_start_dedup; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON INDEX public.idx_contests_schedule_start_dedup IS 'Deduplication safety net: prevents duplicate auto-generated contests for the same schedule and start time';


--
-- Name: idx_contests_shard_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_shard_id ON public.contests USING btree (shard_id);


--
-- Name: idx_contests_starting_reminder_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_starting_reminder_pending ON public.contests USING btree (starts_at) WHERE ((starting_reminder_sent_at IS NULL) AND (status = ANY (ARRAY['scheduled'::public.contest_status, 'registration_open'::public.contest_status, 'registration_closed'::public.contest_status])));


--
-- Name: idx_contests_starts_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_starts_at ON public.contests USING btree (starts_at);


--
-- Name: idx_contests_starts_at_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_starts_at_date ON public.contests USING btree (date((starts_at AT TIME ZONE 'UTC'::text)));


--
-- Name: idx_contests_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_status ON public.contests USING btree (status);


--
-- Name: idx_contests_status_asset_class; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_status_asset_class ON public.contests USING btree (status, asset_class);


--
-- Name: idx_contests_status_duration_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_status_duration_type ON public.contests USING btree (status, duration_type);


--
-- Name: idx_contests_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_template_id ON public.contests USING btree (template_id) WHERE (template_id IS NOT NULL);


--
-- Name: idx_contests_template_start_dedup; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_contests_template_start_dedup ON public.contests USING btree (template_id, starts_at) WHERE (template_id IS NOT NULL);


--
-- Name: idx_contests_tier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contests_tier_id ON public.contests USING btree (tier_id) WHERE (tier_id IS NOT NULL);


--
-- Name: idx_contests_tier_start_dedup; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_contests_tier_start_dedup ON public.contests USING btree (tier_id, starts_at) WHERE (tier_id IS NOT NULL);


--
-- Name: idx_email_template_versions_active; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_email_template_versions_active ON public.email_template_versions USING btree (slug) WHERE (is_active = true);


--
-- Name: idx_email_template_versions_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_email_template_versions_slug ON public.email_template_versions USING btree (slug, created_at DESC);


--
-- Name: idx_email_templates_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_email_templates_updated_at ON public.email_templates USING btree (updated_at DESC);


--
-- Name: idx_email_verification_tokens_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_email_verification_tokens_expires_at ON public.email_verification_tokens USING btree (expires_at);


--
-- Name: idx_email_verification_tokens_token_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_email_verification_tokens_token_hash ON public.email_verification_tokens USING btree (token_hash);


--
-- Name: idx_email_verification_tokens_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_email_verification_tokens_user_id ON public.email_verification_tokens USING btree (user_id);


--
-- Name: idx_fills_contest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_contest_id ON public.fills_old USING btree (contest_id);


--
-- Name: idx_fills_contest_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_contest_symbol ON public.fills_old USING btree (contest_id, symbol);


--
-- Name: idx_fills_contest_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_contest_user ON public.fills_old USING btree (contest_id, user_id);


--
-- Name: idx_fills_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_created_at ON public.fills_old USING btree (created_at);


--
-- Name: idx_fills_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_order_id ON public.fills_old USING btree (order_id);


--
-- Name: idx_fills_s0_contest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s0_contest ON public.fills_shard_0 USING btree (contest_id);


--
-- Name: idx_fills_s0_contest_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s0_contest_symbol ON public.fills_shard_0 USING btree (contest_id, symbol);


--
-- Name: idx_fills_s0_contest_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s0_contest_user ON public.fills_shard_0 USING btree (contest_id, user_id);


--
-- Name: idx_fills_s0_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s0_created_at ON public.fills_shard_0 USING btree (created_at);


--
-- Name: idx_fills_s0_fill_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_fills_s0_fill_id ON public.fills_shard_0 USING btree (fill_id);


--
-- Name: idx_fills_s0_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s0_order ON public.fills_shard_0 USING btree (order_id);


--
-- Name: idx_fills_s0_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s0_symbol ON public.fills_shard_0 USING btree (symbol);


--
-- Name: idx_fills_s0_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s0_user ON public.fills_shard_0 USING btree (user_id);


--
-- Name: idx_fills_s1_contest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s1_contest ON public.fills_shard_1 USING btree (contest_id);


--
-- Name: idx_fills_s1_contest_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s1_contest_symbol ON public.fills_shard_1 USING btree (contest_id, symbol);


--
-- Name: idx_fills_s1_contest_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s1_contest_user ON public.fills_shard_1 USING btree (contest_id, user_id);


--
-- Name: idx_fills_s1_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s1_created_at ON public.fills_shard_1 USING btree (created_at);


--
-- Name: idx_fills_s1_fill_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_fills_s1_fill_id ON public.fills_shard_1 USING btree (fill_id);


--
-- Name: idx_fills_s1_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s1_order ON public.fills_shard_1 USING btree (order_id);


--
-- Name: idx_fills_s1_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s1_symbol ON public.fills_shard_1 USING btree (symbol);


--
-- Name: idx_fills_s1_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s1_user ON public.fills_shard_1 USING btree (user_id);


--
-- Name: idx_fills_s2_contest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s2_contest ON public.fills_shard_2 USING btree (contest_id);


--
-- Name: idx_fills_s2_contest_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s2_contest_symbol ON public.fills_shard_2 USING btree (contest_id, symbol);


--
-- Name: idx_fills_s2_contest_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s2_contest_user ON public.fills_shard_2 USING btree (contest_id, user_id);


--
-- Name: idx_fills_s2_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s2_created_at ON public.fills_shard_2 USING btree (created_at);


--
-- Name: idx_fills_s2_fill_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_fills_s2_fill_id ON public.fills_shard_2 USING btree (fill_id);


--
-- Name: idx_fills_s2_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s2_order ON public.fills_shard_2 USING btree (order_id);


--
-- Name: idx_fills_s2_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s2_symbol ON public.fills_shard_2 USING btree (symbol);


--
-- Name: idx_fills_s2_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s2_user ON public.fills_shard_2 USING btree (user_id);


--
-- Name: idx_fills_s3_contest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s3_contest ON public.fills_shard_3 USING btree (contest_id);


--
-- Name: idx_fills_s3_contest_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s3_contest_symbol ON public.fills_shard_3 USING btree (contest_id, symbol);


--
-- Name: idx_fills_s3_contest_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s3_contest_user ON public.fills_shard_3 USING btree (contest_id, user_id);


--
-- Name: idx_fills_s3_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s3_created_at ON public.fills_shard_3 USING btree (created_at);


--
-- Name: idx_fills_s3_fill_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_fills_s3_fill_id ON public.fills_shard_3 USING btree (fill_id);


--
-- Name: idx_fills_s3_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s3_order ON public.fills_shard_3 USING btree (order_id);


--
-- Name: idx_fills_s3_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s3_symbol ON public.fills_shard_3 USING btree (symbol);


--
-- Name: idx_fills_s3_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_s3_user ON public.fills_shard_3 USING btree (user_id);


--
-- Name: idx_fills_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_symbol ON public.fills_old USING btree (symbol);


--
-- Name: idx_fills_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fills_user_id ON public.fills_old USING btree (user_id);


--
-- Name: idx_final_rankings_contest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_final_rankings_contest_id ON public.final_rankings USING btree (contest_id);


--
-- Name: idx_final_rankings_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_final_rankings_rank ON public.final_rankings USING btree (contest_id, rank);


--
-- Name: idx_final_rankings_settlement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_final_rankings_settlement_id ON public.final_rankings USING btree (settlement_id);


--
-- Name: idx_final_rankings_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_final_rankings_user_id ON public.final_rankings USING btree (user_id);


--
-- Name: idx_finalization_state_completed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_finalization_state_completed ON public.contest_finalization_state USING btree (finalization_completed_at DESC) WHERE (finalization_completed_at IS NOT NULL);


--
-- Name: idx_finalization_state_errors; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_finalization_state_errors ON public.contest_finalization_state USING btree (last_error_at) WHERE (error_message IS NOT NULL);


--
-- Name: idx_finalization_state_incomplete; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_finalization_state_incomplete ON public.contest_finalization_state USING btree (finalization_started_at) WHERE (finalization_completed_at IS NULL);


--
-- Name: idx_kyc_audit_log_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kyc_audit_log_action ON public.kyc_audit_log USING btree (action);


--
-- Name: idx_kyc_audit_log_actor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kyc_audit_log_actor_id ON public.kyc_audit_log USING btree (actor_id);


--
-- Name: idx_kyc_audit_log_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kyc_audit_log_created_at ON public.kyc_audit_log USING btree (created_at);


--
-- Name: idx_kyc_audit_log_user_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kyc_audit_log_user_action ON public.kyc_audit_log USING btree (user_id, action);


--
-- Name: idx_kyc_audit_log_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kyc_audit_log_user_id ON public.kyc_audit_log USING btree (user_id);


--
-- Name: idx_kyc_documents_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kyc_documents_created_at ON public.kyc_documents USING btree (created_at);


--
-- Name: idx_kyc_documents_document_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kyc_documents_document_type ON public.kyc_documents USING btree (document_type);


--
-- Name: idx_kyc_documents_reviewed_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kyc_documents_reviewed_by ON public.kyc_documents USING btree (reviewed_by);


--
-- Name: idx_kyc_documents_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kyc_documents_status ON public.kyc_documents USING btree (status);


--
-- Name: idx_kyc_documents_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kyc_documents_user_id ON public.kyc_documents USING btree (user_id);


--
-- Name: idx_kyc_documents_user_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kyc_documents_user_status ON public.kyc_documents USING btree (user_id, status);


--
-- Name: idx_leaderboard_snapshots_contest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leaderboard_snapshots_contest_id ON public.leaderboard_snapshots USING btree (contest_id);


--
-- Name: idx_leaderboard_snapshots_taken_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leaderboard_snapshots_taken_at ON public.leaderboard_snapshots USING btree (taken_at);


--
-- Name: idx_notifications_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_created_at ON public.notifications USING btree (created_at);


--
-- Name: idx_notifications_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_type ON public.notifications USING btree (type);


--
-- Name: idx_notifications_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);


--
-- Name: idx_notifications_user_unread; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user_unread ON public.notifications USING btree (user_id, created_at DESC) WHERE (read_at IS NULL);


--
-- Name: idx_oauth_accounts_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_oauth_accounts_email ON public.oauth_accounts USING btree (email) WHERE (email IS NOT NULL);


--
-- Name: idx_oauth_accounts_provider_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_oauth_accounts_provider_lookup ON public.oauth_accounts USING btree (provider, provider_user_id);


--
-- Name: idx_oauth_accounts_provider_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_oauth_accounts_provider_user_id ON public.oauth_accounts USING btree (provider_user_id);


--
-- Name: idx_oauth_accounts_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_oauth_accounts_user_id ON public.oauth_accounts USING btree (user_id);


--
-- Name: idx_orders_contest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_contest_id ON public.orders_old USING btree (contest_id);


--
-- Name: idx_orders_contest_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_contest_symbol ON public.orders_old USING btree (contest_id, symbol);


--
-- Name: idx_orders_contest_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_contest_user ON public.orders_old USING btree (contest_id, user_id);


--
-- Name: idx_orders_contest_user_filled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_contest_user_filled ON ONLY public.orders USING btree (contest_id, user_id) WHERE (status = 'filled'::public.order_status);


--
-- Name: idx_orders_contest_user_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_contest_user_status ON public.orders_old USING btree (contest_id, user_id, status);


--
-- Name: idx_orders_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_created_at ON public.orders_old USING btree (created_at);


--
-- Name: idx_orders_pending_by_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_pending_by_symbol ON ONLY public.orders USING btree (contest_id, symbol, created_at) WHERE (status = 'pending'::public.order_status);


--
-- Name: idx_orders_s0_contest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s0_contest ON public.orders_shard_0 USING btree (contest_id);


--
-- Name: idx_orders_s0_contest_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s0_contest_symbol ON public.orders_shard_0 USING btree (contest_id, symbol);


--
-- Name: idx_orders_s0_contest_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s0_contest_user ON public.orders_shard_0 USING btree (contest_id, user_id);


--
-- Name: idx_orders_s0_contest_user_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s0_contest_user_status ON public.orders_shard_0 USING btree (contest_id, user_id, status);


--
-- Name: idx_orders_s0_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s0_created_at ON public.orders_shard_0 USING btree (created_at);


--
-- Name: idx_orders_s0_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_orders_s0_order_id ON public.orders_shard_0 USING btree (order_id);


--
-- Name: idx_orders_s0_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s0_status ON public.orders_shard_0 USING btree (status);


--
-- Name: idx_orders_s0_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s0_symbol ON public.orders_shard_0 USING btree (symbol);


--
-- Name: idx_orders_s0_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s0_user ON public.orders_shard_0 USING btree (user_id);


--
-- Name: idx_orders_s1_contest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s1_contest ON public.orders_shard_1 USING btree (contest_id);


--
-- Name: idx_orders_s1_contest_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s1_contest_symbol ON public.orders_shard_1 USING btree (contest_id, symbol);


--
-- Name: idx_orders_s1_contest_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s1_contest_user ON public.orders_shard_1 USING btree (contest_id, user_id);


--
-- Name: idx_orders_s1_contest_user_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s1_contest_user_status ON public.orders_shard_1 USING btree (contest_id, user_id, status);


--
-- Name: idx_orders_s1_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s1_created_at ON public.orders_shard_1 USING btree (created_at);


--
-- Name: idx_orders_s1_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_orders_s1_order_id ON public.orders_shard_1 USING btree (order_id);


--
-- Name: idx_orders_s1_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s1_status ON public.orders_shard_1 USING btree (status);


--
-- Name: idx_orders_s1_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s1_symbol ON public.orders_shard_1 USING btree (symbol);


--
-- Name: idx_orders_s1_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s1_user ON public.orders_shard_1 USING btree (user_id);


--
-- Name: idx_orders_s2_contest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s2_contest ON public.orders_shard_2 USING btree (contest_id);


--
-- Name: idx_orders_s2_contest_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s2_contest_symbol ON public.orders_shard_2 USING btree (contest_id, symbol);


--
-- Name: idx_orders_s2_contest_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s2_contest_user ON public.orders_shard_2 USING btree (contest_id, user_id);


--
-- Name: idx_orders_s2_contest_user_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s2_contest_user_status ON public.orders_shard_2 USING btree (contest_id, user_id, status);


--
-- Name: idx_orders_s2_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s2_created_at ON public.orders_shard_2 USING btree (created_at);


--
-- Name: idx_orders_s2_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_orders_s2_order_id ON public.orders_shard_2 USING btree (order_id);


--
-- Name: idx_orders_s2_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s2_status ON public.orders_shard_2 USING btree (status);


--
-- Name: idx_orders_s2_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s2_symbol ON public.orders_shard_2 USING btree (symbol);


--
-- Name: idx_orders_s2_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s2_user ON public.orders_shard_2 USING btree (user_id);


--
-- Name: idx_orders_s3_contest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s3_contest ON public.orders_shard_3 USING btree (contest_id);


--
-- Name: idx_orders_s3_contest_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s3_contest_symbol ON public.orders_shard_3 USING btree (contest_id, symbol);


--
-- Name: idx_orders_s3_contest_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s3_contest_user ON public.orders_shard_3 USING btree (contest_id, user_id);


--
-- Name: idx_orders_s3_contest_user_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s3_contest_user_status ON public.orders_shard_3 USING btree (contest_id, user_id, status);


--
-- Name: idx_orders_s3_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s3_created_at ON public.orders_shard_3 USING btree (created_at);


--
-- Name: idx_orders_s3_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_orders_s3_order_id ON public.orders_shard_3 USING btree (order_id);


--
-- Name: idx_orders_s3_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s3_status ON public.orders_shard_3 USING btree (status);


--
-- Name: idx_orders_s3_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s3_symbol ON public.orders_shard_3 USING btree (symbol);


--
-- Name: idx_orders_s3_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_s3_user ON public.orders_shard_3 USING btree (user_id);


--
-- Name: idx_orders_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_status ON public.orders_old USING btree (status);


--
-- Name: idx_orders_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_symbol ON public.orders_old USING btree (symbol);


--
-- Name: idx_orders_user_contest_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_user_contest_created ON ONLY public.orders USING btree (user_id, contest_id, created_at DESC);


--
-- Name: idx_orders_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orders_user_id ON public.orders_old USING btree (user_id);


--
-- Name: idx_otp_logs_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_otp_logs_phone ON public.otp_logs USING btree (phone);


--
-- Name: idx_otp_logs_sent_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_otp_logs_sent_at ON public.otp_logs USING btree (sent_at);


--
-- Name: idx_password_reset_codes_user_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_password_reset_codes_user_created ON public.password_reset_codes USING btree (user_id, created_at DESC);


--
-- Name: idx_password_reset_codes_user_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_password_reset_codes_user_expires ON public.password_reset_codes USING btree (user_id, expires_at) WHERE (used_at IS NULL);


--
-- Name: idx_password_reset_tokens_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_password_reset_tokens_expires_at ON public.password_reset_tokens USING btree (expires_at);


--
-- Name: idx_password_reset_tokens_token_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_password_reset_tokens_token_hash ON public.password_reset_tokens USING btree (token_hash);


--
-- Name: idx_password_reset_tokens_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_password_reset_tokens_user_id ON public.password_reset_tokens USING btree (user_id);


--
-- Name: idx_payment_intents_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_intents_created_at ON public.payment_intents USING btree (created_at);


--
-- Name: idx_payment_intents_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_intents_provider ON public.payment_intents USING btree (provider);


--
-- Name: idx_payment_intents_provider_payment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_payment_intents_provider_payment_id ON public.payment_intents USING btree (provider, provider_payment_id) WHERE (provider_payment_id IS NOT NULL);


--
-- Name: idx_payment_intents_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_intents_status ON public.payment_intents USING btree (status);


--
-- Name: idx_payment_intents_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_intents_user_id ON public.payment_intents USING btree (user_id);


--
-- Name: idx_payment_intents_user_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_intents_user_status ON public.payment_intents USING btree (user_id, status);


--
-- Name: idx_payouts_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payouts_created_at ON public.payouts USING btree (created_at);


--
-- Name: idx_payouts_pending_review; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payouts_pending_review ON public.payouts USING btree (status, created_at DESC) WHERE (status = 'pending'::public.payout_status);


--
-- Name: idx_payouts_reviewed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payouts_reviewed_at ON public.payouts USING btree (reviewed_at);


--
-- Name: idx_payouts_reviewed_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payouts_reviewed_by ON public.payouts USING btree (reviewed_by);


--
-- Name: idx_payouts_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payouts_status ON public.payouts USING btree (status);


--
-- Name: idx_payouts_transaction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payouts_transaction_id ON public.payouts USING btree (transaction_id) WHERE (transaction_id IS NOT NULL);


--
-- Name: idx_payouts_user_created_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payouts_user_created_status ON public.payouts USING btree (user_id, created_at DESC, status);


--
-- Name: idx_payouts_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payouts_user_id ON public.payouts USING btree (user_id);


--
-- Name: idx_payouts_user_idempotency_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_payouts_user_idempotency_key ON public.payouts USING btree (user_id, idempotency_key) WHERE ((idempotency_key IS NOT NULL) AND ((idempotency_key)::text <> ''::text));


--
-- Name: idx_payouts_user_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payouts_user_status ON public.payouts USING btree (user_id, status);


--
-- Name: idx_permissions_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_permissions_name ON public.permissions USING btree (name);


--
-- Name: idx_positions_closed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_closed_at ON public.positions_old USING btree (closed_at);


--
-- Name: idx_positions_contest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_contest_id ON public.positions_old USING btree (contest_id);


--
-- Name: idx_positions_contest_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_contest_user ON public.positions_old USING btree (contest_id, user_id);


--
-- Name: idx_positions_contest_user_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_contest_user_symbol ON public.positions_old USING btree (contest_id, user_id, symbol);


--
-- Name: idx_positions_leaderboard; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_leaderboard ON ONLY public.positions USING btree (contest_id, realized_score DESC) WHERE (closed_at IS NULL);


--
-- Name: idx_positions_open; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_open ON public.positions_old USING btree (contest_id, user_id) WHERE (closed_at IS NULL);


--
-- Name: idx_positions_opened_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_opened_at ON public.positions_old USING btree (opened_at);


--
-- Name: idx_positions_s0_closed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s0_closed_at ON public.positions_shard_0 USING btree (closed_at);


--
-- Name: idx_positions_s0_contest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s0_contest ON public.positions_shard_0 USING btree (contest_id);


--
-- Name: idx_positions_s0_contest_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s0_contest_user ON public.positions_shard_0 USING btree (contest_id, user_id);


--
-- Name: idx_positions_s0_contest_user_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s0_contest_user_symbol ON public.positions_shard_0 USING btree (contest_id, user_id, symbol);


--
-- Name: idx_positions_s0_open; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s0_open ON public.positions_shard_0 USING btree (contest_id, user_id) WHERE (closed_at IS NULL);


--
-- Name: idx_positions_s0_opened_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s0_opened_at ON public.positions_shard_0 USING btree (opened_at);


--
-- Name: idx_positions_s0_position_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_positions_s0_position_id ON public.positions_shard_0 USING btree (position_id);


--
-- Name: idx_positions_s0_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s0_symbol ON public.positions_shard_0 USING btree (symbol);


--
-- Name: idx_positions_s0_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s0_user ON public.positions_shard_0 USING btree (user_id);


--
-- Name: idx_positions_s1_closed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s1_closed_at ON public.positions_shard_1 USING btree (closed_at);


--
-- Name: idx_positions_s1_contest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s1_contest ON public.positions_shard_1 USING btree (contest_id);


--
-- Name: idx_positions_s1_contest_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s1_contest_user ON public.positions_shard_1 USING btree (contest_id, user_id);


--
-- Name: idx_positions_s1_contest_user_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s1_contest_user_symbol ON public.positions_shard_1 USING btree (contest_id, user_id, symbol);


--
-- Name: idx_positions_s1_open; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s1_open ON public.positions_shard_1 USING btree (contest_id, user_id) WHERE (closed_at IS NULL);


--
-- Name: idx_positions_s1_opened_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s1_opened_at ON public.positions_shard_1 USING btree (opened_at);


--
-- Name: idx_positions_s1_position_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_positions_s1_position_id ON public.positions_shard_1 USING btree (position_id);


--
-- Name: idx_positions_s1_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s1_symbol ON public.positions_shard_1 USING btree (symbol);


--
-- Name: idx_positions_s1_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s1_user ON public.positions_shard_1 USING btree (user_id);


--
-- Name: idx_positions_s2_closed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s2_closed_at ON public.positions_shard_2 USING btree (closed_at);


--
-- Name: idx_positions_s2_contest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s2_contest ON public.positions_shard_2 USING btree (contest_id);


--
-- Name: idx_positions_s2_contest_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s2_contest_user ON public.positions_shard_2 USING btree (contest_id, user_id);


--
-- Name: idx_positions_s2_contest_user_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s2_contest_user_symbol ON public.positions_shard_2 USING btree (contest_id, user_id, symbol);


--
-- Name: idx_positions_s2_open; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s2_open ON public.positions_shard_2 USING btree (contest_id, user_id) WHERE (closed_at IS NULL);


--
-- Name: idx_positions_s2_opened_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s2_opened_at ON public.positions_shard_2 USING btree (opened_at);


--
-- Name: idx_positions_s2_position_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_positions_s2_position_id ON public.positions_shard_2 USING btree (position_id);


--
-- Name: idx_positions_s2_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s2_symbol ON public.positions_shard_2 USING btree (symbol);


--
-- Name: idx_positions_s2_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s2_user ON public.positions_shard_2 USING btree (user_id);


--
-- Name: idx_positions_s3_closed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s3_closed_at ON public.positions_shard_3 USING btree (closed_at);


--
-- Name: idx_positions_s3_contest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s3_contest ON public.positions_shard_3 USING btree (contest_id);


--
-- Name: idx_positions_s3_contest_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s3_contest_user ON public.positions_shard_3 USING btree (contest_id, user_id);


--
-- Name: idx_positions_s3_contest_user_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s3_contest_user_symbol ON public.positions_shard_3 USING btree (contest_id, user_id, symbol);


--
-- Name: idx_positions_s3_open; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s3_open ON public.positions_shard_3 USING btree (contest_id, user_id) WHERE (closed_at IS NULL);


--
-- Name: idx_positions_s3_opened_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s3_opened_at ON public.positions_shard_3 USING btree (opened_at);


--
-- Name: idx_positions_s3_position_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_positions_s3_position_id ON public.positions_shard_3 USING btree (position_id);


--
-- Name: idx_positions_s3_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s3_symbol ON public.positions_shard_3 USING btree (symbol);


--
-- Name: idx_positions_s3_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_s3_user ON public.positions_shard_3 USING btree (user_id);


--
-- Name: idx_positions_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_symbol ON public.positions_old USING btree (symbol);


--
-- Name: idx_positions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_user_id ON public.positions_old USING btree (user_id);


--
-- Name: idx_predefined_avatars_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_predefined_avatars_active ON public.predefined_avatars USING btree (is_active, sort_order);


--
-- Name: idx_prize_distributions_contest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prize_distributions_contest_id ON public.prize_distributions USING btree (contest_id);


--
-- Name: idx_prize_distributions_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prize_distributions_rank ON public.prize_distributions USING btree (contest_id, rank);


--
-- Name: idx_prize_distributions_settlement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prize_distributions_settlement_id ON public.prize_distributions USING btree (settlement_id);


--
-- Name: idx_prize_distributions_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prize_distributions_status ON public.prize_distributions USING btree (status);


--
-- Name: idx_prize_distributions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prize_distributions_user_id ON public.prize_distributions USING btree (user_id);


--
-- Name: idx_referral_codes_activation_requested_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_referral_codes_activation_requested_at ON public.referral_codes USING btree (activation_requested_at);


--
-- Name: idx_referral_codes_activation_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_referral_codes_activation_status ON public.referral_codes USING btree (activation_status);


--
-- Name: idx_referral_codes_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_referral_codes_created_at ON public.referral_codes USING btree (created_at);


--
-- Name: idx_referral_codes_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_referral_codes_is_active ON public.referral_codes USING btree (is_active);


--
-- Name: idx_referral_codes_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_referral_codes_user_id ON public.referral_codes USING btree (user_id);


--
-- Name: idx_referrals_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_referrals_code ON public.referrals USING btree (code);


--
-- Name: idx_referrals_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_referrals_created_at ON public.referrals USING btree (created_at);


--
-- Name: idx_referrals_qualified_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_referrals_qualified_at ON public.referrals USING btree (qualified_at);


--
-- Name: idx_referrals_referred_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_referrals_referred_id ON public.referrals USING btree (referred_id);


--
-- Name: idx_referrals_referrer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_referrals_referrer_id ON public.referrals USING btree (referrer_id);


--
-- Name: idx_referrals_referrer_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_referrals_referrer_status ON public.referrals USING btree (referrer_id, status);


--
-- Name: idx_referrals_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_referrals_status ON public.referrals USING btree (status);


--
-- Name: idx_role_permissions_permission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_role_permissions_permission_id ON public.role_permissions USING btree (permission_id);


--
-- Name: idx_role_permissions_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_role_permissions_role_id ON public.role_permissions USING btree (role_id);


--
-- Name: idx_security_audit_log_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_security_audit_log_created_at ON public.security_audit_log USING btree (created_at);


--
-- Name: idx_security_audit_log_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_security_audit_log_event_type ON public.security_audit_log USING btree (event_type);


--
-- Name: idx_security_audit_log_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_security_audit_log_user_id ON public.security_audit_log USING btree (user_id);


--
-- Name: idx_settlement_events_contest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settlement_events_contest_id ON public.settlement_events USING btree (contest_id);


--
-- Name: idx_settlement_events_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settlement_events_created_at ON public.settlement_events USING btree (created_at);


--
-- Name: idx_settlement_events_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settlement_events_event_type ON public.settlement_events USING btree (event_type);


--
-- Name: idx_settlement_events_settlement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settlement_events_settlement_id ON public.settlement_events USING btree (settlement_id);


--
-- Name: idx_shard_assignment_log_assigned_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shard_assignment_log_assigned_by ON public.shard_assignment_log USING btree (assigned_by);


--
-- Name: idx_shard_assignment_log_contest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shard_assignment_log_contest_id ON public.shard_assignment_log USING btree (contest_id);


--
-- Name: idx_shard_assignment_log_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shard_assignment_log_created_at ON public.shard_assignment_log USING btree (created_at);


--
-- Name: idx_shard_assignment_log_new_shard_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shard_assignment_log_new_shard_id ON public.shard_assignment_log USING btree (new_shard_id);


--
-- Name: idx_shard_assignment_log_old_shard_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shard_assignment_log_old_shard_id ON public.shard_assignment_log USING btree (old_shard_id);


--
-- Name: idx_shard_config_kafka_partition; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shard_config_kafka_partition ON public.shard_config USING btree (kafka_partition);


--
-- Name: idx_shard_config_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shard_config_status ON public.shard_config USING btree (status);


--
-- Name: idx_support_tickets_assigned_admin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_support_tickets_assigned_admin ON public.support_tickets USING btree (assigned_admin_id) WHERE (assigned_admin_id IS NOT NULL);


--
-- Name: idx_support_tickets_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_support_tickets_created_at ON public.support_tickets USING btree (created_at DESC);


--
-- Name: idx_support_tickets_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_support_tickets_status ON public.support_tickets USING btree (status);


--
-- Name: idx_support_tickets_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_support_tickets_updated_at ON public.support_tickets USING btree (updated_at DESC);


--
-- Name: idx_support_tickets_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_support_tickets_user_id ON public.support_tickets USING btree (user_id);


--
-- Name: idx_symbols_asset_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_symbols_asset_type ON public.symbols USING btree (asset_type);


--
-- Name: idx_symbols_binance; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_symbols_binance ON public.symbols USING btree (provider_symbol_binance) WHERE (provider_symbol_binance IS NOT NULL);


--
-- Name: idx_symbols_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_symbols_created_at ON public.symbols USING btree (created_at DESC);


--
-- Name: idx_symbols_finnhub; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_symbols_finnhub ON public.symbols USING btree (provider_symbol_finnhub) WHERE (provider_symbol_finnhub IS NOT NULL);


--
-- Name: idx_symbols_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_symbols_is_active ON public.symbols USING btree (is_active);


--
-- Name: idx_symbols_nobitex; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_symbols_nobitex ON public.symbols USING btree (provider_symbol_nobitex) WHERE (provider_symbol_nobitex IS NOT NULL);


--
-- Name: idx_template_entry_tiers_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_template_entry_tiers_active ON public.template_entry_tiers USING btree (template_id, is_active) WHERE (is_active = true);


--
-- Name: idx_template_entry_tiers_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_template_entry_tiers_template_id ON public.template_entry_tiers USING btree (template_id);


--
-- Name: idx_template_prize_dist_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_template_prize_dist_template_id ON public.template_prize_distributions USING btree (template_id);


--
-- Name: idx_ticket_attachments_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ticket_attachments_message_id ON public.ticket_attachments USING btree (message_id);


--
-- Name: idx_ticket_messages_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ticket_messages_created_at ON public.ticket_messages USING btree (ticket_id, created_at);


--
-- Name: idx_ticket_messages_ticket_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ticket_messages_ticket_id ON public.ticket_messages USING btree (ticket_id);


--
-- Name: idx_tier_prize_dist_tier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tier_prize_dist_tier_id ON public.tier_prize_distributions USING btree (tier_id);


--
-- Name: idx_tournament_schedules_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tournament_schedules_is_active ON public.tournament_schedules USING btree (is_active) WHERE (is_active = true);


--
-- Name: idx_tournament_schedules_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tournament_schedules_template_id ON public.tournament_schedules USING btree (template_id);


--
-- Name: idx_tournament_templates_auto_create; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tournament_templates_auto_create ON public.tournament_templates USING btree (auto_create) WHERE (auto_create = true);


--
-- Name: idx_tournament_templates_auto_generate; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tournament_templates_auto_generate ON public.tournament_templates USING btree (next_occurrence_at, auto_create) WHERE (auto_create = true);


--
-- Name: idx_tournament_templates_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tournament_templates_created_at ON public.tournament_templates USING btree (created_at);


--
-- Name: idx_tournament_templates_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tournament_templates_is_active ON public.tournament_templates USING btree (is_active) WHERE (is_active = true);


--
-- Name: idx_tournament_templates_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tournament_templates_key ON public.tournament_templates USING btree (template_key) WHERE (template_key IS NOT NULL);


--
-- Name: idx_tournament_templates_market_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tournament_templates_market_type ON public.tournament_templates USING btree (market_type);


--
-- Name: idx_tournament_templates_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tournament_templates_name ON public.tournament_templates USING btree (name);


--
-- Name: idx_tournament_templates_recurrence; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tournament_templates_recurrence ON public.tournament_templates USING btree (next_occurrence_at) WHERE (recurrence_rule IS NOT NULL);


--
-- Name: idx_tournament_templates_template_duration_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tournament_templates_template_duration_type ON public.tournament_templates USING btree (template_duration_type);


--
-- Name: idx_tournaments_archive_archived_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tournaments_archive_archived_at ON public.tournaments_archive USING btree (archived_at);


--
-- Name: idx_tournaments_archive_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tournaments_archive_status ON public.tournaments_archive USING btree (status);


--
-- Name: idx_user_notif_prefs_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_notif_prefs_user ON public.user_notification_preferences USING btree (user_id);


--
-- Name: idx_user_roles_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_roles_role_id ON public.user_roles USING btree (role_id);


--
-- Name: idx_user_roles_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_roles_user_id ON public.user_roles USING btree (user_id);


--
-- Name: idx_user_score_history_contest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_score_history_contest_id ON public.user_score_history USING btree (contest_id);


--
-- Name: idx_user_score_history_contribution; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_score_history_contribution ON public.user_score_history USING btree (user_id, score_contribution DESC);


--
-- Name: idx_user_score_history_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_score_history_created_at ON public.user_score_history USING btree (created_at);


--
-- Name: idx_user_score_history_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_score_history_rank ON public.user_score_history USING btree (rank);


--
-- Name: idx_user_score_history_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_score_history_user_id ON public.user_score_history USING btree (user_id);


--
-- Name: idx_user_stats_total_score; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_stats_total_score ON public.user_stats USING btree (total_score DESC);


--
-- Name: idx_user_stats_tragge_point; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_stats_tragge_point ON public.user_stats USING btree (tragge_point DESC);


--
-- Name: idx_user_stats_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_stats_updated_at ON public.user_stats USING btree (updated_at);


--
-- Name: idx_user_stats_win_rate; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_stats_win_rate ON public.user_stats USING btree (win_rate DESC);


--
-- Name: idx_user_verification_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_verification_created_at ON public.user_verification USING btree (created_at);


--
-- Name: idx_user_verification_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_verification_expires_at ON public.user_verification USING btree (expires_at);


--
-- Name: idx_user_verification_national_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_verification_national_code ON public.user_verification USING btree (national_code) WHERE (national_code IS NOT NULL);


--
-- Name: idx_user_verification_national_code_manual; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_verification_national_code_manual ON public.user_verification USING btree (national_code_manual) WHERE (national_code_manual IS NOT NULL);


--
-- Name: idx_user_verification_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_verification_provider ON public.user_verification USING btree (provider);


--
-- Name: idx_user_verification_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_verification_status ON public.user_verification USING btree (status);


--
-- Name: idx_user_verification_verified_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_verification_verified_by ON public.user_verification USING btree (verified_by);


--
-- Name: idx_users_ban_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_ban_expires_at ON public.users USING btree (ban_expires_at) WHERE ((status = 'suspended'::public.user_status) AND (ban_expires_at IS NOT NULL));


--
-- Name: idx_users_country; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_country ON public.users USING btree (country) WHERE (country IS NOT NULL);


--
-- Name: idx_users_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_created_at ON public.users USING btree (created_at);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_email_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_email_status ON public.users USING btree (email, status);


--
-- Name: idx_users_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_users_phone ON public.users USING btree (phone) WHERE (phone IS NOT NULL);


--
-- Name: idx_users_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_status ON public.users USING btree (status);


--
-- Name: idx_users_system_account; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_system_account ON public.users USING btree (id) WHERE (is_system_account = true);


--
-- Name: idx_users_telegram_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_users_telegram_id ON public.users USING btree (telegram_id) WHERE (telegram_id IS NOT NULL);


--
-- Name: idx_users_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_users_username ON public.users USING btree (username) WHERE (username IS NOT NULL);


--
-- Name: idx_verification_codes_cleanup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_verification_codes_cleanup ON public.verification_codes USING btree (expires_at) WHERE (verified_at IS NULL);


--
-- Name: idx_verification_codes_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_verification_codes_expires ON public.verification_codes USING btree (expires_at);


--
-- Name: idx_verification_codes_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_verification_codes_lookup ON public.verification_codes USING btree (user_id, method, verified_at) WHERE (verified_at IS NULL);


--
-- Name: idx_verification_codes_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_verification_codes_user_id ON public.verification_codes USING btree (user_id);


--
-- Name: idx_wallet_ledger_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wallet_ledger_created_at ON public.wallet_ledger USING btree (created_at);


--
-- Name: idx_wallet_ledger_idempotency_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_wallet_ledger_idempotency_key ON public.wallet_ledger USING btree (idempotency_key) WHERE (idempotency_key IS NOT NULL);


--
-- Name: idx_wallet_ledger_idempotency_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wallet_ledger_idempotency_lookup ON public.wallet_ledger USING btree (idempotency_key) WHERE (idempotency_key IS NOT NULL);


--
-- Name: idx_wallet_ledger_reason_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wallet_ledger_reason_code ON public.wallet_ledger USING btree (reason_code) WHERE (reason_code IS NOT NULL);


--
-- Name: idx_wallet_ledger_ref; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wallet_ledger_ref ON public.wallet_ledger USING btree (ref_type, ref_id);


--
-- Name: idx_wallet_ledger_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wallet_ledger_type ON public.wallet_ledger USING btree (type);


--
-- Name: idx_wallet_ledger_user_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wallet_ledger_user_created ON public.wallet_ledger USING btree (user_id, created_at DESC);


--
-- Name: idx_wallet_ledger_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wallet_ledger_user_id ON public.wallet_ledger USING btree (user_id);


--
-- Name: idx_wallet_ledger_user_reason_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wallet_ledger_user_reason_code ON public.wallet_ledger USING btree (user_id, reason_code) WHERE (reason_code IS NOT NULL);


--
-- Name: idx_wallet_ledger_user_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wallet_ledger_user_type ON public.wallet_ledger USING btree (user_id, type);


--
-- Name: idx_wallets_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wallets_created_at ON public.wallets USING btree (created_at);


--
-- Name: idx_wallets_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wallets_status ON public.wallets USING btree (status);


--
-- Name: orders_shard_0_contest_id_symbol_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orders_shard_0_contest_id_symbol_created_at_idx ON public.orders_shard_0 USING btree (contest_id, symbol, created_at) WHERE (status = 'pending'::public.order_status);


--
-- Name: orders_shard_0_contest_id_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orders_shard_0_contest_id_user_id_idx ON public.orders_shard_0 USING btree (contest_id, user_id) WHERE (status = 'filled'::public.order_status);


--
-- Name: orders_shard_0_user_id_contest_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orders_shard_0_user_id_contest_id_created_at_idx ON public.orders_shard_0 USING btree (user_id, contest_id, created_at DESC);


--
-- Name: orders_shard_1_contest_id_symbol_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orders_shard_1_contest_id_symbol_created_at_idx ON public.orders_shard_1 USING btree (contest_id, symbol, created_at) WHERE (status = 'pending'::public.order_status);


--
-- Name: orders_shard_1_contest_id_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orders_shard_1_contest_id_user_id_idx ON public.orders_shard_1 USING btree (contest_id, user_id) WHERE (status = 'filled'::public.order_status);


--
-- Name: orders_shard_1_user_id_contest_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orders_shard_1_user_id_contest_id_created_at_idx ON public.orders_shard_1 USING btree (user_id, contest_id, created_at DESC);


--
-- Name: orders_shard_2_contest_id_symbol_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orders_shard_2_contest_id_symbol_created_at_idx ON public.orders_shard_2 USING btree (contest_id, symbol, created_at) WHERE (status = 'pending'::public.order_status);


--
-- Name: orders_shard_2_contest_id_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orders_shard_2_contest_id_user_id_idx ON public.orders_shard_2 USING btree (contest_id, user_id) WHERE (status = 'filled'::public.order_status);


--
-- Name: orders_shard_2_user_id_contest_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orders_shard_2_user_id_contest_id_created_at_idx ON public.orders_shard_2 USING btree (user_id, contest_id, created_at DESC);


--
-- Name: orders_shard_3_contest_id_symbol_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orders_shard_3_contest_id_symbol_created_at_idx ON public.orders_shard_3 USING btree (contest_id, symbol, created_at) WHERE (status = 'pending'::public.order_status);


--
-- Name: orders_shard_3_contest_id_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orders_shard_3_contest_id_user_id_idx ON public.orders_shard_3 USING btree (contest_id, user_id) WHERE (status = 'filled'::public.order_status);


--
-- Name: orders_shard_3_user_id_contest_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orders_shard_3_user_id_contest_id_created_at_idx ON public.orders_shard_3 USING btree (user_id, contest_id, created_at DESC);


--
-- Name: positions_shard_0_contest_id_realized_score_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX positions_shard_0_contest_id_realized_score_idx ON public.positions_shard_0 USING btree (contest_id, realized_score DESC) WHERE (closed_at IS NULL);


--
-- Name: positions_shard_1_contest_id_realized_score_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX positions_shard_1_contest_id_realized_score_idx ON public.positions_shard_1 USING btree (contest_id, realized_score DESC) WHERE (closed_at IS NULL);


--
-- Name: positions_shard_2_contest_id_realized_score_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX positions_shard_2_contest_id_realized_score_idx ON public.positions_shard_2 USING btree (contest_id, realized_score DESC) WHERE (closed_at IS NULL);


--
-- Name: positions_shard_3_contest_id_realized_score_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX positions_shard_3_contest_id_realized_score_idx ON public.positions_shard_3 USING btree (contest_id, realized_score DESC) WHERE (closed_at IS NULL);


--
-- Name: uq_contests_schedule_idempotency_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_contests_schedule_idempotency_key ON public.contests USING btree (schedule_idempotency_key) WHERE ((schedule_idempotency_key IS NOT NULL) AND (schedule_idempotency_key <> ''::text));


--
-- Name: fills_shard_0_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.fills_partitioned_pkey ATTACH PARTITION public.fills_shard_0_pkey;


--
-- Name: fills_shard_1_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.fills_partitioned_pkey ATTACH PARTITION public.fills_shard_1_pkey;


--
-- Name: fills_shard_2_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.fills_partitioned_pkey ATTACH PARTITION public.fills_shard_2_pkey;


--
-- Name: fills_shard_3_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.fills_partitioned_pkey ATTACH PARTITION public.fills_shard_3_pkey;


--
-- Name: orders_shard_0_contest_id_symbol_created_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_orders_pending_by_symbol ATTACH PARTITION public.orders_shard_0_contest_id_symbol_created_at_idx;


--
-- Name: orders_shard_0_contest_id_user_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_orders_contest_user_filled ATTACH PARTITION public.orders_shard_0_contest_id_user_id_idx;


--
-- Name: orders_shard_0_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.orders_partitioned_pkey ATTACH PARTITION public.orders_shard_0_pkey;


--
-- Name: orders_shard_0_user_id_contest_id_created_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_orders_user_contest_created ATTACH PARTITION public.orders_shard_0_user_id_contest_id_created_at_idx;


--
-- Name: orders_shard_1_contest_id_symbol_created_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_orders_pending_by_symbol ATTACH PARTITION public.orders_shard_1_contest_id_symbol_created_at_idx;


--
-- Name: orders_shard_1_contest_id_user_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_orders_contest_user_filled ATTACH PARTITION public.orders_shard_1_contest_id_user_id_idx;


--
-- Name: orders_shard_1_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.orders_partitioned_pkey ATTACH PARTITION public.orders_shard_1_pkey;


--
-- Name: orders_shard_1_user_id_contest_id_created_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_orders_user_contest_created ATTACH PARTITION public.orders_shard_1_user_id_contest_id_created_at_idx;


--
-- Name: orders_shard_2_contest_id_symbol_created_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_orders_pending_by_symbol ATTACH PARTITION public.orders_shard_2_contest_id_symbol_created_at_idx;


--
-- Name: orders_shard_2_contest_id_user_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_orders_contest_user_filled ATTACH PARTITION public.orders_shard_2_contest_id_user_id_idx;


--
-- Name: orders_shard_2_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.orders_partitioned_pkey ATTACH PARTITION public.orders_shard_2_pkey;


--
-- Name: orders_shard_2_user_id_contest_id_created_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_orders_user_contest_created ATTACH PARTITION public.orders_shard_2_user_id_contest_id_created_at_idx;


--
-- Name: orders_shard_3_contest_id_symbol_created_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_orders_pending_by_symbol ATTACH PARTITION public.orders_shard_3_contest_id_symbol_created_at_idx;


--
-- Name: orders_shard_3_contest_id_user_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_orders_contest_user_filled ATTACH PARTITION public.orders_shard_3_contest_id_user_id_idx;


--
-- Name: orders_shard_3_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.orders_partitioned_pkey ATTACH PARTITION public.orders_shard_3_pkey;


--
-- Name: orders_shard_3_user_id_contest_id_created_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_orders_user_contest_created ATTACH PARTITION public.orders_shard_3_user_id_contest_id_created_at_idx;


--
-- Name: positions_shard_0_contest_id_realized_score_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_positions_leaderboard ATTACH PARTITION public.positions_shard_0_contest_id_realized_score_idx;


--
-- Name: positions_shard_0_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.positions_partitioned_pkey ATTACH PARTITION public.positions_shard_0_pkey;


--
-- Name: positions_shard_1_contest_id_realized_score_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_positions_leaderboard ATTACH PARTITION public.positions_shard_1_contest_id_realized_score_idx;


--
-- Name: positions_shard_1_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.positions_partitioned_pkey ATTACH PARTITION public.positions_shard_1_pkey;


--
-- Name: positions_shard_2_contest_id_realized_score_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_positions_leaderboard ATTACH PARTITION public.positions_shard_2_contest_id_realized_score_idx;


--
-- Name: positions_shard_2_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.positions_partitioned_pkey ATTACH PARTITION public.positions_shard_2_pkey;


--
-- Name: positions_shard_3_contest_id_realized_score_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_positions_leaderboard ATTACH PARTITION public.positions_shard_3_contest_id_realized_score_idx;


--
-- Name: positions_shard_3_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.positions_partitioned_pkey ATTACH PARTITION public.positions_shard_3_pkey;


--
-- Name: users create_user_referral_code; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER create_user_referral_code AFTER INSERT ON public.users FOR EACH ROW EXECUTE FUNCTION public.trigger_create_referral_code();


--
-- Name: users create_wallet_on_user_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER create_wallet_on_user_insert AFTER INSERT ON public.users FOR EACH ROW EXECUTE FUNCTION public.trigger_create_wallet_for_user();


--
-- Name: contest_duration_configs set_contest_duration_configs_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_contest_duration_configs_updated_at BEFORE UPDATE ON public.contest_duration_configs FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: contest_settlements set_contest_settlements_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_contest_settlements_updated_at BEFORE UPDATE ON public.contest_settlements FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: contest_finalization_state set_finalization_state_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_finalization_state_updated_at BEFORE UPDATE ON public.contest_finalization_state FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: orders set_orders_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: payment_intents set_payment_intents_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_payment_intents_updated_at BEFORE UPDATE ON public.payment_intents FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: payouts set_payouts_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_payouts_updated_at BEFORE UPDATE ON public.payouts FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: shard_config set_shard_config_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_shard_config_updated_at BEFORE UPDATE ON public.shard_config FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: template_entry_tiers set_template_entry_tiers_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_template_entry_tiers_updated_at BEFORE UPDATE ON public.template_entry_tiers FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: tournament_schedules set_tournament_schedules_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_tournament_schedules_updated_at BEFORE UPDATE ON public.tournament_schedules FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: tournament_templates set_tournament_templates_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_tournament_templates_updated_at BEFORE UPDATE ON public.tournament_templates FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: user_verification set_user_verification_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_user_verification_updated_at BEFORE UPDATE ON public.user_verification FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: users set_users_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: wallets set_wallets_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_wallets_updated_at BEFORE UPDATE ON public.wallets FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: withdrawal_limits set_withdrawal_limits_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_withdrawal_limits_updated_at BEFORE UPDATE ON public.withdrawal_limits FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();


--
-- Name: symbols symbols_updated_at_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER symbols_updated_at_trigger BEFORE UPDATE ON public.symbols FOR EACH ROW EXECUTE FUNCTION public.update_symbols_updated_at();


--
-- Name: calendar_entries trg_calendar_entries_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_calendar_entries_updated_at BEFORE UPDATE ON public.calendar_entries FOR EACH ROW EXECUTE FUNCTION public.update_calendar_entries_updated_at();


--
-- Name: email_template_versions trg_check_max_template_versions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_check_max_template_versions BEFORE INSERT ON public.email_template_versions FOR EACH ROW EXECUTE FUNCTION public.check_max_template_versions();


--
-- Name: oauth_accounts trg_oauth_accounts_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_oauth_accounts_updated_at BEFORE UPDATE ON public.oauth_accounts FOR EACH ROW EXECUTE FUNCTION public.update_oauth_accounts_updated_at();


--
-- Name: support_tickets trg_support_tickets_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_support_tickets_updated_at BEFORE UPDATE ON public.support_tickets FOR EACH ROW EXECUTE FUNCTION public.update_support_ticket_timestamp();


--
-- Name: contest_participants trg_update_participant_count; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_update_participant_count AFTER INSERT OR DELETE ON public.contest_participants FOR EACH ROW EXECUTE FUNCTION public.trigger_update_contest_participant_count();


--
-- Name: tournament_schedules trg_validate_active_days; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_validate_active_days BEFORE INSERT OR UPDATE ON public.tournament_schedules FOR EACH ROW EXECUTE FUNCTION public.validate_active_days();


--
-- Name: user_score_history trigger_update_user_stats; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_user_stats AFTER INSERT OR UPDATE ON public.user_score_history FOR EACH ROW EXECUTE FUNCTION public.update_user_stats();


--
-- Name: admin_mfa_credentials admin_mfa_credentials_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_mfa_credentials
    ADD CONSTRAINT admin_mfa_credentials_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: admin_mfa_recovery_codes admin_mfa_recovery_codes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_mfa_recovery_codes
    ADD CONSTRAINT admin_mfa_recovery_codes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.admin_mfa_credentials(user_id) ON DELETE CASCADE;


--
-- Name: affiliate_commissions affiliate_commissions_referred_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.affiliate_commissions
    ADD CONSTRAINT affiliate_commissions_referred_id_fkey FOREIGN KEY (referred_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: affiliate_commissions affiliate_commissions_referrer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.affiliate_commissions
    ADD CONSTRAINT affiliate_commissions_referrer_id_fkey FOREIGN KEY (referrer_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: audit_logs audit_logs_actor_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_actor_user_id_fkey FOREIGN KEY (actor_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: calendar_contest_history calendar_contest_history_calendar_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_contest_history
    ADD CONSTRAINT calendar_contest_history_calendar_entry_id_fkey FOREIGN KEY (calendar_entry_id) REFERENCES public.calendar_entries(id) ON DELETE CASCADE;


--
-- Name: calendar_contest_history calendar_contest_history_contest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_contest_history
    ADD CONSTRAINT calendar_contest_history_contest_id_fkey FOREIGN KEY (contest_id) REFERENCES public.contests(id) ON DELETE CASCADE;


--
-- Name: calendar_entries calendar_entries_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_entries
    ADD CONSTRAINT calendar_entries_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: calendar_entries calendar_entries_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_entries
    ADD CONSTRAINT calendar_entries_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.tournament_templates(id) ON DELETE RESTRICT;


--
-- Name: contest_finalization_state contest_finalization_state_contest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contest_finalization_state
    ADD CONSTRAINT contest_finalization_state_contest_id_fkey FOREIGN KEY (contest_id) REFERENCES public.contests(id) ON DELETE CASCADE;


--
-- Name: contest_participants contest_participants_contest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contest_participants
    ADD CONSTRAINT contest_participants_contest_id_fkey FOREIGN KEY (contest_id) REFERENCES public.contests(id) ON DELETE CASCADE;


--
-- Name: contest_participants contest_participants_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contest_participants
    ADD CONSTRAINT contest_participants_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: contest_prize_locks contest_prize_locks_contest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contest_prize_locks
    ADD CONSTRAINT contest_prize_locks_contest_id_fkey FOREIGN KEY (contest_id) REFERENCES public.contests(id);


--
-- Name: contest_reminders_sent contest_reminders_sent_contest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contest_reminders_sent
    ADD CONSTRAINT contest_reminders_sent_contest_id_fkey FOREIGN KEY (contest_id) REFERENCES public.contests(id) ON DELETE CASCADE;


--
-- Name: contest_settlements contest_settlements_contest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contest_settlements
    ADD CONSTRAINT contest_settlements_contest_id_fkey FOREIGN KEY (contest_id) REFERENCES public.contests(id);


--
-- Name: contest_status_history contest_status_history_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contest_status_history
    ADD CONSTRAINT contest_status_history_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: contest_status_history contest_status_history_contest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contest_status_history
    ADD CONSTRAINT contest_status_history_contest_id_fkey FOREIGN KEY (contest_id) REFERENCES public.contests(id) ON DELETE CASCADE;


--
-- Name: contest_symbols contest_symbols_contest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contest_symbols
    ADD CONSTRAINT contest_symbols_contest_id_fkey FOREIGN KEY (contest_id) REFERENCES public.contests(id) ON DELETE CASCADE;


--
-- Name: contests contests_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contests
    ADD CONSTRAINT contests_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES public.tournament_schedules(id) ON DELETE SET NULL;


--
-- Name: contests contests_tier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contests
    ADD CONSTRAINT contests_tier_id_fkey FOREIGN KEY (tier_id) REFERENCES public.template_entry_tiers(id) ON DELETE SET NULL;


--
-- Name: email_template_versions email_template_versions_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_template_versions
    ADD CONSTRAINT email_template_versions_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: email_template_versions email_template_versions_slug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_template_versions
    ADD CONSTRAINT email_template_versions_slug_fkey FOREIGN KEY (slug) REFERENCES public.email_templates(slug) ON DELETE CASCADE;


--
-- Name: email_template_versions email_template_versions_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_template_versions
    ADD CONSTRAINT email_template_versions_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: email_templates email_templates_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_templates
    ADD CONSTRAINT email_templates_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: email_verification_tokens email_verification_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_verification_tokens
    ADD CONSTRAINT email_verification_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: fills_old fills_contest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fills_old
    ADD CONSTRAINT fills_contest_id_fkey FOREIGN KEY (contest_id) REFERENCES public.contests(id) ON DELETE CASCADE;


--
-- Name: fills_old fills_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fills_old
    ADD CONSTRAINT fills_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders_old(order_id) ON DELETE CASCADE;


--
-- Name: fills_old fills_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fills_old
    ADD CONSTRAINT fills_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: final_rankings final_rankings_contest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.final_rankings
    ADD CONSTRAINT final_rankings_contest_id_fkey FOREIGN KEY (contest_id) REFERENCES public.contests(id);


--
-- Name: final_rankings final_rankings_settlement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.final_rankings
    ADD CONSTRAINT final_rankings_settlement_id_fkey FOREIGN KEY (settlement_id) REFERENCES public.contest_settlements(id) ON DELETE CASCADE;


--
-- Name: final_rankings final_rankings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.final_rankings
    ADD CONSTRAINT final_rankings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: chart_drawings fk_chart_drawings_contest; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chart_drawings
    ADD CONSTRAINT fk_chart_drawings_contest FOREIGN KEY (contest_id) REFERENCES public.contests(id);


--
-- Name: contests fk_contests_shard; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contests
    ADD CONSTRAINT fk_contests_shard FOREIGN KEY (shard_id) REFERENCES public.shard_config(shard_id);


--
-- Name: contests fk_contests_template_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contests
    ADD CONSTRAINT fk_contests_template_id FOREIGN KEY (template_id) REFERENCES public.tournament_templates(id) ON DELETE SET NULL;


--
-- Name: fills fk_fills_p_shard; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.fills
    ADD CONSTRAINT fk_fills_p_shard FOREIGN KEY (shard_id) REFERENCES public.shard_config(shard_id);


--
-- Name: orders fk_orders_p_shard; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.orders
    ADD CONSTRAINT fk_orders_p_shard FOREIGN KEY (shard_id) REFERENCES public.shard_config(shard_id);


--
-- Name: positions fk_positions_p_shard; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.positions
    ADD CONSTRAINT fk_positions_p_shard FOREIGN KEY (shard_id) REFERENCES public.shard_config(shard_id);


--
-- Name: shard_assignment_log fk_shard_assignment_new_shard; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shard_assignment_log
    ADD CONSTRAINT fk_shard_assignment_new_shard FOREIGN KEY (new_shard_id) REFERENCES public.shard_config(shard_id);


--
-- Name: shard_assignment_log fk_shard_assignment_old_shard; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shard_assignment_log
    ADD CONSTRAINT fk_shard_assignment_old_shard FOREIGN KEY (old_shard_id) REFERENCES public.shard_config(shard_id);


--
-- Name: kyc_audit_log kyc_audit_log_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kyc_audit_log
    ADD CONSTRAINT kyc_audit_log_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: kyc_audit_log kyc_audit_log_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kyc_audit_log
    ADD CONSTRAINT kyc_audit_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: kyc_documents kyc_documents_reviewed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kyc_documents
    ADD CONSTRAINT kyc_documents_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: kyc_documents kyc_documents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kyc_documents
    ADD CONSTRAINT kyc_documents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: leaderboard_snapshots leaderboard_snapshots_contest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leaderboard_snapshots
    ADD CONSTRAINT leaderboard_snapshots_contest_id_fkey FOREIGN KEY (contest_id) REFERENCES public.contests(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: oauth_accounts oauth_accounts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_accounts
    ADD CONSTRAINT oauth_accounts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: orders_old orders_contest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders_old
    ADD CONSTRAINT orders_contest_id_fkey FOREIGN KEY (contest_id) REFERENCES public.contests(id) ON DELETE CASCADE;


--
-- Name: orders_old orders_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders_old
    ADD CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: password_reset_codes password_reset_codes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_codes
    ADD CONSTRAINT password_reset_codes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: password_reset_tokens password_reset_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: payment_intents payment_intents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_intents
    ADD CONSTRAINT payment_intents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: payouts payouts_reviewed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payouts
    ADD CONSTRAINT payouts_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.users(id);


--
-- Name: payouts payouts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payouts
    ADD CONSTRAINT payouts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: positions_old positions_contest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions_old
    ADD CONSTRAINT positions_contest_id_fkey FOREIGN KEY (contest_id) REFERENCES public.contests(id) ON DELETE CASCADE;


--
-- Name: positions_old positions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions_old
    ADD CONSTRAINT positions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: prize_distributions prize_distributions_contest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prize_distributions
    ADD CONSTRAINT prize_distributions_contest_id_fkey FOREIGN KEY (contest_id) REFERENCES public.contests(id);


--
-- Name: prize_distributions prize_distributions_settlement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prize_distributions
    ADD CONSTRAINT prize_distributions_settlement_id_fkey FOREIGN KEY (settlement_id) REFERENCES public.contest_settlements(id) ON DELETE CASCADE;


--
-- Name: prize_distributions prize_distributions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prize_distributions
    ADD CONSTRAINT prize_distributions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: referral_codes referral_codes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_codes
    ADD CONSTRAINT referral_codes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: referrals referrals_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_code_fkey FOREIGN KEY (code) REFERENCES public.referral_codes(code) ON DELETE RESTRICT;


--
-- Name: referrals referrals_referred_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_referred_id_fkey FOREIGN KEY (referred_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: referrals referrals_referrer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_referrer_id_fkey FOREIGN KEY (referrer_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: security_audit_log security_audit_log_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_audit_log
    ADD CONSTRAINT security_audit_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: settlement_events settlement_events_contest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settlement_events
    ADD CONSTRAINT settlement_events_contest_id_fkey FOREIGN KEY (contest_id) REFERENCES public.contests(id);


--
-- Name: settlement_events settlement_events_settlement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settlement_events
    ADD CONSTRAINT settlement_events_settlement_id_fkey FOREIGN KEY (settlement_id) REFERENCES public.contest_settlements(id) ON DELETE CASCADE;


--
-- Name: shard_assignment_log shard_assignment_log_assigned_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shard_assignment_log
    ADD CONSTRAINT shard_assignment_log_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: shard_assignment_log shard_assignment_log_contest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shard_assignment_log
    ADD CONSTRAINT shard_assignment_log_contest_id_fkey FOREIGN KEY (contest_id) REFERENCES public.contests(id) ON DELETE CASCADE;


--
-- Name: support_tickets support_tickets_assigned_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_assigned_admin_id_fkey FOREIGN KEY (assigned_admin_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: support_tickets support_tickets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: template_entry_tiers template_entry_tiers_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.template_entry_tiers
    ADD CONSTRAINT template_entry_tiers_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.tournament_templates(id) ON DELETE CASCADE;


--
-- Name: template_prize_distributions template_prize_distributions_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.template_prize_distributions
    ADD CONSTRAINT template_prize_distributions_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.tournament_templates(id) ON DELETE CASCADE;


--
-- Name: ticket_attachments ticket_attachments_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_attachments
    ADD CONSTRAINT ticket_attachments_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.ticket_messages(id) ON DELETE CASCADE;


--
-- Name: ticket_messages ticket_messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_messages
    ADD CONSTRAINT ticket_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: ticket_messages ticket_messages_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_messages
    ADD CONSTRAINT ticket_messages_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.support_tickets(id) ON DELETE CASCADE;


--
-- Name: tier_prize_distributions tier_prize_distributions_tier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tier_prize_distributions
    ADD CONSTRAINT tier_prize_distributions_tier_id_fkey FOREIGN KEY (tier_id) REFERENCES public.template_entry_tiers(id) ON DELETE CASCADE;


--
-- Name: tournament_schedules tournament_schedules_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournament_schedules
    ADD CONSTRAINT tournament_schedules_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.tournament_templates(id) ON DELETE CASCADE;


--
-- Name: user_notification_preferences user_notification_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notification_preferences
    ADD CONSTRAINT user_notification_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_score_history user_score_history_contest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_score_history
    ADD CONSTRAINT user_score_history_contest_id_fkey FOREIGN KEY (contest_id) REFERENCES public.contests(id) ON DELETE CASCADE;


--
-- Name: user_score_history user_score_history_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_score_history
    ADD CONSTRAINT user_score_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_stats user_stats_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_stats
    ADD CONSTRAINT user_stats_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_verification user_verification_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_verification
    ADD CONSTRAINT user_verification_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_verification user_verification_verified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_verification
    ADD CONSTRAINT user_verification_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: verification_codes verification_codes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verification_codes
    ADD CONSTRAINT verification_codes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: wallet_ledger wallet_ledger_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallet_ledger
    ADD CONSTRAINT wallet_ledger_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: wallets wallets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: withdrawal_limits withdrawal_limits_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdrawal_limits
    ADD CONSTRAINT withdrawal_limits_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: withdrawal_limits withdrawal_limits_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdrawal_limits
    ADD CONSTRAINT withdrawal_limits_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: calendar_contests_mv; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: -
--

REFRESH MATERIALIZED VIEW public.calendar_contests_mv;


--
-- PostgreSQL database dump complete
--

\unrestrict YbaHzY9KHjJqjPoVKHAMchbtbmVGD9KqbeRxjhgqarEZb4uh2ymeX0G4amaPvNC

