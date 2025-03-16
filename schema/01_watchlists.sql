-- Create watchlists table
CREATE TABLE IF NOT EXISTS watchlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    is_dynamic BOOLEAN NOT NULL DEFAULT FALSE,
    query TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create watchlist_stocks table for many-to-many relationship
CREATE TABLE IF NOT EXISTS watchlist_stocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    watchlist_id UUID NOT NULL REFERENCES watchlists(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(watchlist_id, symbol)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_watchlist_stocks_watchlist_id ON watchlist_stocks(watchlist_id);
CREATE INDEX IF NOT EXISTS idx_watchlist_stocks_symbol ON watchlist_stocks(symbol);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_watchlists_updated_at
BEFORE UPDATE ON watchlists
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Create RLS policies for watchlists
ALTER TABLE watchlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE watchlist_stocks ENABLE ROW LEVEL SECURITY;

-- Create default policies (allowing all operations for now)
CREATE POLICY "Allow all operations on watchlists" ON watchlists
    FOR ALL
    USING (true);

CREATE POLICY "Allow all operations on watchlist_stocks" ON watchlist_stocks
    FOR ALL
    USING (true);

-- Create a default watchlist for mock data
INSERT INTO watchlists (name, is_dynamic, query)
VALUES ('Default Watchlist', false, NULL)
ON CONFLICT DO NOTHING;

-- Add some default stocks to the default watchlist
WITH default_watchlist AS (
    SELECT id FROM watchlists WHERE name = 'Default Watchlist' LIMIT 1
)
INSERT INTO watchlist_stocks (watchlist_id, symbol)
VALUES 
    ((SELECT id FROM default_watchlist), 'AAPL'),
    ((SELECT id FROM default_watchlist), 'MSFT'),
    ((SELECT id FROM default_watchlist), 'GOOGL'),
    ((SELECT id FROM default_watchlist), 'AMZN'),
    ((SELECT id FROM default_watchlist), 'TSLA'),
    ((SELECT id FROM default_watchlist), 'META'),
    ((SELECT id FROM default_watchlist), 'NVDA'),
    ((SELECT id FROM default_watchlist), 'JPM'),
    ((SELECT id FROM default_watchlist), 'V'),
    ((SELECT id FROM default_watchlist), 'JNJ')
ON CONFLICT DO NOTHING;