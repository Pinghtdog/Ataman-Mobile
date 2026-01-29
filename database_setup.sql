-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.ambulances (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  plate_number text NOT NULL UNIQUE,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  is_available boolean DEFAULT true,
  current_driver_id uuid,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT ambulances_pkey PRIMARY KEY (id),
  CONSTRAINT ambulances_current_driver_id_fkey FOREIGN KEY (current_driver_id) REFERENCES auth.users(id)
);
CREATE TABLE public.audit_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  facility_id bigint,
  action text NOT NULL,
  details jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT audit_logs_pkey PRIMARY KEY (id),
  CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT audit_logs_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facilities(id)
);
CREATE TABLE public.barangays (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT barangays_pkey PRIMARY KEY (id)
);
CREATE TABLE public.beds (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  bed_label text NOT NULL,
  status text NOT NULL DEFAULT 'available'::text CHECK (status = ANY (ARRAY['available'::text, 'occupied'::text, 'cleaning'::text, 'maintenance'::text, 'reserved'::text])),
  facility_id bigint NOT NULL,
  patient_id uuid,
  resource_id uuid,
  updated_at timestamp with time zone DEFAULT now(),
  ward_type text NOT NULL DEFAULT 'ER'::text,
  CONSTRAINT beds_pkey PRIMARY KEY (id),
  CONSTRAINT beds_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facilities(id),
  CONSTRAINT beds_resource_id_fkey FOREIGN KEY (resource_id) REFERENCES public.facility_resources(id),
  CONSTRAINT beds_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.users(id)
);
CREATE TABLE public.bookings (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id uuid NOT NULL,
  facility_id bigint,
  service_id uuid,
  family_member_id uuid,
  facility_name text,
  appointment_time timestamp with time zone NOT NULL,
  status USER-DEFINED DEFAULT 'pending'::booking_status,
  triage_result text,
  triage_priority text,
  created_at timestamp with time zone DEFAULT now(),
  notes text,
  nature_of_visit text DEFAULT 'New Consultation/Case'::text,
  chief_complaint text,
  referred_from text,
  referred_to text,
  CONSTRAINT bookings_pkey PRIMARY KEY (id),
  CONSTRAINT bookings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT bookings_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facilities(id),
  CONSTRAINT bookings_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.facility_services(id),
  CONSTRAINT bookings_family_member_id_fkey FOREIGN KEY (family_member_id) REFERENCES public.family_members(id)
);
CREATE TABLE public.clinical_notes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  patient_id uuid,
  doctor_id uuid,
  referral_id uuid,
  subjective_notes text,
  objective_notes text,
  assessment text,
  plan text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT clinical_notes_pkey PRIMARY KEY (id),
  CONSTRAINT clinical_notes_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.users(id),
  CONSTRAINT clinical_notes_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES auth.users(id),
  CONSTRAINT clinical_notes_referral_id_fkey FOREIGN KEY (referral_id) REFERENCES public.referrals(id)
);
CREATE TABLE public.departments (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  facility_id bigint,
  name text NOT NULL,
  specialty text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT departments_pkey PRIMARY KEY (id),
  CONSTRAINT departments_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facilities(id)
);
CREATE TABLE public.emergency_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  assigned_ambulance_id uuid,
  user_name text,
  user_phone text,
  address text,
  type USER-DEFINED DEFAULT 'sos'::emergency_type,
  status USER-DEFINED DEFAULT 'pending'::emergency_status,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT emergency_requests_pkey PRIMARY KEY (id),
  CONSTRAINT emergency_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT emergency_requests_assigned_ambulance_id_fkey FOREIGN KEY (assigned_ambulance_id) REFERENCES public.ambulances(id)
);
CREATE TABLE public.facilities (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  name text NOT NULL,
  short_code text UNIQUE,
  address text NOT NULL,
  barangay text,
  status USER-DEFINED DEFAULT 'available'::facility_status,
  type USER-DEFINED DEFAULT 'bhc'::facility_type,
  ownership USER-DEFINED DEFAULT 'GOVERNMENT_LGU'::facility_ownership_type,
  capability USER-DEFINED DEFAULT 'BARANGAY_HEALTH_STATION'::facility_service_capability,
  current_queue_length integer DEFAULT 0,
  has_doctor_on_site boolean DEFAULT false,
  meds_availability text DEFAULT 'Normal'::text,
  latitude double precision,
  longitude double precision,
  is_diversion_active boolean DEFAULT false,
  contact_number text,
  email text,
  website text,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  bed_types jsonb DEFAULT '[]'::jsonb,
  is_philhealth_accredited boolean DEFAULT false,
  CONSTRAINT facilities_pkey PRIMARY KEY (id)
);
CREATE TABLE public.facility_medicines (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  facility_id bigint,
  medicine_id uuid,
  price numeric NOT NULL,
  stock_count integer DEFAULT 0,
  is_in_stock boolean DEFAULT (stock_count > 0),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT facility_medicines_pkey PRIMARY KEY (id),
  CONSTRAINT facility_medicines_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facilities(id),
  CONSTRAINT facility_medicines_medicine_id_fkey FOREIGN KEY (medicine_id) REFERENCES public.medicines(id)
);
CREATE TABLE public.facility_notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  facility_id bigint NOT NULL,
  type text NOT NULL CHECK (type = ANY (ARRAY['NEW_REFERRAL'::text, 'BED_REQUEST'::text, 'SOS_INCOMING'::text])),
  message text NOT NULL,
  related_record_id uuid,
  is_read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT facility_notifications_pkey PRIMARY KEY (id),
  CONSTRAINT facility_notifications_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facilities(id)
);
CREATE TABLE public.facility_resources (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  facility_id bigint NOT NULL,
  resource_type text NOT NULL,
  total_capacity integer DEFAULT 0,
  current_occupied integer DEFAULT 0,
  last_updated timestamp with time zone DEFAULT now(),
  resource_category text,
  status text,
  sub_text text,
  department_id bigint,
  sub_category text,
  unit_label text,
  CONSTRAINT facility_resources_pkey PRIMARY KEY (id),
  CONSTRAINT facility_resources_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id)
);
CREATE TABLE public.facility_schedules (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  facility_id bigint,
  service_name text NOT NULL,
  schedule_day text NOT NULL,
  details text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT facility_schedules_pkey PRIMARY KEY (id),
  CONSTRAINT facility_schedules_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facilities(id)
);
CREATE TABLE public.facility_services (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  facility_id bigint,
  name text NOT NULL,
  category text DEFAULT 'general'::text,
  is_available boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  status text DEFAULT 'operational'::text CHECK (status = ANY (ARRAY['operational'::text, 'maintenance'::text, 'offline'::text])),
  max_slots_per_time_slot integer DEFAULT 2,
  CONSTRAINT facility_services_pkey PRIMARY KEY (id),
  CONSTRAINT facility_services_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facilities(id)
);
CREATE TABLE public.facility_staff (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  facility_id bigint NOT NULL,
  role text NOT NULL CHECK (role = ANY (ARRAY['ADMIN'::text, 'DOCTOR'::text, 'NURSE'::text, 'HEAD_NURSE'::text, 'TECHNICIAN'::text, 'RESIDENT'::text, 'SPECIALIST'::text, 'ATTENDANT'::text, 'HEALTH_OFFICER'::text, 'SUPPORT'::text, 'DISPATCHER'::text])),
  is_verified boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  department_id bigint,
  CONSTRAINT facility_staff_pkey PRIMARY KEY (id),
  CONSTRAINT facility_staff_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id),
  CONSTRAINT facility_staff_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT facility_staff_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facilities(id)
);
CREATE TABLE public.facility_vaccines (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  facility_id bigint NOT NULL,
  vaccine_id uuid NOT NULL,
  stock_count integer DEFAULT 0,
  last_restocked timestamp with time zone DEFAULT now(),
  is_available boolean DEFAULT (stock_count > 0),
  status text DEFAULT
CASE
    WHEN (stock_count > 10) THEN 'IN_STOCK'::text
    WHEN (stock_count > 0) THEN 'LIMITED'::text
    ELSE 'NO_STOCK'::text
END,
  CONSTRAINT facility_vaccines_pkey PRIMARY KEY (id),
  CONSTRAINT facility_vaccines_vaccine_id_fkey FOREIGN KEY (vaccine_id) REFERENCES public.vaccines(id),
  CONSTRAINT facility_vaccines_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facilities(id)
);
CREATE TABLE public.family_members (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  full_name text NOT NULL,
  relationship text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  age integer DEFAULT 0,
  is_active_account boolean DEFAULT false,
  birth_date date,
  medical_id text UNIQUE,
  gender text,
  is_verified boolean DEFAULT false,
  CONSTRAINT family_members_pkey PRIMARY KEY (id),
  CONSTRAINT family_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.ice_candidates (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  call_id uuid,
  candidate jsonb,
  type text CHECK (type = ANY (ARRAY['caller'::text, 'receiver'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT ice_candidates_pkey PRIMARY KEY (id),
  CONSTRAINT ice_candidates_call_id_fkey FOREIGN KEY (call_id) REFERENCES public.video_calls(id)
);
CREATE TABLE public.medical_history (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  title text NOT NULL,
  subtitle text NOT NULL,
  date timestamp with time zone NOT NULL DEFAULT now(),
  type text NOT NULL CHECK (type = ANY (ARRAY['consultation'::text, 'immunization'::text, 'emergency'::text, 'lab'::text])),
  tag text,
  extra_info text,
  has_pdf boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT medical_history_pkey PRIMARY KEY (id),
  CONSTRAINT medical_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.medicines (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  description text,
  category text,
  icon_name text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT medicines_pkey PRIMARY KEY (id)
);
CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  title text NOT NULL,
  body text NOT NULL,
  type text DEFAULT 'general'::text,
  is_read boolean DEFAULT false,
  data jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.prescriptions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  medication_name text NOT NULL,
  dosage text NOT NULL,
  doctor_name text NOT NULL,
  valid_until timestamp with time zone NOT NULL,
  instructions text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT prescriptions_pkey PRIMARY KEY (id),
  CONSTRAINT prescriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.referral_pathways (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  origin_facility_id bigint,
  destination_facility_id bigint,
  protocol_notes text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT referral_pathways_pkey PRIMARY KEY (id)
);
CREATE TABLE public.referrals (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  reference_number text DEFAULT ((('REF-'::text || to_char(now(), 'YYYYMMDD'::text)) || '-'::text) || SUBSTRING((gen_random_uuid())::text FROM 1 FOR 4)) UNIQUE,
  patient_id uuid,
  origin_facility_id bigint,
  destination_facility_id bigint,
  chief_complaint text,
  diagnosis_impression text,
  status USER-DEFINED DEFAULT 'PENDING'::referral_status,
  ai_priority_score double precision,
  ai_recommended_destination_id bigint,
  created_at timestamp with time zone DEFAULT now(),
  attachments ARRAY,
  doctor_name text,
  transport_type text,
  eta_status text,
  current_lat double precision,
  current_long double precision,
  ambulance_id uuid,
  service_stream USER-DEFINED,
  assigned_bed_id bigint,
  CONSTRAINT referrals_pkey PRIMARY KEY (id),
  CONSTRAINT referrals_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.users(id),
  CONSTRAINT referrals_ambulance_id_fkey FOREIGN KEY (ambulance_id) REFERENCES public.ambulances(id),
  CONSTRAINT referrals_assigned_bed_id_fkey FOREIGN KEY (assigned_bed_id) REFERENCES public.beds(id),
  CONSTRAINT referrals_origin_facility_id_fkey FOREIGN KEY (origin_facility_id) REFERENCES public.facilities(id),
  CONSTRAINT referrals_destination_facility_id_fkey FOREIGN KEY (destination_facility_id) REFERENCES public.facilities(id),
  CONSTRAINT referrals_ai_recommended_destination_id_fkey FOREIGN KEY (ai_recommended_destination_id) REFERENCES public.facilities(id)
);
CREATE TABLE public.resource_assignments (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  resource_id uuid UNIQUE,
  user_id uuid,
  assigned_at timestamp with time zone DEFAULT now(),
  facility_id bigint,
  expected_end_at timestamp with time zone,
  CONSTRAINT resource_assignments_pkey PRIMARY KEY (id),
  CONSTRAINT resource_assignments_resource_id_fkey FOREIGN KEY (resource_id) REFERENCES public.facility_resources(id),
  CONSTRAINT resource_assignments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.special_services (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  facility_id bigint,
  service_name text NOT NULL,
  frequency text,
  details text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT special_services_pkey PRIMARY KEY (id),
  CONSTRAINT special_services_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facilities(id)
);
CREATE TABLE public.telemed_doctors (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  full_name text NOT NULL,
  specialty text DEFAULT 'General Medicine'::text,
  is_online boolean DEFAULT false,
  current_wait_minutes integer DEFAULT 0,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT telemed_doctors_pkey PRIMARY KEY (id),
  CONSTRAINT telemed_doctors_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.telemed_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  doctor_id uuid,
  patient_id uuid,
  status text CHECK (status = ANY (ARRAY['scheduled'::text, 'active'::text, 'completed'::text])),
  meeting_link text,
  started_at timestamp with time zone,
  ended_at timestamp with time zone,
  CONSTRAINT telemed_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT telemed_sessions_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.telemed_doctors(id),
  CONSTRAINT telemed_sessions_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.users(id)
);
CREATE TABLE public.telemedicine_services (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  category text NOT NULL,
  title text NOT NULL,
  subtitle text,
  icon_name text,
  bg_color text,
  is_active boolean DEFAULT true,
  icon_color text,
  display_order integer DEFAULT 0,
  CONSTRAINT telemedicine_services_pkey PRIMARY KEY (id)
);
CREATE TABLE public.triage_results (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  raw_symptoms text NOT NULL,
  urgency text NOT NULL,
  case_category text,
  specialty text,
  recommended_action text,
  required_capability text,
  reason text,
  summary_for_provider text,
  soap_note jsonb DEFAULT '{}'::jsonb,
  is_telemed_suitable boolean DEFAULT false,
  ai_confidence double precision DEFAULT 0.0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT triage_results_pkey PRIMARY KEY (id),
  CONSTRAINT triage_results_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.triage_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  status text DEFAULT 'active'::text,
  current_step integer DEFAULT 1,
  history jsonb DEFAULT '[]'::jsonb,
  result jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT triage_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT triage_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.users (
  id uuid NOT NULL,
  email text,
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
  first_name text,
  last_name text,
  middle_name text,
  medical_id text DEFAULT ('ATAM-'::text || upper(SUBSTRING((gen_random_uuid())::text FROM 1 FOR 8))) UNIQUE,
  is_temporary boolean DEFAULT false,
  suffix text,
  maiden_name text,
  birthplace text,
  mother_name text,
  residential_address text,
  civil_status text,
  educational_attainment text,
  employment_status text,
  is_4ps_member boolean DEFAULT false,
  philhealth_status text,
  family_position text,
  is_pcb_member boolean DEFAULT false,
  CONSTRAINT users_pkey PRIMARY KEY (id)
);
CREATE TABLE public.vaccine_records (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  vaccine_id uuid NOT NULL,
  facility_id bigint,
  dose_number integer DEFAULT 1,
  administered_at timestamp with time zone,
  next_dose_due timestamp with time zone,
  status text DEFAULT 'PENDING'::text CHECK (status = ANY (ARRAY['PENDING'::text, 'COMPLETED'::text, 'CANCELLED'::text, 'MISSED'::text])),
  provider_name text,
  remarks text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT vaccine_records_pkey PRIMARY KEY (id),
  CONSTRAINT vaccine_records_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT vaccine_records_vaccine_id_fkey FOREIGN KEY (vaccine_id) REFERENCES public.vaccines(id),
  CONSTRAINT vaccine_records_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facilities(id)
);
CREATE TABLE public.vaccines (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  manufacturer text,
  doses_required integer DEFAULT 1,
  min_age_months integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  abbr text,
  CONSTRAINT vaccines_pkey PRIMARY KEY (id)
);
CREATE TABLE public.video_calls (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  doctor_id uuid,
  patient_id uuid,
  offer jsonb,
  answer jsonb,
  created_at timestamp with time zone DEFAULT now(),
  status text NOT NULL DEFAULT 'calling'::text CHECK (status = ANY (ARRAY['calling'::text, 'active'::text, 'ended'::text, 'missed'::text])),
  CONSTRAINT video_calls_pkey PRIMARY KEY (id)
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
