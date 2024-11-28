CREATE OR REPLACE FUNCTION controllo_università()
RETURNS TRIGGER AS
$BODY$
	DECLARE
		professore integer;
		studente integer;
		aula integer;
	BEGIN
		SELECT count(*) INTO aula FROM Aula WHERE Aula.Università = NEW.Nome;
		SELECT count(*) INTO professore FROM Persona JOIN Professore ON Persona.Codice_fiscale = Professore.Persona WHERE Persona.Università = NEW.Nome;
		SELECT count(*) INTO studente FROM Persona JOIN Studente ON Persona.Codice_fiscale = Studente.Persona WHERE Persona.Università = NEW.Nome;
		IF ( aula = 0 or professore = 0 or studente =0 ) THEN RAISE EXCEPTION $$'Non è possibile inserire % poichè non ha almeno un professore,un aula e uno studente'$$, NEW.Nome;
		ELSE return NEW;
		END IF;	
		
	END;
$BODY$
LANGUAGE PLPGSQL;

CREATE CONSTRAINT TRIGGER università_valida
AFTER INSERT
ON Università
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE PROCEDURE controllo_università();


CREATE OR REPLACE FUNCTION controllo_persona()
RETURNS TRIGGER AS
$BODY$
	DECLARE
		professore integer;
		studente integer;
	BEGIN
		SELECT count(*) INTO professore FROM Persona JOIN Professore ON Persona.Codice_fiscale = Professore.Persona WHERE Professore.Persona = NEW.Codice_fiscale;
		SELECT count(*) INTO studente FROM Persona JOIN Studente ON Persona.Codice_fiscale = Studente.Persona WHERE Studente.Persona = NEW.Codice_fiscale;
		IF (professore = 0 and studente =0 ) THEN RAISE EXCEPTION $$'Non è possibile inserire % poichè non è uno studente o un professore'$$, NEW.Codice_fiscale;
		ELSE return NEW;
		END IF;	
		
	END;
$BODY$
LANGUAGE PLPGSQL;

CREATE CONSTRAINT TRIGGER persona_valida	
AFTER INSERT
ON Persona
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE PROCEDURE controllo_persona();





CREATE OR REPLACE FUNCTION no_studente_professore()
RETURNS TRIGGER AS
$BODY$
	DECLARE
		professore integer;
		studente integer;
	BEGIN
		SELECT count(*) INTO professore FROM Professore WHERE Persona = NEW.Persona;
		SELECT count(*) INTO studente FROM Studente WHERE Persona = NEW.Persona;
		IF ((professore + studente)>1 ) THEN RAISE EXCEPTION $$'Non è possibile inserire % poichè è già uno studente o un professore'$$, NEW.Persona;
		ELSE return NEW;
		END IF;	
		
	END;
$BODY$
LANGUAGE PLPGSQL;

CREATE CONSTRAINT TRIGGER studente_no_professore
AFTER INSERT
ON Studente
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE PROCEDURE no_studente_professore();

CREATE CONSTRAINT TRIGGER professore_no_studente
AFTER INSERT
ON Professore
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE PROCEDURE no_studente_professore();


CREATE OR REPLACE FUNCTION eliminazione_in_università()
RETURNS TRIGGER AS
$BODY$
	DECLARE
		professore integer;
		studente integer;
		aula integer;
		università varchar(50);
	BEGIN
		SELECT Nome INTO università FROM Università WHERE Nome = OLD.Università;
		SELECT count(*) INTO aula FROM Aula WHERE Aula.Università = OLD.Università;
		SELECT count(*) INTO professore FROM Persona JOIN Professore ON Persona.Codice_fiscale = Professore.Persona WHERE Persona.Università = OLD.Università;
		SELECT count(*) INTO studente FROM Persona JOIN Studente ON Persona.Codice_fiscale = Studente.Persona WHERE Persona.Università = OLD.Università;		
		IF ( (aula = 0 or professore = 0 or studente =0) and università is not null) THEN RAISE EXCEPTION $$'Non è possibile eliminare % poichè altrimenti l università non ha almeno un professore,un aula e uno studente'$$, OLD;
		ELSE return NEW;
		END IF;	
		
	END;
