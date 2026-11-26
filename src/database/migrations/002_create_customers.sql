CREATE TABLE IF NOT EXISTS customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  tenant_id UUID NOT NULL,

  external_id VARCHAR(255),

  first_name VARCHAR(100) NOT NULL,

  last_name VARCHAR(100),

  email VARCHAR(255),

  phone VARCHAR(50),

  status VARCHAR(50) NOT NULL DEFAULT 'active',

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT fk_customers_tenant
    FOREIGN KEY (tenant_id)
    REFERENCES tenants(id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_customers_tenant_id
ON customers(tenant_id);