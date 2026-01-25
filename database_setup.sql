--Enums and Data Types
-- 1. Facility Types & Attributes
CREATE TYPE facility_status AS ENUM ('available', 'congested', 'closed');
CREATE TYPE facility_type AS ENUM ('hospital', 'bhc', 'clinic');
CREATE TYPE facility_ownership_type AS ENUM ('GOVERNMENT_NATIONAL', 'GOVERNMENT_LGU', 'PRIVATE', 'NGO_CHARITABLE');
CREATE TYPE facility_service_capability AS ENUM ('BARANGAY_HEALTH_STATION', 'RURAL_HEALTH_UNIT', 'INFIRMARY', 'HOSPITAL_LEVEL_1', 'HOSPITAL_LEVEL_2', 'HOSPITAL_LEVEL_3', 'SPECIALIZED_CENTER');

-- 2. Booking & Emergency
CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'completed', 'cancelled', 'missed');
CREATE TYPE emergency_type AS ENUM ('sos', 'ambulance', 'accident', 'maternal', 'cardiac', 'other');
CREATE TYPE emergency_status AS ENUM ('pending', 'dispatched', 'arrived', 'completed', 'cancelled');

-- 3. Referral Logic
CREATE TYPE referral_priority_type AS ENUM ('ROUTINE', 'URGENT', 'EMERGENCY');
CREATE TYPE referral_case_category AS ENUM ('GENERAL_MEDICINE', 'MATERNAL_CHILD_HEALTH', 'TRAUMA_SURGERY', 'INFECTIOUS_DISEASE', 'DIALYSIS_RENAL', 'ANIMAL_BITE', 'MENTAL_HEALTH');
CREATE TYPE referral_status AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED', 'COMPLETED', 'CANCELLED');


--Core Tables
-- Users (Patients) - Extends auth.users
CREATE TABLE public.users (
  id uuid NOT NULL REFERENCES auth.users(id),
  email text NOT NULL,
  full_name text,
  phone_number text,
  birth_date date,
  barangay text,
  philhealth_id text,
  fcm_token text,
  is_profile_complete boolean DEFAULT false,
  gender text,
  blood_type text,
  emergency_contact_name text,
  emergency_contact_phone text,
  allergies text,
  medical_conditions text,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT users_pkey PRIMARY KEY (id)
);

-- Facilities (Hospitals/Clinics)
CREATE TABLE public.facilities (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  name text NOT NULL,
  short_code text UNIQUE,
  address text NOT NULL,
  barangay text,
  status facility_status DEFAULT 'available',
  type facility_type DEFAULT 'bhc',
  ownership facility_ownership_type DEFAULT 'GOVERNMENT_LGU',
  capability facility_service_capability DEFAULT 'BARANGAY_HEALTH_STATION',
  current_queue_length integer DEFAULT 0,
  has_doctor_on_site boolean DEFAULT false,
  meds_availability text DEFAULT 'Normal',
  latitude double precision,
  longitude double precision,
  is_diversion_active boolean DEFAULT false,
  contact_number text,
  email text,
  website text,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT facilities_pkey PRIMARY KEY (id)
);

-- Facility Staff (RBAC for Command Center)
CREATE TABLE public.facility_staff (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  facility_id bigint NOT NULL REFERENCES public.facilities(id),
  role text NOT NULL CHECK (role IN ('ADMIN', 'DOCTOR', 'NURSE', 'DISPATCHER')),
  is_verified boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT facility_staff_pkey PRIMARY KEY (id)
);

-- Ambulances
CREATE TABLE public.ambulances (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  plate_number text NOT NULL UNIQUE,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  is_available boolean DEFAULT true,
  current_driver_id uuid REFERENCES auth.users(id),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT ambulances_pkey PRIMARY KEY (id)
);

-- Emergency Requests
CREATE TABLE public.emergency_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id),
  assigned_ambulance_id uuid REFERENCES public.ambulances(id),
  user_name text,
  user_phone text,
  address text,
  type emergency_type DEFAULT 'sos',
  status emergency_status DEFAULT 'pending',
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT emergency_requests_pkey PRIMARY KEY (id)
);

