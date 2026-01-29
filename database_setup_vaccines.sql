-- Vaccines Table Setup
CREATE TABLE public.vaccines (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  manufacturer text,
  doses_required integer DEFAULT 1,
  min_age_months integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT vaccines_pkey PRIMARY KEY (id)
);

-- Vaccine Stock / Availability at Facilities
CREATE TABLE public.facility_vaccines (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  facility_id bigint NOT NULL REFERENCES public.facilities(id) ON DELETE CASCADE,
  vaccine_id uuid NOT NULL REFERENCES public.vaccines(id) ON DELETE CASCADE,
  stock_count integer DEFAULT 0,
  last_restocked timestamp with time zone DEFAULT now(),
  is_available boolean DEFAULT true,
  CONSTRAINT facility_vaccines_pkey PRIMARY KEY (id),
  UNIQUE(facility_id, vaccine_id)
);

-- Vaccine Appointments / Records
CREATE TABLE public.vaccine_records (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  vaccine_id uuid NOT NULL REFERENCES public.vaccines(id),
  facility_id bigint REFERENCES public.facilities(id),
  dose_number integer DEFAULT 1,
  administered_at timestamp with time zone,
  next_dose_due timestamp with time zone,
  status text DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'COMPLETED', 'CANCELLED', 'MISSED')),
  provider_name text,
  remarks text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT vaccine_records_pkey PRIMARY KEY (id)
);

-- Seed Data for Vaccines
INSERT INTO public.vaccines (name, description, manufacturer, doses_required, min_age_months)
VALUES 
('BCG', 'Bacille Calmette-Guérin vaccine against tuberculosis.', 'Multiple', 1, 0),
('Hepatitis B', 'Vaccine against Hepatitis B virus.', 'Multiple', 3, 0),
('Pentavalent (DTP-HepB-Hib)', 'Combined vaccine against Diphtheria, Tetanus, Pertussis, Hep B, and Hib.', 'Multiple', 3, 1),
('OPV', 'Oral Polio Vaccine.', 'Multiple', 3, 1),
('IPV', 'Inactivated Polio Vaccine.', 'Multiple', 2, 3),
('PCV', 'Pneumococcal Conjugate Vaccine.', 'Multiple', 3, 1),
('MMR', 'Vaccine against Measles, Mumps, and Rubella.', 'Multiple', 2, 9),
('COVID-19 (Pfizer)', 'mRNA vaccine for COVID-19 protection.', 'Pfizer-BioNTech', 2, 60);

-- Enable RLS
ALTER TABLE public.vaccines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.facility_vaccines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vaccine_records ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Vaccines viewable by all" ON public.vaccines FOR SELECT USING (true);
CREATE POLICY "Facility vaccines viewable by all" ON public.facility_vaccines FOR SELECT USING (true);
CREATE POLICY "Users view own vaccine records" ON public.vaccine_records FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Staff manage vaccine records" ON public.vaccine_records FOR ALL USING (EXISTS (SELECT 1 FROM public.facility_staff WHERE user_id = auth.uid()));

-- Real-time for vaccine stock updates
ALTER publication supabase_realtime ADD TABLE facility_vaccines;
