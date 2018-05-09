####################################################
# Custom proxy build with Goliath (non-blocking Ruby web server framework)
# https://github.com/postrank-labs/goliath
####################################################
require 'goliath'
require 'em-synchrony/em-http'

class Proxy < Goliath::API
  use Goliath::Rack::Params

  REDIRECT_HOSTNAME = 'localhost'
  REDIRECT_PORT = '4567'

  def on_headers(env, headers)
    @headers = headers
  end

  def response(env)
    if correct_parameter?(env['params']['api_key']) || correct_parameter?(@headers['X-Api-Key'])
      http = server_request(env)
      [200, response_headers(http.response_header), http.response]
    else
      [401, response_headers({}), "Unauthorized!"]
    end
  end

  private

  def response_headers(headers)
    headers.merge!("X-Goliath" => "Proxy")
  end

  def server_request(env)
    EM::HttpRequest.new(redirect_url(env), {
      head: strip_x_api_key_header(@headers),
      query: strip_api_key_param(env['params'])
    }).get
  end
  #...
####################################################
# here we get a lot better performance instead of using
# case i
# when 1..19
# when 20..99 etc
# because we check less if-conditions

  def spellout(number)
    if number === 1_000_000 then "one million"
    elsif number >= 1000 then spellout_thousands(number)
    elsif number >= 100 then spellout_hundreds(number)
    elsif number >= 20 then spellout_tens(number)
    elsif number > 0 then spellout_units(number)
    else
      raise "invalid number: #{number.inspect}"
    end
  end

#####################################################
# algorithmic problems
#####################################################

def minNum(a, k, p)
  return -1 if a >= k

  advantage = k.to_f - a.to_f
  factor = p.to_f / advantage

  if factor >= 0
    factor.floor + 1
  else
    -1
  end
end

#####################################################
def letter_to_index(letter)
  Integer(letter) - 1
end

def read_char_and_inc_pos(string_io, position, length = 1)
  char = string_io.read(length)
  position += length

  [char, position]
end

def read_count(string_io, position)
  buffer = []

  while true do
    char, position = read_char_and_inc_pos(string_io, position)
    if char != '('
      buffer << char
    else
      break
    end
  end
  count = buffer.reverse.join("").to_i

  [count, position]
end

def frequency(s)
  length = s.size
  string_io = StringIO.new(s.reverse)
  letter_count = Array.new(26, 0)
  position = 0
  count = 1

  while (position < length) do
    char, position = read_char_and_inc_pos(string_io, position, 1)

    if char == ')'
      count, position = read_count(string_io, position)
      next
    end

    if char == '#'
      char, position = read_char_and_inc_pos(string_io, position, 2)
      char = letter_to_index(char.reverse)
    else
      char = letter_to_index(char)
    end
    letter_count[char] += count

    count = 1 # reset letter counter
  end

  letter_count
end
