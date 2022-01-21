create table identity (
      id                     BIGSERIAL PRIMARY KEY,
      trx_id                 TEXT NOT NULL DEFAULT '',
      upi                    TEXT NOT NULL DEFAULT '',
      mrn                    TEXT NOT NULL DEFAULT '',
      patient_last           TEXT NOT NULL DEFAULT '',
      patient_first          TEXT NOT NULL DEFAULT '',
      date_of_birth          DATE DEFAULT NULL,
      gender                 TEXT NOT NULL DEFAULT '',
      active                 BOOLEAN NOT NULL DEFAULT false,
      create_date            TIMESTAMP DEFAULT now(),
      end_date               TIMESTAMP DEFAULT NULL,
      created_by             TEXT NOT NULL DEFAULT '',
      modified_by            TEXT DEFAULT NULL
);

create table mrn_overflow (
    id               BIGSERIAL PRIMARY KEY,
    identity_id      BIGINT,
    mrn              TEXT NOT NULL DEFAULT '',

    FOREIGN KEY(identity_id) REFERENCES identity(id)
);

create table phone (
    id                  BIGSERIAL PRIMARY KEY,
    identity_id         BIGINT,
    number              TEXT NOT NULL DEFAULT '',
    type                TEXT NOT NULL DEFAULT '',

    FOREIGN KEY(identity_id) REFERENCES identity(id)
);

create table identity_map (
      id                     BIGSERIAL PRIMARY KEY,
      identity_id            BIGINT,

      FOREIGN KEY(identity_id) REFERENCES identity(id)
);

create table identity_map_history (
      id                BIGSERIAL PRIMARY KEY,
      create_date       TIMESTAMP NOT NULL,
      identity_map_id   BIGINT NOT NULL,
      old_identity_id   BIGINT DEFAULT NULL,
      new_identity_id   BIGINT NOT NULL,
      event             TEXT NOT NULL DEFAULT ''
);

create table appointment (
      id                     BIGSERIAL PRIMARY KEY,
      identity_map_id        BIGINT,
      identity_id            BIGINT DEFAULT NULL,
      active                 BOOLEAN DEFAULT TRUE,
      date                   DATE DEFAULT NULL,
      medication             TEXT NOT NULL DEFAULT '',

      FOREIGN KEY(identity_map_id) REFERENCES identity_map(id),
      FOREIGN KEY(identity_id) REFERENCES identity(id)
);

create table refill (
     id                     BIGSERIAL PRIMARY KEY,
     identity_map_id        BIGINT,
     identity_id            BIGINT DEFAULT NULL,
     active                 BOOLEAN DEFAULT TRUE,
     date                   DATE DEFAULT NULL,
     call_attempts          SMALLINT DEFAULT 0 NOT NULL,
     medication             TEXT NOT NULL DEFAULT '',

     FOREIGN KEY(identity_map_id) REFERENCES identity_map(id),
     FOREIGN KEY(identity_id) REFERENCES identity(id)
);

-- WHILE THIS WORKS PROPERLY WHEN MAKING MANUAL DB UPDATES, I'M HAVING TROUBLE
-- GETTING IT TO WORK WITH SPRING/HIBERNATE
--
-- CREATE OR REPLACE FUNCTION process_identity_map_history()
-- RETURNS TRIGGER
-- AS $$
-- BEGIN
--     --
--     -- Create a row in identity_map_history to reflect the operation performed on identity_map,
--     -- making use of the special variable TG_OP to work out the operation.
--     --
--     IF (TG_OP = 'UPDATE') THEN
--         INSERT INTO identity_map_history (create_date, identity_map_id, old_identity_id, new_identity_id) SELECT now(), NEW.id, OLD.identity_id, NEW.identity_id;
--     END IF;
--     RETURN NULL; -- result is ignored since this is an AFTER trigger
-- END;
-- $$ LANGUAGE PLPGSQL;
--
-- CREATE TRIGGER identity_map_trigger
--     AFTER UPDATE ON public.identity_map
--     FOR EACH ROW EXECUTE PROCEDURE process_identity_map_history();

create table identity_history (
          id                     BIGSERIAL PRIMARY KEY,
          trx_id                 TEXT NOT NULL DEFAULT '',
          upi                    TEXT NOT NULL DEFAULT '',
          mrn                    TEXT NOT NULL DEFAULT '',
          patient_last           TEXT NOT NULL DEFAULT '',
          patient_first          TEXT NOT NULL DEFAULT '',
          date_of_birth          DATE DEFAULT NULL,
          gender                 TEXT NOT NULL DEFAULT '',
          active                 BOOLEAN NOT NULL DEFAULT false,
          create_date            TIMESTAMP DEFAULT now(),
          end_date               TIMESTAMP DEFAULT NULL,
          created_by             TEXT NOT NULL DEFAULT '',
          modified_by            TEXT DEFAULT NULL
);

create table mrn_overflow_history (
          id               BIGSERIAL PRIMARY KEY,
          identity_id      BIGINT,
          mrn              TEXT NOT NULL DEFAULT '',

          FOREIGN KEY(identity_id) REFERENCES identity(id)
);

create table phone_history (
           id                  BIGSERIAL PRIMARY KEY,
           identity_id         BIGINT,
           number              TEXT NOT NULL DEFAULT '',
           type                TEXT NOT NULL DEFAULT '',

           FOREIGN KEY(identity_id) REFERENCES identity(id)
);