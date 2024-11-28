DROP TABLE IF EXISTS Università CASCADE;
CREATE TABLE Università(
	Nome varchar(50),
	Regione varchar(21) NOT NULL,
	Città varchar(40) NOT NULL,
	Posti_disponibili integer NOT NULL CONSTRAINT posti_positivi CHECK(Posti_disponibili > 0),
	Via varchar(30) NOT NULL,
	Cap char(5) NOT NULL,
	Civico varchar(5) NOT NULL,
	CONSTRAINT pk_università PRIMARY KEY(Nome),
	UNIQUE(Via,Cap,Civico)
);

DROP TABLE IF EXISTS Aula CASCADE;
CREATE TABLE Aula(
	Codice_aula serial,
	Nome varchar(20) NOT NULL,
	Numero_posti integer NOT NULL,
	Edificio varchar(30) NOT NULL,
	Università varchar(50) NOT NULL,
	CONSTRAINT pk_aula PRIMARY KEY(Codice_aula),
	CONSTRAINT fk_aula_università FOREIGN KEY(Università) references Università(Nome) on update cascade on delete restrict deferrable initially deferred,
	UNIQUE(Nome,Edificio,Università)
);

DROP TABLE IF EXISTS Persona CASCADE;
CREATE TABLE Persona(
	Codice_fiscale char(16),
	Nome varchar(120) NOT NULL,
	Cognome varchar(50) NOT NULL,
	Matricola integer NOT NULL,
	Sesso char NOT NULL,
	Data_di_nascita date NOT NULL,
	Città_di_nascita varchar(40) NOT NULL,
	Email varchar(150) NOT NULL UNIQUE,
	Dipartimento varchar(30) NOT NULL,
	Stato varchar(10) NOT NULL DEFAULT 'Libero',
	Università varchar(50) NOT NULL,
	CONSTRAINT fk_persona_università FOREIGN KEY(Università) references Università(Nome) on update cascade on delete restrict deferrable initially deferred,
    CONSTRAINT pk_persona PRIMARY KEY(Codice_fiscale),
	UNIQUE(Matricola,Università),
	CONSTRAINT check_email CHECK (Email LIKE '%_@__%.__%'),
	CONSTRAINT check_data_nascita CHECK (Data_di_nascita > '1930-01-01' and Data_di_nascita <  CURRENT_DATE-17*365)
);
 
DROP DOMAIN IF EXISTS Settimana cascade;
CREATE DOMAIN Settimana as varchar(9)
CHECK (VALUE = 'Lunedì' or VALUE = 'Martedì' or VALUE = 'Mercoledì' or VALUE = 'Giovedì' or VALUE = 'Venerdì')
NOT NULL;

DROP TABLE IF EXISTS Calendario CASCADE;
CREATE TABLE Calendario(
	Codice_attività serial,
	Orario_inizio time NOT NULL,
	Orario_fine time NOT NULL,
	Giorno_settimana Settimana,
	Nome varchar(30) NOT NULL,
	Semestre integer NOT NULL,
	Aula integer NOT NULL,
	CONSTRAINT pk_calendario PRIMARY KEY(Codice_attività),
	CONSTRAINT check_giorno_settimana CHECK (Giorno_settimana != 'Sabato' and Giorno_settimana !='Domenica'),
	CONSTRAINT check_durata CHECK (Orario_fine > Orario_inizio),
	CONSTRAINT check_semestre CHECK(Semestre = 1 or Semestre = 2),
	CONSTRAINT fk_calendario_aula FOREIGN KEY(Aula) references Aula(Codice_aula) on update cascade on delete set null
);

DROP TABLE IF EXISTS Professore CASCADE;
CREATE TABLE Professore(
	Persona char(16),
	Titolo varchar(50) NOT NULL,
	Numero_ufficio integer NOT NULL,
	CONSTRAINT pk_professore PRIMARY KEY(Persona),
	CONSTRAINT fk_professore_persona FOREIGN KEY(Persona) references Persona(Codice_fiscale) on update cascade on delete restrict deferrable initially deferred
);

DROP TABLE IF EXISTS Studente CASCADE;
CREATE TABLE Studente(
	Persona char(16),
	Anno_corso integer NOT NULL,
	Curriculum varchar(30) NOT NULL,
	Anno_iscrizione integer NOT NULL,
	CONSTRAINT pk_studente PRIMARY KEY(Persona),
	CONSTRAINT fk_studente_persona FOREIGN KEY(Persona) references Persona(Codice_fiscale) on update cascade on delete restrict deferrable initially deferred
	
);

DROP TABLE IF EXISTS Attività CASCADE;
CREATE TABLE Attività(
	Data_svolgimento date,
	Attività_calendario integer,
	Modalità varchar(11) NOT NULL DEFAULT 'Presenza',
	Capienza_predisposta integer NOT NULL,
	Capienza_reale integer NOT NULL,
	Professore char(16) NOT NULL,
	CONSTRAINT pk_attività PRIMARY KEY(Data_svolgimento,Attività_calendario),
	CONSTRAINT fk_attività_calendario FOREIGN KEY(Attività_calendario) references Calendario(Codice_attività) on update cascade on delete restrict,
	CONSTRAINT check_capienza CHECK(Capienza_predisposta > 0 AND Capienza_reale > 0 AND Capienza_reale >= Capienza_predisposta),
	CONSTRAINT check_attività_periodo CHECK(Data_svolgimento >= CURRENT_DATE), 
	CONSTRAINT fk_attività_professore FOREIGN KEY(Professore) references Professore(Persona) on delete restrict on update cascade
);

DROP TABLE IF EXISTS Prenotazione CASCADE;
CREATE TABLE Prenotazione(
	Studente char(16),
	Data_attività date,
	Attività integer,
	CONSTRAINT pk_prenotazione PRIMARY KEY(Studente,Data_attività,Attività),
	CONSTRAINT fk_prenotazione_persona FOREIGN KEY(Studente) references Studente(Persona) on update cascade on delete cascade,
	CONSTRAINT fk_prenotazione_attività FOREIGN KEY(Data_attività,Attività) references Attività(Data_svolgimento,Attività_calendario) on update cascade on delete cascade
);

DROP TABLE IF EXISTS Positivo CASCADE;
CREATE TABLE Positivo(
	ID_caso serial,
	Ospedalizzato boolean NOT NULL DEFAULT False,
	Sintomatico boolean NOT NULL DEFAULT False,
	Data_positività date NOT NULL,
	Persona char(16) NOT NULL,
	CONSTRAINT pk_positivo PRIMARY KEY(ID_caso),
	CONSTRAINT fk_positivo_persona FOREIGN KEY(Persona) references Persona(Codice_fiscale) on update cascade on delete cascade,
	UNIQUE(Data_positività,Persona),
	CONSTRAINT check_data_positività CHECK (Data_positività < (CURRENT_DATE+1))
);

DROP TABLE IF EXISTS Vaccino CASCADE;
CREATE TABLE Vaccino(
	Nome varchar(9),
	CONSTRAINT pk_vaccino PRIMARY KEY(Nome)
);

DROP TABLE IF EXISTS Attestato_positivo CASCADE;
CREATE TABLE Attestato_positivo(
	ID_caso integer,
	Vaccino varchar(9),
	Data_somministrazione date NOT NULL,
	CONSTRAINT pk_attestato_positivo PRIMARY KEY(ID_caso,Vaccino,Data_somministrazione),
	CONSTRAINT fk_attestato_positivo_positivo FOREIGN KEY(ID_caso) references Positivo(ID_caso) on update cascade on delete cascade,
	CONSTRAINT fk_attestato_positivo_vaccino FOREIGN KEY(Vaccino) references Vaccino(Nome) on update restrict on delete restrict,
	CONSTRAINT check_data_somministrazione_positivo CHECK (Data_somministrazione < (CURRENT_DATE+1))
);

DROP TABLE IF EXISTS Contatto CASCADE;
CREATE TABLE Contatto(
	ID_caso serial,
	Data_contatto date NOT NULL default CURRENT_DATE,
	Persona char(16) NOT NULL,
	CONSTRAINT pk_contatto PRIMARY KEY(ID_caso),
	CONSTRAINT fk_contatto_persona FOREIGN KEY(Persona) references Persona(Codice_fiscale) on update cascade on delete cascade,
	UNIQUE(Data_contatto,Persona),
	CONSTRAINT check_data_contatto CHECK (Data_contatto < (CURRENT_DATE+1))
);

DROP TABLE IF EXISTS Attestato_contatto CASCADE;
CREATE TABLE Attestato_contatto(
	ID_caso integer,
	Vaccino varchar(9),
	Data_somministrazione date,
	CONSTRAINT pk_attestato_contatto PRIMARY KEY(ID_caso,Vaccino,Data_somministrazione),
	CONSTRAINT fk_attestato_contatto_contatto FOREIGN KEY(ID_caso) references Contatto(ID_caso) on update cascade on delete cascade,
	CONSTRAINT fk_attestato_contatto_vaccino FOREIGN KEY(Vaccino) references Vaccino(Nome) on update restrict on delete restrict,
	CONSTRAINT check_data_somministrazione_contatto CHECK (Data_somministrazione < (CURRENT_DATE+1))
);


