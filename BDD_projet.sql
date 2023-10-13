/* Type catalog_attribute 
 * cat : le nom du catalogue
 * cat_name : le nom de l'attribut contennant "name" 
 * cat_price : le nom de l'attribut contennant "price" 
 */
/*CREATE TYPE catalog_attribute AS (
	cat VARCHAR(255),
	cat_name VARCHAR(50),
	cat_price numeric(8,2) 
 ); */

/* Fonction unify_catalog 
 * ne prend rien en paramètre
 * ne retourne rien 
 */
create or replace function unify_catalog() returns void as $$
declare
	/* cat : nom de catalogue
	 * catalog_name_price :  tableau bidimensionnel à 3 colonnes: 
	 * 		colonne 1 : des noms de catalogue
	 * 		colonne 2 : son attribut avec name
	 * 		colonne 3 : son attribut avec price
	 * tampon : chaine de caractère variable tampon
	 * i : compteur de parcours de table Meta 
	 * indicePid : compteur du pid dans la table C_ALL
	 * requete : permet de construire une requete qui renvoie un enregistrement
	 * code : permet de recuperer trans_code de la table META
	 */
	cat VARCHAR;
	catalog_name_price VARCHAR[][];
	tampon VARCHAR;
	i INT := 1 ;
	indicePid int := 1;

	cursDyn REFCURSOR;
	requete VARCHAR; 
	res record;
	code VARCHAR;

begin
	/*Détruit la table C_ALL si elle existe */
	DROP TABLE IF exists C_ALL;

	/*Crée une table C_ALL*/
	CREATE TABLE C_ALL
	(
    	pid NUMERIC(5)PRIMARY KEY,
    	pname VARCHAR(50),
    	pprice NUMERIC(8,2)
	);
	
	/*
	 * Initialisation du tableau bidimensionnel catalog_name_price
	 */
	catalog_name_price := ARRAY[ [null,null,null], [null, null,null], [null, null,null] ];

	/* Parcourt la table META
	 * pour obtenir les noms des catalogues , les attributs contenant name et price
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

		i:= i + 1;
	end loop;

	/* Charge dynamiquement les données de chaque catalogue dans C_ALL, connaissant le nom des
	 * attributs nom et prix précédemment trouvés
	 * */
    for i in 1..array_length(catalog_name_price, 1) loop --on fait la boucle pour toutes les tables disponible dans catalog_name_price

        -- Construction de la requête : retourne un enregistrement composé de pid, attribut name et attribut price
        requete := 'SELECT ' || i || ', ' || catalog_name_price[i][2] || ' AS pname, ' || catalog_name_price[i][3] || ' AS pprice FROM ' || catalog_name_price[i][1];

       -- Parcours du curseur dynamique
        OPEN cursDyn FOR EXECUTE requete;
        LOOP
            FETCH cursDyn into res;
            EXIT WHEN NOT FOUND;

            raise notice 'L enregistrement est : %', res;
           /* On regarde dans la table meta si la table ou on est a des codes specifiques
            * a appliquer a ses données avant de les inserer dans la table C_ALL
            */
            SELECT trans_code INTO code 
          	FROM meta 
         	WHERE table_name = UPPER(catalog_name_price[i][1]);
  
         
       	 	/* On regarde que le code qui correspond à la table ou l'onest, n'est pas null
          	*/
			IF code IS NOT NULL then
				/* Le code contient 'CAP'
				 * on met le nom du produit en majuscule
				 * en modifiant la valeur res.pname
				 */
           		IF code LIKE '%CAP%' THEN
           			res.pname := UPPER(res.pname);
           		END IF;
	           	/* Le code contient 'CUP'
				 * on fait une conversion dollars vers euro du prix du produit
				 * en modifiant res.pprice
				 */
           		IF code LIKE '%CUR%' THEN
           			res.pprice := res.pprice / 1.05;
           		END IF;
			END IF;
			/* On peut inserer dynamiquement les données dans C_ALL
			 * après avoir effectué toutes les modifications nécessaires
			 * grace au trans_code
			 */
            INSERT INTO C_ALL (pid, pname, pprice) VALUES (indicePid, res.pname, res.pprice);
           	-- FETCH cursDyn into res; --Si on met cette ligne on a pas toutes les lignes 
           	indicePid := indicePid + 1;
        END LOOP;
        CLOSE cursDyn;
    end loop;

   exception
		/* Si une requête renvoie null, on arrête le programme 
 		 */
        when NO_DATA_FOUND then
            raise exception 'Aucune donnée trouvée dans la requête.';
end
$$language plpgsql;

select unify_catalog();

/*
create or replace function f()returns void as $$
declare
test varchar;
cat varchar[][];

begin
cat := ARRAY[ [null,null], [null, null], [null, null] ];
cat[1][1] := 'c2';
		SELECT column_name into test
		FROM information_schema.columns
		WHERE table_name = 'c1';
		cat[1][2] := test;
	raise notice '%',cat[1][2];
end

$$ language plpgsql;
select f();*/
