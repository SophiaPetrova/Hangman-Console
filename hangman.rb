#!/usr/bin/ruby

require 'sqlite3'

total_chances = 5
wrong_try = 0
right_guess = ''

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

puts `clear`
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
      break
    end
  elsif char.length > 1
    puts "YOU HANGED!"
    puts hanged
    break
  else
    puts "Sorry! The word doesn't contains '#{char}'"
    wrong_try += 1

    if (wrong_try == total_chances)
      puts "YOU HANGED!"
      puts hanged
      break
    else
      puts 'Try another: '
    end
  end

end
