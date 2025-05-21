CREATE TABLE IF NOT EXISTS public.postg_ipca (
  id SERIAL PRIMARY KEY,
  nome TEXT,
  valor NUMERIC,
  dt_update TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.postg_pre (
  id SERIAL PRIMARY KEY,
  nome TEXT,
  valor NUMERIC,
  dt_update TIMESTAMP
);