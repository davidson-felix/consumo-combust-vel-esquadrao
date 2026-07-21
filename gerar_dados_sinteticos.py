"""
Gerador de dados sintéticos — Projeto de Portfólio
Análise de Consumo de Combustível e Orçamento de Esquadrão Naval (fictício)

IMPORTANTE: Todos os dados neste projeto são 100% SINTÉTICOS (gerados por
este script), criados para fins de demonstração técnica de portfólio.
Não representam dados reais de nenhuma unidade da Marinha do Brasil ou de
qualquer outra organização. Nomes de embarcações, esquadrão e valores
financeiros são fictícios.

Autor: Davidson Felix Alves
Contexto: projeto de portfólio para transição de carreira militar-para-civil,
usando como inspiração de negócio a rotina real de controle de cotas de
combustível e aprovação de verbas orçamentárias de unidades subordinadas
(função desempenhada em esquadrão real, mas SEM uso de nenhum dado real).
"""

import numpy as np
import pandas as pd
from pathlib import Path

# Seed fixa para reprodutibilidade (qualquer pessoa que rodar este script
# gera exatamente os mesmos dados)
SEED = 42
rng = np.random.default_rng(SEED)

SAIDA_DIR = Path(__file__).parent / "brutos"
SAIDA_DIR.mkdir(parents=True, exist_ok=True)

# ---------------------------------------------------------------------------
# 1) DIMENSÃO: EMBARCAÇÕES (fictícias)
# ---------------------------------------------------------------------------
embarcacoes = pd.DataFrame([
    {"vessel_id": "V01", "vessel_name": "NE Cabo Frio (fictício)",   "vessel_class": "Fragata", "capacidade_tanque_litros": 850_000},
    {"vessel_id": "V02", "vessel_name": "NE Ilha Grande (fictício)", "vessel_class": "Fragata", "capacidade_tanque_litros": 850_000},
    {"vessel_id": "V03", "vessel_name": "NE Paraty (fictício)",      "vessel_class": "Fragata", "capacidade_tanque_litros": 820_000},
    {"vessel_id": "V04", "vessel_name": "NE Angra (fictício)",       "vessel_class": "Corveta", "capacidade_tanque_litros": 480_000},
    {"vessel_id": "V05", "vessel_name": "NE Búzios (fictício)",      "vessel_class": "Corveta", "capacidade_tanque_litros": 460_000},
    {"vessel_id": "V06", "vessel_name": "NE Maricá (fictício)",      "vessel_class": "Corveta", "capacidade_tanque_litros": 460_000},
])
embarcacoes.to_csv(SAIDA_DIR / "dim_embarcacoes.csv", index=False)

# ---------------------------------------------------------------------------
# 2) FATO: CONSUMO DE COMBUSTÍVEL (mensal, por embarcação)
# ---------------------------------------------------------------------------
meses = pd.date_range("2024-01-01", "2025-12-01", freq="MS")  # 24 meses
categorias = ["Operação", "Manutenção", "Treinamento"]
pesos_categoria = [0.55, 0.20, 0.25]

registros_combustivel = []
rec_id = 1

# Fragatas consomem mais que corvetas; 3º e 4º trimestres têm mais exercícios
# (sazonalidade), o que eleva consumo — isso é proposital, para dar ao
# candidato algo real para "descobrir" na análise.
base_consumo = {"Fragata": 42_000, "Corveta": 24_000}

for vessel_id, classe in zip(embarcacoes["vessel_id"], embarcacoes["vessel_class"]):
    for mes in meses:
        sazonalidade = 1.25 if mes.month in (8, 9, 10, 11) else 1.0
        ruido = rng.normal(1.0, 0.08)
        categoria = rng.choice(categorias, p=pesos_categoria)

        cota_alocada = round(base_consumo[classe] * sazonalidade * rng.normal(1.0, 0.03))
        # Na maior parte dos meses o consumo fica dentro da cota; em ~12%
        # dos casos estoura a cota (situação real e recorrente em unidades
        # operacionais, útil para a análise de "excedentes")
        estourou = rng.random() < 0.12
        fator_consumo = rng.uniform(1.03, 1.18) if estourou else rng.uniform(0.75, 1.0)
        litros_consumidos = round(cota_alocada * fator_consumo * ruido)

        registros_combustivel.append({
            "record_id": rec_id,
            "vessel_id": vessel_id,
            "competencia": mes.strftime("%Y-%m-01"),
            "categoria_operacional": categoria,
            "litros_cota_alocada": max(cota_alocada, 1000),
            "litros_consumidos": max(litros_consumidos, 500),
        })
        rec_id += 1

fato_combustivel = pd.DataFrame(registros_combustivel)
fato_combustivel.to_csv(SAIDA_DIR / "fato_consumo_combustivel.csv", index=False)

# ---------------------------------------------------------------------------
# 3) FATO: ORÇAMENTO (mensal, por embarcação e categoria de despesa)
# ---------------------------------------------------------------------------
categorias_despesa = ["Combustível", "Manutenção", "Suprimentos", "Pessoal (Extras)"]
preco_diesel_base = 6.35  # R$/litro — premissa fictícia, varia levemente por mês

registros_orcamento = []
rec_id = 1

# Custo de combustível é derivado do consumo real (para permitir JOIN
# significativo entre as duas tabelas de fato). As demais categorias têm
# variação própria.
preco_por_mes = {
    mes: round(preco_diesel_base * rng.normal(1.0, 0.02), 3) for mes in meses
}

for vessel_id, classe in zip(embarcacoes["vessel_id"], embarcacoes["vessel_class"]):
    for mes in meses:
        consumo_mes = fato_combustivel[
            (fato_combustivel["vessel_id"] == vessel_id)
            & (fato_combustivel["competencia"] == mes.strftime("%Y-%m-01"))
        ]["litros_consumidos"].iloc[0]

        gasto_combustivel = round(consumo_mes * preco_por_mes[mes], 2)
        orcado_combustivel = round(gasto_combustivel * rng.uniform(0.92, 1.05), 2)

        base_outras = {"Fragata": 18_000, "Corveta": 11_000}[classe]
        for cat in categorias_despesa[1:]:
            fator_cat = {"Manutenção": 1.4, "Suprimentos": 0.8, "Pessoal (Extras)": 0.5}[cat]
            orcado = round(base_outras * fator_cat * rng.normal(1.0, 0.10), 2)
            gasto = round(orcado * rng.uniform(0.80, 1.15), 2)
            registros_orcamento.append({
                "record_id": rec_id, "vessel_id": vessel_id, "competencia": mes.strftime("%Y-%m-01"),
                "categoria_despesa": cat, "orcamento_alocado_brl": max(orcado, 0),
                "orcamento_gasto_brl": max(gasto, 0),
            })
            rec_id += 1

        registros_orcamento.append({
            "record_id": rec_id, "vessel_id": vessel_id, "competencia": mes.strftime("%Y-%m-01"),
            "categoria_despesa": "Combustível", "orcamento_alocado_brl": orcado_combustivel,
            "orcamento_gasto_brl": gasto_combustivel,
        })
        rec_id += 1

fato_orcamento = pd.DataFrame(registros_orcamento)
fato_orcamento.to_csv(SAIDA_DIR / "fato_orcamento.csv", index=False)

print("Dados sintéticos gerados com sucesso:")
print(f"  dim_embarcacoes.csv        -> {len(embarcacoes)} linhas")
print(f"  fato_consumo_combustivel.csv -> {len(fato_combustivel)} linhas")
print(f"  fato_orcamento.csv          -> {len(fato_orcamento)} linhas")
