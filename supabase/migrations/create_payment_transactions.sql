-- Crear tabla para transacciones de pago
CREATE TABLE IF NOT EXISTS payment_transactions (
    id UUID DEFAULT gen_random_uuid () PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
    request_id UUID NOT NULL REFERENCES requests (id) ON DELETE CASCADE,
    quote_id UUID NOT NULL REFERENCES quotes (id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    transaction_id VARCHAR(100) UNIQUE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW()
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_payment_transactions_user_id ON payment_transactions (user_id);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_request_id ON payment_transactions (request_id);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_transaction_id ON payment_transactions (transaction_id);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions (status);

-- Habilitar Row Level Security (RLS)
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

-- Política: Los usuarios pueden ver sus propias transacciones
CREATE POLICY "Users can view their own transactions" ON payment_transactions FOR
SELECT USING (auth.uid () = user_id);

-- Política: Los usuarios pueden insertar sus propias transacciones
CREATE POLICY "Users can insert their own transactions" ON payment_transactions FOR
INSERT
WITH
    CHECK (auth.uid () = user_id);

-- Política: Los proveedores pueden ver transacciones relacionadas con sus cotizaciones
CREATE POLICY "Providers can view transactions for their quotes" ON payment_transactions FOR
SELECT USING (
        EXISTS (
            SELECT 1
            FROM quotes
            WHERE
                quotes.id = payment_transactions.quote_id
                AND quotes.provider_id = auth.uid ()
        )
    );

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_payment_transactions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar updated_at
CREATE TRIGGER update_payment_transactions_updated_at
    BEFORE UPDATE ON payment_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_payment_transactions_updated_at();