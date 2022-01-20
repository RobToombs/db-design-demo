drop table phone, mrn_overflow, refill, appointment, identity_map_history, identity_map, identity;

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
      done                   BOOLEAN NOT NULL DEFAULT false,
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