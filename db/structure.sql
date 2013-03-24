--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

-- COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: acct_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE acct_type_enum AS ENUM (
    'asset',
    'liability',
    'expense',
    'income'
);


--
-- Name: asset_subtype_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE asset_subtype_enum AS ENUM (
    'liquid',
    'retirement',
    'loan',
    'property'
);


--
-- Name: investment_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE investment_type_enum AS ENUM (
    'buy',
    'sell',
    'reinvest'
);


--
-- Name: vehicle; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE vehicle AS ENUM (
    'RAV4',
    'Passat',
    'Sonata'
);


--
-- Name: vehicle_old; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE vehicle_old AS ENUM (
    'RAV4',
    'Passat'
);


--
-- Name: acct_id(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION acct_id(text) RETURNS integer
    LANGUAGE sql
    AS $_$select acct_id as acct_id from account a where a.name like $1 $_$;


--
-- Name: concat(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat(text, text) RETURNS text
    LANGUAGE sql
    AS $_$select $1 || case length($1) when 0 then '' else ', ' end || $2 $_$;


--
-- Name: deltxn(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION deltxn(trans_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$ begin delete from transaction t where t.trans_id = trans_id; end; $$;


--
-- Name: reconciled_entry_immutable(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION reconciled_entry_immutable() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
if (TG_OP = 'DELETE') then
  raise notice 'checking delete for %, %', OLD.entry_id, OLD.stmt_id;
  if (OLD.stmt_id is not null) then
    raise exception 'reconciled entry % cannot be deleted', OLD.entry_id;
  end if;
elsif (TG_OP = 'UPDATE') then
  raise notice 'checking update for %, %, %', OLD.entry_id, OLD.stmt_id, NEW.stmt_id;
  if (OLD.stmt_id is not null and NEW.stmt_id is not null) then
    raise exception 'reconciled entry % cannot updated', OLD.entry_id;
  end if;
end if;
return null;
end;
$$;


--
-- Name: stmts(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION stmts(acct_id integer) RETURNS TABLE(stmt_id integer, stmt_date date, balance numeric)
    LANGUAGE sql
    AS $_$ select stmt_id, stmt_date, balance from bankstatement bs where bs.acct_id = $1 order by stmt_date; $_$;


--
-- Name: verify_zero_sum_txn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION verify_zero_sum_txn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if (TG_OP = 'DELETE' or TG_OP = 'UPDATE') then
    if (select sum(amount) from entry e where e.trans_id = OLD.trans_id) <> 0 then
      raise exception 'transaction % does not sum to zero', OLD.trans_id;
    end if;
  end if;
  if (TG_OP = 'INSERT' or TG_OP = 'UPDATE') then
    if (select sum(amount) from entry e where e.trans_id = NEW.trans_id) <> 0 then
      raise exception 'transaction % does not sum to zero', NEW.trans_id;
    end if;
  end if; 
  return NEW;
end;
$$;


--
-- Name: flatten(text); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE flatten(text) (
    SFUNC = public.concat,
    STYPE = text,
    INITCOND = ''
);


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: account; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE account (
    acct_id integer NOT NULL,
    name character varying(80) DEFAULT ''::character varying NOT NULL,
    acct_type acct_type_enum DEFAULT 'asset'::acct_type_enum,
    memo text,
    entered timestamp without time zone DEFAULT now() NOT NULL,
    inst_id integer,
    num character varying(30) DEFAULT NULL::character varying,
    date_opened date,
    is_open boolean DEFAULT true NOT NULL,
    asset_subtype asset_subtype_enum,
    is_investment boolean DEFAULT false NOT NULL,
    budget_category_id integer
);


--
-- Name: account_acct_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE account_acct_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_acct_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE account_acct_id_seq OWNED BY account.acct_id;


--
-- Name: bankstatement; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bankstatement (
    stmt_id integer NOT NULL,
    acct_id integer NOT NULL,
    stmt_date date NOT NULL,
    balance numeric(10,2) NOT NULL,
    entered timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: bankstatement_stmt_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bankstatement_stmt_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bankstatement_stmt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bankstatement_stmt_id_seq OWNED BY bankstatement.stmt_id;


--
-- Name: budget_category; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE budget_category (
    budget_category_id integer NOT NULL,
    category_name text,
    annual_amount money
);


--
-- Name: budget_category_budget_category_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE budget_category_budget_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: budget_category_budget_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE budget_category_budget_category_id_seq OWNED BY budget_category.budget_category_id;


--
-- Name: classification; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE classification (
    classif_id integer NOT NULL,
    name character varying(50) DEFAULT ''::character varying NOT NULL
);


--
-- Name: classification_classif_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE classification_classif_id_seq
    START WITH 31
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: classification_classif_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE classification_classif_id_seq OWNED BY classification.classif_id;


--
-- Name: entry; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE entry (
    entry_id integer NOT NULL,
    trans_id integer NOT NULL,
    acct_id integer NOT NULL,
    num character varying(20),
    amount numeric(10,2) NOT NULL,
    user_id integer NOT NULL,
    classif_id integer,
    stmt_id integer,
    memo text
);


--
-- Name: entry_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE entry_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: entry_entry_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE entry_entry_id_seq OWNED BY entry.entry_id;


--
-- Name: fuser; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE fuser (
    user_id integer NOT NULL,
    fullname character varying(50) NOT NULL,
    nickname character varying(4) NOT NULL
);


--
-- Name: fuser_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE fuser_user_id_seq
    START WITH 9
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fuser_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE fuser_user_id_seq OWNED BY fuser.user_id;


--
-- Name: gas; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE gas (
    entry_id integer NOT NULL,
    odometer integer,
    gallons numeric(5,3),
    vehicle vehicle NOT NULL
);


--
-- Name: payee; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE payee (
    payee_id integer NOT NULL,
    name character varying(50) NOT NULL,
    memo text,
    entered timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: transaction; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE transaction (
    trans_id integer NOT NULL,
    date date NOT NULL,
    payee_id integer,
    is_void boolean DEFAULT false NOT NULL,
    entered timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: trip_odometer; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW trip_odometer AS
    SELECT g.entry_id, (g.odometer - (SELECT g2.odometer FROM ((gas g2 JOIN entry e USING (entry_id)) JOIN transaction t2 USING (trans_id)) WHERE ((g2.vehicle = g.vehicle) AND (t2.date < t.date)) ORDER BY t2.date DESC LIMIT 1)) AS trip_odometer FROM ((gas g JOIN entry e USING (entry_id)) JOIN transaction t USING (trans_id)) ORDER BY g.vehicle, t.date;


--
-- Name: gas_history; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW gas_history AS
    SELECT g.vehicle, t.date, g.gallons, e.amount, p.name, g.odometer, o.trip_odometer, round(((o.trip_odometer)::numeric / g.gallons), 1) AS mpg FROM ((((gas g JOIN entry e USING (entry_id)) JOIN transaction t USING (trans_id)) LEFT JOIN payee p USING (payee_id)) JOIN trip_odometer o USING (entry_id)) ORDER BY g.vehicle, t.date;


--
-- Name: institution; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE institution (
    inst_id integer NOT NULL,
    name character varying(50) NOT NULL
);


--
-- Name: institution_inst_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE institution_inst_id_seq
    START WITH 9
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: institution_inst_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE institution_inst_id_seq OWNED BY institution.inst_id;


--
-- Name: inventory; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE inventory (
    entry_id integer NOT NULL,
    memo text,
    serial_number character varying(255) DEFAULT NULL::character varying,
    manual_url text,
    model_number text
);


--
-- Name: investment; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE investment (
    investment_id integer NOT NULL,
    symbol character varying(50) DEFAULT NULL::character varying
);


--
-- Name: investment_investment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE investment_investment_id_seq
    START WITH 19
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: investment_investment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE investment_investment_id_seq OWNED BY investment.investment_id;


--
-- Name: investment_transaction; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE investment_transaction (
    inv_trans_id integer NOT NULL,
    acct_id integer,
    date date,
    quantity numeric(17,4) NOT NULL,
    price numeric(16,6) NOT NULL,
    fee numeric(16,2) NOT NULL,
    type investment_type_enum DEFAULT 'buy'::investment_type_enum NOT NULL,
    memo character varying(50) DEFAULT NULL::character varying,
    investment_id integer NOT NULL,
    amount numeric(16,2) NOT NULL,
    user_id integer,
    sec_fee numeric(16,2) DEFAULT 0.00,
    split_factor numeric(14,10) DEFAULT 1.0000000000,
    trans_id integer
);


--
-- Name: investment_transaction_inv_trans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE investment_transaction_inv_trans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: investment_transaction_inv_trans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE investment_transaction_inv_trans_id_seq OWNED BY investment_transaction.inv_trans_id;


--
-- Name: payee_payee_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE payee_payee_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payee_payee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE payee_payee_id_seq OWNED BY payee.payee_id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: transaction_trans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE transaction_trans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transaction_trans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE transaction_trans_id_seq OWNED BY transaction.trans_id;


--
-- Name: acct_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY account ALTER COLUMN acct_id SET DEFAULT nextval('account_acct_id_seq'::regclass);


--
-- Name: stmt_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY bankstatement ALTER COLUMN stmt_id SET DEFAULT nextval('bankstatement_stmt_id_seq'::regclass);


--
-- Name: budget_category_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY budget_category ALTER COLUMN budget_category_id SET DEFAULT nextval('budget_category_budget_category_id_seq'::regclass);


--
-- Name: classif_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY classification ALTER COLUMN classif_id SET DEFAULT nextval('classification_classif_id_seq'::regclass);


--
-- Name: entry_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY entry ALTER COLUMN entry_id SET DEFAULT nextval('entry_entry_id_seq'::regclass);


--
-- Name: user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY fuser ALTER COLUMN user_id SET DEFAULT nextval('fuser_user_id_seq'::regclass);


--
-- Name: inst_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY institution ALTER COLUMN inst_id SET DEFAULT nextval('institution_inst_id_seq'::regclass);


--
-- Name: investment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY investment ALTER COLUMN investment_id SET DEFAULT nextval('investment_investment_id_seq'::regclass);


--
-- Name: inv_trans_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY investment_transaction ALTER COLUMN inv_trans_id SET DEFAULT nextval('investment_transaction_inv_trans_id_seq'::regclass);


--
-- Name: payee_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY payee ALTER COLUMN payee_id SET DEFAULT nextval('payee_payee_id_seq'::regclass);


--
-- Name: trans_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY transaction ALTER COLUMN trans_id SET DEFAULT nextval('transaction_trans_id_seq'::regclass);


--
-- Name: account_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY account
    ADD CONSTRAINT account_pkey PRIMARY KEY (acct_id);


--
-- Name: bankstatement_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bankstatement
    ADD CONSTRAINT bankstatement_pkey PRIMARY KEY (stmt_id);


--
-- Name: budget_category_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY budget_category
    ADD CONSTRAINT budget_category_pkey PRIMARY KEY (budget_category_id);


--
-- Name: classification_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY classification
    ADD CONSTRAINT classification_pkey PRIMARY KEY (classif_id);


--
-- Name: entry_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY entry
    ADD CONSTRAINT entry_pkey PRIMARY KEY (entry_id);


--
-- Name: fuser_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY fuser
    ADD CONSTRAINT fuser_pkey PRIMARY KEY (user_id);


--
-- Name: inst_name; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY institution
    ADD CONSTRAINT inst_name UNIQUE (name);


--
-- Name: institution_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY institution
    ADD CONSTRAINT institution_pkey PRIMARY KEY (inst_id);


--
-- Name: inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY inventory
    ADD CONSTRAINT inventory_pkey PRIMARY KEY (entry_id);


--
-- Name: investment_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY investment
    ADD CONSTRAINT investment_pkey PRIMARY KEY (investment_id);


--
-- Name: investment_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY investment_transaction
    ADD CONSTRAINT investment_transaction_pkey PRIMARY KEY (inv_trans_id);


--
-- Name: payee_name; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY payee
    ADD CONSTRAINT payee_name UNIQUE (name);


--
-- Name: payee_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY payee
    ADD CONSTRAINT payee_pkey PRIMARY KEY (payee_id);


--
-- Name: transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY transaction
    ADD CONSTRAINT transaction_pkey PRIMARY KEY (trans_id);


--
-- Name: uniq_acct_date; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bankstatement
    ADD CONSTRAINT uniq_acct_date UNIQUE (acct_id, stmt_date);


--
-- Name: uniq_acct_name; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY account
    ADD CONSTRAINT uniq_acct_name UNIQUE (name);


--
-- Name: uniq_classif_name; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY classification
    ADD CONSTRAINT uniq_classif_name UNIQUE (name);


--
-- Name: uniq_inst_num; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY account
    ADD CONSTRAINT uniq_inst_num UNIQUE (inst_id, num);


--
-- Name: user_fullname; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY fuser
    ADD CONSTRAINT user_fullname UNIQUE (fullname);


--
-- Name: user_nickname; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY fuser
    ADD CONSTRAINT user_nickname UNIQUE (nickname);


--
-- Name: acct_id_2; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX acct_id_2 ON bankstatement USING btree (acct_id);


--
-- Name: acct_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX acct_type ON account USING btree (acct_type);


--
-- Name: entry_amt; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX entry_amt ON entry USING btree (amount);


--
-- Name: entry_num; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX entry_num ON entry USING btree (num);


--
-- Name: inst_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX inst_id ON account USING btree (inst_id);


--
-- Name: open; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX open ON account USING btree (is_open);


--
-- Name: stmt_date; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX stmt_date ON bankstatement USING btree (stmt_date);


--
-- Name: trans_date; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX trans_date ON transaction USING btree (date);


--
-- Name: trans_payee; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX trans_payee ON transaction USING btree (payee_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: reconciled_entry_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER reconciled_entry_immutable AFTER DELETE OR UPDATE ON entry NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE reconciled_entry_immutable();


--
-- Name: verify_zero_sum_txn; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER verify_zero_sum_txn AFTER INSERT OR DELETE OR UPDATE ON entry DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE verify_zero_sum_txn();


--
-- Name: account_budget_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account
    ADD CONSTRAINT account_budget_category_id_fkey FOREIGN KEY (budget_category_id) REFERENCES budget_category(budget_category_id);


--
-- Name: fk_acct_inst; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account
    ADD CONSTRAINT fk_acct_inst FOREIGN KEY (inst_id) REFERENCES institution(inst_id);


--
-- Name: fk_entry_acct; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entry
    ADD CONSTRAINT fk_entry_acct FOREIGN KEY (acct_id) REFERENCES account(acct_id);


--
-- Name: fk_entry_classif; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entry
    ADD CONSTRAINT fk_entry_classif FOREIGN KEY (classif_id) REFERENCES classification(classif_id) ON DELETE SET NULL;


--
-- Name: fk_entry_stmt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entry
    ADD CONSTRAINT fk_entry_stmt FOREIGN KEY (stmt_id) REFERENCES bankstatement(stmt_id);


--
-- Name: fk_entry_trans; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entry
    ADD CONSTRAINT fk_entry_trans FOREIGN KEY (trans_id) REFERENCES transaction(trans_id) ON DELETE CASCADE;


--
-- Name: fk_entry_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entry
    ADD CONSTRAINT fk_entry_user FOREIGN KEY (user_id) REFERENCES fuser(user_id);


--
-- Name: fk_invsttrans_invst; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY investment_transaction
    ADD CONSTRAINT fk_invsttrans_invst FOREIGN KEY (investment_id) REFERENCES investment(investment_id);


--
-- Name: fk_stmt_account; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bankstatement
    ADD CONSTRAINT fk_stmt_account FOREIGN KEY (acct_id) REFERENCES account(acct_id) ON DELETE CASCADE;


--
-- Name: fk_trans_payee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY transaction
    ADD CONSTRAINT fk_trans_payee FOREIGN KEY (payee_id) REFERENCES payee(payee_id);


--
-- Name: gas_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gas
    ADD CONSTRAINT gas_entry_id_fkey FOREIGN KEY (entry_id) REFERENCES entry(entry_id);


--
-- PostgreSQL database dump complete
--

