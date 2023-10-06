/*Parcourt la table META pour obtenir les noms des catalogues*/
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
/* Fonction unify_catalog 
 * ne prend rien en paramètre
 * ne retourne rien */
create or replace function unify_catalog() returns void as $$
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
	
	/**/
	SELECT name_catalog();

	/*Récupère dans le schéma de chaque catalogue 
	 * les noms des attributs qui contiennent 
	 * name et price,
	 * respectivement ;*/
	
end
$$language plpgsql;

select unify_catalog();