/*Ceci est un test pour Git, ne fait pas attention*/

create or replace function nbParts() returns int as 
$$
DECLARE
n int;
begin
	select count(*) into n from parts;
	return n;
end

$$ language plpgsql;

select nbparts();
