
-- QUERY: Media giorni positività per Regione

SELECT Università.Regione,ROUND(CAST(avg(data-data_positività)as integer)) as Media_giorni_positività 
FROM Positivo JOIN Tampone 
ON Positivo.id_caso = Tampone.caso_riferimento
JOIN Persona 
ON Positivo.Persona = Persona.Codice_fiscale 
JOIN Università 
ON Persona.Università = Università.Nome 
WHERE Tampone.Risultato = 'Negativo' 
GROUP BY Università.Regione;


-- QUERY: Ricerca vaccinati con due dosi positivi per più di 21 giorni

SELECT * FROM Persona 
WHERE 21<(SELECT data-data_positività FROM Positivo JOIN Tampone
		  ON Positivo.id_caso = Tampone.caso_riferimento 
		  WHERE Tampone.Risultato = 'Negativo' and Positivo.persona = Persona.Codice_fiscale AND 1<(SELECT count(*) FROM Attestato_Positivo 
																		 WHERE Attestato_Positivo.id_caso = Positivo.id_caso)
);

-- QUERY: Lista aulee e stato al momento della ricerca di una particolare università / di tutte le università


SELECT codice_aula,Aula.nome,numero_posti,edificio,'Occupata' as Stato_attuale FROM Aula JOIN Calendario ON Aula.codice_aula = Calendario.aula JOIN Attività ON Calendario.codice_attività = Attività.attività_calendario JOIN Università ON Aula.Università = Università.Nome WHERE Università ='Università degli studi di Salerno' AND  CURRENT_TIME(0) BETWEEN Calendario.orario_inizio AND Calendario.orario_fine AND Attività.modalità != 'Distanza' AND Attività.data_svolgimento = CURRENT_DATE
UNION
SELECT codice_aula,Aula.nome,numero_posti,edificio, 'Libera' as Stato_attuale FROM Aula JOIN Università ON Aula.Università = Università.Nome AND Università = 'Università degli studi di Salerno' 
EXCEPT
SELECT codice_aula,Aula.nome,numero_posti,edificio,'Libera' as Stato_attuale FROM Aula JOIN Calendario ON Aula.codice_aula = Calendario.aula JOIN Attività ON Calendario.codice_attività = Attività.attività_calendario JOIN Università ON Aula.Università = Università.Nome WHERE Università ='Università degli studi di Salerno' AND  CURRENT_TIME(0) BETWEEN Calendario.orario_inizio AND Calendario.orario_fine AND Attività.modalità != 'Distanza' AND Attività.data_svolgimento = CURRENT_DATE;


SELECT codice_aula,Aula.nome,numero_posti,edificio,università,'Occupata' as Stato_attuale FROM Aula JOIN Calendario ON Aula.codice_aula = Calendario.aula JOIN Attività ON Calendario.codice_attività = Attività.attività_calendario JOIN Università ON Aula.Università = Università.Nome  AND  CURRENT_TIME(0) BETWEEN Calendario.orario_inizio AND Calendario.orario_fine AND Attività.modalità != 'Distanza' AND Attività.data_svolgimento = CURRENT_DATE
UNION
SELECT codice_aula,Aula.nome,numero_posti,edificio,università, 'Libera' as Stato_attuale FROM Aula JOIN Università ON Aula.Università = Università.Nome 
EXCEPT
SELECT codice_aula,Aula.nome,numero_posti,edificio,università,'Libera' as Stato_attuale FROM Aula JOIN Calendario ON Aula.codice_aula = Calendario.aula JOIN Attività ON Calendario.codice_attività = Attività.attività_calendario JOIN Università ON Aula.Università = Università.Nome AND  CURRENT_TIME(0) BETWEEN Calendario.orario_inizio AND Calendario.orario_fine AND Attività.modalità != 'Distanza' AND Attività.data_svolgimento = CURRENT_DATE;


-- QUERY: Ricerca attività svolte oggi dai positivi odierni e tracciamento dei contatti di una particolare università / di tutte le università