$BODY$
LANGUAGE PLPGSQL;

CREATE CONSTRAINT TRIGGER elimina_aula
AFTER DELETE OR UPDATE
ON Aula
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE PROCEDURE eliminazione_in_università();

CREATE CONSTRAINT TRIGGER elimina_persona
AFTER DELETE OR UPDATE
ON Persona
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE PROCEDURE eliminazione_in_università();


CREATE OR REPLACE FUNCTION controllo_positivo()
RETURNS TRIGGER AS
$BODY$
	DECLARE
		tampone_iniziale integer;
		data_tampone date;
	BEGIN
		SELECT count(*) INTO tampone_iniziale FROM Tampone WHERE caso_riferimento = NEW.ID_caso AND Risultato = 'Positivo';
		IF(tampone_iniziale=0) THEN RAISE EXCEPTION $$'Non è possibile inserire % poichè non ha un riferimento al tampone di positività'$$, NEW.ID_caso;
		ELSE 
		SELECT data INTO data_tampone FROM Tampone WHERE caso_riferimento = NEW.ID_caso AND Risultato = 'Positivo';
		IF(NEW.data_positività < data_tampone) THEN RAISE EXCEPTION $$'Non è possibile inserire % poichè ha un riferimento al tampone di positività con data postuma alla segnalazione'$$, NEW.ID_caso;
		ELSIF(NEW.ospedalizzato = true and NEW.sintomatico ='false') THEN RAISE EXCEPTION $$'Non puoi inserire un caso covid ospedalizzato se non è mai stato sintomatico'$$;
		ELSE
		UPDATE Persona SET Stato = 'Positivo' WHERE Codice_fiscale = NEW.Persona;
		END IF;
		return NEW;
		END IF;	
		
	END;
$BODY$
LANGUAGE PLPGSQL;

CREATE CONSTRAINT TRIGGER positivo_valido
AFTER INSERT 
ON Positivo
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE PROCEDURE controllo_positivo();


CREATE OR REPLACE FUNCTION controllo_rimozione_tampone()
RETURNS TRIGGER AS
$BODY$
	DECLARE
		tampone_positivo integer;
		tampone_contatto integer;
		caso_positivo integer;
		caso_contatto integer;
	BEGIN
		SELECT ID_Caso INTO caso_positivo FROM Positivo WHERE ID_Caso = OLD.caso_riferimento;
		SELECT ID_Caso INTO caso_contatto FROM Contatto WHERE ID_Caso = OLD.contatto_riferimento;
		SELECT count(*) INTO tampone_positivo FROM Tampone WHERE caso_riferimento = OLD.caso_riferimento AND Risultato = OLD.Risultato;
		SELECT count(*) INTO tampone_contatto FROM Tampone WHERE contatto_riferimento = OLD.contatto_riferimento;

		IF(OLD.caso_riferimento is null and OLD.contatto_riferimento is not null and caso_contatto is not null and tampone_contatto != 1)  THEN RAISE EXCEPTION $$'Non è possibile rimuovere % poichè non esiste un altro riferimento per il caso covid %'$$, OLD.codice_cun,OLD.contatto_riferimento;
		ELSIF(OLD.caso_riferimento is not null and OLD.contatto_riferimento is null and caso_positivo is not null and tampone_positivo != 1) THEN RAISE EXCEPTION $$'Non è possibile rimuovere % poichè non esiste un altro riferimento per il caso covid %'$$, OLD.codice_cun,OLD.caso_riferimento;
		ELSE return OLD;
		END IF;	
		
	END;
$BODY$
LANGUAGE PLPGSQL;

CREATE CONSTRAINT TRIGGER elimina_tampone
AFTER DELETE OR UPDATE 
ON Tampone
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE PROCEDURE controllo_rimozione_tampone();


