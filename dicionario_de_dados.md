# Dicionário de Dados

## Origem e metodologia (leia isto primeiro)

Todos os dados deste projeto foram **gerados artificialmente** pelo script
`dados/gerar_dados_sinteticos.py`, usando uma seed fixa (42) para que
qualquer pessoa que rode o script obtenha exatamente os mesmos números.
Não há nenhum dado real de nenhuma organização.

Premissas usadas na geração (para transparência total):
- Fragatas consomem, em média, ~42.000 L/mês; corvetas ~24.000 L/mês
  (valores fictícios, só para criar diferença proporcional plausível entre
  classes de navio).
- Meses de agosto a novembro recebem um multiplicador de 1,25x para simular
  sazonalidade de exercícios operacionais.
- Em ~12% dos registros, o consumo simulado ultrapassa a cota alocada
  (fator aleatório), para gerar casos de "estouro de cota" analisáveis.
- O preço do combustível é uma premissa fictícia de R$ 6,35/litro, com
  variação aleatória leve mês a mês — **não é um preço real de mercado**.
- O gasto orçamentário com combustível é derivado do consumo simulado
  (litros × preço), o que permite JOIN significativo entre as tabelas de
  consumo e de orçamento. As demais categorias de despesa (Manutenção,
  Suprimentos, Pessoal) têm variação própria, sem relação com consumo.

## Tabela: `dim_embarcacoes`

| Campo | Tipo | Descrição |
|---|---|---|
| `vessel_id` | texto | Identificador único da embarcação (V01–V06) |
| `vessel_name` | texto | Nome fictício da embarcação (marcado "(fictício)") |
| `vessel_class` | texto | Classe: `Fragata` ou `Corveta` |
| `capacidade_tanque_litros` | inteiro | Capacidade fictícia do tanque, em litros |

## Tabela: `fato_consumo_combustivel`

| Campo | Tipo | Descrição |
|---|---|---|
| `record_id` | inteiro | Chave primária |
| `vessel_id` | texto | Chave estrangeira para `dim_embarcacoes` |
| `competencia` | data | Primeiro dia do mês de referência (formato AAAA-MM-01) |
| `categoria_operacional` | texto | `Operação`, `Manutenção` ou `Treinamento` — categoria que mais consumiu combustível naquele mês |
| `litros_cota_alocada` | inteiro | Cota de combustível alocada para o mês (fictícia) |
| `litros_consumidos` | inteiro | Consumo real simulado no mês |

## Tabela: `fato_orcamento`

| Campo | Tipo | Descrição |
|---|---|---|
| `record_id` | inteiro | Chave primária |
| `vessel_id` | texto | Chave estrangeira para `dim_embarcacoes` |
| `competencia` | data | Primeiro dia do mês de referência |
| `categoria_despesa` | texto | `Combustível`, `Manutenção`, `Suprimentos` ou `Pessoal (Extras)` |
| `orcamento_alocado_brl` | decimal | Verba alocada no mês para a categoria, em R$ (fictícia) |
| `orcamento_gasto_brl` | decimal | Verba efetivamente gasta no mês, em R$ (fictícia) |

## Volume de dados

- `dim_embarcacoes`: 6 linhas
- `fato_consumo_combustivel`: 144 linhas (6 embarcações × 24 meses)
- `fato_orcamento`: 576 linhas (6 embarcações × 24 meses × 4 categorias de despesa)

## Limitações conhecidas (para deixar claro em entrevista, se perguntado)

- Os dados são sintéticos e simplificados: não incluem eventos reais como
  manutenção não programada, variação real de preço de combustível no
  mercado, ou decisões de comando que alterariam alocação de cota.
- A correlação entre "categoria operacional" e consumo é simplificada
  (uma categoria dominante por mês, quando na realidade um mês pode ter
  múltiplas atividades simultâneas).
- O projeto foi desenhado para demonstrar competência técnica (SQL, Python,
  Power BI) e raciocínio de negócio, não para ser um modelo preditivo
  validado.
