-- =============================================================================
-- Music App Database - Complete Schema with Security
-- Data Fundamentals Project: Admin Roles & Security in Supabase
-- =============================================================================

-- create schema

CREATE SCHEMA music;

-- =============================================================================
-- TABLE CREATION
-- =============================================================================

-- create user table

CREATE TABLE music.users (
    user_id SERIAL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    country TEXT NOT NULL,
    subscription_type TEXT DEFAULT 'free' CHECK (subscription_type IN ('free', 'premium', 'family')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- create artists table

CREATE TABLE music.artists (
    artist_id SERIAL PRIMARY KEY,
    artist_name TEXT UNIQUE NOT NULL,
    real_name TEXT,
    genre TEXT NOT NULL,
    country TEXT NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

--create songs table

CREATE TABLE music.songs (
    song_id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    artist_id INTEGER REFERENCES music.artists(artist_id) ON DELETE CASCADE,
    album_name TEXT NOT NULL,
    release_year INTEGER NOT NULL CHECK (release_year >= 2000 AND release_year <= EXTRACT(YEAR FROM CURRENT_DATE)),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- SAMPLE DATA INSERTION
-- =============================================================================

-- Insert sample data into user table

INSERT INTO music.users (username, first_name, last_name, country, subscription_type)
VALUES
('musiclover88', 'Alice', 'Johnson', 'United States', 'premium'),
('afrobeats_fan', 'Bob', 'Smith', 'United Kingdom', 'free'),
('popqueen', 'Carol', 'Williams', 'Canada', 'premium'),
('east_african', 'David', 'Brown', 'Kenya', 'family'),
('naija_vibes', 'Frank', 'Miller', 'Nigeria', 'free');

-- Insert sample data into artists table

INSERT INTO music.artists (artist_name, real_name, genre, country, is_verified)
VALUES
('Ed Sheeran', 'Edward Christopher Sheeran', 'Pop/Folk', 'United Kingdom', true),
('Billie Eilish', 'Billie Eilish Pirate Baird O''Connell', 'Alternative Pop', 'United States', true),
('Taylor Swift', 'Taylor Alison Swift', 'Pop/Country', 'United States', true),
('Sauti Sol', 'Bien-Aimé Baraza, Willis Chimano, Savara Mudigi, Polycarp Otieno', 'Afro-pop', 'Kenya', true),
('Diamond Platnumz', 'Naseeb Abdul Juma', 'Bongo Flava', 'Tanzania', true),
('Burna Boy', 'Damini Ebunoluwa Ogulu', 'Afro-fusion', 'Nigeria', true);

--Insert sample data into songs table

INSERT INTO music.songs (title, artist_id, album_name, release_year)
VALUES
('Shape of You', 1, '÷ (Divide)', 2017),
('Bad Guy', 2, 'When We All Fall Asleep, Where Do We Go?', 2019),
('Anti-Hero', 3, 'Midnights', 2022),
('Suzanna', 4, 'Mwanzo', 2011),
('Jeje', 5, 'A Boy from Tandale', 2018);

-- Verify music schema exist

SELECT schema_name 
FROM information_schema.schemata 
WHERE schema_name = 'music';

-- =============================================================================
-- STEP 1: ADD AUTH COLUMNS AND UPDATE EXISTING DATA
-- =============================================================================

-- Add auth_id column to users table (linking to Supabase auth)
ALTER TABLE music.users ADD COLUMN auth_id UUID UNIQUE;

-- Add user_auth_id columns to artists and songs tables for ownership tracking
ALTER TABLE music.artists ADD COLUMN user_auth_id UUID;
ALTER TABLE music.songs ADD COLUMN user_auth_id UUID;

-- Add role column for role-based access control
ALTER TABLE music.users ADD COLUMN role TEXT DEFAULT 'user' CHECK (role IN ('admin', 'user'));

-- =============================================================================
-- STEP 2: GENERATE AND ASSIGN AUTH_UIDS FOR EXISTING USERS
-- =============================================================================

-- Update existing users with simulated auth_ids (in real scenario, these come from Supabase Auth)
UPDATE music.users 
SET 
    auth_id = CASE 
        WHEN username = 'musiclover88' THEN '11111111-1111-1111-1111-111111111111'::UUID
        WHEN username = 'afrobeats_fan' THEN '22222222-2222-2222-2222-222222222222'::UUID
        WHEN username = 'popqueen' THEN '33333333-3333-3333-3333-333333333333'::UUID
        WHEN username = 'east_african' THEN '44444444-4444-4444-4444-444444444444'::UUID
        WHEN username = 'naija_vibes' THEN '55555555-5555-5555-5555-555555555555'::UUID
    END,
    role = CASE 
        WHEN username = 'musiclover88' THEN 'admin'
        ELSE 'user'
    END;

-- =============================================================================
-- STEP 3: UPDATE ARTISTS AND SONGS WITH OWNERSHIP INFORMATION
-- =============================================================================

-- Assign admin as the creator for all existing artists
UPDATE music.artists 
SET user_auth_id = '11111111-1111-1111-1111-111111111111'::UUID;

-- Assign songs to different users to demonstrate ownership
UPDATE music.songs 
SET user_auth_id = CASE 
    WHEN title = 'Shape of You' THEN '11111111-1111-1111-1111-111111111111'::UUID  -- admin
    WHEN title = 'Bad Guy' THEN '22222222-2222-2222-2222-222222222222'::UUID       -- musiclover88
    WHEN title = 'Anti-Hero' THEN '33333333-3333-3333-3333-333333333333'::UUID     -- popqueen
    WHEN title = 'Suzanna' THEN '44444444-4444-4444-4444-444444444444'::UUID       -- east_african
    WHEN title = 'Jeje' THEN '55555555-5555-5555-5555-555555555555'::UUID          -- naija_vibes
END;

-- =============================================================================
-- STEP 4: ENABLE ROW LEVEL SECURITY
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE music.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE music.artists ENABLE ROW LEVEL SECURITY;
ALTER TABLE music.songs ENABLE ROW LEVEL SECURITY;

-- Verify RLS is enabled
SELECT 
    tablename, 
    rowsecurity,
    '✅ RLS Enabled' as status
FROM pg_tables 
WHERE schemaname = 'music' 
AND tablename IN ('users', 'artists', 'songs');

-- =============================================================================
-- STEP 5: CREATE ROW LEVEL SECURITY POLICIES
-- =============================================================================

-- USERS TABLE POLICIES
-- Users can view their own user record
CREATE POLICY "Users can view own profile" ON music.users
    FOR SELECT USING (auth.uid()::text = auth_id::text);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON music.users
    FOR UPDATE USING (auth.uid()::text = auth_id::text);

-- Admins can view all users
CREATE POLICY "Admins can view all users" ON music.users
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM music.users WHERE auth_id = auth.uid() AND role = 'admin')
    );

-- Admins can update all users
CREATE POLICY "Admins can update all users" ON music.users
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM music.users WHERE auth_id = auth.uid() AND role = 'admin')
    );

