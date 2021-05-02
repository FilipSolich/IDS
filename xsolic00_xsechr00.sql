--
-- xsolic00-xsechr00.sql
--
-- Date:    1. 5. 2021
-- Authors: Filip Solich <xsolic00@stud.fit.vutbr.cz>
--          Marek Sechra <xsechr00@stud.fit.vutbr.cz>
--


--
-- Drop everything
--
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


--
-- Sequences for primary keys
--
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

CREATE SEQUENCE vlastnictvi_id_seq
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE propujcka_id_seq
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE  vec_id_seq
START WITH 1
INCREMENT BY 1;



--
-- Create tables
--
CREATE TABLE kocka (
    id INT DEFAULT kocka_id_seq.NEXTVAL,
    hlavni_jmeno VARCHAR(30),
    vzorek_kuze VARCHAR(30),
    barva_srsti VARCHAR(30),
    rasa VARCHAR(30)
);

CREATE TABLE hostitel (
    id INT DEFAULT hostitel_id_seq.NEXTVAL,
    jmeno VARCHAR(30),
    vek INT CHECK (vek >= 18),
    pohlavi VARCHAR(30),
    jmeno_pro_kocku VARCHAR(30),
    ulice VARCHAR(100),
    cislo_popisne INT,
    mesto VARCHAR(100),
    psc INT,
    kocka INT NOT NULL,
    preferovana_rasa VARCHAR(30) NOT NULL
);

CREATE TABLE rasa (
    nazev VARCHAR(30),
    barva_oci VARCHAR(30),
    puvod VARCHAR(50),
    max_delka_tesaku INT
);

CREATE TABLE zivot (
    id INT DEFAULT zivot_id_seq.NEXTVAL,
    stav VARCHAR(30) NOT NULL,
    zacatek TIMESTAMP NOT NULL,
    konec TIMESTAMP,
    zpusob_smrti VARCHAR(50),
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
    druh VARCHAR(30) NOT NULL,
    kapacita_kocek INT NOT NULL,
    velikost INT NOT NULL
);

CREATE TABLE vec (
    id INT,-- DEFAULT vec_id_seq.NEXTVAL,
    druh VARCHAR(30) NOT NULL,
    pocet INT,
    teritorium INT NOT NULL
);

CREATE TABLE vlastnictvi (
    id INT DEFAULT vlastnictvi_id_seq.NEXTVAL,
    od TIMESTAMP NOT NULL,
    do TIMESTAMP,
    vec INT NOT NULL,
    kocka INT NOT NULL
);

CREATE TABLE propujcka (
    id INT DEFAULT  propujcka_id_seq.NEXTVAL,
    od TIMESTAMP NOT NULL,
    do TIMESTAMP,
    vlastnictvi INT NOT NULL,
    hostitel INT NOT NULL
);


--
-- TRIGGER
--

-- trigger pro automatické generování hotnot primárního klíče
-- Tabulka: vec
-- ID: id
CREATE OR REPLACE TRIGGER id_vec_trigger
    BEFORE INSERT ON vec
    FOR EACH ROW
    BEGIN
        :NEW.id := vec_id_seq.NEXTVAL;
    END;

-- Trigger pro kontrolu tabulky života jestli nebyl začátek a konec zapsán jako budoucí datum a jestli je začátek < konec (pokud není null)
-- tabulka: zivot
-- atribut: zacatek,konec
CREATE OR REPLACE TRIGGER check_zivot_start
    BEFORE INSERT OR UPDATE ON zivot
    FOR EACH ROW
    BEGIN
        IF :NEW.zacatek > CURRENT_DATE
        THEN
            :NEW.zacatek := CURRENT_DATE;
        END IF;
        IF :NEW.konec is not null
        THEN
            IF :NEW.konec > CURRENT_DATE
            THEN
                :NEW.konec := CURRENT_DATE;
            END IF;
        END IF;
        IF :NEW.konec is not null
        THEN
            IF :NEW.zacatek > :NEW.konec
            THEN
                RAISE_APPLICATION_ERROR(-20001, 'Nespravná hodnota v tabulce zivot, život nemůže začít později než když skončí');
            END IF;
        END IF;
    END;


--
-- PROCEDURE
--

