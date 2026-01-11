
-- “Número de empregados por departamento”
CREATE VIEW vw_pedidos_por_cliente AS
SELECT c.id_cliente,
       c.nome,
       COUNT(p.id_pedido) AS total_pedidos
FROM clientes c
LEFT JOIN pedidos p ON p.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nome;
