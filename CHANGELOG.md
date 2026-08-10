# Changelog

## 1.2.14
- Vers?o est?vel promovida ap?s a valida??o da beta.14.
- Inclui todas as op??es de QoL, corre??es, Bag com abas, Quick HM, Itemfinder, Move Info, Fast Save e confirma??es de reset testadas.
- O conte?do funcional ? o mesmo aprovado em 2.0.0-beta.14.

## 2.0.0-beta.14
- RESET ALL foi renomeado para RESET DEFAULT ALL.
- Reset geral e resets de Battle, Pokemon e Misc agora pedem confirma??o com NO selecionado por padr?o.
- EXP Share ON foi renomeado para GEN1; o ciclo agora aparece como OFF / GEN1 / SMART.
- O valor interno ACTIVE foi mantido para compatibilidade com saves existentes.

## 2.0.0-beta.13
- Corrigido o texto invis?vel da aba ativa da Bag: fundo preto com letras brancas.
- O restante da Bag mant?m o tema e a lista originais.
- AUTO SORT agora mostra uma seta vazada na op??o atualmente salva.
- O cursor preenchido continua indicando a op??o em navega??o.

## 2.0.0-beta.12
- Unlimited TM foi renomeado para Reusable TMs, mantendo o funcionamento.
- Adicionado Quick HM OFF / ON / IGNORE no menu Pokemon Options e QUICK HM no menu START.
- ON exige possuir o HM e a ins?gnia, mas n?o exige ensinar o golpe; IGNORE ignora ambos os requisitos.
- Bag ampliada para 999 slots e dividida nas abas ITEMS, KEY, BALL e TM/HM.
- Esquerda/Direita alterna as abas; START abre a escolha de AUTO SORT OFF / NAME / QUANTITY / TYPE.
- TYPE usa a ordem funcional aprovada, incluindo EXP.ALL em KEY, Balls por for?a e HM01-HM05 antes de TM01-TM50.
- Adicionado Move Info ON/OFF em Battle Options, com Type, Power e Accuracy nos layouts Classic e Wide.
- Adicionado Fast Save ON/OFF em MISC; ON salva sem caixas de texto e toca apenas o som de confirma??o.
- Mantidas as corre??es e o Itemfinder animado da beta.11.

## 2.0.0-beta.11
- Criado o submenu MISC com Fast Run, Auto Run, Instant Text, Itemfinder e Fast Center.
- A tela principal agora mostra MISC imediatamente acima de RESET ALL.
- Adicionado Itemfinder OFF / ON / HAVE ITEM.
- ON funciona mesmo sem possuir o Itemfinder; HAVE ITEM exige o item na mochila.
- Itens ocultos ainda nao coletados, dentro do alcance nativo do Itemfinder, recebem um quadrado de alto contraste que encolhe em direcao ao centro do tile.
- O marcador e removido ao coletar o item ou sair do alcance.

## 2.0.0-beta.10
- EXP SHARE ACTIVE agora aparece como ON no menu, mantendo compatibilidade com saves existentes.
- Adicionado aviso em ingles com o total de EXP compartilhada: "1 POKeMON gained" ou "N POKeMON shared".
- O aviso usa o total realmente distribuido e funciona nos modos ON e SMART.
- Fast Center agora usa o jingle nativo Music_PkmnHealed como confirmacao da cura.
- Mantidas as correcoes de Fast Run, Auto Run, cutscenes e equipe com apenas um Pokemon.

## 2.0.0-beta.9
- Corrigido Fast Center nas builds atuais do Gen1Recomp.
- A cura agora intercepta diretamente OverworldController:nurseHeal.
- Com Fast Center ligado, a equipe e curada imediatamente, o ponto de retorno e atualizado e a conversa/animacao longa e ignorada.
- Mantidas as correcoes de EXP Share e corrida das betas anteriores.

## 2.0.0-beta.8
- Corrigido EXP Share com apenas um Pokemon elegivel na equipe.
- Sem outros destinatarios, o Pokemon ativo recebe a EXP nativa completa em vez de perder metade.
- Mantida a correcao de velocidade de cutscenes da beta.7.

## 2.0.0-beta.7
- Corrigida a velocidade residual do Fast Run em movimentos de cutscene.
- Passos iniciados por script agora restauram explicitamente a duracao normal do jogador, sem herdar a velocidade do ultimo passo manual.
- O comportamento do Fast Run durante o controle normal nao foi alterado.

## 2.0.0-beta.6
- Corrigido Fast Run ao segurar B durante cutscenes.
- Corrigido Auto Run acelerando movimentos de cutscene/script.
- Fast Run e Auto Run agora compartilham a mesma valida??o: s? aceleram passos iniciados diretamente pelo input manual do jogador.
- Nenhuma outra l?gica de gameplay foi alterada nesta corre??o.

## 2.0.0-beta.3
- Todas as fun??es agora usam OFF como padr?o em instala??o nova e nos resets.
- Move Editor padr?o alterado para OFF.
- Infinite PP padr?o alterado para OFF.
- Fast Run refor?ado para aceitar somente passos originados do controle manual do overworld; movimentos de scripts/cutscenes s?o rejeitados mesmo se uma dire??o continuar segurada.
- Move Info ganhou resolu??o mais robusta de tipos da Gen 1 e layout compacto para evitar que tipos longos, como ELECTRIC, sejam cortados.
- ThunderPunch e demais golpes agora exibem Type, PP, Power e Accuracy no rodap?.

## 2.0.0-beta.2
- Corrige Fast Run/Auto Run afetando movimentos de cutscene e scripts.
- Fast Run agora exige dire??o sendo segurada por uma fonte real de input do jogador (teclado, controle, anal?gico ou touch).
- Movimentos for?ados de eventos permanecem na velocidade original, evitando dessincroniza??o/travamento de scripts como a sequ?ncia inicial do Professor Carvalho.

# Changelog

## 2.0.0-beta.1
- Adicionado menu MOD OPTIONS no START.
- Configura??es persistentes via mod save.
- Fast Run OFF/ON/ON+SURF e Auto Run dependente do Fast Run.
- Instant Text.
- Fast Pok?mon Center Heal.
- Never Miss, Always Critical, Infinite PP e Always Catch.
- EXP Share OFF/ACTIVE/SMART com level-up nativo e mensagens indiretas de EXP suprimidas.
- Smart EXP prioriza menores n?veis e divide igualmente quando equalizados.
- Move Editor TODOS/BASE/OFF.
- Move info: Type, PP, Power e Accuracy.
- BASE limitado a dados Gen 1, TMs + level-up, sem HMs.
- Forget HM, Unlimited TM e evolu??o de Pikachu por Thunder Stone.
- Reset Defaults por categoria e Reset All geral.
- Mantidas as corre??es de estabilidade/navega??o do Move Editor v1.1.0.