-- Facility Services
CREATE TABLE public.facility_services (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  facility_id bigint REFERENCES public.facilities(id),
  name text NOT NULL,
  category text DEFAULT 'general', -- 'Reproductive Health' triggers privacy rules
  is_available boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT facility_services_pkey PRIMARY KEY (id)
);

ALTER TABLE public.facility_services
ADD COLUMN status text DEFAULT 'operational' CHECK (status IN ('operational', 'maintenance', 'offline'));


-- Family Members (for booking on behalf of others)
CREATE TABLE public.family_members (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id),
  full_name text NOT NULL,
  relationship text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT family_members_pkey PRIMARY KEY (id)
);

-- Bookings (Appointments)
CREATE TABLE public.bookings (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id uuid NOT NULL REFERENCES public.users(id),
  facility_id bigint REFERENCES public.facilities(id),
  service_id uuid REFERENCES public.facility_services(id),
  family_member_id uuid REFERENCES public.family_members(id),
  facility_name text,
  appointment_time timestamp with time zone NOT NULL,
  status booking_status DEFAULT 'pending',
  triage_result text,
  triage_priority text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT bookings_pkey PRIMARY KEY (id)
);

ALTER TABLE public.bookings ADD COLUMN notes text;


-- Referrals (Hospital to Hospital)
CREATE TABLE public.referrals (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  reference_number text DEFAULT ((('REF-'::text || to_char(now(), 'YYYYMMDD'::text)) || '-'::text) || SUBSTRING((gen_random_uuid())::text FROM 1 FOR 4)) UNIQUE,
  patient_id uuid REFERENCES public.users(id),
  origin_facility_id bigint REFERENCES public.facilities(id),
  destination_facility_id bigint REFERENCES public.facilities(id),
  chief_complaint text,
  diagnosis_impression text,
  status referral_status DEFAULT 'PENDING',
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT referrals_pkey PRIMARY KEY (id)
);
ALTER TABLE public.referrals ADD COLUMN attachments text[];


-- AI Suggestions
-- Store AI insights so the dashboard can display "Recommended Referral"
ALTER TABLE public.referrals
ADD COLUMN ai_priority_score float,
ADD COLUMN ai_recommended_destination_id bigint REFERENCES public.facilities(id);


-- Referral Pathways (Rules for Auto-Referral)
CREATE TABLE public.referral_pathways (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  origin_facility_id bigint REFERENCES public.facilities(id),
  destination_facility_id bigint REFERENCES public.facilities(id),
  case_category referral_case_category NOT NULL,
  priority_level referral_priority_type NOT NULL,
  protocol_notes text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT referral_pathways_pkey PRIMARY KEY (id)
);

-- Facility Resources (Real-time Bed Tracking)
CREATE TABLE public.facility_resources (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  facility_id bigint NOT NULL REFERENCES public.facilities(id),
  resource_type text NOT NULL CHECK (resource_type IN ('ER_BEDS', 'WARD_BEDS', 'ICU_BEDS', 'OXYGEN')),
  total_capacity integer DEFAULT 0,
  current_occupied integer DEFAULT 0,
  last_updated timestamp with time zone DEFAULT now(),
  CONSTRAINT facility_resources_pkey PRIMARY KEY (id)
);

-- Facility Notifications (Alerts for Command Center)
CREATE TABLE public.facility_notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  facility_id bigint NOT NULL REFERENCES public.facilities(id),
  type text NOT NULL CHECK (type IN ('NEW_REFERRAL', 'BED_REQUEST', 'SOS_INCOMING')),
  message text NOT NULL,
  related_record_id uuid,
  is_read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT facility_notifications_pkey PRIMARY KEY (id)
);

-- Telemed Doctors
CREATE TABLE public.telemed_doctors (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id), -- Linked for login
  full_name text NOT NULL,
  specialty text DEFAULT 'General Medicine',
  is_online boolean DEFAULT false,
  current_wait_minutes integer DEFAULT 0,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT telemed_doctors_pkey PRIMARY KEY (id)
);

-- Triage Results (AI/Manual)
CREATE TABLE public.triage_results (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id),
  raw_symptoms text NOT NULL,
  urgency text NOT NULL,
  specialty text,
  reason text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT triage_results_pkey PRIMARY KEY (id)
);


