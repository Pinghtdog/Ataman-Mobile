-- Seed medicines first if not exists
INSERT INTO public.medicines (name, description, category, icon_name)
VALUES
('Paracetamol', 'Pain reliever and a fever reducer', 'Analgesics', 'medication'),
('Amoxicillin', 'Antibiotic that fights bacteria', 'Antibiotics', 'medication'),
('Amlodipine', 'Used to treat high blood pressure', 'Antihypertensives', 'medication'),
('Metformin', 'Oral diabetes medicine', 'Antidiabetics', 'medication'),
('Cetirizine', 'Antihistamine used to relieve allergy symptoms', 'Antihistamines', 'medication')
ON CONFLICT (name) DO NOTHING;

-- Seed facility_medicines
-- Assuming facility IDs 1 to 5 exist based on typical seeds
INSERT INTO public.facility_medicines (facility_id, medicine_id, price, stock_count)
SELECT
  f.id as facility_id,
  m.id as medicine_id,
  (random() * (50 - 5) + 5)::numeric(10,2) as price,
  (random() * 500)::integer as stock_count
FROM public.facilities f
CROSS JOIN public.medicines m
WHERE m.name IN ('Paracetamol', 'Amoxicillin', 'Amlodipine', 'Metformin', 'Cetirizine')
LIMIT 20
ON CONFLICT (facility_id, medicine_id) DO UPDATE
SET stock_count = EXCLUDED.stock_count, price = EXCLUDED.price;
