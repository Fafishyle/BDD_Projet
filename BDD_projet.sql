/* Fonction name_catalog
 * ne prend rien en paramètre
 * parcourt la table META
 * retourne un ensemble de chaine de caractère qui sont les noms des catalogues 
 */ 
create or replace function name_catalog() returns setof meta.table_name%type as $$
declare
	nuplet record;
begin 
	for nuplet in SELECT * FROM meta loop
		return next nuplet.table_name;
	end loop;
return;
end
$$ language plpgsql;

/* Type catalog_attribute 
 * cat : le nom du catalogue
 * cat_name : le nom de l'attribut contennant "name" 
 * cat_price : le nom de l'attribut contennant "price" 
 */
CREATE TYPE catalog_attribute AS (
	cat VARCHAR(255),
	cat_name VARCHAR(50),
	cat_price numeric(8,2) 
 ); 

/* Fonction unify_catalog 
 * ne prend rien en paramètre
 * ne retourne rien 
 */
create or replace function unify_catalog() returns void as $$
declare
	/* uplet_name_catalog : parcours les noms des catalogues
 	*  tab_cat_attribute : enregistrements des noms des catalogue, des attributs qui contiennent name et price 
 	*/
	uplet_name_catalog record;
	tab_cat_attribute catalog_attribute;
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
	/*Récupère pour chaque catalogue 
	 * les noms des attributs 
	 * qui contiennent "name" et "price"
	 */
	for uplet_name_catalog in SELECT * FROM name_catalog()loop
		tab_cat_attribute.cat := uplet_name_catalog;
		/*tab_cat_attribute.cat_name :=;
		tab_cat_attribute.cat_price :=;*/
	end loop; 
	
end
$$language plpgsql;

select unify_catalog();