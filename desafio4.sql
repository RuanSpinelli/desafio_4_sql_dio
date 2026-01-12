/* ============================================================
   DESAFIO SQL – VIEWS, PERMISSÕES E TRIGGERS
   Banco de dados: e-commerce (clientes, pedidos, produtos)
   SGBD: PostgreSQL
   ============================================================ */

---------------------------------------------------------------
-- PARTE 1 – CRIAÇÃO DE VIEWS
---------------------------------------------------------------

/*
 VIEW 1
 Total de pedidos por cliente
 (adaptado ao contexto e-commerce)
*/
CREATE OR REPLACE VIEW vw_total_pedidos_cliente AS
SELECT
    c.id_cliente,
    c.nome,
    COUNT(p.id_pedido) AS total_pedidos
FROM clientes c
LEFT JOIN pedidos p ON p.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nome;


/*
 VIEW 2
 Lista de clientes e seus pedidos
*/
CREATE OR REPLACE VIEW vw_clientes_pedidos AS
SELECT
    c.nome AS cliente,
    p.id_pedido,
    p.data_pedido
FROM clientes c
JOIN pedidos p ON p.id_cliente = c.id_cliente;


/*
 VIEW 3
 Produtos mais vendidos (ordenado por quantidade DESC)
*/
CREATE OR REPLACE VIEW vw_produtos_mais_vendidos AS
SELECT
    pr.id_produto,
    pr.nome,
    SUM(ip.quantidade) AS total_vendido
FROM produtos pr
JOIN itens_pedido ip ON ip.id_produto = pr.id_produto
GROUP BY pr.id_produto, pr.nome
ORDER BY total_vendido DESC;


/*
 VIEW 4
 Detalhes completos dos pedidos
*/
CREATE OR REPLACE VIEW vw_detalhes_pedido AS
SELECT
    p.id_pedido,
    c.nome AS cliente,
    pr.nome AS produto,
    ip.quantidade,
    pr.preco,
    (ip.quantidade * pr.preco) AS valor_total
FROM pedidos p
JOIN clientes c ON c.id_cliente = p.id_cliente
JOIN itens_pedido ip ON ip.id_pedido = p.id_pedido
JOIN produtos pr ON pr.id_produto = ip.id_produto;


---------------------------------------------------------------
-- PARTE 1.1 – CONTROLE DE ACESSO (USUÁRIOS E PERMISSÕES)
---------------------------------------------------------------

/*
 Usuário gerente: acesso às views
*/
CREATE USER gerente WITH PASSWORD 'gerente123';

/*
 Usuário cliente: acesso limitado
*/
CREATE USER cliente_app WITH PASSWORD 'cliente123';

/* Permissões */
GRANT SELECT ON vw_total_pedidos_cliente TO gerente;
GRANT SELECT ON vw_clientes_pedidos TO gerente;
GRANT SELECT ON vw_produtos_mais_vendidos TO gerente;
GRANT SELECT ON vw_detalhes_pedido TO gerente;

GRANT SELECT ON vw_clientes_pedidos TO cliente_app;


---------------------------------------------------------------
-- PARTE 2 – TRIGGERS
---------------------------------------------------------------

/*
 TRIGGER 1
 BEFORE DELETE – Backup de clientes excluídos
*/
CREATE TABLE IF NOT EXISTS clientes_backup (
    id_cliente INT,
    nome VARCHAR(100),
    email VARCHAR(100),
    data_exclusao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION backup_cliente()
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
EXECUTE FUNCTION backup_cliente();


/*
 TRIGGER 2
 BEFORE INSERT – Impedir quantidade inválida em itens do pedido
*/
CREATE OR REPLACE FUNCTION validar_quantidade_item()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.quantidade <= 0 THEN
        RAISE EXCEPTION 'Quantidade deve ser maior que zero';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_quantidade
BEFORE INSERT ON itens_pedido
FOR EACH ROW
EXECUTE FUNCTION validar_quantidade_item();


/*
 TRIGGER 3
 BEFORE INSERT – Soma quantidade se produto já existir no pedido
*/
CREATE OR REPLACE FUNCTION somar_quantidade_item()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM itens_pedido
        WHERE id_pedido = NEW.id_pedido
          AND id_produto = NEW.id_produto
    ) THEN
        UPDATE itens_pedido
        SET quantidade = quantidade + NEW.quantidade
        WHERE id_pedido = NEW.id_pedido
          AND id_produto = NEW.id_produto;

        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_somar_quantidade
BEFORE INSERT ON itens_pedido
FOR EACH ROW
EXECUTE FUNCTION somar_quantidade_item();


---------------------------------------------------------------
-- TESTES (OPCIONAL PARA VALIDAÇÃO)
---------------------------------------------------------------

-- SELECT * FROM vw_total_pedidos_cliente;
-- SELECT * FROM vw_produtos_mais_vendidos;
-- DELETE FROM clientes WHERE id_cliente = 1;
-- INSERT INTO itens_pedido (id_pedido, id_produto, quantidade) VALUES (1, 1, 2);
