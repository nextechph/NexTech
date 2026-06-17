-- NexTech Website Supabase Database Setup Schema
-- Run this script in the Supabase SQL Editor
-- This script is fully idempotent — safe to run multiple times.

-- --------------------------------------------------
-- 0. Drop ALL existing RLS policies (idempotency guard)
-- --------------------------------------------------

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT policyname, tablename
        FROM pg_policies
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', r.policyname, r.tablename);
    END LOOP;
END $$;

-- Drop storage.objects policies for our bucket
DROP POLICY IF EXISTS "Allow public read of images" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to insert images" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to update images" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete images" ON storage.objects;

-- --------------------------------------------------
-- 1. Create Tables
-- --------------------------------------------------

-- Site Settings Table (Single Row)
CREATE TABLE IF NOT EXISTS public.site_settings (
    id int8 PRIMARY KEY DEFAULT 1,
    badge text,
    subtitle text,
    footer_desc text,
    copyright text,
    footer_url text,
    facebook text,
    twitter text,
    instagram text,
    tiktok text,
    email text,
    location text DEFAULT 'Global / Distributed Remote',
    updated_at timestamptz DEFAULT now(),
    CONSTRAINT one_row CHECK (id = 1)
);

-- Services Table
CREATE TABLE IF NOT EXISTS public.services (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    num text,
    icon text,
    title text,
    desc_text text, -- using desc_text as "desc" is a reserved keyword in SQL
    bullets jsonb DEFAULT '[]'::jsonb,
    sort_order int4 DEFAULT 0
);

-- Portfolio Projects Table
CREATE TABLE IF NOT EXISTS public.portfolio_projects (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text,
    desc_text text, -- using desc_text as "desc" is a reserved keyword in SQL
    tag text,
    url text,
    image_url text,
    status text DEFAULT 'live', -- 'live' or 'coming-soon'
    sort_order int4 DEFAULT 0,
    created_at timestamptz DEFAULT now()
);

-- Blog Posts Table
CREATE TABLE IF NOT EXISTS public.blog_posts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text,
    excerpt text,
    content text,
    category text,
    author text,
    post_date text, -- using post_date as "date" can conflict or be confusing
    read_time text,
    image_url text,
    status text DEFAULT 'published', -- 'published' or 'draft'
    created_at timestamptz DEFAULT now()
);

-- Planner Config Table (Single Row)
CREATE TABLE IF NOT EXISTS public.planner_config (
    id int8 PRIMARY KEY DEFAULT 1,
    student jsonb DEFAULT '{}'::jsonb,
    addons jsonb DEFAULT '[]'::jsonb,
    tiers jsonb DEFAULT '[]'::jsonb,
    timeline jsonb DEFAULT '[]'::jsonb,
    contact_methods jsonb DEFAULT '["Email","WhatsApp","Phone Call","Zoom / Video Call","Facebook Messenger"]'::jsonb,
    updated_at timestamptz DEFAULT now(),
    CONSTRAINT one_row CHECK (id = 1)
);

-- Migration: add contact_methods to existing planner_config tables
ALTER TABLE public.planner_config
    ADD COLUMN IF NOT EXISTS contact_methods jsonb DEFAULT '["Email","WhatsApp","Phone Call","Zoom / Video Call","Facebook Messenger"]'::jsonb;

-- Subscribers Table
CREATE TABLE IF NOT EXISTS public.subscribers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text UNIQUE NOT NULL,
    subscribed_at timestamptz DEFAULT now()
);

-- Contact Submissions Table
CREATE TABLE IF NOT EXISTS public.contact_submissions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text,
    email text,
    subject text,
    message text,
    blueprint text, -- pre-filled planner summary or selected tier info
    submitted_at timestamptz DEFAULT now()
);

-- --------------------------------------------------
-- 2. Populate Default Data
-- --------------------------------------------------

-- Default Site Settings
INSERT INTO public.site_settings (id, badge, subtitle, footer_desc, copyright, footer_url, facebook, twitter, instagram, tiktok, email, location)
VALUES (
    1, 
    'Empowering Innovation', 
    'We build cutting-edge digital products and custom software solutions designed to help your business grow and thrive.',
    'NexTech is a leading software development and design agency specializing in modern web solutions, mobile apps, and enterprise software.',
    '© 2026 NexTech. All rights reserved.',
    'nextechnology.com',
    'facebook.com/nextech',
    'twitter.com/nextech',
    'instagram.com/nextech',
    'tiktok.com/@nextech',
    'hello@nextechnology.com',
    'Global / Distributed Remote'
)
ON CONFLICT (id) DO NOTHING;

