# frozen_string_literal: true

require 'stringio'
require 'date'

# Redireciona stdin para que o require não trave no gets do programa principal
_stdin_orig  = $stdin
_stdout_orig = $stdout
$stdin  = StringIO.new("dummy\n")
$stdout = StringIO.new
require_relative 'main'
$stdin  = _stdin_orig
$stdout = _stdout_orig

# Datas relativas calculadas a partir de hoje para os testes funcionarem
# em qualquer dia em que forem executados.
HOJE             = Date.today
AMANHA           = (HOJE + 1).strftime('%d/%m/%Y')
DEPOIS_DE_AMANHA = (HOJE + 2).strftime('%d/%m/%Y')
ANO_ATUAL        = HOJE.year

CASOS = [
  {
    descricao: 'Exemplo do enunciado (ação, pessoa, horário mm:ss, data relativa, tag)',
    entrada: 'Agendar com José reunião às 10:00 amanhã #trabalho',
    esperado: {
      datas: [AMANHA],
      horarios: ['10:00'],
      pessoas: ['José'],
      acoes: %w[agendar reunião],
      tags: ['#trabalho'],
      urls: [],
      emails: []
    }
  },
  {
    descricao: 'Múltiplas pessoas e data numérica com ano',
    entrada: 'Marcar com Pedro e João às 10 30 no dia 13 de agosto de 2021 #faculdade',
    esperado: {
      datas: ['13/08/2021'],
      horarios: ['10:30'],
      pessoas: %w[Pedro João],
      acoes: ['marcar'],
      tags: ['#faculdade'],
      urls: [],
      emails: []
    }
  },
  {
    descricao: 'Email com hífen, data numérica DD/MM/AAAA, horário por extenso',
    entrada: 'Enviar para Maria 20/04/2022 às 10 horas jose.da-silva@sp.senac.br',
    esperado: {
      datas: ['20/04/2022'],
      horarios: ['10:00'],
      pessoas: ['Maria'],
      acoes: ['enviar'],
      tags: [],
      urls: [],
      emails: ['jose.da-silva@sp.senac.br']
    }
  },
  {
    descricao: "URL com âncora '#' não deve gerar tag; tag real deve ser reconhecida",
    entrada: 'Revisar site https://sp.senac.br/pag1#teste?aula=1&teste=4 depois de amanhã #trabalho',
    esperado: {
      datas: [DEPOIS_DE_AMANHA],
      horarios: [],
      pessoas: [],
      acoes: ['revisar'],
      tags: ['#trabalho'],
      urls: ['https://sp.senac.br/pag1#teste?aula=1&teste=4'],
      emails: []
    }
  },
  {
    descricao: "Data por extenso sem 'de' (variação do spec), nome composto, horário '1 hora'",
    entrada: "Ligar para Ana Clara 18 agosto 1 hora #casa",
    esperado: {
      datas: ["18/08/#{ANO_ATUAL}"],
      horarios: ['01:00'],
      pessoas: ['Ana Clara'],
      acoes: ['ligar'],
      tags: ['#casa'],
      urls: [],
      emails: []
    }
  }
].freeze

NOMES_CAMPOS = {
  datas: 'Dia',
  horarios: 'Horário',
  pessoas: 'Pessoa',
  acoes: 'Ação',
  tags: 'Tag',
  urls: 'URL',
  emails: 'Email'
}.freeze

total     = CASOS.size
aprovados = 0
r         = ReconhecedorAfazeres.new

puts "Executando #{total} exemplos (data de hoje: #{HOJE.strftime('%d/%m/%Y')})"
puts '=' * 60
puts

CASOS.each_with_index do |caso, indice|
  resultado = r.extrair(caso[:entrada])
  esperado  = caso[:esperado]

  falhas = []
  NOMES_CAMPOS.each_key do |campo|
    obtido = resultado[campo] || []
    espera = esperado[campo]  || []
    falhas << [campo, espera, obtido] unless obtido == espera
  end

  if falhas.empty?
    aprovados += 1
    puts "Exemplo #{indice + 1}: OK  — #{caso[:descricao]}"
  else
    puts "Exemplo #{indice + 1}: FALHOU  — #{caso[:descricao]}"
    falhas.each do |campo, espera, obtido|
      puts "  [#{NOMES_CAMPOS[campo]}] esperado: #{espera.inspect}"
      puts "  [#{NOMES_CAMPOS[campo]}] obtido  : #{obtido.inspect}"
    end
  end
  puts "  Entrada: #{caso[:entrada]}"
  puts
end

puts '=' * 60
puts "Resultado: #{aprovados}/#{total} exemplos OK"
exit(aprovados == total ? 0 : 1)