DROP TABLE IF EXISTS Tampone CASCADE;
CREATE TABLE Tampone(
	Codice_CUN serial,
	Data date NOT NULL,
	Orario time NOT NULL,
	Risultato char(8) NOT NULL,
	Tipologia varchar(10) NOT NULL,
	Caso_riferimento integer,
	Contatto_riferimento integer,
	CONSTRAINT pk_tampone PRIMARY KEY(Codice_CUN),
	CONSTRAINT fk_tampone_positivo FOREIGN KEY(Caso_riferimento) references Positivo(ID_caso) on update cascade on delete cascade deferrable initially deferred,
	CONSTRAINT fk_tampone_contatto FOREIGN KEY(Contatto_riferimento) references Contatto(ID_caso) on update cascade on delete cascade,
	CONSTRAINT check_data_tampone CHECK (Data < (CURRENT_DATE+1))
);

/*NOTA: Nonostante alcuni attributi siano seriali, li abbiamo inseriti manualmente e non attraverso la modalità DEFAULT per facilitarci l'inserimento di altre tabelle che 
referenziavano questi attributi. Inoltre non è presente il popolamento delle tabelle Contatto e Attestato Contatto, dato che i primi vengono inseriti attraverso la query di
tracciamento dei contatti e gli attestati vengono caricati in seguito alla segnalazione del contatto.
Nel file di popolamento ci sono alcuni script a seconda del giorno della settimana in cui viene visto il progetto. Questo perchè nel nostro database il giorno delle attività,
deve coincidere con il giorno della settimana della schedulazione nel calendario, e dato che non possiamo inserire attività passate, abbiamo pensato di creare 5 script diversi
a seconda del giorno della settimana in cui si sta controllando. */
BEGIN TRANSACTION;
INSERT INTO Università values ('Università degli studi di Salerno', 'Campania', 'Salerno', 30000, 'Via Giovanni Paolo', '84084', '132');
INSERT INTO Università values ('Università degli studi di Napoli', 'Campania', 'Napoli', 10000, 'Corso Umberto', '80138', '40');
INSERT INTO Università values ('Politecnico di Milano','Lombardia','Milano',55000,'Piazza Leonardo Da Vinci','20133','32');
INSERT INTO Università values ('Università degli studi di Firenze','Toscana','Firenze',30000,'Piazza San Marco','50121','4');
INSERT INTO Università values ('Politecnico di Torino','Piemonte','Torino',60000,'Corso Duca Degli Abruzzi','86100','16');

--PERSONE Università degli studi di Salerno
INSERT INTO Persona values ('TRNRMN00T52A783A','Ramona','Tarantino',1612704902,'F','2000-12-12','Benevento','rtarantino7@unisa.it','Ingegneria Informatica','Libero','Università degli studi di Salerno');
INSERT INTO Persona values ('MLNMRC00D04C361Z','Marco','Milone',1612783940,'M','2000-12-26','Cava de tirreni','mmilone15@unisa.it','Ingegneria Informatica','Libero','Università degli studi di Salerno');
INSERT INTO Persona values ('VNDFNC00D68G964C','Francesca','Venditti',1612783640,'F','2000-04-28','Pozzuoli','fvenditti1@unisa.it','Ingegneria Informatica','Libero','Università degli studi di Salerno');
INSERT INTO Persona values ('NTNGNN01B21A399J','Giovanni','Intonti',1612783899,'M','2001-02-21','Ariano Irpino','gintonti@unisa.it','Ingegneria Informatica','Libero','Università degli studi di Salerno');
INSERT INTO Persona values ('VTLLCU98B16F839G','Luca','Vitale',1612704910,'M','1998-02-16','Napoli','lvitale9@unisa.it','Farmacia','Libero','Università degli studi di Salerno');
INSERT INTO Persona values ('MNZLSE02L53B963F','Elisa','Manzo',1612783789,'F','2002-07-03','Caserta','emanzo8@unisa.it','Lettere','Libero','Università degli studi di Salerno');
INSERT INTO Persona values ('DLCVCN97L05H703I','Vincenzo','De Luca',1612783543,'M','1997-07-05','Salerno','vdeluca@unisa.it','Giurisprudenza','Libero','Università degli studi di Salerno');
INSERT INTO Persona values ('MRCMTT99L17A509P','Matteo','Marcone',1612783874,'M','1999-07-17','Avellino','mmarcone@unisa.it','Economia','Libero','Università degli studi di Salerno');
INSERT INTO Persona values ('CSNRKE00C70F839Y','Erika','Cusano',1612783876,'F','2000-03-30','Napoli','ecusano@unisa.it','Matematica','Libero','Università degli studi di Salerno');
INSERT INTO Persona values ('CSCGAI00D67H703B','Gaia','Casci',1612783664,'F','2000-04-27','Salerno','gcasci@unisa.it','Economia','Libero','Università degli studi di Salerno');

INSERT INTO Persona values ('GTAMTT60L17H703S','Matteo','Gaeta',1000000000,'M','1960-05-16','Salerno','mgaeta@unisa.it','Ingegneria Informatica','Libero','Università degli studi di Salerno');
INSERT INTO Persona values ('GRCGPP75D08H703K','Giuseppe','Greco',1000000001,'M','1975-04-08','Salerno','ggreco@unisa.it','Fisica','Libero','Università degli studi di Salerno');
INSERT INTO Persona values ('MNZRNN70A48F839L','Rosanna','Manzo',1000000002,'F','1972-04-27','Napoli','rmanzo@unisa.it','Economia','Libero','Università degli studi di Salerno');

--PERSONE Università degli studi di Napoli
INSERT INTO Persona values ('RSSMTT00S12F839U','Matteo','Rossi',1000099999,'M','2000-12-11','Napoli','mrossi@unina.it','Ingegneria Informatica','Libero','Università degli studi di Napoli');
INSERT INTO Persona values ('VRDMRC00S12F839T','Marco','Verdi',1000099998,'M','2000-12-22','Torre del Greco','mverdi@unina.it','Ingegneria Chimica','Libero','Università degli studi di Napoli');
INSERT INTO Persona values ('NREGPP00S12B990R','Giuseppe','Neri',1000099997,'M','2000-04-18','Casoria','gneri@unina.it','Ingegneria Informatica','Libero','Università degli studi di Napoli');
INSERT INTO Persona values ('FRRLLN00S52A064B','Liliana','Ferrari',1000099910,'F','2001-02-28','Afragola','lferrari8@unina.it','Ingegneria Informatica','Libero','Università degli studi di Napoli');
INSERT INTO Persona values ('RSSFNC01S52F839H','Franca','Russo',1000099911,'F','1998-02-11','Napoli','frusso1@unina.it','Farmacia','Libero','Università degli studi di Napoli');
INSERT INTO Persona values ('RMNDBR98A41B963Z','Debora','Romano',1000099912,'F','2002-07-09','Caserta','dromano998@unina.it','Farmacia','Libero','Università degli studi di Napoli');
INSERT INTO Persona values ('DLCLNR97A41B963J','Eleonora','De Luca',1000099913,'F','1997-07-05','Ercolano','edeluca@unina.it','Matematica','Libero','Università degli studi di Napoli');
INSERT INTO Persona values ('FNTMTT99A01A509U','Matteo','Fontana',1000099914,'M','1999-07-12','Avellino','mfontana3@unina.it','Economia','Libero','Università degli studi di Napoli');
INSERT INTO Persona values ('CSTLCU00A01H703F','Luca','Costa',1000099915,'M','2000-03-23','Acerra','lcosta@unina.it','Matematica','Libero','Università degli studi di Napoli');
INSERT INTO Persona values ('DFLPLA00A01H703Q','Paolo','De Filippo',1000099916,'M','2000-04-21','Salerno','pdefilippo6@unina.it','Economia','Libero','Università degli studi di Napoli');

INSERT INTO Persona values ('PACRCC60L17H703S','Riccardo','Pace',1000000003,'M','1965-07-19','Salerno','rpace@unina.it','Ingegneria Informatica','Libero','Università degli studi di Napoli');
INSERT INTO Persona values ('MORGSP75D08H703K','Giuseppe','Moro',1000000004,'M','1975-03-08','Benevento','gmoro@unina.it','Matematica','Libero','Università degli studi di Napoli');
INSERT INTO Persona values ('MNCMNN70A48F839T','Marianna','Mancini',1000000005,'F','1978-10-27','Napoli','mmancini@unina.it','Economia','Libero','Università degli studi di Napoli');

