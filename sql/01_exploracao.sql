-- Validações iniciais da tabela bruta importada no PostgreSQL.

SELECT COUNT(*) AS total_linhas
FROM superstore;

SELECT
    MIN(TO_DATE("Order Date", 'MM/DD/YYYY')) AS primeira_venda,
    MAX(TO_DATE("Order Date", 'MM/DD/YYYY')) AS ultima_venda,
    COUNT(DISTINCT "Order ID") AS total_pedidos,
    COUNT(DISTINCT "Customer ID") AS total_clientes
FROM superstore;

SELECT
    "Category" AS categoria,
    COUNT(*) AS itens_vendidos,
    ROUND(SUM("Sales")::numeric, 2) AS vendas,
    ROUND(SUM("Profit")::numeric, 2) AS lucro
FROM superstore
GROUP BY "Category"
ORDER BY vendas DESC;
