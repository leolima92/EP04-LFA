require 'date'

class ReconhecedorAfazeres
  MESES = {
    'janeiro' => 1,
    'fevereiro' => 2,
    'marco' => 3,
    'março' => 3,
    'abril' => 4,
    'maio' => 5,
    'junho' => 6,
    'julho' => 7,
    'agosto' => 8,
    'setembro' => 9,
    'outubro' => 10,
    'novembro' => 11,
    'dezembro' => 12
  }.freeze

  ACOES = %w[
    agendar marcar ligar comprar pagar enviar estudar revisar entregar fazer buscar levar
    reuniao reunião cancelar confirmar reservar anotar lembrar responder
  ].freeze

  REGEX_EMAIL = /\b[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}\b/.freeze

  REGEX_URL = %r{https?://[^\s]+}i.freeze

  REGEX_TAG = /(?<![^\s])#[\p{L}\p{N}_-]+/u.freeze

  REGEX_HORA_COM_MINUTO = /\b(?:às|as)?\s*(\d{1,2})(?::|\s+)(\d{2})\b/i.freeze

  REGEX_HORA_POR_EXTENSO = /\b(\d{1,2})\s*(?:h|hora|horas)\b/i.freeze

  REGEX_AS_HORA = /\b(?:às|as)\s*(\d{1,2})\b(?!\s*(?::|\d))/i.freeze

  REGEX_DATA_NUMERICA = %r{\b(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?\b}.freeze

  REGEX_DATA_RELATIVA = /(?<![\p{L}])(hoje|amanh[ãa]|depois de amanh[ãa])(?![\p{L}])/iu.freeze

  REGEX_DATA_TEXTUAL = /\b(\d{1,2})\s*(?:de\s+)?(janeiro|fevereiro|mar[çc]o|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro)\s*(?:de\s+)?(\d{4})?\b/i.freeze

  REGEX_ACAO = /\b(#{ACOES.join('|')})\b/i.freeze

  REGEX_NOME = /[A-ZÁÉÍÓÚÂÊÔÃÕÇ][\p{L}]+(?:\s+(?:de|da|do|dos|das)\s+[A-ZÁÉÍÓÚÂÊÔÃÕÇ][\p{L}]+|\s+[A-ZÁÉÍÓÚÂÊÔÃÕÇ][\p{L}]+)*/u.freeze

  REGEX_PESSOA = /(?i:\b(?:com|para|pra|ao|à))\s+(#{REGEX_NOME}(?:\s+e\s+#{REGEX_NOME})*)/u.freeze

  def extrair(texto)
    {
      datas: extrair_datas(texto),
      horarios: extrair_horarios(texto),
      pessoas: extrair_pessoas(texto),
      acoes: extrair_acoes(texto),
      tags: extrair_tags(texto),
      urls: extrair_urls(texto),
      emails: extrair_emails(texto)
    }
  end

  def extrair_datas(texto)
    hoje = Date.today
    datas = []

    texto.scan(REGEX_DATA_RELATIVA) do |match|
      termo = match[0].downcase
      data = if termo =~ /depois de amanh/
               hoje + 2
             elsif termo =~ /amanh/
               hoje + 1
             else
               hoje
             end
      datas << data.strftime('%d/%m/%Y')
    end

    texto.scan(REGEX_DATA_NUMERICA) do |d, m, y|
      year = if y
               y.length == 2 ? 2000 + y.to_i : y.to_i
             else
               hoje.year
             end
      begin
        data = Date.new(year, m.to_i, d.to_i)
        datas << data.strftime('%d/%m/%Y')
      rescue ArgumentError
        # data inválida, ignora
      end
    end

    texto.scan(REGEX_DATA_TEXTUAL) do |d, mes_nome, y|
      mes = MESES[mes_nome.downcase]
      next unless mes

      year = y ? y.to_i : hoje.year
      begin
        data = Date.new(year, mes, d.to_i)
        datas << data.strftime('%d/%m/%Y')
      rescue ArgumentError
        # data inválida, ignora
      end
    end

    datas.uniq
  end

  def extrair_horarios(texto)
    texto_limpo = texto.gsub(REGEX_URL, '')
    horarios = []

    texto_limpo.scan(REGEX_HORA_COM_MINUTO) do |h, m|
      horarios << format('%02d:%02d', h.to_i, m.to_i)
    end

    texto_limpo.scan(REGEX_AS_HORA) do |match|
      hora_str = format('%02d:00', match[0].to_i)
      horarios << hora_str unless horarios.include?(hora_str)
    end

    texto_limpo.scan(REGEX_HORA_POR_EXTENSO) do |match|
      hora_str = format('%02d:00', match[0].to_i)
      horarios << hora_str unless horarios.include?(hora_str)
    end

    horarios.uniq
  end

  def extrair_pessoas(texto)
    pessoas = []
    texto.scan(REGEX_PESSOA) do |match|
      match[0].split(/\s+e\s+/i).each { |n| pessoas << n.strip }
    end
    pessoas.uniq
  end

  def extrair_acoes(texto)
    texto.scan(REGEX_ACAO).map { |m| m[0].downcase }.uniq
  end

  def extrair_tags(texto)
    texto_limpo = texto.gsub(REGEX_URL, '')
    texto_limpo.scan(REGEX_TAG).uniq
  end

  def extrair_urls(texto)
    texto.scan(REGEX_URL).uniq
  end

  def extrair_emails(texto)
    texto_limpo = texto.gsub(REGEX_URL, '')
    texto_limpo.scan(REGEX_EMAIL).uniq
  end
end

print 'Digite uma tarefa: '
entrada = gets.chomp

reconhecedor = ReconhecedorAfazeres.new
resultado = reconhecedor.extrair(entrada)

nao_encontrado = 'não encontrado'

puts "\nElementos reconhecidos:"
puts '-' * 30
puts "Dia: #{resultado[:datas].empty? ? nao_encontrado : resultado[:datas].join(', ')}"
puts "Horário: #{resultado[:horarios].empty? ? nao_encontrado : resultado[:horarios].join(', ')}"
puts "Pessoa: #{resultado[:pessoas].empty? ? nao_encontrado : resultado[:pessoas].join(', ')}"
puts "Ação: #{resultado[:acoes].empty? ? nao_encontrado : resultado[:acoes].join(', ')}"
puts "Tag: #{resultado[:tags].empty? ? nao_encontrado : resultado[:tags].join(', ')}"
puts "URL: #{resultado[:urls].empty? ? nao_encontrado : resultado[:urls].join(', ')}"
puts "Email: #{resultado[:emails].empty? ? nao_encontrado : resultado[:emails].join(', ')}"