--PERSONE Politecnico di Milano
INSERT INTO Persona values ('TFNHRD63R03B217K','Lorenzo','Colombo',1002222222,'M','2000-12-11','Milano','lcolombo@polimi.it','Ingegneria Informatica','Libero','Politecnico di Milano');
INSERT INTO Persona values ('MLKBZR68M42B350G','Gabriele','Sala',1002222223,'M','2001-10-12','Milano','gsala@polimi.it','Ingegneria Chimica','Libero','Politecnico di Milano');
INSERT INTO Persona values ('ZTQTFR56A58L697L','Tommaso','Villa',1002222224,'M','2002-09-10','Brescia','tvilla@polimi.it','Ingegneria Industriale','Libero','Politecnico di Milano');
INSERT INTO Persona values ('SWFRYF37B65A948O','Alessandro','Cattaneo',1002222225,'M','1999-08-09','Monza','acattaneo@polimi.it','Ingegneria Informatica','Libero','Politecnico di Milano');
INSERT INTO Persona values ('QVTDNZ40L07C348V','Edoardo','Brambilla',1002222226,'M','2000-07-20','Como','ebrambilla@polimi.it','Economia','Libero','Politecnico di Milano');
INSERT INTO Persona values ('YMCBTX40A41I605Z','Sofia','Rossi',1002222227,'F','1998-06-22','Milano','srossi22@polimi.it','Economia','Libero','Politecnico di Milano');
INSERT INTO Persona values ('VFCZLG94R66M271D','Aurora','Fumagalli',1002222228,'F','2002-05-30','Varese','afumagalli@polimi.it','Ingegneria Chimica','Libero','Politecnico di Milano');
INSERT INTO Persona values ('RTGMTL30P44G691C','Giulia','Riva',1002222229,'F','1996-04-12','Pavia','griva@polimi.it','Ingegneria Chimica','Libero','Politecnico di Milano');
INSERT INTO Persona values ('TQBMNN79D44G997S','Ginevra','Bianchi',1002222210,'F','1997-12-24','Cremona','gbianchi76@polimi.it','Economia','Libero','Politecnico di Milano');
INSERT INTO Persona values ('MDMPTN91M02F527H','Emma','Russo',1002222211,'F','2001-11-08','Mantova','erusso6@polimi.it','Economia','Libero','Politecnico di Milano');

INSERT INTO Persona values ('CSTPPY83B15E317O','Stefano','Palladino',1000000006,'M','1969-07-19','Monza','spalladino@polimi.it','Ingegneria Informatica','Libero','Politecnico di Milano');
INSERT INTO Persona values ('SNBZFC36C47H334A','Fabrizio','Ferrero',1000000007,'M','1971-07-18','Milano','fferrero2@polimi.it','Ingegneria Chimica','Libero','Politecnico di Milano');
INSERT INTO Persona values ('WPKRHT53L24L325A','Rossella','Caruso',1000000008,'F','1981-11-29','Roma','rcaruso@polimi.it','Economia','Libero','Politecnico di Milano');

--PERSONE Politecnico di Torino
INSERT INTO Persona values ('ZDYFHO27M61G582Y','Samuele','Gallo',1111133333,'M','2000-11-22','Torino','sgallo2@polito.it','Informatica','Libero','Politecnico di Torino');
INSERT INTO Persona values ('CSPDTM27E68E997W','Lorenzo','Rizzo',1111133334,'M','2001-10-26','Asti','lrizzo2@polito.it','Biologia','Libero','Politecnico di Torino');
INSERT INTO Persona values ('MJXHPZ53C69B591C','Riccardo','Santoro',1111133335,'M','2003-09-25','Cuneo','rsantoro1@polito.it','Informatica','Libero','Politecnico di Torino');
INSERT INTO Persona values ('VCYDLV34A25A761K','Matteo','Colombo',1111133336,'M','2002-07-25','Vercelli','mcolombo9@polito.it','Chimica','Libero','Politecnico di Torino');
INSERT INTO Persona values ('HPTLCS61M19C057F','Angelo','Lombardo',1111133337,'M','1999-02-24','Novara','alombardo1@polito.it','Chimica','Libero','Politecnico di Torino');
INSERT INTO Persona values ('PHGPAU98L18I747E','Greta','Colombo',1111133338,'F','1997-02-13','Biella','gcolombo88@polito.it','Informarica','Libero','Politecnico di Torino');
INSERT INTO Persona values ('PLCBDH40P25L755D','Chiara','Ricci',1111133339,'F','1998-03-15','Torino','cricci@polito.it','Ingegneria Civile','Libero','Politecnico di Torino');
INSERT INTO Persona values ('SLWBVR27D08C752K','Christiana','Vitali',1111133390,'F','2000-01-12','Torino','cvitali@polito.it','Ingegneria Civile','Libero','Politecnico di Torino');
INSERT INTO Persona values ('ZCPPMD67R46H475T','Domenica','Messina',1111133311,'F','2001-01-23','Asti','dmessina@polito.it','Informatica','Libero','Politecnico di Torino');
INSERT INTO Persona values ('KVXTLD66L08D027L','Enrica','Bucci',1111133312,'F','2000-05-22','Alessandria','ebucci@polito.it','Informatica','Libero','Politecnico di Torino');

INSERT INTO Persona values ('PDKDCX73P45B179E','Stefano','Proietti',1000000009,'M','1982-02-11','Torino','sproietti@polito.it','Informatica','Libero','Politecnico di Torino');
INSERT INTO Persona values ('VTRDJR62S23G136K','Marco','Boscolo',1000000010,'M','1983-01-18','Milano','mboscolo@polito.it','Ingegneria Civile','Libero','Politecnico di Torino');
INSERT INTO Persona values ('ZGCRRS55C11I991J','Francesca','Manca',1000000011,'F','1981-11-20','Asti','fmanca@polito.it','Chimica','Libero','Politecnico di Torino');

--PERSONE Università degli studi di Firenze
INSERT INTO Persona values ('HHDNZP30A03L026W','Emilio','Sanna',1234577777,'M','2000-11-22','Firenze','esanna@unifi.it','Filosofia','Libero','Università degli studi di Firenze');
INSERT INTO Persona values ('GSRLBB44L63I673Q','Ernesto','Savastano',1234577778,'M','2001-10-22','Grosseto','esavastano@unifi.it','Filosofia','Libero','Università degli studi di Firenze');
INSERT INTO Persona values ('ZNGZLN84A26H250W','Samuele','Lallo',1234577779,'M','2002-11-09','Pistoia','slallo@unifi.it','Lettere','Libero','Università degli studi di Firenze');
INSERT INTO Persona values ('BRECHS46P55C327X','Fabio','Tarantino',1234577745,'M','1999-12-02','Lucca','ftarantino@unifi.it','Lettere','Libero','Università degli studi di Firenze');
INSERT INTO Persona values ('RWVCFL74S45D408R','Federico','Foscolo',1234577744,'M','1999-10-12','Firenze','ffoscolo@unifi.it','Storia','Libero','Università degli studi di Firenze');
INSERT INTO Persona values ('CYGFCR46E06G458T','Federica','Pavesi',1234577733,'F','1996-04-21','Arezzo','fpavesi@unifi.it','Storia','Libero','Università degli studi di Firenze');
INSERT INTO Persona values ('BWDXBM96P02G566J','Annamaria','Cerise',1234577722,'F','1995-08-08','Arezzo','acerise@unifi.it','Storia','Libero','Università degli studi di Firenze');
INSERT INTO Persona values ('ZMMCST86C27E915S','Gaia','Carraro',1234577711,'F','2001-06-01','Roma','gcarraro@unifi.it','Sociologia','Libero','Università degli studi di Firenze');
INSERT INTO Persona values ('DKODKC48P04L032G','Flavia','Gramsci',1234577734,'F','2000-04-02','Pavia','fgramsci@unifi.it','Sociologia','Libero','Università degli studi di Firenze');
INSERT INTO Persona values ('ZZCLHR28D55C147D','Flaviana','Greco',1234577789,'F','2000-03-07','Padova','fgreco2@unifi.it','Sociologia','Libero','Università degli studi di Firenze');

INSERT INTO Persona values ('PSJNVC64B67I749D','Luca','Prisco',1000000012,'M','1990-02-14','Torino','lprisco@unifi.it','Sociologia','Libero','Università degli studi di Firenze');
INSERT INTO Persona values ('GSGNRX97A26I982Y','Francesco','Enrisi',1000000013,'M','1986-01-02','Milano','fenrisio@unifi.it','Lettere','Libero','Università degli studi di Firenze');
INSERT INTO Persona values ('CVWCFW65L01I189Q','Chiara','Del vecchio',1000000014,'F','1971-11-07','Asti','cdelvecchio@unifi.it','Storia','Libero','Università degli studi di Firenze');

--AULE
INSERT INTO Aula values (1, 'A01', 60, 'Ingegneria informatica', 'Università degli studi di Salerno');
INSERT INTO Aula values (2, 'A02', 120, 'Fisica', 'Università degli studi di Salerno');
INSERT INTO Aula values (3,'A03', 110, 'Matematica','Università degli studi di Salerno');

INSERT INTO Aula values (4,'A04', 70 , 'Ingegneria chimica', 'Università degli studi di Napoli');
INSERT INTO Aula values (5,'A05', 65 , 'Ingegneria Informatica', 'Università degli studi di Napoli');
INSERT INTO Aula values (6,'A06', 65 , 'Economia', 'Università degli studi di Napoli');

INSERT INTO Aula values (7, 'A07', 75, 'Ingegneria informatica', 'Politecnico di Milano');
INSERT INTO Aula values (8, 'A08', 29, 'Fisica', 'Politecnico di Milano');
INSERT INTO Aula values (9,'A09', 10 , 'Matematica','Politecnico di Milano');