-- Enhance triage_results table for ATAMAN AI Pro features
ALTER TABLE triage_results
ADD COLUMN IF NOT EXISTS case_category TEXT,
ADD COLUMN IF NOT EXISTS recommended_action TEXT,
ADD COLUMN IF NOT EXISTS required_capability TEXT,
ADD COLUMN IF NOT EXISTS reason TEXT,
ADD COLUMN IF NOT EXISTS summary_for_provider TEXT,
ADD COLUMN IF NOT EXISTS soap_subjective TEXT,
ADD COLUMN IF NOT EXISTS soap_objective TEXT,
ADD COLUMN IF NOT EXISTS soap_assessment TEXT,
ADD COLUMN IF NOT EXISTS soap_plan TEXT;
-- Indexing for potential clinical reporting/analytics later
CREATE INDEX IF NOT EXISTS idx_triage_urgency ON triage_results(urgency);
CREATE INDEX IF NOT EXISTS idx_triage_case_category ON triage_results(case_category);
-- Add Telemedicine suitability and AI Confidence columns
 ALTER TABLE triage_results
ADD COLUMN IF NOT EXISTS is_telemed_suitable BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS ai_confidence DOUBLE PRECISION DEFAULT 0.0;


-- Barangays (Lookup)
CREATE TABLE public.barangays (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT barangays_pkey PRIMARY KEY (id)
);

-- Prescriptions
CREATE TABLE public.prescriptions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id),
  medication_name text NOT NULL,
  dosage text NOT NULL,
  doctor_name text NOT NULL,
  valid_until timestamp with time zone NOT NULL,
  instructions text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT prescriptions_pkey PRIMARY KEY (id)
);

--Digital Charting
CREATE TABLE public.clinical_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid REFERENCES public.users(id),
  doctor_id uuid REFERENCES auth.users(id),
  referral_id uuid REFERENCES public.referrals(id), -- If part of a referral
  subjective_notes text,
  objective_notes text,
  assessment text,
  plan text,
  created_at timestamp with time zone DEFAULT now()
);

ALTER TABLE public.clinical_notes ADD COLUMN vital_signs jsonb DEFAULT '{}'::jsonb;
-- Example data: {"bp": "120/80", "temp": 37.5, "hr": 80}


-- Telemed Session Logs (For the Video Pitch Feature)
CREATE TABLE public.telemed_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id uuid REFERENCES public.telemed_doctors(id),
  patient_id uuid REFERENCES public.users(id),
  status text CHECK (status IN ('scheduled', 'active', 'completed')),
  meeting_link text,
  started_at timestamp with time zone,
  ended_at timestamp with time zone
);

--audit logs
CREATE TABLE public.audit_logs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id),
  facility_id bigint REFERENCES public.facilities(id),
  action text NOT NULL, -- e.g., "UPDATED_BED_COUNT"
  details jsonb, -- e.g., {"old": 5, "new": 0}
  created_at timestamptz DEFAULT now()
);
-- Enable RLS so only Admins can see this
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins view logs" ON public.audit_logs FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.facility_staff WHERE user_id = auth.uid() AND role = 'ADMIN')
);






