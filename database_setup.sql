-- Enums and Data Types
CREATE TYPE facility_status AS ENUM ('available', 'congested', 'closed');
CREATE TYPE facility_type AS ENUM ('hospital', 'bhc', 'clinic');
CREATE TYPE facility_ownership_type AS ENUM ('GOVERNMENT_NATIONAL', 'GOVERNMENT_LGU', 'PRIVATE', 'NGO_CHARITABLE');
CREATE TYPE facility_service_capability AS ENUM ('BARANGAY_HEALTH_STATION', 'RURAL_HEALTH_UNIT', 'INFIRMARY', 'HOSPITAL_LEVEL_1', 'HOSPITAL_LEVEL_2', 'HOSPITAL_LEVEL_3', 'SPECIALIZED_CENTER');

CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'completed', 'cancelled', 'missed');
CREATE TYPE emergency_type AS ENUM ('sos', 'ambulance', 'accident', 'maternal', 'cardiac', 'other');
CREATE TYPE emergency_status AS ENUM ('pending', 'dispatched', 'arrived', 'completed', 'cancelled');

CREATE TYPE referral_priority_type AS ENUM ('ROUTINE', 'URGENT', 'EMERGENCY');
CREATE TYPE referral_case_category AS ENUM ('GENERAL_MEDICINE', 'MATERNAL_CHILD_HEALTH', 'TRAUMA_SURGERY', 'INFECTIOUS_DISEASE', 'DIALYSIS_RENAL', 'ANIMAL_BITE', 'MENTAL_HEALTH');
CREATE TYPE referral_status AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED', 'COMPLETED', 'CANCELLED');

-- Core Tables
-- Users (Patients) - Can be manual (temporary) or linked to auth.users
CREATE TABLE public.users (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  medical_id text UNIQUE DEFAULT ('ATAM-' || upper(substring(gen_random_uuid()::text from 1 for 8))),
  email text, -- Nullable for manual input
  first_name text NOT NULL,
  last_name text NOT NULL,
  phone_number text,
  birth_date date,
  barangay text,
  philhealth_id text,
  fcm_token text,
  is_profile_complete boolean DEFAULT false,
  is_temporary boolean DEFAULT false, -- True if manually created by staff/ambulance
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
  is_philhealth_accredited BOOLEAN DEFAULT FALSE,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT facilities_pkey PRIMARY KEY (id)
);

-- Facility Staff (RBAC)
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

-- Emergency Requests (Linked to Users with Cascade Update)
CREATE TABLE public.emergency_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id) ON UPDATE CASCADE,
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
  category text DEFAULT 'general',
  is_available boolean DEFAULT true,
  status text DEFAULT 'operational' CHECK (status IN ('operational', 'maintenance', 'offline')),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT facility_services_pkey PRIMARY KEY (id)
);

-- Family Members
CREATE TABLE public.family_members (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id) ON UPDATE CASCADE,
  full_name text NOT NULL,
  relationship text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT family_members_pkey PRIMARY KEY (id)
);

-- Bookings
CREATE TABLE public.bookings (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id uuid NOT NULL REFERENCES public.users(id) ON UPDATE CASCADE,
  facility_id bigint REFERENCES public.facilities(id),
  service_id uuid REFERENCES public.facility_services(id),
  family_member_id uuid REFERENCES public.family_members(id),
  facility_name text,
  appointment_time timestamp with time zone NOT NULL,
  status booking_status DEFAULT 'pending',
  triage_result text,
  triage_priority text,
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT bookings_pkey PRIMARY KEY (id)
);

-- Referrals
CREATE TABLE public.referrals (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  reference_number text DEFAULT ((('REF-'::text || to_char(now(), 'YYYYMMDD'::text)) || '-'::text) || SUBSTRING((gen_random_uuid())::text FROM 1 FOR 4)) UNIQUE,
  patient_id uuid REFERENCES public.users(id) ON UPDATE CASCADE,
  origin_facility_id bigint REFERENCES public.facilities(id),
  destination_facility_id bigint REFERENCES public.facilities(id),
  chief_complaint text,
  diagnosis_impression text,
  status referral_status DEFAULT 'PENDING',
  attachments text[],
  ai_priority_score float,
  ai_recommended_destination_id bigint REFERENCES public.facilities(id),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT referrals_pkey PRIMARY KEY (id)
);

-- Referral Pathways
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

-- Facility Resources
CREATE TABLE public.facility_resources (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  facility_id bigint NOT NULL REFERENCES public.facilities(id),
  resource_type text NOT NULL CHECK (resource_type IN ('ER_BEDS', 'WARD_BEDS', 'ICU_BEDS', 'OXYGEN')),
  total_capacity integer DEFAULT 0,
  current_occupied integer DEFAULT 0,
  last_updated timestamp with time zone DEFAULT now(),
  CONSTRAINT facility_resources_pkey PRIMARY KEY (id)
);