INSERT INTO Aula values (10,'A10', 100 , 'Ingegneria chimica', 'Politecnico di Torino');
INSERT INTO Aula values (11,'A11', 160 , 'Ingegneria Informatica', 'Politecnico di Torino');
INSERT INTO Aula values (12,'A12', 260 , 'Economia', 'Politecnico di Torino');

INSERT INTO Aula values (13,'A13', 260 , 'Sociologia', 'Università degli studi di Firenze');
INSERT INTO Aula values (14,'A14', 202 , 'Lettere', 'Università degli studi di Firenze');
INSERT INTO Aula values (15,'A15', 126 , 'Storia', 'Università degli studi di Firenze');

-- PROFESSORE 
INSERT INTO Professore values ('GTAMTT60L17H703S','Professore ordinario', 12);
INSERT INTO Professore values ('GRCGPP75D08H703K','Professore non ordinario', 25);
INSERT INTO Professore values ('MNZRNN70A48F839L','Professore ordinario', 56 );

INSERT INTO Professore values ('PACRCC60L17H703S','Professore ordinario', 11);
INSERT INTO Professore values ('MORGSP75D08H703K','Professore non ordinario', 22);
INSERT INTO Professore values ('MNCMNN70A48F839T','Professore ordinario', 55 );

INSERT INTO Professore values ('CSTPPY83B15E317O','Professore ordinario', 123);
INSERT INTO Professore values ('SNBZFC36C47H334A','Professore non ordinario', 145);
INSERT INTO Professore values ('WPKRHT53L24L325A','Professore ordinario', 156 );

INSERT INTO Professore values ('PDKDCX73P45B179E','Professore ordinario', 121);
INSERT INTO Professore values ('VTRDJR62S23G136K','Professore non ordinario', 252);
INSERT INTO Professore values ('ZGCRRS55C11I991J','Professore ordinario', 563 );

INSERT INTO Professore values ('PSJNVC64B67I749D','Professore ordinario', 89);
INSERT INTO Professore values ('GSGNRX97A26I982Y','Professore non ordinario', 4);
INSERT INTO Professore values ('CVWCFW65L01I189Q','Professore ordinario', 5 );

--STUDENTE
INSERT INTO Studente values ('TRNRMN00T52A783A', 1, 'Triennale', 2022);
INSERT INTO Studente values ('MLNMRC00D04C361Z', 2, 'Magistrale', 2021);
INSERT INTO Studente values ('VNDFNC00D68G964C', 3, 'Triennale', 2020);
INSERT INTO Studente values ('NTNGNN01B21A399J', 4, 'Ciclo unico', 2019);
INSERT INTO Studente values ('VTLLCU98B16F839G', 5, 'Ciclo unico', 2018);
INSERT INTO Studente values ('MNZLSE02L53B963F', 1, 'Triennale', 2022);
INSERT INTO Studente values ('DLCVCN97L05H703I', 2, 'Triennale', 2021);
INSERT INTO Studente values ('MRCMTT99L17A509P', 3, 'Ciclo unico', 2020);
INSERT INTO Studente values ('CSNRKE00C70F839Y', 4, 'Ciclo unico', 2019);
INSERT INTO Studente values ('CSCGAI00D67H703B', 5, 'Ciclo unico', 2018);

INSERT INTO Studente values ('RSSMTT00S12F839U', 1, 'Triennale', 2022);
INSERT INTO Studente values ('VRDMRC00S12F839T', 2, 'Magistrale', 2021);
INSERT INTO Studente values ('NREGPP00S12B990R', 3, 'Triennale', 2020);
INSERT INTO Studente values ('FRRLLN00S52A064B', 4, 'Ciclo unico', 2019);
INSERT INTO Studente values ('RSSFNC01S52F839H', 5, 'Ciclo unico', 2018);
INSERT INTO Studente values ('RMNDBR98A41B963Z', 1, 'Triennale', 2022);
INSERT INTO Studente values ('DLCLNR97A41B963J', 2, 'Triennale', 2021);
INSERT INTO Studente values ('FNTMTT99A01A509U', 3, 'Ciclo unico', 2020);
INSERT INTO Studente values ('CSTLCU00A01H703F', 4, 'Ciclo unico', 2019);
INSERT INTO Studente values ('DFLPLA00A01H703Q', 5, 'Ciclo unico', 2018);

INSERT INTO Studente values ('TFNHRD63R03B217K', 1, 'Triennale', 2022);
INSERT INTO Studente values ('MLKBZR68M42B350G', 2, 'Magistrale', 2021);
INSERT INTO Studente values ('ZTQTFR56A58L697L', 3, 'Triennale', 2020);
INSERT INTO Studente values ('SWFRYF37B65A948O', 4, 'Ciclo unico', 2019);
INSERT INTO Studente values ('QVTDNZ40L07C348V', 5, 'Ciclo unico', 2018);
INSERT INTO Studente values ('YMCBTX40A41I605Z', 1, 'Triennale', 2022);
INSERT INTO Studente values ('VFCZLG94R66M271D', 2, 'Triennale', 2021);
INSERT INTO Studente values ('RTGMTL30P44G691C', 3, 'Ciclo unico', 2020);
INSERT INTO Studente values ('TQBMNN79D44G997S', 4, 'Ciclo unico', 2019);
INSERT INTO Studente values ('MDMPTN91M02F527H', 5, 'Ciclo unico', 2018);

INSERT INTO Studente values ('ZDYFHO27M61G582Y', 1, 'Triennale', 2022);
INSERT INTO Studente values ('CSPDTM27E68E997W', 2, 'Magistrale', 2021);
INSERT INTO Studente values ('MJXHPZ53C69B591C', 3, 'Triennale', 2020);
INSERT INTO Studente values ('VCYDLV34A25A761K', 4, 'Ciclo unico', 2019);
INSERT INTO Studente values ('HPTLCS61M19C057F', 5, 'Ciclo unico', 2018);
INSERT INTO Studente values ('PHGPAU98L18I747E', 1, 'Triennale', 2022);
INSERT INTO Studente values ('PLCBDH40P25L755D', 2, 'Triennale', 2021);
INSERT INTO Studente values ('SLWBVR27D08C752K', 3, 'Ciclo unico', 2020);
INSERT INTO Studente values ('ZCPPMD67R46H475T', 4, 'Ciclo unico', 2019);
INSERT INTO Studente values ('KVXTLD66L08D027L', 5, 'Ciclo unico', 2018);

INSERT INTO Studente values ('HHDNZP30A03L026W', 1, 'Triennale', 2022);
INSERT INTO Studente values ('GSRLBB44L63I673Q', 2, 'Magistrale', 2021);
INSERT INTO Studente values ('ZNGZLN84A26H250W', 3, 'Triennale', 2020);
INSERT INTO Studente values ('BRECHS46P55C327X', 4, 'Ciclo unico', 2019);
INSERT INTO Studente values ('RWVCFL74S45D408R', 5, 'Ciclo unico', 2018);
INSERT INTO Studente values ('CYGFCR46E06G458T', 1, 'Triennale', 2022);
INSERT INTO Studente values ('BWDXBM96P02G566J', 2, 'Triennale', 2021);
INSERT INTO Studente values ('ZMMCST86C27E915S', 3, 'Ciclo unico', 2020);
INSERT INTO Studente values ('DKODKC48P04L032G', 4, 'Ciclo unico', 2019);
INSERT INTO Studente values ('ZZCLHR28D55C147D', 5, 'Ciclo unico', 2018);
COMMIT WORK;

--VACCINO
BEGIN TRANSACTION;
INSERT INTO Vaccino values ('Pfizer');
INSERT INTO Vaccino values ('Moderna');
INSERT INTO Vaccino values ('Vaxzevria');
INSERT INTO Vaccino values ('J&J');
COMMIT WORK;

--POSITIVI PASSATI 
--UNIVERSITA' DI SALERNO 
BEGIN TRANSACTION;

INSERT INTO Positivo values (1, false, true,'2022-03-01','TRNRMN00T52A783A' );
INSERT INTO Tampone values (default, '2022-02-28', '15:00', 'Positivo', 'Rapido', 1, null);
INSERT INTO Tampone values (default,'2022-03-23','12:00','Negativo','Molecolare',1,null);
INSERT INTO Attestato_Positivo values(1,'Pfizer','2021-07-28');
INSERT INTO Attestato_Positivo values(1,'Vaxzevria','2022-02-23');

INSERT INTO Positivo values (2, false, false,'2022-03-27','MLNMRC00D04C361Z' );
INSERT INTO Tampone values (default, '2022-03-27', '18:00', 'Positivo', 'Rapido', 2, null);
INSERT INTO Tampone values (default,'2022-04-07','20:00','Negativo','Molecolare',2,null);
INSERT INTO Attestato_Positivo values(2,'Moderna','2021-06-21');

INSERT INTO Positivo values (3, true, true,'2022-04-21','DLCVCN97L05H703I' );
INSERT INTO Tampone values (default, '2022-04-21', '08:00', 'Positivo', 'Molecolare', 3, null);
INSERT INTO Tampone values (default,'2022-04-30','11:00','Negativo','Rapido',3,null);
INSERT INTO Attestato_Positivo values(3,'Pfizer','2022-01-03');
INSERT INTO Attestato_Positivo values(3,'J&J','2022-04-12');

