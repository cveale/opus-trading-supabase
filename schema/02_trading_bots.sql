-- Create trading_bots table
CREATE TABLE IF NOT EXISTS trading_bots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    strategy_type TEXT NOT NULL,
    strategy_config JSONB NOT NULL DEFAULT '{}',
    risk_level TEXT NOT NULL DEFAULT 'medium',
    max_positions INTEGER NOT NULL DEFAULT 5,
    max_allocation_percentage NUMERIC(5,2) NOT NULL DEFAULT 20.00,
    stop_loss_percentage NUMERIC(5,2),
    take_profit_percentage NUMERIC(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create bot_positions table for tracking active positions
CREATE TABLE IF NOT EXISTS bot_positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bot_id UUID NOT NULL REFERENCES trading_bots(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    quantity NUMERIC(16,6) NOT NULL,
    entry_price NUMERIC(16,6) NOT NULL,
    current_price NUMERIC(16,6),
    stop_loss_price NUMERIC(16,6),
    take_profit_price NUMERIC(16,6),
    status TEXT NOT NULL DEFAULT 'open',
    entry_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    exit_time TIMESTAMP WITH TIME ZONE,
    exit_price NUMERIC(16,6),
    profit_loss NUMERIC(16,6),
    profit_loss_percentage NUMERIC(7,2),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create bot_transactions table for tracking all transactions
CREATE TABLE IF NOT EXISTS bot_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bot_id UUID NOT NULL REFERENCES trading_bots(id) ON DELETE CASCADE,
    position_id UUID REFERENCES bot_positions(id) ON DELETE SET NULL,
    symbol TEXT NOT NULL,
    transaction_type TEXT NOT NULL,
    quantity NUMERIC(16,6) NOT NULL,
    price NUMERIC(16,6) NOT NULL,
    total_amount NUMERIC(16,6) NOT NULL,
    transaction_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'completed',
    order_id TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_bot_positions_bot_id ON bot_positions(bot_id);
CREATE INDEX IF NOT EXISTS idx_bot_positions_symbol ON bot_positions(symbol);
CREATE INDEX IF NOT EXISTS idx_bot_positions_status ON bot_positions(status);
CREATE INDEX IF NOT EXISTS idx_bot_transactions_bot_id ON bot_transactions(bot_id);
CREATE INDEX IF NOT EXISTS idx_bot_transactions_position_id ON bot_transactions(position_id);
CREATE INDEX IF NOT EXISTS idx_bot_transactions_symbol ON bot_transactions(symbol);

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_trading_bots_updated_at
BEFORE UPDATE ON trading_bots
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bot_positions_updated_at
BEFORE UPDATE ON bot_positions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Create RLS policies
ALTER TABLE trading_bots ENABLE ROW LEVEL SECURITY;
ALTER TABLE bot_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bot_transactions ENABLE ROW LEVEL SECURITY;

-- Create default policies (allowing all operations for now)
CREATE POLICY "Allow all operations on trading_bots" ON trading_bots
    FOR ALL
    USING (true);

CREATE POLICY "Allow all operations on bot_positions" ON bot_positions
    FOR ALL
    USING (true);

CREATE POLICY "Allow all operations on bot_transactions" ON bot_transactions
    FOR ALL
    USING (true);

-- Create a default trading bot for mock data
INSERT INTO trading_bots (
    name, 
    description, 
    strategy_type, 
    strategy_config, 
    risk_level, 
    max_positions, 
    max_allocation_percentage, 
    stop_loss_percentage, 
    take_profit_percentage
)
VALUES (
    'Momentum Trader', 
    'A bot that trades based on price momentum indicators', 
    'momentum', 
    '{
        "rsi_period": 14,
        "rsi_overbought": 70,
        "rsi_oversold": 30,
        "macd_fast_period": 12,
        "macd_slow_period": 26,
        "macd_signal_period": 9,
        "volume_threshold": 1000000
    }',
    'medium',
    5,
    20.00,
    5.00,
    15.00
)
ON CONFLICT DO NOTHING;