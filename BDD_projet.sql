/* Fonction unify_catalog 
 * ne prend rien en paramètre
 * intégre dans la table C_ALL (un seul catalogue unifié) les données de différents catalogues
 * fait des affichages
 * ne retourne rien
 */
create or replace function unify_catalog() returns void as $$
declare
	/* cat : nom de catalogue
	 * att_name : attribut d'un catalogue contennant name
	 * att_price : attribut d'un catalogue contennant price
	 * indicePid : clef primaire de la table C_ALL
	 * cursDyn : curseur dynamique
	 * requete : permet de construire une requete qui cherche à partir du pid, du nom de l'attribut name et du nom de l'attribut pprice
	 * res : enregistrement resultat (pid, pname, pprice) à charger dans la table
	 * code : permet de récupérer trans_code de la table META
	 */
	cat VARCHAR;
	att_name VARCHAR;
	att_price VARCHAR;
	indicePid int := 1;
	cursDyn REFCURSOR;
	requete VARCHAR; 
	res record;
	code VARCHAR;

BEGIN
	-- Détruit la table C_ALL si elle existe
	DROP TABLE IF exists C_ALL;
	-- Crée une table C_ALL
	CREATE TABLE C_ALL
	(
    	pid NUMERIC(5)PRIMARY KEY,
    	pname VARCHAR(50),
    	pprice NUMERIC(8,2)
	);
	-- Parcourt la table META
	for cat in SELECT table_name FROM meta loop
		cat := LOWER(cat);
		raise notice 'Pour le catalogue : %',cat;
		/* Récupère dans le schéma de chaque catalogue
	 	 * les noms des attributs qui contiennent name
	 	 */ 
		SELECT column_name into att_name
		FROM information_schema.columns
		WHERE table_name = cat
		and 
		column_name ILIKE '%name%';
		raise notice '- d attribut name : %',att_name;
		/* Récupère dans le schéma de chaque catalogue
	 	 * les noms des attributs qui contiennent price
	 	 */ 
		SELECT column_name into att_price
		FROM information_schema.columns 
		WHERE table_name = cat
		and column_name ILIKE '%price%';
		raise notice '- d attribut price : %',att_price;
		/* Pour chaque table disponible dans catalog_name_price
	 	 * charge dynamiquement les données dans C_ALL, 
	 	 * à partir des noms des attributs name et price précédemment trouvés 
         * Construction de la requête du curseur dynamique
         */
        requete := 'SELECT ' 
        			|| indicePid || 'AS pid, '
       				|| att_name  || ' AS pname, ' 
       				|| att_price || ' AS pprice 
					FROM ' || cat;
        if requete is null then
			raise exception 'Le catalogue % (ou un de ses attributs) de la table META, n existe pas.', cat ;
		end if;
        OPEN cursDyn FOR EXECUTE requete;
       	FETCH cursDyn into res;
        LOOP
            EXIT WHEN NOT FOUND;
            res.pid := indicePid;
            raise notice 'L enregistrement (pid, pname , pprice) est : %', res;
           /* Verifie dans la table META 
            * si des transformations sont à appliquer  aux données
            * avant de les inserer dans la table C_ALL
            */
            SELECT trans_code INTO code
          	FROM meta
         	WHERE table_name = UPPER(cat);  		   
			IF code IS NOT NULL then
				/* Si code contient 'CAP'
				 * mettre le nom du produit en majuscule
				 */
           		IF code LIKE '%CAP%' THEN
           			res.pname := UPPER(res.pname);
           		END IF;
	           	/* Si code contient 'CUR'
				 * convertit le prix du produit (qui est en dollars) en euro
				 */
           		IF code LIKE '%CUR%' THEN
           			res.pprice := res.pprice / 1.05;
           		END IF;
           		raise notice '	et en appliquant les transformations : % .', res;
			END IF;
			/* Insère les données dans C_ALL
			 * après avoir effectué toutes les modifications nécessaires
			 */
            INSERT INTO C_ALL (pid, pname, pprice) VALUES (res.pid, res.pname, res.pprice);
            FETCH cursDyn into res;
           	indicePid := indicePid + 1;
        END LOOP;
        CLOSE cursDyn;
      raise notice E'\n';
    end loop;

   EXCEPTION
		-- Si une requête renvoie null, on arrête le programme 
        when NO_DATA_FOUND then
            raise exception 'Aucune donnée trouvée dans la requête.';
           
END
$$language plpgsql;

-- Teste la fonction unify_catalog, voir la sortie pour les affichages
SELECT unify_catalog();
