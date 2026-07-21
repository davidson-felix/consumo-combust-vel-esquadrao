-- =============================================================================
-- CONSULTAS — Projeto de Portfólio: Consumo de Combustível e Orçamento
-- Cada bloco resolve uma pergunta de negócio real e está mapeado a um
-- tópico do roteiro de estudo (SELECT básico -> window functions).
-- Dialeto: SQLite (funções de data usam strftime).
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1) SELECT + WHERE + ORDER BY + LIMIT
-- Pergunta: quais foram os 10 meses/embarcação com maior consumo em 2024?
-- -----------------------------------------------------------------------------
SELECT vessel_id, competencia, categoria_operacional, litros_consumidos
FROM fato_consumo_combustivel
WHERE competencia LIKE '2024%'
ORDER BY litros_consumidos DESC
LIMIT 10;


-- -----------------------------------------------------------------------------
-- 2) GROUP BY + HAVING
-- Pergunta: quais embarcações têm consumo médio mensal acima de 30.000 L?
-- (HAVING filtra depois da agregação, diferente do WHERE)
-- -----------------------------------------------------------------------------
SELECT vessel_id, ROUND(AVG(litros_consumidos), 0) AS consumo_medio_mensal
FROM fato_consumo_combustivel
GROUP BY vessel_id
HAVING AVG(litros_consumidos) > 30000
ORDER BY consumo_medio_mensal DESC;


-- -----------------------------------------------------------------------------
-- 3) INNER JOIN
-- Pergunta: qual o nome e a classe da embarcação em cada registro de consumo?
-- -----------------------------------------------------------------------------
SELECT f.competencia, e.vessel_name, e.vessel_class, f.litros_consumidos
FROM fato_consumo_combustivel f
INNER JOIN dim_embarcacoes e ON e.vessel_id = f.vessel_id
ORDER BY f.competencia, e.vessel_name
LIMIT 20;


-- -----------------------------------------------------------------------------
-- 4) LEFT JOIN
-- Pergunta: existe algum mês em que uma embarcação NÃO tem lançamento de
-- orçamento de combustível? (LEFT JOIN + IS NULL é o padrão clássico para
-- achar "o que falta")
-- -----------------------------------------------------------------------------
SELECT f.vessel_id, f.competencia
FROM fato_consumo_combustivel f
LEFT JOIN fato_orcamento o
    ON o.vessel_id = f.vessel_id
    AND o.competencia = f.competencia
    AND o.categoria_despesa = 'Combustível'
WHERE o.record_id IS NULL;
-- (resultado esperado: vazio — confirma integridade dos dados sintéticos)


-- -----------------------------------------------------------------------------
-- 5) Funções agregadas (COUNT, SUM, AVG, MIN, MAX)
-- Pergunta: visão geral do consumo no período todo
-- -----------------------------------------------------------------------------
SELECT
    COUNT(*)                           AS total_registros,
    SUM(litros_consumidos)             AS total_litros_consumidos,
    ROUND(AVG(litros_consumidos), 0)   AS media_mensal_por_registro,
    MIN(litros_consumidos)             AS menor_consumo_registrado,
    MAX(litros_consumidos)             AS maior_consumo_registrado
FROM fato_consumo_combustivel;


-- -----------------------------------------------------------------------------
-- 6) CASE WHEN
-- Pergunta: em cada registro, a embarcação ficou DENTRO ou ESTOUROU a cota
-- de combustível? Por quanto (%)?
-- -----------------------------------------------------------------------------
SELECT
    vessel_id, competencia, litros_cota_alocada, litros_consumidos,
    ROUND(100.0 * (litros_consumidos - litros_cota_alocada) / litros_cota_alocada, 1) AS variacao_pct,
    CASE
        WHEN litros_consumidos > litros_cota_alocada THEN 'ESTOUROU A COTA'
        WHEN litros_consumidos > litros_cota_alocada * 0.95 THEN 'NO LIMITE'
        ELSE 'DENTRO DA COTA'
    END AS status_cota
FROM fato_consumo_combustivel
ORDER BY variacao_pct DESC
LIMIT 15;