-- Facility Notifications
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
  user_id uuid REFERENCES auth.users(id),
  full_name text NOT NULL,
  specialty text DEFAULT 'General Medicine',
  is_online boolean DEFAULT false,
  current_wait_minutes integer DEFAULT 0,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT telemed_doctors_pkey PRIMARY KEY (id)
);

-- Triage Results
CREATE TABLE public.triage_results (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id) ON UPDATE CASCADE,
  raw_symptoms text NOT NULL,
  urgency text NOT NULL,
  specialty text,
  reason text,
  case_category TEXT,
  recommended_action TEXT,
  required_capability TEXT,
  summary_for_provider TEXT,
  soap_subjective TEXT,
  soap_objective TEXT,
  soap_assessment TEXT,
  soap_plan TEXT,
  is_telemed_suitable BOOLEAN DEFAULT FALSE,
  ai_confidence DOUBLE PRECISION DEFAULT 0.0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT triage_results_pkey PRIMARY KEY (id)
);

-- Barangays
CREATE TABLE public.barangays (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT barangays_pkey PRIMARY KEY (id)
);

-- Prescriptions
CREATE TABLE public.prescriptions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON UPDATE CASCADE,
  medication_name text NOT NULL,
  dosage text NOT NULL,
  doctor_name text NOT NULL,
  valid_until timestamp with time zone NOT NULL,
  instructions text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT prescriptions_pkey PRIMARY KEY (id)
);

-- Clinical Notes
CREATE TABLE public.clinical_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid REFERENCES public.users(id) ON UPDATE CASCADE,
  doctor_id uuid REFERENCES auth.users(id),
  referral_id uuid REFERENCES public.referrals(id),
  subjective_notes text,
  objective_notes text,
  assessment text,
  plan text,
  vital_signs jsonb DEFAULT '{}'::jsonb,
  created_at timestamp with time zone DEFAULT now()
);

-- Telemed Sessions
CREATE TABLE public.telemed_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id uuid REFERENCES public.telemed_doctors(id),
  patient_id uuid REFERENCES public.users(id) ON UPDATE CASCADE,
  status text CHECK (status IN ('scheduled', 'active', 'completed')),
  meeting_link text,
  started_at timestamp with time zone,
  ended_at timestamp with time zone
);

-- Audit Logs
CREATE TABLE public.audit_logs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id),
  facility_id bigint REFERENCES public.facilities(id),
  action text NOT NULL,
  details jsonb,
  created_at timestamptz DEFAULT now()
);

-- Beds
CREATE TABLE public.beds (
  id bigint generated by default as identity not null,
  bed_label text not null,
  facility_id bigint not null REFERENCES public.facilities (id) on delete CASCADE,
  resource_id uuid not null REFERENCES public.facility_resources (id) on delete CASCADE,
  status text not null DEFAULT 'AVAILABLE' CHECK (status IN ('AVAILABLE', 'OCCUPIED', 'CLEANING', 'MAINTENANCE', 'RESERVED')),
  patient_id uuid null REFERENCES public.users (id) on delete set null ON UPDATE CASCADE,
  updated_at timestamp with time zone DEFAULT now(),
  constraint beds_pkey primary key (id)
);

-- Functions & Triggers
-- Updated handle_new_user to support syncing from medical_id
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_medical_id text;
BEGIN
  v_medical_id := new.raw_user_meta_data->>'medical_id';

  IF v_medical_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.users WHERE medical_id = v_medical_id AND is_temporary = true) THEN
    UPDATE public.users
    SET
      id = new.id,
      email = new.email,
      first_name = COALESCE(new.raw_user_meta_data->>'first_name', first_name),
      last_name = COALESCE(new.raw_user_meta_data->>'last_name', last_name),
      phone_number = COALESCE(new.phone, new.raw_user_meta_data->>'phone', phone_number),
      birth_date = COALESCE((new.raw_user_meta_data->>'birth_date')::date, birth_date),
      philhealth_id = COALESCE(new.raw_user_meta_data->>'philhealth_id', philhealth_id),
      is_temporary = false,
      is_profile_complete = true,
      updated_at = now()
    WHERE medical_id = v_medical_id;
  ELSE
    INSERT INTO public.users (
      id,
      email,
      first_name,
      last_name,
      phone_number,
      birth_date,
      barangay,
      philhealth_id,
      is_profile_complete,
      is_temporary,
      medical_id
    )
    VALUES (
      new.id,
      new.email,
      new.raw_user_meta_data->>'first_name',
      new.raw_user_meta_data->>'last_name',
      COALESCE(new.phone, new.raw_user_meta_data->>'phone'),
      (new.raw_user_meta_data->>'birth_date')::date,
      new.raw_user_meta_data->>'barangay',
      new.raw_user_meta_data->>'philhealth_id',
      COALESCE((new.raw_user_meta_data->>'is_profile_complete')::boolean, false),
      false,
      COALESCE(new.raw_user_meta_data->>'medical_id', 'ATAM-' || upper(substring(gen_random_uuid()::text from 1 for 8)))
    );
  END IF;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = now();
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_facilities_updated_at BEFORE UPDATE ON public.facilities FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_ambulances_modtime BEFORE UPDATE ON public.ambulances FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- CORE LOGIC: Rapid Referral Transaction (RPC)
CREATE OR REPLACE FUNCTION create_referral_transaction(
  p_patient_id uuid,
  p_origin_facility_id bigint,
  p_destination_facility_id bigint,
  p_chief_complaint text,
  p_diagnosis text,
  p_priority text
)
RETURNS json LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_referral_id uuid;
  v_reference_number text;
  v_origin_name text;