INSERT INTO Contatto (persona) (SELECT Studente as contatto FROM Prenotazione WHERE (data_attività,attività) IN (SELECT DISTINCT data_attività,attività 
								FROM Prenotazione 
								WHERE data_attività = CURRENT_DATE AND Studente IN (SELECT Persona.Codice_fiscale 
												FROM Positivo,Persona,Università WHERE Positivo.persona = Persona.Codice_fiscale AND Persona.Università = Università.Nome AND Università.Nome = 'Università degli studi di Salerno' AND Positivo.data_positività = CURRENT_DATE
) UNION (SELECT DISTINCT data_svolgimento as data_attività,attività_calendario as attività FROM Attività WHERE data_svolgimento = CURRENT_DATE AND professore IN(SELECT Persona.Codice_fiscale 
												FROM Positivo,Persona,Università WHERE Positivo.persona = Persona.Codice_fiscale AND Persona.Università = Università.Nome AND Università.Nome = 'Università degli studi di Salerno' AND Positivo.data_positività = CURRENT_DATE)) )							
													 AND studente IN (SELECT Persona.Codice_fiscale 
													 FROM Persona 
													 WHERE stato = 'Libero')) UNION
	(SELECT Professore as contatto FROM Attività WHERE (data_svolgimento,attività_calendario) IN (SELECT DISTINCT data_attività,attività
								FROM Prenotazione 
							WHERE data_attività = CURRENT_DATE AND Studente IN (SELECT Persona.Codice_fiscale 
												FROM Positivo,Persona,Università WHERE Positivo.persona = Persona.Codice_fiscale AND Persona.Università = Università.Nome AND Università.Nome = 'Università degli studi di Salerno' AND Positivo.data_positività = CURRENT_DATE
) 
																		
													 AND professore IN (SELECT Persona.Codice_fiscale 
													 FROM Persona 
													 WHERE stato = 'Libero')))
;



INSERT INTO Contatto (persona) (SELECT Studente as contatto FROM Prenotazione WHERE (data_attività,attività) IN (SELECT DISTINCT data_attività,attività 
								FROM Prenotazione 
								WHERE data_attività = CURRENT_DATE AND Studente IN (SELECT Persona.Codice_fiscale 
												FROM Positivo,Persona,Università WHERE Positivo.persona = Persona.Codice_fiscale AND Persona.Università = Università.Nome  AND Positivo.data_positività = CURRENT_DATE
) UNION (SELECT DISTINCT data_svolgimento as data_attività,attività_calendario as attività FROM Attività WHERE data_svolgimento = CURRENT_DATE AND professore IN(SELECT Persona.Codice_fiscale 
												FROM Positivo,Persona,Università WHERE Positivo.persona = Persona.Codice_fiscale AND Persona.Università = Università.Nome  AND Positivo.data_positività = CURRENT_DATE)) )							
													 AND studente IN (SELECT Persona.Codice_fiscale 
													 FROM Persona 
													 WHERE stato = 'Libero')) UNION
	(SELECT Professore as contatto FROM Attività WHERE (data_svolgimento,attività_calendario) IN (SELECT DISTINCT data_attività,attività
								FROM Prenotazione 
							WHERE data_attività = CURRENT_DATE AND Studente IN (SELECT Persona.Codice_fiscale 
												FROM Positivo,Persona,Università WHERE Positivo.persona = Persona.Codice_fiscale AND Persona.Università = Università.Nome  AND Positivo.data_positività = CURRENT_DATE
) 
																		
													 AND professore IN (SELECT Persona.Codice_fiscale 
													 FROM Persona 
													 WHERE stato = 'Libero')))
;


-- Per controllare l'effettivo inserimento
SELECT * FROM Contatto;


-- VISTA

CREATE View VistaSupporto(Università,Numero_iscritti) as (SELECT Università.Nome, count(Persona.Codice_fiscale) FROM Università,Persona WHERE Università.Nome = Persona.Università  GROUP BY Università.Nome) ; 
CREATE View StatoUniversità(Università,Numero_iscritti, Numero_positivi,Indice_positività, Posti_disponibili,Regione,Città,Via,Cap,Civico) as (SELECT VistaSupporto.università,VistaSupporto.numero_iscritti,count(Persona.Codice_fiscale),ROUND(CAST(CAST(count(Persona.Codice_fiscale) as float) as numeric)/numero_iscritti,2),posti_disponibili,regione,città,via,cap,civico FROM VistaSupporto,Persona,Università WHERE VistaSupporto.università = Persona.Università AND VistaSupporto.Università = Università.Nome AND Persona.Stato = 'Positivo' GROUP BY VistaSupporto.università,VistaSupporto.numero_iscritti,Università.posti_disponibili,Università.regione,Università.cap,Università.via,Università.civico,Università.città);
SELECT * FROM StatoUniversità;

-- QUERY CON VISTA: Età media studenti positivi nell'università con più casi covid positivi al momento

SELECT Persona.Università as Università_con_più_casi,CAST(avg(CURRENT_DATE-data_di_nascita)/365 as integer) as Età_media_positivi FROM Persona 
WHERE Università IN (SELECT università FROM StatoUniversità 
					 WHERE numero_positivi = (SELECT max(numero_positivi) FROM StatoUniversità)) 
					 AND Stato = 'Positivo' AND EXISTS (SELECT persona FROM Studente WHERE studente.persona = persona.codice_fiscale) GROUP BY Persona.Università;

