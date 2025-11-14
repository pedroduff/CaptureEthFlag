# Contrato escolhido: https://capturetheether.com/challenges/lotteries/predict-the-future/

# Resumo final
O contrato tem várias vulnerabilidades porque:
* Usa “random” que não é realmente aleatório
* Depende do saldo para verificar conclusão
* Usa transfer() (que pode travar o pagamento)
* Não tem timeout e pode travar
* É de uma versão muito antiga do Solidity

## E por causa dessas falhas, é possível:
* Prever o número
* Chamar a função no bloco certo
* Ganhar os 2 ETH de forma garantida

# Auditoria de forma detalhada

## 1. Randomness previsível
### Problema
O contrato tenta criar um número "aleatório", mas usa: 
* block.blockhash(blocknumber - 1)
* now - timestamp
Esses valores são conhecidos no momento da execução.
### Motivo
Esses dados não são realmente aleatórios:
* blockhash do bloco anterior é público.
* now (timestamp) pode ser ligeiramente ajustado pelo minerador.
* O atacante pode calcular o mesmo resultado dentro do próprio ataque.
### Risco/impacto
O atacante consegue:
* Rodar um contrato que testa o “random” antes de chamar settle()
* Só chamar settle() quando ele sabe que vai ganhar
* Testar até ganhar sem nunca perder dinheiro

## 2. isComplete() depende do saldo do contrato
### Problema
O contrato considera completo quando: return address(this).balance == 0;
### Motivo
O saldo do contrato pode ser alterado sem chamar funções do desafio, por exemplo: selfdestruct(target);
Isso envia ETH direto para o contrato.
### Risco/impacto
* Alguém pode forçar o contrato a ter saldo ≠ 0
* Isso trava o desafio para sempre
* isComplete() vira inútil


## 3. Uso de transfer() pode causar DoS
### Problema
O contrato paga usando: msg.sender.transfer(2 ether);
### Motivo
transfer() envia só 2300 gas, e isso pode não ser suficiente se:
* o ganhador for um contrato
* a EVM mudar preços de opcodes
Pode fazer o pagamento falhar.
### Risco/impacto
* O vencedor pode não conseguir receber
* O jogo trava
* Ataque de DoS por “fallback caro”


## 4. O contrato pode travar se o guesser nunca chamar settle()
### Problema
Uma vez que alguém chama: lockInGuess(n)
O contrato salva: guesser = msg.sender;
Mas se essa pessoa nunca chamar settle(), ninguém mais pode jogar.
### Motivo
O contrato não tem nenhum método para resetar o jogo ou para tratar “abandono”.
### Risco/impacto
O contrato pode ficar travado para sempre.

## 5.Uso de Solidity 0.4.21 - versão muito antiga
### Problema
O contrato usa: pragma solidity ^0.4.21;
E um construtor com nome da função, que é um padrão ultrapassado.
### Motivo
Solidity moderno usa: constructor() {}
E versões antigas:
* Não têm safe math embutido
* Tem mais vulnerabilidades comuns
* Tem warnings no Remix
### Risco/impacto
* Bugs (como overflow/underflow)
* Confusão no deploy
* Ferramentas modernas não funcionam perfeitamente


# O arquivo AttackPredictFuture.sol é uma tentativa de quebra do contrato