CREATE OR REPLACE FUNCTION rimuovi_specializzazione_persona()
RETURNS TRIGGER AS
$BODY$
	DECLARE
		professore integer;
		studente integer;
		persona char(16);
	BEGIN
		SELECT Codice_fiscale into persona FROM Persona WHERE Codice_fiscale = OLD.Persona;
		SELECT count(*) INTO professore FROM Persona JOIN Professore ON Persona.Codice_fiscale = Professore.Persona WHERE Professore.Persona = OLD.Persona;
		SELECT count(*) INTO studente FROM Persona JOIN Studente ON Persona.Codice_fiscale = Studente.Persona WHERE Studente.Persona = OLD.Persona;	
		IF(persona is not null and professore=0 and studente = 0)THEN RAISE EXCEPTION $$'Non è possibile eliminare % poichè altrimenti non è nè un professore nè uno studente'$$, OLD.Persona;
		ELSE return NEW;
		END IF;	
		
	END;
$BODY$
LANGUAGE PLPGSQL;


CREATE CONSTRAINT TRIGGER elimina_padre_professore
AFTER DELETE OR UPDATE
ON Professore
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE PROCEDURE rimuovi_specializzazione_persona();

CREATE CONSTRAINT TRIGGER elimina_padre_studente
AFTER DELETE OR UPDATE
ON Studente
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE PROCEDURE rimuovi_specializzazione_persona();



CREATE OR REPLACE FUNCTION controllo_attività()
RETURNS TRIGGER AS
$BODY$
	DECLARE
		giorno_previsto varchar(9);
		giorno_effettivo varchar(9);
		stato varchar(10);
	BEGIN
		SELECT giorno_settimana INTO giorno_previsto FROM Calendario WHERE codice_attività = NEW.attività_calendario;
		SELECT  to_char(NEW.data_svolgimento,'Day') INTO giorno_effettivo;
		SELECT Persona.Stato INTO stato FROM Persona WHERE Codice_fiscale = NEW.Professore;
		IF((giorno_previsto = 'Lunedì' and giorno_effettivo NOT LIKE 'Monday%')   or (giorno_previsto = 'Martedì' and giorno_effettivo NOT LIKE 'Tuesday%')    or (giorno_previsto = 'Mercoledì' and giorno_effettivo NOT LIKE 'Wednesday%')    or(giorno_previsto = 'Giovedì' and giorno_effettivo NOT LIKE 'Thursday%')    or(giorno_previsto = 'Venerdì' and giorno_effettivo NOT LIKE 'Friday%')        )
		THEN RAISE EXCEPTION $$'Non è possibile inserire l ''attività % in data % poichè non schedulata nel calendario in questo giorno della settimana'$$, NEW.attività_calendario, NEW.data_svolgimento;
		ELSIF(stato != 'Libero' and NEW.modalità != 'Distanza') THEN NEW.modalità = 'Distanza';
		
		END IF;	
		 return NEW;
	END;
$BODY$
LANGUAGE PLPGSQL;


CREATE TRIGGER attività_valida
BEFORE INSERT OR UPDATE
ON Attività
FOR EACH ROW
EXECUTE PROCEDURE controllo_attività();



CREATE OR REPLACE FUNCTION controllo_attività2()
RETURNS TRIGGER AS
$BODY$
	DECLARE
		capienza integer;
		università_attività varchar(50);
		università_professore varchar(50);
	BEGIN
		SELECT Aula.Università INTO università_attività FROM Attività,Calendario,Aula WHERE Attività.attività_calendario = Calendario.Codice_attività AND Calendario.aula = Aula.Codice_aula  AND Attività.attività_calendario = NEW.attività_calendario;
		SELECT Persona.Università INTO università_professore FROM Professore,Persona WHERE Professore.Persona = Persona.Codice_fiscale AND Professore.Persona = NEW.professore;
		SELECT Aula.numero_posti  INTO capienza FROM Calendario JOIN Attività ON Calendario.codice_attività = Attività.attività_calendario JOIN Aula ON Calendario.Aula = Aula.Codice_aula WHERE Attività.attività_calendario = NEW.attività_calendario;
		IF(capienza != NEW.capienza_reale) THEN RAISE EXCEPTION $$'Non è possibile inserire l ''attività % poichè ha un numero di posti non coincidente con l aula in cui è schedulata'$$, NEW.attività_calendario;
		ELSIF(università_attività != università_professore) THEN RAISE EXCEPTION $$'Non è possibile inserire la prenotazione poichè si riferisce ad un attività di un altra università'$$;

		ELSE
		return NEW;
		END IF;
	END;
