# Análise de Consumo de Combustível e Orçamento — Esquadrão Naval (dados fictícios)

Projeto de portfólio de análise de dados, construído durante minha transição
de carreira da Marinha do Brasil para o mercado civil. Aplica SQL, Python e
Power BI a um problema de negócio que conheço na prática: controle de cota
de combustível e gestão orçamentária de unidades subordinadas.

**⚠️ Aviso importante:** todos os dados deste repositório são **100%
sintéticos**, gerados por script (`dados/gerar_dados_sinteticos.py`). Não
representam nenhum dado real da Marinha do Brasil ou de qualquer outra
organização — dados operacionais reais são sigilosos e nunca foram
utilizados aqui. Nomes de embarcações e valores financeiros são fictícios.
Ver [`dicionario_de_dados.md`](dicionario_de_dados.md) para detalhes de como
os dados foram gerados.

## Contexto e pergunta de negócio

Numa unidade naval real, o oficial responsável pela seção de logística
aprova mensalmente cotas de combustível e verbas orçamentárias para as
embarcações subordinadas — uma função que exerci entre 2022 e 2024. Este
projeto simula essa rotina com um esquadrão fictício de 6 embarcações
(3 fragatas, 3 corvetas) ao longo de 24 meses, respondendo:

1. Quais embarcações e períodos concentram o maior consumo de combustível?
2. Existe sazonalidade (ex: picos em meses de exercício)?
3. Com que frequência as embarcações estouram a cota alocada, e em qual
   categoria operacional isso mais acontece?
4. O orçamento gasto está batendo com o orçamento alocado, por embarcação?

## Estrutura do repositório

```
consumo-combustivel-esquadrao/
├── README.md                          # este arquivo
├── dicionario_de_dados.md             # descrição dos campos e metodologia de geração
├── requirements.txt                   # dependências Python
├── dados/
│   ├── gerar_dados_sinteticos.py      # script que gera os dados fictícios (seed fixa)
│   ├── montar_banco.py                # monta o banco SQLite a partir dos CSVs
│   └── brutos/                        # os 3 CSVs gerados
├── esquadrao.db                       # banco SQLite pronto (gerado por montar_banco.py)
├── sql/
│   ├── schema.sql                     # estrutura das tabelas
│   └── consultas.sql                  # 12 queries comentadas (SELECT básico -> window functions)
├── notebooks/
│   ├── analise.py                     # análise em formato de script (mesmo conteúdo do notebook)
│   └── 01_analise.ipynb               # notebook Jupyter/Colab (EDA + 4 gráficos)
├── imagens/                           # gráficos exportados (.png)
└── power_bi/
    ├── *.csv                          # dados prontos para importar no Power BI
    └── ROTEIRO_MONTAGEM_POWERBI.md    # passo a passo para montar o dashboard
```

## Como reproduzir

**SQL (sem instalar nada):**
Abra `esquadrao.db` no [DB Fiddle](https://dbfiddle.uk) (dialeto SQLite) ou
em qualquer visualizador de SQLite, e rode as queries de `sql/consultas.sql`.

**Python (sem instalar nada):**
Suba a pasta `notebooks/` e `dados/` para o [Google Colab](https://colab.research.google.com)
e execute `01_analise.ipynb` célula por célula.

**Power BI:**
Siga `power_bi/ROTEIRO_MONTAGEM_POWERBI.md` a partir dos CSVs em `power_bi/`.

**Localmente:**
```bash
pip install -r requirements.txt
python dados/gerar_dados_sinteticos.py   # gera os CSVs
python dados/montar_banco.py             # monta o esquadrao.db
python notebooks/analise.py              # roda a análise e gera os gráficos
```

## Principais achados

1. **Sazonalidade clara:** o consumo da frota sobe ~25% entre agosto e
   novembro, período concentrado de exercícios — achado relevante para
   antecipar pedido de cota nesse trimestre.
2. **Estouro de cota concentrado em "Operação":** a categoria operacional
   "Operação" responde pela maior parte dos registros de estouro de cota,
   sugerindo que o modelo de alocação atual pode estar subdimensionado
   para meses operacionais intensos.
3. **Orçamento de combustível estourado em todas as embarcações:** entre
   ~0,7% e ~1,7% acima do alocado no período, com fragatas concentrando o
   maior desvio em valor absoluto.

*(Achados baseados em dados fictícios — o objetivo é demonstrar o raciocínio
analítico de ponta a ponta, não descrever uma situação real.)*

## Sobre este projeto

Este é meu primeiro projeto de dados de ponta a ponta (SQL → Python →
Power BI), construído para praticar o fluxo completo num contexto de
negócio que domino por experiência real. Ainda estou nos estudos de SQL,
Power BI e Python (roteiro auto-dirigido em andamento) — meus próximos
passos são adicionar um segundo projeto num domínio diferente e aprofundar window functions e DAX.

**Autor:** Davidson Felix Alves — [LinkedIn](https://www.linkedin.com/in/davidson-felix)
