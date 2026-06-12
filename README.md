# Reconhecedor de Lista de Afazeres

Este projeto implementa um reconhecedor de padrões textuais para um sistema de lista de afazeres. A aplicação recebe uma frase digitada pelo usuário e identifica, por meio de expressões regulares em Ruby, elementos como datas, horários, pessoas, ações, tags, URLs e emails.

## Problema resolvido

Em sistemas de tarefas, é comum o usuário escrever frases em linguagem natural, como:

```txt
Agendar com José reunião às 10:00 amanhã #trabalho
```

O objetivo do sistema é transformar esse texto livre em informações estruturadas:

```txt
Dia: 12/06/2026
Horário: 10:00
Pessoa: José
Ação: agendar
Ação: reunião
Tag: #trabalho
```

A data exibida para termos relativos, como `hoje`, `amanhã` e `depois de amanhã`, depende da data atual do computador no momento da execução.

## Teoria envolvida

O projeto se baseia em **expressões regulares**, que são utilizadas para descrever padrões pertencentes à classe das **linguagens regulares**. Na teoria de Linguagens Formais, toda expressão regular possui um autômato finito equivalente capaz de reconhecer a mesma linguagem.

Neste trabalho, cada categoria de informação foi modelada como uma linguagem regular independente. Por exemplo, horários, tags, emails, URLs, datas relativas e ações podem ser descritos por padrões bem definidos e reconhecidos por expressões regulares.

Alguns exemplos de linguagens regulares tratadas no projeto são:

* a linguagem dos horários, como `10:30`, `10 30`, `10 horas`, `1 hora` e `às 10`;
* a linguagem das tags, formada por palavras iniciadas com `#`, como `#casa` e `#trabalho`;
* a linguagem dos emails, formada por textos com usuário, arroba, domínio e extensão;
* a linguagem das URLs iniciadas por `http://` ou `https://`;
* a linguagem das ações, formada por uma lista finita de verbos escolhidos, como `agendar`, `marcar`, `ligar`, `comprar`, `pagar`, `enviar`, entre outros;
* a linguagem das datas relativas, como `hoje`, `amanhã` e `depois de amanhã`.

O uso de expressões regulares torna a solução declarativa: em vez de procurar manualmente partes da string com combinações de substrings, o programa define padrões formais e aplica esses padrões sobre a entrada digitada pelo usuário.

Foram definidos padrões para reconhecer:

* horários, como `10:30`, `10 30`, `10 horas`, `1 hora` e `às 10`;
* datas, como `28 de Fevereiro`, `13 de agosto de 2021`, `30/01`, `20/04/2022`, `hoje`, `amanhã` e `depois de amanhã`;
* variações de datas, como `18 agosto` e `18 de agosto 2023`;
* tags, como `#casa`, `#trabalho`, `#faculdade`, entre outras;
* URLs, como `https://sp.senac.br/pag1#teste?aula=1&teste=4`;
* emails, como `jose.da-silva@sp.senac.br`;
* ações escolhidas no projeto, como `agendar`, `marcar`, `ligar`, `comprar`, `pagar`, `enviar`, entre outras;
* pessoas identificadas por conectores como `com`, `para`, `pra`, `ao` e `à`.

A modelagem detalhada de cada expressão regular, com os critérios adotados e os casos cobertos, está documentada em [`docs/modelagem.md`](docs/modelagem.md).

## Estrutura do projeto

```txt
EP04-LFA/
├── main.rb
├── README.md
└── docs/
    └── modelagem.md
```

## Como executar

É necessário ter o Ruby instalado. Recomenda-se a versão 3.0 ou superior.

No terminal, dentro da pasta do projeto, execute:

```bash
ruby main.rb
```

Digite uma tarefa quando o programa solicitar a entrada.

Exemplo de entrada:

```txt
Agendar com José reunião às 10:00 amanhã #trabalho
```

Saída esperada:

```txt
Elementos reconhecidos:
------------------------------
Dia: 12/06/2026
Horário: 10:00
Pessoa: José
Ação: agendar, reunião
Tag: #trabalho
URL: não encontrado
Email: não encontrado
```

## Exemplos de teste

### Exemplo 1

Entrada:

```txt
Agendar com José reunião às 10:00 amanhã #trabalho
```

Saída esperada:

```txt
Dia: 12/06/2026
Horário: 10:00
Pessoa: José
Ação: agendar, reunião
Tag: #trabalho
URL: não encontrado
Email: não encontrado
```

### Exemplo 2

Entrada:

```txt
Marcar com Pedro e João às 10 30 no dia 13 de agosto de 2021 #faculdade
```

Saída esperada:

```txt
Dia: 13/08/2021
Horário: 10:30
Pessoa: Pedro, João
Ação: marcar
Tag: #faculdade
URL: não encontrado
Email: não encontrado
```

### Exemplo 3

Entrada:

```txt
Enviar email para Maria 20/04/2022 às 10 horas jose.da-silva@sp.senac.br
```

Saída esperada:

```txt
Dia: 20/04/2022
Horário: 10:00
Pessoa: Maria
Ação: enviar
Tag: não encontrado
URL: não encontrado
Email: jose.da-silva@sp.senac.br
```

### Exemplo 4

Entrada:

```txt
Revisar site https://sp.senac.br/pag1#teste?aula=1&teste=4 depois de amanhã #trabalho
```

Saída esperada:

```txt
Dia: 13/06/2026
Horário: não encontrado
Pessoa: não encontrado
Ação: revisar
Tag: #trabalho
URL: https://sp.senac.br/pag1#teste?aula=1&teste=4
Email: não encontrado
```

### Exemplo 5

Entrada:

```txt
Ligar para Ana Clara 18 agosto 1 hora #casa
```

Saída esperada:

```txt
Dia: 18/08/2026
Horário: 01:00
Pessoa: Ana Clara
Ação: ligar
Tag: #casa
URL: não encontrado
Email: não encontrado
```

## Explicação básica do código

A classe `ReconhecedorAfazeres` concentra as expressões regulares e os métodos de extração. Cada método é responsável por uma categoria de informação e devolve apenas valores válidos e sem repetição.

Principais métodos:

* `extrair`: executa todos os reconhecedores e retorna um hash com os resultados;
* `extrair_datas`: reconhece datas numéricas (`30/01`), textuais (`13 de agosto de 2021`) e relativas (`hoje`, `amanhã`, `depois de amanhã`), convertendo todas para o formato `dd/mm/aaaa`;
* `extrair_horarios`: reconhece horários com dois-pontos, com espaço, por extenso (`10 horas`) e na forma `às 10`;
* `formatar_horario`: valida se a hora está entre `0` e `23` e se os minutos estão entre `0` e `59`, retornando o horário no formato `HH:MM`;
* `extrair_pessoas`: reconhece pessoas a partir dos conectores definidos, exigindo nomes próprios iniciados por letra maiúscula;
* `extrair_acoes`: reconhece os verbos e ações escolhidos no projeto;
* `extrair_tags`: reconhece tags iniciadas por `#`, ignorando o caractere `#` que aparece dentro de URLs;
* `extrair_urls`: reconhece links iniciados por `http://` ou `https://`;
* `extrair_emails`: reconhece endereços de email.

O programa lê a entrada pelo teclado com `gets`, aplica as expressões regulares e exibe os elementos encontrados de forma estruturada.

## Validações realizadas

Além de reconhecer os padrões com expressões regulares, o programa realiza algumas validações simples após a captura:

* horários só são aceitos se estiverem entre `00:00` e `23:59`;
* datas inválidas, como `31/02`, são ignoradas;
* URLs são removidas antes da busca por tags e emails, evitando falsos positivos em trechos como `#teste` dentro de links;
* resultados repetidos são removidos antes da exibição.

A biblioteca padrão `Date` é utilizada apenas para validar, representar e formatar datas, além de calcular datas relativas como `hoje`, `amanhã` e `depois de amanhã`.

## Limitações conhecidas

O reconhecedor foi construído para padrões comuns em listas de afazeres, mas não tenta interpretar linguagem natural de forma completa.

Algumas limitações conhecidas são:

* não reconhece datas vagas, como `semana que vem`, `mês que vem` ou `daqui a dois dias`;
* não reconhece nomes próprios escritos totalmente em minúsculo;
* não reconhece horários escritos por extenso, como `dez e meia`;
* não interpreta contexto semântico completo da frase;
* não diferencia se uma palavra reconhecida como ação está sendo usada em outro sentido.

Essas limitações existem porque o objetivo do projeto é usar expressões regulares para reconhecer padrões formais, e não implementar um interpretador completo de linguagem natural.