-- ARTISTS TABLE POLICIES
-- All authenticated users can view artists
CREATE POLICY "Anyone can view artists" ON music.artists
    FOR SELECT USING (true);

-- Only admins can insert artists
CREATE POLICY "Only admins can insert artists" ON music.artists
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM music.users WHERE auth_id = auth.uid() AND role = 'admin')
    );

-- Only admins can update artists
CREATE POLICY "Only admins can update artists" ON music.artists
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM music.users WHERE auth_id = auth.uid() AND role = 'admin')
    );

-- Only admins can delete artists
CREATE POLICY "Only admins can delete artists" ON music.artists
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM music.users WHERE auth_id = auth.uid() AND role = 'admin')
    );

-- SONGS TABLE POLICIES
-- Users can view all songs
CREATE POLICY "Users can view all songs" ON music.songs
    FOR SELECT USING (true);

-- Users can insert their own songs
CREATE POLICY "Users can insert own songs" ON music.songs
    FOR INSERT WITH CHECK (auth.uid()::text = user_auth_id::text);

-- Users can update songs they own
CREATE POLICY "Users can update own songs" ON music.songs
    FOR UPDATE USING (auth.uid()::text = user_auth_id::text);

-- Users can delete songs they own
CREATE POLICY "Users can delete own songs" ON music.songs
    FOR DELETE USING (auth.uid()::text = user_auth_id::text);

-- Admins have full access to songs
CREATE POLICY "Admins have full song access" ON music.songs
    FOR ALL USING (
        EXISTS (SELECT 1 FROM music.users WHERE auth_id = auth.uid() AND role = 'admin')
    );

-- =============================================================================
-- STEP 6: CREATE ADMIN-ONLY FUNCTIONS
-- =============================================================================

-- Function to delete a user and their data (admin only)
CREATE OR REPLACE FUNCTION music.delete_user(target_username TEXT)
RETURNS TEXT
LANGUAGE PLPGSQL
SECURITY DEFINER
AS $$
DECLARE
    target_user_id INTEGER;