BEGIN
  SELECT name INTO v_origin_name FROM public.facilities WHERE id = p_origin_facility_id;
  INSERT INTO public.referrals (patient_id, origin_facility_id, destination_facility_id, chief_complaint, diagnosis_impression, status)
  VALUES (p_patient_id, p_origin_facility_id, p_destination_facility_id, p_chief_complaint, p_diagnosis, 'PENDING'::referral_status)
  RETURNING id, reference_number INTO v_referral_id, v_reference_number;

  INSERT INTO public.facility_notifications (facility_id, type, message, related_record_id)
  VALUES (p_destination_facility_id, 'NEW_REFERRAL', 'Incoming ' || p_priority || ' referral from ' || v_origin_name || '. Ref: ' || v_reference_number, v_referral_id);

  RETURN json_build_object('referral_id', v_referral_id, 'reference_number', v_reference_number, 'status', 'success');
END;
$$;

-- Bed Count Automation
CREATE OR REPLACE FUNCTION update_resource_counts()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.facility_resources
  SET total_capacity = (SELECT count(*) FROM public.beds WHERE resource_id = NEW.resource_id),
      current_occupied = (SELECT count(*) FROM public.beds WHERE resource_id = NEW.resource_id AND status = 'OCCUPIED')
  WHERE id = NEW.resource_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_bed_counts AFTER INSERT OR UPDATE OR DELETE ON public.beds FOR EACH ROW EXECUTE PROCEDURE update_resource_counts();

-- RLS Policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.facilities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.facility_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ambulances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.facility_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_pathways ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.facility_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.facility_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.telemed_doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.triage_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.barangays ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clinical_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.telemed_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.beds ENABLE ROW LEVEL SECURITY;

-- Policy definitions
CREATE POLICY "Public facilities viewable by all" ON public.facilities FOR SELECT USING (true);
CREATE POLICY "Barangays viewable by all" ON public.barangays FOR SELECT USING (true);
CREATE POLICY "Ambulances viewable by all" ON public.ambulances FOR SELECT USING (true);
CREATE POLICY "Bed stats viewable by all" ON public.facility_resources FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Staff manage patients" ON public.users FOR ALL USING (
  EXISTS (SELECT 1 FROM public.facility_staff WHERE user_id = auth.uid()) OR
  EXISTS (SELECT 1 FROM public.ambulances WHERE current_driver_id = auth.uid())
);

CREATE POLICY "Users view own bookings" ON public.bookings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users create own bookings" ON public.bookings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Staff view facility bookings" ON public.bookings FOR SELECT USING (EXISTS (SELECT 1 FROM public.facility_staff WHERE user_id = auth.uid() AND facility_id = bookings.facility_id));

CREATE POLICY "Users view own triage" ON public.triage_results FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users create triage" ON public.triage_results FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Staff view referrals" ON public.referrals FOR SELECT USING (EXISTS (SELECT 1 FROM public.facility_staff WHERE user_id = auth.uid() AND (facility_id = referrals.origin_facility_id OR facility_id = referrals.destination_facility_id)));
CREATE POLICY "Staff update incoming referrals" ON public.referrals FOR UPDATE USING (EXISTS (SELECT 1 FROM public.facility_staff WHERE user_id = auth.uid() AND facility_id = referrals.destination_facility_id));

CREATE POLICY "Admins view logs" ON public.audit_logs FOR SELECT USING (EXISTS (SELECT 1 FROM public.facility_staff WHERE user_id = auth.uid() AND role = 'ADMIN'));

CREATE POLICY "Public view beds" ON public.beds FOR SELECT USING (true);
CREATE POLICY "Staff manage beds" ON public.beds FOR ALL USING (EXISTS (SELECT 1 FROM public.facility_staff WHERE user_id = auth.uid() AND facility_id = beds.facility_id));

-- Real-Time Setup
ALTER publication supabase_realtime ADD TABLE ambulances, emergency_requests, facility_resources, facility_notifications, beds;
