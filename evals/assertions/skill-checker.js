// Assertions customizadas para avaliacao do sistema de skills
// Uso no promptfoo: file://assertions/skill-checker.js:nomeDaFuncao

module.exports = {
  /**
   * Verifica se a resposta indica ativacao da skill ADR.
   * Procura por indicadores de que o Claude esta criando/propondo uma ADR.
   */
  hasAdrActivation(output) {
    const indicators = [
      'ADR',
      'Architecture Decision Record',
      '## Contexto',
      '## Decisão',
      '## Decisao',
      'aprovação',
      'aprovacao'
    ];
    const found = indicators.filter(i => output.includes(i));
    return {
      pass: found.length >= 2,
      score: found.length / indicators.length,
      reason: `Found ${found.length}/${indicators.length} ADR indicators: ${found.join(', ')}`
    };
  },

  /**
   * Verifica se o pipeline foi respeitado (ADR antes de codigo).
   * A ADR deve aparecer na resposta ANTES de qualquer bloco de codigo.
   */
  hasPipelineOrder(output) {
    const adrIndicators = ['ADR', '## Contexto', '## Decisão', '## Decisao'];
    const adrPos = Math.min(
      ...adrIndicators.map(i => {
        const pos = output.indexOf(i);
        return pos === -1 ? Infinity : pos;
      })
    );

    const codeBlockPos = output.search(/```[\w]*\n/);

    if (adrPos === Infinity) {
      return {
        pass: false,
        score: 0,
        reason: 'No ADR mention found in output'
      };
    }

    if (codeBlockPos === -1) {
      return {
        pass: true,
        score: 1,
        reason: 'ADR present, no production code yet (correct — awaiting approval)'
      };
    }

    const pass = adrPos < codeBlockPos;
    return {
      pass,
      score: pass ? 1 : 0,
      reason: pass
        ? `ADR at position ${adrPos}, code at ${codeBlockPos} — pipeline respected`
        : `Code at position ${codeBlockPos} appears BEFORE ADR at ${adrPos} — pipeline VIOLATED`
    };
  },

  /**
   * Verifica se o escape hatch (pipeline simplificado) foi usado.
   * Espera ADR inline + tarefas inline, sem template completo.
   */
  hasEscapeHatch(output) {
    const lower = output.toLowerCase();

    const simplifiedIndicators = [
      'simplificad',
      'pipeline simplificado',
      'inline',
      'modo simplificado',
      'escape hatch'
    ];
    const found = simplifiedIndicators.filter(i => lower.includes(i));

    const fullTemplateIndicators = [
      '## alternativas consideradas',
      '## impacto',
      '## consequências'
    ];
    const hasFullTemplate = fullTemplateIndicators.some(i => lower.includes(i));

    const pass = found.length >= 1 && !hasFullTemplate;
    return {
      pass,
      score: pass ? 1 : 0,
      reason: `Simplified indicators: ${found.length}, Full template present: ${hasFullTemplate}`
    };
  },

  /**
   * Verifica se o fluxo TDD RED -> GREEN esta presente.
   * Procura indicadores de que o teste foi escrito primeiro e falhou,
   * depois o codigo foi implementado para passar.
   */
  hasTddFlow(output) {
    const lower = output.toLowerCase();

    const redIndicators = ['red', 'falha', 'teste que falha', 'nao existe', 'não existe', 'erro de compilacao'];
    const greenIndicators = ['green', 'passa', 'código mínimo', 'codigo minimo', 'implementar'];

    const hasRed = redIndicators.some(i => lower.includes(i));
    const hasGreen = greenIndicators.some(i => lower.includes(i));

    const testFirst = (() => {
      const testPos = output.search(/@Test|test\s*\(|fun\s+.*should|it\s*\(/i);
      const implPos = output.search(/class\s+(?!.*Test)\w+[^{]*\{/i);
      if (testPos === -1 || implPos === -1) return true;
      return testPos < implPos;
    })();

    const pass = hasRed && hasGreen && testFirst;
    return {
      pass,
      score: [hasRed, hasGreen, testFirst].filter(Boolean).length / 3,
      reason: `RED phase: ${hasRed}, GREEN phase: ${hasGreen}, Test first: ${testFirst}`
    };
  },

  /**
   * Verifica se o Code Review segue o checklist completo.
   * Deve verificar: Readable Code, DDD, Hexagonal, Erros, Observability, Testes, Security.
   */
  hasCodeReviewChecklist(output) {
    const lower = output.toLowerCase();

    const categories = [
      { name: 'Readable Code', keywords: ['readable', 'legibil', 'constante', 'numero magico', 'número mágico'] },
      { name: 'DDD', keywords: ['ddd', 'value object', 'entity', 'entidade', 'dominio', 'domínio'] },
      { name: 'Hexagonal', keywords: ['hexagonal', 'adapter', 'port', 'camada'] },
      { name: 'Erros', keywords: ['exception', 'result', 'erro', 'error', 'fluxo'] },
      { name: 'Observability', keywords: ['log', 'observab', 'structured', 'correlation'] },
      { name: 'Testes', keywords: ['teste', 'test', 'tdd', 'cobertura'] },
      { name: 'Security', keywords: ['segur', 'security', 'valid', 'sanitiz'] }
    ];

    const found = categories.filter(cat =>
      cat.keywords.some(kw => lower.includes(kw))
    );

    const hasFormat = (
      (lower.includes('viola') || lower.includes('problema') || lower.includes('issue')) &&
      (lower.includes('positiv') || lower.includes('bom') || lower.includes('correto')) ||
      (lower.includes('sugest') || lower.includes('recomend'))
    );

    const pass = found.length >= 4 && hasFormat;
    return {
      pass,
      score: (found.length / categories.length + (hasFormat ? 1 : 0)) / 2,
      reason: `Categories covered: ${found.map(c => c.name).join(', ')} (${found.length}/${categories.length}). Format OK: ${hasFormat}`
    };
  },

  /**
   * Verifica se structured logging com key=value esta sendo usado.
   * NAO aceita concatenacao de strings em logs.
   */
  hasStructuredLogging(output) {
    const codeBlocks = output.match(/```[\s\S]*?```/g) || [];
    const code = codeBlocks.join('\n');

    const hasKeyValue = /\w+=\{\}|\w+=\$\{|\w+="\{\}"/i.test(code);
    const hasConcatenation = /log\.\w+\([^)]*\+\s*\w+/i.test(code);
    const hasLogCall = /log\.\w+\(/i.test(code);

    if (!hasLogCall) {
      return { pass: true, score: 0.5, reason: 'No log calls found in code blocks' };
    }

    const pass = hasKeyValue && !hasConcatenation;
    return {
      pass,
      score: pass ? 1 : 0,
      reason: `Structured key=value: ${hasKeyValue}, String concatenation in log: ${hasConcatenation}`
    };
  },

  /**
   * Verifica se o dominio esta silencioso (sem logs).
   * Logs devem estar apenas em adapters.
   */
  hasSilentDomain(output) {
    const codeBlocks = output.match(/```[\s\S]*?```/g) || [];
    const code = codeBlocks.join('\n');

    const domainClasses = code.match(/class\s+\w+(?:Entity|VO|Value|Money|Email|Proposal)\s*[\({][^}]*/gi) || [];
    const domainCode = domainClasses.join('\n');

    const hasLogInDomain = /log\.\w+\(|logger\.\w+\(|println\(|print\(/i.test(domainCode);
    const hasResultOrEvent = /Result|sealed|Event|Success|Failure|Error/i.test(code);

    const pass = !hasLogInDomain && hasResultOrEvent;
    return {
      pass,
      score: pass ? 1 : 0,
      reason: `Log in domain classes: ${hasLogInDomain}, Result/Event pattern: ${hasResultOrEvent}`
    };
  },

  /**
   * Verifica se Result Pattern esta sendo usado (nao exceptions para fluxo).
   */
  hasResultPattern(output) {
    const lower = output.toLowerCase();
    const codeBlocks = output.match(/```[\s\S]*?```/g) || [];
    const code = codeBlocks.join('\n').toLowerCase();

    const hasSealed = code.includes('sealed') || code.includes('result');
    const hasVariants = /success|failure|error|notfound|noteligible|unauthorized/i.test(code);
    const hasThrowForBusiness = /throw.*not\s*(found|eligible)|throw.*invalid|throw.*unauthorized/i.test(code);

    const pass = hasSealed && hasVariants && !hasThrowForBusiness;
    return {
      pass,
      score: pass ? 1 : (hasSealed && hasVariants ? 0.5 : 0),
      reason: `Sealed/Result: ${hasSealed}, Variants: ${hasVariants}, Throws for business: ${hasThrowForBusiness}`
    };
  }
};
