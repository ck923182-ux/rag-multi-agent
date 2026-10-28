
-- Phase 2: Enforce tenant relationship integrity.
-- Review before execution against PostgreSQL.
-- This migration is transactional but is not fully idempotent.

BEGIN;

-- Prevent concurrent writes from introducing ownership mismatches
-- between the preflight checks and the creation of constraints.
LOCK TABLE
    inventory,
    products,
    orders,
    customers,
    order_items,
    agent_runs,
    agent_configs
IN SHARE ROW EXCLUSIVE MODE;

-- 1. Preflight: reject existing ownership mismatches.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inventory i
        JOIN products p ON p.id = i.product_id
        WHERE i.tenant_id <> p.tenant_id
    ) THEN
        RAISE EXCEPTION
            'Migration 020 aborted: inventory/product tenant mismatch';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM orders o
        JOIN customers c ON c.id = o.customer_id
        WHERE o.tenant_id <> c.tenant_id
    ) THEN
        RAISE EXCEPTION
            'Migration 020 aborted: order/customer tenant mismatch';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM order_items oi
        JOIN orders o ON o.id = oi.order_id
        JOIN products p ON p.id = oi.product_id
        WHERE o.tenant_id <> p.tenant_id
    ) THEN
        RAISE EXCEPTION
            'Migration 020 aborted: order item uses another tenant product';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM agent_runs ar
        JOIN agent_configs ac ON ac.id = ar.config_id
        WHERE ar.agent_id <> ac.agent_id
    ) THEN
        RAISE EXCEPTION
            'Migration 020 aborted: agent run/config ownership mismatch';
    END IF;
END;
$$;

-- 2. Add composite candidate keys for tenant-aware foreign keys.
ALTER TABLE customers
    ADD CONSTRAINT uq_customers_id_tenant
    UNIQUE (id, tenant_id);

ALTER TABLE products
    ADD CONSTRAINT uq_products_id_tenant
    UNIQUE (id, tenant_id);

ALTER TABLE orders
    ADD CONSTRAINT uq_orders_id_tenant
    UNIQUE (id, tenant_id);

ALTER TABLE agent_configs
    ADD CONSTRAINT uq_agent_configs_id_agent
    UNIQUE (id, agent_id);

-- 3. Inventory must reference a product from the same tenant.
ALTER TABLE inventory
    DROP CONSTRAINT fk_inventory_product;

ALTER TABLE inventory
    ADD CONSTRAINT fk_inventory_product_tenant
    FOREIGN KEY (product_id, tenant_id)
    REFERENCES products (id, tenant_id)
    ON DELETE CASCADE;

-- 4. An order must reference a customer from the same tenant.
ALTER TABLE orders
    DROP CONSTRAINT fk_orders_customer;

ALTER TABLE orders
    ADD CONSTRAINT fk_orders_customer_tenant
    FOREIGN KEY (customer_id, tenant_id)
    REFERENCES customers (id, tenant_id)
    ON DELETE CASCADE;

-- 5. Add tenant ownership to order_items and backfill from the parent order.
ALTER TABLE order_items
    ADD COLUMN tenant_id UUID;

UPDATE order_items oi
SET tenant_id = o.tenant_id
FROM orders o
WHERE o.id = oi.order_id;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM order_items
        WHERE tenant_id IS NULL
    ) THEN
        RAISE EXCEPTION
            'Migration 020 aborted: order item tenant backfill incomplete';
    END IF;
END;
$$;

ALTER TABLE order_items
    ALTER COLUMN tenant_id SET NOT NULL;

-- Replace single-column foreign keys with tenant-aware foreign keys.
ALTER TABLE order_items
    DROP CONSTRAINT fk_order_items_order;

ALTER TABLE order_items
    DROP CONSTRAINT fk_order_items_product;

ALTER TABLE order_items
    ADD CONSTRAINT fk_order_items_order_tenant
    FOREIGN KEY (order_id, tenant_id)
    REFERENCES orders (id, tenant_id)
    ON DELETE CASCADE;

ALTER TABLE order_items
    ADD CONSTRAINT fk_order_items_product_tenant
    FOREIGN KEY (product_id, tenant_id)
    REFERENCES products (id, tenant_id)
    ON DELETE RESTRICT;

-- 6. A run may only reference a configuration belonging to its agent.
ALTER TABLE agent_runs
    DROP CONSTRAINT fk_agent_runs_config;

ALTER TABLE agent_runs
    ADD CONSTRAINT fk_agent_runs_config_agent
    FOREIGN KEY (config_id, agent_id)
    REFERENCES agent_configs (id, agent_id)
    ON DELETE SET NULL (config_id);

-- Preserve the existing agent_runs.agent_id foreign key and its
-- ON DELETE CASCADE behavior. Do not reintroduce the history trigger
-- removed by migration 019.

-- 7. Supporting indexes for composite foreign-key lookups.
CREATE INDEX IF NOT EXISTS idx_inventory_product_tenant
    ON inventory (product_id, tenant_id);

CREATE INDEX IF NOT EXISTS idx_orders_customer_tenant
    ON orders (customer_id, tenant_id);

CREATE INDEX IF NOT EXISTS idx_order_items_order_tenant
    ON order_items (order_id, tenant_id);

CREATE INDEX IF NOT EXISTS idx_order_items_product_tenant
    ON order_items (product_id, tenant_id);

CREATE INDEX IF NOT EXISTS idx_agent_runs_config_agent
    ON agent_runs (config_id, agent_id);

COMMIT;