--Functions, Triggers & RPCs
--Trigger to Create User Profile on Sign Up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (
    id,
    email,
    phone_number,
    full_name,
    birth_date,
    barangay,
    philhealth_id,
    is_profile_complete
  )
  VALUES (
    new.id,
    new.email,
    COALESCE(new.phone, new.raw_user_meta_data->>'phone'),
    new.raw_user_meta_data->>'full_name',
    (new.raw_user_meta_data->>'birth_date')::date,
    new.raw_user_meta_data->>'barangay',
    new.raw_user_meta_data->>'philhealth_id',
    COALESCE((new.raw_user_meta_data->>'is_profile_complete')::boolean, false)
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

--Utility: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = now();
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_facilities_updated_at
BEFORE UPDATE ON public.facilities
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_ambulances_modtime
BEFORE UPDATE ON public.ambulances
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

--CORE LOGIC: Rapid Referral Transaction (RPC)
-- This ensures a notification is ALWAYS sent when a referral is created.
CREATE OR REPLACE FUNCTION create_referral_transaction(
  p_patient_id uuid,
  p_origin_facility_id bigint,
  p_destination_facility_id bigint,
  p_chief_complaint text,
  p_diagnosis text,
  p_priority text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_referral_id uuid;
  v_reference_number text;
  v_origin_name text;
BEGIN
  -- Get Origin Name
  SELECT name INTO v_origin_name
  FROM public.facilities
  WHERE id = p_origin_facility_id;

  -- Insert Referral
  INSERT INTO public.referrals (
    patient_id,
    origin_facility_id,
    destination_facility_id,
    chief_complaint,
    diagnosis_impression,
    status
  )
  VALUES (
    p_patient_id,
    p_origin_facility_id,
    p_destination_facility_id,
    p_chief_complaint,
    p_diagnosis,
    'PENDING'::referral_status
  )
  RETURNING id, reference_number INTO v_referral_id, v_reference_number;

  -- Create Notification for Destination
  INSERT INTO public.facility_notifications (
    facility_id,
    type,
    message,
    related_record_id
  )
  VALUES (
    p_destination_facility_id,
    'NEW_REFERRAL',
    'Incoming ' || p_priority || ' referral from ' || v_origin_name || '. Ref: ' || v_reference_number,
    v_referral_id
  );

  RETURN json_build_object(
    'referral_id', v_referral_id,
    'reference_number', v_reference_number,
    'status', 'success'
  );
END;
$$;


--Row Level Security (RLS) Policies
-- Enable RLS on all sensitive tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.facilities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ambulances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.facility_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.facility_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.facility_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.barangays ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.triage_results ENABLE ROW LEVEL SECURITY;

--PUBLIC READ (Reference Data)
CREATE POLICY "Public facilities viewable by all" ON public.facilities FOR SELECT USING (true);
CREATE POLICY "Barangays viewable by all" ON public.barangays FOR SELECT USING (true);
CREATE POLICY "Ambulances viewable by all" ON public.ambulances FOR SELECT USING (true); -- For GPS tracking
CREATE POLICY "Bed stats viewable by all" ON public.facility_resources FOR SELECT TO authenticated USING (true);

--PATIENT DATA (Users accessing their own records)
CREATE POLICY "Users view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users view own bookings" ON public.bookings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users create own bookings" ON public.bookings FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users view own emergencies" ON public.emergency_requests FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users create emergencies" ON public.emergency_requests FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users view own triage" ON public.triage_results FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users create triage" ON public.triage_results FOR INSERT WITH CHECK (auth.uid() = user_id);

-- HOSPITAL STAFF (Command Center Access)

-- Staff Roles
CREATE POLICY "Staff view own role" ON public.facility_staff FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins manage staff" ON public.facility_staff FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.facility_staff AS s
    WHERE s.user_id = auth.uid() AND s.role = 'ADMIN' AND s.facility_id = facility_staff.facility_id
  )
);

-- Staff Viewing Bookings (With Privacy Filter)
CREATE POLICY "Staff view facility bookings" ON public.bookings FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.facility_staff
    WHERE user_id = auth.uid() AND facility_id = bookings.facility_id
  )
  AND NOT EXISTS ( -- REPRODUCTIVE HEALTH PRIVACY FILTER
     SELECT 1 FROM public.facility_services
     WHERE id = bookings.service_id
     AND category = 'Reproductive Health'
  )
);

-- Staff Managing Referrals
CREATE POLICY "Staff view referrals" ON public.referrals FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.facility_staff
    WHERE user_id = auth.uid()
    AND (facility_id = referrals.origin_facility_id OR facility_id = referrals.destination_facility_id)
  )
);

CREATE POLICY "Staff update incoming referrals" ON public.referrals FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.facility_staff
    WHERE user_id = auth.uid() AND facility_id = referrals.destination_facility_id
  )
);

-- Staff Managing Resources (Beds)
CREATE POLICY "Staff update facility beds" ON public.facility_resources FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.facility_staff
    WHERE user_id = auth.uid() AND facility_id = facility_resources.facility_id
  )
);

-- Staff Notifications
CREATE POLICY "Staff view notifications" ON public.facility_notifications FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.facility_staff
    WHERE user_id = auth.uid() AND facility_id = facility_notifications.facility_id
  )
);


--Real-Time Setup
ALTER publication supabase_realtime ADD TABLE ambulances;
ALTER publication supabase_realtime ADD TABLE emergency_requests;
ALTER publication supabase_realtime ADD TABLE facility_resources;
ALTER publication supabase_realtime ADD TABLE facility_notifications;