$BODY$
LANGUAGE PLPGSQL;

		


CREATE TRIGGER attività_valida2
AFTER INSERT OR UPDATE
ON Attività
FOR EACH ROW
EXECUTE PROCEDURE controllo_attività2();
		

CREATE OR REPLACE FUNCTION controllo_anno_studente()
RETURNS TRIGGER AS
$BODY$
	DECLARE
		data_nascita date;
		anno_nascita integer;
	BEGIN
		SELECT Data_di_nascita INTO data_nascita FROM Studente JOIN Persona ON Studente.Persona = Persona.Codice_fiscale WHERE Persona = NEW.Persona;
		SELECT (date_part('year',data_nascita)) INTO anno_nascita;
		IF((NEW.Anno_iscrizione - anno_nascita < 17) or  NEW.Anno_iscrizione > (date_part('year',now())))
		THEN RAISE EXCEPTION $$'Non è possibile inserire lo studente % poichè è iscritto in una data non valida'$$, NEW.Persona;
		ELSIF((NEW.Anno_corso >  ((date_part('year',now()) -NEW.Anno_iscrizione)+1)) or (NEW.Anno_corso <0 or NEW.Anno_corso>5))
		THEN RAISE EXCEPTION $$'Non è possibile inserire lo studente % poichè è iscritto ad un anno non valido per lui'$$, NEW.Persona;
		ELSE return NEW;
		END IF;	
		
	END;
$BODY$
LANGUAGE PLPGSQL;


CREATE CONSTRAINT TRIGGER studente_anno
AFTER INSERT OR UPDATE
ON Studente
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE PROCEDURE controllo_anno_studente();


CREATE OR REPLACE FUNCTION controllo_prenotazione()
RETURNS TRIGGER AS
$BODY$
	DECLARE
		data_attività date;
		università_attività varchar(50);
		università_studente varchar(50);
		stato varchar(10);
		numero_prenotazioni integer;
	BEGIN
		SELECT count(*) INTO numero_prenotazioni FROM Prenotazione WHERE Prenotazione.data_attività = NEW.data_attività AND attività = NEW.attività;
		SELECT Aula.Università INTO università_attività FROM Prenotazione,Attività,Calendario,Aula WHERE Prenotazione.data_attività = Attività.data_svolgimento AND Prenotazione.attività = Attività.attività_calendario AND Attività.attività_calendario = Calendario.Codice_attività AND Calendario.aula = Aula.Codice_aula  AND Prenotazione.data_attività = NEW.data_attività AND Prenotazione.attività = NEW.attività;
		SELECT Persona.Università INTO università_studente FROM Prenotazione,Studente,Persona WHERE Prenotazione.studente = Studente.Persona AND Studente.Persona = Persona.Codice_fiscale AND Prenotazione.studente = NEW.studente;
		SELECT Persona.stato INTO stato FROM Persona WHERE Codice_fiscale = NEW.studente;
		IF(NEW.data_attività < CURRENT_DATE)
		THEN RAISE EXCEPTION $$'Non è possibile inserire la prenotazione poichè si riferisce ad un attività già trascorsa'$$;
		ELSIF(università_attività != università_studente) THEN RAISE EXCEPTION $$'Non è possibile inserire la prenotazione poichè si riferisce ad un attività di un altra università'$$;
		ELSIF(stato = 'Quarantena' or stato ='Positivo' or numero_prenotazioni > (SELECT capienza_predisposta FROM Attività WHERE attività_calendario = NEW.attività AND data_svolgimento = NEW.data_attività ))  THEN 
		UPDATE Attività SET modalità = 'Mista' WHERE data_svolgimento = NEW.data_attività AND attività_calendario = NEW.attività;
		
		END IF;	
		return NEW;
		
	END;
$BODY$
LANGUAGE PLPGSQL;




