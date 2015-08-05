#!/usr/bin/ruby

require 'sqlite3'

begin
    
    db = SQLite3::Database.new "words.db"
    db.execute "CREATE TABLE IF NOT EXISTS Words(Id INTEGER PRIMARY KEY, 
        Word TEXT, Description TEXT, Category TEXT)"
    db.execute "INSERT INTO Words VALUES(1,'banana banana', 'yellow', 'fruits')"
    db.execute "INSERT INTO Words VALUES(2,'orange orange','exotic', 'fruits')"
    db.execute "INSERT INTO Words VALUES(3,'watermelon watermelon', 'red and green', 'fruits')"
    db.execute "INSERT INTO Words VALUES(4,'earth earth','we live on it', 'astronomy')"
    db.execute "INSERT INTO Words VALUES(5,'upiter upiter','biggest planet', 'astronomy' )"
    db.execute "INSERT INTO Words VALUES(6,'venus venus','second from the sun', 'astronomy')"
    db.execute "INSERT INTO Words VALUES(7,'pluton pluton','for a long time it wasn't even a planet', 'astronomy')"
    db.execute "INSERT INTO Words VALUES(8,'neptun neptun','there is a greek god with that name', 'astrology')"
    
rescue SQLite3::Exception => e 
    
    puts "Exception occurred"
    puts e
    
ensure
    db.close if db
end

puts `clear`
puts "\n<<< Hangman >>>\n\n"
puts "To choose category for your game type \"astronomy\" or \"fruits\". If you want to see game statistics on this pc type \"stats\" \n"
print "> "
user_word = gets.chomp.downcase.strip
until user_word == "astronomy" || user_word == "fruits" || user_word == "stats"
print "> "
user_word = gets.chomp.downcase.strip
end

begin
    prng = Random.new
    db = SQLite3::Database.open "words.db"
    db.results_as_hash = true
    category = user_word

    stm = db.prepare "SELECT * FROM Words WHERE Category= :category ORDER BY RANDOM() LIMIT 1;"
    rs = stm.execute category

    row = rs.next   
    word_description = row['Description']
    choosen_word = row['Word']
                
rescue SQLite3::Exception => e 
    
    puts "Exception occurred"
    puts e
    
ensure
    stm.close if stm
    db.close if db
end
hanged_stats = 0
win_stats = 0
total_chances = 5
wrong_try = 0
right_guess = ''
used_letters = ''
all_letters = right_guess + used_letters
hanged = <<HANG
 +---+-
 |   |
 |   0
 |   |\\
 |   /\\
-+----------
HANG

survived = <<WIN
   (@)
  ^\\|
    |/^
____|_____
WIN

class String
  def map
    s = ''
    size.times {|i| s << yield(self[i])}
    s
  end
end

def get_placeholder(sample_word, guessed_word)
  placeholder = ''
  if sample_word.include?(' ')
    sample_word = sample_word.split(' ')
    placeholder = (get_placeholder(sample_word[0],guessed_word) + " " + get_placeholder(sample_word[1], guessed_word))
  else
    placeholder = sample_word[0] + sample_word[1..-2].map { |char| guessed_word.include?(char)? char : '_ '} + sample_word[-1]
  end
  placeholder
end

puts `clear`


while true
  puts get_placeholder(choosen_word, right_guess)
  puts "You can try to guess the word but if you fail you will be hanged"
  puts "Your category is " + category + "\n"
  puts 'Guess what is '+ word_description + ":"
  print "Enter word [#{total_chances - wrong_try} chances left]:"

  char = gets.chomp
  puts `clear`
  
  if choosen_word.include? char

    if(right_guess.include? char)
      puts char + ' is already given and accepted.'
      puts 'Try another: '
    else
      right_guess = right_guess + char
      placeholder = get_placeholder(choosen_word, right_guess)

      puts 'Great! '
    end

    unless placeholder.include? '_ '
      puts "WELL DONE!! YOU SURVIVED"
      puts survived
      win_stats += 1
      break
    end
  elsif char.length > 1
    puts "YOU HANGED!"
    puts hanged
    hanged_stats += 1
    break
  else
    used_letters = used_letters + char
    puts "Sorry! The word dosen't contains '#{char}'"
    wrong_try += 1

    if (wrong_try == total_chances)
      puts "YOU HANGED!"
      puts hanged
      hanged_stats += 1
      break
    else
      puts 'Try another: '
    end
  end

end


begin
    
    db = SQLite3::Database.new "stats.db"
    db.execute "CREATE TABLE IF NOT EXISTS Stats(Id INTEGER PRIMARY KEY, 
        Wins INT, Loses INT, Letters TEXT)"
    db.execute "INSERT INTO Stats VALUES(1, ?, ?, ?)", [win_stats, hanged_stats, all_letters]

rescue SQLite3::Exception => e 
    
    puts "Exception occurred"
    puts e
    
ensure
    db.close if db
end
