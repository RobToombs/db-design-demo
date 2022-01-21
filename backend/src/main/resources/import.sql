truncate phone, mrn_overflow, appointment, refill, identity_map, identity, identity_map_history, identity_history, phone_history, mrn_overflow_history, identity_history;

INSERT INTO identity (id, upi, trx_id, mrn, patient_last, patient_first, date_of_birth, gender, active, create_date, end_date, created_by, modified_by) VALUES (1, '-2084392503', 'TRX-13712371123', '12345', 'Tombs', 'Robert', '1990-03-03', 'M', true, now(), null, 'dani@shieldsrx.com', '');
INSERT INTO identity (id, upi, trx_id, mrn, patient_last, patient_first, date_of_birth, gender, active, create_date, end_date, created_by, modified_by) VALUES (2, '821534616', 'TRX-23321253278', '321345', 'Jobs', 'Steve', '1955-02-24', 'F', true, now(), null, 'stella@shieldsrx.com', '');

INSERT INTO phone (id, identity_id, number, type) VALUES (1, 1, '603-505-4444', 'MOBILE');
INSERT INTO phone (id, identity_id, number, type) VALUES (2, 1, '603-505-6666', 'HOME');
INSERT INTO phone (id, identity_id, number, type) VALUES (3, 2, '555-555-5555', 'MOBILE');

INSERT INTO mrn_overflow (id, identity_id, mrn) VALUES (1, 1, '12345-2');
INSERT INTO mrn_overflow (id, identity_id, mrn) VALUES (2, 1, '12345-3');
INSERT INTO mrn_overflow (id, identity_id, mrn) VALUES (3, 2, '321345-2');

INSERT INTO identity_map (id, identity_id) VALUES (1, 1);
INSERT INTO identity_map (id, identity_id) VALUES (2, 2);

INSERT INTO identity_map_history (id, create_date, event, identity_map_id, new_identity_id, old_identity_id) VALUES (1, now(), 'CREATE', 1, 1, null);
INSERT INTO identity_map_history (id, create_date, event, identity_map_id, new_identity_id, old_identity_id) VALUES (2, now(), 'CREATE', 2, 2, null);

INSERT INTO appointment (id, identity_map_id, date, medication, active) VALUES (1, 1, '2021-12-24 07:30:00', 'Coffee', true);
INSERT INTO appointment (id, identity_map_id, date, medication, active) VALUES (2, 2, '2021-12-25 09:00:00', 'Apples', true);

INSERT INTO refill (id, identity_map_id, date, call_attempts, medication, active) VALUES (1, 1, '2021-12-27', 1, 'Coffee', true);
INSERT INTO refill (id, identity_map_id, date, call_attempts, medication, active) VALUES (2, 1, '2021-12-25', 2, 'Donuts', true);
INSERT INTO refill (id, identity_map_id, date, call_attempts, medication, active) VALUES (3, 2, '2022-01-01', 0, 'Apples', true);

SELECT setval('identity_id_seq', (SELECT MAX(id) FROM identity));
SELECT setval('identity_map_id_seq', (SELECT MAX(id) FROM identity_map));
SELECT setval('appointment_id_seq', (SELECT MAX(id) FROM appointment));
SELECT setval('refill_id_seq', (SELECT MAX(id) FROM refill));
SELECT setval('phone_id_seq', (SELECT MAX(id) FROM phone));
SELECT setval('mrn_overflow_id_seq', (SELECT MAX(id) FROM mrn_overflow));
SELECT setval('identity_map_history_id_seq', (SELECT MAX(id) FROM identity_map_history));
SELECT setval('phone_history_id_seq', (SELECT MAX(id) FROM phone_history));
SELECT setval('mrn_overflow_history_id_seq', (SELECT MAX(id) FROM mrn_overflow_history));
SELECT setval('identity_history_id_seq', (SELECT MAX(id) FROM identity_history));