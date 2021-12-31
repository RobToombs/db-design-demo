truncate appointment, refill, identity_map, identity, identity_map_history;

INSERT INTO identity (id, upi, mrn, patient_last, patient_first, date_of_birth, gender, active, create_date, end_date, created_by, modified_by) VALUES (1, '-2084392503', '12345', 'Tombs', 'Robert', '1990-03-03', 'M', true, now(), null, 'dani@shieldsrx.com', '');
INSERT INTO identity (id, upi, mrn, patient_last, patient_first, date_of_birth, gender, active, create_date, end_date, created_by, modified_by) VALUES (2, '821534616', '321345', 'Jobs', 'Steve', '1955-02-24', 'F', true, now(), null, 'stella@shieldsrx.com', '');

INSERT INTO identity_map (id, identity_id) VALUES (1, 1);
INSERT INTO identity_map (id, identity_id) VALUES (2, 2);

INSERT INTO appointment (id, identity_map_id, date, medication) VALUES (1, 1, '2021-12-24 07:30:00', 'Coffee');
INSERT INTO appointment (id, identity_map_id, date, medication) VALUES (2, 2, '2021-12-25 09:00:00', 'Apples');

INSERT INTO refill (id, identity_map_id, date, call_attempts, medication) VALUES (1, 1, '2021-12-27', 1, 'Coffee');
INSERT INTO refill (id, identity_map_id, date, call_attempts, medication) VALUES (2, 1, '2021-12-25', 2, 'Donuts');
INSERT INTO refill (id, identity_map_id, date, call_attempts, medication) VALUES (3, 2, '2022-01-01', 0, 'Apples');

SELECT setval('identity_id_seq', (SELECT MAX(id) FROM identity));
SELECT setval('identity_map_id_seq', (SELECT MAX(id) FROM identity_map));
SELECT setval('appointment_id_seq', (SELECT MAX(id) FROM appointment));
SELECT setval('refill_id_seq', (SELECT MAX(id) FROM refill));