-- Default Planner Config
INSERT INTO public.planner_config (id, student, addons, tiers, timeline, contact_methods)
VALUES (
    1,
    '{"title": "Student Starter Package", "base": 5000, "desc": "1-page website \u00b7 Mobile responsive \u00b7 1 revision \u00b7 Basic deployment"}'::jsonb,
    '[
        {"label": "Additional Page", "price": 1500, "note": "per page"},
        {"label": "Contact Form", "price": 1000, "note": ""},
        {"label": "Portfolio / Gallery Section", "price": 2000, "note": ""},
        {"label": "Blog Setup", "price": 2500, "note": ""},
        {"label": "SEO Optimization", "price": 1500, "note": ""},
        {"label": "Animations & Interactions", "price": 2000, "note": ""},
        {"label": "Custom Domain Setup", "price": 500, "note": ""},
        {"label": "Logo / Branding Design", "price": 3000, "note": ""},
        {"label": "Extra Revision Round", "price": 800, "note": "per round"},
        {"label": "Rush Delivery (under 2 weeks)", "price": 2000, "note": ""}
    ]'::jsonb,
    '[
        {"name": "Starter", "range": "\u20b110k \u2013 \u20b125k", "ideal": "Small sites & simple builds", "badge": "", "mult": 1},
        {"name": "Growth", "range": "\u20b125k \u2013 \u20b160k", "ideal": "Custom design & full-featured sites", "badge": "MOST POPULAR", "mult": 1.5},
        {"name": "Enterprise", "range": "\u20b160k+", "ideal": "Complex projects & large-scale builds", "badge": "", "mult": 2.2}
    ]'::jsonb,
    '[
        {"label": "Rush", "note": "2\u20134 weeks"},
        {"label": "Standard", "note": "1\u20132 months \u00b7 most common"},
        {"label": "Relaxed", "note": "3+ months \u00b7 no hard deadline"}
    ]'::jsonb,
    '["Email","WhatsApp","Phone Call","Zoom / Video Call","Facebook Messenger"]'::jsonb
)
ON CONFLICT (id) DO NOTHING;

-- --------------------------------------------------
-- 3. Enable Row Level Security (RLS)
-- --------------------------------------------------

ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portfolio_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.planner_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contact_submissions ENABLE ROW LEVEL SECURITY;

-- --------------------------------------------------
-- 4. Create RLS Policies
-- --------------------------------------------------

-- Site Settings Policies
DROP POLICY IF EXISTS "Allow public read access to site_settings" ON public.site_settings;
DROP POLICY IF EXISTS "Allow admin to modify site_settings" ON public.site_settings;
CREATE POLICY "Allow public read access to site_settings" ON public.site_settings
    FOR SELECT USING (true);
CREATE POLICY "Allow admin to modify site_settings" ON public.site_settings
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Services Policies
DROP POLICY IF EXISTS "Allow public read access to services" ON public.services;
DROP POLICY IF EXISTS "Allow admin to modify services" ON public.services;
CREATE POLICY "Allow public read access to services" ON public.services
    FOR SELECT USING (true);
CREATE POLICY "Allow admin to modify services" ON public.services
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Portfolio Projects Policies
DROP POLICY IF EXISTS "Allow public read access to portfolio_projects" ON public.portfolio_projects;
DROP POLICY IF EXISTS "Allow admin to modify portfolio_projects" ON public.portfolio_projects;
CREATE POLICY "Allow public read access to portfolio_projects" ON public.portfolio_projects
    FOR SELECT USING (true);
CREATE POLICY "Allow admin to modify portfolio_projects" ON public.portfolio_projects
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Blog Posts Policies
DROP POLICY IF EXISTS "Allow public read access to blog_posts" ON public.blog_posts;
DROP POLICY IF EXISTS "Allow admin to modify blog_posts" ON public.blog_posts;
CREATE POLICY "Allow public read access to blog_posts" ON public.blog_posts
    FOR SELECT USING (true);
CREATE POLICY "Allow admin to modify blog_posts" ON public.blog_posts
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Planner Config Policies
DROP POLICY IF EXISTS "Allow public read access to planner_config" ON public.planner_config;
DROP POLICY IF EXISTS "Allow admin to modify planner_config" ON public.planner_config;
CREATE POLICY "Allow public read access to planner_config" ON public.planner_config
    FOR SELECT USING (true);
CREATE POLICY "Allow admin to modify planner_config" ON public.planner_config
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Subscribers Policies
DROP POLICY IF EXISTS "Allow public to insert subscribers" ON public.subscribers;
DROP POLICY IF EXISTS "Allow admin to manage subscribers" ON public.subscribers;
CREATE POLICY "Allow public to insert subscribers" ON public.subscribers
    FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow admin to manage subscribers" ON public.subscribers
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Contact Submissions Policies
DROP POLICY IF EXISTS "Allow public to insert contact_submissions" ON public.contact_submissions;
DROP POLICY IF EXISTS "Allow admin to manage contact_submissions" ON public.contact_submissions;
CREATE POLICY "Allow public to insert contact_submissions" ON public.contact_submissions
    FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow admin to manage contact_submissions" ON public.contact_submissions
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- --------------------------------------------------
-- 5. Storage Buckets and Policies
-- --------------------------------------------------

-- Create 'images' bucket (publicly readable bucket)
INSERT INTO storage.buckets (id, name, public)
VALUES ('images', 'images', true)
ON CONFLICT (id) DO NOTHING;

-- RLS policies for storage.objects in the 'images' bucket
DROP POLICY IF EXISTS "Allow public read of images" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to insert images" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to update images" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete images" ON storage.objects;

CREATE POLICY "Allow public read of images" ON storage.objects
    FOR SELECT USING (bucket_id = 'images');

CREATE POLICY "Allow authenticated users to insert images" ON storage.objects
    FOR INSERT TO authenticated WITH CHECK (bucket_id = 'images');

CREATE POLICY "Allow authenticated users to update images" ON storage.objects
    FOR UPDATE TO authenticated USING (bucket_id = 'images') WITH CHECK (bucket_id = 'images');

CREATE POLICY "Allow authenticated users to delete images" ON storage.objects
    FOR DELETE TO authenticated USING (bucket_id = 'images');

-- --------------------------------------------------
-- 6. Grant Permissions to API Roles
-- --------------------------------------------------

GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, anon, authenticated, service_role;
