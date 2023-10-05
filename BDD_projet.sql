create or replace function unify () returns void as $$
begin
	/*Détruit la table C_ALL si elle existe */
	DROP TABLE IF exists C_ALL;
end
$$language plpgsql;

select unify();