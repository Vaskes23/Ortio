-- Ortio XR System - Supabase Database Schema
-- Deploy this via Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TABLES
-- ============================================================================

-- Users table (metadata for authenticated users)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    profile_image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT username_length CHECK (char_length(username) >= 3 AND char_length(username) <= 30),
    CONSTRAINT name_not_empty CHECK (char_length(name) > 0)
);

-- Models table (3D model metadata, files stored in Storage bucket)
CREATE TABLE IF NOT EXISTS models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT name_not_empty CHECK (char_length(name) > 0),
    CONSTRAINT file_size_positive CHECK (file_size > 0)
);

-- Annotations table (spatial feedback on 3D models)
CREATE TABLE IF NOT EXISTS annotations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID REFERENCES models(id) ON DELETE CASCADE NOT NULL,
    author_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,

    -- Position (model-relative coordinates)
    position_x REAL NOT NULL,
    position_y REAL NOT NULL,
    position_z REAL NOT NULL,

    -- Rotation (quaternion: x, y, z, w)
    rotation_x REAL NOT NULL,
    rotation_y REAL NOT NULL,
    rotation_z REAL NOT NULL,
    rotation_w REAL NOT NULL,

    -- Content
    title TEXT NOT NULL,
    content TEXT NOT NULL,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT title_length CHECK (char_length(title) > 0 AND char_length(title) <= 50),
    CONSTRAINT content_length CHECK (char_length(content) > 0 AND char_length(content) <= 500)
);

-- Model sharing table (many-to-many relationship)
CREATE TABLE IF NOT EXISTS model_shares (
    model_id UUID REFERENCES models(id) ON DELETE CASCADE NOT NULL,
    shared_with_user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    permission TEXT DEFAULT 'view' NOT NULL,
    shared_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (model_id, shared_with_user_id),

    CONSTRAINT valid_permission CHECK (permission IN ('view', 'annotate'))
);

-- ============================================================================
-- INDEXES (for performance)
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_models_owner_id ON models(owner_id);
CREATE INDEX IF NOT EXISTS idx_models_created_at ON models(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_annotations_model_id ON annotations(model_id);
CREATE INDEX IF NOT EXISTS idx_annotations_author_id ON annotations(author_id);
CREATE INDEX IF NOT EXISTS idx_annotations_created_at ON annotations(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_model_shares_shared_with ON model_shares(shared_with_user_id);

-- ============================================================================
-- ROW-LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE models ENABLE ROW LEVEL SECURITY;
ALTER TABLE annotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE model_shares ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "users_select_own" ON users
    FOR SELECT
    USING (id = auth.uid());

CREATE POLICY "users_update_own" ON users
    FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

CREATE POLICY "users_insert_own" ON users
    FOR INSERT
    WITH CHECK (id = auth.uid());

-- Models table policies
CREATE POLICY "models_select_own" ON models
    FOR SELECT
    USING (owner_id = auth.uid());

CREATE POLICY "models_select_shared" ON models
    FOR SELECT
    USING (
        id IN (
            SELECT model_id
            FROM model_shares
            WHERE shared_with_user_id = auth.uid()
        )
    );

CREATE POLICY "models_insert_own" ON models
    FOR INSERT
    WITH CHECK (owner_id = auth.uid());

CREATE POLICY "models_update_own" ON models
    FOR UPDATE
    USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());

CREATE POLICY "models_delete_own" ON models
    FOR DELETE
    USING (owner_id = auth.uid());

-- Annotations table policies
CREATE POLICY "annotations_select_own_model" ON annotations
    FOR SELECT
    USING (
        model_id IN (
            SELECT id
            FROM models
            WHERE owner_id = auth.uid()
        )
    );

CREATE POLICY "annotations_select_shared_model" ON annotations
    FOR SELECT
    USING (
        model_id IN (
            SELECT model_id
            FROM model_shares
            WHERE shared_with_user_id = auth.uid()
        )
    );

CREATE POLICY "annotations_insert_own_model" ON annotations
    FOR INSERT
    WITH CHECK (
        author_id = auth.uid() AND
        model_id IN (
            SELECT id
            FROM models
            WHERE owner_id = auth.uid()
        )
    );

CREATE POLICY "annotations_insert_shared_model" ON annotations
    FOR INSERT
    WITH CHECK (
        author_id = auth.uid() AND
        model_id IN (
            SELECT model_id
            FROM model_shares
            WHERE shared_with_user_id = auth.uid()
                AND permission = 'annotate'
        )
    );

CREATE POLICY "annotations_update_own" ON annotations
    FOR UPDATE
    USING (author_id = auth.uid())
    WITH CHECK (author_id = auth.uid());

CREATE POLICY "annotations_delete_own" ON annotations
    FOR DELETE
    USING (author_id = auth.uid());

-- Model shares table policies
CREATE POLICY "shares_select_own_model" ON model_shares
    FOR SELECT
    USING (
        model_id IN (
            SELECT id
            FROM models
            WHERE owner_id = auth.uid()
        )
    );

CREATE POLICY "shares_select_own" ON model_shares
    FOR SELECT
    USING (shared_with_user_id = auth.uid());

CREATE POLICY "shares_insert_own_model" ON model_shares
    FOR INSERT
    WITH CHECK (
        model_id IN (
            SELECT id
            FROM models
            WHERE owner_id = auth.uid()
        )
    );

CREATE POLICY "shares_delete_own_model" ON model_shares
    FOR DELETE
    USING (
        model_id IN (
            SELECT id
            FROM models
            WHERE owner_id = auth.uid()
        )
    );

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER models_updated_at
    BEFORE UPDATE ON models
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER annotations_updated_at
    BEFORE UPDATE ON annotations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
