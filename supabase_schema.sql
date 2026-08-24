-- ==============================================================================
-- SIMULA PARINTINS - ESQUEMA E POLÍTICAS DE SEGURANÇA COMPLETAS (RLS)
-- ==============================================================================
-- Execute este script no "SQL Editor" do seu painel Supabase para liberar a leitura das parciais

-- 1. Garante que RLS está ativo na tabela
ALTER TABLE public.votos ENABLE ROW LEVEL SECURITY;

-- 2. Permite a LEITURA PÚBLICA dos votos (Necessário para a apuração do Top 3 nas Parciais e verificação de CPF)
DROP POLICY IF EXISTS "Permitir leitura de votos para apuracao" ON public.votos;
CREATE POLICY "Permitir leitura de votos para apuracao" 
ON public.votos 
FOR SELECT 
TO anon, authenticated 
USING (true);

-- 3. Permite a INSERÇÃO de votos com validação dos dados do eleitor
DROP POLICY IF EXISTS "Permitir insercao segura de votos" ON public.votos;
DROP POLICY IF EXISTS "Permitir insercao anonima de votos" ON public.votos;
CREATE POLICY "Permitir insercao segura de votos" 
ON public.votos 
FOR INSERT 
TO anon, authenticated 
WITH CHECK (
    length(nome_eleitor) >= 3 AND
    length(telefone) >= 10 AND
    length(cpf) >= 11
);

-- 4. Bloqueia qualquer ALTERAÇÃO de votos já registrados
DROP POLICY IF EXISTS "Bloquear alteracao de votos" ON public.votos;
CREATE POLICY "Bloquear alteracao de votos" 
ON public.votos 
FOR UPDATE 
TO anon 
USING (false);

-- 5. Bloqueia qualquer EXCLUSÃO de votos já registrados
DROP POLICY IF EXISTS "Bloquear exclusao de votos" ON public.votos;
CREATE POLICY "Bloquear exclusao de votos" 
ON public.votos 
FOR DELETE 
TO anon 
USING (false);