INSERT INTO Positivo values (4, false, true,'2022-04-11','VNDFNC00D68G964C' );
INSERT INTO Tampone values (default, '2022-04-10', '10:00', 'Positivo', 'Molecolare', 4, null);
INSERT INTO Tampone values (default,'2022-04-30','12:00','Negativo','Molecolare',4,null);
INSERT INTO Attestato_Positivo values(4,'Pfizer','2021-12-26');
INSERT INTO Attestato_Positivo values(4,'Pfizer','2022-03-13');

INSERT INTO Positivo values (5, false, false,'2022-05-05','NTNGNN01B21A399J' );
INSERT INTO Tampone values (default, '2022-05-05', '15:00', 'Positivo', 'Rapido', 5, null);
INSERT INTO Tampone values (default,'2022-05-21','12:00','Negativo','Rapido',5,null);
INSERT INTO Attestato_Positivo values(5,'Pfizer','2021-02-17');
INSERT INTO Attestato_Positivo values(5,'Pfizer','2021-06-10');
INSERT INTO Attestato_Positivo values(5,'Vaxzevria','2022-04-04');

INSERT INTO Positivo values (6, false, true,'2022-05-29','VTLLCU98B16F839G' );
INSERT INTO Tampone values (default, '2022-05-27', '15:00', 'Positivo', 'Rapido', 6, null);
INSERT INTO Tampone values (default,'2022-06-09','12:00','Negativo','Molecolare',6,null);


INSERT INTO Positivo values (7, false, false,'2022-04-05','GTAMTT60L17H703S' );
INSERT INTO Tampone values (default, '2022-04-05', '20:00', 'Positivo', 'Molecolare', 7, null);
INSERT INTO Tampone values (default,'2022-04-13','19:00','Negativo','Rapido',7,null);
INSERT INTO Attestato_Positivo values(7,'Vaxzevria','2022-02-17');
INSERT INTO Attestato_Positivo values(7,'Vaxzevria','2022-04-21');


INSERT INTO Positivo values (8, false, false,'2022-02-02','MNZRNN70A48F839L' );
INSERT INTO Tampone values (default, '2022-02-01', '08:00', 'Positivo', 'Rapido', 8, null);
INSERT INTO Tampone values (default,'2022-03-02','11:00','Negativo','Rapido',8,null);
INSERT INTO Attestato_Positivo values(8,'Pfizer','2021-08-09');
INSERT INTO Attestato_Positivo values(8,'J&J','2021-12-11');

-- UNIVERSITA' DI NAPOLI 
INSERT INTO Positivo values (9, false, true,'2022-03-11','RSSMTT00S12F839U' );
INSERT INTO Tampone values (default, '2022-03-11', '13:00', 'Positivo', 'Rapido', 9, null);
INSERT INTO Tampone values (default,'2022-03-26','12:00','Negativo','Molecolare',9,null);
INSERT INTO Attestato_Positivo values(9,'J&J','2021-03-28');
INSERT INTO Attestato_Positivo values(9,'J&J','2021-12-23');

INSERT INTO Positivo values (10, true, true,'2022-03-25','VRDMRC00S12F839T' );
INSERT INTO Tampone values (default, '2022-03-23', '18:00', 'Positivo', 'Rapido', 10, null);
INSERT INTO Tampone values (default,'2022-04-08','20:00','Negativo','Rapido',10,null);
INSERT INTO Attestato_Positivo values(10,'Moderna','2021-09-29');

INSERT INTO Positivo values (11, true, true,'2022-03-21','NREGPP00S12B990R' );
INSERT INTO Tampone values (default, '2022-03-21', '08:00', 'Positivo', 'Molecolare', 11, null);
INSERT INTO Tampone values (default,'2022-04-01','11:00','Negativo','Rapido',11,null);
INSERT INTO Attestato_Positivo values(11,'Moderna','2022-02-13');
INSERT INTO Attestato_Positivo values(11,'J&J','2022-03-13');

INSERT INTO Positivo values (12, false, true,'2022-04-20','FRRLLN00S52A064B' );
INSERT INTO Tampone values (default, '2022-04-20', '10:00', 'Positivo', 'Molecolare', 12, null);
INSERT INTO Tampone values (default,'2022-04-29','12:00','Negativo','Molecolare',12,null);
INSERT INTO Attestato_Positivo values(12,'Moderna','2021-11-30');
INSERT INTO Attestato_Positivo values(12,'Moderna','2022-02-21');

INSERT INTO Positivo values (13, false, true,'2022-04-30','RSSFNC01S52F839H' );
INSERT INTO Tampone values (default, '2022-04-30', '18:00', 'Positivo', 'Rapido', 13, null);
INSERT INTO Tampone values (default,'2022-05-13','18:00','Negativo','Rapido',13,null);
INSERT INTO Attestato_Positivo values(13,'Vaxzevria','2021-04-17');
INSERT INTO Attestato_Positivo values(13,'Vaxzevria','2021-07-19');
INSERT INTO Attestato_Positivo values(13,'Vaxzevria','2022-01-09');

INSERT INTO Positivo values (14, false, true,'2022-05-15','RMNDBR98A41B963Z' );
INSERT INTO Tampone values (default, '2022-05-14', '15:00', 'Positivo', 'Rapido', 14, null);
INSERT INTO Tampone values (default,'2022-05-30','12:00','Negativo','Molecolare',14,null);
INSERT INTO Attestato_Positivo values(14,'Vaxzevria','2022-05-05');


INSERT INTO Positivo values (15, false, false,'2022-04-05','MORGSP75D08H703K' );
INSERT INTO Tampone values (default, '2022-04-05', '20:00', 'Positivo', 'Molecolare', 15, null);
INSERT INTO Tampone values (default,'2022-04-13','19:00','Negativo','Rapido',15,null);
INSERT INTO Attestato_Positivo values(15,'Vaxzevria','2021-12-11');
INSERT INTO Attestato_Positivo values(15,'Vaxzevria','2022-03-22');


INSERT INTO Positivo values (16, false, false,'2022-02-02','PACRCC60L17H703S' );
INSERT INTO Tampone values (default, '2022-02-01', '08:00', 'Positivo', 'Rapido', 16, null);
INSERT INTO Tampone values (default,'2022-02-11','11:00','Negativo','Rapido',16,null);
INSERT INTO Attestato_Positivo values(16,'Pfizer','2021-04-19');
INSERT INTO Attestato_Positivo values(16,'J&J','2021-09-12');


-- UNIVERSITA' DI MILANO 
INSERT INTO Positivo values (17, false, true,'2022-02-18','ZTQTFR56A58L697L' );
INSERT INTO Tampone values (default, '2022-02-17', '13:00', 'Positivo', 'Rapido', 17, null);
INSERT INTO Tampone values (default,'2022-03-09','12:00','Negativo','Molecolare',17,null);
INSERT INTO Attestato_Positivo values(17,'Vaxzevria','2021-10-28');
INSERT INTO Attestato_Positivo values(17,'J&J','2022-02-01');

INSERT INTO Positivo values (18, true, true,'2022-03-02','VFCZLG94R66M271D' );
INSERT INTO Tampone values (default, '2022-03-02', '18:00', 'Positivo', 'Rapido', 18, null);
INSERT INTO Tampone values (default,'2022-03-30','20:00','Negativo','Rapido',18,null);
INSERT INTO Attestato_Positivo values(18,'Vaxzevria','2022-01-29');

INSERT INTO Positivo values (19, true, true,'2022-04-10','MDMPTN91M02F527H' );
INSERT INTO Tampone values (default, '2022-04-10', '08:00', 'Positivo', 'Molecolare', 19, null);
INSERT INTO Tampone values (default,'2022-04-21','11:00','Negativo','Rapido',19,null);
INSERT INTO Attestato_Positivo values(19,'Pfizer','2022-01-10');
INSERT INTO Attestato_Positivo values(19,'J&J','2022-04-03');

INSERT INTO Positivo values (20, false, true,'2022-04-21','MLKBZR68M42B350G' );
INSERT INTO Tampone values (default, '2022-04-20', '10:00', 'Positivo', 'Molecolare', 20, null);
INSERT INTO Tampone values (default,'2022-05-15','12:00','Negativo','Molecolare',20,null);
INSERT INTO Attestato_Positivo values(20,'Moderna','2021-11-30');
INSERT INTO Attestato_Positivo values(20,'Pfizer','2022-03-11');

INSERT INTO Positivo values (21, false, true,'2022-04-30','TFNHRD63R03B217K' );
INSERT INTO Tampone values (default, '2022-04-30', '18:00', 'Positivo', 'Rapido', 21, null);
INSERT INTO Tampone values (default,'2022-05-22','18:00','Negativo','Rapido',21,null);
INSERT INTO Attestato_Positivo values(21,'Pfizer','2021-09-07');
INSERT INTO Attestato_Positivo values(21,'Vaxzevria','2021-11-09');
INSERT INTO Attestato_Positivo values(21,'Vaxzevria','2022-03-29');

