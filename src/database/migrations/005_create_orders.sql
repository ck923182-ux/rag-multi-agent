CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  tenant_id UUID NOT NULL,

  customer_id UUID NOT NULL,

  external_id VARCHAR(255),

  order_number VARCHAR(100) NOT NULL,

  status VARCHAR(50) NOT NULL DEFAULT 'pending',

  total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,

  currency VARCHAR(10) NOT NULL DEFAULT 'INR',

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT fk_orders_tenant
    FOREIGN KEY (tenant_id)
    REFERENCES tenants(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id)
    REFERENCES customers(id)
    ON DELETE CASCADE,

  CONSTRAINT uq_orders_tenant_order_number
    UNIQUE (tenant_id, order_number),

  CONSTRAINT chk_orders_total_amount
    CHECK (total_amount >= 0)
);

CREATE INDEX IF NOT EXISTS idx_orders_tenant_id
ON orders(tenant_id);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id
ON orders(customer_id);

CREATE INDEX IF NOT EXISTS idx_orders_status
ON orders(status);