-- Procedura, která vypíše hostitele, které mají špatně zadané PSČ
-- tabulka: hostitel:
-- atribut: psc(int)
CREATE OR REPLACE PROCEDURE hostitele_spatne_psc as
CURSOR hostitele is select * from hostitel;

h hostitele%ROWTYPE;
BEGIN
    dbms_output.put_line('Hostitele se spatnym PSC : ');
    open hostitele;
        loop
           fetch hostitele  into h; --nacteni prvniho radku
           exit when hostitele%NOTFOUND;
           if not REGEXP_LIKE (h.psc,'^[0-9][0-9][0-9][0-9][0-9]$')
               then
               dbms_output.put_line('Hostitel: ' || h.jmeno || ' Vek: ' ||  h.vek || ' Pohlavi: ' || h.pohlavi || ' Jmeno pro kocku:' || h.jmeno_pro_kocku|| ' Adresa: ' || h.ulice || ' ' || h.cislo_popisne );
               dbms_output.put_line(' SPATNE PSC: '|| h.psc );
            end if;
        end loop;
    CLOSE hostitele;
end;

-- Procedura, která vypíše jméno a rasu první kočky
-- tabulka: kocka, rasa
CREATE OR REPLACE PROCEDURE prvni_kocka IS
    prvni kocka.id%type := 1;
    k_jmeno kocka.hlavni_jmeno%type;
    k_rasa rasa.nazev%type;
BEGIN
    SELECT k.hlavni_jmeno, r.nazev INTO k_jmeno, k_rasa
    FROM kocka k LEFT JOIN rasa r ON k.rasa = r.nazev
    WHERE k.id = prvni;
    dbms_output.put_line('Jmeno prvni kocky: ' || k_jmeno);
    dbms_output.put_line('Rasa prvni kocky: ' || k_rasa);
EXCEPTION
    WHEN no_data_found THEN
        dbms_output.put_line('Prvni kocka neni v databazi');
END;


-- INDEX is last


--
-- Add PRIMARY KEY
--
ALTER TABLE kocka ADD CONSTRAINT PK_kocka PRIMARY KEY (id);
ALTER TABLE hostitel ADD CONSTRAINT PK_hostitel PRIMARY KEY (id);
ALTER TABLE rasa ADD CONSTRAINT PK_rasa PRIMARY KEY (nazev);
ALTER TABLE zivot ADD CONSTRAINT PK_zivot PRIMARY KEY (id);
ALTER TABLE vyskyt ADD CONSTRAINT PK_vyskyt PRIMARY KEY (id);
ALTER TABLE teritorium ADD CONSTRAINT PK_teritorium PRIMARY KEY(id);
ALTER TABLE vec ADD CONSTRAINT PK_vec PRIMARY KEY(id);
ALTER TABLE vlastnictvi ADD  CONSTRAINT PK_vlastnictvi PRIMARY KEY(id);
ALTER TABLE propujcka ADD CONSTRAINT PK_propujcka PRIMARY KEY(id);


--
-- Add FOREIGN KEY
--
ALTER TABLE kocka ADD CONSTRAINT FK_kocka_rasa FOREIGN KEY (rasa) REFERENCES rasa;
ALTER TABLE hostitel ADD CONSTRAINT FK_hostitel_kocka FOREIGN KEY (kocka) REFERENCES kocka;
ALTER TABLE hostitel ADD CONSTRAINT FK_hostitel_preferovana_rasa FOREIGN KEY (preferovana_rasa) REFERENCES rasa;
ALTER TABLE zivot ADD CONSTRAINT FK_zivot_kocka FOREIGN KEY (kocka) REFERENCES kocka ON DELETE CASCADE;
ALTER TABLE zivot ADD CONSTRAINT FK_zivot_teritorium FOREIGN KEY (teritorium) REFERENCES teritorium ON DELETE CASCADE;
ALTER TABLE vyskyt ADD CONSTRAINT FK_vyskyt_kocka FOREIGN KEY (kocka) REFERENCES kocka ON DELETE CASCADE;
ALTER TABLE vyskyt ADD CONSTRAINT FK_vyskyt_teritorium FOREIGN KEY (teritorium) REFERENCES teritorium ON DELETE CASCADE;
ALTER TABLE vec ADD CONSTRAINT FK_vec_teritorium FOREIGN KEY (teritorium) REFERENCES teritorium ON DELETE CASCADE;
ALTER TABLE vlastnictvi ADD CONSTRAINT  FK_vlastnictvi_vec FOREIGN KEY (vec) REFERENCES vec ON DELETE CASCADE;
ALTER TABLE vlastnictvi ADD CONSTRAINT FK_vlastnictvi_kocka FOREIGN KEY (kocka) REFERENCES kocka ON DELETE CASCADE;
ALTER TABLE propujcka ADD CONSTRAINT FK_propujcka_vlastnictvi FOREIGN KEY (vlastnictvi) REFERENCES vlastnictvi ON DELETE CASCADE;
ALTER TABLE propujcka ADD CONSTRAINT FK_propujcka_hostitel FOREIGN KEY (hostitel) REFERENCES hostitel ON DELETE CASCADE;


