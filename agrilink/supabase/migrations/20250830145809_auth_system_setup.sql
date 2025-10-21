-- Location: supabase/migrations/20250830145809_auth_system_setup.sql
-- Schema Analysis: No existing schema found
-- Integration Type: Complete authentication system setup
-- Dependencies: None (initial migration)

-- 1. Create types for user management
CREATE TYPE public.user_role AS ENUM ('admin', 'farmer', 'veterinarian', 'buyer');
CREATE TYPE public.user_status AS ENUM ('active', 'inactive', 'pending', 'suspended');

-- 2. Core user profiles table (intermediary between auth.users and app data)
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    phone_number TEXT,
    role public.user_role DEFAULT 'farmer'::public.user_role,
    status public.user_status DEFAULT 'active'::public.user_status,
    avatar_url TEXT,
    location TEXT,
    farm_size TEXT,
    specialization TEXT, -- for veterinarians
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Essential indexes for performance
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX idx_user_profiles_status ON public.user_profiles(status);

-- 4. Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies using Pattern 1 (Core User Table)
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- 6. Function for automatic profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, role)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'farmer'::public.user_role)
  );
  RETURN NEW;
END;
$$;

-- 7. Trigger for automatic profile creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 8. Update trigger for user_profiles
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- 9. Mock data for testing
DO $$
DECLARE
    admin_uuid UUID := gen_random_uuid();
    farmer_uuid UUID := gen_random_uuid();
    vet_uuid UUID := gen_random_uuid();
BEGIN
    -- Create auth users with required fields for testing
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (admin_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@agrilink.com', crypt('admin123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Admin User", "role": "admin"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (farmer_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'farmer@agrilink.com', crypt('farmer123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "John Farmer", "role": "farmer"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (vet_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'vet@agrilink.com', crypt('vet123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Dr. Sarah Vet", "role": "veterinarian"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data creation failed: %', SQLERRM;
END $$;

-- 10. Cleanup function for testing
CREATE OR REPLACE FUNCTION public.cleanup_test_auth_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    test_user_ids UUID[];
BEGIN
    -- Get test user IDs
    SELECT ARRAY_AGG(id) INTO test_user_ids
    FROM auth.users
    WHERE email LIKE '%@agrilink.com';

    -- Delete in dependency order
    DELETE FROM public.user_profiles WHERE id = ANY(test_user_ids);
    DELETE FROM auth.users WHERE id = ANY(test_user_ids);

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
END;
$$;