-- v184: a "N Seater" car carries N-1 passengers (the driver takes one seat). Stored seats = passenger seats.
-- (applied live; triggers fix new categories/vehicles typed as N; existing 5 Seater->4, 7 Seater->6, Sienta->6, MH1234->6)
create or replace function public._seater_n(p_name text) returns int language sql immutable as $$
  select (regexp_match(lower(coalesce(p_name, '')), '(\d+)\s*-?\s*seat'))[1]::int $$;
-- triggers trg_cat_seater_fix (vehicle_categories) and trg_truck_seater_fix (trucks) set seats = N-1 when seats = N
