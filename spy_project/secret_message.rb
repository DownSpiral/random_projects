mode = ARGV[0]
password = ARGV[1]
seed = password.split('').map(&:ord).reduce(0) { |memo, n| memo ^ n }
message = ARGV[2]

CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!@#$%^&*()=+-_'/?><,.|\{}[] ~"
MIXED_CHARACTERS = CHARACTERS.split('').shuffle(random: Random.new(seed))
ENCIPHER = Hash[[MIXED_CHARACTERS, MIXED_CHARACTERS.rotate].transpose]
DECIPHER = Hash[[MIXED_CHARACTERS.rotate, MIXED_CHARACTERS].transpose]

CIPHER = mode == "encrypt" ? ENCIPHER : DECIPHER

puts message.split('').map { |character| CIPHER[character] }.join('')