CREATE CONSTRAINT TRIGGER prenotazione_valida
AFTER INSERT OR UPDATE
ON Prenotazione
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE PROCEDURE controllo_prenotazione();



CREATE OR REPLACE FUNCTION controllo_tampone()
RETURNS TRIGGER AS
$BODY$
	DECLARE
		tampone_positivo integer;
		tampone_negativo integer;
		tampone_contatto integer;
		data_somministrazione date;
		numero_vaccini integer;
		data_contatto date;
		data_positività date;
		contatore integer;
		nuovo_tampone integer;
	BEGIN
		SELECT max(id_caso) into nuovo_tampone FROM Positivo;
		IF((SELECT count(*) FROM Positivo) = 0) THEN contatore = 0;
		ELSE contatore = 1;
		END IF;
		SELECT Data INTO data_positività FROM Tampone WHERE risultato = 'Positivo' AND caso_riferimento = NEW.caso_riferimento;
		SELECT Attestato_contatto.data_somministrazione INTO data_somministrazione FROM Attestato_contatto WHERE ID_caso = NEW.contatto_riferimento ORDER BY Attestato_contatto.data_somministrazione DESC LIMIT 1;
		SELECT count(*) INTO numero_vaccini FROM Attestato_contatto WHERE Attestato_contatto.ID_caso = NEW.contatto_riferimento;
		SELECT Contatto.data_contatto INTO data_contatto FROM Contatto WHERE ID_caso = NEW.contatto_riferimento;
		IF(NEW.caso_riferimento is null AND NEW.contatto_riferimento is null)
			THEN RAISE EXCEPTION $$'Non è possibile inserire % poichè non ha un riferimento a nessun caso covid'$$, NEW.codice_cun;
		ELSIF(NEW.caso_riferimento is not null AND NEW.contatto_riferimento is not null) 
		THEN RAISE EXCEPTION $$'Non è possibile inserire % poichè non si può avere un riferimento ad un positivo ed ad un contatto'$$, NEW.codice_cun;
		ELSIF(NEW.contatto_riferimento is not null AND numero_vaccini >= 3 AND (NEW.Data-data_contatto)<7) THEN RAISE EXCEPTION $$'Non è possibile inserire % poichè per il caso % è prevista una quarantena maggiore'$$, NEW.codice_cun,NEW.contatto_riferimento;
		ELSIF(NEW.contatto_riferimento is not null AND numero_vaccini = 2 AND (NEW.Data-data_contatto<7) AND (CURRENT_DATE-data_somministrazione < 120)) THEN RAISE EXCEPTION $$'Non è possibile inserire % poichè per il caso % è prevista una quarantena maggiore'$$, NEW.codice_cun,NEW.contatto_riferimento;
		ELSIF(NEW.contatto_riferimento is not null AND numero_vaccini = 2 AND (NEW.Data-data_contatto<10) AND (CURRENT_DATE-data_somministrazione > 120)) THEN RAISE EXCEPTION $$'Non è possibile inserire % poichè per il caso % è prevista una quarantena maggiore'$$, NEW.codice_cun,NEW.contatto_riferimento;
		ELSIF(NEW.contatto_riferimento is not null AND numero_vaccini < 2 AND (NEW.Data-data_contatto)<10) THEN RAISE EXCEPTION $$'Non è possibile inserire % poichè per il caso % è prevista una quarantena maggiore'$$, NEW.codice_cun,NEW.contatto_riferimento;
		ELSIF(NEW.Risultato = 'Negativo' and NEW.Data < data_positività) THEN RAISE EXCEPTION $$'Non è possibile inserire % poichè un tampone di accertata negatività non può avere una data antecedente alla positività'$$, NEW.codice_cun;
		ELSIF(NEW.Risultato = 'Negativo' and NEW.contatto_riferimento is not null) THEN 
			UPDATE Persona SET Stato = 'Libero' WHERE Codice_fiscale = (SELECT DISTINCT persona FROM Contatto, Tampone WHERE id_caso = NEW.contatto_riferimento);
		ELSIF(NEW.Risultato = 'Negativo' and NEW.caso_riferimento is not null) THEN
			UPDATE Persona SET Stato = 'Libero' WHERE Codice_fiscale = (SELECT DISTINCT persona FROM Positivo, Tampone WHERE id_caso = NEW.caso_riferimento);
		ELSIF(NEW.Risultato = 'Positivo' and NEW.contatto_riferimento is not null AND contatore = 1) THEN
			UPDATE Persona SET Stato = 'Positivo' WHERE Codice_fiscale IN (SELECT DISTINCT persona FROM Contatto, Tampone WHERE id_caso = NEW.contatto_riferimento);
		    INSERT INTO Positivo VALUES(nuovo_tampone+1,DEFAULT,DEFAULT,NEW.Data,(SELECT DISTINCT persona FROM Contatto, Tampone WHERE id_caso = NEW.contatto_riferimento));
			INSERT INTO Tampone VALUES(DEFAULT,NEW.Data,NEW.Orario,'Positivo',NEW.tipologia,nuovo_tampone+1,NULL);
		ELSIF(NEW.Risultato = 'Positivo' and NEW.contatto_riferimento is not null AND contatore = 0) THEN
			UPDATE Persona SET Stato = 'Positivo' WHERE Codice_fiscale IN (SELECT DISTINCT persona FROM Contatto, Tampone WHERE id_caso = NEW.contatto_riferimento);
		    INSERT INTO Positivo VALUES(1,DEFAULT,DEFAULT,NEW.Data,(SELECT DISTINCT persona FROM Contatto, Tampone WHERE id_caso = NEW.contatto_riferimento));
			INSERT INTO Tampone VALUES(DEFAULT,NEW.Data,NEW.Orario,'Positivo',NEW.tipologia,1,NULL);
		
		END IF;
		return NEW;
		
	END;
