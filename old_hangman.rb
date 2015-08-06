#!/usr/bin/ruby

require 'sqlite3'

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



begin
    
  db = SQLite3::Database.new "hangman.db"
  db.execute "CREATE TABLE IF NOT EXISTS Words(Id INTEGER PRIMARY KEY, 
        Word TEXT, Description TEXT, Category TEXT)"
  db.execute "INSERT INTO Words VALUES(1,'banana', 'yellow', 'fruits')"
  db.execute "INSERT INTO Words VALUES(2,'orange','exotic', 'fruits')"
  db.execute "INSERT INTO Words VALUES(3,'watermelon', 'red and green', 'fruits')"
  db.execute "INSERT INTO Words VALUES(4,'New York','in USA', 'cities')"
  db.execute "INSERT INTO Words VALUES(5,'Buenos Aires','in Argentina', 'cities' )"
  db.execute "INSERT INTO Words VALUES(6,'Santo Domingos','in Dominican Republic', 'cities')"
  db.execute "INSERT INTO Words VALUES(7,'Phnom Penh','in Cambodia', 'cities')"
  db.execute "INSERT INTO Words VALUES(8,'San Salvador','in El Salvador', 'cities')"
    
rescue SQLite3::Exception => e 
    
    puts "Exception occurred"
    puts e
    
ensure
    db.close if db
end


 begin
    
  db = SQLite3::Database.open "hangman.db"
  db.results_as_hash = true

  db.execute "CREATE TABLE IF NOT EXISTS Stats(Id INTEGER PRIMARY KEY, 
         Wins INT DEFAULT 0, Loses INT DEFAULT 0, Letters TEXT DEFAULT NULL)"
  stm2 = db.prepare "INSERT OR REPLACE INTO Stats VALUES(1, ?, ?, ?)"
  stm2.bind_params win_stats, hanged_stats, all_letters
  a = stm2.execute
  statement = db.execute "SELECT * FROM Stats;"

   won_games = statement['Wins']
   lost_games = statement['Loses']
   all_used_letters = statement['Letters']
  
  n = db.changes
  puts "There has been #{n} changes"
  puts won_games
  puts lost_games
  puts all_used_letters
 rescue SQLite3::Exception => e 
    
    puts "Exception occurred"
    puts e
    
  ensure
    db.close if db
 end

# puts `clear`
puts "\n<<< Hangman >>>\n\n"
puts "To choose category for your game type \"cities\" or \"fruits\"\n"
print "> "
user_word = gets.chomp.downcase.strip
until user_word == "cities" || user_word == "fruits"
user_word = gets.chomp.downcase.strip
end

begin
    prng = Random.new
    db = SQLite3::Database.open "hangman.db"
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
    
    db = SQLite3::Database.open "hangman.db"
    db.execute "INSERT OR REPLACE INTO Stats VALUES(1, Wins + ?, Loses + ?, Letters + ?);", [win_stats, hanged_stats, all_letters]

  rescue SQLite3::Exception => e 
    
    puts "Exception occurred"
    puts e
    
  ensure
    db.close if db
  end