--
-- INSERT data
--
INSERT INTO rasa (nazev, barva_oci, puvod, max_delka_tesaku)
VALUES ('Turecká angora', 'ČERNÁ', 'Turecko', 20);
INSERT INTO rasa (nazev, barva_oci, puvod, max_delka_tesaku)
VALUES ('Birma', 'ZELENÁ', 'Barma', 14);
INSERT INTO rasa (nazev, barva_oci, puvod, max_delka_tesaku)
VALUES ('Ragdoll', 'ČERVENÁ', 'USA', 32);
INSERT INTO rasa (nazev, barva_oci, puvod, max_delka_tesaku)
VALUES ('Perská kočka', 'ZELENÁ', 'Írán', 22);
INSERT INTO rasa (nazev, barva_oci, puvod, max_delka_tesaku)
VALUES ('Sibiřská kočka', 'ČERNÁ', 'Rusko', 11);

INSERT INTO kocka (hlavni_jmeno, vzorek_kuze, barva_srsti, rasa)
VALUES ('Jonatán', 'VZOREK1', 'ČERVENÁ', 'Turecká angora');
INSERT INTO kocka (hlavni_jmeno, vzorek_kuze, barva_srsti, rasa)
VALUES ('Eddie', 'VZOREK2', 'ZELENÁ', 'Ragdoll');
INSERT INTO kocka (hlavni_jmeno, vzorek_kuze, barva_srsti, rasa)
VALUES ('Gréta', 'VZOREK3', 'MODRÁ', 'Ragdoll');
INSERT INTO kocka (hlavni_jmeno, vzorek_kuze, barva_srsti, rasa)
VALUES ('Elvis', 'VZOREK4', 'ZELENÁ', 'Birma');
INSERT INTO kocka (hlavni_jmeno, vzorek_kuze, barva_srsti, rasa)
VALUES ('Gordon', 'VZOREK5', 'ČERNÁ', 'Sibiřská kočka');

INSERT INTO hostitel (jmeno, vek, pohlavi, jmeno_pro_kocku, ulice, cislo_popisne, mesto, psc, kocka, preferovana_rasa)
VALUES ('Petr', 30, 'Muž', 'Fous', 'Modrá', 8, 'Brno', 123456, 1, 'Turecká angora');
INSERT INTO hostitel (jmeno, vek, pohlavi, jmeno_pro_kocku, ulice, cislo_popisne, mesto, psc, kocka,  preferovana_rasa)
VALUES ('Vašek', 25, 'Muž', 'Tlapka', 'Vratimovká', 15, 'Ostrava', 45612, 2, 'Birma');
INSERT INTO hostitel (jmeno, vek, pohlavi, jmeno_pro_kocku, ulice, cislo_popisne, mesto, psc, kocka, preferovana_rasa)
VALUES ('Aneta', 33, 'Žena', 'Morris', 'Cholevova', 12, 'Ostrava', 54612, 3, 'Perská kočka');
INSERT INTO hostitel (jmeno, vek, pohlavi, jmeno_pro_kocku, ulice, cislo_popisne, mesto, psc, kocka, preferovana_rasa)
VALUES ('Adéla', 28, 'Žena', 'Whiskey', 'Dlouhá', 1 , 'Praha', 10001, 1, 'Ragdoll');
INSERT INTO hostitel (jmeno, vek, pohlavi, jmeno_pro_kocku, ulice, cislo_popisne, mesto, psc, kocka, preferovana_rasa)
VALUES ('Jakub', 60, 'Muž', 'Charlota', 'Široká', 2, 'Praha', 10001, 5, 'Sibiřská kočka');
INSERT INTO hostitel (jmeno, vek, pohlavi, jmeno_pro_kocku, ulice, cislo_popisne, mesto, psc, kocka, preferovana_rasa)
VALUES ('Milan', 60, 'Muž', 'Mňauko', 'Božetěchova', 23, 'Olomouc', 10001, 4, 'Birma');