INSERT INTO Positivo values (22, false, true,'2022-05-12','QVTDNZ40L07C348V' );
INSERT INTO Tampone values (default, '2022-05-12', '15:00', 'Positivo', 'Rapido', 22, null);
INSERT INTO Tampone values (default,'2022-06-01','12:00','Negativo','Molecolare',22,null);
INSERT INTO Attestato_Positivo values(22,'Pfizer','2022-04-16');


INSERT INTO Positivo values (23, false, false,'2022-05-10','CSTPPY83B15E317O' );
INSERT INTO Tampone values (default, '2022-05-07', '20:00', 'Positivo', 'Molecolare', 23, null);
INSERT INTO Tampone values (default,'2022-05-28','19:00','Negativo','Rapido',23,null);
INSERT INTO Attestato_Positivo values(23,'Moderna','2021-06-16');
INSERT INTO Attestato_Positivo values(23,'Vaxzevria','2022-04-26');


INSERT INTO Positivo values (24, false, false,'2022-01-23','SNBZFC36C47H334A' );
INSERT INTO Tampone values (default, '2022-01-23', '08:00', 'Positivo', 'Rapido', 24, null);
INSERT INTO Tampone values (default,'2022-02-19','11:00','Negativo','Rapido',24,null);
INSERT INTO Attestato_Positivo values(24,'Pfizer','2021-04-11');
INSERT INTO Attestato_Positivo values(24,'Pfizer','2021-09-19');

-- UNIVERSITA' DI FIRENZE 

INSERT INTO Positivo values (25, false, false,'2022-01-31','ZNGZLN84A26H250W' );
INSERT INTO Tampone values (default, '2022-01-31', '19:00', 'Positivo', 'Rapido', 25, null);
INSERT INTO Tampone values (default,'2022-02-09','12:00','Negativo','Molecolare',25,null);
INSERT INTO Attestato_Positivo values(25,'Vaxzevria','2021-11-18');
INSERT INTO Attestato_Positivo values(25,'Vaxzevria','2022-01-24');

INSERT INTO Positivo values (26, false, false,'2022-01-31','GSRLBB44L63I673Q' );
INSERT INTO Tampone values (default, '2022-01-30', '14:00', 'Positivo', 'Rapido', 26, null);
INSERT INTO Tampone values (default,'2022-02-07','18:00','Negativo','Rapido',26,null);
INSERT INTO Attestato_Positivo values(26,'J&J','2021-12-05');

INSERT INTO Positivo values (27, false, false,'2022-03-21','ZMMCST86C27E915S' );
INSERT INTO Tampone values (default, '2022-03-21', '08:00', 'Positivo', 'Molecolare', 27, null);
INSERT INTO Tampone values (default,'2022-04-01','11:00','Negativo','Rapido',27,null);
INSERT INTO Attestato_Positivo values(27,'Pfizer','2022-01-19');
INSERT INTO Attestato_Positivo values(27,'Pfizer','2022-03-02');

INSERT INTO Positivo values (28, false, true,'2022-04-17','HHDNZP30A03L026W' );
INSERT INTO Tampone values (default, '2022-04-16', '18:00', 'Positivo', 'Molecolare', 28, null);
INSERT INTO Tampone values (default,'2022-04-26','17:00','Negativo','Molecolare',28,null);
INSERT INTO Attestato_Positivo values(28,'Pfizer','2021-10-03');
INSERT INTO Attestato_Positivo values(28,'Pfizer','2022-04-08');

INSERT INTO Positivo values (29, false, false,'2022-04-20','DKODKC48P04L032G' );
INSERT INTO Tampone values (default, '2022-04-20', '08:00', 'Positivo', 'Rapido', 29, null);
INSERT INTO Tampone values (default,'2022-04-30','17:00','Negativo','Rapido',29,null);
INSERT INTO Attestato_Positivo values(29,'Pfizer','2020-12-17');
INSERT INTO Attestato_Positivo values(29,'Moderna','2021-06-12');
INSERT INTO Attestato_Positivo values(29,'J&J','2022-04-07');

INSERT INTO Positivo values (30, true, true,'2022-05-02','ZZCLHR28D55C147D' );
INSERT INTO Tampone values (default, '2022-05-01', '15:00', 'Positivo', 'Rapido', 30, null);
INSERT INTO Tampone values (default,'2022-05-07','12:00','Negativo','Molecolare',30,null);
INSERT INTO Attestato_Positivo values(30,'Pfizer','2022-04-19');


INSERT INTO Positivo values (31, false, false,'2022-05-19','CVWCFW65L01I189Q' );
INSERT INTO Tampone values (default, '2022-05-18', '20:00', 'Positivo', 'Molecolare', 31, null);
INSERT INTO Tampone values (default,'2022-05-25','19:00','Negativo','Rapido',31,null);
INSERT INTO Attestato_Positivo values(31,'Moderna','2021-06-20');
INSERT INTO Attestato_Positivo values(31,'Moderna','2022-04-27');


INSERT INTO Positivo values (32, false, true,'2022-04-13','GSGNRX97A26I982Y' );
INSERT INTO Tampone values (default, '2022-04-13', '08:00', 'Positivo', 'Rapido', 32, null);
INSERT INTO Tampone values (default,'2022-04-24','11:00','Negativo','Rapido',32,null);
INSERT INTO Attestato_Positivo values(32,'J&J','2021-09-11');
INSERT INTO Attestato_Positivo values(32,'Pfizer','2021-11-19');

-- UNIVERSITA' DI TORINO 
INSERT INTO Positivo values (33, false, false,'2022-01-10','MJXHPZ53C69B591C' );
INSERT INTO Tampone values (default, '2022-01-10', '09:00', 'Positivo', 'Rapido', 33, null);
INSERT INTO Tampone values (default,'2022-02-07','17:00','Negativo','Molecolare',33,null);
INSERT INTO Attestato_Positivo values(33,'Vaxzevria','2021-10-28');
INSERT INTO Attestato_Positivo values(33,'Vaxzevria','2021-12-24');

INSERT INTO Positivo values (34, false, false,'2022-01-28','VCYDLV34A25A761K' );
INSERT INTO Tampone values (default, '2022-01-28', '12:00', 'Positivo', 'Rapido', 34, null);
INSERT INTO Tampone values (default,'2022-02-17','14:00','Negativo','Rapido',34,null);
INSERT INTO Attestato_Positivo values(34,'Pfizer','2021-01-15');

INSERT INTO Positivo values (35, false, false,'2022-03-11','CSPDTM27E68E997W' );
INSERT INTO Tampone values (default, '2022-03-11', '18:00', 'Positivo', 'Molecolare', 35, null);
INSERT INTO Tampone values (default,'2022-04-12','14:00','Negativo','Rapido',35,null);
INSERT INTO Attestato_Positivo values(35,'Pfizer','2022-01-25');
INSERT INTO Attestato_Positivo values(35,'Vaxzevria','2022-03-09');

INSERT INTO Positivo values (36, false, true,'2022-04-27','ZCPPMD67R46H475T' );
INSERT INTO Tampone values (default, '2022-04-26', '20:00', 'Positivo', 'Molecolare', 36, null);
INSERT INTO Tampone values (default,'2022-05-16','18:00','Negativo','Molecolare',36,null);
INSERT INTO Attestato_Positivo values(36,'Pfizer','2021-09-23');
INSERT INTO Attestato_Positivo values(36,'Pfizer','2022-04-07');

INSERT INTO Positivo values (37, false, false,'2022-04-10','ZDYFHO27M61G582Y' );
INSERT INTO Tampone values (default, '2022-04-07', '18:00', 'Positivo', 'Rapido', 37, null);
INSERT INTO Tampone values (default,'2022-05-12','19:00','Negativo','Rapido',37,null);
INSERT INTO Attestato_Positivo values(37,'Pfizer','2021-04-23');
INSERT INTO Attestato_Positivo values(37,'Moderna','2021-06-27');
INSERT INTO Attestato_Positivo values(37,'Moderna','2022-04-01');

INSERT INTO Positivo values (38, true, true,'2022-05-12','KVXTLD66L08D027L' );
INSERT INTO Tampone values (default, '2022-05-11', '07:30', 'Positivo', 'Rapido', 38, null);
INSERT INTO Tampone values (default,'2022-05-19','16:00','Negativo','Molecolare',38,null);
INSERT INTO Attestato_Positivo values(38,'Pfizer','2022-04-29');


INSERT INTO Positivo values (39, false, false,'2022-05-09','ZGCRRS55C11I991J' );
INSERT INTO Tampone values (default, '2022-05-08', '20:00', 'Positivo', 'Molecolare', 39, null);
INSERT INTO Tampone values (default,'2022-06-01','19:00','Negativo','Rapido',39,null);
INSERT INTO Attestato_Positivo values(39,'J&J','2021-04-20');
INSERT INTO Attestato_Positivo values(39,'Moderna','2022-04-20');


INSERT INTO Positivo values (40, false, true,'2022-03-03','PDKDCX73P45B179E' );
INSERT INTO Tampone values (default, '2022-03-01', '08:00', 'Positivo', 'Rapido', 40, null);
INSERT INTO Tampone values (default,'2022-04-02','11:00','Negativo','Rapido',40,null);
INSERT INTO Attestato_Positivo values(40,'J&J','2021-09-19');
INSERT INTO Attestato_Positivo values(40,'J&J','2022-02-28');
COMMIT WORK;


