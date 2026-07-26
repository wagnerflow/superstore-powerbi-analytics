-- Exemplos curtos de análises sobre a view usada pelo dashboard.

-- 1. Amostra da camada analítica
SELECT *
FROM vw_superstore_dashboard
ORDER BY data_pedido, id_linha
LIMIT 20;

-- 2. Vendas, lucro e margem por categoria
SELECT
    categoria,
    ROUND(SUM(vendas)::numeric, 2) AS vendas,
    ROUND(SUM(lucro)::numeric, 2) AS lucro,
    ROUND((100 * SUM(lucro) / NULLIF(SUM(vendas), 0))::numeric, 2) AS margem_pct
FROM vw_superstore_dashboard
GROUP BY categoria
ORDER BY vendas DESC;

-- 3. Produtos com pior margem e volume relevante
SELECT
    produto,
    categoria,
    ROUND(SUM(vendas)::numeric, 2) AS vendas,
    ROUND(SUM(lucro)::numeric, 2) AS lucro,
    ROUND((100 * SUM(lucro) / NULLIF(SUM(vendas), 0))::numeric, 2) AS margem_pct
FROM vw_superstore_dashboard
GROUP BY produto, categoria
HAVING SUM(vendas) >= 1000
ORDER BY margem_pct
LIMIT 10;

-- 4. Performance por região
SELECT
    regiao,
    COUNT(DISTINCT id_pedido) AS pedidos,
    ROUND(SUM(vendas)::numeric, 2) AS vendas,
    ROUND(SUM(lucro)::numeric, 2) AS lucro,
    ROUND((100 * SUM(lucro) / NULLIF(SUM(vendas), 0))::numeric, 2) AS margem_pct
FROM vw_superstore_dashboard
GROUP BY regiao
ORDER BY vendas DESC;

-- 5. Relação entre desconto e rentabilidade
SELECT
    ROUND(desconto::numeric, 2) AS desconto,
    COUNT(*) AS itens,
    ROUND(SUM(vendas)::numeric, 2) AS vendas,
    ROUND(SUM(lucro)::numeric, 2) AS lucro,
    ROUND((100 * SUM(lucro) / NULLIF(SUM(vendas), 0))::numeric, 2) AS margem_pct
FROM vw_superstore_dashboard
GROUP BY ROUND(desconto::numeric, 2)
ORDER BY desconto;