INSERT INTO teritorium(druh, kapacita_kocek, velikost)
VALUES ('Hnízdní',5,1000);
INSERT INTO teritorium(druh, kapacita_kocek, velikost)
VALUES ('Rodinná',4,100);
INSERT INTO teritorium(druh, kapacita_kocek, velikost)
VALUES ('Skupinová',7,1300);
INSERT INTO teritorium(druh, kapacita_kocek, velikost)
VALUES ('Inviduální',1,10);
INSERT INTO teritorium(druh, kapacita_kocek, velikost)
VALUES ('Komunistická',1948,6666);


INSERT INTO zivot (stav, zacatek, konec, zpusob_smrti, kocka, teritorium)
VALUES ('Žije', TO_TIMESTAMP('12.12.2020 08:13:33', 'dd.mm.yyyy HH24:MI:SS'), NULL, NULL, 1, NULL);
INSERT INTO zivot (stav, zacatek, konec, zpusob_smrti, kocka, teritorium)
VALUES ('Nežije', TO_TIMESTAMP('30.11.2020 12:22:22', 'dd.mm.yyyy HH24:MI:SS'),
    TO_TIMESTAMP('12.12.2020 08:13:32', 'dd.mm.yyyy HH24:MI:SS'), 'Utopeni', 1, 4);
INSERT INTO zivot (stav, zacatek, konec, zpusob_smrti, kocka, teritorium)
VALUES ('Žije', TO_TIMESTAMP('13.10.2019 15:54:59', 'dd.mm.yyyy HH24:MI:SS'), NULL, NULL, 4, NULL);
INSERT INTO zivot (stav, zacatek, konec, zpusob_smrti, kocka, teritorium)
VALUES ('Žije', TO_TIMESTAMP('20.11.2016 12:12:12', 'dd mm.yyyy HH24:MI:SS'), NULL, NULL, 3, NULL);
INSERT INTO zivot (stav, zacatek, konec, zpusob_smrti, kocka, teritorium)
VALUES ('Žije', TO_TIMESTAMP('3.8.2015 15:12:13', 'dd.mm.yyyy HH24:MI:SS'), NULL, NULL, 2, NULL);
INSERT INTO zivot (stav, zacatek, konec, zpusob_smrti, kocka, teritorium)
VALUES ('Žije', TO_TIMESTAMP('3.8.2015 15:12:13', 'dd.mm.yyyy HH24:MI:SS'), NULL, NULL, 5, NULL);

INSERT INTO vyskyt(od, do, kocka, teritorium)
VALUES (TO_TIMESTAMP('3.8.2015 15:12:13', 'dd.mm.yyyy HH24:MI:SS'),NULL, 4, 5);
INSERT INTO vyskyt(od, do, kocka, teritorium)
VALUES (TO_TIMESTAMP('12.12.2020 08:13:33', 'dd.mm.yyyy HH24:MI:SS'),
    TO_TIMESTAMP('18.12.2020 09:13:33', 'dd.mm.yyyy HH24:MI:SS'), 5, 5);
INSERT INTO vyskyt(od, do, kocka, teritorium)
VALUES (TO_TIMESTAMP('20.11.2016 12:12:12', 'dd.mm.yyyy HH24:MI:SS'),NULL, 3, 4);
INSERT INTO vyskyt(od, do, kocka, teritorium)
VALUES (TO_TIMESTAMP('3.8.2015 15:12:13', 'dd.mm.yyyy HH24:MI:SS'), NULL, 2, 1);
INSERT INTO vyskyt(od, do, kocka, teritorium)
VALUES (TO_TIMESTAMP('18.12.2020 09:13:33', 'dd.mm.yyyy HH24:MI:SS'),
    TO_TIMESTAMP('20.12.2020 02:53:12', 'dd.mm.yyyy HH24:MI:SS'), 1, 1);

