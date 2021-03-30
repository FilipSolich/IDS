--
-- xsolic00-xsechr00.sql
--
-- Date:    29. 3. 2021
-- Authors: Filip Solich <xsolic00@stud.fit.vutbr.cz>
--          Marek Sechra <xsechr00@stud.fit.vutbr.cz>
--


-- Drop everything
DROP SEQUENCE kocka_id_seq;
DROP SEQUENCE hostitel_id_seq;
DROP SEQUENCE zivot_id_seq;
DROP SEQUENCE vyskyt_id_seq;
DROP SEQUENCE teritorium_id_seq;
DROP SEQUENCE vec_id_seq;
DROP SEQUENCE vlastnictvi_id_seq;
DROP SEQUENCE propujcka_id_seq;

DROP TABLE kocka CASCADE CONSTRAINTS;
DROP TABLE hostitel CASCADE CONSTRAINTS;
DROP TABLE teritorium CASCADE CONSTRAINTS;
DROP TABLE vec CASCADE CONSTRAINTS;
DROP TABLE rasa CASCADE CONSTRAINTS;
DROP TABLE zivot CASCADE CONSTRAINTS;
DROP TABLE vyskyt CASCADE CONSTRAINTS;
DROP TABLE vlastnictvi CASCADE CONSTRAINTS;
DROP TABLE propujcka CASCADE CONSTRAINTS;


-- Sequences for primary keys
CREATE SEQUENCE kocka_id_seq
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE hostitel_id_seq
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE zivot_id_seq
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE vyskyt_id_seq
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE teritorium_id_seq
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE vec_id_seq
START WITH  1
INCREMENT BY 1;

CREATE SEQUENCE vlastnictvi_id_seq
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE propujcka_id_seq
START WITH 1
INCREMENT BY 1;

-- Create tables
CREATE TABLE kocka (
    id INT DEFAULT kocka_id_seq.NEXTVAL,
    hlavni_jmeno VARCHAR2(30),
    vzorek_kuze VARCHAR2(30), -- co ma byt vzorek kuze?
    barva_srsti INT,
    rasa VARCHAR2(30)
);

CREATE TABLE hostitel (
    id INT DEFAULT hostitel_id_seq.NEXTVAL,
    jmeno VARCHAR2(30),
    vek INT,
    pohlavi VARCHAR2(30),
    pojmenovani_od_kocky VARCHAR2(30),
    adresa VARCHAR2(100), -- melo by byt rozdeleno na ulice, cp, mesto, stat a psc?
    kocka INT,
    preferovana_rasa VARCHAR2(30)
);

CREATE TABLE rasa (
    nazev VARCHAR2(30),
    barva_oci VARCHAR2(30),
    puvod VARCHAR2(50),
    max_delka_tesaku INT
);

-- Misto delky by bylo asi lepsi mit jen zacatek a konec ze ktereho se to da vypocitat
-- a nebo jen delku jako TIMESTAMP protoze v zadani je napsane delka zivota
-- a ne datum zacatku a datum konce.

-- Z stav muzeme udelat "ENUM" aby jsme splnili pozadavek na minimalne jeden CHECK
CREATE TABLE zivot (
    id INT DEFAULT zivot_id_seq.NEXTVAL,
    stav VARCHAR2(30) NOT NULL,
    delka TIMESTAMP,
    zacatek DATE NOT NULL,
    konec DATE,
    zpusob_smrti VARCHAR2(50),
    kocka INT NOT NULL,
    teritorium INT
);

CREATE TABLE vyskyt (
    id INT DEFAULT vyskyt_id_seq.NEXTVAL,
    od TIMESTAMP NOT NULL,
    do TIMESTAMP,
    kocka INT NOT NULL,
    teritorium INT NOT NULL
);

CREATE TABLE teritorium (
  id INT DEFAULT teritorium_id_seq.NEXTVAL,
  druh VARCHAR2(30) NOT NULL,
  kapacita_kocek INT NOT NULL,
  velikost INT NOT NULL,
  vyskyt INT NOT NULL,
  zivot INT NOT NULL,
  vec INT NOT NULL
);

CREATE TABLE vec (
    id INT DEFAULT vec_id_seq.NEXTVAL,
    druh VARCHAR2(30) NOT NULL,
    pocet INT,
    teritorium INT NOT NULL,
    vlastnictvi INT NOT NULL
);

