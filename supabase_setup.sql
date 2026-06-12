-- NexTech Website Supabase Database Setup Schema
-- Run this script in the Supabase SQL Editor

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
    updated_at timestamptz DEFAULT now(),
    CONSTRAINT one_row CHECK (id = 1)
);

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
INSERT INTO public.site_settings (id, badge, subtitle, footer_desc, copyright, footer_url, facebook, twitter, instagram, tiktok, email)
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
    'hello@nextechnology.com'
)
ON CONFLICT (id) DO NOTHING;

-- Default Planner Config
INSERT INTO public.planner_config (id, student, addons, tiers, timeline)
VALUES (
    1,
    '{"title": "Student Discount", "desc": "Are you a student or building an educational project? We offer up to 20% discount on development rates.", "base": -20}'::jsonb,
    '[
        {"id": "seo", "name": "SEO Package", "desc": "Search engine optimization setup, meta tags, and indexing support.", "price": 150},
        {"id": "auth", "name": "User Auth & Profiles", "desc": "Login/Signup, social logins, and secure user profile databases.", "price": 300},
        {"id": "payment", "name": "Stripe/Payment Integration", "desc": "Accept credit cards, subscriptions, and issue invoices.", "price": 450},
        {"id": "admin", "name": "Admin Dashboard", "desc": "A custom back-office dashboard to manage your users and data.", "price": 600},
        {"id": "multilingual", "name": "Multilingual Support", "desc": "Translate your site or app into up to 3 different languages.", "price": 250}
    ]'::jsonb,
    '[
        {"id": "budget", "name": "Budget Tier", "desc": "Simple brochure website or MVP focused on core features with standard components.", "price": 1000},
        {"id": "growth", "name": "Growth Tier", "desc": "Fully custom site or mobile app with interactive states, custom animations, and CMS.", "price": 3500},
        {"id": "enterprise", "name": "Enterprise Tier", "desc": "Complex web app, custom backend integrations, high performance & scaling.", "price": 8000}
    ]'::jsonb,
    '[
        {"id": "rush", "name": "Rush (2-4 weeks)", "desc": "Fast-tracked schedule, dedicated developers.", "multiplier": 1.3},
        {"id": "standard", "name": "Standard (6-8 weeks)", "desc": "Our standard paced development cycle.", "multiplier": 1.0},
        {"id": "flexible", "name": "Flexible (3+ months)", "desc": "Lower priority, best value for long-term projects.", "multiplier": 0.9}
    ]'::jsonb
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
CREATE POLICY "Allow public read access to site_settings" ON public.site_settings
    FOR SELECT USING (true);

CREATE POLICY "Allow admin to modify site_settings" ON public.site_settings
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Services Policies
CREATE POLICY "Allow public read access to services" ON public.services
    FOR SELECT USING (true);

CREATE POLICY "Allow admin to modify services" ON public.services
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Portfolio Projects Policies
CREATE POLICY "Allow public read access to portfolio_projects" ON public.portfolio_projects
    FOR SELECT USING (true);

CREATE POLICY "Allow admin to modify portfolio_projects" ON public.portfolio_projects
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Blog Posts Policies
CREATE POLICY "Allow public read access to blog_posts" ON public.blog_posts
    FOR SELECT USING (true);

CREATE POLICY "Allow admin to modify blog_posts" ON public.blog_posts
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Planner Config Policies
CREATE POLICY "Allow public read access to planner_config" ON public.planner_config
    FOR SELECT USING (true);

CREATE POLICY "Allow admin to modify planner_config" ON public.planner_config
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Subscribers Policies
CREATE POLICY "Allow public to insert subscribers" ON public.subscribers
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow admin to manage subscribers" ON public.subscribers
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Contact Submissions Policies
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
CREATE POLICY "Allow public read of images" ON storage.objects
    FOR SELECT USING (bucket_id = 'images');

CREATE POLICY "Allow authenticated users to insert images" ON storage.objects
    FOR INSERT TO authenticated WITH CHECK (bucket_id = 'images');

CREATE POLICY "Allow authenticated users to update images" ON storage.objects
    FOR UPDATE TO authenticated USING (bucket_id = 'images') WITH CHECK (bucket_id = 'images');

CREATE POLICY "Allow authenticated users to delete images" ON storage.objects
    FOR DELETE TO authenticated USING (bucket_id = 'images');
