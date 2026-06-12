// Prevent browser from restoring scroll position on reload
if ('scrollRestoration' in history) {
    history.scrollRestoration = 'manual';
}
window.scrollTo(0, 0);

// ── SHARED ADMIN SETTINGS APPLICATOR ──
async function initSiteSettings() {
    // 1. First, apply cached settings immediately if available to avoid FOUC
    try {
        const cached = localStorage.getItem('nt_site_settings');
        if (cached) {
            const data = JSON.parse(cached);
            // Support both old flat structure and new timestamped structure
            const settings = data.settings || data;
            applySettingsDOM(settings);
        }
    } catch (e) {
        console.warn("Failed to parse cached settings:", e);
    }

    // 2. Fetch latest from Supabase if cache is expired or missing
    const CACHE_KEY = 'nt_site_settings';
    const CACHE_TTL = 5 * 60 * 1000; // 5 minutes in ms
    let shouldFetch = true;

    try {
        const cached = localStorage.getItem(CACHE_KEY);
        if (cached) {
            const data = JSON.parse(cached);
            if (data.timestamp && (Date.now() - data.timestamp < CACHE_TTL)) {
                shouldFetch = false;
            }
        }
    } catch (e) {}

    if (shouldFetch) {
        // Wait briefly for Supabase client to initialize if loaded asynchronously
        if (typeof supabase === 'undefined') {
            await new Promise(resolve => setTimeout(resolve, 300));
        }

        const supabaseClientInstance = window.supabaseClient || (typeof getSupabaseClient === 'function' ? getSupabaseClient() : null);
        if (supabaseClientInstance) {
            try {
                const { data, error } = await supabaseClientInstance
                    .from('site_settings')
                    .select('*')
                    .eq('id', 1)
                    .single();

                if (!error && data) {
                    const settings = {
                        badge: data.badge,
                        subtitle: data.subtitle,
                        footerDesc: data.footer_desc,
                        copyright: data.copyright,
                        facebook: data.facebook,
                        twitter: data.twitter,
                        instagram: data.instagram,
                        tiktok: data.tiktok,
                        footerUrl: data.footer_url,
                        email: data.email,
                        location: data.location
                    };
                    
                    // Save to cache
                    localStorage.setItem(CACHE_KEY, JSON.stringify({
                        settings,
                        timestamp: Date.now()
                    }));

                    // Apply to DOM
                    applySettingsDOM(settings);
                }
            } catch (err) {
                console.error("Failed to fetch settings from Supabase:", err);
            }
        }
    }
}

function applySettingsDOM(s) {
    if (!s) return;
    try {
        // Footer tagline
        const footerDesc = document.querySelector('.footer-desc');
        if (footerDesc && s.footerDesc) footerDesc.textContent = s.footerDesc;
        // Copyright
        const copyright = document.querySelector('.footer-bottom p');
        if (copyright && s.copyright) copyright.textContent = s.copyright;
        // Social links (order: facebook, twitter, instagram, tiktok)
        const socials = document.querySelectorAll('.social-links a');
        const urls = [s.facebook, s.twitter, s.instagram, s.tiktok];
        const defaults = [
            'https://facebook.com',
            'https://x.com',
            'https://instagram.com',
            'https://tiktok.com'
        ];
        socials.forEach((a, i) => {
            let href = urls[i] ? urls[i].trim() : '';
            if (href) {
                if (!/^https?:\/\//i.test(href)) {
                    href = 'https://' + href;
                }
                a.href = href;
            } else {
                a.href = defaults[i];
            }
        });
        // Footer URL display
        const footerUrl = document.querySelector('.footer-url');
        if (footerUrl && s.footerUrl) {
            footerUrl.textContent = s.footerUrl;
            let url = s.footerUrl.trim();
            if (url && !/^https?:\/\//i.test(url)) {
                url = 'https://' + url;
            }
            if (footerUrl.tagName === 'A') {
                footerUrl.href = url;
            }
        }
        // Hero badge (index.html only — no-op on other pages)
        const badge = document.querySelector('.hero-badge span:last-child');
        if (badge && s.badge) badge.textContent = s.badge;
        // Hero subtitle (index.html only — no-op on other pages)
        const sub = document.querySelector('.hero-subtitle');
        if (sub && s.subtitle) sub.textContent = s.subtitle;

        // Contact page elements
        const contactEmail = document.getElementById('contactEmail');
        if (contactEmail && s.email) {
            contactEmail.textContent = s.email;
            contactEmail.href = 'mailto:' + s.email;
        }

        const contactWeb = document.getElementById('contactWeb');
        if (contactWeb && s.footerUrl) {
            contactWeb.textContent = s.footerUrl;
            let webUrl = s.footerUrl.trim();
            if (webUrl && !/^https?:\/\//i.test(webUrl)) {
                webUrl = 'https://' + webUrl;
            }
            contactWeb.href = webUrl;
        }

        const contactLocation = document.getElementById('contactLocation');
        if (contactLocation && s.location) {
            contactLocation.textContent = s.location;
        }
    } catch (e) {
        console.error("Error applying site settings DOM:", e);
    }
}