CREATE TABLE vlastnictvi (
  id INT DEFAULT vlastnictvi_id_seq.NEXTVAL,
  od TIMESTAMP NOT NULL,
  do TIMESTAMP,
  vec INT NOT NULL,
  propujcka INT NOT NULL,
  kocka INT NOT NULL
);
CREATE TABLE propujcka (
  id INT DEFAULT  propujcka_id_seq.NEXTVAL,
  od TIMESTAMP NOT NULL,
  do TIMESTAMP,
  vlastnictvi INT NOT NULL,
  hostitel INT NOT NULL
);


-- Add PRIMARY KEY
ALTER TABLE kocka ADD CONSTRAINT PK_kocka PRIMARY KEY (id);
ALTER TABLE hostitel ADD CONSTRAINT PK_hostitel PRIMARY KEY (id);
ALTER TABLE rasa ADD CONSTRAINT PK_rasa PRIMARY KEY (nazev);
ALTER TABLE zivot ADD CONSTRAINT PK_zivot PRIMARY KEY (id);
ALTER TABLE vyskyt ADD CONSTRAINT PK_vyskyt PRIMARY KEY (id);
ALTER TABLE teritorium ADD CONSTRAINT PK_teritorium PRIMARY KEY(id);
ALTER TABLE vec ADD CONSTRAINT PK_vec PRIMARY KEY(id);
ALTER TABLE vlastnictvi ADD  CONSTRAINT PK_vlastnictvi PRIMARY KEY(id);
ALTER TABLE propujcka ADD CONSTRAINT PK_propujcka PRIMARY KEY(id);

-- Add FOREIGN KEY
ALTER TABLE kocka ADD CONSTRAINT FK_kocka_rasa FOREIGN KEY (rasa) REFERENCES rasa;
ALTER TABLE hostitel ADD CONSTRAINT FK_hostitel_kocka FOREIGN KEY (kocka) REFERENCES kocka;
ALTER TABLE hostitel ADD CONSTRAINT FK_hostitel_preferovana_rasa FOREIGN KEY (preferovana_rasa) REFERENCES rasa;
ALTER TABLE zivot ADD CONSTRAINT FK_zivot_kocka FOREIGN KEY (kocka) REFERENCES kocka ON DELETE CASCADE;
ALTER TABLE zivot ADD CONSTRAINT FK_zivot_teritorium FOREIGN KEY (teritorium) REFERENCES teritorium ON DELETE CASCADE;
ALTER TABLE vyskyt ADD CONSTRAINT FK_vyskyt_kocka FOREIGN KEY (kocka) REFERENCES kocka ON DELETE CASCADE;
ALTER TABLE vyskyt ADD CONSTRAINT FK_vyskyt_teritorium FOREIGN KEY (teritorium) REFERENCES teritorium ON DELETE CASCADE;
ALTER TABLE teritorium ADD CONSTRAINT FK_teritorium_vyskyt FOREIGN KEY (vyskyt) REFERENCES vyskyt;
ALTER TABLE teritorium ADD CONSTRAINT FK_teritorium_zivot FOREIGN KEY (zivot) REFERENCES  zivot;
ALTER TABLE teritorium ADD CONSTRAINT FK_teritorium_vec FOREIGN KEY (vec) REFERENCES vec;
ALTER TABLE vec ADD CONSTRAINT FK_vec_teritorium FOREIGN KEY (teritorium) REFERENCES teritorium ON DELETE CASCADE;
ALTER TABLE vec ADD CONSTRAINT FK_vec_vlastnictvi FOREIGN KEY (vlastnictvi) REFERENCES vlastnictvi ON DELETE CASCADE;
ALTER TABLE vlastnictvi ADD CONSTRAINT  FK_vlastnictvi_vec FOREIGN KEY (vec) REFERENCES vec ON DELETE CASCADE;
ALTER TABLE vlastnictvi ADD CONSTRAINT FK_vlastnictvi_kocka FOREIGN KEY (kocka) REFERENCES kocka ON DELETE CASCADE;
ALTER TABLE vlastnictvi ADD CONSTRAINT  FK_vlastnictvi_propujcka FOREIGN KEY (propujcka) REFERENCES propujcka ON DELETE CASCADE;
ALTER TABLE propujcka ADD CONSTRAINT FK_propujcka_vlastnictvi FOREIGN KEY (vlastnictvi) REFERENCES vlastnictvi ON DELETE CASCADE;
ALTER TABLE propujcka ADD CONSTRAINT FK_propujcka_hostitel FOREIGN KEY (hostitel) REFERENCES hostitel ON DELETE CASCADE;