INSERT INTO vec(druh,pocet,teritorium)
VALUES('Umělá myš',1,2);
INSERT INTO vec(druh,pocet,teritorium)
VALUES('Klubíčko',5,1);
INSERT INTO vec(druh,pocet,teritorium)
VALUES('Pilník',2,3);
INSERT INTO vec(druh,pocet,teritorium)
VALUES('Zrcadlo',42,4);
INSERT INTO vec(druh,pocet,teritorium)
VALUES('Srp',10,5);
INSERT INTO vec(druh,pocet,teritorium)
VALUES('Kladivo',10,5);

INSERT INTO vlastnictvi(od,do,vec,kocka)
VALUES(TO_TIMESTAMP('4.12.2020 23:59:59', 'dd.mm.yyyy HH24:MI:SS'),
    TO_TIMESTAMP('8.8.2022 23:59:59', 'dd.mm.yyyy HH24:MI:SS'),1,1);
INSERT INTO vlastnictvi(od,do,vec,kocka)
VALUES(TO_TIMESTAMP('23.11.2018 01:01:33', 'dd.mm.yyyy HH24:MI:SS'),
    TO_TIMESTAMP('6.6.2020 23:59:59', 'dd.mm.yyyy HH24:MI:SS'),2,2);
INSERT INTO vlastnictvi(od,do,vec,kocka)
VALUES(TO_TIMESTAMP('30.12.2020 23:59:59', 'dd.mm.yyyy HH24:MI:SS'),
    TO_TIMESTAMP('30.12.2025 23:59:59', 'dd.mm.yyyy HH24:MI:SS'),1,3);
INSERT INTO vlastnictvi(od,do,vec,kocka)
VALUES(TO_TIMESTAMP('25.4.2018 16:00:53', 'dd.mm.yyyy HH24:MI:SS'),
    TO_TIMESTAMP('11.11.2022 23:59:59', 'dd.mm.yyyy HH24:MI:SS'),5,4);
INSERT INTO vlastnictvi(od,do,vec,kocka)
VALUES(TO_TIMESTAMP('17.3.2011 00:00:00', 'dd.mm.yyyy HH24:MI:SS'),
    TO_TIMESTAMP('18.3.2022 00:00:00', 'dd.mm.yyyy HH24:MI:SS'),5,5);

INSERT INTO propujcka(od,do,vlastnictvi,hostitel)
VALUES(TO_TIMESTAMP('17.3.2021 00:00:00', 'dd.mm.yyyy HH24:MI:SS'),
    TO_TIMESTAMP('11.3.2022 00:00:00', 'dd.mm.yyyy HH24:MI:SS'),1,1);
INSERT INTO propujcka(od,do,vlastnictvi,hostitel)
VALUES(TO_TIMESTAMP('11.11.2020 11:23:00', 'dd.mm.yyyy HH24:MI:SS'),
    TO_TIMESTAMP('11.11.2022 11:23:00', 'dd.mm.yyyy HH24:MI:SS'),1,1);
INSERT INTO propujcka(od,do,vlastnictvi,hostitel)
VALUES(TO_TIMESTAMP('18.3.2015 16:06:00', 'dd.mm.yyyy HH24:MI:SS'),
    TO_TIMESTAMP('18.3.2022 16:06:00', 'dd.mm.yyyy HH24:MI:SS'),1,1);
INSERT INTO propujcka(od,do,vlastnictvi,hostitel)
VALUES(TO_TIMESTAMP('17.3.2011 00:00:00', 'dd.mm.yyyy HH24:MI:SS'),
    TO_TIMESTAMP('6.6.2021 00:00:00', 'dd.mm.yyyy HH24:MI:SS'),1,1);
INSERT INTO propujcka(od,do,vlastnictvi,hostitel)
VALUES(TO_TIMESTAMP('24.10.2019 16:15:14', 'dd.mm.yyyy HH24:MI:SS'),
    TO_TIMESTAMP('25.10.2019 16:15:14', 'dd.mm.yyyy HH24:MI:SS'),1,1);