-- -----------------------------------------------------------------------------
-- 7) Subquery (query dentro de query)
-- Pergunta: quais embarcações consomem acima da média geral da frota?
-- -----------------------------------------------------------------------------
SELECT vessel_id, ROUND(AVG(litros_consumidos), 0) AS consumo_medio
FROM fato_consumo_combustivel
GROUP BY vessel_id
HAVING AVG(litros_consumidos) > (
    SELECT AVG(litros_consumidos) FROM fato_consumo_combustivel
)
ORDER BY consumo_medio DESC;


-- -----------------------------------------------------------------------------
-- 8) CTE (WITH) — deixa a query legível em etapas nomeadas
-- Pergunta: gasto total (combustível + demais categorias) por embarcação,
-- comparado ao orçamento alocado, com % de estouro orçamentário
-- -----------------------------------------------------------------------------
WITH gasto_por_embarcacao AS (
    SELECT
        vessel_id,
        SUM(orcamento_alocado_brl) AS total_alocado,
        SUM(orcamento_gasto_brl)   AS total_gasto
    FROM fato_orcamento
    GROUP BY vessel_id
)
SELECT
    e.vessel_name,
    e.vessel_class,
    g.total_alocado,
    g.total_gasto,
    ROUND(100.0 * (g.total_gasto - g.total_alocado) / g.total_alocado, 1) AS estouro_orcamentario_pct
FROM gasto_por_embarcacao g
JOIN dim_embarcacoes e ON e.vessel_id = g.vessel_id
ORDER BY estouro_orcamentario_pct DESC;


-- -----------------------------------------------------------------------------
-- 9) Window function — ROW_NUMBER()
-- Pergunta: qual foi o mês de MAIOR consumo de cada embarcação? (top 1 por
-- grupo, sem precisar de subquery correlacionada)
-- -----------------------------------------------------------------------------
WITH ranking AS (
    SELECT
        vessel_id, competencia, litros_consumidos,
        ROW_NUMBER() OVER (PARTITION BY vessel_id ORDER BY litros_consumidos DESC) AS posicao
    FROM fato_consumo_combustivel
)
SELECT vessel_id, competencia, litros_consumidos
FROM ranking
WHERE posicao = 1;


-- -----------------------------------------------------------------------------
-- 10) Window function — RANK()
-- Pergunta: ranking das embarcações por gasto total com combustível (RANK
-- deixa empates com o mesmo lugar, diferente de ROW_NUMBER)
-- -----------------------------------------------------------------------------
SELECT
    e.vessel_name,
    SUM(o.orcamento_gasto_brl) AS gasto_total_combustivel,
    RANK() OVER (ORDER BY SUM(o.orcamento_gasto_brl) DESC) AS ranking_gasto
FROM fato_orcamento o
JOIN dim_embarcacoes e ON e.vessel_id = o.vessel_id
WHERE o.categoria_despesa = 'Combustível'
GROUP BY e.vessel_name;


-- -----------------------------------------------------------------------------
-- 11) Window function — LAG/LEAD
-- Pergunta: qual a variação de consumo mês a mês para cada embarcação?
-- (LAG traz o valor do mês anterior na mesma linha, sem self-join)
-- -----------------------------------------------------------------------------
SELECT
    vessel_id, competencia, litros_consumidos,
    LAG(litros_consumidos) OVER (PARTITION BY vessel_id ORDER BY competencia) AS consumo_mes_anterior,
    litros_consumidos - LAG(litros_consumidos) OVER (PARTITION BY vessel_id ORDER BY competencia) AS variacao_absoluta
FROM fato_consumo_combustivel
ORDER BY vessel_id, competencia;


-- -----------------------------------------------------------------------------
-- 12) Funções de data
-- Pergunta: qual o consumo total por trimestre (visão de série temporal)?
-- -----------------------------------------------------------------------------
SELECT
    strftime('%Y', competencia) AS ano,
    CASE
        WHEN CAST(strftime('%m', competencia) AS INTEGER) <= 3 THEN 'T1'
        WHEN CAST(strftime('%m', competencia) AS INTEGER) <= 6 THEN 'T2'
        WHEN CAST(strftime('%m', competencia) AS INTEGER) <= 9 THEN 'T3'
        ELSE 'T4'
    END AS trimestre,
    SUM(litros_consumidos) AS total_litros
FROM fato_consumo_combustivel
GROUP BY ano, trimestre
ORDER BY ano, trimestre;
