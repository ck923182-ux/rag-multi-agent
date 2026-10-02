CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  tenant_id UUID NOT NULL,

  external_id VARCHAR(255),

  sku VARCHAR(100) NOT NULL,

  name VARCHAR(255) NOT NULL,

  description TEXT,

  price NUMERIC(12, 2) NOT NULL DEFAULT 0,

  status VARCHAR(50) NOT NULL DEFAULT 'active',

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT fk_products_tenant
    FOREIGN KEY (tenant_id)
    REFERENCES tenants(id)
    ON DELETE CASCADE,

  CONSTRAINT uq_products_tenant_sku
    UNIQUE (tenant_id, sku),

  CONSTRAINT chk_products_price
    CHECK (price >= 0)
);

CREATE INDEX IF NOT EXISTS idx_products_tenant_id
ON products(tenant_id);