initSiteSettings();

document.addEventListener('DOMContentLoaded', () => {
    // 1. Initialize Lucide Icons
    if (typeof lucide !== 'undefined') {
        lucide.createIcons();
    }

    // 2. Light/Dark Theme Switcher
    const themeToggleBtn = document.getElementById('themeToggleBtn');
    const htmlElement = document.documentElement;
    
    // Check saved preference or default to dark
    const savedTheme = localStorage.getItem('theme') || 'dark';
    htmlElement.setAttribute('data-theme', savedTheme);
    
    themeToggleBtn.addEventListener('click', () => {
        const currentTheme = htmlElement.getAttribute('data-theme');
        const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
        
        htmlElement.setAttribute('data-theme', newTheme);
        localStorage.setItem('theme', newTheme);
    });

    // 3. Mouse Follower Background Glow (Desk/Laptop Only)
    const bgGlow = document.getElementById('bgGlow');
    
    if (bgGlow && window.matchMedia('(pointer: fine)').matches) {
        document.addEventListener('mousemove', (e) => {
            bgGlow.style.opacity = '1';
            // Use client coordinates for fixed element placement
            bgGlow.style.left = `${e.clientX}px`;
            bgGlow.style.top = `${e.clientY}px`;
        });
        
        document.addEventListener('mouseleave', () => {
            bgGlow.style.opacity = '0';
        });
    }

    // 4. Mobile Menu Drawer Toggle
    const mobileMenuToggle = document.getElementById('mobileMenuToggle');
    const mobileNav = document.getElementById('mobileNav');
    
    if (mobileMenuToggle && mobileNav) {
        mobileMenuToggle.addEventListener('click', () => {
            const isOpen = mobileNav.classList.toggle('open');
            
            // Toggle menu icon between menu and X
            const icon = mobileMenuToggle.querySelector('i');
            if (icon) {
                if (isOpen) {
                    icon.setAttribute('data-lucide', 'x');
                } else {
                    icon.setAttribute('data-lucide', 'menu');
                }
                if (typeof lucide !== 'undefined') {
                    lucide.createIcons();
                }
            }
        });
        
        // Close menu when clicking nav link
        mobileNav.addEventListener('click', (e) => {
            if (e.target.classList.contains('mobile-nav-link') || e.target.classList.contains('mobile-btn')) {
                mobileNav.classList.remove('open');
                const icon = mobileMenuToggle.querySelector('i');
                if (icon) {
                    icon.setAttribute('data-lucide', 'menu');
                    if (typeof lucide !== 'undefined') {
                        lucide.createIcons();
                    }
                }
            }
        });
    }

    // 5. Interactive Project Planner Blueprint Calculator
    const serviceOptions = document.querySelectorAll('#serviceOptions .planner-opt-card');
    const budgetOptions = document.querySelectorAll('#budgetOptions .planner-opt-card');
    const timelineOptions = document.querySelectorAll('#timelineOptions .planner-opt-card');
    
    const sumServices = document.getElementById('sumServices');
    const sumBudget = document.getElementById('sumBudget');
    const sumTimeline = document.getElementById('sumTimeline');
    const sumEstimate = document.getElementById('sumEstimate');
    const applyBlueprintBtn = document.getElementById('applyBlueprintBtn');
    const projectDetails = document.getElementById('projectDetails');

    if (sumServices) {
        function updateBlueprint() {
            // Services
            const selectedServices = [];
            let totalWeight = 0;
            
            serviceOptions.forEach(opt => {
                if (opt.classList.contains('active')) {
                    selectedServices.push(opt.getAttribute('data-val'));
                    totalWeight += parseInt(opt.getAttribute('data-weight') || '0', 10);
                }
            });
            
            sumServices.textContent = selectedServices.length > 0 
                ? selectedServices.join(', ') 
                : 'None selected (Please choose at least one)';
                
            // Budget
            let activeBudget = 'Growth ($5k - $10k)';
            let budgetMultiplier = 1.5;
            budgetOptions.forEach(opt => {
                if (opt.classList.contains('active')) {
                    activeBudget = opt.getAttribute('data-val');
                    budgetMultiplier = parseFloat(opt.getAttribute('data-mult') || '1.0');
                }
            });
            if (sumBudget) sumBudget.textContent = activeBudget;
            
            // Timeline
            let activeTimeline = 'Standard (1 - 2 months)';
            timelineOptions.forEach(opt => {
                if (opt.classList.contains('active')) {
                    activeTimeline = opt.getAttribute('data-val');
                }
            });
            if (sumTimeline) sumTimeline.textContent = activeTimeline;
            
            // Intensity Score Calculation
            const score = totalWeight * budgetMultiplier;
            let intensityText = 'Light Intensity';
            
            if (score === 0) {
                intensityText = 'Select Services Above';
            } else if (score < 4) {
                intensityText = 'Light Intensity Blueprint';
            } else if (score < 8) {
                intensityText = 'Medium Intensity Blueprint';
            } else {
                intensityText = 'High Intensity (Enterprise Blueprint)';
            }
            
            if (sumEstimate) sumEstimate.textContent = intensityText;
        }
        
        // Service Option Clicks (Multiple Select)
        serviceOptions.forEach(opt => {
            opt.addEventListener('click', () => {
                opt.classList.toggle('active');
                updateBlueprint();
            });
        });
        
        // Budget Option Clicks (Single Select)
        budgetOptions.forEach(opt => {
            opt.addEventListener('click', () => {
                budgetOptions.forEach(o => o.classList.remove('active'));
                opt.classList.add('active');
                updateBlueprint();
            });
        });
        
        // Timeline Option Clicks (Single Select)
        timelineOptions.forEach(opt => {
            opt.addEventListener('click', () => {
                timelineOptions.forEach(o => o.classList.remove('active'));
                opt.classList.add('active');
                updateBlueprint();
            });
        });
        
        // Apply Blueprint to Inquiry Form
        if (applyBlueprintBtn && projectDetails) {
            applyBlueprintBtn.addEventListener('click', () => {
                const selectedServices = [];
                serviceOptions.forEach(opt => {
                    if (opt.classList.contains('active')) {
                        selectedServices.push(opt.getAttribute('data-val'));
                    }
                });
                
                let activeBudget = '';
                budgetOptions.forEach(opt => {
                    if (opt.classList.contains('active')) activeBudget = opt.getAttribute('data-val');
                });
                
                let activeTimeline = '';
                timelineOptions.forEach(opt => {
                    if (opt.classList.contains('active')) activeTimeline = opt.getAttribute('data-val');
                });
                
                if (selectedServices.length === 0) {
                    alert('Please select at least one service from the blueprint configuration.');
                    return;
                }
                
                // Format descriptive text block
                const formattedDesc = `Hello NexTech team, I have built a custom project blueprint:\n` +
                    `- Required Services: ${selectedServices.join(', ')}\n` +
                    `- Budget Bracket: ${activeBudget}\n` +
                    `- Target Timeline: ${activeTimeline}\n` +
                    `- Estimator: ${sumEstimate ? sumEstimate.textContent : ''}\n` +
                    `Please let me know how we can proceed.`;
                    
                projectDetails.value = formattedDesc;
                
                // Smooth scroll to contact section
                const contactSection = document.getElementById('contact');
                if (contactSection) {
                    // contactSection.scrollIntoView({ behavior: 'smooth' });
                    // Focus on contact details
                    setTimeout(() => {
                        const clientNameInput = document.getElementById('clientName');
                        if (clientNameInput) clientNameInput.focus();
                    }, 800);
                }
            });
        }
        
        // Run initial print
        updateBlueprint();
    }

    // 6. Interactive 3D Tilt Effect on Showcase Cards (Desktop Only)
    const tiltCards = document.querySelectorAll('.card-tilt');
    
    if (window.matchMedia('(pointer: fine)').matches) {
        tiltCards.forEach(card => {
            card.addEventListener('mousemove', (e) => {
                const rect = card.getBoundingClientRect();
                const x = e.clientX - rect.left; // Mouse relative X inside card
                const y = e.clientY - rect.top;  // Mouse relative Y inside card
                
                // Calculate percentages (-10 to 10 scale for subtle rotation)
                const rotateX = -((y / rect.height) - 0.5) * 12;
                const rotateY = ((x / rect.width) - 0.5) * 12;
                
                card.style.transform = `rotateX(${rotateX}deg) rotateY(${rotateY}deg) scale(1.015)`;
                card.style.transition = 'transform 0.1s ease';
            });
            
            card.addEventListener('mouseleave', () => {
                card.style.transform = 'rotateX(0deg) rotateY(0deg) scale(1)';
                card.style.transition = 'transform 0.5s cubic-bezier(0.16, 1, 0.3, 1)';
            });
        });
    }

    // Pre-fill contact form from Planner blueprint (passed via sessionStorage)
    const blueprintData = sessionStorage.getItem('nextech_blueprint');
    if (blueprintData) {
        const projectDetailsField = document.getElementById('projectDetails');
        if (projectDetailsField) {
            projectDetailsField.value = blueprintData;
            sessionStorage.removeItem('nextech_blueprint');
        }
    }

    // 7. Form Submission Handler
    const contactForm = document.getElementById('contactForm');
    const formStatus = document.getElementById('formStatus');
    
    if (contactForm && formStatus) {
        contactForm.addEventListener('submit', (e) => {
            e.preventDefault();
            
            const submitBtn = contactForm.querySelector('.btn-submit');
            const submitBtnText = submitBtn.querySelector('span');
            const originalText = submitBtnText.textContent;
            
            // Loading state
            submitBtn.style.pointerEvents = 'none';
            submitBtnText.textContent = 'Transmitting...';
            formStatus.className = 'form-status';
            formStatus.textContent = '';
            
            setTimeout(() => {
                // Success state simulation
                submitBtn.style.pointerEvents = 'all';
                submitBtnText.textContent = originalText;
                
                formStatus.className = 'form-status success';
                formStatus.innerHTML = '<i data-lucide="check-circle" style="width:14px;height:14px;vertical-align:middle;margin-right:6px;"></i>Inquiry received successfully. Our engineering team will follow up shortly.';
                
                if (typeof lucide !== 'undefined') {
                    lucide.createIcons();
                }
                
                contactForm.reset();
            }, 1500);
        });
    }

    // 8. Intersection Observer for Scroll Animations
    const animatedElements = document.querySelectorAll('.service-card, .portfolio-item, .section-header, .planner-card, .contact-layout');
    
    if ('IntersectionObserver' in window) {
        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };
        
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateY(0)';
                    observer.unobserve(entry.target);
                }
            });
        }, observerOptions);
        
        animatedElements.forEach(el => {
            // Setup initial states in JS if animations supported
            el.style.opacity = '0';
            el.style.transform = 'translateY(30px)';
            el.style.transition = 'opacity 0.8s cubic-bezier(0.16, 1, 0.3, 1), transform 0.8s cubic-bezier(0.16, 1, 0.3, 1)';
            observer.observe(el);
        });
    }
});

// ── Page Transition ──
document.addEventListener('DOMContentLoaded', () => {
    // Fade in on arrival
    document.body.style.opacity = '0';
    requestAnimationFrame(() => {
        document.body.style.transition = 'opacity 0.35s ease';
        document.body.style.opacity = '1';
    });

    // Fade out on nav link click (skip anchor-only links)
    document.querySelectorAll('a[href]').forEach(link => {
        const href = link.getAttribute('href');
        if (
            !href || href.startsWith('#') ||
            href.startsWith('mailto:') ||
            href.startsWith('http') ||
            link.target === '_blank'
        ) return;

        link.addEventListener('click', (e) => {
            e.preventDefault();
            document.body.classList.add('page-leaving');
            setTimeout(() => { window.location.href = href; }, 350);
        });
    });
});