COMMIT;


--
-- SELECT
--
-- SELECT * FROM kocka;
-- SELECT * FROM rasa;
-- SELECT * FROM hostitel;
-- SELECT * FROM zivot;
-- SELECT * FROM vyskyt;
-- SELECT * FROM teritorium;
-- SELECT * FROM vec;
-- SELECT * FROM propujcka;
-- SELECT * FROM vlastnictvi;

/*
-- Vyhledá kočky a kolik mají služebnictva.
SELECT k.hlavni_jmeno as "Kočka", COUNT(h.jmeno) as "Počet služebnictva"
FROM kocka k LEFT JOIN hostitel h ON k.id = h.kocka
GROUP BY k.hlavni_jmeno;

-- Vyhledá ID a druh teritorií, ve kterých je alespoň jedna věc minimálně 5 krát.
SELECT t.id as "ID teritoria", t.druh as "Druh teritoria"
FROM teritorium t
WHERE EXISTS (SELECT id FROM vec v WHERE v.teritorium = t.id AND v.pocet >= 5);

-- Sečtěte počet koček, které se vyskytují nebo vyskytovali v teritoriu s názvem "Komunistická"
SELECT count(hlavni_jmeno) AS Počet_koček
FROM KOCKA INNER JOIN VYSKYT USING(id)
WHERE teritorium IN (
    SELECT id
    FROM TERITORIUM
    WHERE druh = 'Komunistická'
);

-- Seraď rasy koček podle oblibeností hostitelů a vypište země původu a body jejich oblíbenosti
SELECT MAX(H.preferovana_rasa) AS Název_rasy,R.puvod AS Země_půvou,COUNT(preferovana_rasa) AS body_oblíbenosti
FROM RASA R LEFT JOIN HOSTITEL H ON R.nazev = H.preferovana_rasa
GROUP BY H.preferovana_rasa,R.puvod;

-- Vyberte kočky, které žijí v teritoriu od roku 2020 a vypište druh teritoria, ve kterém je kočka a datum jejich nastěhování
SELECT k.hlavni_jmeno AS Jméno_kočky,t.druh AS Druh_teritoria,v.od AS Datum_přistěhování
FROM kocka k INNER JOIN vyskyt v  ON k.id = v.id INNER JOIN teritorium t ON v.id = t.id
WHERE v.od >= DATE '2020-01-01'
*/

-- Vytvoření explicit "index"
-- + dotaz SQL
--  lze kombinovat s "explain plan"
--   spojení 2 tabulek, agregační funkce, group by

-- dotaz: počet koček, které umřeli
-- tabulka: kočka, život


--DROP INDEX index_pocet_mrtvych_kocek;

EXPLAIN PLAN FOR
    SELECT count(*) as pocet_mrtvych_kocek
    FROM kocka k left join zivot z on k.id = z.id
    WHERE z.konec is not null
    GROUP BY z.konec;
SELECT plan_table_output FROM table (dbms_xplan.display());

CREATE INDEX index_pocet_mrtvych_kocek ON zivot(konec);

-- Volani procedur:
BEGIN
  hostitele_spatne_psc();
END;

BEGIN
    prvni_kocka();
END;


-- definice přístupových práv k databázovým objektům pro druhého člena týmu
-- TABLES:
GRANT INSERT, UPDATE, SELECT ON kocka TO xsechr00;
GRANT INSERT, UPDATE, SELECT ON rasa TO xsechr00;
GRANT INSERT, UPDATE, SELECT ON hostitel TO xsechr00;
GRANT INSERT, UPDATE, SELECT ON zivot TO xsechr00;
GRANT INSERT, UPDATE, SELECT ON vyskyt TO xsechr00;
GRANT INSERT, UPDATE, SELECT ON teritorium TO xsechr00;
GRANT INSERT, UPDATE, SELECT ON propujcka TO xsechr00;
GRANT INSERT, UPDATE, SELECT ON vlastnictvi TO xsechr00;

-- Procedurs:
GRANT EXECUTE ON hostitele_spatne_psc TO xsechr00;
GRANT EXECUTE ON prvni_kocka TO xsechr00;
