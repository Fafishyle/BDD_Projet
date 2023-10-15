/* Fonction unify_catalog 
 * ne prend rien en paramètre
 * intégre dans la table C_ALL (un seul catalogue unifié) différents catalogues
 * ne retourne rien
 */
create or replace function unify_catalog() returns void as $$
declare
	/* cat : nom de catalogue
	 * count_catalog : 
	 * catalog_name_price :  tableau bidimensionnel à 3 colonnes: 
	 * 		colonne 1 : des noms de catalogue
	 * 		colonne 2 : son attribut avec name
	 * 		colonne 3 : son attribut avec price
	 * tampon : chaine de caractère variable tampon
	 * i : compteur de parcours de table Meta 
	 * indicePid : compteur du pid dans la table C_ALL
	 * cursDyn : 
	 * requete : permet de construire une requete qui renvoie un enregistrement
	 * res :
	 * code : permet de recuperer trans_code de la table META
	 */
	cat VARCHAR;
	catalog_name_price VARCHAR[][];
	count_catalog INT := 0;
	tampon VARCHAR;
	i INT := 1;
	indicePid int := 1;
	cursDyn REFCURSOR;
	requete VARCHAR; 
	res record;
	code VARCHAR;

begin
	-- Détruit la table C_ALL si elle existe
	DROP TABLE IF exists C_ALL;

	-- Crée une table C_ALL
	CREATE TABLE C_ALL
	(
    	pid NUMERIC(5)PRIMARY KEY,
    	pname VARCHAR(50),
    	pprice NUMERIC(8,2)
	);
	
	
	-- Insérer le nombre de catalogue de la table META dans count_catalog
	select count(*) into count_catalog from meta;

	/* Initialisation du tableau bidimensionnel catalog_name_price
	 * 	de 3 colonnes : "catalog", "name" et "price"
	 * 	de count_catalog lignes, où count_catalog est le nombre total de catalogue
	 *  et de valeur null 
	 */
	catalog_name_price := array_fill(NULL::int, ARRAY[count_catalog, 3]);
	
	/* Parcourt la table META
	 * pour obtenir les noms des catalogues , 
	 * les attributs contenant name et price
	 */
	for cat in SELECT table_name FROM meta loop
		catalog_name_price[i][1] := LOWER(cat);
		raise notice 'Pour le catalogue : %',catalog_name_price[i][1];

		/* Récupère dans le schéma de chaque catalogue
	 	 * les noms des attributs qui contiennent name et price, respectivement
	 	 */ 
		SELECT column_name into tampon
		FROM information_schema.columns
		WHERE table_name = LOWER(cat)
		and 
		column_name LIKE '%name%';
		catalog_name_price[i][2] := tampon;
		raise notice '- d attribut name : %',catalog_name_price[i][2];

		SELECT column_name into tampon
		FROM information_schema.columns 
		WHERE table_name = LOWER(cat)
		and column_name LIKE '%price%';
		catalog_name_price[i][3] := tampon;
		raise notice '- d attribut price : %',catalog_name_price[i][3];

		/* Pour chaque table disponible dans catalog_name_price
	 	 * on charge dynamiquement les données dans C_ALL, 
	 	 * à partir des noms des attributs name et price précédemment trouvés
	 	 * 
         * Construction de la requête du curseur dynamique
         * requete retournera un enregistrement (numéro du catalogue, attribut name, attribut price)
         */
        requete := 'SELECT ' || indicePid || 'AS pid, ' || catalog_name_price[i][2] || ' AS pname, ' || catalog_name_price[i][3] || ' AS pprice FROM ' || catalog_name_price[i][1];
        if requete is null then
			raise exception 'Le catalogue % (ou un de ses attributs) de la table META, n existe pas.', catalog_name_price[i][1] ;
		end if;
        OPEN cursDyn FOR EXECUTE requete;
       	FETCH cursDyn into res;
        LOOP
            EXIT WHEN NOT FOUND;
            res.pid := indicePid;
            raise notice 'L enregistrement (pid, pname , pprice) est : %', res;
           
           /* Verifie dans la table META 
            * si on doit appliquer des transformations aux données
            * avant de les inserer dans la table C_ALL
            */
            SELECT trans_code INTO code
          	FROM meta 
         	WHERE table_name = UPPER(catalog_name_price[i][1]);  		   
			IF code IS NOT NULL then
				/* Le code contient 'CAP'
				 * mettre le nom du produit en majuscule
				 */
           		IF code LIKE '%CAP%' THEN
           			res.pname := UPPER(res.pname);
           		END IF;
	           	/* Le code contient 'CUR'
				 * convertit le prix du produit dollars en euro
				 */
           		IF code LIKE '%CUR%' THEN
           			res.pprice := res.pprice / 1.05;
           		END IF;
			END IF;
        	raise notice '	et en appliquant les transformations : % .', res;
		
			/* Insere les données dans C_ALL
			 * après avoir effectué toutes les modifications nécessaires
			 */
            INSERT INTO C_ALL (pid, pname, pprice) VALUES (res.pid, res.pname, res.pprice);
            FETCH cursDyn into res;
           	indicePid := indicePid + 1;
        END LOOP;
        CLOSE cursDyn;
       i:= i + 1;
      raise notice E'\n';
    end loop;

   exception
		-- Si une requête renvoie null, on arrête le programme 
        when NO_DATA_FOUND then
            raise exception 'Aucune donnée trouvée dans la requête.';
end
$$language plpgsql;

-- Teste la fonction unify_catalog, fait des affichages
select unify_catalog();
