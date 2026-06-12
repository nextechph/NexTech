// Supabase Configuration and Initialization
const SUPABASE_URL = "https://ixelabdnxkizgkgzdhnb.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4ZWxhYmRueGtpemdrZ3pkaG5iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEyMjY4MDIsImV4cCI6MjA5NjgwMjgwMn0.qiFoSGG95l2rfQGkvCJd0qEVNTpnpXD8f3hkb2Zov3Y";

if (typeof supabase === 'undefined') {
    console.warn("Supabase library not loaded yet. It should be loaded via CDN before this script runs.");
} else {
    window.supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
}

// Helper to ensure Supabase client is initialized or retry if loaded asynchronously
function getSupabaseClient() {
    if (window.supabaseClient) {
        return window.supabaseClient;
    }
    if (typeof supabase !== 'undefined') {
        window.supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
        return window.supabaseClient;
    }
    console.error("Supabase client is not available.");
    return null;
}
