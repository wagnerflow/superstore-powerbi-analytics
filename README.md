# Superstore Analytics — Power BI

Projeto de Data Analytics/BI desenvolvido para transformar o dataset
Superstore em uma visão executiva de vendas, desempenho comercial e
rentabilidade.

## Arquitetura

`Superstore CSV → Python (exploração) → PostgreSQL → SQL View → Power BI → DAX → Dashboard`

![Pipeline do projeto](images/05_pipeline.png)

## Tecnologias

- Python e pandas
- PostgreSQL
- SQL
- Power BI
- DAX

## Pipeline

1. `data/superstore.csv`: dataset de origem, com 9.994 registros e 21 colunas.
2. Python: leitura em `cp1252` e exploração inicial de colunas, amostra,
   estatísticas descritivas e completude.
3. PostgreSQL: carga da tabela bruta `superstore` via script (`python/carga_postgres.py`).
4. SQL: a view `vw_superstore_dashboard` padroniza nomes, converte datas e
   adiciona atributos de calendário, prazo de envio e margem de lucro.
5. Power BI: modelo com `fato_vendas`, `Calendario`, `Medidas` e
   `Top Bottom Produtos`.
6. DAX: medidas alimentam indicadores e visuais das três páginas.

## Dashboard

### 1. Overview

Resumo executivo com vendas, lucro, pedidos, clientes, distribuição geográfica,
categorias e evolução temporal.

![Overview](images/dashboard/01_overview.png)

### 2. Performance Comercial

Visão de unidades vendidas, ticket médio, pedidos, categorias, subcategorias,
produtos e segmentos de clientes.

![Performance comercial](images/dashboard/02_performance.png)

### 3. Rentabilidade

Análise de margem, produtos com prejuízo, relação entre desconto e margem e
lucro por categoria.

![Rentabilidade](images/dashboard/03_rentabilidade.png)

## Medidas DAX

Todas as medidas vivem na tabela dedicada `Medidas` (sem dados, só DAX), seguindo a prática de manter o modelo limpo.

### Medidas base

```dax
Total Vendas = SUM(fato_vendas[vendas])

Total Lucro = SUM(fato_vendas[lucro])

Margem % = DIVIDE([Total Lucro], [Total Vendas], 0)

Total Pedidos = DISTINCTCOUNT(fato_vendas[id_pedido])

Total Clientes = DISTINCTCOUNT(fato_vendas[id_cliente])

Ticket Médio = DIVIDE([Total Vendas], [Total Pedidos])

Total Unidades = SUM(fato_vendas[quantidade])
```

### Medidas com cuidado de granularidade

A tabela fato está no grão de linha de pedido (um pedido com múltiplos produtos gera múltiplas linhas). Uma medida ingênua (`AVERAGE` direto na coluna) infla o peso de pedidos com mais itens.

```dax
Dias Médios Envio =
AVERAGEX(
    DISTINCT(fato_vendas[id_pedido]),
    CALCULATE(AVERAGE(fato_vendas[dias_envio]))
)
```

### Medidas de rentabilidade

```dax
Produtos com Prejuízo =
CALCULATE(
    DISTINCTCOUNT(fato_vendas[id_produto]),
    fato_vendas[lucro] < 0
)

Desconto Médio Produto = AVERAGE(fato_vendas[desconto])

Margem Produto =
DIVIDE(
    CALCULATE([Total Lucro]),
    CALCULATE([Vendas Totais])
)

Desconto Médio Categoria = AVERAGE(fato_vendas[desconto])
```

`Margem Produto` reaproveita as medidas base, mas calculada no contexto de filtro de cada produto — usada no scatter de desconto x margem, onde cada ponto é um produto (campo `Details`).

### Tabela calculada — Top/Bottom produtos

Usada no gráfico divergente de produtos mais/menos lucrativos. É uma tabela (Modeling → New Table), não uma medida — isolada da fato, sem necessidade de relacionamento.

```dax
Top Bottom Produtos =
VAR ProdutosLucro =
    SUMMARIZE(
        fato_vendas,
        fato_vendas[produto],
        "Lucro", [Total Lucro]
    )
VAR Top5 = TOPN(5, ProdutosLucro, [Lucro], DESC)
VAR Bottom5 = TOPN(5, ProdutosLucro, [Lucro], ASC)
RETURN
    DISTINCT(UNION(Top5, Bottom5))
```

## Estrutura para publicação

- `sql/`: exploração, criação da view e consultas analíticas.
- `python/`: leitura portável e exploração do CSV, e script de carga no PostgreSQL (`carga_postgres.py`).
- `images/`: imagens técnicas e capturas finais do dashboard.
- `docs/`: documentação complementar do modelo.

## Insights e recomendações

Análise realizada diretamente sobre os dados da base (9.994 registros), agregando por faixa de desconto, categoria e subcategoria.

### 1. A margem vira negativa a partir de ~20% de desconto médio

| Faixa de desconto | Margem média |
|---|---|
| 0–10% | +28,9% |
| 10–20% | +11,6% |
| 20–30% | -10,0% |
| 30–40% | -19,4% |
| 40%+ | -77,4% |

Descontos de até 20% preservam margem positiva. A partir daí, a deterioração é rápida e se agrava de forma acentuada em faixas mais altas.

**Recomendação:** estabelecer 20% como teto de desconto padrão para aprovação automática; descontos acima disso deveriam exigir aprovação gerencial, já que a margem passa a ser sistematicamente negativa nessa faixa.

### 2. A categoria Furniture tem margem 7x menor que as demais

| Categoria | Margem |
|---|---|
| Technology | 17,4% |
| Office Supplies | 17,0% |
| Furniture | 2,5% |

Investigando por subcategoria, o problema está concentrado, não distribuído:

| Subcategoria | Desconto médio | Margem |
|---|---|---|
| Tables | 26,1% | -8,6% |
| Bookcases | 21,1% | -3,0% |
| Chairs | 17,0% | +8,1% |
| Furnishings | 13,8% | +14,2% |

Tables e Bookcases operam com desconto médio acima do ponto de virada identificado no insight 1, e são as únicas subcategorias de Furniture com margem negativa — Chairs e Furnishings, dentro da mesma categoria, são lucrativas.

**Recomendação:** revisar a política de desconto especificamente para Tables e Bookcases, não para Furniture como um todo — o problema não é a categoria, é a prática de desconto em duas subcategorias específicas dela.

### Próximos passos

Investigar se a concentração de desconto em Tables/Bookcases está ligada a um segmento de cliente, região ou canal de venda específico, para direcionar a correção de forma mais precisa.