-- A questo punto è possibile verificare le query di Media giorni positività per Regione e la Ricerca
--vaccinati con due dosi e positivi per più di 21 giorni. 

/* POPOLAMENTO CALENDARIO PER MOSTRARE AULE LIBERE E OCCUPATE 
Per il nostro database abbiamo previsto l'inserimento di Attività che siano conseguenti al momento 
in cui le si inserisce all'interno del database. Per questo motivo inseriamo alcune attività schedulate
nel calendario che occupino interamente alcune giornate, in modo tale che possiate controllare
la query delle aule inserendo attività nel giorno in cui state controllando. Inoltre ricordiamo che
in seguito all'inserimento e al tracciamento dei contatti alcune aule risulteranno libere
poichè l'attività viene svolta a distanza quando il professore risulta positivo*/
BEGIN TRANSACTION;

INSERT INTO Calendario values(1,'07:00','22:00','Lunedì','Programmazione',2,1);
INSERT INTO Calendario values(2,'07:00','22:00','Martedì','Fisica',2,2);
INSERT INTO Calendario values(3,'07:00','22:00','Mercoledì','Matematica',2,1);
INSERT INTO Calendario values(4,'07:00','22:00','Giovedì','Basi di Dati',2,3);
INSERT INTO Calendario values(5,'07:00','22:00','Venerdì','IoT',2,3);

INSERT INTO Calendario values(6,'07:00','22:00','Lunedì','Programmazione',2,4);
INSERT INTO Calendario values(7,'07:00','22:00','Martedì','Fisica',2,4);
INSERT INTO Calendario values(8,'07:00','22:00','Mercoledì','Matematica',2,6);
INSERT INTO Calendario values(9,'07:00','22:00','Giovedì','Basi di Dati',2,5);
INSERT INTO Calendario values(10,'07:00','22:00','Venerdì','IoT',2,6);

INSERT INTO Calendario values(11,'07:00','22:00','Lunedì','Programmazione',2,7);
INSERT INTO Calendario values(12,'07:00','22:00','Martedì','Fisica',2,7);
INSERT INTO Calendario values(13,'07:00','22:00','Mercoledì','Matematica',2,7);
INSERT INTO Calendario values(14,'07:00','22:00','Giovedì','Basi di Dati',2,9);
INSERT INTO Calendario values(15,'07:00','22:00','Venerdì','IoT',2,8);

INSERT INTO Calendario values(16,'07:00','22:00','Lunedì','Programmazione',2,10);
INSERT INTO Calendario values(17,'07:00','22:00','Martedì','Fisica',2,11);
INSERT INTO Calendario values(18,'07:00','22:00','Mercoledì','Matematica',2,11);
INSERT INTO Calendario values(19,'07:00','22:00','Giovedì','Basi di Dati',2,11);
INSERT INTO Calendario values(20,'07:00','22:00','Venerdì','IoT',2,12);

INSERT INTO Calendario values(21,'07:00','22:00','Lunedì','Programmazione',2,13);
INSERT INTO Calendario values(22,'07:00','22:00','Martedì','Fisica',2,13);
INSERT INTO Calendario values(23,'07:00','22:00','Mercoledì','Matematica',2,14);
INSERT INTO Calendario values(24,'07:00','22:00','Giovedì','Basi di Dati',2,14);
INSERT INTO Calendario values(25,'07:00','22:00','Venerdì','IoT',2,15);
COMMIT WORK;

-- A seconda del giorno della settimana runnare uno dei seguenti statement per inserire le attività
--nel giorno corretto, poi eseguire la query per la ricerca delle aule libere 

-- Se è lunedì 
BEGIN TRANSACTION;

INSERT INTO Attività values(CURRENT_DATE,1,DEFAULT,20,60,'GTAMTT60L17H703S');
INSERT INTO Attività values(CURRENT_DATE,6,DEFAULT,25,70,'PACRCC60L17H703S');
INSERT INTO Attività values(CURRENT_DATE,11,DEFAULT,25,75,'CSTPPY83B15E317O');
INSERT INTO Attività values(CURRENT_DATE,16,DEFAULT,50,100,'PDKDCX73P45B179E');
INSERT INTO Attività values(CURRENT_DATE,21,DEFAULT,100,260,'CVWCFW65L01I189Q');
COMMIT WORK;

-- Se è martedì 
BEGIN TRANSACTION;

INSERT INTO Attività values(CURRENT_DATE,2,DEFAULT,60,120,'GTAMTT60L17H703S');
INSERT INTO Attività values(CURRENT_DATE,7,DEFAULT,25,70,'PACRCC60L17H703S');
INSERT INTO Attività values(CURRENT_DATE,12,DEFAULT,45,75,'CSTPPY83B15E317O');
INSERT INTO Attività values(CURRENT_DATE,17,DEFAULT,100,160,'PDKDCX73P45B179E');
INSERT INTO Attività values(CURRENT_DATE,22,DEFAULT,80,260,'CVWCFW65L01I189Q');
COMMIT WORK;

-- Se è mercoledì 
BEGIN TRANSACTION;

INSERT INTO Attività values(CURRENT_DATE,3,DEFAULT,60,60,'GRCGPP75D08H703K');
INSERT INTO Attività values(CURRENT_DATE,8,DEFAULT,65,65,'MORGSP75D08H703K');
INSERT INTO Attività values(CURRENT_DATE,13,DEFAULT,15,75,'CSTPPY83B15E317O');
INSERT INTO Attività values(CURRENT_DATE,18,DEFAULT,50,160,'PDKDCX73P45B179E');
INSERT INTO Attività values(CURRENT_DATE,23,DEFAULT,101,202,'CVWCFW65L01I189Q');
COMMIT WORK;

-- Se è giovedì 
BEGIN TRANSACTION;

INSERT INTO Attività values(CURRENT_DATE,4,DEFAULT,60,110,'GRCGPP75D08H703K');
INSERT INTO Attività values(CURRENT_DATE,9,DEFAULT,65,65,'MORGSP75D08H703K');
INSERT INTO Attività values(CURRENT_DATE,14,DEFAULT,10,10,'CSTPPY83B15E317O');
INSERT INTO Attività values(CURRENT_DATE,19,DEFAULT,100,160,'PDKDCX73P45B179E');
INSERT INTO Attività values(CURRENT_DATE,24,DEFAULT,101,202,'CVWCFW65L01I189Q');
COMMIT WORK;

--Se è venerdì 
BEGIN TRANSACTION;

INSERT INTO Attività values(CURRENT_DATE,5,DEFAULT,55,110,'MNZRNN70A48F839L');
INSERT INTO Attività values(CURRENT_DATE,10,DEFAULT,50,65,'MNCMNN70A48F839T');
INSERT INTO Attività values(CURRENT_DATE,15,DEFAULT,20,29,'CSTPPY83B15E317O');
INSERT INTO Attività values(CURRENT_DATE,20,DEFAULT,130,260,'PDKDCX73P45B179E');
INSERT INTO Attività values(CURRENT_DATE,25,DEFAULT,113,126,'CVWCFW65L01I189Q');
COMMIT WORK;


/* Per lo stesso motivo, la query per il tracciamento dei contatti dei positivi odierni, lavoriamo allo stesso
modo, inserendo prenotazioni relative alle attività, in base al giorno in cui state verificando, per semplicità
inseriamo prenotazioni relative soltanto all'Università degli studi di Salerno e al Politecnico di Milano,
anche per rendere gli statement più leggibili*/

--Se è lunedì 
BEGIN TRANSACTION;

INSERT INTO Prenotazione VALUES ('TRNRMN00T52A783A',CURRENT_DATE,1);
INSERT INTO Prenotazione VALUES ('MLNMRC00D04C361Z',CURRENT_DATE,1);
INSERT INTO Prenotazione VALUES ('VNDFNC00D68G964C',CURRENT_DATE,1);
INSERT INTO Prenotazione VALUES ('NTNGNN01B21A399J',CURRENT_DATE,1);

INSERT INTO Prenotazione VALUES ('MLKBZR68M42B350G',CURRENT_DATE,11);
INSERT INTO Prenotazione VALUES ('ZTQTFR56A58L697L',CURRENT_DATE,11);
INSERT INTO Prenotazione VALUES ('SWFRYF37B65A948O',CURRENT_DATE,11);
INSERT INTO Prenotazione VALUES ('QVTDNZ40L07C348V',CURRENT_DATE,11);
COMMIT WORK;

--Se è martedì 
BEGIN TRANSACTION;

INSERT INTO Prenotazione VALUES ('TRNRMN00T52A783A',CURRENT_DATE,2);
INSERT INTO Prenotazione VALUES ('MLNMRC00D04C361Z',CURRENT_DATE,2);
INSERT INTO Prenotazione VALUES ('VNDFNC00D68G964C',CURRENT_DATE,2);
INSERT INTO Prenotazione VALUES ('NTNGNN01B21A399J',CURRENT_DATE,2);

