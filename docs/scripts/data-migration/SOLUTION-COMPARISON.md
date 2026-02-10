# Comparação de Soluções - Impacto em Produção SQL Server

## Análise de Performance e Segurança

| Critério | Opção A: Concatenar | Opção B: Heredoc | Opção C: Local Temp |
|----------|-------------------|------------------|---------------------|
| **Sessões SQL** | 1 única | 1 única | 5 separadas ❌ |
| **Connection Overhead** | ✅ Mínimo (1 conexão) | ✅ Mínimo (1 conexão) | ❌ Alto (5 conexões) |
| **Tempdb Locks** | ✅ Consistente | ✅ Consistente | ❌ Fragmentado |
| **Memory Pressure** | ⚠️ Alto (~110M rows) | ⚠️ Alto (~110M rows) | ✅ Baixo (limpa por tier) |
| **Risk de Deadlock** | ✅ Zero | ✅ Zero | ⚠️ Médio |
| **Transaction Control** | ✅ Único ponto | ✅ Único ponto | ❌ Múltiplos pontos |
| **Rollback Capability** | ✅ Total | ✅ Total | ⚠️ Parcial |
| **Plan Cache Impact** | ✅ 1 plano | ✅ 1 plano | ⚠️ 5 planos |
| **NOLOCK Effectiveness** | ✅ Máxima | ✅ Máxima | ⚠️ Reduzida |
| **Manutenibilidade** | ✅ Alta | ⚠️ Média | ❌ Baixa |

## Impacto Detalhado em Produção

### Opção A: Concatenar Scripts (RECOMENDADA) ✅

**Vantagens:**
```
✅ UMA sessão = UMA transação lógica
✅ Locks adquiridos uma vez, liberados no final
✅ Sem overhead de autenticação (4× conexões economizadas)
✅ NOLOCK efetivo em TODAS as queries
✅ Tempdb allocation feita uma vez (mais eficiente)
✅ Execution plan cache otimizado
```

**Desvantagens:**
```
⚠️ Tempdb memory: ~110M rows em temp tables simultaneamente
   - m_upstream: 103M rows = ~8-10 GB estimado
   - poll: 2.5M rows = ~500 MB
   - container: 637k rows = ~200 MB
   - TOTAL: ~9-11 GB tempdb space (dentro do limite de 107 GB disponíveis)

⚠️ Rollback complexo: Se falhar no tier-3, precisa reexecutar tudo
   - Mitigação: Scripts são determinísticos (REPEATABLE seed)
```

**Impacto em produção:**
- **CPU:** Baixo (queries já usam NOLOCK, não bloqueiam)
- **I/O:** Moderado (leituras distribuídas ao longo de 10-15 min)
- **Locks:** Mínimo (NOLOCK + TABLESAMPLE não adquire locks)
- **Conexões:** 1 de 32k disponíveis (desprezível)
- **Tempdb:** 9-11 GB de 107 GB (10% - ACEITÁVEL)

### Opção B: Heredoc/Inline

**Idêntica à Opção A em performance**, mas:
```
❌ Logs menos claros (tudo inline, difícil debugar)
❌ Modificação difícil (precisa editar extract-data.sh)
❌ Sem modularidade (não pode executar tier individual)
```

### Opção C: Local Temp Tables

**NÃO VIÁVEL TECNICAMENTE:**
```
❌ Local temp (#) não sobrevivem entre GO batches
❌ Requer REFATORAÇÃO COMPLETA de 65 tabelas
❌ Perda de modularidade (não pode reexecutar tier individual)
❌ 5 sessões = 5× overhead de conexão
❌ Fragmentação de locks no tempdb
```

## RECOMENDAÇÃO FINAL

**Opção A: Concatenar Scripts**

### Justificativa:
1. **Menor impacto em produção:** 1 sessão vs 5 sessões
2. **NOLOCK efetivo:** Não bloqueia queries de produção
3. **Tempdb gerenciável:** 10% de uso (dentro da margem)
4. **Determinístico:** REPEATABLE(42) garante reprodutibilidade
5. **Rollback seguro:** Scripts idempotentes (IF EXISTS checks)

### Mitigações de risco:
```sql
-- Adicionar ao script concatenado:
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  -- Força NOLOCK global
SET LOCK_TIMEOUT 5000;  -- Abort se bloquear >5s
```

### Execução segura:
```bash
# Horário recomendado: Fora de pico (noite/madrugada)
# Duração estimada: 10-15 minutos
# Janela de manutenção: 1 hora (com margem)
```

## Estatísticas de Impacto

### Tier-0 (Executado com sucesso):
- Duração: 543s (9 min)
- Rows extraídas: 111M rows
- Tempdb usado: ~3.7 GB (de 107 GB)
- Sem bloqueios reportados ✅

### Projeção Tiers 1-4:
- Duração estimada: 5-7 min adicional
- Tempdb adicional: ~2-3 GB
- TOTAL: 14-16 min, 12-14 GB tempdb

**Conclusão:** Opção A é SEGURA para produção no horário apropriado.
