
-- “Número de empregados por departamento”
CREATE VIEW vw_pedidos_por_cliente AS
SELECT c.id_cliente,
       c.nome,
       COUNT(p.id_pedido) AS total_pedidos
FROM clientes c
LEFT JOIN pedidos p ON p.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nome;

-- “Lista de departamentos e seus gerentes”
CREATE VIEW vw_clientes_ativos AS
SELECT c.id_cliente,
       c.nome,
       COUNT(p.id_pedido) AS total_pedidos
FROM clientes c
JOIN pedidos p ON p.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nome;

-- Projetos com maior número de empregados
CREATE VIEW vw_produtos_mais_vendidos AS
SELECT pr.id_produto,
       pr.nome,
       SUM(ip.quantidade) AS total_vendido
FROM produtos pr
JOIN itens_pedido ip ON ip.id_produto = pr.id_produto
GROUP BY pr.id_produto, pr.nome
ORDER BY total_vendido DESC;

-- Lista de projetos, departamentos e gerentes
CREATE VIEW vw_produtos_pedidos_clientes AS
SELECT pr.nome AS produto,
       p.id_pedido,
       c.nome AS cliente
FROM itens_pedido ip
JOIN produtos pr ON pr.id_produto = ip.id_produto
JOIN pedidos p ON p.id_pedido = ip.id_pedido
JOIN clientes c ON c.id_cliente = p.id_cliente;

-- Empregados com dependentes e se são gerentes
CREATE VIEW vw_clientes_multiplos_pedidos AS
SELECT c.nome,
       COUNT(p.id_pedido) AS total_pedidos,
       CASE
           WHEN COUNT(p.id_pedido) > 1 THEN 'SIM'
           ELSE 'NAO'
       END AS cliente_frequente
FROM clientes c
JOIN pedidos p ON p.id_cliente = c.id_cliente
GROUP BY c.nome;

-- PERMISSÕES DE USUÁRIOS
CREATE USER usuario_gerente WITH PASSWORD 'gerente123';
CREATE USER usuario_cliente WITH PASSWORD 'cliente123';

GRANT SELECT ON
    vw_pedidos_por_cliente,
    vw_clientes_ativos,
    vw_produtos_mais_vendidos,
    vw_produtos_pedidos_clientes,
    vw_clientes_multiplos_pedidos
TO usuario_gerente;

GRANT SELECT ON vw_produtos_mais_vendidos TO usuario_cliente;

CREATE TABLE clientes_backup (
    id_cliente INT,
    nome VARCHAR(100),
    email VARCHAR(100),
    data_remocao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE OR REPLACE FUNCTION fn_backup_cliente()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO clientes_backup (id_cliente, nome, email)
    VALUES (OLD.id_cliente, OLD.nome, OLD.email);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_backup_cliente
BEFORE DELETE ON clientes
FOR EACH ROW
EXECUTE FUNCTION fn_backup_cliente();


CREATE TABLE pedidos_historico (
    id_pedido INT,
    data_antiga DATE,
    data_nova DATE,
    data_alteracao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION fn_historico_pedido()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO pedidos_historico (id_pedido, data_antiga, data_nova)
    VALUES (OLD.id_pedido, OLD.data_pedido, NEW.data_pedido);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_historico_pedido
BEFORE UPDATE ON pedidos
FOR EACH ROW
EXECUTE FUNCTION fn_historico_pedido();

--testando views e triggers

INSERT INTO clientes (nome, email)
VALUES ('Robson', 'rob@email.com');

INSERT INTO produtos (nome, preco)
VALUES ('Teclado Mecânico', 350.00);

INSERT INTO pedidos (id_cliente, data_pedido)
VALUES (1, CURRENT_DATE);

INSERT INTO itens_pedido (id_pedido, id_produto, quantidade)
VALUES (5, 1, 0);


UPDATE itens_pedido
SET quantidade = quantidade + 2
WHERE id_pedido = 1
  AND id_produto = 1;
/*
INSERT INTO itens_pedido (id_pedido, id_produto, quantidade)
VALUES (1, 1, 2);

SELECT * FROM vw_resumo_pedidos;


SELECT *
FROM pedidos
*/
