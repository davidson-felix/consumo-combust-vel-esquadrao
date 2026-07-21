# Roteiro de Montagem — Dashboard Power BI

Este roteiro monta o dashboard a partir dos 3 CSVs desta pasta. Não existe
arquivo `.pbix` pronto porque o Power BI Desktop é um programa gráfico do
Windows — não dá para gerar esse arquivo automaticamente. Você vai montar
com as mãos, seguindo os passos abaixo, e isso é bom: em qualquer entrevista
técnica você vai ter feito de fato o que está descrevendo.

Tempo estimado: 2 a 3 horas na primeira vez.

---

## Passo 1 — Instalar e abrir

1. Baixe o Power BI Desktop grátis na Microsoft Store (Windows) ou no site
   oficial da Microsoft.
2. Abra o programa. Tela inicial > "Obter dados" > "Texto/CSV".

## Passo 2 — Importar as 3 tabelas

Repita 3 vezes ("Obter dados" > "Texto/CSV"), uma para cada arquivo:
- `dim_embarcacoes.csv`
- `fato_consumo_combustivel.csv`
- `fato_orcamento.csv`

Em cada importação, clique **"Transformar Dados"** (não "Carregar" direto) —
isso abre o Power Query Editor, onde:
- Confira se a coluna `competencia` foi reconhecida como Data (se não, clique
  no ícone do tipo da coluna > Data).
- Confira se colunas numéricas (`litros_consumidos`, `orcamento_gasto_brl`
  etc.) estão como Número Decimal ou Número Inteiro, não Texto.

Clique **"Fechar e Aplicar"** quando terminar.

## Passo 3 — Modelo de Dados (relacionamentos)

Vá na aba **"Modelo"** (ícone de tabelas conectadas, barra lateral esquerda).
Arraste para criar as relações (isso é o equivalente visual ao JOIN do SQL):

- `dim_embarcacoes[vessel_id]` → `fato_consumo_combustivel[vessel_id]`
- `dim_embarcacoes[vessel_id]` → `fato_orcamento[vessel_id]`

Cardinalidade: 1 para muitos (uma embarcação aparece em vários registros de
consumo/orçamento). O Power BI geralmente detecta isso sozinho.

## Passo 4 — Medidas DAX (as 4 que resolvem 80% dos casos)

Na aba **"Modelagem" > "Nova Medida"**, crie estas medidas (cole a fórmula
depois do nome):

```dax
Total Litros Consumidos = SUM(fato_consumo_combustivel[litros_consumidos])

Total Gasto Combustível =
CALCULATE(
    SUM(fato_orcamento[orcamento_gasto_brl]),
    fato_orcamento[categoria_despesa] = "Combustível"
)

% Estouro Orçamentário =
DIVIDE(
    SUM(fato_orcamento[orcamento_gasto_brl]) - SUM(fato_orcamento[orcamento_alocado_brl]),
    SUM(fato_orcamento[orcamento_alocado_brl])
)

Consumo Médio por Embarcação =
AVERAGEX(
    VALUES(dim_embarcacoes[vessel_name]),
    CALCULATE(SUM(fato_consumo_combustivel[litros_consumidos]))
)

Registros Fora da Frota Selecionada =
CALCULATE(
    COUNTROWS(fato_consumo_combustivel),
    ALL(dim_embarcacoes)
)
```

A última mostra o uso de `ALL()` (ignora os filtros de slicer — útil para
comparar "o que está filtrado" vs. "o total geral").

## Passo 5 — Visualizações (monte nesta ordem)

| # | Visual | Campos | O que mostra |
|---|---|---|---|
| 1 | Cartão (Card) | Medida `Total Litros Consumidos` | KPI principal no topo |
| 2 | Cartão (Card) | Medida `Total Gasto Combustível` | KPI financeiro no topo |
| 3 | Cartão (Card) | Medida `% Estouro Orçamentário` (formate como %) | KPI de risco no topo |
| 4 | Gráfico de linha | Eixo X: `competencia` (por mês) / Valor: `Total Litros Consumidos` | Sazonalidade — mesmo gráfico do notebook Python |
| 5 | Gráfico de barras horizontal | Eixo Y: `vessel_name` / Valor: `Total Litros Consumidos`, ordenado decrescente | Ranking por embarcação |
| 6 | Matriz | Linhas: `vessel_name`, Colunas: `categoria_despesa`, Valores: `orcamento_gasto_brl` | Detalhe de gasto por categoria |
| 7 | Segmentação de dados (slicer) | `vessel_class` (Fragata/Corveta) | Filtro interativo |
| 8 | Segmentação de dados (slicer) | Intervalo de `competencia` | Filtro de período |

Empilhe os 3 cartões no topo, o gráfico de linha abaixo (largura total), e
os demais visuais na parte inferior. Adicione um título de página:
"Consumo de Combustível e Orçamento — Esquadrão Naval (dados fictícios)".

## Passo 6 — Publicar (opcional, para link compartilhável)

- **Se tiver licença Power BI Pro** (pode testar grátis por período limitado
  ou assinar 1 mês durante a busca de emprego): "Arquivo" > "Publicar" >
  "Publicar na Web". Isso gera um link público — **use só com estes dados
  fictícios**, nunca com dado sensível, porque o link expõe a base
  completa.
- **Se não quiser pagar:** tire prints de cada página do dashboard (Power BI
  tem exportação de imagem nativa) e coloque na pasta `/imagens` do
  repositório GitHub, com uma nota no README: "versão interativa (.pbix)
  disponível sob demanda".

## Passo 7 — Salvar e subir ao GitHub

Salve o arquivo como `orcamento_combustivel.pbix` nesta mesma pasta
(`power_bi/`) e suba ao repositório junto com os CSVs e este roteiro.