$BODY$
LANGUAGE PLPGSQL;

CREATE CONSTRAINT TRIGGER tampone_valido
AFTER INSERT OR UPDATE
ON Tampone
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE PROCEDURE controllo_tampone();



CREATE OR REPLACE FUNCTION controllo_tampone_duplicato()
RETURNS TRIGGER AS
$BODY$
	DECLARE
		tampone_positivo integer;
		tampone_negativo integer;
		tampone_contatto integer;
	BEGIN
			
		IF(NEW.contatto_riferimento is not null) THEN SELECT count(*) INTO tampone_contatto FROM Tampone WHERE contatto_riferimento = NEW.contatto_riferimento;    END IF;
		IF(NEW.caso_riferimento is not null) THEN SELECT count(*) INTO tampone_positivo FROM Tampone WHERE caso_riferimento = NEW.caso_riferimento AND Risultato = 'Positivo';    END IF;
		IF(NEW.caso_riferimento is not null) THEN SELECT count(*) INTO tampone_negativo FROM Tampone WHERE caso_riferimento = NEW.caso_riferimento AND Risultato = 'Negativo';   END IF;
		IF(NEW.contatto_riferimento is not null AND tampone_contatto > 1) THEN RAISE EXCEPTION $$'Non è possibile inserire % poichè esiste già un tampone con riferimento lo stesso caso covid'$$, NEW.codice_cun;   END IF;
		IF(NEW.caso_riferimento is not null AND (tampone_positivo > 1 OR tampone_negativo >1)) THEN  RAISE EXCEPTION $$'Non è possibile inserire % poichè esiste già un tampone con riferimento lo stesso caso covid'$$, NEW.codice_cun;   END IF;
		return NEW;
		
		
	END;
$BODY$
LANGUAGE PLPGSQL;


CREATE CONSTRAINT TRIGGER tampone_duplicato
AFTER INSERT OR UPDATE
ON Tampone
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE PROCEDURE controllo_tampone_duplicato();


