CREATE TABLE IF NOT EXISTS inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  tenant_id UUID NOT NULL,

  product_id UUID NOT NULL,

  quantity INTEGER NOT NULL DEFAULT 0,

  reserved_quantity INTEGER NOT NULL DEFAULT 0,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT fk_inventory_tenant
    FOREIGN KEY (tenant_id)
    REFERENCES tenants(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_inventory_product
    FOREIGN KEY (product_id)
    REFERENCES products(id)
    ON DELETE CASCADE,

  CONSTRAINT uq_inventory_product
    UNIQUE (product_id),

  CONSTRAINT chk_inventory_quantity
    CHECK (quantity >= 0),

  CONSTRAINT chk_inventory_reserved_quantity
    CHECK (reserved_quantity >= 0),

  CONSTRAINT chk_inventory_reserved_not_greater
    CHECK (reserved_quantity <= quantity)
);

CREATE INDEX IF NOT EXISTS idx_inventory_tenant_id
ON inventory(tenant_id);

CREATE INDEX IF NOT EXISTS idx_inventory_product_id
ON inventory(product_id);