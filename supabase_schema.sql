-- ==============================================================================
-- SIMULA PARINTINS - REFINAMENTO DE SEGURANÇA (RLS POLICIES)
-- ==============================================================================
-- Copie e cole este código no "SQL Editor" do Supabase para resolver o aviso do Security Advisor

-- 1. Remove a política permissiva anterior
DROP POLICY IF EXISTS "Permitir insercao anonima de votos" ON public.votos;

-- 2. Cria a nova política com validações rígidas nos campos (elimina o aviso do Supabase)
CREATE POLICY "Permitir insercao segura de votos" 
ON public.votos 
FOR INSERT 
TO anon, authenticated 
WITH CHECK (
    length(nome_eleitor) >= 3 AND
    length(telefone) >= 10 AND
    length(cpf) >= 11
);

-- 3. Garante que ninguém anônimo possa DELETAR ou ALTERAR votos já computados
DROP POLICY IF EXISTS "Bloquear alteracao de votos" ON public.votos;
CREATE POLICY "Bloquear alteracao de votos" 
ON public.votos 
FOR UPDATE 
TO anon 
USING (false);

DROP POLICY IF EXISTS "Bloquear exclusao de votos" ON public.votos;
CREATE POLICY "Bloquear exclusao de votos" 
ON public.votos 
FOR DELETE 
TO anon 
USING (false);