CREATE OR REPLACE FUNCTION cambio_attività()
RETURNS TRIGGER AS
$BODY$
	DECLARE
		professore integer;
		data_partenza date;
	BEGIN
		SELECT count(*) INTO professore FROM Professore WHERE Persona = NEW.Codice_fiscale;
		IF(NEW.stato != OLD.stato) THEN
			IF(NEW.stato = 'Quarantena') THEN SELECT data_contatto INTO data_partenza FROM Contatto WHERE persona = NEW.Codice_fiscale ORDER BY data_contatto DESC LIMIT 1;
			
			ELSIF(NEW.stato = 'Positivo') THEN SELECT data_positività INTO data_partenza FROM Positivo WHERE persona = NEW.Codice_fiscale ORDER BY data_positività DESC LIMIT 1;
			END IF;
			
			IF(professore = 0 AND (NEW.stato ='Quarantena' or NEW.stato ='Positivo')) THEN
				UPDATE Attività SET Modalità = 'Mista' WHERE (data_svolgimento,attività_calendario) IN (select data_attività,attività FROM Prenotazione,Attività WHERE data_attività = data_svolgimento AND attività = attività_calendario AND studente = NEW.Codice_fiscale AND modalità ='Presenza' AND data_svolgimento >= data_partenza );
				
			ELSIF(professore=1 AND (NEW.stato='Quarantena' or NEW.stato='Positivo')) THEN
				UPDATE Attività SET Modalità = 'Distanza' WHERE Attività.professore = NEW.Codice_fiscale AND data_svolgimento >= data_partenza;
				
			END IF;	
		END IF;
		return NEW;
		
	END;
$BODY$
LANGUAGE PLPGSQL;

CREATE CONSTRAINT TRIGGER cambio_stato
AFTER UPDATE 
ON Persona
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE PROCEDURE cambio_attività();


CREATE OR REPLACE FUNCTION controllo_contatto()
RETURNS TRIGGER AS
$BODY$
	DECLARE
		
	BEGIN
		UPDATE Persona SET Stato = 'Quarantena' WHERE Codice_fiscale = NEW.Persona;
		
		return NEW;
		
	END;
$BODY$
LANGUAGE PLPGSQL;


CREATE CONSTRAINT TRIGGER contatto_validazione
AFTER INSERT 
ON Contatto
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE PROCEDURE controllo_contatto();



CREATE OR REPLACE FUNCTION cancellazione_positivo()
RETURNS TRIGGER AS
$BODY$
	DECLARE
		check_positivo integer;
		check_negativo integer;
	BEGIN
		SELECT count(*) INTO check_positivo FROM Positivo JOIN Tampone ON Positivo.id_caso = Tampone.caso_riferimento WHERE id_caso = OLD.id_caso AND Tampone.Risultato = 'Positivo';
		SELECT count(*) INTO check_negativo FROM Positivo JOIN Tampone ON Positivo.id_caso = Tampone.caso_riferimento WHERE id_caso = OLD.id_caso AND Tampone.Risultato = 'Negativo';
		IF(check_positivo = check_negativo) THEN UPDATE Persona SET Stato = 'Libero' WHERE Stato = 'Positivo' AND Codice_fiscale = OLD.persona; 
		
		
		END IF;
		RETURN NEW;
	END;
$BODY$
LANGUAGE PLPGSQL;



CREATE CONSTRAINT TRIGGER reset_positivo
AFTER UPDATE OR DELETE 
ON Positivo
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE PROCEDURE cancellazione_positivo();




CREATE OR REPLACE FUNCTION cancellazione_contatto()
RETURNS TRIGGER AS
$BODY$
	DECLARE
		altro_contatto integer;
	BEGIN
		SELECT count(*) INTO altro_contatto FROM Contatto LEFT JOIN Tampone ON Contatto.id_caso = Tampone.contatto_riferimento WHERE persona = OLD.persona AND Tampone.Risultato is null;
		IF(altro_contatto=0) THEN UPDATE Persona SET Stato = 'Libero' WHERE Stato = 'Quarantena' AND Codice_fiscale = OLD.persona; 
		
		
		END IF;
		RETURN NEW;
	END;
$BODY$
LANGUAGE PLPGSQL;



CREATE CONSTRAINT TRIGGER reset_contatto
AFTER UPDATE OR DELETE 
ON Contatto
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE PROCEDURE cancellazione_contatto();