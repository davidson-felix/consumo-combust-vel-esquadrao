-- =============================================================================
-- SCHEMA — Projeto de Portfólio: Consumo de Combustível e Orçamento de
-- Esquadrão Naval (dados 100% sintéticos)
-- =============================================================================
-- Compatível com SQLite (usado no projeto). Para Postgres/MySQL, troque
-- TEXT por VARCHAR e ajuste tipos de data conforme o dialeto.

-- Dimensão: embarcações do esquadrão fictício
CREATE TABLE dim_embarcacoes (
    vessel_id                  TEXT PRIMARY KEY,
    vessel_name                TEXT NOT NULL,
    vessel_class               TEXT NOT NULL,       -- 'Fragata' ou 'Corveta'
    capacidade_tanque_litros   INTEGER NOT NULL
);

-- Fato: consumo mensal de combustível por embarcação
CREATE TABLE fato_consumo_combustivel (
    record_id               INTEGER PRIMARY KEY,
    vessel_id                TEXT NOT NULL REFERENCES dim_embarcacoes(vessel_id),
    competencia               TEXT NOT NULL,          -- primeiro dia do mês, formato YYYY-MM-01
    categoria_operacional     TEXT NOT NULL,          -- 'Operação' | 'Manutenção' | 'Treinamento'
    litros_cota_alocada       INTEGER NOT NULL,       -- cota mensal definida
    litros_consumidos          INTEGER NOT NULL        -- consumo real apurado
);

-- Fato: orçamento mensal por embarcação e categoria de despesa
CREATE TABLE fato_orcamento (
    record_id               INTEGER PRIMARY KEY,
    vessel_id                TEXT NOT NULL REFERENCES dim_embarcacoes(vessel_id),
    competencia               TEXT NOT NULL,
    categoria_despesa         TEXT NOT NULL,          -- 'Combustível' | 'Manutenção' | 'Suprimentos' | 'Pessoal (Extras)'
    orcamento_alocado_brl     REAL NOT NULL,
    orcamento_gasto_brl        REAL NOT NULL
);

CREATE INDEX idx_combustivel_vessel ON fato_consumo_combustivel(vessel_id, competencia);
CREATE INDEX idx_orcamento_vessel ON fato_orcamento(vessel_id, competencia);