INSERT INTO Prenotazione VALUES ('MLKBZR68M42B350G',CURRENT_DATE,12);
INSERT INTO Prenotazione VALUES ('ZTQTFR56A58L697L',CURRENT_DATE,12);
INSERT INTO Prenotazione VALUES ('SWFRYF37B65A948O',CURRENT_DATE,12);
INSERT INTO Prenotazione VALUES ('QVTDNZ40L07C348V',CURRENT_DATE,12);
COMMIT WORK;

-- Se è mercoledì 
BEGIN TRANSACTION;

INSERT INTO Prenotazione VALUES ('TRNRMN00T52A783A',CURRENT_DATE,3);
INSERT INTO Prenotazione VALUES ('MLNMRC00D04C361Z',CURRENT_DATE,3);
INSERT INTO Prenotazione VALUES ('VNDFNC00D68G964C',CURRENT_DATE,3);
INSERT INTO Prenotazione VALUES ('NTNGNN01B21A399J',CURRENT_DATE,3);

INSERT INTO Prenotazione VALUES ('MLKBZR68M42B350G',CURRENT_DATE,13);
INSERT INTO Prenotazione VALUES ('ZTQTFR56A58L697L',CURRENT_DATE,13);
INSERT INTO Prenotazione VALUES ('SWFRYF37B65A948O',CURRENT_DATE,13);
INSERT INTO Prenotazione VALUES ('QVTDNZ40L07C348V',CURRENT_DATE,13);
COMMIT WORK;

-- Se è giovedì 
BEGIN TRANSACTION;

INSERT INTO Prenotazione VALUES ('TRNRMN00T52A783A',CURRENT_DATE,4);
INSERT INTO Prenotazione VALUES ('MLNMRC00D04C361Z',CURRENT_DATE,4);
INSERT INTO Prenotazione VALUES ('VNDFNC00D68G964C',CURRENT_DATE,4);
INSERT INTO Prenotazione VALUES ('NTNGNN01B21A399J',CURRENT_DATE,4);

INSERT INTO Prenotazione VALUES ('MLKBZR68M42B350G',CURRENT_DATE,14);
INSERT INTO Prenotazione VALUES ('ZTQTFR56A58L697L',CURRENT_DATE,14);
INSERT INTO Prenotazione VALUES ('SWFRYF37B65A948O',CURRENT_DATE,14);
INSERT INTO Prenotazione VALUES ('QVTDNZ40L07C348V',CURRENT_DATE,14);
COMMIT WORK;

-- Se è venerdì 
BEGIN TRANSACTION;

INSERT INTO Prenotazione VALUES ('TRNRMN00T52A783A',CURRENT_DATE,5);
INSERT INTO Prenotazione VALUES ('MLNMRC00D04C361Z',CURRENT_DATE,5);
INSERT INTO Prenotazione VALUES ('VNDFNC00D68G964C',CURRENT_DATE,5);
INSERT INTO Prenotazione VALUES ('NTNGNN01B21A399J',CURRENT_DATE,5);

INSERT INTO Prenotazione VALUES ('MLKBZR68M42B350G',CURRENT_DATE,15);
INSERT INTO Prenotazione VALUES ('ZTQTFR56A58L697L',CURRENT_DATE,15);
INSERT INTO Prenotazione VALUES ('SWFRYF37B65A948O',CURRENT_DATE,15);
INSERT INTO Prenotazione VALUES ('QVTDNZ40L07C348V',CURRENT_DATE,15);
COMMIT WORK;



/* Dopodichè rendiamo positivo per l'università di salerno uno studente dell'attività, mentre per
il politecnico rendiamo positivo uno studente e un professore così da poter effettuare la query per il tracciamento
dei contatti */
BEGIN TRANSACTION;

INSERT INTO Positivo values (41, false, false,CURRENT_DATE,'NTNGNN01B21A399J' );
INSERT INTO Tampone values (default, CURRENT_DATE, CURRENT_TIME, 'Positivo', 'Molecolare', 41, null);

INSERT INTO Positivo values (42, false, false,CURRENT_DATE,'CSTPPY83B15E317O' );
INSERT INTO Tampone values (default, CURRENT_DATE, CURRENT_TIME, 'Positivo', 'Molecolare', 42, null);

INSERT INTO Positivo values (43, false, false,CURRENT_DATE,'QVTDNZ40L07C348V' );
INSERT INTO Tampone values (default, CURRENT_DATE, CURRENT_TIME, 'Positivo', 'Molecolare', 43, null);
COMMIT WORK;

/* Una volta effettuata la query potremmo anche popolare la tabella di Attestato Contatto inserendo le
relative date di somministrazione dei vaccini dei vari contatti */


-- POSITIVI AL MOMENTO 
BEGIN TRANSACTION;

INSERT INTO Positivo values (44, false, false,'2022-06-02','CSCGAI00D67H703B' );
INSERT INTO Tampone values (default,'2022-06-02','10:00' , 'Positivo', 'Molecolare', 44, null);
INSERT INTO Positivo values (45, false, false,'2022-06-05','CSNRKE00C70F839Y' );
INSERT INTO Tampone values (default,'2022-06-04','10:00' , 'Positivo', 'Molecolare', 45, null);
INSERT INTO Positivo values (46, false, false,'2022-06-05','MRCMTT99L17A509P' );
INSERT INTO Tampone values (default,'2022-05-28','12:00' , 'Positivo', 'Molecolare', 46, null);
INSERT INTO Positivo values (47, false, false,'2022-06-05','DLCVCN97L05H703I' );
INSERT INTO Tampone values (default,'2022-05-30','12:00' , 'Positivo', 'Molecolare', 47, null);


INSERT INTO Positivo values (48, false, false,'2022-06-02','DFLPLA00A01H703Q' );
INSERT INTO Tampone values (default,'2022-06-01','14:00' , 'Positivo', 'Molecolare', 48, null);


INSERT INTO Positivo values (49, false, false,'2022-06-04','YMCBTX40A41I605Z' );
INSERT INTO Tampone values (default,'2022-06-03','17:00' , 'Positivo', 'Molecolare', 49, null);
INSERT INTO Positivo values (50, false, false,'2022-05-25','VFCZLG94R66M271D' );
INSERT INTO Tampone values (default,'2022-05-25','15:00' , 'Positivo', 'Molecolare', 50, null);
INSERT INTO Positivo values (51, false, false,'2022-06-08','RTGMTL30P44G691C' );
INSERT INTO Tampone values (default,'2022-06-06','12:00' , 'Positivo', 'Molecolare', 51, null);
INSERT INTO Positivo values (52, false, false,'2022-06-05','TQBMNN79D44G997S' );
INSERT INTO Tampone values (default,'2022-06-05','13:00' , 'Positivo', 'Molecolare', 52, null);
INSERT INTO Positivo values (53, false, false,'2022-06-01','MDMPTN91M02F527H' );
INSERT INTO Tampone values (default,'2022-05-31','14:00' , 'Positivo', 'Molecolare', 53, null);

INSERT INTO Positivo values (54, false, false,'2022-06-04','ZZCLHR28D55C147D' );
INSERT INTO Tampone values (default,'2022-06-03','17:00' , 'Positivo', 'Molecolare', 54, null);
INSERT INTO Positivo values (55, false, false,'2022-05-25','DKODKC48P04L032G' );
INSERT INTO Tampone values (default,'2022-05-25','15:00' , 'Positivo', 'Molecolare', 55, null);
INSERT INTO Positivo values (56, false, false,'2022-06-08','ZMMCST86C27E915S' );
INSERT INTO Tampone values (default,'2022-06-06','12:00' , 'Positivo', 'Molecolare', 56, null);
INSERT INTO Positivo values (57, false, false,'2022-06-05','BWDXBM96P02G566J' );
INSERT INTO Tampone values (default,'2022-06-05','13:00' , 'Positivo', 'Molecolare', 57, null);
INSERT INTO Positivo values (58, false, false,'2022-06-01','CYGFCR46E06G458T' );
INSERT INTO Tampone values (default,'2022-05-31','14:00' , 'Positivo', 'Molecolare', 58, null);
INSERT INTO Positivo values (59, false, false,'2022-06-05','RWVCFL74S45D408R' );
INSERT INTO Tampone values (default,'2022-06-05','13:00' , 'Positivo', 'Molecolare', 59, null);
INSERT INTO Positivo values (60, false, false,'2022-06-01','ZNGZLN84A26H250W' );
INSERT INTO Tampone values (default,'2022-05-31','14:00' , 'Positivo', 'Molecolare', 60, null);
INSERT INTO Positivo values (61, false, false,'2022-06-01','PSJNVC64B67I749D' );
INSERT INTO Tampone values (default,'2022-05-31','14:00' , 'Positivo', 'Molecolare', 61, null);

INSERT INTO Positivo values (62, false, false,'2022-06-05','ZDYFHO27M61G582Y' );
INSERT INTO Tampone values (default,'2022-06-05','13:00' , 'Positivo', 'Molecolare', 62, null);
INSERT INTO Positivo values (63, false, false,'2022-06-01','MJXHPZ53C69B591C' );
INSERT INTO Tampone values (default,'2022-05-31','14:00' , 'Positivo', 'Molecolare', 63, null);
COMMIT WORK;