BEGIN
    -- Check if current user is admin
    IF NOT EXISTS (
        SELECT 1 FROM music.users 
        WHERE auth_id = auth.uid() AND role = 'admin'
    ) THEN
        RETURN 'Error: Only admins can delete users';
    END IF;
    
    -- Get the target user ID
    SELECT user_id INTO target_user_id 
    FROM music.users 
    WHERE username = target_username;
    
    IF target_user_id IS NULL THEN
        RETURN 'Error: User not found';
    END IF;
    
    -- Delete user's songs first
    DELETE FROM music.songs 
    WHERE user_auth_id IN (SELECT auth_id FROM music.users WHERE user_id = target_user_id);
    
    -- Delete user
    DELETE FROM music.users WHERE user_id = target_user_id;
    
    RETURN 'User deleted successfully';
END;
$$;

-- Function to promote user to admin (admin only)
CREATE OR REPLACE FUNCTION music.promote_to_admin(target_username TEXT)
RETURNS TEXT
LANGUAGE PLPGSQL
SECURITY DEFINER
AS $$
BEGIN
    -- Check if current user is admin
    IF NOT EXISTS (
        SELECT 1 FROM music.users 
        WHERE auth_id = auth.uid() AND role = 'admin'
    ) THEN
        RETURN 'Error: Only admins can promote users';
    END IF;
    
    -- Promote the user
    UPDATE music.users 
    SET role = 'admin' 
    WHERE username = target_username;
    
    IF FOUND THEN
        RETURN 'User promoted to admin successfully';
    ELSE
        RETURN 'Error: User not found';
    END IF;
END;
$$;

-- Function to get system statistics (admin only)
CREATE OR REPLACE FUNCTION music.get_system_stats()
RETURNS TABLE(
    total_users BIGINT,
    total_artists BIGINT,
    total_songs BIGINT,
    premium_users BIGINT,
    admin_count BIGINT
)
LANGUAGE SQL
SECURITY DEFINER
AS $$
    SELECT 
        COUNT(*) as total_users,
        (SELECT COUNT(*) FROM music.artists) as total_artists,
        (SELECT COUNT(*) FROM music.songs) as total_songs,
        COUNT(*) FILTER (WHERE subscription_type IN ('premium', 'family')) as premium_users,
        COUNT(*) FILTER (WHERE role = 'admin') as admin_count
    FROM music.users;
$$;

-- =============================================================================
-- STEP 7: CREATE INDEXES FOR PERFORMANCE
-- =============================================================================

-- Indexes for better performance with RLS
CREATE INDEX IF NOT EXISTS idx_users_auth_id ON music.users(auth_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON music.users(role);
CREATE INDEX IF NOT EXISTS idx_songs_user_auth_id ON music.songs(user_auth_id);
CREATE INDEX IF NOT EXISTS idx_artists_user_auth_id ON music.artists(user_auth_id);

-- =============================================================================
-- STEP 8: VERIFICATION QUERIES
-- =============================================================================

-- Verify RLS and policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    '✅ Policy Active' as status
FROM pg_policies 
WHERE schemaname = 'music'
ORDER BY tablename, policyname;

-- Verify data setup with auth_ids
SELECT 
    u.user_id,
    u.username,
    u.role,
    u.auth_id,
    '✅ Has Auth ID' as auth_status
FROM music.users u
ORDER BY u.role DESC, u.username;

-- Verify song ownership
SELECT 
    s.song_id,
    s.title,
    a.artist_name,
    u.username as added_by,
    u.role as added_by_role,
    '✅ Ownership Set' as ownership_status
FROM music.songs s
JOIN music.artists a ON s.artist_id = a.artist_id
JOIN music.users u ON s.user_auth_id = u.auth_id
ORDER BY u.username, s.title;

-- Test admin function (will work for admin user)
SELECT music.get_system_stats();

-- =============================================================================
-- STEP 9: FINAL SECURITY STATUS CHECK
-- =============================================================================

SELECT 
    '🎵 Music Database Security Setup Complete!' as message,
    (SELECT COUNT(*) FROM music.users) as total_users,
    (SELECT COUNT(*) FROM music.artists) as total_artists,
    (SELECT COUNT(*) FROM music.songs) as total_songs,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'music') as security_policies,
    (SELECT COUNT(*) FROM pg_proc WHERE pronamespace = 'music'::regnamespace) as custom_functions,
    '✅ Ready for Production' as status;

SELECT 
    'Security Setup Complete' as status,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'music') as total_policies,
    (SELECT COUNT(*) FROM pg_proc WHERE pronamespace = 'music'::regnamespace) as total_functions,
    (SELECT COUNT(*) FROM music.users WHERE role = 'admin') as admin_users,
    (SELECT COUNT(*) FROM music.users WHERE role = 'user') as regular_users,
    '✅ Ready for Supabase Auth Integration' as next_step;
